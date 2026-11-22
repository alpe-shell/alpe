import QtQuick
import qs.Common
import qs.Alpe.Dash.Overview as New

New.CalendarOverviewCard {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "CalendarOverviewCard", "qs.Modules.DankDash.Overview", "qs.Alpe.Dash.Overview")
}
