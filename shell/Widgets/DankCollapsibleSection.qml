import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeCollapsibleSection {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankCollapsibleSection", "AlpeCollapsibleSection", "qs.Alpe.Widgets")
}
