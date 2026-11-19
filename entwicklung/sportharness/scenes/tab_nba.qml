import QtQuick
import "../../../plugins/alpeSport"
Rectangle {
    width: 1124; height: 784; color: "#1d2024"
    SportTab { id: tab; anchors.fill: parent; anchors.margins: 12; rowBudget: 7 }
    Timer { interval: 500; running: true; onTriggered: tab.openMatch(tab.dayData.leagues.find(l => l.id === "nba").matches[0]) }
    Timer { interval: 1000; running: true; onTriggered: { const d = tab.children.find(c => c.toString().indexOf("MatchDetail") === 0); d.tab = "box" } }
}
