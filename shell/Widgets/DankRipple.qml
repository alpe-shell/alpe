import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeRipple {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankRipple", "AlpeRipple", "qs.Alpe.Widgets")
}
