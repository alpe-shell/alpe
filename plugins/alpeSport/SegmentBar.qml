import QtQuick
import qs.Common
import qs.DCommon.Widgets

// Schmale Reiter (Verlauf / Statistik / Aufstellung …) im Stil der Shell-Chips.
Row {
    id: root

    property var model: []
    property int currentIndex: 0
    property real chipHeight: 30

    signal selected(int index)

    spacing: Theme.spacingXS

    Repeater {
        model: root.model

        Rectangle {
            id: chip

            required property var modelData
            required property int index
            readonly property bool active: index === root.currentIndex

            width: label.implicitWidth + Theme.spacingL * 2
            height: root.chipHeight
            radius: height / 2
            color: active ? Theme.primaryContainer : chipMouse.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.08) : "transparent"
            border.width: active ? 0 : 1
            border.color: Theme.outlineVariant

            StyledText {
                id: label

                anchors.centerIn: parent
                text: typeof chip.modelData === "string" ? chip.modelData : chip.modelData.text
                font.pixelSize: Theme.fontSizeSmall
                font.weight: chip.active ? Font.DemiBold : Font.Normal
                color: chip.active ? Theme.onPrimaryContainer : Theme.surfaceText
            }

            MouseArea {
                id: chipMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected(chip.index)
            }
        }
    }
}
