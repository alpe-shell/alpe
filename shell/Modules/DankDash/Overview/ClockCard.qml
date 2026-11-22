import QtQuick
import qs.Common
import qs.Alpe.Dash.Overview as New

New.ClockCard {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "ClockCard", "qs.Modules.DankDash.Overview", "qs.Alpe.Dash.Overview")
}
