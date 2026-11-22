import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.FocusedApp {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "FocusedApp", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
