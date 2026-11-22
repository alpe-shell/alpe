import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.NotificationCenterButton {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "NotificationCenterButton", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
