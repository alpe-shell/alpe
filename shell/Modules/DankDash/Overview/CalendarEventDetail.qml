import QtQuick
import qs.Common
import qs.Alpe.Dash.Overview as New

New.CalendarEventDetail {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "CalendarEventDetail", "qs.Modules.DankDash.Overview", "qs.Alpe.Dash.Overview")
}
