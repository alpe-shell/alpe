import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeBlink {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankBlink", "AlpeBlink", "qs.Alpe.Widgets")
}
