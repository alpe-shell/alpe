import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.NetworkMonitor {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "NetworkMonitor", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
