#!/usr/bin/env python3
"""Alpe: Kürzelseite mit 400 Aktionen laden. Es dürfen nur die sichtbaren Zeilen entstehen und
ein Suchschritt muss schnell sein – vorher hielt die Suche die Shell fest (SettingsGroup legt jede
Zeile einzeln neu aus).

    ALPE_SHELL_DIR=/pfad/zur/shell python3 kuerzel_last.py
"""
import glob
import os
import shutil
import sys
import tempfile

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
# Die Szene meldet ihre Ergebnisse über console.log. Fedoras qtlogging.ini schaltet das ab (Befund vom Mac, 28.11.2026);
# QT_LOGGING_RULES geht den Konfigurationsdateien vor. Nicht «*.debug=true»: das stürzt beim Beenden ab.
os.environ.setdefault("QT_LOGGING_RULES", "js.debug=true;qml.debug=true")
from PySide6.QtCore import QTimer, QUrl, qInstallMessageHandler
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, QQmlComponent

here = os.path.dirname(os.path.abspath(__file__))
shell = os.environ.get("ALPE_SHELL_DIR") or os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "shell")
work = tempfile.mkdtemp(prefix="alpe-kuerzel-")
pages = os.path.join(work, "pages")
os.makedirs(pages)
for name in ("AlpeShortcutsTab.qml", "AlpeKwinBackend.qml"):
    shutil.copy(os.path.join(shell, "Modules", "Settings", name), pages)

SCENE = r'''
import QtQuick
import qs.Common
import "pages"
Item {
    id: top
    width: 900; height: 900
    function check(ok, text) { console.log((ok ? "ok     " : "Fehler: ") + text) }
    property var sc: {
        const comps = [];
        for (let c = 0; c < 20; c++) {
            const actions = [];
            for (let a = 0; a < 20; a++)
                actions.push({ action: "a" + c + "_" + a, name: "Aktion " + a + " von Bereich " + c, keys: a % 3 ? [0x10000000 | (0x41 + a)] : [], defaults: [] });
            comps.push({ component: c === 0 ? "kwin" : c === 1 ? "dms" : "comp" + c, name: c === 0 ? "KWin" : c === 1 ? "Alpe" : "Bereich " + c,
                         actions: actions, launch: c >= 18, custom: c === 18, command: c === 18 ? "kitty" : undefined });
        }
        return { available: true, components: comps };
    }
    Component.onCompleted: {
        Proc.responder = (cmd, cb) => { const sub = cmd[3]; Qt.callLater(() => cb(JSON.stringify(sub === "shortcuts" ? sc : sub === "apps" ? { apps: [] } : {}), 0)); };
        keys.active = true;
        step.start();
    }
    Loader { id: keys; active: false; width: 900; height: 900; sourceComponent: AlpeShortcutsTab {} }
    function delegates(item) {
        let n = 0;
        const walk = it => { for (const ch of it.children) { if (ch.modelData !== undefined && ch.index !== undefined) n++; walk(ch); } };
        walk(item);
        return n;
    }
    Timer { id: step; interval: 300; onTriggered: {
        const k = keys.item;
        check(k.total === 400 && k.shown.length === 400, "400 Aktionen in der Liste (" + k.shown.length + ")");
        check(top.delegates(k) < 40, "nur sichtbare Zeilen erzeugt (" + top.delegates(k) + ")");
        let t = Date.now();
        for (const q of ["a", "ak", "akt", "akti", "aktio", "aktion", "aktion 1", ""]) k.filter = q;
        const ms = Date.now() - t;
        check(ms < 500, "8 Suchschritte in " + ms + " ms");
        check(top.delegates(k) < 40, "nach der Suche weiterhin nur sichtbare Zeilen (" + top.delegates(k) + ")");
        const lv = (function f(it) { for (const c of it.children) { if (c.currentIndex !== undefined && c.model !== undefined) return c; const r = f(c); if (r) return r; } return null; })(k);
        const search = (function f(it) { for (const c of it.children) { if (c.title === "Suchen" && c.placeholderText !== undefined) return c; const r = f(c); if (r) return r; } return null; })(k);
        let inList = false;
        for (let p = search; p; p = p.parent) if (p === lv) inList = true;
        check(search !== null && !inList, "Suchfeld liegt ausserhalb der Liste (deren Fokusbereich nimmt ihm sonst den Fokus)");
        k.filter = "aktion 2";
        check(lv.currentIndex === -1, "nach einem Suchschritt keine aktuelle Zeile (currentIndex " + lv.currentIndex + ")");
        k.filter = "";
        k.group = "Programme starten";
        check(k.shown.length === 20 && k.shown[0].first && k.shown[19].last, "Bereich «Programme starten»: 20 Zeilen, erste/letzte markiert");
        k.group = "Eigene Befehle";
        check(k.shown.length === 20 && k.shown.every(r => r.removable && r.custom), "eigene Befehle entfernbar");
        k.group = ""; k.filter = "meta+b";
        check(k.shown.length === 20, "Suche nach Taste «meta+b»: " + k.shown.length + " Treffer");
        Qt.callLater(Qt.quit);
    } }
}
'''
with open(os.path.join(work, "scene.qml"), "w") as f:
    f.write(SCENE)

app = QGuiApplication(sys.argv)
lines = []
qInstallMessageHandler(lambda mode, ctx, msg: lines.append(msg))
engine = QQmlApplicationEngine()
engine.addImportPath(here)
engine.quit.connect(app.quit)
comp = QQmlComponent(engine, QUrl.fromLocalFile(os.path.join(work, "scene.qml")))
obj = comp.create() if comp.isReady() else None
for e in comp.errors():
    lines.append("Fehler: " + e.toString())
QTimer.singleShot(8000, app.quit)
if obj is not None:
    app.exec()
shutil.rmtree(work, ignore_errors=True)
bad = 0
for line in lines:
    if line.startswith(("ok", "Fehler:")) or "TypeError" in line or "ReferenceError" in line:
        print(line if not ("TypeError" in line or "ReferenceError" in line) else "Fehler: " + line)
        bad += line.startswith("Fehler:") or "TypeError" in line or "ReferenceError" in line
if obj is None or not any(l.startswith("ok") for l in lines):
    print("Fehler: Szene lief nicht")
    bad += 1
sys.exit(1 if bad else 0)
