import QtQuick
import "../../../plugins/alpeSport"
Rectangle {
    width: 854; height: 664; color: "#1d2024"
    SportTab { id: tab; anchors.fill: parent; anchors.margins: 12 }
    Timer { interval: 400; running: true; onTriggered: tab.show("league", "sui.hockey") }
    Timer { interval: 900; running: true; onTriggered: {
        const m = tab.currentLeagueData.matches.find(x => x.id === "20261108-CZE-SUI");
        if (!m) console.error("Fehler: Länderspiel fehlt");
        tab.openMatch(m);
        if (!tab.detailData || tab.detailData.match.id !== m.id) console.error("Fehler: Detail ohne Daten");
    } }
}
