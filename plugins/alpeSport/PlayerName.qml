import QtQuick
import qs.Common
import qs.DCommon.Widgets

// Alpe: Spielername, den man anklicken kann (Saisonwerte). Ohne Kennung bloss Text.
StyledText {
    id: root

    property var player: null
    readonly property bool clickable: !!player?.id

    signal clicked(var player)

    font.underline: mouse.containsMouse && clickable
    color: mouse.containsMouse && clickable ? Theme.primary : Theme.surfaceText

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.clickable
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked(root.player)
    }
}
