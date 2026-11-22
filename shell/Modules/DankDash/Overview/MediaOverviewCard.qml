import QtQuick
import qs.Common
import qs.Alpe.Dash.Overview as New

New.MediaOverviewCard {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "MediaOverviewCard", "qs.Modules.DankDash.Overview", "qs.Alpe.Dash.Overview")
}
