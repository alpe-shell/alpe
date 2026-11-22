import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeNumberStepper {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankNumberStepper", "AlpeNumberStepper", "qs.Alpe.Widgets")
}
