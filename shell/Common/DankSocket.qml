import QtQuick
import qs.Alpe.Common as Alpe

Alpe.AlpeSocket {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankSocket", "AlpeSocket", "qs.Alpe.Common")
}
