import QtQuick
import qs.Common
import qs.Alpe.Widgets
import "sport.js" as S

// Karte eines Wettbewerbs in der Tagesansicht: Kopf mit Logo und Name, darunter die Spiele.
Rectangle {
    id: root

    property var league: ({})
    property var matches: []
    property var favorites: []
    property string selectedId: ""

    readonly property string round: {
        if ((league.id ?? "") === "")
            return "";
        const rounds = [...new Set((matches || []).map(m => m.round).filter(r => !!r))];
        return rounds.length === 1 ? rounds[0] : "";
    }

    signal openLeague(string leagueId)
    signal openMatch(var match)

    implicitHeight: column.implicitHeight + Theme.spacingS * 2
    radius: Theme.cornerRadius
    color: Theme.surfaceContainerHigh

    Column {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingS
        spacing: 0

        Item {
            width: parent.width
            height: 36

            LeagueIcon {
                id: icon

                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter
                league: root.league
                size: 20
            }

            Column {
                anchors.left: icon.right
                anchors.leftMargin: Theme.spacingS
                anchors.right: more.left
                anchors.rightMargin: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter
                spacing: -2

                StyledText {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.league.name ?? ""
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    color: Theme.surfaceText
                }

                StyledText {
                    width: parent.width
                    elide: Text.ElideRight
                    text: [root.league.country, root.round].filter(x => !!x).join(" · ")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            Rectangle {
                id: more

                visible: (root.league.id ?? "") !== ""
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: moreRow.implicitWidth + Theme.spacingM
                height: 28
                radius: height / 2
                color: moreMouse.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.08) : "transparent"

                Row {
                    id: moreRow

                    anchors.centerIn: parent
                    spacing: 2

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.league.kind === "league" ? "Tabelle" : "Spiele"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.primary
                    }

                    AlpeIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "chevron_right"
                        size: 16
                        color: Theme.primary
                    }
                }

                MouseArea {
                    id: moreMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openLeague(root.league.id)
                }
            }
        }

        Repeater {
            model: root.matches

            MatchRow {
                required property var modelData

                width: column.width
                match: modelData
                favorite: S.isFavoriteMatch(modelData, root.favorites)
                selected: root.selectedId === modelData.league + "/" + modelData.id
                onClicked: root.openMatch(modelData)
            }
        }
    }
}
