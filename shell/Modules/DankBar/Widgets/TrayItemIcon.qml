import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.TrayItemIcon {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "TrayItemIcon", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
