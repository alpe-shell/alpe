import QtQuick
import qs.Alpe.Common as Alpe

Alpe.AlpeColorAnim {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankColorAnim", "AlpeColorAnim", "qs.Alpe.Common")
}
