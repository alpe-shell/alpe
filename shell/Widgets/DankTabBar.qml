import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeTabBar {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankTabBar", "AlpeTabBar", "qs.Alpe.Widgets")
}
