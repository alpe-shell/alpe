import QtQuick
import qs.Common
import qs.Alpe.Dash.Overview as New

New.SystemMonitorCard {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "SystemMonitorCard", "qs.Modules.DankDash.Overview", "qs.Alpe.Dash.Overview")
}
