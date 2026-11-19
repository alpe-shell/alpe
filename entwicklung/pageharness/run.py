import sys, os
os.environ["QT_QPA_PLATFORM"]="offscreen"
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, QQmlComponent
from PySide6.QtCore import QUrl, QTimer
app=QGuiApplication(sys.argv)
eng=QQmlApplicationEngine()
eng.addImportPath(sys.argv[2] if len(sys.argv) > 2 else "/tmp/lint")
eng.warnings.connect(lambda ws: [print("QMLWARN", w.toString()) for w in ws])
c=QQmlComponent(eng, QUrl.fromLocalFile(sys.argv[1]))
if c.isError():
    for e in c.errors()[:25]: print("ERR", e.toString())
    sys.exit(1)
o=c.create()
for e in c.errors()[:25]: print("ERR", e.toString())
print("created", o)
QTimer.singleShot(2500, app.quit); app.exec()
