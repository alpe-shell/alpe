import QtQuick
import qs.Common
import qs.Alpe.Widgets

// Alpe: Saisonwerte eines Spielers (Klick in Aufstellung, Topspielern, Boxscore oder
// Bestenliste). Liegt wie das Spieldetail rechts bzw. schmal über der Liste.
Item {
    id: root

    property var player: null           // {id, name, league, team?}
    property bool overlay: false
    property var values: null
    property string failure: ""

    readonly property var info: values?.player ?? null
    readonly property var team: info?.team?.name ? info.team : (player?.team ?? null)
    readonly property bool open: player !== null

    signal closeRequested

    function load() {
        values = null;
        failure = "";
        if (player?.id && player?.league)
            query.run(["player", player.league, String(player.id)]);
    }

    onPlayerChanged: if (player)
        load()

    SportQuery {
        id: query

        onResult: (answer, args) => {
            if (!root.player || args[2] !== String(root.player.id))
                return;
            if (!answer || answer.error) {
                root.failure = answer?.error ?? "Keine Antwort";
                return;
            }
            root.values = answer;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: root.overlay ? Theme.surfaceContainer : Theme.surfaceContainerHigh

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            onWheel: wheel => wheel.accepted = true
        }
    }

    AlpeFlickable {
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        contentWidth: width
        contentHeight: body.implicitHeight + Theme.spacingM
        clip: true

        Column {
            id: body

            width: parent.width
            spacing: Theme.spacingM

            Item {
                width: parent.width
                height: 32

                AlpeActionButton {
                    id: back

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "arrow_back"
                    iconColor: Theme.surfaceText
                    tooltipText: "Zurück"
                    onClicked: root.closeRequested()
                }

                StyledText {
                    anchors.left: back.right
                    anchors.leftMargin: Theme.spacingXS
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Spieler"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                AlpeIcon {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    visible: query.busy
                    name: "progress_activity"
                    size: 18
                    color: Theme.surfaceVariantText

                    RotationAnimation on rotation {
                        running: query.busy
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                    }
                }
            }

            // Kopf: Rückennummer, Name, Team
            Row {
                width: parent.width
                spacing: Theme.spacingM

                Rectangle {
                    width: 56
                    height: 56
                    radius: 28
                    color: root.team?.color || Theme.primaryContainer

                    StyledText {
                        anchors.centerIn: parent
                        visible: !!root.info?.jersey
                        text: root.info?.jersey ?? ""
                        font.pixelSize: Theme.fontSizeXLarge
                        font.weight: Font.Bold
                        color: root.team?.color ? "#ffffff" : Theme.onPrimaryContainer
                    }

                    AlpeIcon {
                        anchors.centerIn: parent
                        visible: !root.info?.jersey
                        name: "person"
                        size: 30
                        filled: true
                        color: root.team?.color ? "#ffffff" : Theme.onPrimaryContainer
                    }
                }

                Column {
                    width: parent.width - 56 - Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    StyledText {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: root.info?.name || root.player?.name || ""
                        font.pixelSize: Theme.fontSizeLarge + 2
                        font.weight: Font.DemiBold
                        color: Theme.surfaceText
                    }

                    Row {
                        spacing: Theme.spacingXS
                        visible: !!root.team

                        Crest {
                            anchors.verticalCenter: parent.verticalCenter
                            team: root.team
                            size: 18
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.team?.name ?? ""
                            font.pixelSize: Theme.fontSizeSmall + 1
                            color: Theme.surfaceVariantText
                        }
                    }
                }
            }

            // Steckbrief als Chips
            Flow {
                width: parent.width
                spacing: Theme.spacingXS
                visible: chips.count > 0

                Repeater {
                    id: chips

                    model: {
                        const i = root.info;
                        if (!i)
                            return [];
                        return [["sports", i.position], ["cake", i.age ? i.age + " Jahre" : ""], ["flag", i.nation], ["height", i.height]].filter(c => !!c[1]);
                    }

                    Rectangle {
                        required property var modelData

                        width: chipRow.implicitWidth + Theme.spacingM * 2
                        height: 28
                        radius: 14
                        color: Theme.withAlpha(Theme.surfaceText, 0.06)

                        Row {
                            id: chipRow

                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            AlpeIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: parent.parent.modelData[0]
                                size: 14
                                color: Theme.surfaceVariantText
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.parent.modelData[1]
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }
                        }
                    }
                }
            }

            StyledText {
                width: parent.width
                visible: root.failure !== "" || (!root.values && !query.busy && root.open)
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: root.failure || "Keine Werte"
                font.pixelSize: Theme.fontSizeSmall + 1
                color: root.failure ? Theme.error : Theme.surfaceVariantText
            }

            StyledText {
                width: parent.width
                visible: query.busy && !root.values
                horizontalAlignment: Text.AlignHCenter
                text: "Saisonwerte werden geladen …"
                font.pixelSize: Theme.fontSizeSmall + 1
                color: Theme.surfaceVariantText
            }

            // Saisonwerte je Wettbewerb
            Repeater {
                model: root.values?.splits ?? []

                Rectangle {
                    id: split

                    required property var modelData
                    readonly property int perRow: body.width >= 380 ? 4 : 3

                    width: body.width
                    height: splitColumn.implicitHeight + Theme.spacingM
                    radius: Theme.cornerRadiusS
                    color: Theme.withAlpha(Theme.surfaceText, 0.04)

                    Column {
                        id: splitColumn

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Theme.spacingS
                        spacing: Theme.spacingS

                        StyledText {
                            width: parent.width
                            elide: Text.ElideRight
                            text: split.modelData.title
                            font.pixelSize: Theme.fontSizeSmall + 1
                            font.weight: Font.DemiBold
                            color: Theme.surfaceText
                        }

                        Flow {
                            width: parent.width

                            Repeater {
                                model: split.modelData.cells

                                Column {
                                    required property var modelData

                                    width: splitColumn.width / split.perRow
                                    bottomPadding: Theme.spacingXS

                                    StyledText {
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        text: parent.modelData.value
                                        font.pixelSize: Theme.fontSizeLarge
                                        font.weight: Font.DemiBold
                                        font.features: {
                                            "tnum": 1
                                        }
                                        color: Theme.surfaceText
                                    }

                                    StyledText {
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        text: parent.modelData.label
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        color: Theme.surfaceVariantText
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledText {
                width: parent.width
                visible: (root.values?.splits ?? []).length > 0
                wrapMode: Text.WordWrap
                text: root.player?.league === "nl" ? "Quelle: Swiss Ice Hockey Federation" : "Quelle: ESPN"
                font.pixelSize: Theme.fontSizeSmall - 1
                color: Theme.surfaceVariantText
            }
        }
    }
}
