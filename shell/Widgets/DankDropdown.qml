import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeDropdown {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankDropdown", "AlpeDropdown", "qs.Alpe.Widgets")
}
