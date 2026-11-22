import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeScrollbar {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankScrollbar", "AlpeScrollbar", "qs.Alpe.Widgets")
}
