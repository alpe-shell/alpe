import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeTextCursor {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankTextCursor", "AlpeTextCursor", "qs.Alpe.Widgets")
}
