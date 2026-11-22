pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property string source: "auto"
    property string shellSettingsPath: ""
    property string family: ""
    property string monoFamily: ""
    property string displayFamily: ""
    property int weight: Font.Normal
    property real scale: 1.0

    property var shellSettings: null
    readonly property bool backendReachable: shellSettings !== null
    readonly property bool followingShell: source === "auto" && backendReachable

    readonly property string fontFamily: {
        if (followingShell)
            return shellSettings.fontFamily || Fonts.sans;
        if (source === "system")
            return Fonts.system;
        return family || Fonts.sans;
    }
    readonly property string monoFontFamily: {
        if (followingShell)
            return shellSettings.monoFontFamily || Fonts.mono;
        if (source === "system")
            return Fonts.systemMono;
        return monoFamily || Fonts.mono;
    }
    readonly property string displayFontFamily: {
        if (followingShell)
            return shellSettings.displayFontFamily || Fonts.display;
        if (source === "system")
            return Fonts.display;
        return displayFamily || Fonts.display;
    }
    readonly property int fontWeight: followingShell ? (shellSettings.fontWeight ?? Font.Normal) : weight
    readonly property real fontScale: followingShell ? (shellSettings.fontScale || 1.0) : scale

    FileView {
        id: shellSettingsView
        path: root.source === "auto" ? root.shellSettingsPath : ""
        blockLoading: false
        watchChanges: true
        printErrors: false

        onLoaded: {
            try {
                root.shellSettings = JSON.parse(shellSettingsView.text()) || null;
            } catch (e) {
                root.shellSettings = null;
            }
        }
        onFileChanged: shellSettingsView.reload()
        onLoadFailed: root.shellSettings = null
    }
}
