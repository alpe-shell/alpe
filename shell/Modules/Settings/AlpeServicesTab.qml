pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets

// Alpe: Dienste und Autostart. Die Shell selbst (alpe.service mit ihren Drop-ins), eigene
// systemd-Benutzerdienste (~/.config/systemd/user) mit Start, Stopp und Autostart, die übrigen
// Benutzerdienste zum Ansehen und Neustarten. Autostart-Programme hat die eigene Seite.
Item {
    id: root

    property var parentModal: null

    property var info: null
    property bool loading: false
    property bool showAll: false
    property string message: ""

    AlpeKwinBackend {
        id: backend
    }

    function refresh() {
        loading = true;
        backend.run(["services"], result => {
            loading = false;
            if (result)
                info = result;
        });
    }

    Component.onCompleted: refresh()

    readonly property var all: info ? info.services : []
    readonly property var shell: all.find(s => s.Id === Proc.shellUnit) || null
    // Maskierte Dienste (Verweis auf /dev/null) sind bewusst abgeschaltet: nur nennen, nicht schalten.
    readonly property var own: all.filter(s => s.own && s.Id !== Proc.shellUnit && s.UnitFileState !== "masked")
    readonly property var masked: all.filter(s => s.UnitFileState === "masked")
    readonly property var others: all.filter(s => !s.own && s.Id !== Proc.shellUnit && !launchedApp(s.Id) && s.UnitFileState !== "masked" && (s.ActiveState === "active" || s.ActiveState === "failed"))

    function act(action, unit) {
        message = "";
        backend.run(["service", action, unit], result => {
            if (result && !result.ok)
                message = unit + ": " + (result.error || "fehlgeschlagen");
            refresh();
        });
    }

    function stateText(s) {
        if (!s)
            return "";
        const map = { "active": "läuft", "inactive": "gestoppt", "failed": "fehlgeschlagen", "activating": "startet", "deactivating": "stoppt" };
        return (map[s.ActiveState] || s.ActiveState) + (s.ActiveState === "active" && s.ActiveEnterTimestamp ? " seit " + s.ActiveEnterTimestamp.replace(/^\w+ /, "") : "");
    }

    // Über scripts/alpe-update.sh open: sucht ein vorhandenes Terminal (kitty, ghostty, foot …).
    function journal(unit) {
        Quickshell.execDetached(["bash", Quickshell.shellDir + "/scripts/alpe-update.sh", "open", SessionData.resolveTerminal(), "Protokoll: " + unit, "journalctl", "--user", "-u", unit, "-n", "200", "-f"]);
    }

    // systemd schreibt Sonderzeichen als \x2d usw.; Autostart-Einträge heissen app-NAME@autostart.
    function pretty(id) {
        let name = String(id).replace(/\.service$/, "").replace(/\\x([0-9a-fA-F]{2})/g, (m, h) => String.fromCharCode(parseInt(h, 16)));
        const auto = name.match(/^app-(.+)@autostart$/);
        return auto ? "Autostart: " + auto[1] : name;
    }

    // Von systemd gestartete Programmfenster (app-kitty@<Kennung>) sind keine Dienste im eigentlichen Sinn.
    function launchedApp(id) {
        return /^app-.+@[0-9a-f]{16,}\.service$/.test(String(id));
    }

    SettingsPage {
        SettingsCard {
            width: parent.width
            iconName: "deployed_code"
            title: "Shell"
            settingKey: "alpeServiceShell"
            tags: ["dienste", "services", "systemd", "alpe.service", "neustart"]

            SettingsRow {
                title: "Alpe (alpe.service)"
                subtitle: root.shell ? root.stateText(root.shell) : (root.loading ? "lese …" : "nicht als Dienst eingerichtet")
                iconName: root.shell && root.shell.ActiveState === "active" ? "check_circle" : "error_outline"
                iconColor: root.shell && root.shell.ActiveState === "active" ? Theme.primary : Theme.error

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Protokoll"
                    iconName: "receipt_long"
                    variant: "text"
                    onClicked: root.journal(Proc.shellUnit)
                }
            }

            SettingsRow {
                visible: !!(root.shell && root.shell.dropins.length > 0)
                title: "Ergänzungen (Drop-ins)"
                subtitle: root.shell ? root.shell.dropins.map(p => p.split("/").pop()).join(" · ") : ""
                iconName: "tune"
            }

            SettingsRow {
                title: "Shell neu starten"
                subtitle: "Startet Leiste, Dock und diese Einstellungen neu; offene Fenster bleiben."
                iconName: "restart_alt"

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Neu starten"
                    variant: "tonal"
                    onClicked: Quickshell.execDetached(Proc.shellRestartCommand)
                }
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "settings_applications"
            title: "Eigene Dienste"
            settingKey: "alpeServiceOwn"

            SettingsNoteRow {
                visible: root.info !== null && root.own.length === 0
                text: "Keine eigenen Dienste in ~/.config/systemd/user."
            }

            SettingsRow {
                visible: root.masked.length > 0
                title: "Bewusst abgeschaltet (maskiert)"
                subtitle: root.masked.map(s => root.pretty(s.Id)).join(" · ") + " – zurück mit «systemctl --user unmask NAME»"
                iconName: "block"
            }

            SettingsNoteRow {
                visible: root.message !== ""
                text: root.message
            }

            Repeater {
                model: root.own

                SettingsToggleRow {
                    id: svc
                    required property var modelData
                    width: parent ? parent.width : 0
                    text: root.pretty(modelData.Id)
                    description: (modelData.Description && modelData.Description !== modelData.Id ? modelData.Description + " · " : "") + root.stateText(modelData) + " · Autostart " + (modelData.UnitFileState === "enabled" ? "an" : "aus")
                    checked: modelData.UnitFileState === "enabled"
                    onToggled: checked => root.act(checked ? "enable" : "disable", modelData.Id)

                    accessory: Row {
                        spacing: Theme.spacingXS
                        DButton {
                            text: svc.modelData.ActiveState === "active" ? "Stoppen" : "Starten"
                            variant: "text"
                            onClicked: root.act(svc.modelData.ActiveState === "active" ? "stop" : "start", svc.modelData.Id)
                        }
                        DButton {
                            text: "Neu starten"
                            variant: "text"
                            visible: svc.modelData.ActiveState === "active"
                            onClicked: root.act("restart", svc.modelData.Id)
                        }
                        DButton {
                            text: "Protokoll"
                            variant: "text"
                            onClicked: root.journal(svc.modelData.Id)
                        }
                    }
                }
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "list"
            title: "Weitere Benutzerdienste"
            settingKey: "alpeServiceOthers"

            SettingsToggleRow {
                text: "Laufende Dienste des Systems zeigen"
                description: root.others.length + " Dienste aus Paketen (PipeWire, Schlüsselbund …). Nur ansehen und neu starten; an- und abschalten lieber nicht."
                checked: root.showAll
                onToggled: checked => root.showAll = checked
            }

            Repeater {
                model: root.showAll ? root.others : []

                SettingsRow {
                    id: other
                    required property var modelData
                    width: parent ? parent.width : 0
                    title: root.pretty(modelData.Id)
                    subtitle: (modelData.Description || "") + " · " + root.stateText(modelData)
                    iconName: modelData.ActiveState === "failed" ? "error_outline" : "radio_button_checked"
                    iconColor: modelData.ActiveState === "failed" ? Theme.error : Theme.primary

                    Row {
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        spacing: Theme.spacingXS
                        DButton {
                            text: "Neu starten"
                            variant: "text"
                            onClicked: root.act("restart", other.modelData.Id)
                        }
                        DButton {
                            text: "Protokoll"
                            variant: "text"
                            onClicked: root.journal(other.modelData.Id)
                        }
                    }
                }
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "line_start"
            title: "Autostart"
            settingKey: "alpeServiceAutostart"

            SettingsNavRow {
                title: I18n.tr("Autostart apps")
                hint: "Programme und Befehle, die mit der Sitzung starten (~/.config/autostart)"
                iconName: "line_start"
                onClicked: keyboard => root.parentModal?.navigateTo("autostart", keyboard)
            }
        }
    }
}
