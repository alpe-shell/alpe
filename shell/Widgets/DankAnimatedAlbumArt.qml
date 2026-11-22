import QtQuick
import qs.Common

AlpeAnimatedAlbumArt {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankAnimatedAlbumArt", "AlpeAnimatedAlbumArt", "qs.Widgets")
}
