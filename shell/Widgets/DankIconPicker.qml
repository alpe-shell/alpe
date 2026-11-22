import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeIconPicker {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankIconPicker", "AlpeIconPicker", "qs.Alpe.Widgets")
}
