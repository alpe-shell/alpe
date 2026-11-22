import QtQuick
import qs.Common

AlpePopout {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankPopout", "AlpePopout", "qs.Widgets")
}
