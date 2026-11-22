import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeColorSwatch {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankColorSwatch", "AlpeColorSwatch", "qs.Alpe.Widgets")
}
