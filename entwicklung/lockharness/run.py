import sys, os
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlComponent, QQmlEngine
from PySide6.QtQuick import QQuickView
from PySide6.QtCore import QUrl, QTimer, QSize
app = QGuiApplication(sys.argv)
qml, w, h, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
view = QQuickView()
eng = view.engine()
eng.warnings.connect(lambda ws: [print("QMLWARN", x.toString()) for x in ws])
here = os.path.dirname(os.path.abspath(__file__))
c1 = QQmlComponent(eng, QUrl.fromLocalFile(here + "/Mock.qml")); auth = c1.create()
c2 = QQmlComponent(eng, QUrl.fromLocalFile(here + "/" + os.environ.get("ALPE_WALL", "Wall.qml"))); wall = c2.create()
for c in (c1, c2):
    for e in c.errors(): print("ERR", e.toString())
ctx = view.rootContext()
ctx.setContextProperty("authenticator", auth)
import json
ctx.setContextProperty("config", json.loads(os.environ.get("ALPE_LOCKCFG", "{}")))
ctx.setContextProperty("wallpaper", wall)
ctx.setContextProperty("kscreenlocker_userName", "nutzer")
view.setResizeMode(QQuickView.SizeRootObjectToView)
view.resize(QSize(w, h))
view.setSource(QUrl.fromLocalFile(qml))
if view.status() != QQuickView.Ready:
    for e in view.errors(): print("ERR", e.toString())
    sys.exit(1)
root = view.rootObject()
wall.setParentItem(root); wall.setZ(-1000); wall.setWidth(w); wall.setHeight(h)
view.show()
steps = []
def log(): return list(auth.property("log").toVariant() if hasattr(auth.property("log"), "toVariant") else auth.property("log"))
def at(ms, fn): QTimer.singleShot(ms, fn)
quit_calls = []
app.aboutToQuit.connect(lambda: quit_calls.append(1))
from PySide6.QtQml import QQmlProperty
def setv(name, val): root.setProperty(name, val)
at(100, lambda: setv("viewVisible", True))
def find(name):
    from PySide6.QtQuick import QQuickItem
    return root.findChild(QQuickItem, name)
def typed(text):
    # in das TextInput schreiben
    from PySide6.QtQuick import QQuickItem
    for item in root.findChildren(QQuickItem):
        if item.metaObject().className().startswith("QQuickTextInput") and item.isVisible():
            item.setProperty("text", text); item.forceActiveFocus(); return item
def enter():
    QQmlProperty.read(root, "pending")
    root.metaObject().invokeMethod(root, "submit") if False else None
    from PySide6.QtCore import QMetaObject
    QMetaObject.invokeMethod(root, "submit")
mode = sys.argv[5] if len(sys.argv) > 5 else "shot"
def shot():
    img = view.grabWindow(); img.save(out); print("Bild", out, img.width(), img.height())
if mode == "shot":
    at(600, shot); at(900, app.quit)
else:
    # Ablauf: falsches Passwort vor der Abfrage, Abfrage kommt, Fehler, richtiges Passwort
    at(200, lambda: (typed("falsch"), enter(), print("1 nach Enter ohne Abfrage:", log()[-1], "| pending:", root.property("pending"))))
    at(300, lambda: (auth.prompt(), print("2 Abfrage kommt:", log()[-1], "| Meldung:", root.property("message"), "| Feld leer:", typed is not None)))
    at(400, shot)
    at(700, lambda: (auth.prompt(), typed("geheim"), enter(), print("3 richtig:", log()[-3:], "| unlocked:", auth.property("unlocked"))))
    at(900, lambda: (print("Qt.quit aufgerufen:", bool(quit_calls)), app.quit()))
    at(2000, app.quit)
app.exec()
print("Ende, quit:", bool(quit_calls))
