pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Services

Scope {
    id: root

    readonly property var log: Log.scoped("Lock")

    property string sharedPasswordBuffer: ""
    property bool inputRevealed: false
    property bool shouldLock: false

    onSharedPasswordBufferChanged: {
        if (!powerOffFadeTimer.running)
            return;
        cancelPowerOffFade();
    }

    onShouldLockChanged: {
        inputRevealed = false;
        IdleService.isShellLocked = shouldLock;
    }

    property bool lockInitiatedLocally: false
    property bool pendingLock: false
    readonly property int maxLockRetries: 3
    property int lockRetryAttempts: 0
    property bool lockRetryPending: false
    property bool lockPowerOffArmed: false
    property bool lockWakeAllowed: false
    property bool customLockerSpawned: false
    // Alpe: KWin kennt ext-session-lock nicht. Gesperrt wird dort über logind, worauf der
    // KDE-Sperrbildschirm reagiert; die eigene Sperre bleibt aus dem Spiel.
    readonly property bool kdeLock: CompositorService.isKwin && !(SettingsData.customPowerActionLock?.length > 0)
    // Alpe: Der KDE-Sperrbildschirm zeigt dasselbe Bild wie der Desktop. Gilt für das Alpe-Design
    // wie für das von KDE; Farben statt Bildern lässt er aus.
    readonly property string kdeLockWallpaper: {
        if (!kdeLock || !SettingsData.lockFollowWallpaper)
            return "";
        const first = Quickshell.screens[0]?.name ?? "";
        // Alpe: Bei einem Video-Hintergrund das Standbild (VideoWallpaperService), KDEs
        // Bild-Plugin kann kein Video zeigen; bis das Standbild da ist, bleibt der alte Eintrag.
        const path = String(first !== "" ? SessionData.getMonitorWallpaperImage(first) : VideoWallpaperService.imageFor(SessionData.wallpaperPath));
        if (VideoWallpaperService.isVideo(path))
            return "";
        if (path.startsWith("file://"))
            return path;
        return path.startsWith("/") ? "file://" + path : "";
    }
    onKdeLockWallpaperChanged: {
        if (kdeLockWallpaper !== "")
            Quickshell.execDetached(["sh", "-c", 'command -v kwriteconfig6 >/dev/null || exit 0; kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.image; kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "$1"', "sh", kdeLockWallpaper]);
    }
    // Alpe: Unter Hyprland mit hyprlock folgt dessen Hintergrund dem Desktop, wenn die
    // hyprlock.conf das so verlangt (Marke «alpe: hintergrund = desktop», gesetzt vom Gestalter).
    readonly property string hyprlockWallpaper: {
        if (!CompositorService.isHyprland)
            return "";
        const first = Quickshell.screens[0]?.name ?? "";
        const path = String(first !== "" ? SessionData.getMonitorWallpaperImage(first) : "").replace(/^file:\/\//, "");
        return path.startsWith("/") && !VideoWallpaperService.isVideo(path) ? path : "";
    }
    onHyprlockWallpaperChanged: {
        if (hyprlockWallpaper !== "")
            Quickshell.execDetached(["sh", "-c", 'c="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock.conf"; [ -f "$c" ] && grep -q "alpe: hintergrund = desktop" "$c" && python3 -I "$1" wallpaper "$c" "$2" >/dev/null', "sh", Quickshell.shellDir + "/scripts/alpe-hyprlock.py", hyprlockWallpaper]);
    }
    readonly property bool powerOffOnLock: SettingsData.lockScreenPowerOffMonitorsOnLock || IdleService.lockPowerOffRequested
    property real powerOffFadeTarget: 0
    property bool powerOffFadeInstant: false

    function beginPowerOff() {
        if (!SettingsData.fadeToDpmsEnabled || SettingsData.fadeToDpmsGracePeriod <= 0) {
            applyMonitorsOff();
            return;
        }
        powerOffFadeInstant = false;
        powerOffFadeTarget = 1;
        powerOffFadeTimer.restart();
    }

    function applyMonitorsOff() {
        IdleService.monitorsOff = true;
        CompositorService.powerOffMonitors();
        lockWakeAllowed = false;
        lockWakeDebounce.restart();
        dpmsReapplyTimer.start();
    }

    function resetPowerOffFade() {
        powerOffFadeTimer.stop();
        powerOffFadeInstant = true;
        powerOffFadeTarget = 0;
    }

    function cancelPowerOffFade() {
        resetPowerOffFade();
        IdleService.lockPowerOffRequested = false;
    }

    function lockWithKde() {
        IdleService.lockPowerOffRequested = false;
        Quickshell.execDetached(["loginctl", "lock-session"]);
        IdleService.dismissFadeToLock();
    }

    // Einmal je Anmeldung, nicht bei jedem Neustart der Shell: die Marke liegt im
    // Laufzeitverzeichnis, das mit der Abmeldung verschwindet.
    //
    // Alpe: Die Shell startet spät – zuerst erschienen Autostart-Fenster (Proton VPN) und
    // kurz der Desktop, dann erst die Sperre. Jetzt sperrt KWin selbst gleich beim Start
    // (kscreenlockerrc [Daemon] LockOnStart, wie Plasma Mobile). Stand der Schlüssel zu Beginn
    // dieser Sitzung schon auf true, hat KWin gesperrt und die Shell tut nichts mehr – sonst würde
    // sie nachsperren, wenn man schon entsperrt hat. Nur in der ersten Sitzung nach dem Einschalten
    // sperrt noch die Shell.
    // Startet die Shell erst mitten in der Sitzung (Einrichten, «alpe kde ein --jetzt», Design
    // einspielen), ist das keine Anmeldung: dann nur den Schlüssel setzen, nicht sperren. Massstab
    // ist, wie lange graphical-session.target schon läuft, ersatzweise wie lange KWin läuft.
    function lockAtLoginWithKde() {
        Quickshell.execDetached(["sh", "-c", 'mark="${XDG_RUNTIME_DIR:-/tmp}/alpe-locked-at-login"; [ -e "$mark" ] && exit 0; : > "$mark"; '
            + 'if command -v kreadconfig6 >/dev/null && [ "$(kreadconfig6 --file kscreenlockerrc --group Daemon --key LockOnStart)" = true ]; then exit 0; fi; '
            + 'command -v kwriteconfig6 >/dev/null && kwriteconfig6 --file kscreenlockerrc --group Daemon --key LockOnStart true; '
            + 'since=$(systemctl --user show graphical-session.target -P ActiveEnterTimestamp --timestamp=unix 2>/dev/null); since=${since#@}; '
            + 'case "$since" in ""|*[!0-9]*) ;; *) [ "$since" -gt 0 ] && [ $(( $(date +%s) - since )) -gt 90 ] && exit 0 ;; esac; '
            + 'age=$(ps -o etimes= -C kwin_wayland 2>/dev/null | sort -n | tail -1 | tr -d " "); '
            + 'case "$age" in ""|*[!0-9]*) ;; *) [ "$age" -gt 90 ] && exit 0 ;; esac; '
            + 'exec loginctl lock-session']);
    }

    function syncKdeLockOnStart() {
        if (!kdeLock)
            return;
        Quickshell.execDetached(["sh", "-c", 'command -v kwriteconfig6 >/dev/null || exit 0; kwriteconfig6 --file kscreenlockerrc --group Daemon --key LockOnStart "$1"', "sh", SettingsData.lockAtStartup ? "true" : "false"]);
    }

    Connections {
        target: SettingsData

        function onLockAtStartupChanged() {
            root.syncKdeLockOnStart();
        }
    }

    // logind meldet die Sperre; der KDE-Sperrbildschirm steht dann schon. Der Dienst wartet
    // vor dem Standby auf diese Meldung.
    function confirmKdeLock() {
        if (SessionService.loginctlAvailable && DMSService.apiVersion >= 2)
            DMSService.sendRequest("loginctl.lockerReady", null, () => {});
    }

    Component.onCompleted: {
        IdleService.lockComponent = this;
        IdleService.isSessionLockSecure = sessionLock.secure;
        if (kdeLock) {
            if (SettingsData.lockAtStartup)
                lockAtLoginWithKde();
            else
                syncKdeLockOnStart();
            return;
        }
        if (SettingsData.lockAtStartup) {
            lock();
            return;
        }
        // A shell restarted into a locked session: after a logind Unlock
        // ignored for a lock it started, only lockedHint still says locked,
        // and the state can arrive before this module's Connections exist.
        if (SessionService.locked || SessionService.lockedHint)
            followLoginctlLock();
    }

    function notifyLockedHint(locked: bool) {
        if (!SettingsData.loginctlLockIntegration || !DMSService.isConnected)
            return;
        DMSService.setLockedHint(locked, () => {});
    }

    function notifyLoginctl(lockAction: bool) {
        if (!SettingsData.loginctlLockIntegration || !DMSService.isConnected)
            return;
        if (lockAction)
            DMSService.lockSession(() => {});
        else
            DMSService.unlockSession(() => {});
    }

    function spawnCustomLocker() {
        log.info("Handing the lock to the custom lock command instead of the session lock");
        IdleService.lockPowerOffRequested = false;
        Quickshell.execDetached(["sh", "-c", SettingsData.customPowerActionLock]);
        // The custom locker manages its own surface; DMS never engages
        // WlSessionLock here, so isShellLocked stays false and the fade
        // overlay would never be dismissed. Hand off by dismissing it now.
        IdleService.dismissFadeToLock();
        customLockerSpawned = true;
    }

    function handleLoginctlCustomLock(): bool {
        if (!(SettingsData.customPowerActionLock?.length > 0))
            return false;
        if (!customLockerSpawned)
            spawnCustomLocker();
        return true;
    }

    function followLoginctlLock() {
        if (kdeLock) {
            confirmKdeLock();
            return;
        }
        if (shouldLock || pendingLock)
            return;
        if (handleLoginctlCustomLock())
            return;
        if (!SessionService.active && SessionService.loginctlAvailable && SettingsData.loginctlLockIntegration) {
            pendingLock = true;
            lockInitiatedLocally = false;
            return;
        }
        lockInitiatedLocally = false;
        lockPowerOffArmed = powerOffOnLock;
        shouldLock = true;
    }

    function resetLockRetry() {
        lockRetryAttempts = 0;
        lockRetryPending = false;
        lockRetryTimer.stop();
    }

    function handleLockLost() {
        if (lockRetryAttempts >= maxLockRetries) {
            log.error("Compositor refused session lock", maxLockRetries, "times - resetting lock state");
            forceReset();
            return;
        }
        lockRetryAttempts++;
        lockRetryPending = true;
        lockRetryTimer.restart();
        log.warn("Session lock lost while lock requested - retry", lockRetryAttempts, "/", maxLockRetries);
    }

    function lock() {
        if (kdeLock) {
            lockWithKde();
            return;
        }
        if (SettingsData.customPowerActionLock?.length > 0) {
            spawnCustomLocker();
            return;
        }
        if (shouldLock || pendingLock)
            return;

        resetLockRetry();
        lockInitiatedLocally = true;
        lockPowerOffArmed = powerOffOnLock;

        if (!SessionService.active && SessionService.loginctlAvailable && SettingsData.loginctlLockIntegration) {
            pendingLock = true;
            notifyLoginctl(true);
            return;
        }

        shouldLock = true;
        notifyLoginctl(true);
    }

    function lockAndOutputsOff() {
        if (kdeLock) {
            lockWithKde();
            return;
        }
        IdleService.lockPowerOffRequested = true;
        if (sessionLock.secure) {
            beginPowerOff();
            return;
        }
        lockPowerOffArmed = true;
        lock();
    }

    function unlock() {
        if (!shouldLock)
            return;
        resetLockRetry();
        lockInitiatedLocally = false;
        notifyLoginctl(false);
        shouldLock = false;
    }

    function forceReset() {
        lockInitiatedLocally = false;
        pendingLock = false;
        shouldLock = false;
        customLockerSpawned = false;
        resetLockRetry();
        resetPowerOffFade();
        IdleService.lockPowerOffRequested = false;
    }

    function activate() {
        lock();
    }

    Connections {
        target: SessionService

        function onSessionLocked() {
            root.followLoginctlLock();
        }

        // Alpe: Sobald logind die KDE-Sperre meldet, darf ein wartender Standby weiterlaufen.
        function onLockedHintChanged() {
            if (root.kdeLock && SessionService.lockedHint)
                SessionService.onSessionLockSecured();
        }

        function onSessionUnlocked() {
            customLockerSpawned = false;
            if (AdminPolicy.disableLogindUnlock)
                return;
            if (pendingLock) {
                pendingLock = false;
                lockInitiatedLocally = false;
                return;
            }
            if (!shouldLock || lockInitiatedLocally)
                return;
            shouldLock = false;
        }

        function onSessionResumed() {
            if (!shouldLock || sessionLock.locked)
                return;
            resumeRelockTimer.restart();
        }

        function onLockEditorRequested() {
            if (shouldLock)
                return;
            demoWindow.showDemo();
        }

        function onLoginctlStateChanged() {
            if (root.kdeLock)
                return;
            if (SessionService.active && pendingLock) {
                pendingLock = false;
                lockInitiatedLocally = true;
                lockPowerOffArmed = powerOffOnLock;
                shouldLock = true;
                return;
            }
            if (SessionService.locked && !shouldLock && !pendingLock) {
                if (handleLoginctlCustomLock())
                    return;
                lockInitiatedLocally = false;
                lockPowerOffArmed = powerOffOnLock;
                shouldLock = true;
            }
        }
    }

    Connections {
        target: IdleService

        function onLockRequested() {
            lock();
        }

        function onMonitorsOffChanged() {
            if (!IdleService.monitorsOff)
                root.resetPowerOffFade();
        }
    }

    Pam {
        id: sharedPam
        lockSecured: root.shouldLock && sessionLock.secure
        buffer: root.sharedPasswordBuffer
        onUnlockRequested: root.unlock()
    }

    WlSessionLock {
        id: sessionLock

        locked: shouldLock && !lockRetryPending

        WlSessionLockSurface {
            id: lockSurface

            property string currentScreenName: screen?.name ?? ""
            property bool isActiveScreen: {
                if (Quickshell.screens.length <= 1)
                    return true;
                const screens = SettingsData.getFilteredScreens("lockScreen");
                return screens.length === 0 || screens.includes(screen);
            }

            color: isActiveScreen ? "transparent" : SettingsData.lockScreenInactiveColor

            LockSurface {
                anchors.fill: parent
                visible: lockSurface.isActiveScreen
                lock: sessionLock
                pam: sharedPam
                sharedPasswordBuffer: root.sharedPasswordBuffer
                inputRevealed: root.inputRevealed
                onInputRevealRequested: revealed => root.inputRevealed = revealed
                screenName: lockSurface.currentScreenName
                isLocked: shouldLock
                onUnlockRequested: root.unlock()
                onPasswordChanged: newPassword => {
                    root.sharedPasswordBuffer = newPassword;
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: root.powerOffFadeTarget
                visible: opacity > 0 || powerOffFadeTimer.running

                Behavior on opacity {
                    enabled: !root.powerOffFadeInstant
                    NumberAnimation {
                        duration: SettingsData.fadeToDpmsGracePeriod * 1000
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    property real baselineX: -1
                    property real baselineY: -1

                    anchors.fill: parent
                    enabled: powerOffFadeTimer.running
                    hoverEnabled: enabled
                    onEnabledChanged: {
                        baselineX = -1;
                        baselineY = -1;
                    }
                    onPressed: root.cancelPowerOffFade()
                    onWheel: root.cancelPowerOffFade()
                    onPositionChanged: mouse => {
                        if (baselineX < 0) {
                            baselineX = mouse.x;
                            baselineY = mouse.y;
                            return;
                        }
                        if (Math.abs(mouse.x - baselineX) < 5 && Math.abs(mouse.y - baselineY) < 5)
                            return;
                        root.cancelPowerOffFade();
                    }
                }
            }
        }
    }

    Connections {
        target: sessionLock

        function onSecureChanged() {
            IdleService.isSessionLockSecure = sessionLock.secure;
            notifyLockedHint(sessionLock.secure);
            if (!sessionLock.secure)
                return;
            SessionService.onSessionLockSecured();
            IdleService.dismissFadeToLock();
            lockRetryAttempts = 0;
            pendingLock = false;
            if (lockPowerOffArmed && powerOffOnLock)
                beginPowerOff();
            lockPowerOffArmed = false;
        }

        function onLockedChanged() {
            if (sessionLock.locked)
                return;
            if (shouldLock && (IdleService.monitorsOff || lockPowerOffArmed || IdleService.lockPowerOffRequested))
                return;
            lockWakeAllowed = false;
            resetPowerOffFade();
            if (IdleService.monitorsOff) {
                IdleService.monitorsOff = false;
                CompositorService.powerOnMonitors();
            }
            IdleService.lockPowerOffRequested = false;
            if (shouldLock && !lockRetryPending)
                handleLockLost();
        }
    }

    LockScreenDemo {
        id: demoWindow
    }

    IpcHandler {
        target: "lock"

        function lock() {
            root.lock();
        }

        function lockAndOutputsOff() {
            root.lockAndOutputsOff();
        }

        function unlock() {
            if (AdminPolicy.disableLockIpcUnlock)
                return;
            root.unlock();
        }

        function forceReset() {
            if (AdminPolicy.disableLockIpcUnlock)
                return;
            root.forceReset();
        }

        function demo() {
            if (AdminPolicy.disableLockIpcUnlock)
                return;
            demoWindow.showDemo();
        }

        function isLocked(): bool {
            return sessionLock.secure;
        }

        function status(): string {
            return JSON.stringify({
                shouldLock: root.shouldLock,
                sessionLockLocked: sessionLock.locked,
                sessionLockSecure: sessionLock.secure,
                lockRetryAttempts: root.lockRetryAttempts,
                lockInitiatedLocally: root.lockInitiatedLocally,
                pendingLock: root.pendingLock,
                customLocker: SettingsData.customPowerActionLock?.length > 0,
                customLockerSpawned: root.customLockerSpawned,
                loginctlLocked: SessionService.locked,
                loginctlActive: SessionService.active
            });
        }
    }

    Timer {
        id: powerOffFadeTimer
        interval: SettingsData.fadeToDpmsGracePeriod * 1000
        repeat: false
        onTriggered: root.applyMonitorsOff()
    }

    IdleMonitor {
        timeout: 1
        respectInhibitors: false
        enabled: powerOffFadeTimer.running
        onIsIdleChanged: {
            if (isIdle)
                return;
            if (!powerOffFadeTimer.running)
                return;
            root.cancelPowerOffFade();
        }
    }

    Timer {
        id: lockRetryTimer
        interval: 1000
        repeat: false
        onTriggered: root.lockRetryPending = false
    }

    Timer {
        id: resumeRelockTimer
        interval: 1000
        repeat: false
        onTriggered: {
            if (!root.shouldLock || sessionLock.locked)
                return;
            if (IdleService.monitorsOff || root.lockPowerOffArmed || IdleService.lockPowerOffRequested)
                return;
            root.log.warn("Session lock dead after resume - re-locking");
            root.resetLockRetry();
            root.lockRetryPending = true;
            root.lockRetryPending = false;
        }
    }

    Timer {
        id: dpmsReapplyTimer
        interval: 100
        repeat: false
        onTriggered: IdleService.reapplyDpmsIfNeeded()
    }

    Timer {
        id: lockWakeDebounce
        interval: 200
        repeat: false
        onTriggered: {
            if (!sessionLock.secure)
                return;
            if (!powerOffOnLock)
                return;
            if (!IdleService.monitorsOff) {
                lockWakeAllowed = true;
                return;
            }
            if (lockWakeAllowed) {
                IdleService.monitorsOff = false;
                CompositorService.powerOnMonitors();
            } else {
                lockWakeAllowed = true;
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: sessionLock.secure
        hoverEnabled: enabled
        onPressed: lockWakeDebounce.restart()
        onPositionChanged: lockWakeDebounce.restart()
        onWheel: lockWakeDebounce.restart()
    }

    FocusScope {
        anchors.fill: parent
        focus: sessionLock.secure

        Keys.onPressed: event => {
            if (!sessionLock.secure)
                return;
            lockWakeDebounce.restart();
        }
    }
}
