import QtQuick
import qs.Common
import qs.DCommon.Widgets

// Logo des Wettbewerbs (ESPN), sonst ein Symbol der Sportart.
Item {
    id: root

    property var league: ({})
    property real size: 20
    property color tint: Theme.surfaceVariantText

    readonly property string logo: league?.logo ?? ""

    width: size
    height: size

    Image {
        id: image

        anchors.fill: parent
        source: root.logo !== "" ? "file://" + root.logo : ""
        sourceSize.width: Math.ceil(root.size * 2)
        sourceSize.height: Math.ceil(root.size * 2)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        asynchronous: true
        visible: root.logo !== "" && status !== Image.Error
    }

    DIcon {
        anchors.centerIn: parent
        visible: !image.visible
        name: root.league?.kind === "national" ? "flag" : root.league?.sport === "hockey" ? "sports_hockey" : root.league?.sport === "basketball" ? "sports_basketball" : root.league?.kind === "cup" ? "emoji_events" : "sports_soccer"
        size: root.size
        color: root.tint
    }
}
