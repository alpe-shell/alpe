import QtQuick
import "../../../plugins/alpeSport"
// Alpe: Reiter Statistik eines Wettbewerbs, Klick auf den Torschützenkönig öffnet das Spielerblatt.
Rectangle {
    width: 1224; height: 760; color: "#1d2024"
    SportTab { id: tab; anchors.fill: parent; anchors.margins: 12; rowBudget: 7 }
    function child(name) { return tab.children.find(c => c.toString().indexOf(name) === 0) }
    Timer { interval: 300; running: true; onTriggered: { tab.show("league", "ger.1"); tab.leagueTab = "stats"; tab.loadStats() } }
    Timer { interval: 800; running: true; onTriggered: {
        const stats = tab.statsData["ger.1"];
        if (!stats || stats.categories.length !== 2) console.error("Fehler: Bestenliste fehlt");
        tab.openPlayer(Object.assign({}, stats.categories[0].rows[0].player, {"league": "ger.1", "team": stats.categories[0].rows[0].team}));
    } }
    Timer { interval: 1150; running: true; onTriggered: {
        const sheet = child("PlayerSheet");
        if (!sheet.visible || (sheet.values?.splits ?? []).length !== 2) console.error("Fehler: Spielerblatt " + sheet.visible + " " + JSON.stringify(sheet.failure));
    } }
}
