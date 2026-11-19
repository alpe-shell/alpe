import QtQuick
import qs.Common
import qs.DCommon.Widgets

// NBA-Boxscore eines Teams: Starter zuerst, dann die Bank.
Column {
    id: root

    property var box: null

    signal playerClicked(var player)

    readonly property var columns: box?.columns ?? []
    readonly property var rows: box?.rows ?? []
    readonly property real cellWidth: Math.max(34, Math.min(46, (width - 140) / Math.max(1, columns.length)))

    spacing: 0

    Item {
        width: parent.width
        height: 26

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: "Spieler"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: root.columns

                StyledText {
                    required property string modelData

                    width: root.cellWidth
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.pixelSize: Theme.fontSizeSmall - 1
                    color: Theme.surfaceVariantText
                }
            }
        }
    }

    Repeater {
        model: root.rows

        Item {
            id: line

            required property var modelData
            required property int index
            readonly property bool firstBench: index > 0 && !modelData.starter && root.rows[index - 1].starter

            width: root.width
            height: 28

            Rectangle {
                anchors.fill: parent
                radius: Theme.cornerRadiusXS
                color: rowMouse.containsMouse && rowMouse.enabled ? Theme.withAlpha(Theme.surfaceText, 0.06) : "transparent"
            }

            MouseArea {
                id: rowMouse

                anchors.fill: parent
                hoverEnabled: true
                enabled: !!line.modelData.id
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.playerClicked(line.modelData)
            }

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                visible: line.firstBench
                color: Theme.outlineVariant
            }

            StyledText {
                anchors.left: parent.left
                anchors.right: cells.left
                anchors.rightMargin: Theme.spacingXS
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: line.modelData.name + (line.modelData.pos ? "  " + line.modelData.pos : "")
                font.pixelSize: Theme.fontSizeSmall + 1
                font.weight: line.modelData.starter ? Font.Medium : Font.Normal
                color: Theme.surfaceText
            }

            Row {
                id: cells

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: line.modelData.cells

                    StyledText {
                        required property string modelData
                        required property int index

                        width: root.cellWidth
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: root.columns[index] === "PTS" ? Font.Bold : Font.Normal
                        font.features: {
                            "tnum": 1
                        }
                        color: root.columns[index] === "PTS" ? Theme.surfaceText : Theme.surfaceTextMedium
                    }
                }
            }
        }
    }
}
