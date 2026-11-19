import QtQuick
import "../../../plugins/alpeSport"
// «Ganze Tabelle ›» im Spieldetail: Wettbewerb öffnet mit dem Reiter Tabelle (schmal und breit).
Item {
    width: 1200; height: 700
    SportTab { id: narrow; width: 830; height: 640 }
    SportTab { id: wide; x: 0; width: 1150; height: 640; visible: false }
    function detailOf(tab) { return tab.children.find(c => c.toString().indexOf("MatchDetail") === 0) }
    Timer { interval: 400; running: true; onTriggered: {
        const m = narrow.dayData.leagues.find(l => l.id === "ger.dfb_pokal").matches[0];
        narrow.show("league", "nl");                          // schon auf einer Liga-Seite (wie im Bild)
        narrow.openMatch(m); wide.openMatch(m);
        detailOf(narrow).openTable("ger.1"); detailOf(wide).openTable("ger.1");
        if (narrow.view !== "league" || narrow.leagueId !== "ger.1" || narrow.leagueTab !== "table" || narrow.detailOpen) console.error("Fehler: schmal " + narrow.view + " " + narrow.leagueTab);
        if (wide.view !== "league" || wide.leagueTab !== "table" || !wide.detailOpen) console.error("Fehler: breit " + wide.view + " " + wide.leagueTab + " " + wide.detailOpen);
    } }
}
