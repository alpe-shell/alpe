import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets
import qs.Widgets

Item {
    id: root

    property var parentModal: null

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    readonly property string githubUrl: "https://github.com/duxlabs-dev/dux-shell"

    function host(url) {
        return url.replace(/^https?:\/\//, "").replace(/\/$/, "");
    }

    // Alpe: was ansteht und womit aktualisiert wird.
    function updateHint() {
        const via = SystemUpdateService.scriptMode ? " · " + SystemUpdateService.scriptCommand.split(/\s+/)[0] : "";
        if (SystemUpdateService.scriptRunning)
            return "Läuft im Terminal";
        if (!SystemUpdateService.sysupdateAvailable)
            return via.slice(3);
        const count = SystemUpdateService.updateCount;
        if (count === 0)
            return I18n.tr("Up to date") + via;
        return (count === 1 ? I18n.tr("%1 update", "singular, %1 is 1, available system update count").arg(count) : I18n.tr("%1 updates", "plural, %1 is a count of available system updates").arg(count)) + via;
    }

    component LogoImage: Image {
        width: Theme.iconSize
        height: Theme.iconSize
        sourceSize: Qt.size(Theme.iconSize, Theme.iconSize)
        smooth: true
        fillMode: Image.PreserveAspectFit
    }

    SettingsPage {
        ReleaseHero {}

        SettingsCard {
            SettingsRow {
                body: StyledText {
                    text: I18n.tr('DMS is a modern, highly customizable desktop shell that looks great out of the box, without sacrificing the freedom to make it your own.<br/><br/>Built with %1 and %2, it brings together panels, widgets, system controls, and more into a cohesive desktop experience.', 'about page blurb, %1 is a Quickshell link, %2 is a Go link').arg(`<a href="https://quickshell.org" style="text-decoration:none; color:${Theme.primary};">Quickshell</a>`).arg(`<a href="https://go.dev" style="text-decoration:none; color:${Theme.primary};">Go</a>`)
                    textFormat: Text.RichText
                    font.pixelSize: Theme.fontSizeMedium
                    linkColor: Theme.primary
                    onLinkActivated: url => Qt.openUrlExternally(url)
                    color: Theme.surfaceVariantText
                    width: parent.width
                    wrapMode: Text.WordWrap

                    HoverHandler {
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                }
            }

            SettingsRow {
                iconName: "fork_right"
                title: "Herkunft"
                subtitle: `${Brand.name} ${Brand.version} «${Brand.codename}» baut auf ${Brand.upstreamName} ${Brand.upstreamVersion} auf (MIT-Lizenz).`
            }

            SettingsLinkRow {
                title: "Alpe auf GitHub"
                subtitle: root.host(Brand.url) + " – Anleitung, Neuigkeiten, Fehler melden"
                url: Brand.url
            }
        }

        SettingsCard {
            visible: DMSService.isConnected
            iconName: "dns"
            title: I18n.tr("Backend", "noun, settings label for the backend service in use")

            SettingsRow {
                title: I18n.tr("Version")
                trailingBadge: DMSService.cliVersion || "—"
            }

            SettingsRow {
                title: I18n.tr("API", "about page card title, application programming interface version")
                trailingBadge: `v${DMSService.apiVersion}`
            }

            SettingsRow {
                title: I18n.tr("Status")
                trailingBadge: I18n.tr("Connected")

                DBadge {
                    color: Theme.success
                }
            }

            SettingsRow {
                visible: DMSService.capabilities.length > 0
                title: I18n.tr("Capabilities")
                body: Flow {
                    width: parent.width
                    spacing: Theme.spacingS

                    Repeater {
                        model: DMSService.capabilities

                        DBadge {
                            required property string modelData
                            text: modelData
                            color: Theme.primaryHover
                            textColor: Theme.primary
                        }
                    }
                }
            }
        }

        SettingsCard {
            iconName: "build"
            title: I18n.tr("Tools", "about page card title for welcome and system check")

            SettingsNavRow {
                iconName: "system_update_alt"
                title: I18n.tr("Software updates", "settings page, modal and bar widget title, DMS and system package updates")
                hint: root.updateHint()
                onClicked: keyboard => root.parentModal?.navigateTo("updater", keyboard)
            }

            SettingsNavRow {
                iconName: "build"
                title: "Wartung"
                hint: "Neustart, Protokoll, Zwischenspeicher, Plugins"
                onClicked: keyboard => root.parentModal?.navigateTo("alpe_maintenance", keyboard)
            }

            SettingsNavRow {
                visible: CompositorService.isKwin
                iconName: "desktop_windows"
                title: "KWin & Plasma"
                hint: "Tastenkürzel, Brücke, KDE-Module"
                onClicked: keyboard => root.parentModal?.navigateTo("alpe_desktop", keyboard)
            }

            SettingsNavRow {
                iconName: "visibility_off"
                title: "Seitenauswahl"
                hint: "Einstellungsseiten ein- und ausblenden"
                onClicked: keyboard => root.parentModal?.navigateTo("alpe_pages", keyboard)
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: `<a href="${root.githubUrl}/blob/master/LICENSE" style="text-decoration:none; color:${Theme.surfaceVariantText};">${I18n.tr('MIT License')}</a>`
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceVariantText
            textFormat: Text.RichText
            wrapMode: Text.NoWrap
            onLinkActivated: url => Qt.openUrlExternally(url)

            HoverHandler {
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }
}
