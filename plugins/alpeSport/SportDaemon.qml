import QtQuick
import qs.Common
import qs.Services
import qs.Modules.Plugins
import qs.Modules.DDash
import "sport.js" as S

// Alpe: Hintergrunddienst des Sport-Plugins. Läuft, solange das Plugin an ist, auch bei
// geschlossenem Dashboard. Ruft «sport watch» auf: Das Hilfsprogramm kennt den Spielplan der
// Favoriten von heute, lädt nur Wettbewerbe nach, in denen ein Favorit gerade spielt oder bald
// beginnt, und schickt Mitteilungen bei Tor, Beginn und Schluss. Die Spiele landen in der
// globalen Variable «favoriteMatches» (für das Leisten-Element).
//
// Takt: laufendes Spiel → Einstellung «Laufende Spiele nachladen» (Vorgabe 30 s); sonst sagt das
// Hilfsprogramm, wann es wieder etwas zu tun gibt (höchstens alle 30 Minuten). Ohne Favoriten
// oder mit allem aus ruht der Dienst ganz.
PluginComponent {
    id: root

    readonly property var favorites: pluginData.favorites ?? []
    readonly property bool notifyGoals: pluginData.notifyGoals ?? true
    readonly property bool notifyStart: pluginData.notifyStart ?? true
    readonly property bool notifyEnd: pluginData.notifyEnd ?? true
    readonly property bool barLive: pluginData.barLive ?? true
    readonly property int liveSeconds: Math.max(15, Math.min(300, Number(pluginData.refreshLive) || 30))
    readonly property var kinds: [notifyGoals ? "goal" : "", notifyStart ? "start" : "", notifyEnd ? "end" : ""].filter(k => k !== "")
    readonly property bool wanted: favorites.length > 0 && (kinds.length > 0 || barLive)

    property var leagues: []
    readonly property var enabledIds: S.ordered(leagues, pluginData.order).filter(l => {
        const stored = DashRegistry.storedOptions ? DashRegistry.storedOptions("plugin_alpeSport") : {};
        const key = S.optionKey(l.id);
        return key in stored ? stored[key] === true || stored[key] === "true" : l["default"] !== false;
    }).map(l => l.id)

    function publish(matches) {
        PluginService.setGlobalVar("alpeSport", "favoriteMatches", matches);
    }

    function poll() {
        if (!wanted) {
            publish([]);
            return;
        }
        if (leagues.length === 0) {
            leaguesQuery.run(["leagues"]);
            return;
        }
        watchQuery.run(["watch", "--favorites", favorites.join(","), "--leagues", enabledIds.join(","), "--notify", kinds.join(",")]);
    }

    // Änderungen an Favoriten oder Schaltern gesammelt übernehmen
    onFavoritesChanged: settle.restart()
    onKindsChanged: settle.restart()
    onEnabledIdsChanged: settle.restart()
    onWantedChanged: settle.restart()
    Component.onCompleted: settle.restart()

    Timer {
        id: settle

        interval: 1500
        onTriggered: root.poll()
    }

    Timer {
        id: next

        interval: 60000
        onTriggered: root.poll()
    }

    SportQuery {
        id: leaguesQuery

        onResult: (answer, args) => {
            if ((answer?.leagues?.length ?? 0) > 0) {
                root.leagues = answer.leagues;
                root.poll();
            } else {
                next.interval = 120000;
                next.restart();
            }
        }
    }

    SportQuery {
        id: watchQuery

        timeoutMs: 60000

        onResult: (answer, args) => {
            if (!answer || answer.error) {
                next.interval = 120000;              // Quelle oder Netz weg: in zwei Minuten wieder
            } else {
                root.publish(answer.matches ?? []);
                next.interval = (answer.hot ? root.liveSeconds : Math.max(60, answer.next ?? 1800)) * 1000;
            }
            if (root.wanted)
                next.restart();
        }
    }

    // Nach dem Aufwachen aus dem Ruhezustand sofort nachsehen statt den Rest des Takts abzuwarten
    Connections {
        target: SessionService
        ignoreUnknownSignals: true

        function onSessionResumed() {
            settle.restart();
        }
    }
}
