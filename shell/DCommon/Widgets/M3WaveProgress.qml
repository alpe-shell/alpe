// Übergang bis D7.8 (Plan 2.3.0): Hülle für Plugins, die noch qs.DCommon.Widgets importieren.
import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.M3WaveProgress {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "M3WaveProgress", "qs.DCommon.Widgets", "qs.Alpe.Widgets")
}
