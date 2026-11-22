import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.Weather {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "Weather", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
