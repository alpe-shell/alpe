pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Alpe.Widgets
import qs.Widgets

Item {
    id: root

    property string mode: "apps"
    property real size: Theme.iconSize
    property real appsIconSize: size
    property color appsIconColor: Theme.widgetIconColor
    property string colorOverride: ""
    property real brightness: 0.5
    property real contrast: 1
    property string customPath: ""
    property bool fallbackToApps: false

    readonly property string resolvedColor: {
        switch (colorOverride) {
        case "primary":
            return Theme.primary;
        case "surface":
            return Theme.surfaceText;
        default:
            return colorOverride;
        }
    }
    readonly property bool colorize: resolvedColor !== ""
    readonly property string resolvedMode: {
        const fallback = fallbackToApps ? "apps" : "";
        switch (mode) {
        case "custom":
            return customPath !== "" ? "custom" : fallback;
        case "compositor":
            return CompositorService.isKnownCompositor ? "compositor" : fallback;
        case "os":
        case "alpe":
            return mode;
        case "apps":
            return "apps";
        default:
            return fallback;
        }
    }
    readonly property string compositorSource: {
        switch (CompositorService.compositor) {
        case "hyprland":
            return "file://" + Theme.shellDir + "/assets/hyprland.svg";
        default:
            return "";
        }
    }

    width: size
    height: size

    AlpeIcon {
        visible: root.resolvedMode === "apps"
        anchors.centerIn: parent
        name: "apps"
        size: root.appsIconSize
        color: root.appsIconColor
    }

    SystemLogo {
        visible: root.resolvedMode === "os"
        anchors.centerIn: parent
        width: root.size
        height: root.size
        colorOverride: root.resolvedColor
        brightnessOverride: root.brightness
        contrastOverride: root.contrast
    }

    // Alpe-Zeichen: gezeichnet aus Alpe/Widgets/LogoShape.js (dieselbe Quelle wie die Material-Vorlage «Alpe»).
    Loader {
        active: root.resolvedMode === "alpe"
        anchors.centerIn: parent
        width: root.size
        height: root.size
        sourceComponent: AlpeMaterialShape {
            shape: "alpeLogo"
            respectThemeShape: false
            color: root.colorize ? root.resolvedColor : "#ffffff"
        }
    }

    IconImage {
        visible: root.resolvedMode === "compositor"
        anchors.centerIn: parent
        width: root.size
        height: root.size
        smooth: true
        asynchronous: true
        source: root.compositorSource
        layer.enabled: root.colorize
        layer.effect: MultiEffect {
            saturation: 0
            colorization: 1
            colorizationColor: root.resolvedColor
            brightness: root.brightness
            contrast: root.contrast
        }
    }

    IconImage {
        visible: root.resolvedMode === "custom"
        anchors.centerIn: parent
        width: root.size
        height: root.size
        smooth: true
        asynchronous: true
        source: root.customPath ? "file://" + root.customPath.replace("file://", "") : ""
        layer.enabled: root.colorize
        layer.effect: MultiEffect {
            saturation: 0
            colorization: 1
            colorizationColor: root.resolvedColor
            brightness: root.brightness
            contrast: root.contrast
        }
    }
}
