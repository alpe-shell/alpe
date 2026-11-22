import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeLocationSearch {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankLocationSearch", "AlpeLocationSearch", "qs.Alpe.Widgets")
}
