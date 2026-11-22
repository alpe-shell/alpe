import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeFlickable {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankFlickable", "AlpeFlickable", "qs.Alpe.Widgets")
}
