import QtQuick
import qs.Alpe.Common as Alpe

Alpe.AlpeAnim {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankAnim", "AlpeAnim", "qs.Alpe.Common")
}
