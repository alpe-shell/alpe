import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeListView {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankListView", "AlpeListView", "qs.Alpe.Widgets")
}
