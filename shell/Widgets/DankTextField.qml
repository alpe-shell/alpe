import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeTextField {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankTextField", "AlpeTextField", "qs.Alpe.Widgets")
}
