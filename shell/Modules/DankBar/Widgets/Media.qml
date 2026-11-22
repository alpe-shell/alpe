import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.Media {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "Media", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
