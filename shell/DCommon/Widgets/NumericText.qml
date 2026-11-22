// Übergang bis D7.8 (Plan 2.3.0): Hülle für Plugins, die noch qs.DCommon.Widgets importieren.
import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.NumericText {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "NumericText", "qs.DCommon.Widgets", "qs.Alpe.Widgets")
}
