import QtQuick
import "../../../plugins/alpeSport"
// Alpe: Bestenlisten der National League (schmal: eine Spalte) und Torhüter-Blatt.
Rectangle {
    width: 860; height: 760; color: "#1d2024"
    SportTab { id: tab; anchors.fill: parent; anchors.margins: 12; rowBudget: 7 }
    Timer { interval: 300; running: true; onTriggered: { tab.show("league", "nl"); tab.leagueTab = "stats"; tab.loadStats() } }
    Timer { interval: 900; running: true; onTriggered: {
        const cats = tab.statsData["nl"]?.categories ?? [];
        if (cats.map(c => c.title).join(",") !== "Skorer,Tore,Assists,Plus/Minus,Torhüter") console.error("Fehler: NL " + cats.map(c => c.title));
    } }
}
