import QtQuick
import qs.Common

AlpeFocusGrab {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankFocusGrab", "AlpeFocusGrab", "qs.Widgets")
}
