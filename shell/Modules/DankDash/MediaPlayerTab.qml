import QtQuick
import qs.Common
import qs.Alpe.Dash as New

New.MediaPlayerTab {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "MediaPlayerTab", "qs.Modules.DankDash", "qs.Alpe.Dash")
}
