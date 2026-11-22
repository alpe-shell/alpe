import QtQuick
import qs.Common

AlpeModal {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankModal", "AlpeModal", "qs.Modals.Common")
}
