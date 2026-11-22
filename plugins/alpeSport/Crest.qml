import QtQuick
import qs.Common
import qs.Alpe.Widgets

// Vereinslogo; ohne Logo (National League, kleine Cup-Gegner) ein rundes Abzeichen mit Kuerzel.
Item {
    id: root

    property var team: null
    property real size: 24

    readonly property string logo: team?.logo ?? ""
    readonly property bool showLogo: logo !== "" && image.status !== Image.Error
    readonly property color fill: team?.color || Theme.surfaceContainerHighest
    readonly property bool lightFill: (0.299 * fill.r + 0.587 * fill.g + 0.114 * fill.b) > 0.62
    readonly property string abbr: (team?.abbr || team?.short || team?.name || "?").slice(0, 4)

    implicitWidth: size
    implicitHeight: size
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
        visible: root.showLogo
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.showLogo
        radius: width / 2
        color: root.fill
        border.width: root.team?.accent ? Math.max(1, Math.round(root.size / 16)) : 0
        border.color: root.team?.accent || "transparent"

        StyledText {
            anchors.centerIn: parent
            width: parent.width - 2
            horizontalAlignment: Text.AlignHCenter
            text: root.abbr
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 6
            font.pixelSize: Math.max(7, Math.round(root.size * (root.abbr.length > 3 ? 0.3 : 0.36)))
            font.weight: Font.Bold
            color: !root.team?.color ? Theme.surfaceText : root.lightFill ? "#111111" : "#ffffff"
        }
    }
}
