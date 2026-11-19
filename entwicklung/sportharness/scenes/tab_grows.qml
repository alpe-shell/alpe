import QtQuick
import qs.Modules.DDash
import "../../../plugins/alpeSport"
// Alpe: Das Dash ist so breit wie DashMetrics.panelColumnsFor (wie DDashPopout). Zu 6 × 8,
// Spieldetail öffnen macht es zwei Spalten breiter (8 × 8); schliessen macht es wieder schmal. Im Bearbeiten-Modus und mit ausgeschalteter Einstellung bleibt es schmal.
// SHOT_DELAY=690 nimmt das Bild mit offenem Detail auf.
Rectangle {
    id: dash
    readonly property int columns: DashMetrics.panelColumnsFor("plugin_alpeSport")
    width: DashMetrics.contentWidthFor(false, columns) + 24; height: 784; color: "#1d2024"
    SportTab { id: tab; anchors.fill: parent; anchors.margins: 12; rowBudget: 8 }
    property real before: 0
    function check(ok, text) { if (!ok) console.error("Fehler: " + text) }
    function match() { return tab.dayData.leagues.find(l => l.id === "ger.dfb_pokal").matches.find(m => m.id === "3") }
    Timer { interval: 400; running: true; onTriggered: {
        dash.before = tab.width;
        dash.check(dash.columns === 6 && !tab.wide, "Ausgangslage 6 Spalten, schmal");
        dash.check(tab.implicitHeight === DashMetrics.heightForRows(8), "zu 8 Zeilen hoch");
        tab.openMatch(dash.match());
    } }
    Timer { interval: 700; running: true; onTriggered: {
        dash.check(tab.wide, "Detail steht neben der Liste");
        dash.check(dash.columns === 8, "mit Detail 8 Spalten, nicht " + dash.columns);
        dash.check(tab.implicitHeight === DashMetrics.heightForRows(8), "8 Zeilen hoch, offen wie zu");
        tab.closeDetail();
    } }
    Timer { interval: 1000; running: true; onTriggered: {
        dash.check(dash.columns === 6, "geschlossen wieder 6 Spalten, nicht " + dash.columns);
        tab.editMode = true;
        tab.openMatch(dash.match());
        dash.check(dash.columns === 6, "im Bearbeiten-Modus keine Verbreiterung");
        tab.editMode = false;
        dash.check(dash.columns > 6, "nach dem Bearbeiten wieder breit");
        tab.setData("growDetail", false);
        dash.check(dash.columns === 6 && !tab.wide, "Einstellung aus: schmal, Detail überlagert");
        tab.setData("growDetail", true);
        tab.closeDetail();
        dash.check(dash.columns === 6, "am Ende wieder schmal");
    } }
}
