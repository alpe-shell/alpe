import QtQuick
import "../../../plugins/alpeSport"
// Alpe: Spieldetail mit TV-Zeile und Knopf des Streamingdienstes (Bild).
Rectangle {
    width: 1224; height: 900; color: "#1d2024"
    SportTab { id: tab; anchors.fill: parent; anchors.margins: 12; rowBudget: 8 }
    Timer { interval: 300; running: true; onTriggered: {
        tab.setData("streams", {"nl": {"name": "MySports", "url": "https://www.mysports.ch"}});
        tab.openMatch(tab.dayData.leagues.find(l => l.id === "nl").matches[0]);
    } }
    Timer { interval: 900; running: true; onTriggered: {
        const d = tab.children.find(c => c.toString().indexOf("MatchDetail") === 0);
        const f = d.children.find(c => c.toString().indexOf("AlpeFlickable") === 0);
        f.contentY = Math.max(0, f.contentHeight - f.height);
        if (!d.stream) console.error("Fehler: Streaming-Link fehlt");
    } }
}
