import QtQuick
import Quickshell.Widgets
import qs.Common
import qs.Alpe.Widgets

Item {
    id: root

    property string source: ""
    property int glyphSize: Theme.iconSizeSmall
    property bool badgeVisible: true

    readonly property var sourceAsset: ({
            "flatpak": "../../assets/package-sources/flatpak.svg",
            "snap": "../../assets/package-sources/snap.svg",
            "nix": "../../assets/package-sources/nix.svg"
        })
    // Alpe (Entscheid vom 26.11.2026): AppImage ohne fremdes Zeichen, neutrales Symbol aus der mitgelieferten
    // Symbolschrift (Material Symbols Rounded)
    readonly property var sourceGlyph: ({
            "appimage": "deployed_code"
        })

    readonly property string assetPath: sourceAsset[source] || ""
    readonly property string glyphName: sourceGlyph[source] || ""

    visible: badgeVisible && SettingsData.launcherShowSourceBadges && (assetPath.length > 0 || glyphName.length > 0)
    implicitWidth: glyphSize
    implicitHeight: glyphSize

    AlpeIcon {
        anchors.centerIn: parent
        visible: root.glyphName.length > 0
        name: root.glyphName
        size: root.glyphSize
        color: Theme.surfaceVariantText
    }

    IconImage {
        visible: root.assetPath.length > 0
        anchors.fill: parent
        source: root.assetPath ? Qt.resolvedUrl(root.assetPath) : ""
        implicitSize: root.glyphSize * 2
        backer.sourceSize: Qt.size(root.glyphSize * 2, root.glyphSize * 2)
        smooth: true
        mipmap: true
        asynchronous: true
    }
}
