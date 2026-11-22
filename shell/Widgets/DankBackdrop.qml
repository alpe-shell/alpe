import QtQuick
import qs.Common

AlpeBackdrop {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankBackdrop", "AlpeBackdrop", "qs.Widgets")
}
