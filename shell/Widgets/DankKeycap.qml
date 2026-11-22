import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeKeycap {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankKeycap", "AlpeKeycap", "qs.Alpe.Widgets")
}
