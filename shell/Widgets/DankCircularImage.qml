import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeCircularImage {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankCircularImage", "AlpeCircularImage", "qs.Alpe.Widgets")
}
