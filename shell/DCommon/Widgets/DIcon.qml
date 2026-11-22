// Übergang bis D7.8 (Plan 2.3.0): Hülle für Plugins, die noch qs.DCommon.Widgets importieren.
import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeIcon {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DIcon", "AlpeIcon", "qs.Alpe.Widgets")
}
