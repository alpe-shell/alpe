import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.WorkspaceSwitcher {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "WorkspaceSwitcher", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
