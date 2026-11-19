import QtQuick
import "../../../plugins/alpeSport"
Rectangle {
    width: 854; height: 664; color: "#1d2024"
    SportTab { id: tab; anchors.fill: parent; anchors.margins: 12 }
    Timer { interval: 400; running: true; onTriggered: { tab.show("league", "ger.1"); tab.leagueTab = "table" } }
}
