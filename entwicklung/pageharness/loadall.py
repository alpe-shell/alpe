#!/usr/bin/env python3
"""Lädt jede Alpe-Einstellungsseite mit den Attrappen dieses Ordners und meldet QML-Fehler.

    ALPE_SHELL_DIR=~/dux-shell python3 loadall.py

Fängt Fehler, an denen eine Seite gar nicht erst entsteht (doppelte Handler, fehlende Typen,
Syntax). Die Seiten werden vorher aus dem Shell-Code in einen
temporären Ordner kopiert.
"""
import glob
import os
import shutil
import sys
import tempfile

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlComponent, QQmlEngine

here = os.path.dirname(os.path.abspath(__file__))
shell = os.environ.get("ALPE_SHELL_DIR") or os.path.expanduser("~/dux-shell")
settings = os.path.join(shell, "quickshell", "Modules", "Settings")
# In einen Wegwerf-Ordner kopieren: der Arbeitsbaum (git) bleibt sauber.
pages = tempfile.mkdtemp(prefix="alpe-pages-")
for f in glob.glob(os.path.join(settings, "Alpe*.qml")):
    shutil.copy(f, pages)

app = QGuiApplication(sys.argv)
engine = QQmlEngine()
engine.addImportPath(here)
bad = 0
for f in sorted(glob.glob(os.path.join(pages, "Alpe*Tab.qml"))):
    comp = QQmlComponent(engine, QUrl.fromLocalFile(f))
    obj = comp.create() if comp.isReady() else None
    errors = [e.toString() for e in comp.errors()]
    name = os.path.basename(f)
    if obj is None or errors:
        bad += 1
        print("FEHLER", name)
        for e in errors[:5]:
            print("      ", e)
    else:
        print("ok    ", name)
print("\nalle Seiten laden" if bad == 0 else f"\n{bad} Seite(n) laden nicht")
shutil.rmtree(pages, ignore_errors=True)
sys.exit(1 if bad else 0)
