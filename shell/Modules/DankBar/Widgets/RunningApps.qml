import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.RunningApps {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "RunningApps", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
