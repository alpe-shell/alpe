import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeFilterChips {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankFilterChips", "AlpeFilterChips", "qs.Alpe.Widgets")
}
