import QtQuick
import qs.Common
import qs.Alpe.Dash.Overview as New

New.CalendarEventEditor {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "CalendarEventEditor", "qs.Modules.DankDash.Overview", "qs.Alpe.Dash.Overview")
}
