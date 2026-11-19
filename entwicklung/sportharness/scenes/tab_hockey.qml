import QtQuick
import "../../../plugins/alpeSport"
Rectangle {
    width: 1124; height: 784; color: "#1d2024"
    SportTab { id: tab; anchors.fill: parent; anchors.margins: 12; rowBudget: 7 }
    Timer { interval: 500; running: true; onTriggered: tab.openMatch(tab.dayData.leagues.find(l => l.id === "nl").matches[0]) }
}
