pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets

// Alpe: Leistung. Was Oberfläche und Dienst gerade an Speicher und Rechenzeit brauchen
// (scripts/alpe-perf.py, nur solange die Seite offen ist), und Schalter für Teile, die nicht
// jeder braucht: im Dienst (~/.config/alpe/aus, wirkt nach einem Neustart der Shell, nur mit
// dem eigenen Dienst) und in der Oberfläche (Einstellungen der Shell, wirken sofort).
Item {
    id: root

    property var parentModal: null

    property var info: null
    property bool restartNeeded: false
    readonly property string script: Quickshell.shellDir + "/scripts/alpe-perf.py"

    function refresh() {
        Proc.runCommand("alpe-perf", ["python3", "-I", script], (output, code) => {
            try {
                root.info = JSON.parse(output);
            } catch (e) {}
        }, 0, 10000);
    }

    Timer {
        interval: 3000
        repeat: true
        triggeredOnStart: true
        running: root.visible
        onTriggered: root.refresh()
    }

    function mb(kb) {
        return (kb / 1024).toFixed(kb < 102400 ? 1 : 0) + " MB";
    }

    function setPart(name, off) {
        Proc.runCommand("alpe-perf-off-" + name, ["python3", "-I", script, "off", name, off ? "on" : "off"], () => {
            root.restartNeeded = true;
            root.refresh();
        }, 0, 10000);
    }

    // Teile des Dienstes: [Name, Titel, Beschreibung]
    readonly property var parts: [
        ["bluetooth", "Bluetooth", "Geräte, Akkustände und Kopplung über BlueZ. Aus, wenn der Rechner kein Bluetooth nutzt."],
        ["wellbeing", "Digitales Wohlbefinden", "Erfasst Bildschirmzeit je Programm für die Statistik und App-Limits."],
        ["clipboard", "Verlauf der Zwischenablage", "Merkt sich Kopiertes; ohne ihn bleibt nur das Einfügen des Letzten."],
        ["location", "Standort", "Für Nachtlicht und Dunkelmodus nach Sonnenstand. Das Wetter von MeteoSchweiz braucht ihn nicht."],
        ["trayrecovery", "Tray-Wiederherstellung", "Holt Symbole im Systembereich nach einem Absturz von Programmen zurück."],
        ["evdev", "Tastatur-Ereignisse", "Für die Anzeigen von Feststell- und Num-Taste."],
        ["notifyactions", "Aktionen in Mitteilungen", "Knöpfe in Mitteilungen anderer Programme."]
    ]

    // Teile der Oberfläche: [Einstellung, Titel, Beschreibung, an ist teuer?]
    readonly property var uiParts: [
        ["audioVisualizerEnabled", "Audio-Visualisierung", "Startet cava, solange Musik läuft; kostet dauernd etwas CPU."],
        ["launcherHistoryEnabled", "Verlauf im Starter", "Merkt sich gestartete Programme für die Reihenfolge."],
        ["notificationHistoryEnabled", "Verlauf der Mitteilungen", "Hält alte Mitteilungen im Speicher."],
        ["soundsEnabled", "Systemklänge", "Klänge bei Mitteilungen, Lautstärke usw."]
    ]

    SettingsPage {
        SettingsCard {
            width: parent.width
            iconName: "speed"
            title: "Verbrauch"
            settingKey: "alpePerformance"
            tags: ["leistung", "ram", "speicher", "cpu", "performance"]

            SettingsNoteRow {
                visible: root.info === null
                text: "Messe …"
            }

            Repeater {
                model: root.info ? root.info.processes : []

                SettingsRow {
                    required property var modelData
                    width: parent ? parent.width : 0
                    title: modelData.name
                    // Alpe: RSS zählt geteilte Bibliotheken und Grafiktreiber voll (so steht es im
                    // Systemmonitor); PSS teilt sie auf, «privat» gehört nur diesem Prozess.
                    subtitle: "PID " + modelData.pid + " · " + modelData.threads + " Threads" + (modelData.rss ? " · RSS " + root.mb(modelData.rss) + ", privat " + root.mb(modelData.private) : "")
                    iconName: modelData.name.startsWith("Oberfläche") ? "web_asset" : "deployed_code"
                    trailingBadge: root.mb(modelData.pss) + " · " + modelData.cpu.toFixed(1) + " % CPU"
                }
            }

            SettingsNoteRow {
                visible: root.info !== null && root.info.arenaLimited === false
                noteIconName: "info"
                text: "Speicher-Arenen nicht begrenzt: bash ~/alpe/install.sh setzt MALLOC_ARENA_MAX=2 für den Dienst (danach Shell neu starten). Das hält RSS bei vielen Zeichen-Threads tiefer."
            }

            SettingsRow {
                visible: root.info !== null
                title: "Zusammen"
                subtitle: root.info ? "von " + root.mb(root.info.memTotal) + " Arbeitsspeicher, frei " + root.mb(root.info.memAvailable) + ". Gemessen als PSS: geteilte Bibliotheken zählen anteilig." : ""
                iconName: "memory"
                trailingBadge: root.info ? root.mb(root.info.totalPss) : ""
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "deployed_code"
            title: "Teile des Dienstes"
            settingKey: "alpePerformanceBackend"

            SettingsNoteRow {
                visible: root.info !== null && !root.info.ownBackend
                text: "Läuft mit dem Dienst aus dem Paket: Diese Schalter wirken erst mit dem eigenen Dienst (bash ~/alpe/tools/backend.sh build, dann use alpe)."
            }

            Repeater {
                model: root.parts

                SettingsToggleRow {
                    required property var modelData
                    width: parent ? parent.width : 0
                    text: modelData[1]
                    description: modelData[2]
                    checked: !(root.info && root.info.off.indexOf(modelData[0]) >= 0)
                    onToggled: checked => root.setPart(modelData[0], !checked)
                }
            }

            SettingsRow {
                visible: root.restartNeeded
                title: "Wirkt nach einem Neustart der Shell"
                subtitle: "Offene Fenster bleiben."
                iconName: "restart_alt"

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Neu starten"
                    variant: "tonal"
                    onClicked: Quickshell.execDetached(["sh", "-c", "systemctl --user restart dms.service 2>/dev/null || dms restart"])
                }
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "web_asset"
            title: "Teile der Oberfläche"
            settingKey: "alpePerformanceUi"

            Repeater {
                model: root.uiParts

                SettingsToggleRow {
                    required property var modelData
                    width: parent ? parent.width : 0
                    text: modelData[1]
                    description: modelData[2]
                    checked: !!SettingsData[modelData[0]]
                    onToggled: checked => SettingsData.set(modelData[0], checked)
                }
            }
        }
    }
}
