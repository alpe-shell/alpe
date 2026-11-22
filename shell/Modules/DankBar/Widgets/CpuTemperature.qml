import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.CpuTemperature {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "CpuTemperature", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
