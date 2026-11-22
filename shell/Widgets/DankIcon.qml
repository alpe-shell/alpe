import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeIcon {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankIcon", "AlpeIcon", "qs.Alpe.Widgets")
}
