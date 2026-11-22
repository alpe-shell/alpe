import QtQuick
import qs.Common
import qs.Alpe.Dash.Overview as New

New.WeatherOverviewCard {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "WeatherOverviewCard", "qs.Modules.DankDash.Overview", "qs.Alpe.Dash.Overview")
}
