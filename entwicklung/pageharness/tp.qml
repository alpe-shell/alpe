import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import "pages"
Item {
    id: top
    width: 800; height: 600
    property var nav: []
    property QtObject modal: QtObject { function navigateTo(page, keyboard) { top.nav = top.nav.concat([page]); return true } }
    function rows(item, out) {
        out = out || [];
        for (const c of item.children) {
            if (!c.visible) continue;
            if (c.isCard) out.push("## " + c.title);
            if (c.isRow) out.push("   " + c.title + (c.subtitle ? "  —  " + c.subtitle : "") + (c.trailingBadge ? "  [" + c.trailingBadge + "]" : "") + (c.checked !== undefined ? (c.checked ? "  (an)" : "  (aus)") : "") + (c.enabled ? "" : "  {gesperrt}"));
            rows(c, out);
        }
        return out;
    }
    function find(item, pred) { for (const c of item.children) { if (pred(c)) return c; const f = find(c, pred); if (f) return f; } return null }
    function row(page, title) { return find(page, c => c.isRow && c.title === title) }
    function dump(name, page) { console.log("=== " + name + "\n" + rows(page).join("\n")) }
    AlpeLockTab { id: lock; parentModal: top.modal }
    AlpeKwinTab { id: kwin; parentModal: top.modal }
    AlpeDeviceTab { id: device; parentModal: top.modal }
    AlpePeripheralsTab { id: periph; parentModal: top.modal }
    AlpeMaintenanceTab { id: maint; parentModal: top.modal }
    AlpePagesTab { id: pages; parentModal: top.modal }
    Timer { interval: 300; running: true; onTriggered: {
        console.log("Design gelesen:", Registry.answer("plasmashellrc", "shell=\nalpe=1\nblur=\ndim=40\n"), Registry.answer("--group Daemon", "tools=ok\nAutolock=true\nTimeout=10\nLockGrace=30\nLockOnResume=false\n"));
        dump("Sperre", lock);
        Quickshell.calls = [];
        row(lock, "Alpe-Design").toggled(true);
        console.log("Umschalten: Probe läuft:", Registry.procs.some(p => p.running && p.command.join(" ").indexOf("test org.alpe.desktop") > 0), "| beantwortet", Registry.answer("org.alpe.desktop", JSON.stringify({greeter: true, fallback: false, missing: [], suggest: "", code: 124, errors: 0})), "| aktiv:", lock.alpeActive, "| Befehl:", JSON.stringify(Quickshell.calls));
        row(lock, "Unschärfe").sliderDragFinished(32);
        console.log("Unschärfe:", JSON.stringify(Quickshell.calls[Quickshell.calls.length - 1]));
        row(lock, "Alpe-Design").toggled(false);
        console.log("zurück auf KDE:", lock.alpeActive, JSON.stringify(Quickshell.calls[Quickshell.calls.length - 1]));
        row(lock, "Alpe-Design").toggled(true);
        Registry.answer("org.alpe.desktop", JSON.stringify({greeter: true, fallback: true, missing: ["QtQuick.Effects"], suggest: "sudo pacman -S --needed qt6-declarative", code: 124, errors: 1}));
        console.log("Probe gescheitert -> bleibt KDE:", lock.alpeActive);
        KwinService._handleLine(JSON.stringify({payload: {data: [JSON.stringify({v: 1, seq: 1, current: "d1", activeOutput: "DP-2", active: "", desktops: [{id: "d1", name: "1", number: 1}], windows: [{id: "{a}", appId: "kitty", title: "t", output: "DP-2", desktops: ["d1"]}], grips: [{id: "{a}", output: "DP-2", x: 1, y: 1, w: 100, h: 8, gx: 1, gy: 1}]})]}, member: "state"}));
        dump("KWin", kwin);
        row(kwin, "Am Bildschirmrand einrasten").toggled(false);
        console.log("Einstellungen:", JSON.stringify(SettingsData.log));
        Qt.quit();
    } }
}
