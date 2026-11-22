import QtQuick
import qs.Common
import qs.Alpe.Widgets as Alpe

Alpe.AlpeTooltipV2 {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankTooltipV2", "AlpeTooltipV2", "qs.Alpe.Widgets")
}
