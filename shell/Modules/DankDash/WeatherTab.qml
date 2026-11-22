import QtQuick
import qs.Common
import qs.Alpe.Dash as New

New.WeatherTab {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "WeatherTab", "qs.Modules.DankDash", "qs.Alpe.Dash")
}
