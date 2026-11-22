import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.ClipboardButton {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "ClipboardButton", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
