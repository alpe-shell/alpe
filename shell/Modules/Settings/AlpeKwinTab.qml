pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets

// Alpe: was unter KWin nicht die Shell, sondern KWin und Plasma regeln – an einem Ort.
Item {
    id: root

    property var parentModal: null

    // Kennung in kglobalshortcutsrc (Gruppe kwin) → Anzeigename und Symbol
    readonly property var shortcutRows: [["dms-launcher", "Starter", "grid_view"], ["dms-clipboard", "Zwischenablage", "content_paste"], ["dms-processlist", "Systemmonitor", "monitoring"], ["dms-settings", "Einstellungen", "settings"], ["dms-notifications", "Benachrichtigungen", "notifications"], ["dms-control-center", "Kontrollzentrum", "tune"], ["dms-dash", "Dashboard", "space_dashboard"], ["dms-powermenu", "Energiemenü", "power_settings_new"], ["dms-notepad", "Notizblock", "edit_note"]]
    property var shortcutKeys: ({})
    property bool shortcutsLoaded: false

    // KDE-Module: Kennung für kcmshell6, Titel, Hinweis, Symbol
    readonly property var modules: [["kcm_keys", "Kurzbefehle", "Tastenkürzel von Alpe, KWin und Programmen", "keyboard_command_key"], ["kcm_kscreen", "Bildschirme", "Auflösung, Bildwiederholrate, HDR, Skalierung", "monitor"], ["kcm_nightlight", "Nachtfarben", "Farbtemperatur nach Tageszeit", "nightlight"], ["kcm_kwinrules", "Fensterregeln", "Grösse, Position und Titelleiste je Programm", "select_window"], ["kcm_kwinoptions", "Fensterverhalten", "Fokus, Platzierung neuer Fenster, Aktionen", "web_asset"], ["kcm_kwin_effects", "Arbeitsflächen-Effekte", "Unschärfe, abgerundete Ecken, Animationen", "auto_awesome"], ["kcm_kwin_virtualdesktops", "Virtuelle Arbeitsflächen", "Anzahl, Namen, Anordnung", "view_week"], ["kcm_kwin_scripts", "KWin-Skripte", "Erweiterungen der Fensterverwaltung", "extension"], ["kcm_mouse", "Maus", "Zeigergeschwindigkeit, Beschleunigung, Tasten", "mouse"], ["kcm_keyboard", "Tastatur", "Belegung, Wiederholrate, Sondertasten", "keyboard"], ["kcm_powerdevilprofilesconfig", "Energieverwaltung von Plasma", "Läuft neben den Zeiten unter «Energie»; doppelte Abschaltzeiten hier ausschalten", "bolt"], ["kcm_screenlocker", "Bildschirmsperre", "Aussehen des Sperrbildschirms", "lock"]]
    property var availableModules: null

    // Programme für die Griffleisten: was gerade offen ist, dazu alles Ausgenommene.
    readonly property var gripApps: {
        const seen = {};
        const out = [];
        const add = id => {
            const key = String(id || "").toLowerCase();
            if (key === "" || seen[key])
                return;
            seen[key] = true;
            out.push(key);
        };
        for (const toplevel of KwinService.toplevels)
            add(toplevel.appId);
        for (const id of SettingsData.windowGripExcluded || [])
            add(id);
        return out.sort();
    }

    function gripExcluded(app) {
        return (SettingsData.windowGripExcluded || []).includes(app);
    }

    function setGripExcluded(app, excluded) {
        const list = (SettingsData.windowGripExcluded || []).filter(entry => entry !== app);
        if (excluded)
            list.push(app);
        SettingsData.set("windowGripExcluded", list);
    }

    function gripStatus() {
        if (!SettingsData.windowGripEnabled)
            return "";
        if (!KwinService.connected)
            return "Wartet auf die Brücke zu KWin";
        const count = KwinService.grips.length;
        return count === 0 ? "Zurzeit kein Fenster mit Griffleiste" : count === 1 ? "1 Griffleiste gesetzt" : count + " Griffleisten gesetzt";
    }

    function hasModule(id) {
        return availableModules === null || availableModules[id] === true;
    }

    function openModule(id) {
        Quickshell.execDetached(["kcmshell6", id]);
    }

    // Format: «aktiv,vorgabe,Anzeigename»; mehrere Tasten mit Tabulator getrennt, Kommas maskiert.
    function parseShortcuts(text) {
        const out = {};
        for (const line of text.split("\n")) {
            const cut = line.indexOf("=");
            if (cut < 0)
                continue;
            const value = line.slice(cut + 1);
            if (value === "") {
                out[line.slice(0, cut)] = "";
                continue;
            }
            const active = value.replace(/\\,/g, "\u0001").split(",")[0].replace(/\u0001/g, ",");
            out[line.slice(0, cut)] = active === "none" || active === "" ? "none" : active.split(/\\t|\t/).join("  ·  ");
        }
        shortcutKeys = out;
        shortcutsLoaded = true;
    }

    function shortcutText(id) {
        if (!shortcutsLoaded)
            return "…";
        const keys = shortcutKeys[id];
        if (keys === undefined || keys === "")
            return "–";
        return keys === "none" ? "nicht belegt" : keys;
    }

    function reloadShortcuts() {
        shortcutReader.running = false;
        shortcutReader.running = true;
    }

    Process {
        id: shortcutReader
        running: true
        command: ["sh", "-c", 'for key in "$@"; do printf "%s=%s\\n" "$key" "$(kreadconfig6 --file kglobalshortcutsrc --group kwin --key "$key" 2>/dev/null)"; done', "sh"].concat(root.shortcutRows.map(row => row[0]))
        stdout: StdioCollector {
            onStreamFinished: root.parseShortcuts(text)
        }
    }

    Process {
        running: true
        command: ["kcmshell6", "--list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = {};
                let count = 0;
                for (const line of text.split("\n")) {
                    const match = line.match(/^\s*(kcm_?[A-Za-z0-9_]+)\b/);
                    if (!match)
                        continue;
                    found[match[1]] = true;
                    count++;
                }
                if (count > 0)
                    root.availableModules = found;
            }
        }
    }

    // Nach dem Neuladen registriert das Skript die Kürzel neu; kurz warten, dann nachlesen.
    Timer {
        id: shortcutReloadDelay
        interval: 1500
        onTriggered: root.reloadShortcuts()
    }

    component ExternalRow: SettingsRow {
        id: externalRow
        resetKeys: []
        clickable: true

        DIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: "open_in_new"
            size: Theme.iconSize
            color: externalRow.supportingContentColor
        }
    }

    SettingsPage {
        SettingsCard {
            width: parent.width
            iconName: "hub"
            title: "Brücke zu KWin"
            settingKey: "alpeKwinBridge"

            SettingsRow {
                title: KwinService.connected ? "Verbunden" : "Keine Verbindung"
                subtitle: KwinService.connected ? `${KwinService.toplevels.length} Fenster · ${KwinService.workspaces.length} Arbeitsflächen` + (KwinService.activeOutput ? ` · aktiv: ${KwinService.activeOutput}` : "") : "Das KWin-Skript meldet sich nicht. Ohne es fehlen Fensterliste, Dock und Arbeitsflächen."
                iconName: KwinService.connected ? "check_circle" : "error_outline"
                iconColor: KwinService.connected ? Theme.primary : Theme.error

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonHeight: Theme.buttonHeightS
                    text: "Neu laden"
                    iconName: "refresh"
                    backgroundColor: SettingsMetrics.controlSurface
                    textColor: Theme.surfaceText
                    onClicked: {
                        KwinService.reloadBridge();
                        shortcutReloadDelay.restart();
                    }
                }
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "drag_pan"
            title: "Fenster ziehen"
            settingKey: "alpeWindowGrip"

            SettingsToggleRow {
                settingKey: "windowGripEnabled"
                tags: ["fenster", "ziehen", "verschieben", "bewegen", "titelleiste", "griffleiste", "drag", "move"]
                text: "Fenster am oberen Rand ziehen"
                description: "Für Fenster ohne Titelleiste: Ein unsichtbarer Streifen auf dem oberen Rand verschiebt das Fenster, ein Doppelklick maximiert es. Er sitzt rittlings auf dem Rand, damit Menüleisten bedienbar bleiben."
                checked: SettingsData.windowGripEnabled
                onToggled: checked => SettingsData.set("windowGripEnabled", checked)
            }

            SettingsSliderRow {
                settingKey: "windowGripOutside"
                visible: SettingsData.windowGripEnabled
                text: "Streifen über dem Fenster"
                description: "Gilt nur, wo über dem Rand kein anderes Fenster liegt. Dort stört er nichts."
                unit: "px"
                minimum: 0
                maximum: 40
                value: SettingsData.windowGripOutside
                onSliderDragFinished: finalValue => SettingsData.set("windowGripOutside", finalValue)
            }

            SettingsSliderRow {
                settingKey: "windowGripHeight"
                visible: SettingsData.windowGripEnabled
                text: "Streifen im Fenster"
                description: "Klicks in diesem Teil erreichen das Programm nicht. Zusammen " + (SettingsData.windowGripHeight + SettingsData.windowGripOutside) + " px; 20 px sind auf einem 34-Zoll-Bildschirm mit 3440 × 1440 rund 5 mm."
                unit: "px"
                minimum: 2
                maximum: 40
                value: SettingsData.windowGripHeight
                onSliderDragFinished: finalValue => SettingsData.set("windowGripHeight", finalValue)
            }

            SettingsToggleRow {
                settingKey: "windowGripSkipDecorated"
                visible: SettingsData.windowGripEnabled
                text: "Programme mit eigener Titelleiste auslassen"
                description: "Erkannt am selbst gezeichneten Fensterschatten, wie ihn GTK-Programme und Browser haben. Ihre Kopfleiste zieht ohnehin."
                checked: SettingsData.windowGripSkipDecorated
                onToggled: checked => SettingsData.set("windowGripSkipDecorated", checked)
            }

            SettingsToggleRow {
                settingKey: "windowGripSnap"
                visible: SettingsData.windowGripEnabled
                text: "Am Bildschirmrand einrasten"
                description: "Links oder rechts: Hälfte, in den Ecken: Viertel, oben: maximiert. Eine Vorschau zeigt den Platz, bevor man loslässt; wieder weggezogen, bekommt das Fenster seine alte Grösse."
                checked: SettingsData.windowGripSnap
                onToggled: checked => SettingsData.set("windowGripSnap", checked)
            }

            SettingsToggleRow {
                settingKey: "windowGripCorners"
                visible: SettingsData.windowGripEnabled
                text: "Grösse an den unteren Ecken ziehen"
                description: "Fenster ohne Rahmen haben keinen Rand zum Ziehen. Unten links und rechts liegt dafür eine kleine Fläche; der Zeiger zeigt den Doppelpfeil."
                checked: SettingsData.windowGripCorners
                onToggled: checked => SettingsData.set("windowGripCorners", checked)
            }

            SettingsToggleRow {
                settingKey: "windowGripEdges"
                visible: SettingsData.windowGripEnabled && SettingsData.windowGripCorners
                text: "Auch an den Rändern ziehen"
                description: "Links, rechts und unten ein 8 px breiter, unsichtbarer Rand ausserhalb des Fensters, wie bei einer Fensterdekoration. Nur über freiem Hintergrund, nie über einem anderen Fenster."
                checked: SettingsData.windowGripEdges
                onToggled: checked => SettingsData.set("windowGripEdges", checked)
            }

            SettingsRow {
                visible: SettingsData.windowGripEnabled
                title: "Rechtsklick auf den Streifen"
                subtitle: "Fenstermenü: minimieren, maximieren, im Vordergrund halten, auf allen Arbeitsflächen, schliessen."
                iconName: "menu"
            }

            SettingsRow {
                visible: SettingsData.windowGripEnabled
                title: "Stand"
                subtitle: root.gripStatus()
                iconName: KwinService.grips.length > 0 ? "check_circle" : "info"
            }

            SettingsRow {
                visible: SettingsData.windowGripEnabled && root.gripApps.length > 0
                title: "Je Programm"
                subtitle: "Ausgeschaltet bekommt ein Programm keinen Streifen – sinnvoll, wenn es oben eine eigene Leiste hat, die schon zieht."
                iconName: "apps"
            }

            Repeater {
                model: SettingsData.windowGripEnabled ? root.gripApps : []

                SettingsToggleRow {
                    id: appRow
                    required property string modelData
                    text: modelData
                    description: root.gripExcluded(modelData) ? "Ausgenommen" : ""
                    iconName: "web_asset"
                    checked: !root.gripExcluded(modelData)
                    // Verzögert: Die Änderung lädt die Brücke neu und baut diese Liste um.
                    onToggled: checked => {
                        const app = appRow.modelData;
                        Qt.callLater(() => root.setGripExcluded(app, !checked));
                    }
                }
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "keyboard_command_key"
            title: "Tastenkürzel von Alpe"
            settingKey: "alpeKwinShortcuts"

            Repeater {
                model: root.shortcutRows

                SettingsRow {
                    id: shortcutRow
                    required property var modelData
                    title: modelData[1]
                    iconName: modelData[2]
                    trailingBadge: root.shortcutText(modelData[0])
                    trailingBadgeColor: root.shortcutKeys[modelData[0]] === "none" ? Theme.warning : shortcutRow.supportingContentColor
                }
            }

            ExternalRow {
                title: "Tasten ändern"
                subtitle: "KDE-Modul «Kurzbefehle», Gruppe «KWin», Einträge «Alpe: …». Eine schon vergebene Taste lässt KWin unbelegt."
                iconName: "edit"
                onClicked: root.openModule("kcm_keys")
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "settings_applications"
            title: "KDE-Module"
            settingKey: "alpeKdeModules"

            Repeater {
                model: root.modules

                ExternalRow {
                    required property var modelData
                    visible: root.hasModule(modelData[0])
                    title: modelData[1]
                    subtitle: modelData[2]
                    iconName: modelData[3]
                    onClicked: root.openModule(modelData[0])
                }
            }

            ExternalRow {
                title: "Alle Systemeinstellungen"
                subtitle: "Die vollständige Einstellungsanwendung von Plasma"
                iconName: "settings"
                onClicked: Quickshell.execDetached(["systemsettings"])
            }
        }
    }
}
