pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

// KWin backend. KWin exposes neither wlr-foreign-toplevel-management nor
// ext-workspace, so windows and virtual desktops are mirrored by a KWin script
// (Services/kwin/dms-bridge.js). The script pushes JSON snapshots as D-Bus
// method calls, read here through `busctl monitor`. Actions go the other way
// as one-shot KWin scripts.
Singleton {
    id: root

    readonly property var log: Log.scoped("KwinService")

    readonly property bool active: CompositorService.isKwin
    property bool connected: false

    // Objects shaped like Quickshell.Wayland.Toplevel
    property var toplevels: []
    property var activeToplevel: null

    // Objects shaped like Quickshell.WindowManager windowsets
    property var workspaces: []
    property string currentDesktopId: ""
    property string activeOutput: ""

    readonly property QtObject toplevelList: QtObject {
        readonly property var values: root.toplevels
    }
    readonly property QtObject projection: QtObject {
        readonly property var windowsets: root.workspaces
    }

    signal windowsChanged

    property var _toplevelPool: ({})
    property var _workspacePool: ({})
    property int _cmdSerial: 0
    property int _monitorFailures: 0

    // Alpe: Griffleisten. Wo der obere Rand eines Fensters ohne Titelleiste sichtbar ist, meldet
    // das Skript eine Leiste; Modules/WindowGrips.qml legt dort eine unsichtbare Fläche ab.
    readonly property bool gripEnabled: active && SettingsData.windowGripEnabled
    property var grips: []
    property bool gripHeld: false
    // Wohin ein gezogenes Fenster einrasten würde: {output, x, y, w, h, kind} oder null.
    property var snapPreview: null
    // Offene Popouts und Dialoge der Shell liegen über den Fenstern; so lange ruhen die Leisten.
    property bool shellBusy: false
    // Was tatsächlich als Fläche steht. Nachgeführt wird verzögert und nie, während eine Leiste
    // gedrückt ist: an der gedrückten Fläche hängt der Mausgriff, sie darf nicht verschwinden.
    property var visibleGrips: []

    onGripsChanged: gripPublish.restart()
    onShellBusyChanged: gripPublish.restart()
    onGripEnabledChanged: gripPublish.restart()
    onConnectedChanged: gripPublish.restart()
    onGripHeldChanged: gripPublish.restart()

    function _publishGrips() {
        if (gripHeld)
            return;
        const next = gripEnabled && connected && !shellBusy ? grips : [];
        if (JSON.stringify(next) !== JSON.stringify(visibleGrips))
            visibleGrips = next;
    }

    Timer {
        id: gripPublish
        interval: 16
        onTriggered: root._publishGrips()
    }
    readonly property string _bridgeConfig: JSON.stringify({
        "gripEnabled": gripEnabled,
        "gripHeight": SettingsData.windowGripHeight,
        "gripOutside": SettingsData.windowGripOutside,
        "gripSkipDecorated": SettingsData.windowGripSkipDecorated,
        "gripSnap": SettingsData.windowGripSnap,
        "gripExcluded": SettingsData.windowGripExcluded || [],
        "shellPid": Quickshell.processId
    })
    on_BridgeConfigChanged: {
        if (connected)
            configReload.restart();
    }

    function _syncShellBusy() {
        const open = map => Object.values(map || {}).some(entry => !!entry);
        shellBusy = open(PopoutManager.currentPopoutsByScreen) || open(ModalManager.currentModalsByScreen);
    }

    function _gripShortcut(name) {
        Quickshell.execDetached(["busctl", "--user", "call", "org.kde.kglobalaccel", "/component/kwin", "org.kde.kglobalaccel.Component", "invokeShortcut", "s", name]);
    }

    function gripBegin() {
        if (!gripEnabled)
            return;
        gripHeld = true;
        gripRelease.restart();
        _gripShortcut("alpe-grip-begin");
    }

    function gripEnd() {
        gripRelease.stop();
        snapPreview = null;
        if (!gripHeld)
            return;
        gripHeld = false;
        _gripShortcut("alpe-grip-end");
    }

    function _applyGrips(list) {
        _syncShellBusy();
        if (!Array.isArray(list))
            return;
        if (JSON.stringify(list) !== JSON.stringify(grips))
            grips = list;
    }

    Connections {
        target: PopoutManager
        function onPopoutChanged() {
            root._syncShellBusy();
        }
    }

    Connections {
        target: ModalManager
        function onModalChanged() {
            root._syncShellBusy();
        }
    }

    // Geht das Loslassen verloren (Fläche verschwunden, Shell neu geladen), endet der Griff trotzdem.
    Timer {
        id: gripRelease
        interval: 60000
        onTriggered: root.gripEnd()
    }

    Timer {
        id: configReload
        interval: 400
        onTriggered: root.reloadBridge()
    }

    readonly property string _bridgeName: "dms-bridge"
    readonly property string _bridgePath: Quickshell.shellDir + "/Services/kwin/dms-bridge.js"
    readonly property string _scripting: "busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting"

    readonly property Component _toplevelComponent: Component {
        QtObject {
            id: tl

            property string kwinId: ""
            property string appId: ""
            property string title: ""
            property bool activated: false
            property bool minimized: false
            property bool maximized: false
            property bool fullscreen: false
            property bool urgent: false
            property int pid: 0
            property var screens: []
            property var kwinDesktops: []
            property bool onAllDesktops: false
            property bool _sync: false

            onMinimizedChanged: {
                if (!tl._sync)
                    root._windowCommand(tl.kwinId, "w.minimized=" + (tl.minimized ? "true" : "false") + ";");
            }
            onFullscreenChanged: {
                if (!tl._sync)
                    root._windowCommand(tl.kwinId, "w.fullScreen=" + (tl.fullscreen ? "true" : "false") + ";");
            }
            onMaximizedChanged: {
                if (!tl._sync)
                    root._windowCommand(tl.kwinId, "w.setMaximize(" + (tl.maximized ? "true,true" : "false,false") + ");");
            }

            function activate() {
                root._windowCommand(tl.kwinId, "if(w.minimized)w.minimized=false;" + "if(!w.onAllDesktops&&w.desktops.length&&w.desktops.indexOf(workspace.currentDesktop)===-1)workspace.currentDesktop=w.desktops[0];" + "workspace.activeWindow=w;");
            }

            function close() {
                root._windowCommand(tl.kwinId, "w.closeWindow();");
            }
        }
    }

    readonly property Component _workspaceComponent: Component {
        QtObject {
            id: ws

            property string kwinId: ""
            property string name: ""
            property int number: 0
            property bool active: false
            property bool urgent: false
            readonly property bool shouldDisplay: true
            readonly property var coordinates: []

            function activate() {
                root.switchToDesktop(ws.kwinId);
            }
        }
    }

    function filterCurrentWorkspace(list) {
        if (!list)
            return [];
        const current = currentDesktopId;
        return list.filter(t => t && (t.onAllDesktops || !t.kwinDesktops || t.kwinDesktops.length === 0 || t.kwinDesktops.includes(current)));
    }

    function switchToDesktop(desktopId) {
        if (!_safe(desktopId))
            return;
        _run("var d=workspace.desktops;for(var i=0;i<d.length;i++){if(String(d[i].id)==='" + desktopId + "'){workspace.currentDesktop=d[i];break;}}");
    }

    function _safe(token) {
        return typeof token === "string" && /^[A-Za-z0-9{}_-]+$/.test(token);
    }

    // Befehle aus dem Fenstermenü der Griffleisten.
    function windowInfo(windowId) {
        return toplevels.find(toplevel => toplevel.kwinId === windowId) ?? null;
    }

    function windowAction(windowId, action) {
        switch (action) {
        case "minimize":
            _windowCommand(windowId, "w.minimized=true;");
            break;
        case "maximize":
            _windowCommand(windowId, "var m=" + (windowInfo(windowId)?.maximized ? "false" : "true") + ";w.setMaximize(m,m);");
            break;
        case "above":
            _windowCommand(windowId, "w.keepAbove=!w.keepAbove;");
            break;
        case "alldesktops":
            _windowCommand(windowId, "w.onAllDesktops=!w.onAllDesktops;");
            break;
        case "close":
            _windowCommand(windowId, "w.closeWindow();");
            break;
        }
    }

    function _windowCommand(windowId, body) {
        if (!_safe(windowId))
            return;
        _run("var l=workspace.windowList(),w=null;for(var i=0;i<l.length;i++){if(String(l[i].internalId)==='" + windowId + "'){w=l[i];break;}}if(w){" + body + "}");
    }

    function _run(body) {
        if (!active)
            return;
        const name = "dms-cmd-" + Date.now() + "-" + (++_cmdSerial);
        const js = "(function(){try{" + body + "}catch(e){print('dms-kwin: '+e);}})();";
        const sh = 'f="${XDG_RUNTIME_DIR:-/tmp}/$1.js"; printf "%s" "$2" > "$f" || exit 1; ' + 'id=$(' + _scripting + ' loadScript ss "$f" "$1" | cut -d" " -f2); ' + 'busctl --user call org.kde.KWin "/Scripting/Script$id" org.kde.kwin.Script run >/dev/null; ' + 'sleep 2; ' + _scripting + ' unloadScript s "$1" >/dev/null; rm -f "$f"';
        Quickshell.execDetached(["sh", "-c", sh, "sh", name, js]);
    }

    function reloadBridge() {
        if (!active)
            return;
        bridgeLoader.running = false;
        bridgeLoader.running = true;
    }

    function _handleLine(line) {
        if (!line)
            return;
        let message;
        try {
            message = JSON.parse(line);
        } catch (e) {
            return;
        }
        const raw = message.payload?.data?.[0];
        if (typeof raw !== "string")
            return;
        if (message.member === "shortcut") {
            _handleShortcut(raw);
            return;
        }
        if (message.member !== "state")
            return;
        let state;
        try {
            state = JSON.parse(raw);
        } catch (e) {
            log.warn("Unreadable bridge state:", e);
            return;
        }
        _apply(state);
        _applyGrips(state.grips);
        const snap = state.snap ?? null;
        if (JSON.stringify(snap) !== JSON.stringify(snapPreview))
            snapPreview = snap;
    }

    // Shortcut ids registered by the bridge script, mapped to this shell's IPC
    readonly property var _shortcutActions: ({
            "dms-launcher": ["spotlight", "toggle"],
            "dms-clipboard": ["clipboard", "toggle"],
            "dms-processlist": ["processlist", "toggle"],
            "dms-settings": ["settings", "toggle"],
            "dms-notifications": ["notifications", "toggle"],
            "dms-control-center": ["control-center", "toggle"],
            "dms-dash": ["dash", "toggle", ""],
            "dms-powermenu": ["powermenu", "toggle"],
            "dms-notepad": ["notepad", "toggle"]
        })

    function _handleShortcut(name) {
        const action = _shortcutActions[name];
        if (!action)
            return;
        Quickshell.execDetached(["qs", "ipc", "--pid", String(Quickshell.processId), "call"].concat(action));
    }

    function _sameList(a, b) {
        if (a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; i++) {
            if (a[i] !== b[i])
                return false;
        }
        return true;
    }

    function _sameStrings(a, b) {
        if (!a || !b || a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; i++) {
            if (a[i] !== b[i])
                return false;
        }
        return true;
    }

    function _screensFor(outputName) {
        if (!outputName)
            return [];
        const out = [];
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === outputName)
                out.push(Quickshell.screens[i]);
        }
        return out;
    }

    function _apply(state) {
        if (!connected) {
            connected = true;
            log.info("Bridge connected:", (state.windows || []).length, "windows,", (state.desktops || []).length, "desktops");
        }
        let layoutChanged = false;

        // Virtual desktops
        const current = state.current || "";
        const wsLive = {};
        const wsList = [];
        for (const d of (state.desktops || [])) {
            let ws = _workspacePool[d.id];
            if (!ws) {
                ws = _workspaceComponent.createObject(root, {
                    "kwinId": d.id
                });
                _workspacePool[d.id] = ws;
            }
            ws.name = d.name || String(d.number || "");
            ws.number = d.number || 0;
            ws.active = d.id === current;
            wsLive[d.id] = true;
            wsList.push(ws);
        }
        if (!_sameList(workspaces, wsList))
            workspaces = wsList;
        for (const id in _workspacePool) {
            if (wsLive[id])
                continue;
            _workspacePool[id].destroy();
            delete _workspacePool[id];
        }
        if (currentDesktopId !== current) {
            currentDesktopId = current;
            layoutChanged = true;
        }
        if (activeOutput !== (state.activeOutput || ""))
            activeOutput = state.activeOutput || "";

        // Windows
        const activeId = state.active || "";
        const live = {};
        const list = [];
        const urgentDesktops = {};
        for (const w of (state.windows || [])) {
            let t = _toplevelPool[w.id];
            if (!t) {
                t = _toplevelComponent.createObject(root, {
                    "kwinId": w.id,
                    "_sync": true
                });
                _toplevelPool[w.id] = t;
                layoutChanged = true;
            }
            t._sync = true;
            t.appId = w.appId || "";
            t.title = w.title || "";
            t.pid = w.pid || 0;
            t.urgent = !!w.urgent;
            t.maximized = !!w.maximized;
            t.fullscreen = !!w.fullscreen;
            if (t.minimized !== !!w.minimized) {
                t.minimized = !!w.minimized;
                layoutChanged = true;
            }
            if (t.onAllDesktops !== !!w.allDesktops) {
                t.onAllDesktops = !!w.allDesktops;
                layoutChanged = true;
            }
            const desktops = w.desktops || [];
            if (!_sameStrings(t.kwinDesktops, desktops)) {
                t.kwinDesktops = desktops;
                layoutChanged = true;
            }
            const currentOutput = t.screens.length > 0 ? t.screens[0].name : "";
            if (currentOutput !== (w.output || "")) {
                t.screens = _screensFor(w.output);
                layoutChanged = true;
            }
            t.activated = w.id === activeId;
            t._sync = false;
            if (t.urgent) {
                for (const d of desktops)
                    urgentDesktops[d] = true;
            }
            live[w.id] = true;
            list.push(t);
        }
        for (const ws of wsList)
            ws.urgent = !!urgentDesktops[ws.kwinId];

        const nextActive = activeId ? (_toplevelPool[activeId] ?? null) : null;
        if (!_sameList(toplevels, list)) {
            toplevels = list;
            layoutChanged = true;
        }
        if (activeToplevel !== nextActive)
            activeToplevel = nextActive;
        for (const id in _toplevelPool) {
            if (live[id])
                continue;
            _toplevelPool[id].destroy();
            delete _toplevelPool[id];
        }
        if (layoutChanged)
            windowsChanged();
    }

    Process {
        id: busMonitor
        command: ["busctl", "--user", "monitor", "--json=short", "--match=type='method_call',interface='dev.duxlabs.KwinBridge'"]
        running: root.active
        stdout: SplitParser {
            onRead: line => root._handleLine(line)
        }
        onStarted: bridgeDelay.restart()
        onExited: exitCode => {
            root.connected = false;
            if (!root.active)
                return;
            root._monitorFailures++;
            root.log.warn("busctl monitor exited with code", exitCode);
            if (root._monitorFailures <= 5)
                monitorRestart.restart();
        }
    }

    Timer {
        id: monitorRestart
        interval: 3000
        onTriggered: {
            if (root.active)
                busMonitor.running = true;
        }
    }

    // busctl needs a moment to become a bus monitor before the first snapshot is sent
    Timer {
        id: bridgeDelay
        interval: 500
        onTriggered: root.reloadBridge()
    }

    // No snapshot after loading the bridge: load it once more, then give up and report
    Timer {
        id: bridgeWatchdog
        interval: 3000
        property int attempts: 0
        onTriggered: {
            if (root.connected || !root.active)
                return;
            attempts++;
            if (attempts > 2) {
                root.log.warn("No state from the KWin bridge; windows and workspaces stay empty");
                return;
            }
            root.reloadBridge();
        }
    }

    Process {
        id: bridgeLoader
        // Alpe: Geladen wird eine Kopie, der die Einstellungen als ALPE_CONFIG voranstehen.
        command: ["sh", "-c", 'copy="${XDG_RUNTIME_DIR:-/tmp}/alpe-kwin-bridge.js"; { printf "var ALPE_CONFIG = %s;\n" "$3"; cat "$1"; } > "$copy" || exit 4; ' + root._scripting + ' unloadScript s "$2" >/dev/null 2>&1; ' + 'id=$(' + root._scripting + ' loadScript ss "$copy" "$2" | cut -d" " -f2) || exit 1; ' + '[ "$id" -ge 0 ] 2>/dev/null || exit 2; ' + 'busctl --user call org.kde.KWin "/Scripting/Script$id" org.kde.kwin.Script run >/dev/null || exit 3', "sh", root._bridgePath, root._bridgeName, root._bridgeConfig]
        onExited: exitCode => {
            if (exitCode !== 0)
                root.log.warn("Loading the KWin bridge script failed with code", exitCode, "path:", root._bridgePath);
            else
                root.log.info("KWin bridge script loaded");
            bridgeWatchdog.restart();
        }
    }

    Component.onDestruction: {
        if (active)
            Quickshell.execDetached(["sh", "-c", _scripting + " unloadScript s " + _bridgeName + " >/dev/null 2>&1"]);
    }
}
