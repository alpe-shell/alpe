pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Alpe.Widgets
import qs.Modules.Settings.Widgets

// Alpe: dieselbe Shell auf verschiedenen Rechnern. Die Seite zeigt, was Alpe am Gerät erkennt
// und was es daraus ableitet – welche Seiten erscheinen, wer sperrt, wer die Helligkeit stellt.
// Es gibt keine getrennten Ausgaben für Desktop und Laptop; entschieden wird zur Laufzeit.
Item {
    id: root

    property var parentModal: null

    property string model: ""
    property string arch: ""
    property string chassis: ""

    readonly property var keyboardLight: BrightnessService.devices.find(dev => dev.class === "leds" && String(dev.id).includes("kbd")) ?? null
    readonly property var screens: BrightnessService.devices.filter(dev => dev.class !== "leds")

    // Alpe: Ladegrenze, Zuklappen (über scripts/alpe-root.sh mit pkexec)
    readonly property string rootScript: Quickshell.shellDir + "/scripts/alpe-root.sh"
    property int chargeNow: -1
    property int chargeWanted: 80
    property bool chargePersistent: false
    property var lid: ({ "HandleLidSwitch": "", "HandleLidSwitchExternalPower": "", "HandleLidSwitchDocked": "" })
    property var lidWanted: ({})
    property string message: ""
    readonly property var lidValues: ["suspend", "lock", "ignore", "hibernate", "poweroff"]
    readonly property var lidLabels: ["Standby", "Nur sperren", "Nichts tun", "Ruhezustand (Disk)", "Ausschalten"]

    function readState() {
        Proc.runCommand("alpe-device-state", ["sh", "-c", 'for b in /sys/class/power_supply/*; do [ "$(cat $b/type 2>/dev/null)" = Battery ] && [ -f $b/charge_control_end_threshold ] && { echo "charge=$(cat $b/charge_control_end_threshold)"; break; }; done; [ -f /etc/alpe/ladegrenze ] && echo persist=1; for k in HandleLidSwitch HandleLidSwitchExternalPower HandleLidSwitchDocked; do printf "%s=" $k; busctl --json=short get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager $k 2>/dev/null || printf "{}"; echo; done'], (out, code) => {
            const next = Object.assign({}, root.lid);
            root.chargePersistent = false;
            for (const line of String(out).split("\n")) {
                const cut = line.indexOf("=");
                if (cut < 0)
                    continue;
                const key = line.slice(0, cut), value = line.slice(cut + 1).trim();
                if (key === "charge") {
                    root.chargeNow = parseInt(value);
                    root.chargeWanted = root.chargeNow;
                } else if (key === "persist")
                    root.chargePersistent = true;
                else if (key in next) {
                    try {
                        next[key] = String(JSON.parse(value).data || "");
                    } catch (e) {}
                }
            }
            root.lid = next;
            root.lidWanted = Object.assign({}, next);
        }, 0, 8000);
    }

    function runRoot(args, done) {
        root.message = "";
        Proc.runCommand("alpe-root-" + args[0], ["pkexec", "/bin/sh", rootScript].concat(args), (out, code) => {
            root.message = code === 0 ? "" : code === 126 || code === 127 ? "Abgebrochen (keine Berechtigung)." : "Fehlgeschlagen: " + String(out).trim();
            root.readState();
            if (done)
                done(code === 0);
        }, 0, 120000);
    }


    function kindText() {
        if (SettingsTabs.isLaptop)
            return "Laptop (Akku vorhanden)";
        return chassis === "laptop" ? "Laptop ohne erkannten Akku" : "Desktop (kein Akku)";
    }

    function brightnessText() {
        if (screens.length === 0)
            return "Kein regelbarer Bildschirm gefunden";
        const names = screens.map(dev => BrightnessService.deviceTitle(dev)).join(", ");
        if (screens[0].class === "kde")
            return "Über Plasma" + (BrightnessService.kdeBackend === "kscreen" ? " (kscreen-doctor)" : "") + " · " + names;
        return "Über den Alpe-Dienst · " + names;
    }

    function parse(text) {
        for (const line of text.split("\n")) {
            const cut = line.indexOf("=");
            if (cut < 0)
                continue;
            const value = line.slice(cut + 1).replace(/\u0000/g, "").trim();
            switch (line.slice(0, cut)) {
            case "model":
                model = value;
                break;
            case "arch":
                arch = value;
                break;
            case "chassis":
                chassis = value;
                break;
            }
        }
    }

    Component.onCompleted: {
        BatteryService.addRef();
        readState();
    }
    Component.onDestruction: BatteryService.removeRef()

    Process {
        running: true
        // Apple Silicon und andere ARM-Geräte nennen ihr Modell im Gerätebaum, PCs im DMI.
        command: ["sh", "-c", 'if [ -r /proc/device-tree/model ]; then m="$(tr -d "\\000" < /proc/device-tree/model)"; else m="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null) $(cat /sys/class/dmi/id/product_name 2>/dev/null)"; fi; printf "model=%s\\n" "$m"; printf "arch=%s\\n" "$(uname -m)"; c="$(cat /sys/class/dmi/id/chassis_type 2>/dev/null)"; case "$c" in 8|9|10|14|31|32) echo chassis=laptop ;; "") echo chassis= ;; *) echo chassis=desktop ;; esac']
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    component StateRow: SettingsRow {
        property bool on: true
        resetKeys: []
        iconColor: on ? Theme.primary : Theme.surfaceVariantText
    }

    SettingsPage {
        SettingsCard {
            width: parent.width
            iconName: "devices"
            title: "Erkannt"
            settingKey: "alpeDevice"

            SettingsRow {
                title: root.model !== "" ? root.model : "Unbekanntes Modell"
                subtitle: root.kindText() + (root.arch !== "" ? " · " + root.arch : "")
                iconName: SettingsTabs.isLaptop ? "laptop_mac" : "desktop_windows"
            }

            SettingsRow {
                title: "Fensterverwaltung"
                iconName: "select_window"
                trailingBadge: CompositorService.displayName
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "rule"
            title: "Was Alpe daraus ableitet"
            settingKey: "alpeDeviceDerived"

            StateRow {
                on: BatteryService.batteryAvailable
                title: "Akku"
                subtitle: BatteryService.batteryAvailable ? "Vorhanden: Seite «Akku», Akkuanzeige und getrennte Zeiten für Netz- und Akkubetrieb sind da." : "Keiner: Akku-Seite, Akkuanzeige und Akku-Symbole entfallen."
                iconName: BatteryService.batteryAvailable ? "battery_full" : "power"
            }

            StateRow {
                on: SettingsTabs.wifiShown
                title: "WLAN"
                subtitle: !SettingsTabs.wifiPresent ? "Kein WLAN-Gerät: Seite ausgeblendet." : SettingsTabs.wifiShown ? "WLAN-Gerät vorhanden: Seite sichtbar." : "WLAN-Gerät vorhanden, Seite ausgeblendet (Vorgabe ohne Akku; änderbar in der Seitenauswahl)."
                iconName: SettingsTabs.wifiShown ? "wifi" : "wifi_off"
            }

            StateRow {
                title: "Sperrbildschirm"
                subtitle: CompositorService.isKwin ? "KDE-Sperrbildschirm – KWin lässt keinen anderen zu." : "Eigener Sperrbildschirm der Shell."
                iconName: "lock"
            }

            StateRow {
                on: root.screens.length > 0
                title: "Bildschirmhelligkeit"
                subtitle: root.brightnessText()
                iconName: "brightness_medium"
            }

            StateRow {
                on: KwinService.gripEnabled
                title: "Fenster am oberen Rand ziehen"
                subtitle: !CompositorService.isKwin ? "Nur unter KWin nötig; hier bewegt die Fensterverwaltung die Fenster selbst." : KwinService.gripEnabled ? "Eingeschaltet." : "Ausgeschaltet."
                iconName: "drag_pan"
            }

            StateRow {
                on: SystemUpdateService.scriptMode
                title: "Systemaktualisierung"
                subtitle: SystemUpdateService.scriptMode ? "Über «" + SystemUpdateService.scriptCommand + "» im Terminal." : "Über den Alpe-Dienst – kein «" + Brand.updateCommand + "» im Suchpfad."
                iconName: "system_update_alt"
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "laptop_mac"
            title: "Unterwegs"
            settingKey: "alpeDeviceLaptop"
            visible: SettingsTabs.isLaptop || root.keyboardLight !== null

            SettingsSliderRow {
                visible: root.keyboardLight !== null
                text: "Tastaturbeleuchtung"
                unit: "%"
                minimum: 0
                maximum: 100
                value: root.keyboardLight ? BrightnessService.getDeviceBrightness(root.keyboardLight.id) : 0
                onSliderValueChanged: newValue => {
                    if (root.keyboardLight)
                        BrightnessService.setBrightness(newValue, root.keyboardLight.id, true);
                }
            }

            SettingsDropdownRow {
                visible: root.keyboardLight !== null
                readonly property var values: [0, 10, 30, 60, 120, 300]
                readonly property var labels: ["Nie", "10 Sekunden", "30 Sekunden", "1 Minute", "2 Minuten", "5 Minuten"]
                text: "Tastaturbeleuchtung aus nach"
                description: "Ohne Eingabe; bei der nächsten Taste wieder wie vorher."
                options: labels
                currentValue: {
                    const i = values.indexOf(SettingsData.alpeKbdIdleOff);
                    return labels[i >= 0 ? i : 2];
                }
                onValueChanged: value => SettingsData.set("alpeKbdIdleOff", values[labels.indexOf(value)])
            }

            SettingsToggleRow {
                visible: root.keyboardLight !== null
                text: "Tastaturbeleuchtung aus beim Sperren"
                checked: SettingsData.alpeKbdOffWhenLocked
                onToggled: checked => SettingsData.set("alpeKbdOffWhenLocked", checked)
            }

            SettingsNavRow {
                visible: SettingsTabs.isLaptop
                title: I18n.tr("Battery")
                hint: "Ladelimit, Warnungen, Energieprofile je Stromquelle"
                iconName: "battery_charging_full"
                onClicked: keyboard => root.parentModal?.navigateTo("battery", keyboard)
            }

            SettingsNavRow {
                visible: SettingsTabs.isLaptop
                title: I18n.tr("Power & sleep")
                hint: "Sperren, Bildschirm aus und Standby – getrennt für Netz und Akku"
                iconName: "power_settings_new"
                onClicked: keyboard => root.parentModal?.navigateTo("power_sleep", keyboard)
            }
        }

        // ---------------------------------------------------------- Akku schonen
        SettingsCard {
            width: parent.width
            iconName: "battery_charging_80"
            title: "Akku schonen"
            settingKey: "alpeDeviceCharge"
            visible: SettingsTabs.isLaptop && root.chargeNow > 0
            tags: ["ladegrenze", "akku", "charge limit", "macbook", "asahi"]

            SettingsSliderRow {
                text: "Laden bis"
                description: "Der Akku lädt nur bis hier und hält den Stand am Netzteil; das schont ihn, wenn das MacBook meist angeschlossen ist. Gerade eingestellt: " + root.chargeNow + " %" + (root.chargePersistent ? ", beim Start wiederhergestellt." : root.chargeNow < 100 ? ", aber nicht nach einem Neustart." : ".")
                unit: "%"
                minimum: 50
                maximum: 100
                step: 5
                value: root.chargeWanted
                onSliderDragFinished: v => root.chargeWanted = v
            }

            SettingsRow {
                title: root.chargeWanted === root.chargeNow && (root.chargePersistent || root.chargeNow === 100) ? "Übernommen" : "Grenze " + root.chargeWanted + " % übernehmen"
                subtitle: "Braucht einmal dein Passwort. Ein kleiner Systemdienst (alpe-ladegrenze) setzt den Wert nach jedem Start wieder; bei 100 % wird er entfernt."
                iconName: "lock_open"

                AlpeButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Übernehmen"
                    variant: "tonal"
                    enabled: !(root.chargeWanted === root.chargeNow && (root.chargePersistent || root.chargeNow === 100))
                    onClicked: root.runRoot(["charge", String(root.chargeWanted)])
                }
            }
        }

        // ---------------------------------------------------------- Zuklappen
        SettingsCard {
            width: parent.width
            iconName: "laptop_chromebook"
            title: "Zuklappen"
            settingKey: "alpeDeviceLid"
            visible: SettingsTabs.isLaptop && root.lid.HandleLidSwitch !== ""
            tags: ["deckel", "zuklappen", "lid", "logind", "standby"]

            Repeater {
                model: [["HandleLidSwitch", "Im Akkubetrieb"], ["HandleLidSwitchExternalPower", "Am Netzteil"], ["HandleLidSwitchDocked", "Mit externem Bildschirm"]]

                SettingsDropdownRow {
                    required property var modelData
                    width: parent ? parent.width : 0
                    text: modelData[1]
                    options: root.lidLabels
                    currentValue: {
                        const v = root.lidWanted[modelData[0]] || root.lid[modelData[0]];
                        const i = root.lidValues.indexOf(v);
                        return i >= 0 ? root.lidLabels[i] : v;
                    }
                    onValueChanged: value => {
                        const next = Object.assign({}, root.lidWanted);
                        next[modelData[0]] = root.lidValues[root.lidLabels.indexOf(value)];
                        root.lidWanted = next;
                    }
                }
            }

            SettingsRow {
                readonly property bool dirty: JSON.stringify(root.lidWanted) !== JSON.stringify(root.lid)
                title: dirty ? "Änderungen übernehmen" : "Übernommen"
                subtitle: "Gilt systemweit über logind (/etc/systemd/logind.conf.d/60-alpe-deckel.conf); braucht einmal dein Passwort."
                iconName: "lock_open"

                AlpeButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Übernehmen"
                    variant: "tonal"
                    enabled: parent.dirty
                    onClicked: root.runRoot(["lid", root.lidWanted.HandleLidSwitch || "suspend", root.lidWanted.HandleLidSwitchExternalPower || "suspend", root.lidWanted.HandleLidSwitchDocked || "ignore"])
                }
            }

            SettingsNoteRow {
                visible: root.message !== ""
                text: root.message
            }
        }
    }
}
