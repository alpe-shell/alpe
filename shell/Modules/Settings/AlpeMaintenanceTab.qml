pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets

// Alpe: Wartung der Shell selbst – Neustart, Protokoll, Zwischenspeicher, eigene Plugins und
// der Schutz des Backend-Pakets vor fremden Aktualisierungen.
Item {
    id: root

    property var parentModal: null

    property string cacheSize: ""
    property bool cacheBusy: false
    // "", "held", "open", "unknown"
    property string holdState: ""
    property string treeState: ""

    readonly property var ownPlugins: (PluginService.availablePluginsList || []).filter(plugin => String(plugin.id).startsWith("alpe"))

    function probe() {
        prober.running = false;
        prober.running = true;
    }

    function parse(text) {
        for (const line of text.split("\n")) {
            const cut = line.indexOf("=");
            if (cut < 0)
                continue;
            const value = line.slice(cut + 1).trim();
            switch (line.slice(0, cut)) {
            case "cache":
                cacheSize = value;
                break;
            case "hold":
                holdState = value;
                break;
            case "tree":
                treeState = value;
                break;
            }
        }
        cacheBusy = false;
    }

    function restartShell() {
        Quickshell.execDetached(["sh", "-c", 'if systemctl --user is-active --quiet dms.service; then exec systemctl --user restart dms.service; fi; exec "$1" restart', "sh", Proc.dmsBin]);
    }

    function openJournal() {
        Quickshell.execDetached(["sh", "-c", 'for term in "$1" "${TERMINAL:-}" kitty ghostty foot alacritty konsole; do [ -n "$term" ] && command -v "$term" >/dev/null 2>&1 && exec "$term" -e journalctl --user -u dms.service -b -e; done', "sh", SessionData.resolveTerminal()]);
    }

    function clearCache() {
        cacheBusy = true;
        cacheCleaner.running = true;
    }

    function lastRunText() {
        const run = SystemUpdateService.scriptRun;
        if (!run || !(run.started > 0))
            return "Noch nie über Alpe gestartet";
        const when = new Date((run.finished > 0 ? run.finished : run.started) * 1000).toLocaleString(I18n.locale(), Locale.ShortFormat);
        switch (run.state) {
        case "running":
            return "Läuft gerade";
        case "done":
            return when + " · ohne Fehler";
        case "failed":
            return when + " · mit Fehlern (Code " + run.code + ")";
        default:
            return when + " · abgebrochen";
        }
    }

    function treeText() {
        switch (treeState) {
        case "clean":
            return "Unverändert gegenüber dem letzten Commit";
        case "dirty":
            return "Enthält Änderungen ohne Commit";
        case "nogit":
            return "Kein Git-Arbeitsverzeichnis";
        default:
            return "";
        }
    }

    Process {
        id: prober
        running: true
        command: ["sh", "-c", 'dir="${XDG_CACHE_HOME:-$HOME/.cache}/alpe"; if [ -d "$dir" ]; then printf "cache=%s\\n" "$(du -sh "$dir" 2>/dev/null | cut -f1)"; else echo "cache=leer"; fi; case "${DMS_EXECUTABLE:-}" in */.local/lib/alpe/*) echo hold=own ;; *) if command -v pacman-conf >/dev/null 2>&1; then if pacman -Qq "$1" >/dev/null 2>&1; then if pacman-conf IgnorePkg 2>/dev/null | grep -qx "$1"; then echo hold=held; else echo hold=open; fi; else echo hold=unknown; fi; else echo hold=unknown; fi ;; esac; if git -C "$2" rev-parse --is-inside-work-tree >/dev/null 2>&1; then if [ -z "$(git -C "$2" status --porcelain 2>/dev/null)" ]; then echo tree=clean; else echo tree=dirty; fi; else echo tree=nogit; fi', "sh", Brand.heldPackages[0] ?? "", Quickshell.shellDir]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Process {
        id: cacheCleaner
        command: ["sh", "-c", 'dir="${XDG_CACHE_HOME:-$HOME/.cache}/alpe"; [ -d "$dir" ] && find "$dir" -mindepth 1 -delete; exit 0']
        onExited: {
            WeatherService.forceRefresh();
            root.probe();
        }
    }

    SettingsPage {
        SettingsCard {
            width: parent.width
            iconName: "terminal"
            title: "Shell"
            settingKey: "alpeMaintenanceShell"

            SettingsRow {
                title: `${Brand.name} ${Brand.version} «${Brand.codename}»`
                subtitle: root.treeText()
                iconName: "landscape"
                trailingBadge: "Basis " + Brand.upstreamVersion
            }

            SettingsRow {
                title: "Shell neu starten"
                subtitle: "Lädt Oberfläche und Plugins neu. Offene Programme bleiben unberührt."
                iconName: "restart_alt"

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonHeight: Theme.buttonHeightS
                    text: I18n.tr("Restart")
                    iconName: "restart_alt"
                    backgroundColor: SettingsMetrics.controlSurface
                    textColor: Theme.surfaceText
                    onClicked: root.restartShell()
                }
            }

            SettingsRow {
                title: "Protokoll"
                subtitle: "Meldungen der Shell seit dem Systemstart, im Terminal"
                iconName: "receipt_long"
                clickable: true
                resetKeys: []
                onClicked: root.openJournal()

                DIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "open_in_new"
                    size: Theme.iconSize
                    color: Theme.surfaceVariantText
                }
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "system_update_alt"
            title: "Aktualisierung"
            settingKey: "alpeMaintenanceUpdate"

            SettingsNavRow {
                title: I18n.tr("Software updates", "settings page, modal and bar widget title, DMS and system package updates")
                hint: (SystemUpdateService.scriptMode ? SystemUpdateService.scriptCommand + " · " : "") + root.lastRunText()
                iconName: "system_update_alt"
                onClicked: keyboard => root.parentModal?.navigateTo("updater", keyboard)
            }

            SettingsRow {
                visible: root.holdState !== "" && root.holdState !== "unknown" && Brand.heldPackages.length > 0
                title: root.holdState === "own" ? "Eigener Hintergrunddienst" : "Paket «" + (Brand.heldPackages[0] ?? "") + "»"
                subtitle: root.holdState === "own" ? "Aus demselben Quellcode gebaut wie diese Shell (tools/backend.sh); er passt immer, eine Ausnahme in pacman ist unnötig." : root.holdState === "held" ? "In pacman festgehalten. Das Backend passt damit sicher zu dieser Shell." : "Nicht festgehalten: Eine Paketaktualisierung könnte ein Backend bringen, das nicht mehr zu dieser Shell passt."
                iconName: root.holdState === "open" ? "gpp_maybe" : "verified_user"
                iconColor: root.holdState === "open" ? Theme.warning : Theme.primary
                trailingBadge: root.holdState === "own" ? "alpe" : root.holdState === "held" ? "IgnorePkg" : "offen"
                trailingBadgeColor: root.holdState === "open" ? Theme.warning : Theme.surfaceVariantText
            }

            SettingsNoteRow {
                visible: root.holdState === "open"
                noteIconName: "terminal"
                monospace: true
                text: "sudo sed -i -E 's/^#?[[:space:]]*IgnorePkg[[:space:]]*=[[:space:]]*(.*)$/IgnorePkg = \\1 " + (Brand.heldPackages[0] ?? "") + "/' /etc/pacman.conf"
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "cached"
            title: "Zwischenspeicher"
            settingKey: "alpeMaintenanceCache"

            SettingsRow {
                title: "Wetter und Radar"
                subtitle: "Stationsliste, amtliche Tagesprognose und Radarbilder. Wird nach dem Leeren neu geladen."
                iconName: "partly_cloudy_day"
                trailingBadge: root.cacheSize

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonHeight: Theme.buttonHeightS
                    text: "Leeren"
                    iconName: "delete_sweep"
                    busy: root.cacheBusy
                    enabled: !root.cacheBusy
                    backgroundColor: SettingsMetrics.controlSurface
                    textColor: Theme.surfaceText
                    onClicked: root.clearCache()
                }
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "extension"
            title: "Eigene Plugins"
            settingKey: "alpeMaintenancePlugins"
            visible: root.ownPlugins.length > 0

            Repeater {
                model: ScriptModel {
                    values: root.ownPlugins
                }

                SettingsNavRow {
                    id: pluginRow
                    required property var modelData
                    readonly property bool pluginLoaded: PluginService.loadedPlugins[modelData.id] !== undefined
                    title: modelData.name || modelData.id
                    hint: (pluginLoaded ? "Aktiv" : "Nicht geladen") + (modelData.version ? " · Version " + modelData.version : "")
                    iconName: modelData.icon || "extension"
                    iconColor: pluginLoaded ? Theme.primary : Theme.surfaceVariantText
                    onClicked: keyboard => root.parentModal?.navigateTo(SettingsTabs.pluginPrefix + modelData.id, keyboard)
                }
            }
        }
    }
}
