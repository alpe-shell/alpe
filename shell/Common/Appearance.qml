pragma Singleton

import Quickshell
import qs.Alpe.Common as Alpe

Singleton {
    readonly property var rounding: Alpe.Appearance.rounding
    readonly property var spacing: Alpe.Appearance.spacing
    readonly property var fontSize: Alpe.Appearance.fontSize
    readonly property var anim: Alpe.Appearance.anim
}
