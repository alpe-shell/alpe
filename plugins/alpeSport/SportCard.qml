import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import "sport.js" as S

// Karte fuer die Übersicht: heute zuerst die Spiele der Favoriten, dann laufende, dann die naechsten.
// Ein Klick oeffnet den Sport-Tab.
DashCardComponent {
    id: root

    property var dayData: null
    readonly property var favorites: pluginData.favorites ?? []
    property var leagues: []
    readonly property var enabledIds: S.ordered(leagues, pluginData.order).filter(l => {
        const value = options[S.optionKey(l.id)];
        return value === undefined ? l["default"] !== false : value === true || value === "true";
    }).map(l => l.id)
    readonly property var picks: {
        const all = [];
        for (const league of dayData?.leagues ?? []) {
            if (enabledIds.indexOf(league.id) < 0)
                continue;
            for (const m of league.matches)
                all.push(m);
        }
        const rank = m => (S.isFavoriteMatch(m, favorites) ? 0 : 3) + (m.status === "live" ? 0 : m.status === "pre" ? 1 : 2);
        return all.sort((a, b) => rank(a) - rank(b) || (a.start < b.start ? -1 : 1));
    }
    readonly property int liveCount: picks.filter(m => m.status === "live").length
    readonly property int rows: Math.max(1, Math.floor((height - 2 * pad - 30) / 30))

    clickable: true

    function load() {
        if (leagues.length === 0)
            query.run(["leagues"]);
        else
            query.run(["day", "--leagues", enabledIds.join(",")]);
    }

    onLiveChanged: {
        if (live)
            load();
    }
    onEnabledIdsChanged: {
        if (live && leagues.length > 0)
            load();
    }
    Component.onCompleted: {
        if (live)
            load();
    }

    SportQuery {
        id: query

        onResult: (data, args) => {
            if (args[0] === "leagues") {
                if ((data?.leagues?.length ?? 0) > 0)
                    root.leagues = data.leagues;
                return;
            }
            if (data && !data.error)
                root.dayData = data;
        }
    }

    Timer {
        interval: root.liveCount > 0 ? 30000 : 180000
        repeat: true
        running: root.live
        onTriggered: {
            if (!query.busy)
                root.load();
        }
    }

    Item {
        anchors.fill: parent

        Row {
            id: head

            width: parent.width
            height: 24
            spacing: Theme.spacingS

            DIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "sports_soccer"
                size: 18
                color: root.accentColor
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Sport heute"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                color: root.contentColor
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.liveCount > 0
                width: liveLabel.implicitWidth + 12
                height: 18
                radius: 9
                color: Theme.success

                StyledText {
                    id: liveLabel

                    anchors.centerIn: parent
                    text: root.liveCount + " live"
                    font.pixelSize: Theme.fontSizeSmall - 1
                    font.weight: Font.Bold
                    color: Theme.surface
                }
            }
        }

        Column {
            anchors.top: head.bottom
            anchors.topMargin: Theme.spacingXS
            width: parent.width
            spacing: 0

            Repeater {
                model: root.picks.slice(0, root.rows)

                Item {
                    id: line

                    required property var modelData
                    readonly property bool live: modelData.status === "live"

                    width: parent.width
                    height: 30

                    Crest {
                        id: homeCrest

                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        team: line.modelData.home
                        size: 18
                    }

                    StyledText {
                        anchors.left: homeCrest.right
                        anchors.leftMargin: Theme.spacingXS
                        anchors.right: score.left
                        anchors.rightMargin: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: line.modelData.home.short || line.modelData.home.name
                        font.pixelSize: Theme.fontSizeSmall + 1
                        color: root.contentColor
                    }

                    Column {
                        id: score

                        anchors.centerIn: parent
                        width: 58

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: S.centerText(line.modelData)
                            font.pixelSize: Theme.fontSizeSmall + 1
                            font.weight: S.hasScore(line.modelData) ? Font.Bold : Font.Normal
                            font.features: {
                                "tnum": 1
                            }
                            color: line.live ? Theme.success : root.contentColor
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: line.live
                            text: S.shortLabel(line.modelData.label)
                            font.pixelSize: Theme.fontSizeSmall - 3
                            color: Theme.success
                        }
                    }

                    StyledText {
                        anchors.left: score.right
                        anchors.leftMargin: Theme.spacingXS
                        anchors.right: awayCrest.left
                        anchors.rightMargin: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                        text: line.modelData.away.short || line.modelData.away.name
                        font.pixelSize: Theme.fontSizeSmall + 1
                        color: root.contentColor
                    }

                    Crest {
                        id: awayCrest

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        team: line.modelData.away
                        size: 18
                    }
                }
            }

            StyledText {
                visible: root.picks.length === 0
                topPadding: Theme.spacingS
                text: root.dayData ? "Heute keine Spiele" : "Wird geladen …"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }
    }
}
