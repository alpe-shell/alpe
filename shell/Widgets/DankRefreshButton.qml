import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeRefreshButton {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankRefreshButton", "AlpeRefreshButton", "qs.Alpe.Widgets")
}
