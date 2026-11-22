pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import "../PamStack.js" as PamStack

Singleton {
    id: root

    signal toastRequested(int severity, string title, string body, string command, string category)
    signal toastCategoryDismissed(string category)

    property var settingsRoot: null

    property string dankshellU2fPamText: ""
    property string u2fKeysText: ""

    property string fingerprintProbeOutput: ""
    property int fingerprintProbeExitCode: 0
    property bool fingerprintProbeFinalized: false

    property string pamProbeOutput: ""
    property bool pamProbeFinalized: false

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string u2fKeysPath: homeDir ? homeDir + "/.config/Yubico/u2f_keys" : ""
    property bool authProbeRequested: false
    readonly property bool homeU2fKeysDetected: u2fKeysPath !== "" && (authWatchers.item?.u2fKeys.loaded ?? false) && u2fKeysText.trim() !== ""
    readonly property bool lockU2fCustomConfigDetected: PamStack.moduleEnabled(dankshellU2fPamText, "pam_u2f")
    readonly property bool lockU2fCustomSourceDetected: (settingsRoot?.lockU2fPamPath || "") !== "" && (authWatchers.item?.customU2fPam.loaded ?? false)

    function envFlag(name) {
        const value = (Quickshell.env(name) || "").trim().toLowerCase();
        if (value === "1" || value === "true" || value === "yes" || value === "on")
            return true;
        if (value === "0" || value === "false" || value === "no" || value === "off")
            return false;
        return null;
    }

    readonly property var forcedFprintAvailable: envFlag("ALPE_FORCE_FPRINT_AVAILABLE")
    readonly property var forcedU2fAvailable: envFlag("ALPE_FORCE_U2F_AVAILABLE")

    // --- Derived auth probe state ---

    readonly property bool pamFprintSupportDetected: pamProbeFinalized && pamProbeOutput.includes("pam_fprintd.so:true")
    readonly property bool pamU2fSupportDetected: pamProbeFinalized && pamProbeOutput.includes("pam_u2f.so:true")

    readonly property string fingerprintProbeState: {
        if (forcedFprintAvailable !== null)
            return forcedFprintAvailable ? "ready" : "probe_failed";
        if (!fingerprintProbeFinalized)
            return "probe_failed";
        return PamStack.fingerprintProbeState(fingerprintProbeExitCode, fingerprintProbeOutput, pamFprintSupportDetected);
    }

    // --- Lock fingerprint capabilities ---

    readonly property bool lockFingerprintCanEnable: {
        if (forcedFprintAvailable !== null)
            return forcedFprintAvailable;
        switch (fingerprintProbeState) {
        case "ready":
        case "missing_enrollment":
            return true;
        default:
            return false;
        }
    }

    readonly property bool lockFingerprintReady: {
        if (forcedFprintAvailable !== null)
            return forcedFprintAvailable;
        return fingerprintProbeState === "ready";
    }

    readonly property string lockFingerprintReason: {
        if (forcedFprintAvailable !== null)
            return forcedFprintAvailable ? "ready" : "probe_failed";
        return fingerprintProbeState;
    }

    // --- Lock U2F capabilities ---

    readonly property bool lockU2fReady: {
        if (forcedU2fAvailable !== null)
            return forcedU2fAvailable;
        return lockU2fCustomSourceDetected || lockU2fCustomConfigDetected || homeU2fKeysDetected;
    }

    readonly property bool lockU2fCanEnable: {
        if (forcedU2fAvailable !== null)
            return forcedU2fAvailable;
        return lockU2fReady || pamU2fSupportDetected;
    }

    readonly property string lockU2fReason: {
        if (forcedU2fAvailable !== null)
            return forcedU2fAvailable ? "ready" : "probe_failed";
        if (lockU2fReady)
            return "ready";
        if (lockU2fCanEnable)
            return "missing_key_registration";
        return "missing_pam_support";
    }

    // --- Aggregates ---

    readonly property bool fprintdAvailable: lockFingerprintReady
    readonly property bool u2fAvailable: lockU2fReady

    // --- Auth detection ---

    readonly property var _fprintProbeCommand: ["sh", "-c", "if command -v fprintd-list >/dev/null 2>&1; then fprintd-list \"${USER:-$(id -un)}\" 2>&1; else printf '__missing_command__\\n'; exit 127; fi"]
    readonly property var _pamProbeCommand: ["sh", "-c", "for module in pam_fprintd.so pam_u2f.so; do found=false; for dir in /usr/lib64/security /usr/lib/security /lib/security /lib/x86_64-linux-gnu/security /usr/lib/x86_64-linux-gnu/security /usr/lib/aarch64-linux-gnu/security /run/current-system/sw/lib/security; do if [ -f \"$dir/$module\" ]; then found=true; break; fi; done; printf '%s:%s\\n' \"$module\" \"$found\"; done"]

    function detectAuthCapabilities() {
        authProbeRequested = true;
        // FileView cannot watch paths that do not exist yet, so reload the U2F PAM
        authWatchers.item.dankshellU2fPam.reload();
        authWatchers.item.u2fKeys.reload();

        if (forcedFprintAvailable === null) {
            fingerprintProbeFinalized = false;
            Proc.runCommand("fprint-probe", _fprintProbeCommand, (output, exitCode) => {
                fingerprintProbeOutput = output || "";
                fingerprintProbeExitCode = exitCode;
                fingerprintProbeFinalized = true;
            }, 0);
        }

        pamProbeFinalized = false;
        Proc.runCommand("pam-probe", _pamProbeCommand, (output, _exitCode) => {
            pamProbeOutput = output || "";
            pamProbeFinalized = true;
        }, 0);
    }

    function detectFprintd() {
        detectAuthCapabilities();
    }

    function detectU2f() {
        detectAuthCapabilities();
    }

    // --- Auth apply pipeline ---

    property bool authApplyRunning: false
    property bool authApplyQueued: false
    property bool authApplyRerunRequested: false
    property bool authApplyTerminalFallbackFromPrecheck: false
    property string authApplyStdout: ""
    property string authApplyStderr: ""
    property string authApplySudoProbeStderr: ""
    property string authApplyTerminalFallbackStderr: ""

    function scheduleAuthApply() {
        if (!settingsRoot)
            return;

        authApplyQueued = true;
        if (authApplyRunning) {
            authApplyRerunRequested = true;
            return;
        }

        authApplyDebounce.restart();
    }

    function beginAuthApply() {
        if (!authApplyQueued || authApplyRunning || !settingsRoot)
            return;

        authApplyQueued = false;
        authApplyRerunRequested = false;
        authApplyStdout = "";
        authApplyStderr = "";
        authApplySudoProbeStderr = "";
        authApplyTerminalFallbackStderr = "";
        authApplyTerminalFallbackFromPrecheck = false;
        authApplyRunning = true;
        authApplySudoProbeProcess.running = true;
    }

    function launchAuthApplyTerminalFallback(fromPrecheck, details) {
        authApplyTerminalFallbackFromPrecheck = fromPrecheck;
        if (details && details !== "")
            toastRequested(0, I18n.tr("Authentication changes need sudo. Opening terminal so you can use password or fingerprint."), details, "", "auth-sync");
        authApplyTerminalFallbackStderr = "";
        authApplyTerminalFallbackProcess.running = true;
    }

    function finishAuthApply() {
        const shouldRerun = authApplyQueued || authApplyRerunRequested;
        authApplyRunning = false;
        authApplyRerunRequested = false;
        if (shouldRerun)
            authApplyDebounce.restart();
    }

    Timer {
        id: authApplyDebounce
        interval: 300
        repeat: false
        onTriggered: root.beginAuthApply()
    }

    property var authApplyProcess: Process {
        command: [Proc.backendBin, "auth", "sync", "--yes"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.authApplyStdout = text || ""
        }

        stderr: StdioCollector {
            onStreamFinished: root.authApplyStderr = text || ""
        }

        onExited: exitCode => {
            const out = (root.authApplyStdout || "").trim();
            const err = (root.authApplyStderr || "").trim();

            if (exitCode === 0) {
                let details = out;
                if (err !== "")
                    details = details !== "" ? details + "\n\nstderr:\n" + err : "stderr:\n" + err;
                root.toastRequested(0, I18n.tr("Authentication changes applied"), details, "", "auth-sync");
                root.detectAuthCapabilities();
                root.finishAuthApply();
                return;
            }

            let details = "";
            if (out !== "")
                details = out;
            if (err !== "")
                details = details !== "" ? details + "\n\nstderr:\n" + err : "stderr:\n" + err;
            root.toastRequested(1, I18n.tr("Background authentication sync failed. Trying terminal mode."), details, "", "auth-sync");
            root.launchAuthApplyTerminalFallback(false, "");
        }
    }

    property var authApplySudoProbeProcess: Process {
        command: ["sudo", "-n", "true"]
        running: false

        stderr: StdioCollector {
            onStreamFinished: root.authApplySudoProbeStderr = text || ""
        }

        onExited: exitCode => {
            const err = (root.authApplySudoProbeStderr || "").trim();
            if (exitCode === 0) {
                root.toastRequested(0, I18n.tr("Applying authentication changes..."), "", "", "auth-sync");
                root.authApplyProcess.running = true;
                return;
            }

            root.launchAuthApplyTerminalFallback(true, err);
        }
    }

    property var authApplyTerminalFallbackProcess: Process {
        command: [Proc.backendBin, "auth", "sync", "--terminal", "--yes"]
        running: false

        stderr: StdioCollector {
            onStreamFinished: root.authApplyTerminalFallbackStderr = text || ""
        }

        onExited: exitCode => {
            if (exitCode === 0) {
                const message = root.authApplyTerminalFallbackFromPrecheck ? I18n.tr("Terminal opened. Complete authentication there; it will close automatically when done.") : I18n.tr("Terminal fallback opened. Complete authentication there; it will close automatically when done.");
                root.toastRequested(0, message, "", "", "auth-sync");
            } else {
                let details = (root.authApplyTerminalFallbackStderr || "").trim();
                root.toastRequested(2, I18n.tr("Terminal fallback failed. Install one of the supported terminal emulators or run '%1' manually.", "terminal fallback status, %1 is a command").arg("alpe-dienst auth sync") + " " + I18n.tr("(exit %1)", "process exit code").arg(exitCode), details, "", "auth-sync");
            }
            root.finishAuthApply();
        }
    }

    Loader {
        id: authWatchers
        active: root.authProbeRequested
        sourceComponent: Item {
            property alias dankshellU2fPam: dankshellU2fPamWatcher
            property alias customU2fPam: customU2fPamWatcher
            property alias u2fKeys: u2fKeysWatcher

            FileView {
                id: dankshellU2fPamWatcher
                path: "/etc/pam.d/dankshell-u2f"
                watchChanges: true
                printErrors: false
                onLoaded: root.dankshellU2fPamText = text()
                onLoadFailed: root.dankshellU2fPamText = ""
            }

            FileView {
                id: customU2fPamWatcher
                path: root.settingsRoot?.lockU2fPamPath || ""
                printErrors: false
            }

            FileView {
                id: u2fKeysWatcher
                path: root.u2fKeysPath
                watchChanges: true
                printErrors: false
                onLoaded: root.u2fKeysText = text()
                onLoadFailed: root.u2fKeysText = ""
            }
        }
    }
}
