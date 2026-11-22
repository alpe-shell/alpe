import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.Battery {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "Battery", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
