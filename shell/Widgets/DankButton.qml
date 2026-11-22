import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeButton {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankButton", "AlpeButton", "qs.Alpe.Widgets")
}
