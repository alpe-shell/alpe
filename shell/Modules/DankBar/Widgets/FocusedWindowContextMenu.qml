import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.FocusedWindowContextMenu {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "FocusedWindowContextMenu", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
