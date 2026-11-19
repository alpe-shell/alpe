import QtQuick
import "../../../plugins/alpeSport"
// Prueft: schmal, Spiel offen, Klick auf einen Wettbewerb in der Leiste -> Detail zu, Wettbewerb offen
Rectangle {
    width: 854; height: 664; color: "#1d2024"
    SportTab { id: tab; anchors.fill: parent; anchors.margins: 12 }
    Timer { interval: 400; running: true; onTriggered: tab.openMatch(tab.dayData.leagues.find(l => l.id === "nl").matches[0]) }
    Timer { interval: 800; running: true; onTriggered: {
        if (!tab.detailOpen) console.error("Fehler: Detail ging nicht auf");
        tab.show("league", "ger.1");
        if (tab.detailOpen || tab.view !== "league" || tab.leagueId !== "ger.1") console.error("Fehler: Detail bleibt offen");
    } }
}
