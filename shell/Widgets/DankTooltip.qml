import QtQuick
import qs.Common

AlpeTooltip {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankTooltip", "AlpeTooltip", "qs.Widgets")
}
