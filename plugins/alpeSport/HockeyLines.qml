import QtQuick
import qs.Common
import qs.DCommon.Widgets

// Aufstellung im Eishockey: Torhüter, dann die Blöcke (Sturm links–Mitte–rechts, Verteidigung).
// Alpe: Namen sind anklickbar (Saisonwerte).
Column {
    id: root

    property var lineup: null

    signal playerClicked(var player)

    spacing: Theme.spacingS

    function names(list) {
        return (list ?? []).filter(p => !!(p.short || p.name)).map(p => (p.num ? "#" + p.num + " " : "") + (p.short || p.name)).join("  –  ");
    }

    Rectangle {
        width: parent.width
        height: goalieColumn.implicitHeight + Theme.spacingS * 2
        radius: Theme.cornerRadiusS
        color: Theme.withAlpha(Theme.surfaceText, 0.05)
        visible: root.names(root.lineup?.goalies) !== ""

        Column {
            id: goalieColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Theme.spacingS

            StyledText {
                text: "Torhüter"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            PlayerFlow {
                width: parent.width
                players: root.lineup?.goalies ?? []
                onPlayerClicked: p => root.playerClicked(p)
            }
        }
    }

    Repeater {
        model: root.lineup?.blocks ?? []

        Rectangle {
            id: block

            required property var modelData

            width: root.width
            height: blockColumn.implicitHeight + Theme.spacingS * 2
            radius: Theme.cornerRadiusS
            color: Theme.withAlpha(Theme.surfaceText, 0.05)

            Column {
                id: blockColumn

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Theme.spacingS
                spacing: 2

                StyledText {
                    text: block.modelData.name
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Theme.primary
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: block.modelData.forwards.length > 0

                    DIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "north"
                        size: 14
                        color: Theme.surfaceVariantText
                    }

                    PlayerFlow {
                        width: parent.width - 22
                        players: block.modelData.forwards
                        onPlayerClicked: p => root.playerClicked(p)
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: block.modelData.defense.length > 0

                    DIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "shield"
                        size: 14
                        color: Theme.surfaceVariantText
                    }

                    PlayerFlow {
                        width: parent.width - 22
                        players: block.modelData.defense
                        onPlayerClicked: p => root.playerClicked(p)
                    }
                }
            }
        }
    }

    StyledText {
        visible: !!root.lineup?.coach
        text: "Trainer: " + (root.lineup?.coach ?? "")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    component PlayerFlow: Flow {
        id: flow

        property var players: []

        signal playerClicked(var player)

        spacing: 0

        Repeater {
            model: (flow.players ?? []).filter(p => !!(p.short || p.name))

            Row {
                required property var modelData
                required property int index

                StyledText {
                    visible: parent.index > 0
                    text: "  –  "
                    font.pixelSize: Theme.fontSizeSmall + 1
                    color: Theme.surfaceVariantText
                }

                PlayerName {
                    player: parent.modelData
                    text: (parent.modelData.num ? "#" + parent.modelData.num + " " : "") + (parent.modelData.short || parent.modelData.name)
                    font.pixelSize: Theme.fontSizeSmall + 1
                    onClicked: p => flow.playerClicked(p)
                }
            }
        }
    }
}
