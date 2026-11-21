import QtQuick
import Quickshell
import qs.Common
import qs.Services
import "pages"
// Prüft die KWin-Seiten von Alpe mit vorgefertigten Antworten von alpe-kwin.py.
Item {
    id: top
    width: 900; height: 1200
    function log(m) { console.log(m) }
    property var st: ({
        rules: [{ id: "3f1c", Description: "Keine Titelleiste", noborder: "true", noborderrule: "2", wmclassmatch: "0", other: ["types"] },
                { id: "7aa0", Description: "Zed", wmclass: "dev.zed.Zed", wmclassmatch: "1", opacityactive: "86", opacityactiverule: "2", other: [] }],
        blurClasses: ["dev.zed.Zed", "org.gnome.Nautilus"], blur: { BlurStrength: "12" }, corners: { Size: "14" },
        effects: { blur: { id: "better_blur_dx", installed: true, enabled: true, loaded: true }, corners: { id: "kwin4_effect_shapecorners", installed: true, enabled: true, loaded: true }, kwinblur: { id: "blur", installed: true, enabled: false, loaded: false } },
        placement: "Smart", animation: "0.5", focusPolicy: "ClickToFocus" })
    property var sc: ({ available: true, components: [
        { component: "kwin", name: "KWin", actions: [{ action: "Window Close", name: "Fenster schliessen", keys: [134217812], defaults: [134217812] }, { action: "Overview", name: "Übersicht", keys: [], defaults: [268435543] }] },
        { component: "dms", name: "Alpe", actions: [{ action: "alpe-launcher", name: "Alpe: Starter", keys: [268435488], defaults: [] }] } ] })
    property var sv: ({ available: true, services: [{ Id: "dms.service", ActiveState: "active", ActiveEnterTimestamp: "Tue 2026-11-17 18:00:00 CET", own: false, dropins: ["/x/dms.service.d/kwin.conf"], UnitFileState: "enabled" },
        { Id: "alpe-sync.service", Description: "Sync", ActiveState: "inactive", own: true, dropins: [], UnitFileState: "disabled" },
        { Id: "pipewire.service", Description: "PipeWire", ActiveState: "active", own: false, dropins: [], UnitFileState: "enabled" }] })
    Component.onCompleted: {
        KwinService.toplevels = [{ appId: "kitty" }, { appId: "dev.zed.Zed" }, { appId: "kitty" }];
        Proc.responder = (cmd, cb) => {
            const sub = cmd[3];
            const out = sub === "state" ? st : sub === "shortcuts" ? sc : sub === "services" ? sv : sub === "rule-set" ? { id: "neu1" }
                : sub === "apps" ? { apps: [{ id: "kitty.desktop", name: "kitty" }, { id: "org.kde.dolphin.desktop", name: "Dolphin" }] }
                : sub === "shortcut-new" ? { ok: true, component: "net.local.notizen.desktop" } : {};
            Qt.callLater(() => cb(JSON.stringify(out), 0));
        };
        step.start();
    }
    Loader { id: rules; active: false; width: 880; sourceComponent: AlpeWindowRulesTab {} }
    Loader { id: fx; active: false; width: 880; sourceComponent: AlpeEffectsTab {} }
    Loader { id: keys; active: false; width: 880; sourceComponent: AlpeShortcutsTab {} }
    Loader { id: svc; active: false; width: 880; sourceComponent: AlpeServicesTab {} }
    Timer { id: step; interval: 50; onTriggered: { rules.active = fx.active = keys.active = svc.active = true; step2.start() } }
    Timer { id: step2; interval: 300; onTriggered: {
        const r = rules.item;
        log("Regeln: " + r.rules.length + " | laufend: " + r.runningApps.join(",") + " | Zusammenfassung Zed: " + r.summary(r.rules[1]));
        r.select(r.rules[1]);
        log("Entwurf: Deckkraft " + r.draft.opacityOn + " " + r.draft.opacityactive + " blur " + r.draft.blur + " Titelleiste " + r.draft.border);
        r.change("position", true); r.change("border", "hide"); r.change("opacityOn", false);
        const v = r.values(r.draft);
        log("Werte: noborder=" + v.noborder + " noborderrule=" + v.noborderrule + " positionrule=" + v.positionrule + " opacityactive=" + v.opacityactive + " wmclass=" + v.wmclass);
        Proc.calls = [];
        r.save();
        Qt.callLater(() => {
            const call = Proc.calls.find(c => c[3] === "rule-set");
            const payload = JSON.parse(call[4]);
            log("rule-set: id " + payload.id + " blur " + payload.blur + " opacityactiverule " + payload.values.opacityactiverule + " Position " + payload.values.positionrule);
            r.newRule("kitty");
            const v2 = r.values(r.draft);
            log("neue Regel kitty: wmclassmatch " + v2.wmclassmatch + " Beschreibung " + v2.Description);
            r.change("wmclassmatch", 0);
            log("alle Programme: wmclass " + r.values(r.draft).wmclass + " wmclasscomplete " + r.values(r.draft).wmclasscomplete);
            step3.start();
        });
    } }
    Timer { id: step3; interval: 200; onTriggered: {
        const f = fx.item;
        log("Effekte: Ecken " + f.effectState(f.fx.corners) + " | Radius " + f.num(f.corners, "Size", 20) + " | Tempo " + f.speedOptions[f.nearestSpeed(parseFloat(f.st.animation))] + " | Platzierung " + f.placementOptions[f.placementValues.indexOf(f.st.placement)]);
        Proc.calls = [];
        f.set("kwinrc", "Round-Corners", "Size", 16); f.set("kwinrc", "Round-Corners", "Size", 18); f.set("kwinrc", "Effect-better-blur-dx", "BlurStrength", 9);
        log("verzögert: noch keine Schreibaufrufe " + (Proc.calls.length === 0) + ", ausstehend " + f.pending.length);
        step4.start();
    } }
    Timer { id: step4; interval: 500; onTriggered: {
        const call = Proc.calls.find(c => c[3] === "apply");
        log("apply gebündelt: " + call[4]);
        const k = keys.item;
        log("Kürzel: " + k.shown.length + "/" + k.total + " info " + (k.info !== null) + " Zeilen | " + k.keyText(134217812) + " | " + k.keyText(268435488) + " | " + k.keyText(Qt.MetaModifier | Qt.ShiftModifier | Qt.Key_S) + " | " + k.keyText(Qt.Key_Print) + " | " + k.keyText(Qt.ControlModifier | Qt.Key_F12));
        k.filter = "starter"; log("Suche «starter»: " + k.shown.map(r => r.actionName).join(","));
        k.filter = "meta+w"; log("Suche «meta+w»: " + k.shown.map(r => r.actionName).join(","));
        k.filter = "";
        log("Gruppen: " + k.shown.map(r => r.group + (r.first ? "[" : "") + (r.last ? "]" : "")).join(" "));
        const ov = k.shown.find(r => r.action === "Overview");
        Proc.calls = [];
        k.beginCapture(ov);
        log("Aufnahme: block on " + !!Proc.calls.find(c => c[3] === "block" && c[4] === "on") + " Fokus " + (k.capture !== null) + " Inhibitor " + k.inhibiting);
        k.captured(Qt.AltModifier | Qt.Key_F4);
        log("Alt+F4 frei: gesetzt " + JSON.parse(Proc.calls.find(c => c[3] === "shortcut-set")[4]).keys + " | block off " + !!Proc.calls.find(c => c[3] === "block" && c[4] === "off") + " Inhibitor " + k.inhibiting);
        Proc.calls = [];
        k.beginCapture(ov); k.captured(134217812);
        log("Konflikt: " + (k.conflict ? k.keyText(k.conflict.combo) + " bei " + k.conflict.owner.actionName : "keiner") + " | noch nichts gesetzt " + !Proc.calls.find(c => c[3] === "shortcut-set"));
        k.resolveConflict(true);
        Qt.callLater(() => Qt.callLater(() => {
            const sets = Proc.calls.filter(c => c[3] === "shortcut-set").map(c => JSON.parse(c[4]));
            log("aufgelöst: " + sets.map(s => s.action + "=" + JSON.stringify(s.keys)).join(" dann "));
            // Neues Kürzel: Befehl
            Proc.calls = [];
            k.newKind = "command"; log("neu bereit ohne Angaben: " + k.newReady);
            k.newName = "Notizen"; k.newCommand = "kitty -e nvim"; k.captureNew();
            k.captured(Qt.MetaModifier | Qt.Key_Space);
            log("Meta+Leertaste belegt? " + (k.conflict ? "Konflikt mit " + k.conflict.owner.actionName : "nein"));
            Proc.calls = [];
            k.resolveConflict(false);
            k.captureNew(); k.captured(Qt.MetaModifier | Qt.Key_J);
            const nw = Proc.calls.find(c => c[3] === "shortcut-new");
            log("shortcut-new: " + (nw ? nw[4] : "fehlt"));
            k.newKind = "app"; k.newApp = "kitty.desktop"; Proc.calls = [];
            k.captureNew(); k.captured(Qt.MetaModifier | Qt.Key_Return);
            log("Programm: " + Proc.calls.find(c => c[3] === "shortcut-new")[4]);
            const s = svc.item;
            log("Dienste: Shell " + s.stateText(s.shell) + " | eigene " + s.own.map(x => x.Id) + " | weitere " + s.others.map(x => x.Id));
            Proc.calls = []; s.act("enable", "alpe-sync.service");
            log("Autostart an: " + JSON.stringify(Proc.calls[0].slice(3)));
            Qt.quit();
        }));
    } }
}
