import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
Item {
    function state(grips) { return JSON.stringify({payload: {data: [JSON.stringify({v: 1, seq: 1, current: "d1", activeOutput: "DP-2", active: "", desktops: [{id: "d1", name: "1", number: 1}], windows: [{id: "{a}", appId: "kitty", title: "t", output: "DP-2", desktops: ["d1"]}], grips: grips})]}, member: "state"}) }
    readonly property var two: [{id: "{a}", output: "DP-2", x: 100, y: 100, w: 900, h: 8, gx: 100, gy: 100}, {id: "{a}", output: "DP-2", x: 100, y: 88, w: 900, h: 12, gx: 100, gy: 88}]
    function cmds() { return Quickshell.calls.map(c => c[c.length - 1]).join(",") }
    Component.onCompleted: {
        console.log("aktiv", KwinService.active, "gripEnabled", KwinService.gripEnabled, "| Lader läuft mit Einstellungen:", Registry.procs.filter(p => p.command.length > 5).map(p => p.command[p.command.length - 1]).join(" "));
        KwinService._handleLine(state(two));
        console.log("A sofort:", KwinService.grips.length, KwinService.visibleGrips.length, "verbunden", KwinService.connected, "Fenster", KwinService.toplevels.length);
    }
    Timer { interval: 100; running: true; onTriggered: {
        console.log("B nach Veröffentlichung:", KwinService.visibleGrips.length);
        KwinService.gripBegin();
        KwinService._handleLine(state(null));
        KwinService._handleLine(state([]));
        step2.start();
    } }
    Timer { id: step2; interval: 100; onTriggered: {
        console.log("C gehalten: sichtbar bleibt", KwinService.visibleGrips.length, "(gemeldet", KwinService.grips.length + ")", "| Befehle:", cmds());
        KwinService.gripEnd();
        step3.start();
    } }
    Timer { id: step3; interval: 100; onTriggered: {
        console.log("D losgelassen:", KwinService.visibleGrips.length, "| Befehle:", cmds());
        KwinService._handleLine(state(two));
        PopoutManager.currentPopoutsByScreen = {"DP-2": {}}; PopoutManager.popoutChanged();
        step4.start();
    } }
    Timer { id: step4; interval: 100; onTriggered: {
        console.log("E Popout offen: sichtbar", KwinService.visibleGrips.length, "busy", KwinService.shellBusy);
        PopoutManager.currentPopoutsByScreen["DP-2"] = null;   // ohne Signal, wie im Original an manchen Stellen
        KwinService._handleLine(state(two));
        step5.start();
    } }
    Timer { id: step5; interval: 100; onTriggered: {
        console.log("F Popout zu (erkannt über die nächste Meldung): sichtbar", KwinService.visibleGrips.length);
        const before = Registry.procs.length;
        SettingsData.windowGripOutside = 0;
        step6.before = before; step6.start();
    } }
    Timer { id: step6; property int before: 0; interval: 600; onTriggered: {
        const last = Registry.procs[Registry.procs.length - 1];
        console.log("G Einstellung geändert: Brücke neu geladen:", Registry.procs.length > before, "| neue Einstellungen:", last.command[last.command.length - 1]);
        SettingsData.windowGripEnabled = false;
        step7.start();
    } }
    Timer { id: step7; interval: 100; onTriggered: console.log("H abgeschaltet: sichtbar", KwinService.visibleGrips.length, "gripEnabled", KwinService.gripEnabled) }
}
