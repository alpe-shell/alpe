import QtQuick
import qs.Common
import qs.Alpe.Widgets

// Alpe: Bestenlisten eines Wettbewerbs (Tore, Vorlagen; NBA Punkte, Rebounds, Assists;
// National League Skorer, Tore, Assists, Plus/Minus, Torhüter). Breit zwei Spalten.
Item {
    id: root

    property var stats: null            // Antwort von «sport stats ID»
    property var favorites: []
    property string sport: "soccer"

    readonly property var categories: stats?.categories ?? []
    readonly property int columns: width >= 640 ? 2 : 1
    readonly property real cardWidth: (width - (columns - 1) * Theme.spacingM) / columns

    signal openPlayer(var player)

    implicitHeight: grid.implicitHeight

    Flow {
        id: grid

        width: root.width
        spacing: Theme.spacingM

        Repeater {
            model: root.categories

            Rectangle {
                id: card

                required property var modelData

                width: root.cardWidth
                height: cardColumn.implicitHeight + Theme.spacingS * 2
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Column {
                    id: cardColumn

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingS

                    StyledText {
                        leftPadding: Theme.spacingS
                        topPadding: 2
                        bottomPadding: Theme.spacingXS
                        text: card.modelData.title
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.DemiBold
                        color: Theme.surfaceText
                    }

                    Repeater {
                        model: card.modelData.rows

                        Item {
                            id: row

                            required property var modelData
                            required property int index
                            readonly property bool favorite: (root.favorites ?? []).indexOf(root.sport + ":" + (modelData.team?.id ?? "")) >= 0

                            width: cardColumn.width
                            height: 38

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.cornerRadiusS
                                color: rowMouse.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.06) : row.favorite ? Theme.withAlpha(Theme.primary, 0.08) : "transparent"
                            }

                            StyledText {
                                id: rank

                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 26
                                horizontalAlignment: Text.AlignHCenter
                                text: row.modelData.rank
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: row.index === 0 ? Font.Bold : Font.Normal
                                color: row.index === 0 ? Theme.primary : Theme.surfaceVariantText
                            }

                            Crest {
                                id: crest

                                anchors.left: rank.right
                                anchors.leftMargin: Theme.spacingXS
                                anchors.verticalCenter: parent.verticalCenter
                                team: row.modelData.team
                                size: 22
                            }

                            Column {
                                anchors.left: crest.right
                                anchors.leftMargin: Theme.spacingS
                                anchors.right: value.left
                                anchors.rightMargin: Theme.spacingS
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: -1

                                StyledText {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: row.modelData.player.name
                                    font.pixelSize: Theme.fontSizeSmall + 1
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                    text: [row.modelData.team?.name ?? "", row.modelData.sub ?? ""].filter(x => x !== "").join("  ·  ")
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    color: Theme.surfaceVariantText
                                }
                            }

                            Rectangle {
                                id: value

                                anchors.right: parent.right
                                anchors.rightMargin: Theme.spacingXS
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.max(34, valueText.implicitWidth + Theme.spacingS * 2)
                                height: 24
                                radius: 12
                                color: row.index === 0 ? Theme.primary : Theme.withAlpha(Theme.surfaceText, 0.06)

                                StyledText {
                                    id: valueText

                                    anchors.centerIn: parent
                                    text: row.modelData.value
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                    font.features: {
                                        "tnum": 1
                                    }
                                    color: row.index === 0 ? Theme.onPrimary : Theme.surfaceText
                                }
                            }

                            MouseArea {
                                id: rowMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !!row.modelData.player?.id
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.openPlayer(Object.assign({}, row.modelData.player, {
                                    "league": root.stats?.league?.id ?? "",
                                    "team": row.modelData.team
                                }))
                            }
                        }
                    }
                }
            }
        }
    }
}
