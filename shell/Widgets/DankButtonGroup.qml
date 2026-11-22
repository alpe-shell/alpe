import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeButtonGroup {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankButtonGroup", "AlpeButtonGroup", "qs.Alpe.Widgets")
}
