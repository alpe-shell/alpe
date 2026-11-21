pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string desktop: (Quickshell.env("XDG_CURRENT_DESKTOP") || "").split(":")[0].toLowerCase()

    readonly property bool tiling: {
        if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE"))
            return true;

        switch (desktop) {
        case "hyprland":
            return true;
        default:
            return false;
        }
    }

    readonly property bool supportsMinimize: !tiling
}
