import QtQuick
import qs.Common

AlpeFloatingWindow {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankFloatingWindow", "AlpeFloatingWindow", "qs.Widgets")
}
