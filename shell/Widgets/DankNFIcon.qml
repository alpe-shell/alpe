import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeNFIcon {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankNFIcon", "AlpeNFIcon", "qs.Alpe.Widgets")
}
