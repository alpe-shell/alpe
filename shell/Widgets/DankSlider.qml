import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeSlider {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankSlider", "AlpeSlider", "qs.Alpe.Widgets")
}
