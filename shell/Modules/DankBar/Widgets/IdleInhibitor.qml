import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.IdleInhibitor {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "IdleInhibitor", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
