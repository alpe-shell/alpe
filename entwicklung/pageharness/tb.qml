import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
Item {
    readonly property var backend: ({devices: [{id: "ddc:i2c-5", class: "ddc", current: 50, currentPercent: 50, max: 100, backend: "ddc"}, {id: "leds:kbd", class: "leds", current: 1, currentPercent: 30, max: 3, backend: "sysfs"}]})
    function ids() { return BrightnessService.devices.map(d => d.id + "(" + d.class + ")").join(",") }
    function setCalls() { return Registry.procs.filter(p => p.command[2] === "set").map(p => p.command.slice(3).join("=") + (p.running ? "*" : "")).join(" ") }
    property int osd: 0
    Connections { target: BrightnessService; function onBrightnessChanged(show) { osd++ } }
    Component.onCompleted: {
        console.log("A Start: kdeMode", BrightnessService.kdeMode, "| Abfrage läuft:", Registry.procs.some(p => p.command[2] === "list" && p.running));
        ShellBackend.brightnessStateUpdate(backend);
        console.log("B Dienst zuerst:", ids(), "| aktuell:", BrightnessService.currentDevice);
        Registry.answer("alpe-brightness.py\",\"list", JSON.stringify({backend: "powerdevil", devices: [{id: "kde:display0", label: "Odyssey G85SD", percent: 70}]}));
        console.log("C mit Plasma:", ids(), "| aktuell:", BrightnessService.currentDevice, "| Wert:", BrightnessService.brightnessLevel, "| Titel:", BrightnessService.deviceTitle(BrightnessService.getCurrentDeviceInfo()), "| Symbol:", BrightnessService.brightnessIconName(BrightnessService.getCurrentDeviceInfo(), 70), "| Standard:", BrightnessService.getDefaultDevice());
        BrightnessService.setBrightness(40, "kde:display0", true);
        BrightnessService.setBrightness(35, "kde:display0", true);
        BrightnessService.setBrightness(30, "kde:display0", true);
        console.log("D drei Züge am Regler: Wert", BrightnessService.getDeviceBrightness("kde:display0"), "| Aufrufe:", setCalls(), "| an den Dienst:", ShellBackend.requests.length);
        Registry.answer("\"set\"", JSON.stringify({ok: true, error: ""}));
        console.log("E erster fertig -> jüngster Wunsch:", setCalls());
        Registry.answer("\"set\"", JSON.stringify({ok: false, error: "kein DDC"}));
        console.log("F Fehler gemeldet:", JSON.stringify(ToastService.shown), "| offen:", Registry.procs.filter(p => p.running).length);
        ShellBackend.brightnessStateUpdate(backend);
        ShellBackend.brightnessDeviceUpdate({id: "ddc:i2c-5", class: "ddc", current: 10, currentPercent: 10, max: 100});
        console.log("G Dienstmeldung danach:", ids(), "| Wert bleibt:", BrightnessService.getDeviceBrightness("kde:display0"), "| OSD-Signale:", osd);
        BrightnessService.setBrightness(2, "leds:kbd", false);
        console.log("H Tastatur weiter über den Dienst:", ShellBackend.requests.join(" ; "));
        BrightnessService.setBrightness(80, "", false);
        console.log("I ohne Gerätename (Taste/IPC):", setCalls(), "| OSD-Signale:", osd);
        CompositorService.isKwin = false;
        console.log("J ohne KWin:", ids(), "| aktuell:", BrightnessService.currentDevice);
    }
}
