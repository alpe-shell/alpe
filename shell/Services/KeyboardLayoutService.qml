pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Common
import qs.Services

Singleton {
    id: root

    property int consumers: 0
    readonly property bool active: consumers > 0
    property string _polledLayout: ""
    property var _polledNames: []
    property int _polledCount: 0
    property int _polledIndex: -1
    property string _hyprlandKeyboard: ""

    readonly property bool available: {
        switch (CompositorService.compositor) {
        case "hyprland":
            return true;
        default:
            return false;
        }
    }

    readonly property bool namesAreXkbCodes: CompositorService.compositor === "hyprland"

    readonly property var layoutNames: {
        switch (CompositorService.compositor) {
        case "hyprland":
            return _polledNames;
        default:
            return [];
        }
    }

    readonly property string currentLayout: {
        switch (CompositorService.compositor) {
        case "hyprland":
            return _polledLayout;
        default:
            return "";
        }
    }

    readonly property bool layoutKnown: currentLayout !== "" && currentLayout !== "Unknown"

    readonly property string compactLayout: {
        switch (CompositorService.compositor) {
        case "hyprland":
            return _polledNames.length > 0 ? (_polledNames[_polledIndex] ?? "") : _polledLayout;
        default:
            return currentLayout;
        }
    }

    readonly property int layoutCount: {
        switch (CompositorService.compositor) {
        case "hyprland":
            return _polledCount;
        default:
            return 0;
        }
    }

    onActiveChanged: {
        if (active)
            refresh();
    }

    Connections {
        target: CompositorService
        function onCompositorChanged() {
            if (root.active)
                root.refresh();
        }
    }

    Connections {
        target: root.active && CompositorService.isHyprland ? Hyprland : null
        enabled: root.active && CompositorService.isHyprland
        function onRawEvent(event) {
            if (event.name === "activelayout")
                root._pollHyprland();
        }
    }

    function refresh() {
        switch (CompositorService.compositor) {
        case "hyprland":
            _pollHyprland();
            return;
        }
    }

    function cycle() {
        switch (CompositorService.compositor) {
        case "hyprland":
            Quickshell.execDetached(["hyprctl", "switchxkblayout", _hyprlandKeyboard, "next"]);
            _pollHyprland();
            return;
        }
    }

    function _pollHyprland() {
        Proc.runCommand("keyboard-layout-hyprland", ["hyprctl", "-j", "devices"], (output, exitCode) => {
            if (exitCode !== 0) {
                root._applyHyprlandKeyboard(null);
                return;
            }
            try {
                root._applyHyprlandKeyboard(JSON.parse(output).keyboards.find(kb => kb.main === true));
            } catch (e) {
                root._applyHyprlandKeyboard(null);
            }
        });
    }

    function _applyHyprlandKeyboard(keyboard) {
        if (!keyboard) {
            _hyprlandKeyboard = "";
            _polledNames = [];
            _polledCount = 0;
            _polledIndex = -1;
            _polledLayout = "Unknown";
            return;
        }
        const layouts = keyboard.layout ? keyboard.layout.split(",") : [];
        const variants = (keyboard.variant ?? "").split(",");
        const index = keyboard.active_layout_index;
        _hyprlandKeyboard = keyboard.name;
        _polledCount = layouts.length;
        _polledIndex = index === undefined ? -1 : index;
        _polledNames = index === undefined ? [] : layouts.map((layout, i) => variants[i] ? layout + "-" + variants[i] : layout);
        _polledLayout = keyboard.active_keymap || "Unknown";
    }
}
