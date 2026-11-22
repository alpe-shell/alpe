import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeGridView {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankGridView", "AlpeGridView", "qs.Alpe.Widgets")
}
