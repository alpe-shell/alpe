import sys
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView
from PySide6.QtCore import QUrl, QTimer
app = QGuiApplication(sys.argv)
v = QQuickView(); v.engine().addImportPath(sys.argv[2])
v.engine().warnings.connect(lambda ws: [print("QMLWARN", w.toString()) for w in ws])
v.setSource(QUrl.fromLocalFile(sys.argv[1]))
for e in v.errors(): print("ERR", e.toString())
v.show()
QTimer.singleShot(int(sys.argv[4]) if len(sys.argv) > 4 else 1500, lambda: (v.grabWindow().save(sys.argv[3]), app.quit()))
app.exec()
