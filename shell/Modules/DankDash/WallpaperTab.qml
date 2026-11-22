import QtQuick
import qs.Common
import qs.Alpe.Dash as New

New.WallpaperTab {
    id: shim
    Component.onCompleted: Deprecation.module(shim, "WallpaperTab", "qs.Modules.DankDash", "qs.Alpe.Dash")
}
