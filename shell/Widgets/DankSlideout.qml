import QtQuick
import qs.Common

AlpeSlideout {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankSlideout", "AlpeSlideout", "qs.Widgets")
}
