import QtQuick
import qs.Common
import qs.Alpe.Dash.Overview as New

New.UserInfoCard {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "UserInfoCard", "qs.Modules.DankDash.Overview", "qs.Alpe.Dash.Overview")
}
