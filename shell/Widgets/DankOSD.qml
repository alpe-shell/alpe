import QtQuick
import qs.Common

AlpeOSD {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankOSD", "AlpeOSD", "qs.Widgets")
}
