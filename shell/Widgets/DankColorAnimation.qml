import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeColorAnimation {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankColorAnimation", "AlpeColorAnimation", "qs.Alpe.Widgets")
}
