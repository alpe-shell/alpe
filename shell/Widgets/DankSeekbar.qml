import QtQuick
import qs.Common

AlpeSeekbar {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankSeekbar", "AlpeSeekbar", "qs.Widgets")
}
