import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.RamMonitor {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "RamMonitor", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
