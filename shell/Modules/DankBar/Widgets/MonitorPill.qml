import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.MonitorPill {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "MonitorPill", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
