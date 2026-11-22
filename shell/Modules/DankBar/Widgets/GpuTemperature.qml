import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.GpuTemperature {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "GpuTemperature", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
