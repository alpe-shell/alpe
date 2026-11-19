import QtQuick
import qs.Services
import "../../../plugins/alpeSport"
// Alpe: Hintergrunddienst veröffentlicht die Favoritenspiele, das Leisten-Element zeigt das
// laufende Spiel, ein Klick öffnet das Dashboard und der Sport-Tab übernimmt das Spiel.
Rectangle {
    width: 1224; height: 760; color: "#111318"
    SportDaemon { id: daemon }
    Rectangle { x: 12; y: 8; width: bar.implicitWidth + 24; height: 36; radius: 18; color: "#1d2024"
        SportWidget { id: bar; x: 12; anchors.verticalCenter: parent.verticalCenter } }
    SportTab { id: tab; x: 12; y: 56; width: 1200; height: 690; visible: false }
    Timer { interval: 2600; running: true; onTriggered: {
        const shown = PluginService.globalVars?.alpeSport?.favoriteMatches ?? [];
        if (shown.length !== 2) console.error("Fehler: Dienst hat " + shown.length + " Spiele veröffentlicht");
        if (!bar.shown || bar.shown.status !== "live" || !bar.effectiveVisible) console.error("Fehler: Leiste zeigt nichts");
        bar.click();
        if (PopoutService.dashOpened[0] !== "plugin_alpeSport") console.error("Fehler: Dashboard nicht geöffnet");
        tab.visible = true;
    } }
    Timer { interval: 3000; running: true; onTriggered: {
        if (tab.detailKey !== bar.shown.league + "/" + bar.shown.id) console.error("Fehler: Tab hat das Spiel nicht übernommen: " + tab.detailKey);
        if (PluginService.getGlobalVar("alpeSport", "openMatch", 1) !== null) console.error("Fehler: Auftrag nicht verbraucht");
    } }
}
