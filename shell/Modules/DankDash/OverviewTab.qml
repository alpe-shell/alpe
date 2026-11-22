import QtQuick
import qs.Common
import qs.Alpe.Dash as New

New.OverviewTab {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "OverviewTab", "qs.Modules.DankDash", "qs.Alpe.Dash")
}
