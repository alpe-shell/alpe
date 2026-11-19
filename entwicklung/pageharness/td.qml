import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import "pages"
// Prüft die Seite «Sperrbildschirm gestalten» (AlpeLockDesignTab) mit dem echten HyprlockView.
Item {
    id: top
    width: 820; height: 2000
    function log(m) { console.log(m) }
    Component.onCompleted: Quickshell.environment = ({ "HOME": "/home/nutzer", "USER": "nutzer", "XDG_DATA_HOME": "/tmp/phdata" })
    Loader { id: l; width: 800; active: false; sourceComponent: AlpeLockDesignTab {} }
    Timer { interval: 50; running: true; onTriggered: { l.active = true; s1.start() } }
    Timer { id: s1; interval: 300; onTriggered: {
        const p = l.item;
        log("installiert " + p.installed + " | Leser beantwortet " + Registry.answer("kreadconfig6", "Style=hyprlock\nLocale=\nLayout=\n"));
        log("Layout geladen: " + (p.layout !== null) + " eigene: " + p.custom + " Elemente " + p.widgets.length + " Unschärfe " + p.bg.blurRadius);
        const hours = p.widgets.findIndex(w => w.type === "label");
        p.selected = hours;
        log("Auswahl: " + p.typeName(p.sel) + " «" + p.friendly(p.sel) + "»");
        // Ziehen in der Vorschau: Signal aus HyprlockView
        const view = p.children[0] ? null : null;
        p.moveBy(hours, 40, -10);
        log("nach Ziehen: " + JSON.stringify(p.widgets[hours].position) + " Verlauf " + p.history.length);
        p.resizeBy(hours, 1); p.resizeBy(hours, 1);
        log("Mausrad zweimal: Grösse " + p.widgets[hours].fontSize + " Verlauf " + p.history.length + " (zusammengefasst)");
        p.editSel(w => { w.format = "%H"; delete w.text; }, "");
        p.addLabel();
        log("Text hinzugefügt: " + p.widgets.length + " Auswahl " + p.selected + " «" + p.friendly(p.sel) + "»");
        p.duplicateSelected(); log("dupliziert: " + p.widgets.length);
        p.removeSelected(); log("entfernt: " + p.widgets.length + " Auswahl " + p.selected);
        p.selected = p.widgets.findIndex(w => w.type === "input");
        p.editSel(w => w.innerColor = p.withAlpha(w.innerColor, 0.5), "alpha:innerColor");
        log("Feldfarbe 50 %: " + p.sel.innerColor + " Deckkraft " + p.alphaOf(p.sel.innerColor).toFixed(2));
        p.removeSelected(); log("Passwortfeld lässt sich nicht entfernen: " + p.widgets.filter(w => w.type === "input").length);
        p.undo(); p.undo();
        log("zweimal rückgängig: Verlauf " + p.history.length + " Elemente " + p.widgets.length);
        s2.start();
    } }
    Timer { id: s2; interval: 800; onTriggered: {
        const p = l.item;
        const writes = Quickshell.calls.filter(c => c.indexOf("Layout") >= 0);
        log("gespeichert (verzögert): " + writes.length + " Mal, letzter Wert gültiges JSON: " + (() => { try { return !!JSON.parse(writes[writes.length - 1].slice(-1)[0]).widgets } catch (e) { return false } })());
        p.resetToTemplate();
        const del = Quickshell.calls.filter(c => c.indexOf("Layout") >= 0 && c.indexOf("--delete") >= 0).length;
        log("Vorlage: Layout gelöscht " + del + " eigene " + p.custom + " Elemente " + p.widgets.length);
        p.selected = 0;
        log("Hintergrund: Quelle " + (p.bg.source || "desktop") + " | Desktop-Bild «" + p.desktopImage + "»");
        SessionData.wallpaperPath = "/home/nutzer/Videos/berge.mp4";
        log("Video-Hintergrund ohne Standbild: Desktop-Bild «" + p.desktopImage + "» (leer = Hinweis)");
        p.edit(l => { l.background.source = "image"; l.background.image = "/home/nutzer/Pictures/lock.jpg"; }, "");
        log("eigenes Bild: " + p.bg.source + " " + p.bg.image);
        Qt.callLater(() => Qt.quit());
    } }
}
