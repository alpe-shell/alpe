import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.KeyboardLayoutName {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "KeyboardLayoutName", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
