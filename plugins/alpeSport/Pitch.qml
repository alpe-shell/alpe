import QtQuick
import qs.Common
import qs.DCommon.Widgets

// Spielfeld mit der Startelf (Torhueter unten, Sturm oben), wie in der Aufstellung bei FotMob.
Item {
    id: root

    property var lineup: null           // {formation, lines: [[spieler…]…], bench}
    property var team: null
    property string sport: "soccer"

    signal playerClicked(var player)

    readonly property var lines: lineup?.lines ?? []
    readonly property color shirt: team?.color || Theme.primary

    implicitHeight: width * 1.22

    Rectangle {
        id: field

        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.success, 0.10)
        border.width: 1
        border.color: Theme.withAlpha(Theme.success, 0.28)
        clip: true

        // Linien: Mittellinie oben, Strafraum unten
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: -width / 2
            width: parent.width * 0.32
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: Theme.withAlpha(Theme.success, 0.28)
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: parent.width * 0.56
            height: parent.height * 0.17
            color: "transparent"
            border.width: 1
            border.color: Theme.withAlpha(Theme.success, 0.28)
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: parent.width * 0.26
            height: parent.height * 0.07
            color: "transparent"
            border.width: 1
            border.color: Theme.withAlpha(Theme.success, 0.28)
        }
    }

    Repeater {
        model: root.lines.length

        Item {
            id: line

            required property int index
            // Linie 0 = Torhueter ganz unten
            readonly property var players: root.lines[index]
            readonly property real slot: root.height / Math.max(1, root.lines.length)

            width: root.width
            height: slot
            y: root.height - (index + 1) * slot

            Repeater {
                model: line.players.length

                Item {
                    id: spot

                    required property int index
                    readonly property var player: line.players[index]

                    width: Math.min(84, root.width / Math.max(1, line.players.length))
                    height: 54
                    x: (index + 0.5) * root.width / line.players.length - width / 2
                    y: (line.height - height) / 2

                    // Alpe: Klick zeigt die Saisonwerte des Spielers
                    MouseArea {
                        anchors.fill: parent
                        z: 10
                        enabled: !!spot.player.id
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.playerClicked(spot.player)
                    }

                    Rectangle {
                        id: dot

                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 30
                        height: 30
                        radius: 15
                        color: line.index === 0 ? Theme.surfaceContainerHighest : root.shirt
                        border.width: 2
                        border.color: Theme.withAlpha(Theme.surface, 0.6)

                        StyledText {
                            anchors.centerIn: parent
                            text: spot.player.num
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                            color: line.index === 0 ? Theme.surfaceText : "#ffffff"
                        }

                        Row {
                            anchors.left: parent.right
                            anchors.leftMargin: -6
                            anchors.top: parent.top
                            anchors.topMargin: -4
                            spacing: 1

                            Repeater {
                                model: spot.player.marks ?? []

                                Item {
                                    required property string modelData

                                    width: modelData === "goal" || modelData === "owngoal" ? 13 : 9
                                    height: 13

                                    DIcon {
                                        anchors.centerIn: parent
                                        visible: parent.modelData === "goal" || parent.modelData === "owngoal"
                                        name: "sports_soccer"
                                        size: 13
                                        color: parent.modelData === "owngoal" ? Theme.error : Theme.surfaceText
                                    }

                                    Rectangle {
                                        anchors.centerIn: parent
                                        visible: parent.modelData === "yellow" || parent.modelData === "red"
                                        width: 8
                                        height: 11
                                        radius: 1.5
                                        color: parent.modelData === "yellow" ? "#f5c518" : "#e53935"
                                    }
                                }
                            }
                        }

                        DIcon {
                            anchors.right: parent.left
                            anchors.rightMargin: -6
                            anchors.top: parent.top
                            anchors.topMargin: -4
                            visible: spot.player.subOut === true
                            name: "arrow_downward"
                            size: 13
                            color: Theme.error
                        }
                    }

                    StyledText {
                        anchors.top: dot.bottom
                        anchors.topMargin: 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: {
                            const parts = (spot.player.name || "").split(" ");
                            return parts.length > 1 ? parts.slice(1).join(" ") : spot.player.name;
                        }
                        font.pixelSize: Theme.fontSizeSmall - 1
                        color: Theme.surfaceText
                    }
                }
            }
        }
    }

    StyledText {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingS
        text: root.lineup?.formation ?? ""
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
        color: Theme.surfaceVariantText
    }

    StyledText {
        anchors.centerIn: parent
        visible: root.lines.length === 0
        text: "Aufstellung noch nicht bekannt"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }
}
