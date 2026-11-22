pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Alpe.Widgets
import qs.Modules.Settings.Widgets

// Alpe: Sperrbildschirm unter KWin. KWin kennt ext-session-lock nicht, die Sperre des
// Ursprungsprojekts kann dort nicht arbeiten. Gesperrt wird über logind, worauf der
// KDE-Sperrbildschirm reagiert; diese Seite stellt dessen Verhalten ein (kscreenlockerrc).
Item {
    id: root

    property var parentModal: null

    // Vorgaben des KDE-Sperrbildschirms, solange nichts anderes in kscreenlockerrc steht.
    property bool autolock: true
    property int timeoutMinutes: 5
    property int graceSeconds: 5
    property bool lockOnResume: true
    property bool loaded: false
    property bool toolsMissing: false

    // Design: aus welchem Shell-Paket der Sperrdienst seine Oberfläche nimmt (plasmashellrc).
    property string shellPackage: ""
    property bool alpeInstalled: false
    property int designBlur: 48
    property int designDim: 40
    property string designStyle: "hyprlock"
    // Alpe: Stil «hyprlock» zeichnet die hyprlock.conf des MacBooks nach (Vorgabe).
    readonly property var styleValues: ["hyprlock", "klar", "slab"]
    readonly property var styleOptions: ["Eigenes Layout", "Klar", "Alfa Slab One"]
    // Wartet die Umschaltung auf das Ergebnis der Probe?
    property string switching: ""
    readonly property bool alpeActive: shellPackage === "org.alpe.desktop"

    function writeDesign(key, value) {
        Quickshell.execDetached(["kwriteconfig6", "--file", "kscreenlockerrc", "--group", "Greeter", "--group", "LnF", "--group", "General", "--key", key, String(value)]);
    }

    function useDesign(name) {
        if (name === "kde") {
            Quickshell.execDetached(["kwriteconfig6", "--file", "plasmashellrc", "--group", "Shell", "--key", "ShellPackage", "--delete"]);
            shellPackage = "";
            return;
        }
        // Das Alpe-Design erst nach bestandener Probe: Ein Design, das nicht lädt, führt zum Notdesign.
        switching = name;
        tester.command = ["bash", Quickshell.shellDir + "/scripts/alpe-lockcheck.sh", "test", "org.alpe.desktop"];
        tester.running = true;
    }

    function finishSwitch() {
        const ok = check !== null && check.greeter && !check.fallback;
        if (switching === "alpe" && ok) {
            Quickshell.execDetached(["kwriteconfig6", "--file", "plasmashellrc", "--group", "Shell", "--key", "ShellPackage", "org.alpe.desktop"]);
            shellPackage = "org.alpe.desktop";
        }
        switching = "";
    }

    readonly property var timeoutValues: [1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 120]
    readonly property var timeoutOptions: timeoutValues.map(minutes => I18n.duration(minutes * 60))
    readonly property var graceValues: [0, 5, 10, 15, 30, 60, 120, 300]
    readonly property var graceOptions: graceValues.map(seconds => seconds === 0 ? "Sofort" : I18n.duration(seconds))

    function nearest(values, wanted) {
        let best = 0;
        for (let i = 1; i < values.length; i++) {
            if (Math.abs(values[i] - wanted) < Math.abs(values[best] - wanted))
                best = i;
        }
        return best;
    }

    function parse(text) {
        for (const line of text.split("\n")) {
            const cut = line.indexOf("=");
            if (cut < 0)
                continue;
            const key = line.slice(0, cut);
            const value = line.slice(cut + 1).trim();
            if (value === "")
                continue;
            switch (key) {
            case "Autolock":
                autolock = value !== "false";
                break;
            case "Timeout":
                timeoutMinutes = Math.max(1, parseInt(value) || 5);
                break;
            case "LockGrace":
                graceSeconds = Math.max(0, parseInt(value) || 0);
                break;
            case "LockOnResume":
                lockOnResume = value !== "false";
                break;
            case "tools":
                toolsMissing = value !== "ok";
                break;
            }
        }
        loaded = true;
    }

    // Schreibt einen Wert und lässt den laufenden Sperrdienst die Datei neu einlesen.
    function write(key, value) {
        Quickshell.execDetached(["sh", "-c", 'kwriteconfig6 --file kscreenlockerrc --group Daemon --key "$1" "$2" && busctl --user call org.kde.screensaver /ScreenSaver org.kde.screensaver configure >/dev/null 2>&1', "sh", key, String(value)]);
    }

    function lockNow() {
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    // Befund des Testlaufs: null (noch keiner), sonst die Antwort von scripts/alpe-lockcheck.sh.
    property var check: null
    readonly property bool checkBad: check !== null && (!check.greeter || check.fallback)

    function checkTitle() {
        if (tester.running)
            return "Testfenster ist offen";
        if (check === null)
            return "Noch nicht geprüft";
        if (!check.greeter)
            return "Der KDE-Sperrbildschirm ist nicht installiert";
        if (check.fallback)
            return "Das Design lädt nicht – KDE zeigt das blaue Notdesign";
        return "Der Sperrbildschirm lädt sein Design";
    }

    function checkDetail() {
        if (tester.running)
            return "Passwort eingeben, um es zu schliessen. Es schliesst sich sonst nach 90 Sekunden. Gesperrt ist dabei nichts.";
        if (check === null)
            return "Der Test öffnet den Sperrbildschirm als gewöhnliches Fenster. So zeigt sich gefahrlos, ob er lädt und das Passwort annimmt.";
        if (!check.greeter)
            return "Paket «kscreenlocker» fehlt.";
        if (check.fallback)
            return check.missing.length > 0 ? "Fehlende Bausteine: " + check.missing.join(", ") : "Den Grund nennt der Bericht (siehe unten).";
        return "Hat das Passwort das Testfenster geschlossen, funktioniert auch das Entsperren.";
    }

    Process {
        id: tester
        command: ["bash", Quickshell.shellDir + "/scripts/alpe-lockcheck.sh", "test"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.check = JSON.parse(text);
                } catch (e) {
                    root.check = null;
                }
                root.finishSwitch();
            }
        }
    }

    Process {
        running: true
        command: ["sh", "-c", 'command -v kreadconfig6 >/dev/null 2>&1 || exit 0; printf "shell=%s\n" "$(kreadconfig6 --file plasmashellrc --group Shell --key ShellPackage)"; d="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/shells/org.alpe.desktop"; [ -e "$d/contents/lockscreen/LockScreen.qml" ] && echo alpe=1 || echo alpe=0; printf "blur=%s\n" "$(kreadconfig6 --file kscreenlockerrc --group Greeter --group LnF --group General --key Blur)"; printf "dim=%s\n" "$(kreadconfig6 --file kscreenlockerrc --group Greeter --group LnF --group General --key Dim)"; printf "style=%s\n" "$(kreadconfig6 --file kscreenlockerrc --group Greeter --group LnF --group General --key Style)"']
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    const cut = line.indexOf("=");
                    if (cut < 0)
                        continue;
                    const value = line.slice(cut + 1).trim();
                    switch (line.slice(0, cut)) {
                    case "shell":
                        root.shellPackage = value;
                        break;
                    case "alpe":
                        root.alpeInstalled = value === "1";
                        break;
                    case "blur":
                        if (value !== "")
                            root.designBlur = isNaN(parseInt(value)) ? 48 : parseInt(value);
                        break;
                    case "dim":
                        if (value !== "")
                            root.designDim = isNaN(parseInt(value)) ? 40 : parseInt(value);
                        break;
                    case "style":
                        root.designStyle = root.styleValues.indexOf(value) >= 0 ? value : "hyprlock";
                        break;
                    }
                }
            }
        }
    }

    Process {
        running: true
        command: ["sh", "-c", 'if command -v kreadconfig6 >/dev/null 2>&1 && command -v kwriteconfig6 >/dev/null 2>&1; then echo tools=ok; else echo tools=missing; exit 0; fi; for key in Autolock Timeout LockGrace LockOnResume; do printf "%s=%s\\n" "$key" "$(kreadconfig6 --file kscreenlockerrc --group Daemon --key "$key")"; done']
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    SettingsPage {
        SettingsCard {
            width: parent.width
            iconName: "lock"
            title: I18n.tr("Lock screen")
            settingKey: "alpeLock"

            SettingsRow {
                title: "KDE-Sperrbildschirm"
                subtitle: "KWin lässt nur seinen eigenen Sperrbildschirm zu. Alpe sperrt deshalb über die Sitzungsverwaltung: Sperren im Energiemenü, per Tastenkürzel und vor dem Standby landen alle dort."
                iconName: "shield_lock"

                AlpeButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonHeight: Theme.buttonHeightS
                    text: "Jetzt sperren"
                    iconName: "lock"
                    onClicked: root.lockNow()
                }
            }

            SettingsToggleRow {
                settingKey: "lockAtStartup"
                tags: ["lock", "startup", "login", "autologin", "anmeldung"]
                text: "Nach der Anmeldung sperren"
                description: "Für die automatische Anmeldung: KWin sperrt gleich beim Start, bevor Desktop und Autostart-Programme zu sehen sind (ab der nächsten Anmeldung nach dem Einschalten). Greift einmal je Anmeldung, nicht bei einem Neustart der Shell."
                checked: SettingsData.lockAtStartup
                onToggled: checked => SettingsData.set("lockAtStartup", checked)
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "palette"
            title: "Design"
            settingKey: "alpeLockDesign"

            SettingsToggleRow {
                text: "Alpe-Design"
                description: !root.alpeInstalled ? "Nicht installiert – «bash ~/alpe/install.sh» richtet es ein." : root.switching !== "" ? "Probe läuft: Der Sperrbildschirm erscheint kurz und schliesst sich nach der Wartezeit oder mit dem Passwort." : root.alpeActive ? "Uhr, Datum und Passwortfeld über dem weichgezeichneten Hintergrund." : "Aus: KDEs eigener Sperrbildschirm. Eingeschaltet wird erst nach einer Probe."
                enabled: root.alpeInstalled && root.switching === ""
                checked: root.alpeActive
                onToggled: checked => root.useDesign(checked ? "alpe" : "kde")
            }

            SettingsToggleRow {
                settingKey: "lockFollowWallpaper"
                text: "Hintergrund wie der Desktop"
                description: "Das Bild des Desktops wird auch zum Bild des Sperrbildschirms, bei jedem Wechsel."
                checked: SettingsData.lockFollowWallpaper
                onToggled: checked => SettingsData.set("lockFollowWallpaper", checked)
            }

            SettingsDropdownRow {
                visible: root.alpeActive
                text: "Stil"
                description: root.designStyle === "hyprlock" ? "Frei angeordnet wie am MacBook; gestaltet auf der Seite «Sperrbildschirm gestalten»." : "Feste Anordnung von Alpe."
                options: root.styleOptions
                currentValue: root.styleOptions[Math.max(0, root.styleValues.indexOf(root.designStyle))]
                onValueChanged: value => {
                    const index = root.styleOptions.indexOf(value);
                    if (index < 0)
                        return;
                    root.designStyle = root.styleValues[index];
                    root.writeDesign("Style", root.designStyle);
                }
            }

            SettingsNavRow {
                visible: root.alpeActive && root.designStyle === "hyprlock"
                title: "Sperrbildschirm gestalten"
                hint: "Vorschau, Texte, Bilder, Passwortfeld, Hintergrund"
                iconName: "brush"
                onClicked: keyboard => root.parentModal?.navigateTo("lock_design", keyboard)
            }

            // Unschärfe und Abdunkeln stellt das eigene Layout selbst ein.
            SettingsSliderRow {
                visible: root.alpeActive && root.designStyle !== "hyprlock"
                text: "Unschärfe"
                minimum: 0
                maximum: 64
                value: root.designBlur
                onSliderDragFinished: finalValue => {
                    root.designBlur = finalValue;
                    root.writeDesign("Blur", finalValue);
                }
            }

            SettingsSliderRow {
                visible: root.alpeActive && root.designStyle !== "hyprlock"
                text: "Abdunkeln"
                unit: "%"
                minimum: 0
                maximum: 80
                value: root.designDim
                onSliderDragFinished: finalValue => {
                    root.designDim = finalValue;
                    root.writeDesign("Dim", finalValue);
                }
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "fact_check"
            title: "Prüfen"
            settingKey: "alpeLockCheck"

            SettingsRow {
                title: root.checkTitle()
                subtitle: root.checkDetail()
                iconName: root.checkBad ? "error_outline" : root.check !== null && !tester.running ? "check_circle" : "science"
                iconColor: root.checkBad ? Theme.error : Theme.primary

                AlpeButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonHeight: Theme.buttonHeightS
                    text: "Testen"
                    iconName: "science"
                    busy: tester.running
                    enabled: !tester.running
                    backgroundColor: SettingsMetrics.controlSurface
                    textColor: Theme.surfaceText
                    onClicked: {
                        tester.command = ["bash", Quickshell.shellDir + "/scripts/alpe-lockcheck.sh", "test"];
                        tester.running = true;
                    }
                }
            }

            SettingsNoteRow {
                visible: root.checkBad && (root.check?.suggest ?? "") !== ""
                noteIconName: "terminal"
                monospace: true
                text: root.check?.suggest ?? ""
            }

            SettingsNoteRow {
                visible: root.checkBad
                noteIconName: "terminal"
                monospace: true
                text: "bash " + Quickshell.shellDir + "/scripts/alpe-lockcheck.sh report"
            }

            SettingsNoteRow {
                noteIconName: "emergency_home"
                tint: Theme.surfaceVariantText
                tintBackground: SettingsMetrics.controlSurface
                text: "Notausgang, falls der Sperrbildschirm einmal hängt: Strg+Alt+F3, anmelden, «loginctl unlock-sessions» eingeben, zurück mit Strg+Alt+F1 oder F2."
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "timer"
            title: "Automatische Sperre"
            settingKey: "alpeAutolock"
            visible: !root.toolsMissing

            SettingsToggleRow {
                text: "Bei Inaktivität sperren"
                description: "Die Zeit läuft im KDE-Sperrdienst. Programme, die den Ruhezustand unterdrücken (etwa ein laufendes Video), halten sie an."
                enabled: root.loaded
                checked: root.autolock
                onToggled: checked => {
                    root.autolock = checked;
                    root.write("Autolock", checked);
                }
            }

            SettingsDropdownRow {
                text: I18n.tr("Automatically lock after")
                visible: root.autolock
                enabled: root.loaded
                options: root.timeoutOptions
                currentValue: root.timeoutOptions[root.nearest(root.timeoutValues, root.timeoutMinutes)]
                onValueChanged: value => {
                    const index = root.timeoutOptions.indexOf(value);
                    if (index < 0)
                        return;
                    root.timeoutMinutes = root.timeoutValues[index];
                    root.write("Timeout", root.timeoutMinutes);
                }
            }

            SettingsDropdownRow {
                text: "Passwort verlangen nach"
                description: "Schonfrist nach der automatischen Sperre: In dieser Zeit genügt eine Mausbewegung."
                visible: root.autolock
                enabled: root.loaded
                options: root.graceOptions
                currentValue: root.graceOptions[root.nearest(root.graceValues, root.graceSeconds)]
                onValueChanged: value => {
                    const index = root.graceOptions.indexOf(value);
                    if (index < 0)
                        return;
                    root.graceSeconds = root.graceValues[index];
                    root.write("LockGrace", root.graceSeconds);
                }
            }

            SettingsToggleRow {
                text: "Nach dem Standby sperren"
                description: "Der Rechner wacht gesperrt auf."
                enabled: root.loaded
                checked: root.lockOnResume
                onToggled: checked => {
                    root.lockOnResume = checked;
                    root.write("LockOnResume", checked);
                }
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "link"
            title: "Verwandtes"

            SettingsNavRow {
                title: I18n.tr("Power & sleep")
                hint: "Bildschirme nach dem Sperren ausschalten, Standby, Energiemenü"
                iconName: "power_settings_new"
                onClicked: keyboard => root.parentModal?.navigateTo("power_sleep", keyboard)
            }

            SettingsRow {
                title: "Aussehen des Sperrbildschirms"
                subtitle: "Einstellungen von KDEs eigenem Design (Bild, Uhr, Medienanzeige) – KDE-Modul «Bildschirmsperre»"
                iconName: "wallpaper"
                clickable: true
                onClicked: Quickshell.execDetached(["kcmshell6", "kcm_screenlocker"])

                AlpeIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "open_in_new"
                    size: Theme.iconSize
                    color: Theme.surfaceVariantText
                }
            }
        }
    }
}
