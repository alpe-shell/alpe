pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Alpe.Widgets
import qs.Modules.Settings.Widgets

// Alpe: Akkustände von Maus, Tastatur und Headset. Was UPower meldet, erscheint von selbst;
// Funk-Headsets mit eigenem Empfänger kommen über HeadsetService dazu.
Item {
    id: root

    property var parentModal: null

    readonly property var intervalValues: [60, 120, 300, 600, 900]
    readonly property var intervalOptions: intervalValues.map(seconds => I18n.duration(seconds))

    function percentColor(percentage) {
        if (percentage <= SettingsData.headsetBatteryLowThreshold)
            return Theme.error;
        if (percentage <= 30)
            return Theme.warning;
        return Theme.surfaceVariantText;
    }

    function headsetSubtitle(dev) {
        switch (dev.state) {
        case "ok":
            return dev.charging ? "Lädt" : "Verbunden";
        case "off":
            return "Ausgeschaltet oder ausser Reichweite";
        default:
            return "Keine Antwort vom Headset";
        }
    }

    function toolName(tool) {
        return tool === "hyper_headset_cli" ? "HyperHeadset" : tool === "headsetcontrol" ? "HeadsetControl" : "";
    }

    function headsetStatus() {
        if (!HeadsetService.checked)
            return HeadsetService.busy ? "Wird abgefragt …" : "Noch nicht abgefragt";
        if (HeadsetService.toolMissing)
            return "Kein Auslesewerkzeug installiert";
        if (HeadsetService.devices.length === 0)
            return HeadsetService.error === "nodevice" ? "Kein unterstütztes Headset gefunden – steckt der Empfänger?" : HeadsetService.error;
        return "über " + toolName(HeadsetService.tool);
    }

    Component.onCompleted: {
        BatteryService.addRef();
        HeadsetService.addRef();
    }
    Component.onDestruction: {
        BatteryService.removeRef();
        HeadsetService.removeRef();
    }

    SettingsPage {
        SettingsCard {
            width: parent.width
            iconName: "battery_full"
            title: "Geräte"
            settingKey: "alpePeripherals"

            Repeater {
                model: ScriptModel {
                    values: BatteryService.upowerPeripherals
                }

                SettingsRow {
                    id: upowerRow
                    required property var modelData
                    title: modelData.name
                    subtitle: modelData.charging ? "Lädt" : "Verbunden"
                    iconName: modelData.icon
                    trailingBadge: modelData.percentage + " %"
                    trailingBadgeColor: root.percentColor(modelData.percentage)
                }
            }

            Repeater {
                model: ScriptModel {
                    values: SettingsData.headsetBatteryEnabled ? HeadsetService.devices : []
                }

                SettingsRow {
                    id: headsetRow
                    required property var modelData
                    title: modelData.name
                    subtitle: root.headsetSubtitle(modelData)
                    iconName: "headset_mic"
                    trailingBadge: modelData.percentage >= 0 ? modelData.percentage + " %" : "–"
                    trailingBadgeColor: modelData.percentage >= 0 ? root.percentColor(modelData.percentage) : Theme.surfaceVariantText
                }
            }

            SettingsRow {
                visible: BatteryService.upowerPeripherals.length === 0 && (!SettingsData.headsetBatteryEnabled || HeadsetService.devices.length === 0)
                title: "Keine Geräte mit Akkustand"
                subtitle: "Funkmaus oder Tastatur erscheinen, sobald sie verbunden sind."
                iconName: "battery_unknown"
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "headset_mic"
            title: "Headset"
            settingKey: "alpeHeadset"

            SettingsToggleRow {
                settingKey: "headsetBatteryEnabled"
                tags: ["headset", "battery", "akku", "hyperx", "kopfhörer"]
                text: "Akkustand des Headsets auslesen"
                description: "Erscheint hier und als Ring in der Energie-Anzeige neben der Maus."
                checked: SettingsData.headsetBatteryEnabled
                onToggled: checked => SettingsData.set("headsetBatteryEnabled", checked)
            }

            SettingsRow {
                visible: SettingsData.headsetBatteryEnabled
                title: "Status"
                subtitle: root.headsetStatus()
                iconName: HeadsetService.toolMissing || (HeadsetService.checked && HeadsetService.devices.length === 0) ? "error_outline" : "check_circle"
                iconColor: HeadsetService.toolMissing || (HeadsetService.checked && HeadsetService.devices.length === 0) ? Theme.warning : Theme.primary

                AlpeButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonHeight: Theme.buttonHeightS
                    text: "Jetzt abfragen"
                    iconName: "refresh"
                    busy: HeadsetService.busy
                    enabled: !HeadsetService.busy
                    backgroundColor: SettingsMetrics.controlSurface
                    textColor: Theme.surfaceText
                    onClicked: HeadsetService.refresh()
                }
            }

            SettingsNoteRow {
                visible: SettingsData.headsetBatteryEnabled && HeadsetService.toolMissing
                noteIconName: "terminal"
                monospace: true
                text: "paru -S headsetcontrol        # die meisten Headsets, HyperX Cloud II Wireless\nparu -S hyper-headset-bin     # HyperX, auch Cloud II Core Wireless"
            }

            SettingsNoteRow {
                visible: SettingsData.headsetBatteryEnabled && HeadsetService.checked && !HeadsetService.toolMissing && HeadsetService.devices.length === 0
                noteIconName: "info"
                text: "Installiert: " + HeadsetService.tools.map(tool => root.toolName(tool)).join(", ") + ". Findet keines davon das Headset, fehlt meist die udev-Regel (Empfänger nach der Installation einmal aus- und einstecken) oder das Modell wird vom anderen Werkzeug unterstützt."
            }

            SettingsDropdownRow {
                settingKey: "headsetBatteryInterval"
                visible: SettingsData.headsetBatteryEnabled
                text: "Abfrage im Hintergrund"
                description: "Für die Warnung. Solange eine Anzeige offen ist, wird alle 30 Sekunden abgefragt."
                enabled: SettingsData.headsetBatteryNotifyLow
                options: root.intervalOptions
                currentValue: root.intervalOptions[Math.max(0, root.intervalValues.indexOf(SettingsData.headsetBatteryInterval))]
                onValueChanged: value => {
                    const index = root.intervalOptions.indexOf(value);
                    if (index >= 0)
                        SettingsData.set("headsetBatteryInterval", root.intervalValues[index]);
                }
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "notifications"
            title: "Warnung"
            settingKey: "alpeHeadsetAlert"
            visible: SettingsData.headsetBatteryEnabled

            SettingsToggleRow {
                settingKey: "headsetBatteryNotifyLow"
                text: "Bei tiefem Akkustand warnen"
                description: "Einmal je Entladung, als Hinweis am Bildschirmrand."
                checked: SettingsData.headsetBatteryNotifyLow
                onToggled: checked => SettingsData.set("headsetBatteryNotifyLow", checked)
            }

            SettingsSliderRow {
                settingKey: "headsetBatteryLowThreshold"
                text: "Schwelle"
                unit: "%"
                enabled: SettingsData.headsetBatteryNotifyLow
                value: SettingsData.headsetBatteryLowThreshold
                minimum: 5
                maximum: 40
                onSliderValueChanged: newValue => SettingsData.set("headsetBatteryLowThreshold", newValue)
            }
        }
    }
}
