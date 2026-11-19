import QtQuick
import "../../../plugins/alpeSport"
Rectangle {
    width: 854; height: 664; color: "#1d2024"
    SportTab { id: tab; anchors.fill: parent; anchors.margins: 12 }
    Timer { interval: 400; running: true; onTriggered: tab.openMatch(tab.dayData.leagues.find(l => l.id === "ger.dfb_pokal").matches.find(m => m.id === "3")) }
    Timer { interval: 900; running: true; onTriggered: tab.children.find(c => c.toString().indexOf("MatchDetail") === 0).tab = "lineup" }
}
