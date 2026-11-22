import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeActionButton {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankActionButton", "AlpeActionButton", "qs.Alpe.Widgets")
}
