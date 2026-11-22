import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeSVGIcon {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankSVGIcon", "AlpeSVGIcon", "qs.Alpe.Widgets")
}
