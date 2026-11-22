import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeTextEdit {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankTextEdit", "AlpeTextEdit", "qs.Alpe.Widgets")
}
