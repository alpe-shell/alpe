import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeSpinner {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankSpinner", "AlpeSpinner", "qs.Alpe.Widgets")
}
