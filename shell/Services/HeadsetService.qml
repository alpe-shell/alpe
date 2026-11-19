pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

// Alpe: Akkustand kabelloser Headsets mit eigenem USB-Empfänger. UPower sieht sie nicht;
// scripts/alpe-headset.py fragt HeadsetControl oder HyperHeadset und vereinheitlicht die Antwort.
Singleton {
    id: root

    readonly property var log: Log.scoped("HeadsetService")

    // Offene Ansichten: die Energie-Anzeige (über BatteryService) und die Einstellungsseite.
    property int viewers: 0
    property int refCount: 0

    readonly property bool enabled: SettingsData.headsetBatteryEnabled
    readonly property bool watching: viewers > 0 || refCount > 0
    readonly property bool wanted: enabled && (watching || SettingsData.headsetBatteryNotifyLow)

    property bool checked: false
    property bool busy: false
    property string tool: ""
    property var tools: []
    property string error: ""
    property var devices: []
    property double lastUpdated: 0

    readonly property bool toolMissing: checked && error === "missing"
    // Für die Ringe in der Energie-Anzeige: nur Geräte mit bekanntem Stand.
    readonly property var gaugeDevices: !enabled ? [] : devices.filter(dev => dev.state === "ok" && dev.percentage >= 0).map(dev => ({
                "name": dev.name,
                "percentage": dev.percentage,
                "type": -1,
                "icon": "headset_mic",
                "charging": dev.charging
            }))

    property var _warned: ({})

    function addRef() {
        refCount++;
    }

    function removeRef() {
        refCount = Math.max(0, refCount - 1);
    }

    function refresh() {
        if (query.running)
            return;
        busy = true;
        query.running = true;
    }

    function _apply(text) {
        let data = null;
        try {
            data = JSON.parse(text);
        } catch (e) {
            if (text.trim() !== "")
                log.warn("Unlesbare Antwort:", text.slice(0, 200));
        }
        checked = true;
        busy = false;
        lastUpdated = Date.now();
        if (!data) {
            error = "unlesbare Antwort";
            devices = [];
            return;
        }
        tool = data.tool || "";
        tools = data.tools || [];
        error = data.error || "";
        devices = data.devices || [];
        _checkLow();
    }

    // Einmal je Entladung warnen; die Sperre fällt, sobald geladen wird oder der Stand
    // wieder deutlich über der Schwelle liegt.
    function _checkLow() {
        const threshold = SettingsData.headsetBatteryLowThreshold;
        const warned = Object.assign({}, _warned);
        for (const dev of devices) {
            if (dev.state !== "ok" || dev.percentage < 0)
                continue;
            if (dev.charging || dev.percentage > threshold + 5) {
                delete warned[dev.name];
                continue;
            }
            if (dev.percentage > threshold || warned[dev.name] || !SettingsData.headsetBatteryNotifyLow)
                continue;
            warned[dev.name] = true;
            ToastService.showWarning(dev.name, "Akku bei " + dev.percentage + " % – bald laden", "", "material:headset_mic");
        }
        _warned = warned;
    }

    onWantedChanged: {
        if (wanted)
            refresh();
    }

    onWatchingChanged: {
        if (watching && enabled && Date.now() - lastUpdated > 10000)
            refresh();
    }

    Component.onCompleted: {
        if (wanted)
            startup.start();
    }

    // Die Shell soll erst stehen; der Empfänger braucht nach der Anmeldung ohnehin einen Moment.
    Timer {
        id: startup
        interval: 20000
        onTriggered: root.refresh()
    }

    Timer {
        interval: root.watching ? 30000 : Math.max(30, SettingsData.headsetBatteryInterval) * 1000
        repeat: true
        running: root.wanted && !(root.toolMissing && !root.watching)
        onTriggered: root.refresh()
    }

    Process {
        id: query
        command: ["python3", Quickshell.shellDir + "/scripts/alpe-headset.py"]
        stdout: StdioCollector {
            onStreamFinished: root._apply(text)
        }
        onExited: exitCode => {
            if (exitCode === 0)
                return;
            root.checked = true;
            root.busy = false;
            root.error = "Abfrage fehlgeschlagen (Code " + exitCode + ")";
            root.devices = [];
        }
    }
}
