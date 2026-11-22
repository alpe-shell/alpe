import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.ControlCenterButton {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "ControlCenterButton", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
