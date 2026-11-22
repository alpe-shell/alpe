// Übergang bis D7.8 (Plan 2.3.0): Hülle für Plugins, die noch qs.DCommon.Widgets importieren.
import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeDropdown {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DDropdown", "AlpeDropdown", "qs.Alpe.Widgets")
}
