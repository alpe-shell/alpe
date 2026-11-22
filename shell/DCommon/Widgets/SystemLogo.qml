// Übergang bis D7.8 (Plan 2.3.0): Hülle für Plugins, die noch qs.DCommon.Widgets importieren.
import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.SystemLogo {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "SystemLogo", "qs.DCommon.Widgets", "qs.Alpe.Widgets")
}
