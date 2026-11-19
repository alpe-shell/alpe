import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services

// Alpe: Tastaturbeleuchtung (MacBook und andere Laptops mit leds/*kbd_backlight*).
// Aus nach einer Zeit ohne Eingabe (alpeKbdIdleOff, Sekunden, 0 = nie) und beim Sperren
// (alpeKbdOffWhenLocked); bei der nächsten Eingabe bzw. beim Entsperren wieder wie vorher.
// Gesetzt wird über BrightnessService (logind, ohne Root).
Item {
    id: root

    readonly property var light: BrightnessService.devices.find(dev => dev.class === "leds" && String(dev.id).includes("kbd")) ?? null
    readonly property string device: light ? String(light.id) : ""
    property real saved: -1
    property bool dimmedByUs: false

    function dim() {
        if (device === "" || dimmedByUs)
            return;
        const now = BrightnessService.getDeviceBrightness(device);
        if (now <= 0)
            return;
        saved = now;
        dimmedByUs = true;
        BrightnessService.setBrightness(0, device, true);
    }

    function restore() {
        if (!dimmedByUs)
            return;
        dimmedByUs = false;
        if (saved > 0 && !(SettingsData.alpeKbdOffWhenLocked && SessionService.locked))
            BrightnessService.setBrightness(saved, device, true);
    }

    IdleMonitor {
        enabled: root.device !== "" && SettingsData.alpeKbdIdleOff > 0
        timeout: Math.max(5, SettingsData.alpeKbdIdleOff)
        respectInhibitors: false
        onIsIdleChanged: isIdle ? root.dim() : root.restore()
    }

    Connections {
        target: SessionService
        enabled: root.device !== "" && SettingsData.alpeKbdOffWhenLocked
        function onLockedChanged() {
            if (SessionService.locked)
                root.dim();
            else
                root.restore();
        }
    }
}
