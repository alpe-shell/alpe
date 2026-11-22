import QtQuick
import Quickshell.Wayland
import qs.Common

FadeOverlayWindow {
    WlrLayershell.namespace: "alpe:fade-to-dpms"
    fadeEnabled: SettingsData.fadeToDpmsEnabled
    gracePeriod: SettingsData.fadeToDpmsGracePeriod
    overlayColor: Theme.screenOffColor
}
