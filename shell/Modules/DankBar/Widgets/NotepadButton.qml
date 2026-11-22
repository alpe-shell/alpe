import QtQuick
import qs.Common
import qs.Modules.Bar.Widgets as New

New.NotepadButton {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "NotepadButton", "qs.Modules.DankBar.Widgets", "qs.Modules.Bar.Widgets")
}
