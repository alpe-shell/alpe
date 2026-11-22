import QtQuick
import qs.Common
import qs.Services
import qs.Alpe.Widgets
import qs.Modules.Plugins
import "sport.js" as S

// Alpe: Leisten-Element «Sport». Zeigt das laufende Spiel eines Favoriten (Logos, Resultat,
// Minute), auf Wunsch auch das nächste ab drei Stunden vor Beginn. Laufen mehrere, wechselt die
// Anzeige alle 8 s. Ohne passendes Spiel verschwindet das Element ganz. Ein Klick öffnet das
// Dashboard beim Spieldetail. Die Daten kommen vom Hintergrunddienst (SportDaemon.qml).
PluginComponent {
    id: root

    readonly property var matches: PluginService.globalVars?.alpeSport?.favoriteMatches ?? []
    readonly property bool barLive: pluginData.barLive ?? true
    readonly property bool barUpcoming: pluginData.barUpcoming ?? true
    property date now: new Date()
    property int cycle: 0

    readonly property var candidates: {
        if (!barLive)
            return [];
        const live = matches.filter(m => m.status === "live");
        if (live.length > 0 || !barUpcoming)
            return live;
        const soon = matches.filter(m => {
            if (m.status !== "pre" || !m.start || m.timeUnknown)
                return false;
            const minutes = (new Date(m.start).getTime() - now.getTime()) / 60000;
            return minutes <= 180 && minutes > -30;
        });
        return soon.slice(0, 1);
    }
    readonly property var shown: candidates.length > 0 ? candidates[cycle % candidates.length] : null
    readonly property bool isLive: shown?.status === "live"
    readonly property string centre: shown ? (isLive ? (shown.home.score || "0") + ":" + (shown.away.score || "0") : S.clock(shown.start)) : ""
    readonly property string minute: isLive ? S.shortLabel(shown.label) : ""

    function sync() {
        setVisibilityOverride(shown !== null);
    }

    onShownChanged: sync()
    Component.onCompleted: sync()

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Timer {
        interval: 8000
        running: root.candidates.length > 1
        repeat: true
        onTriggered: root.cycle += 1
    }

    pillClickAction: (x, y, width, section, screen) => {
        if (!root.shown)
            return;
        PluginService.setGlobalVar("alpeSport", "openMatch", {
            "match": root.shown
        });
        PopoutService.openDankDash("plugin_alpeSport", x, y, width, section, screen);
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.isLive
                width: 6
                height: 6
                radius: 3
                color: Theme.success

                SequentialAnimation on opacity {
                    running: root.isLive
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.35
                        duration: 900
                    }
                    NumberAnimation {
                        to: 1
                        duration: 900
                    }
                }
            }

            Crest {
                anchors.verticalCenter: parent.verticalCenter
                team: root.shown?.home ?? null
                size: root.iconSize
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.centre
                font.pixelSize: root.textSize
                font.weight: Font.Bold
                font.features: {
                    "tnum": 1
                }
                color: Theme.widgetTextColor ?? Theme.surfaceText
            }

            Crest {
                anchors.verticalCenter: parent.verticalCenter
                team: root.shown?.away ?? null
                size: root.iconSize
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: text !== ""
                text: root.minute
                font.pixelSize: Math.max(9, root.textSize - 2)
                font.weight: Font.DemiBold
                color: Theme.success
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 2

            Crest {
                anchors.horizontalCenter: parent.horizontalCenter
                team: root.shown?.home ?? null
                size: root.iconSize
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.centre
                font.pixelSize: Math.max(9, root.textSize - 2)
                font.weight: Font.Bold
                color: root.isLive ? Theme.success : (Theme.widgetTextColor ?? Theme.surfaceText)
            }

            Crest {
                anchors.horizontalCenter: parent.horizontalCenter
                team: root.shown?.away ?? null
                size: root.iconSize
            }
        }
    }
}
