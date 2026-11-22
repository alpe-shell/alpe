import QtQuick
import qs.Common
import qs.Alpe.Dash.Overview as New

New.Card {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "Card", "qs.Modules.DankDash.Overview", "qs.Alpe.Dash.Overview")
}
