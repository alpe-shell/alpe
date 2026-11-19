# Echte Mausereignisse auf der Vorschau: Element anklicken, ziehen, Mausrad.
import sys
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView
from PySide6.QtCore import QUrl, QTimer, QPoint, Qt
from PySide6.QtTest import QTest
app = QGuiApplication(sys.argv)
v = QQuickView(); v.engine().addImportPath(sys.argv[2])
v.engine().warnings.connect(lambda ws: [print("QMLWARN", w.toString()) for w in ws])
v.setSource(QUrl.fromLocalFile(sys.argv[1])); v.show()
def page(): return v.rootObject().findChild(__import__("PySide6.QtQuick").QtQuick.QQuickItem, "") 
def st(msg):
    try:
        p = v.rootObject().property("pageItem")
        sel = p.property("selected")
        lay = p.property("layout")
        lay = lay.toVariant() if hasattr(lay, "toVariant") else lay
        print(msg, sel, lay["widgets"][sel]["position"] if sel >= 0 else "-", flush=True)
    except Exception as e:
        print("Fehler", e, flush=True)
from PySide6.QtGui import QMouseEvent, QWheelEvent
from PySide6.QtCore import QEvent, QPointF
def send(kind, pt, buttons):
    btn = Qt.LeftButton if kind != QEvent.MouseMove else Qt.NoButton
    e = QMouseEvent(kind, QPointF(pt), QPointF(v.mapToGlobal(pt)), btn, buttons, Qt.NoModifier)
    QGuiApplication.sendEvent(v, e)
def wheel(pt, dy):
    e = QWheelEvent(QPointF(pt), QPointF(v.mapToGlobal(pt)), QPoint(0, 0), QPoint(0, dy), Qt.NoButton, Qt.NoModifier, Qt.NoScrollPhase, False)
    QGuiApplication.sendEvent(v, e)
def step1():
    st("vorher: Auswahl")
    a = QPoint(int(sys.argv[3]), int(sys.argv[4]))
    send(QEvent.MouseButtonPress, a, Qt.LeftButton)
    for i in range(1, 11):
        send(QEvent.MouseMove, QPoint(a.x() + 6 * i, a.y() + 3 * i), Qt.LeftButton); app.processEvents()
    send(QEvent.MouseButtonRelease, QPoint(a.x() + 60, a.y() + 30), Qt.NoButton)
    QTimer.singleShot(200, step2)
def step2():
    st("nach Ziehen um 60,30 Vorschau-Pixel: Auswahl")
    p = v.rootObject().property("pageItem")
    lay = p.property("layout"); lay = lay.toVariant() if hasattr(lay, "toVariant") else lay
    print("Grösse vorher", lay["widgets"][p.property("selected")].get("size"), flush=True)
    wheel(QPoint(int(sys.argv[3]) + 60, int(sys.argv[4]) + 30), 120)
    QTimer.singleShot(200, step3)
def step3():
    p = v.rootObject().property("pageItem")
    lay = p.property("layout"); lay = lay.toVariant() if hasattr(lay, "toVariant") else lay
    print("Grösse nach Mausrad", lay["widgets"][p.property("selected")].get("size"), flush=True)
    v.grabWindow().save("/tmp/drag.png"); app.quit()
QTimer.singleShot(1500, step1)
app.exec()
