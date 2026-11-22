import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeToggle {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankToggle", "AlpeToggle", "qs.Alpe.Widgets")
}
