import QtQuick
import qs.Common
import qs.Alpe.Dash as New

New.DashPopout {
    id: shim
    Component.onCompleted: Deprecation.type(shim, "DankDashPopout", "DashPopout", "qs.Alpe.Dash")
}
