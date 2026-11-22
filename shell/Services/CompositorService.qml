pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Common
import qs.DCommon.Common as DCommon
import qs.Services
import "../Common/WorkspaceModel.js" as WorkspaceModel
import "../Common/WindowModel.js" as WindowModel

Singleton {
    id: root
    readonly property var log: Log.scoped("CompositorService")

    property bool isHyprland: false
    property bool isKwin: false
    property string compositor: "unknown"
    property bool compositorDetected: false
    property bool outputPowerAvailable: false
    readonly property bool genericPowerBackend: compositorDetected && !isHyprland
    onGenericPowerBackendChanged: probeOutputPower()

    readonly property bool inOverview: isHyprland && HyprlandService.inOverview

    function probeOutputPower() {
        outputPowerAvailable = false;
        if (!genericPowerBackend)
            return;
        const backend = compositor;
        Proc.runCommand("output-power-probe", [Proc.dmsBin, "dpms", "list"], (output, code) => {
            if (root.compositor === backend && root.genericPowerBackend)
                root.outputPowerAvailable = code === 0;
        }, 0, 5000);
    }

    function setOutputPower(on) {
        Proc.runCommand("output-power-action", [Proc.dmsBin, "dpms", on ? "on" : "off"], (output, code) => {
            if (code !== 0)
                ToastService.showError(I18n.tr("Error"), I18n.tr("Failed to change display power", "Error shown when changing monitor power fails"));
        }, 0, 12000);
    }

    Connections {
        target: DMSService
        function onConnectionStateChanged() {
            if (DMSService.isConnected)
                root.probeOutputPower();
            else
                root.outputPowerAvailable = false;
        }
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            root.probeOutputPower();
            root.refreshHyprlandMonitorLayout();
        }
    }
    readonly property bool frameCompositorLayoutReady: (!isHyprland || HyprlandService.frameLayoutReady)
    readonly property bool useHyprlandFocusGrab: isHyprland && Quickshell.env("ALPE_HYPRLAND_EXCLUSIVE_FOCUS") !== "1"

    readonly property string hyprlandSignature: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")

    property var randrScales: ({})
    property bool randrReady: false
    signal randrDataReady

    property var sortedToplevels: []
    property var hyprlandVisibleSpecialWorkspaces: ({})
    property bool _sortScheduled: false

    signal toplevelsChanged
    signal workspaceStateChanged
    property int windowStateRevision: 0
    onToplevelsChanged: windowStateRevision++
    onWorkspaceStateChanged: windowStateRevision++
    readonly property var _edgePositions: ({
            top: SettingsData.Position.Top,
            bottom: SettingsData.Position.Bottom,
            left: SettingsData.Position.Left,
            right: SettingsData.Position.Right
        })

    readonly property bool supportsMinimize: isKwin || DCommon.Compositor.supportsMinimize

    readonly property bool hasWorkspaceIpc: {
        switch (compositor) {
        case "hyprland":
            return true;
        default:
            return false;
        }
    }
    readonly property bool ephemeralWorkspaces: isHyprland
    readonly property bool windowOverlapSupported: {
        switch (compositor) {
        case "hyprland":
            return true;
        default:
            return false;
        }
    }

    // Umsortieren per Ziehen konnte nur niri; der Zieh-Pfad in WorkspaceSwitcher bleibt dadurch aus.

    readonly property bool isKnownCompositor: configKey !== ""
    readonly property bool supportsWindowRules: isHyprland
    readonly property string dmsFloatingRuleId: "dms-floating-windows"
    property bool dmsWindowFloatingActive: false
    readonly property string dmsOpaqueRuleId: "dms-window-opaque"
    readonly property bool supportsLayoutConfig: isHyprland
    readonly property bool supportsCursorConfig: isHyprland
    readonly property bool supportsDisplayConfig: isHyprland
    readonly property bool supportsBarAutoHideReveal: isHyprland
    readonly property bool supportsWorkspaces: isHyprland
    // compositors where a workspace that does not exist yet is still a valid switch target
    readonly property bool supportsPersistentWorkspaces: isHyprland
    readonly property bool supportsWorkspaceUrgency: isKnownCompositor
    readonly property bool supportsWorkspaceFollowFocus: isKnownCompositor
    // plasmashell desktop menu
    readonly property bool reservesDesktopInput: isKwin
    readonly property bool desktopContextMenuEnabled: {
        switch (SettingsData.desktopContextMenu) {
        case "on":
            return true;
        case "off":
            return false;
        default:
            return !reservesDesktopInput;
        }
    }
    readonly property bool supportsSmartDock: isHyprland
    readonly property bool supportsNativeOverview: false
    readonly property bool supportsPointerConfig: isHyprland
    readonly property bool supportsInputConfig: isHyprland

    readonly property string displayName: {
        switch (compositor) {
        case "hyprland":
            return "Hyprland";
        case "kwin":
            return "KWin";
        default:
            return "";
        }
    }

    readonly property string configKey: {
        switch (compositor) {
        case "hyprland":
            return compositor;
        default:
            return "";
        }
    }

    property var _workspaceRecords: ({})

    Connections {
        target: root.isHyprland ? Hyprland.workspaces : null
        function onValuesChanged() {
            root.workspaceStateChanged();
        }
    }

    Connections {
        target: KwinService
        enabled: root.isKwin
        function onWindowsChanged() {
            root.scheduleSort();
            root.workspaceStateChanged();
        }
        function onActiveToplevelChanged() {
            root.workspaceStateChanged();
        }
    }

    function canMinimize(toplevel) {
        return supportsMinimize && toplevel && toplevel.minimized !== undefined;
    }

    function activateToplevel(toplevel) {
        if (!toplevel)
            return;
        if (canMinimize(toplevel) && toplevel.minimized)
            toplevel.minimized = false;
        toplevel.activate();
    }

    function toggleToplevel(toplevel) {
        if (!toplevel)
            return;
        if (!canMinimize(toplevel)) {
            activateToplevel(toplevel);
            return;
        }
        if (toplevel.minimized) {
            activateToplevel(toplevel);
            return;
        }
        if (toplevel.activated) {
            toplevel.minimized = true;
            return;
        }
        activateToplevel(toplevel);
    }

    function fetchRandrData() {
        Proc.runCommand("randr", [Proc.dmsBin, "randr", "--json"], (output, exitCode) => {
            if (exitCode === 0 && output) {
                try {
                    const data = JSON.parse(output.trim());
                    if (data.outputs && Array.isArray(data.outputs)) {
                        const scales = {};
                        for (const out of data.outputs) {
                            if (out.name && out.scale > 0)
                                scales[out.name] = out.scale;
                        }
                        randrScales = scales;
                    }
                } catch (e) {
                    log.warn("failed to parse randr data:", e);
                }
            }
            randrReady = true;
            randrDataReady();
        }, 0, 3000);
    }

    // wlr-output reports wl_fixed (1/256 steps), surfaces render at fractional-scale-v1 N/120
    function fractionalScale(fixedScale) {
        return Math.round(fixedScale * 120) / 120;
    }

    function getScreenScale(screen) {
        if (!screen)
            return 1;

        if (Quickshell.env("QT_WAYLAND_FORCE_DPI") || Quickshell.env("QT_SCALE_FACTOR")) {
            return screen.devicePixelRatio || 1;
        }

        // Live wlr-output state outranks the one-shot randr snapshot so scale changes propagate
        if (WlrOutputService.wlrOutputAvailable) {
            const wlrOutput = WlrOutputService.getOutput(screen.name);
            if (wlrOutput?.enabled && wlrOutput.scale !== undefined && wlrOutput.scale > 0) {
                return fractionalScale(wlrOutput.scale);
            }
        }

        const randrScale = randrScales[screen.name];
        if (randrScale !== undefined && randrScale > 0)
            return fractionalScale(randrScale);

        if (isHyprland && screen) {
            const hyprlandMonitor = Hyprland.monitors.values.find(m => m.name === screen.name);
            if (hyprlandMonitor?.scale !== undefined)
                return hyprlandMonitor.scale;
        }

        return screen?.devicePixelRatio || 1;
    }

    property var _windowKeys: []
    property int _windowSerial: 0

    function windowKey(toplevel) {
        if (!toplevel)
            return "";
        const known = _windowKeys.find(entry => entry.toplevel === toplevel);
        if (known)
            return known.key;
        const live = DToplevels.toplevels?.values;
        if (live) {
            for (let i = _windowKeys.length - 1; i >= 0; i--) {
                if (!live.includes(_windowKeys[i].toplevel))
                    _windowKeys.splice(i, 1);
            }
        }
        const key = "window:" + (++_windowSerial);
        _windowKeys.push({
            toplevel,
            key
        });
        return key;
    }

    function getFocusedScreenName() {
        if (isHyprland && Hyprland.focusedMonitor)
            return Hyprland.focusedMonitor.name;
        if (isKwin)
            return KwinService.activeOutput;

        return "";
    }

    function getFocusedScreen() {
        const screenName = getFocusedScreenName();
        if (!screenName)
            return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;

        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === screenName)
                return Quickshell.screens[i];
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    Timer {
        id: sortDebounceTimer
        interval: 100
        repeat: false
        onTriggered: {
            _sortScheduled = false;
            const next = computeSortedToplevels();
            // Avoid reassigning (and invalidating bindings) when contents are equivalent.
            if (!_toplevelListEquivalent(next, sortedToplevels))
                sortedToplevels = next;
            toplevelsChanged();
        }
    }

    function _toplevelListEquivalent(a, b) {
        if (!a || !b || a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; i++) {
            const x = a[i];
            const y = b[i];
            if (x === y)
                continue;
            if (!x || !y)
                return false;
            return false;
        }
        return true;
    }

    function scheduleSort() {
        if (_sortScheduled)
            return;
        _sortScheduled = true;
        sortDebounceTimer.restart();
    }

    Connections {
        target: DToplevels.toplevels
        function onValuesChanged() {
            root.scheduleSort();
        }
    }
    Connections {
        target: isHyprland ? Hyprland : null
        enabled: isHyprland

        function onRawEvent(event) {
            if (event.name === "monitoraddedv2" || event.name === "monitorremoved" || event.name === "configreloaded") {
                if (event.name === "configreloaded")
                    HyprlandService.refreshFollowMouse();
                root.refreshHyprlandMonitorLayout();
                return;
            }
            // Hyprland 0.57 emits this when a workspace id changes (e.g. after a rename); Quickshell 0.3.2 ignores it
            if (event.name === "changeworkspaceid") {
                Hyprland.refreshWorkspaces();
                return;
            }
            // Sent by the move/resize wrappers in alpe/binds.lua; Hyprland has no geometry event of its own
            if (event.name === "custom") {
                if (event.data !== "dms:geometry")
                    return;
                try {
                    Hyprland.refreshToplevels();
                } catch (e) {}
                root.scheduleSort();
                return;
            }
            if (event.name === "openwindow" || event.name === "closewindow" || event.name === "movewindow" || event.name === "movewindowv2" || event.name === "workspace" || event.name === "workspacev2" || event.name === "focusedmon" || event.name === "focusedmonv2" || event.name === "activewindow" || event.name === "activewindowv2" || event.name === "changefloatingmode" || event.name === "fullscreen" || event.name === "moveintogroup" || event.name === "moveoutofgroup" || event.name === "activespecial") {
                try {
                    Hyprland.refreshToplevels();
                    if (event.name === "workspace" || event.name === "workspacev2" || event.name === "focusedmon" || event.name === "focusedmonv2" || event.name === "activespecial")
                        Hyprland.refreshMonitors();
                } catch (e) {}
                if (event.name === "activespecial")
                    root.updateHyprlandVisibleSpecialWorkspaces(event);
                root.scheduleSort();
                if (event.name === "activewindow" || event.name === "activewindowv2")
                    root.workspaceStateChanged();
            }
        }
    }

    Component.onCompleted: {
        fetchRandrData();
        detectCompositor();
        updateHyprlandVisibleSpecialWorkspaces(null);
        scheduleSort();
    }

    function computeSortedToplevels() {
        if (!DToplevels.toplevels || !DToplevels.toplevels.values)
            return [];

        if (isHyprland)
            return sortHyprlandToplevelsSafe();

        return Array.from(DToplevels.toplevels.values);
    }

    function _get(o, path, fallback) {
        try {
            let v = o;
            for (let i = 0; i < path.length; i++) {
                if (v === null || v === undefined)
                    return fallback;
                v = v[path[i]];
            }
            return (v === undefined || v === null) ? fallback : v;
        } catch (e) {
            return fallback;
        }
    }

    function _normalizeSpecialWorkspaceName(name) {
        const raw = String(name ?? "").trim();
        if (raw.length === 0)
            return "";
        if (raw === "special")
            return "special:special";
        return raw.startsWith("special:") ? raw : `special:${raw}`;
    }

    function _hyprlandRawEventParts(event, argumentCount) {
        if (!event)
            return [];
        try {
            const parsed = event.parse(argumentCount);
            if (parsed && parsed.length !== undefined)
                return parsed;
        } catch (e) {}
        const data = String(event.data ?? "");
        return data.length > 0 ? data.split(",") : [];
    }

    function _specialWorkspaceNameFromMonitor(monitor) {
        if (!monitor)
            return "";
        const candidates = [monitor.activeSpecialWorkspace?.name, monitor.specialWorkspace?.name, monitor.lastIpcObject?.specialWorkspace?.name, monitor.lastIpcObject?.specialWorkspace, monitor.lastIpcObject?.activeSpecialWorkspace?.name];
        for (let i = 0; i < candidates.length; i++) {
            const normalized = _normalizeSpecialWorkspaceName(candidates[i]);
            if (normalized)
                return normalized;
        }
        return "";
    }

    function updateHyprlandVisibleSpecialWorkspaces(event) {
        if (!isHyprland) {
            hyprlandVisibleSpecialWorkspaces = ({});
            return;
        }

        const next = {};
        try {
            const monitors = Hyprland.monitors?.values || [];
            for (const monitor of monitors) {
                const monitorName = monitor?.name ?? monitor?.lastIpcObject?.name ?? "";
                if (!monitorName)
                    continue;
                const specialName = _specialWorkspaceNameFromMonitor(monitor);
                if (specialName)
                    next[monitorName] = specialName;
            }
        } catch (e) {
            log.warn("updateHyprlandVisibleSpecialWorkspaces monitor snapshot failed:", e);
        }

        if (event?.name === "activespecial") {
            const parts = _hyprlandRawEventParts(event, 2);
            const specialName = _normalizeSpecialWorkspaceName(parts[0]);
            const monitorName = String(parts[1] ?? Hyprland.focusedMonitor?.name ?? Hyprland.focusedWorkspace?.monitor?.name ?? "");
            if (monitorName) {
                if (specialName)
                    next[monitorName] = specialName;
                else
                    delete next[monitorName];
            }
        }

        hyprlandVisibleSpecialWorkspaces = next;
    }

    function sortHyprlandToplevelsSafe() {
        if (!Hyprland.toplevels || !Hyprland.toplevels.values)
            return [];

        const items = Array.from(Hyprland.toplevels.values);

        function _get(o, path, fb) {
            try {
                let v = o;
                for (let k of path) {
                    if (v == null)
                        return fb;
                    v = v[k];
                }
                return (v == null) ? fb : v;
            } catch (e) {
                return fb;
            }
        }

        let snap = [];
        for (let i = 0; i < items.length; i++) {
            const t = items[i];
            if (!t)
                continue;
            const addr = t.address || "";
            if (!addr)
                continue;
            const li = t.lastIpcObject || null;

            const monName = _get(li, ["monitor"], null) ?? _get(t, ["monitor", "name"], "");
            const monX = _get(t, ["monitor", "x"], Number.MAX_SAFE_INTEGER);
            const monY = _get(t, ["monitor", "y"], Number.MAX_SAFE_INTEGER);

            const wsId = _get(li, ["workspace", "id"], null) ?? _get(t, ["workspace", "id"], Number.MAX_SAFE_INTEGER);

            const at = _get(li, ["at"], null);
            let atX = (at !== null && at !== undefined && typeof at[0] === "number") ? at[0] : 1e9;
            let atY = (at !== null && at !== undefined && typeof at[1] === "number") ? at[1] : 1e9;

            const relX = Number.isFinite(monX) ? (atX - monX) : atX;
            const relY = Number.isFinite(monY) ? (atY - monY) : atY;

            snap.push({
                monKey: String(monName),
                monOrderX: Number.isFinite(monX) ? monX : Number.MAX_SAFE_INTEGER,
                monOrderY: Number.isFinite(monY) ? monY : Number.MAX_SAFE_INTEGER,
                wsId: (typeof wsId === "number") ? wsId : Number.MAX_SAFE_INTEGER,
                x: relX,
                y: relY,
                title: t.title || "",
                address: addr,
                wayland: t.wayland
            });
        }

        const groups = new Map();
        for (const it of snap) {
            const key = it.monKey + "::" + it.wsId;
            if (!groups.has(key))
                groups.set(key, []);
            groups.get(key).push(it);
        }

        let groupList = [];
        for (const [key, arr] of groups) {
            const repr = arr[0];
            groupList.push({
                key,
                monKey: repr.monKey,
                monOrderX: repr.monOrderX,
                monOrderY: repr.monOrderY,
                wsId: repr.wsId,
                items: arr
            });
        }

        groupList.sort((a, b) => {
            if (a.monOrderX !== b.monOrderX)
                return a.monOrderX - b.monOrderX;
            if (a.monOrderY !== b.monOrderY)
                return a.monOrderY - b.monOrderY;
            if (a.monKey !== b.monKey)
                return a.monKey.localeCompare(b.monKey);
            if (a.wsId !== b.wsId)
                return a.wsId - b.wsId;
            return 0;
        });

        const COLUMN_THRESHOLD = 48;
        const JITTER_Y = 6;

        let ordered = [];
        for (const g of groupList) {
            const arr = g.items;

            const xs = arr.map(it => it.x).filter(x => Number.isFinite(x)).sort((a, b) => a - b);
            let colCenters = [];
            if (xs.length > 0) {
                for (const x of xs) {
                    if (colCenters.length === 0) {
                        colCenters.push(x);
                    } else {
                        const last = colCenters[colCenters.length - 1];
                        if (x - last >= COLUMN_THRESHOLD) {
                            colCenters.push(x);
                        }
                    }
                }
            } else {
                colCenters = [0];
            }

            for (const it of arr) {
                let bestCol = 0;
                let bestDist = Number.POSITIVE_INFINITY;
                for (let ci = 0; ci < colCenters.length; ci++) {
                    const d = Math.abs(it.x - colCenters[ci]);
                    if (d < bestDist) {
                        bestDist = d;
                        bestCol = ci;
                    }
                }
                it._col = bestCol;
            }

            arr.sort((a, b) => {
                if (a._col !== b._col)
                    return a._col - b._col;

                const dy = a.y - b.y;
                if (Math.abs(dy) > JITTER_Y)
                    return dy;

                if (a.title !== b.title)
                    return a.title.localeCompare(b.title);
                if (a.address !== b.address)
                    return a.address.localeCompare(b.address);
                return 0;
            });

            ordered.push.apply(ordered, arr);
        }
        return ordered.map(x => {
            if (!x.wayland)
                return null;
            x.wayland.address = x.address;
            return x.wayland;
        }).filter(w => w !== null && w !== undefined);
    }

    function filterCurrentWorkspace(toplevels, screen) {
        if (isHyprland)
            return filterHyprlandCurrentWorkspaceSafe(toplevels, screen);
        if (isKwin)
            return KwinService.filterCurrentWorkspace(toplevels);
        return toplevels;
    }

    readonly property string toplevelKey: {
        return "address";
    }

    function toplevelPlacement(toplevel) {
        if (!toplevel)
            return {
                "workspace": "",
                "output": ""
            };
        if (isHyprland) {
            const workspace = WindowModel.hyprlandToplevelFor(Array.from(Hyprland.toplevels?.values || []), toplevel)?.workspace;
            return {
                "workspace": workspace?.name ?? "",
                "output": workspace?.monitor?.name ?? ""
            };
        }
        return {
            "workspace": "",
            "output": toplevel.screens?.[0]?.name ?? ""
        };
    }

    function fullscreenToplevelOnScreen(screenOrName) {
        const screenName = _screenName(screenOrName);
        if (!screenName || !DToplevels.toplevels?.values)
            return false;

        const toplevels = DToplevels.toplevels.values;
        for (let i = 0; i < toplevels.length; i++) {
            const toplevel = toplevels[i];
            if (toplevel?.fullscreen && toplevel.activated && _toplevelOnScreen(toplevel, screenName))
                return true;
        }
        return false;
    }

    function filterCurrentDisplay(toplevels, screenName) {
        if (!toplevels || toplevels.length === 0 || !screenName)
            return toplevels;
        if (isHyprland)
            return filterHyprlandCurrentDisplaySafe(toplevels, screenName);
        return toplevels.filter(t => _toplevelOnScreen(t, screenName));
    }

    function _screenName(screenOrName) {
        if (typeof screenOrName === "string")
            return screenOrName;
        return screenOrName?.name ?? "";
    }

    function _toplevelOnScreen(toplevel, screenName) {
        if (!toplevel || !screenName)
            return false;
        const screens = toplevel.screens;
        if (!screens)
            return false;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i]?.name === screenName)
                return true;
        }
        return false;
    }

    function _hyprlandToplevelMapped(hyprToplevel) {
        if (!hyprToplevel)
            return false;
        if (hyprToplevel.mapped === false)
            return false;
        const ipcMapped = hyprToplevel.lastIpcObject?.mapped;
        if (ipcMapped === false)
            return false;
        if (hyprToplevel.hidden === true)
            return false;
        const ipcHidden = hyprToplevel.lastIpcObject?.hidden;
        if (ipcHidden === true)
            return false;
        return true;
    }

    readonly property var specialWorkspaceNames: {
        if (!isHyprland)
            return [];
        const names = ["special"];
        for (const ws of Hyprland.workspaces?.values || []) {
            if (!WorkspaceModel.hyprlandSpecial(ws))
                continue;
            const name = WorkspaceModel.hyprlandSpecialDisplayName(ws.name ?? "");
            if (!names.includes(name))
                names.push(name);
        }
        return names;
    }

    function hyprlandAddressFor(window) {
        return isHyprland ? (_hyprlandToplevelFor(window)?.address ?? "") : "";
    }

    // IPC callers pass Hyprland's own names, prefixed or not
    function _scratchpadName(name) {
        const bare = WorkspaceModel.hyprlandSpecialDisplayName(String(name ?? ""));
        return !bare || bare === "special" ? "special" : bare;
    }

    function toggleSpecialWorkspace(name) {
        if (!isHyprland)
            return;
        const bare = _scratchpadName(name);
        HyprlandService.toggleSpecial(bare === "special" ? "" : bare);
    }

    function _hyprlandToplevelFor(window) {
        if (!window)
            return null;
        const byAddress = typeof window === "string";
        for (const t of Hyprland.toplevels?.values || []) {
            if (byAddress ? t.address === window : t.wayland === window)
                return t;
        }
        return null;
    }

    function windowScratchpadName(window) {
        if (!isHyprland)
            return "";
        const t = _hyprlandToplevelFor(window);
        const ws = String(t?.lastIpcObject?.workspace?.name || t?.workspace?.name || "");
        return WorkspaceModel.hyprlandSpecialName(ws) ? WorkspaceModel.hyprlandSpecialDisplayName(ws) : "";
    }

    // "+0" is Hyprland's own way out but resolves against the focused monitor, so prefer the window's monitor when known
    function moveWindowOutOfSpecial(window) {
        const t = _hyprlandToplevelFor(window);
        if (!t?.address)
            return;
        const target = t.monitor?.activeWorkspace;
        HyprlandService.moveToWorkspace(target?.name ? WorkspaceModel.hyprlandSelector(target) : "+0", t.address, true);
    }

    function moveWindowToSpecial(window, name) {
        const address = hyprlandAddressFor(window);
        if (!address)
            return;
        const bare = _scratchpadName(name);
        HyprlandService.moveToWorkspace(bare === "special" ? "special" : "special:" + bare, address, false);
    }

    function hyprlandVisibleSpecialWorkspaceOnScreen(screenOrName) {
        const screenName = _screenName(screenOrName);
        if (!isHyprland || !screenName)
            return "";
        hyprlandVisibleSpecialWorkspaces;
        const trackedName = hyprlandVisibleSpecialWorkspaces[screenName] ?? "";
        if (trackedName)
            return trackedName;
        try {
            const monitor = Hyprland.monitors?.values?.find(m => m.name === screenName);
            return _specialWorkspaceNameFromMonitor(monitor);
        } catch (e) {
            return "";
        }
    }

    // Workspace moves can land before Hyprland announces the monitor and before the Wayland
    // output reaches us, so re-read both models once the screen set settles (#3133)
    function refreshHyprlandMonitorLayout() {
        if (!isHyprland)
            return;
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        HyprlandService.refreshWorkspaceRules();
    }

    function _screenForName(screenOrName) {
        if (screenOrName && typeof screenOrName !== "string")
            return screenOrName;
        const screenName = _screenName(screenOrName);
        if (!screenName)
            return null;
        const screens = Quickshell.screens || [];
        for (let i = 0; i < screens.length; i++) {
            if (screens[i]?.name === screenName)
                return screens[i];
        }
        return null;
    }

    function frameConfiguredForScreen(screenOrName) {
        if (!FrameTransitionState.effectiveFrameEnabled)
            return false;
        const screen = _screenForName(screenOrName);
        if (!screen || !SettingsData.isScreenInPreferences(screen, SettingsData.frameScreenPreferences))
            return false;
        return true;
    }

    function frameWindowVisibleForScreen(screenOrName) {
        return frameConfiguredForScreen(screenOrName);
    }

    function overviewActiveOnScreen(screenOrName) {
        return false;
    }

    function usesConnectedFrameChromeForScreen(screenOrName) {
        return FrameTransitionState.effectiveConnectedFrameModeActive && frameWindowVisibleForScreen(screenOrName);
    }

    function canShareConnectedFrameChromeForScreen(screenOrName) {
        if (!usesConnectedFrameChromeForScreen(screenOrName))
            return false;
        if (!isHyprland)
            return true;

        const screenName = _screenName(screenOrName);
        const monitor = Hyprland.monitors.values.find(m => m.name === screenName);
        const specialWorkspace = monitor?.lastIpcObject?.specialWorkspace?.name;
        const workspace = specialWorkspace ? Hyprland.workspaces.values.find(w => w.name === specialWorkspace) : monitor?.activeWorkspace;
        if (!workspace)
            return true;
        return !workspace.toplevels.values.some(t => t.lastIpcObject?.fullscreen === 2);
    }

    // Connected mode renders the bar inside the frame surface.
    function frameHostsSurfacesForScreen(screenOrName) {
        return FrameTransitionState.effectiveConnectedFrameModeActive && frameConfiguredForScreen(screenOrName);
    }

    // A surface set to the overlay layer cannot live inside the frame's single top-layer window,
    // so it stays a standalone window (which resolves itself onto the overlay layer) even in connected mode.
    function frameHostsBarForConfig(screenOrName, barConfig) {
        return frameHostsSurfacesForScreen(screenOrName) && !(barConfig?.useOverlayLayer ?? false);
    }

    function frameHostsDockForConfig(screenOrName, dockConfig) {
        return !!dockConfig && frameHostsSurfacesForScreen(screenOrName) && !dockConfig.useOverlayLayer;
    }

    function frameHostsDockForScreen(screenOrName) {
        return SettingsData.dockConfigsForScreen(screenOrName).some(config => frameHostsDockForConfig(screenOrName, config));
    }

    function framePeerSurfacesUseOverlayForScreen(screenOrName) {
        return frameWindowVisibleForScreen(screenOrName);
    }

    function hyprlandToplevelOverlapsDockEdge(hyprToplevel, screenName, dockPosition, dockThickness, screenWidth, screenHeight) {
        if (!hyprToplevel?.lastIpcObject || !screenName)
            return false;
        const monName = hyprToplevel.monitor?.name ?? hyprToplevel.lastIpcObject?.monitor ?? "";
        if (monName && monName !== screenName)
            return false;
        const ipc = hyprToplevel.lastIpcObject;
        const at = ipc.at;
        const size = ipc.size;
        if (!at || !size)
            return false;
        const monX = hyprToplevel.monitor?.x ?? 0;
        const monY = hyprToplevel.monitor?.y ?? 0;
        const winX = at[0] - monX;
        const winY = at[1] - monY;
        const winW = size[0];
        const winH = size[1];
        switch (dockPosition) {
        case SettingsData.Position.Top:
            return winY < dockThickness;
        case SettingsData.Position.Bottom:
            return winY + winH > screenHeight - dockThickness;
        case SettingsData.Position.Left:
            return winX < dockThickness;
        case SettingsData.Position.Right:
            return winX + winW > screenWidth - dockThickness;
        default:
            return false;
        }
    }

    function _hyprlandDockOverlap(screenName, dockPosition, dockThickness, screenWidth, screenHeight) {
        if (!isHyprland || !screenName || !Hyprland.toplevels?.values)
            return false;

        const filtered = filterCurrentWorkspace(sortedToplevels, screenName);
        for (let i = 0; i < filtered.length; i++) {
            const toplevel = filtered[i];
            let hyprToplevel = null;
            for (const t of Hyprland.toplevels.values) {
                if (t.wayland === toplevel) {
                    hyprToplevel = t;
                    break;
                }
            }
            if (hyprlandToplevelOverlapsDockEdge(hyprToplevel, screenName, dockPosition, dockThickness, screenWidth, screenHeight))
                return true;
        }

        const visibleSpecialWorkspace = hyprlandVisibleSpecialWorkspaceOnScreen(screenName);
        if (!visibleSpecialWorkspace)
            return false;

        for (const hyprToplevel of Hyprland.toplevels.values) {
            const wsName = _normalizeSpecialWorkspaceName(hyprToplevel.workspace?.name ?? hyprToplevel.lastIpcObject?.workspace?.name ?? "");
            if (wsName !== visibleSpecialWorkspace)
                continue;
            if (!_hyprlandToplevelMapped(hyprToplevel))
                continue;
            if (hyprlandToplevelOverlapsDockEdge(hyprToplevel, screenName, dockPosition, dockThickness, screenWidth, screenHeight))
                return true;
        }
        return false;
    }

    function _windowAlive(toplevel) {
        if (!toplevel)
            return false;
        const alive = DToplevels.toplevels?.values;
        return !!alive && Array.from(alive).some(t => t === toplevel);
    }

    function _retainedWindow(screenName, previous) {
        if (!_windowAlive(previous))
            return null;
        return previous;
    }

    function activeWindowForScreen(screenName, previous, includeLastFocused) {
        const active = DToplevels.activeToplevel;
        if (!active)
            return _retainedWindow(screenName, previous);
        if (!screenName || filterCurrentDisplay([active], screenName)?.length > 0)
            return active;
        return _windowAlive(previous) ? previous : null;
    }

    function windowPid(toplevel) {
        if (!toplevel)
            return 0;
        switch (compositor) {
        case "hyprland":
            return WindowModel.hyprlandWindowPid(Array.from(Hyprland.toplevels?.values || []), toplevel);
        default:
            return toplevel.pid || 0;
        }
    }

    function windowOnActiveWorkspace(screenName, toplevel, includeLastFocused) {
        switch (compositor) {
        case "hyprland":
            if (!Hyprland.toplevels)
                return false;
            try {
                return WindowModel.hyprlandWindowOnActiveWorkspace(Array.from(Hyprland.toplevels.values), Hyprland.focusedWorkspace, toplevel);
            } catch (e) {
                return false;
            }
        default:
            return true;
        }
    }

    function windowsHideBar(screenName, position, thickness, screenWidth, screenHeight) {
        switch (compositor) {
        case "hyprland":
            return filterCurrentWorkspace(sortedToplevels, screenName).length > 0;
        default:
            return false;
        }
    }

    function windowsOverlapDock(screenName, position, thickness, screenWidth, screenHeight) {
        switch (compositor) {
        case "hyprland":
            return _hyprlandDockOverlap(screenName, position, thickness, screenWidth, screenHeight);
        default:
            return false;
        }
    }

    function maximizedWindowOnScreen(screenName) {
        switch (compositor) {
        case "hyprland":
            return filterCurrentWorkspace(sortedToplevels, screenName).some(t => t?.maximized);
        default:
            return false;
        }
    }

    function specialWorkspaceName(toplevel) {
        switch (compositor) {
        case "hyprland":
            if (!toplevel || !Hyprland.toplevels)
                return "";
            return WindowModel.hyprlandSpecialWorkspaceName(Array.from(Hyprland.toplevels.values), toplevel);
        default:
            return "";
        }
    }

    function filterHyprlandCurrentDisplaySafe(toplevels, screenName) {
        if (!toplevels || toplevels.length === 0 || !Hyprland.toplevels)
            return toplevels;

        let monitorWindows = new Set();
        try {
            const hy = Array.from(Hyprland.toplevels.values);
            for (const t of hy) {
                const mon = _get(t, ["monitor", "name"], "");
                if (mon === screenName && t.wayland)
                    monitorWindows.add(t.wayland);
            }
        } catch (e) {}

        return toplevels.filter(w => monitorWindows.has(w));
    }

    function _workspaceKeyOf(ws) {
        return ws ? (WorkspaceModel.hyprlandKey(ws) || null) : null;
    }

    function filterHyprlandCurrentWorkspaceSafe(toplevels, screenName) {
        if (!toplevels || toplevels.length === 0 || !Hyprland.toplevels)
            return toplevels;

        let currentWorkspaceId = null;
        try {
            if (Hyprland.monitors) {
                const monitor = Hyprland.monitors.values.find(m => m.name === screenName);
                if (monitor)
                    currentWorkspaceId = _workspaceKeyOf(_get(monitor, ["activeWorkspace"], null));
            }

            if (currentWorkspaceId === null) {
                const hy = Array.from(Hyprland.toplevels.values);
                for (const t of hy) {
                    const mon = _get(t, ["monitor", "name"], "");
                    const wsId = _workspaceKeyOf(_get(t, ["workspace"], null));
                    const active = !!_get(t, ["activated"], false);
                    if (mon === screenName && wsId !== null) {
                        if (active) {
                            currentWorkspaceId = wsId;
                            break;
                        }
                        if (currentWorkspaceId === null)
                            currentWorkspaceId = wsId;
                    }
                }
            }

            if (currentWorkspaceId === null && Hyprland.workspaces) {
                const wss = Array.from(Hyprland.workspaces.values);
                const focusedId = _workspaceKeyOf(Hyprland.focusedWorkspace);
                for (const ws of wss) {
                    const monName = _get(ws, ["monitor", "name"], "");
                    const wsId = _workspaceKeyOf(ws);
                    if (monName === screenName && wsId !== null) {
                        if (focusedId !== null && wsId === focusedId) {
                            currentWorkspaceId = wsId;
                            break;
                        }
                        if (currentWorkspaceId === null)
                            currentWorkspaceId = wsId;
                    }
                }
            }
        } catch (e) {
            log.warn("workspace snapshot failed:", e);
        }

        if (currentWorkspaceId === null)
            return toplevels;

        let map = new Map();
        try {
            const hy = Array.from(Hyprland.toplevels.values);
            for (const t of hy) {
                const wsId = _workspaceKeyOf(_get(t, ["workspace"], null));
                if (t && t.wayland && wsId !== null)
                    map.set(t.wayland, wsId);
            }
        } catch (e) {}

        return toplevels.filter(w => map.get(w) === currentWorkspaceId);
    }

    // Primary detection asks the kernel which process owns the $WAYLAND_DISPLAY
    // socket — the compositor quickshell is actually connected to. Env vars like
    // HYPRLAND_INSTANCE_SIGNATURE can leak into the
    // systemd user environment from previous sessions and lie. Unset
    // WAYLAND_DISPLAY falls back to "wayland-0", mirroring wl_display_connect.
    // /proc/net/unix: field 6 is state (01 = listening), 7 inode, 8 bound path.
    // The BSDs have no /proc/net; sockstat(1) -l -u lists listening unix
    // sockets as USER COMMAND PID FD PROTO LOCAL-ADDRESS.
    function detectCompositor() {
        const procScript = 'sock="${WAYLAND_DISPLAY:-wayland-0}"; case "$sock" in /*) ;; *) sock="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/$sock" ;; esac; inode=$(awk -v p="$sock" \'$8 == p && $6 == 1 {print $7; exit}\' /proc/net/unix); [ -n "$inode" ] || exit 1; fd=$(find /proc/[0-9]*/fd/ -mindepth 1 -maxdepth 1 -lname "socket:\\[$inode\\]" 2>/dev/null | head -n1); [ -n "$fd" ] || exit 1; pid="${fd#/proc/}"; cat "/proc/${pid%%/*}/comm"';
        const sockstatScript = 'sock="${WAYLAND_DISPLAY:-wayland-0}"; case "$sock" in /*) ;; *) sock="${XDG_RUNTIME_DIR:-/var/run/user/$(id -u)}/$sock" ;; esac; sockstat -l -u | awk -v p="$sock" \'$6 == p {print $2; exit}\'';
        const script = Qt.platform.os === "unix" ? sockstatScript : procScript;
        Proc.runCommand("waylandSocketOwner", ["sh", "-c", script], (output, exitCode) => {
            const comm = (exitCode === 0 && output) ? output.trim().toLowerCase() : "";
            const name = _compositorNameFromComm(comm);
            if (name) {
                _applyCompositor(name);
                log.info("Detected", name, "from Wayland socket owner:", comm);
                return;
            }
            if (comm)
                log.info("Unrecognized Wayland socket owner:", comm, "- falling back to env detection");
            _detectFromEnv(0);
        }, 0, 3000);
    }

    function _compositorNameFromComm(comm) {
        switch (comm) {
        case "hyprland":
            return "hyprland";
        case "kwin_wayland":
            return "kwin";
        default:
            return "";
        }
    }

    function _applyCompositor(name) {
        isHyprland = name === "hyprland";
        isKwin = name === "kwin";
        compositor = name;
        compositorDetected = true;
        Qt.callLater(seedDmsWindowFloatingRule);
    }

    function seedDmsWindowFloatingRule() {
        if (!supportsWindowRules)
            return;
        if (SettingsData.shellWindowsFloatingSeeded.includes(compositor)) {
            refreshDmsWindowFloatingRule(true);
            return;
        }
        const seeded = compositor;
        setDmsWindowFloatingRule(true, () => {
            SettingsData.set("shellWindowsFloatingSeeded", SettingsData.shellWindowsFloatingSeeded.concat([seeded]));
            refreshDmsWindowFloatingRule(true);
        });
    }

    function refreshDmsWindowFloatingRule(ensureOpaque) {
        if (!supportsWindowRules)
            return;
        const procId = ensureOpaque ? "dms-windowrule-startup-list" : "dms-windowrule-float-list";
        Proc.runCommand(procId, [Proc.dmsBin, "config", "windowrules", "list", compositor], (output, exitCode) => {
            if (exitCode !== 0) {
                if (ensureOpaque)
                    log.warn("failed to list window rules:", exitCode, output);
                return;
            }
            let rules;
            try {
                rules = JSON.parse(output.trim()).rules || [];
            } catch (e) {
                log.warn("failed to parse window rules", e);
                return;
            }
            // Each rule write rewrites the whole rules file, so writes must not overlap.
            syncDmsWindowFloatingRule(rules, () => {
                if (ensureOpaque)
                    ensureDmsOpaqueRule(rules);
            });
        });
    }

    function dmsRuleMatchesCurrentAppId(rule) {
        return (rule.matchCriteria?.appId || "").includes("alpe_shell");
    }

    function syncDmsWindowFloatingRule(rules, onDone) {
        const rule = rules.find(rule => rule.id === dmsFloatingRuleId && rule.enabled !== false && rule.actions?.openFloating === true);
        dmsWindowFloatingActive = rule !== undefined;
        if (!rule || dmsRuleMatchesCurrentAppId(rule)) {
            onDone?.();
            return;
        }
        setDmsWindowFloatingRule(true, onDone);
    }

    function reloadAfterWindowRuleWrite() {
        if (isHyprland)
            HyprlandService.reloadConfig();
    }

    function setDmsRule(id, rule, onDone) {
        if (!supportsWindowRules)
            return;
        const args = rule ? ["add", compositor, JSON.stringify(Object.assign({
                "id": id,
                "enabled": true
            }, rule))] : ["remove", compositor, id];
        Proc.runCommand("dms-windowrule-" + id, [Proc.dmsBin, "config", "windowrules", ...args], (output, exitCode) => {
            if (exitCode !== 0) {
                log.warn("failed to update the shell window rule", id, exitCode, output);
                return;
            }
            reloadAfterWindowRuleWrite();
            onDone?.();
        });
    }

    function setDmsWindowFloatingRule(enabled, onDone) {
        setDmsRule(dmsFloatingRuleId, enabled ? {
            "name": "Alpe: Fenster der Shell schwebend",
            "matchCriteria": {
                "appId": "^io\\.github\\.alpe_shell\\.Alpe$"
            },
            "actions": {
                "openFloating": true
            }
        } : null, () => {
            dmsWindowFloatingActive = enabled;
            onDone?.();
        });
    }

    function ensureDmsOpaqueRule(rules) {
        if (rules.some(rule => rule.id === dmsOpaqueRuleId && dmsRuleMatchesCurrentAppId(rule)))
            return;
        // DMS windows are translucent via client alpha; Hyprland's opaque keeps that alpha, force_rgbx would drop it.
        let actions;
        if (isHyprland)
            actions = {
                "opaque": true
            };
        else
            return;
        setDmsRule(dmsOpaqueRuleId, {
            "name": "Alpe: Fenster der Shell deckend",
            "matchCriteria": {
                "appId": "^io\\.github\\.alpe_shell\\.Alpe$"
            },
            "actions": actions
        });
    }

    // Fallback when the socket owner can't be resolved (no ss, unrecognized
    // comm). Same priority order as before, but every candidate must prove
    // liveness; a dead socket/PID falls through to the next candidate instead
    // of winning on a stale env var.
    function _envDetectionCandidates() {
        const runtimeDir = Quickshell.env("XDG_RUNTIME_DIR") || "";
        return [
            {
                name: "hyprland",
                present: !!hyprlandSignature,
                test: ["test", "-S", runtimeDir + "/hypr/" + hyprlandSignature + "/.socket.sock"],
                detail: "HYPRLAND_INSTANCE_SIGNATURE " + hyprlandSignature
            },
            {
                name: "kwin",
                present: !!Quickshell.env("KDE_FULL_SESSION"),
                test: ["pgrep", "-x", "kwin_wayland"],
                detail: "KDE_FULL_SESSION"
            }
        ];
    }

    function _detectFromEnv(index) {
        const candidates = _envDetectionCandidates();
        for (let i = index; i < candidates.length; i++) {
            const c = candidates[i];
            if (!c.present)
                continue;
            const next = i + 1;
            Proc.runCommand(c.name + "SocketCheck", c.test, (output, exitCode) => {
                if (exitCode !== 0) {
                    log.warn(c.detail, "is set but not alive, skipping");
                    _detectFromEnv(next);
                    return;
                }
                const name = c.resolve ? c.resolve() : c.name;
                _applyCompositor(name);
                log.info("Detected", name, "via", c.detail);
            }, 0);
            return;
        }
        _applyCompositor("unknown");
        log.warn("No compositor detected");
    }

    function powerOffMonitors() {
        if (isHyprland)
            return HyprlandService.dpmsOff();
        if (isKwin) {
            // Alpe: KWin schaltet über sein eigenes DPMS-Protokoll; kscreen-doctor spricht es.
            Quickshell.execDetached(["kscreen-doctor", "--dpms", "off"]);
            return;
        }
        if (outputPowerAvailable) {
            setOutputPower(false);
            return;
        }
        log.warn("Cannot power off monitors, unknown compositor");
    }

    function powerOnMonitors() {
        if (isHyprland)
            return HyprlandService.dpmsOn();
        if (isKwin) {
            Quickshell.execDetached(["kscreen-doctor", "--dpms", "on"]);
            return;
        }
        if (outputPowerAvailable) {
            setOutputPower(true);
            return;
        }
        log.warn("Cannot power on monitors, unknown compositor");
    }

    function _hyprlandWorkspaceState() {
        return {
            get workspaces() {
                return Hyprland.workspaces?.values || [];
            },
            get monitors() {
                return Hyprland.monitors?.values || [];
            },
            get focusedWorkspace() {
                return Hyprland.focusedWorkspace;
            },
            get toplevels() {
                return Array.from(Hyprland.toplevels?.values || []);
            },
            get workspaceRules() {
                return HyprlandService.workspaceRules;
            },
            get visibleSpecials() {
                return root.hyprlandVisibleSpecialWorkspaces;
            }
        };
    }

    function _workspaceKey(record) {
        switch (compositor) {
        case "hyprland":
            return WorkspaceModel.hyprlandKey(record);
        default:
            return record.id;
        }
    }

    function workspacesForScreen(screenName, followFocus, options) {
        switch (compositor) {
        case "hyprland":
            return WorkspaceModel.hyprlandWorkspacesForScreen(_hyprlandWorkspaceState(), screenName, followFocus, options.occupiedOnly, options.minCount, options.showSpecial);
        default:
            return [];
        }
    }

    function currentWorkspaceKey(screenName, followFocus) {
        switch (compositor) {
        case "hyprland":
            return WorkspaceModel.hyprlandCurrentId(_hyprlandWorkspaceState(), screenName, followFocus);
        default:
            return 1;
        }
    }

    function isCurrentWorkspace(record, currentKey) {
        if (!record)
            return false;
        switch (compositor) {
        case "hyprland":
            return record.special === true ? record.active === true : WorkspaceModel.hyprlandKey(record) === currentKey;
        default:
            return _workspaceKey(record) === currentKey;
        }
    }

    function activeWorkspaceForScreen(screenName) {
        switch (compositor) {
        case "hyprland":
            return WorkspaceModel.hyprlandActiveWorkspace(_hyprlandWorkspaceState(), screenName);
        default:
            return null;
        }
    }

    function windowsOnWorkspace(record) {
        if (!record || record.placeholder)
            return [];
        switch (compositor) {
        case "hyprland":
            return WorkspaceModel.hyprlandWindowsOnWorkspace(sortedToplevels, record, Array.from(Hyprland.toplevels?.values || []));
        default:
            return [];
        }
    }

    function workspaceOccupied(record) {
        if (!record || record.placeholder)
            return false;
        switch (compositor) {
        case "hyprland":
            return WorkspaceModel.hyprlandWorkspaceOccupied(Array.from(Hyprland.toplevels?.values || []), record);
        default:
            return false;
        }
    }

    function workspaceAppsActive(record, currentKey) {
        switch (compositor) {
        case "hyprland":
            return isCurrentWorkspace(record, currentKey);
        default:
            return record.id === currentKey;
        }
    }

    function workspaceUrgent(record, loadedUrgent) {
        return record?.urgent === true;
    }

    function loadWorkspaceUrgent(record) {
        return record?.urgent ?? false;
    }

    function switchToWorkspace(record, screenName, moveToOutput) {
        if (!record || record.placeholder)
            return;
        switch (compositor) {
        case "hyprland":
            if (record.special === true) {
                // togglespecialworkspace acts on the focused monitor, so a pill on another monitor's bar focuses that monitor first
                if (screenName && screenName !== Hyprland.focusedMonitor?.name)
                    HyprlandService.focusMonitor(screenName);
                HyprlandService.toggleSpecial(record.name === "special" ? "" : record.name);
                return;
            }
            if (moveToOutput && record.output && record.output !== moveToOutput)
                HyprlandService.moveWorkspaceToMonitor(WorkspaceModel.hyprlandSelector(record), moveToOutput);
            HyprlandService.focusWorkspace(WorkspaceModel.hyprlandSelector(record));
            return;
        }
    }

    function stepWorkspace(workspaces, currentKey, direction) {
        if (workspaces.length < 2)
            return;
        const index = workspaces.findIndex(ws => ws && _workspaceKey(ws) === currentKey);
        switchToWorkspace(WorkspaceModel.neighbor(workspaces, Math.max(index, 0), direction));
    }

    function scrollWorkspace(screenName, followFocus, showAllTags, direction) {
        switch (compositor) {
        case "hyprland":
            {
                const state = _hyprlandWorkspaceState();
                stepWorkspace(WorkspaceModel.hyprlandScrollWorkspaces(state, screenName, followFocus), WorkspaceModel.hyprlandScrollCurrentId(state, screenName), direction);
                return;
            }
        }
    }

    readonly property bool canStepWindowFocus: compositor === "hyprland"

    function stepWindowFocus(screenName, direction) {
        switch (compositor) {
        case "hyprland":
            if (screenName && screenName !== Hyprland.focusedMonitor?.name)
                HyprlandService.focusMonitor(screenName);
            HyprlandService.cycleWindow(direction > 0);
            return true;
        default:
            return false;
        }
    }

    function focusWindow(windowId) {
        switch (compositor) {
        case "hyprland":
            HyprlandService.focusWindow(windowId);
            return true;
        default:
            return false;
        }
    }

    Binding {
        target: SettingsData
        property: "activeCompositor"
        value: root.compositor
    }

    Connections {
        target: SettingsData

        function onCompositorLayoutRefreshNeeded(frame) {
            if (root.isHyprland && typeof HyprlandService !== "undefined")
                HyprlandService.generateLayoutConfig(frame);
        }

        function onBlurStrengthRefreshNeeded() {
            onCompositorLayoutRefreshNeeded(false);
        }

        function onCompositorInputRefreshNeeded() {
            if (root.isHyprland && typeof HyprlandService !== "undefined")
                HyprlandService.generateInputConfig();
        }

        function onCompositorCursorRefreshNeeded() {
            if (root.isHyprland && typeof HyprlandService !== "undefined") {
                HyprlandService.generateCursorConfig();
                return;
            }
        }
    }
}
