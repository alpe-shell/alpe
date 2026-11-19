import QtQuick
import "../../../plugins/alpeSport"
// Alpe: Spieler in der Aufstellung anklicken (breit: Blatt anstelle des Details) und Streaming-Knopf.
Rectangle {
    width: 1224; height: 760; color: "#1d2024"
    SportTab { id: tab; anchors.fill: parent; anchors.margins: 12; rowBudget: 7 }
    function child(name) { return tab.children.find(c => c.toString().indexOf(name) === 0) }
    Timer { interval: 300; running: true; onTriggered: {
        tab.setData("streams", {"ger.dfb_pokal": {"name": "Sky", "url": "https://sky.ch"}, "nl": {"name": "MySports", "url": "https://www.mysports.ch"}});
        tab.openMatch(tab.dayData.leagues.find(l => l.id === "nl").matches[0]);
    } }
    Timer { interval: 800; running: true; onTriggered: {
        const d = child("MatchDetail");
        if (!d.stream || d.stream.name !== "MySports") console.error("Fehler: Streaming-Link fehlt");
        d.playerClicked({"id": "Genoni Leonardo", "name": "Genoni Leonardo"});
    } }
    Timer { interval: 1200; running: true; onTriggered: {
        const sheet = child("PlayerSheet");
        if (!sheet.visible || sheet.player.league !== "nl" || !sheet.values) console.error("Fehler: Spielerblatt aus dem Detail");
    } }
}
