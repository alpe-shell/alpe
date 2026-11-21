#!/usr/bin/env python3
"""Vorschau des Sport-Tabs ohne Shell: laedt eine Szene mit den Attrappen und speichert ein Bild.

    QML_XHR_ALLOW_FILE_READ=1 python3 shot.py scenes/tab_wide.qml out.png
    ALPE_SPORT_FIXTURES=/pfad  Musterdaten von dort statt aus fixtures/ (so laufen die Tests)
"""
import os, sys
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QML_XHR_ALLOW_FILE_READ", "1")
from PySide6.QtCore import QTimer, QUrl, qInstallMessageHandler
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView

here = os.path.dirname(os.path.abspath(__file__))
app = QGuiApplication(sys.argv)
view = QQuickView()
view.engine().addImportPath(os.path.join(here, "mocks"))
if os.environ.get("ALPE_SPORT_FIXTURES"):
    view.rootContext().setContextProperty("fixturesUrl", QUrl.fromLocalFile(os.path.join(os.environ["ALPE_SPORT_FIXTURES"], "")).toString())
problems = []
# Szenen melden Pruefungsfehler mit console.error("Fehler: …")
qInstallMessageHandler(lambda mode, ctx, msg: problems.append(msg) if "Fehler:" in msg else None)
view.engine().warnings.connect(lambda ws: [problems.append(w.toString()) for w in ws])
view.setSource(QUrl.fromLocalFile(os.path.abspath(sys.argv[1])))
for e in view.errors():
    problems.append(e.toString())
view.show()

def done():
    if len(sys.argv) > 2:
        view.grabWindow().save(sys.argv[2])
    for p in problems:
        print("QML:", p)
    app.exit(1 if any("rror" in p or "is not a type" in p or "Fehler:" in p for p in problems) else 0)

QTimer.singleShot(int(os.environ.get("SHOT_DELAY", "1800")), done)
sys.exit(app.exec())
