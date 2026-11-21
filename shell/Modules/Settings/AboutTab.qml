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

    readonly property string assetsDir: "file://" + Theme.shellDir + "/assets/"
    readonly property string githubUrl: "https://github.com/duxlabs-dev/dux-shell"
    readonly property string kofiUrl: "https://ko-fi.com/duxlabs"
    readonly property string discordUrl: "https://discord.gg/ppWTpKmPgT"

    readonly property var compositor: {
        switch (true) {
        case CompositorService.isHyprland:
            return {
                logo: "hyprland.svg",
                url: "https://hypr.land",
                label: I18n.tr("Hyprland website"),
                discordUrl: "https://discord.com/invite/hQ9XvMUjjr",
                discordLabel: I18n.tr("Hyprland Discord server")
            };
        case CompositorService.isSway:
            return {
                logo: "sway.svg",
                url: "https://swaywm.org",
                label: I18n.tr("Sway website")
            };
        case CompositorService.isScroll:
            return {
                logo: "sway.svg",
                url: "https://github.com/dawsers/scroll",
                label: I18n.tr("Scroll GitHub")
            };
        case CompositorService.isMiracle:
            return {
                logo: "miraclewm.svg",
                url: "https://github.com/miracle-wm-org/miracle-wm",
                label: "miracle-wm"
            };
        case CompositorService.isMango:
            return {
                logo: "mango.png",
                url: "https://github.com/mangowm/mango",
                label: I18n.tr("mangowc GitHub"),
                discordUrl: "https://discord.gg/CPjbDxesh5",
                discordLabel: I18n.tr("mangowc Discord server")
            };
        case CompositorService.isLabwc:
            return {
                logo: "labwc.png",
                url: "https://labwc.github.io/",
                label: I18n.tr("LabWC website"),
                ircUrl: "https://web.libera.chat/gamja/?channels=#labwc"
            };
        case CompositorService.isUmbriel:
            return {
                logo: "umbriel.svg",
                url: "https://github.com/noctalia-dev/umbriel",
                label: "Umbriel"
            };
        default:
            return {
                logo: "",
                url: "",
                label: ""
            };
        }
    }

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
                subtitle: `${Brand.name} ${Brand.version} «${Brand.codename}» baut auf ${Brand.upstreamName} ${ShellVersionService.semverVersion} auf (MIT-Lizenz).`
            }

            SettingsLinkRow {
                title: "Alpe auf GitHub"
                subtitle: root.host(Brand.url) + " – Anleitung, Neuigkeiten, Fehler melden"
                url: Brand.url
            }
        }

        SettingsCard {
            // Die Kanäle gehören zum Ursprungsprojekt; Fragen zu Alpe sind dort fehl am Platz.
            visible: false
            title: I18n.tr("Community", "about page card title, chat and community links")

            SettingsLinkRow {
                visible: root.compositor.url !== ""
                title: root.compositor.label
                subtitle: root.host(root.compositor.url)
                url: root.compositor.url
                leading: LogoImage {
                    source: root.compositor.logo ? root.assetsDir + root.compositor.logo : ""
                }
            }

            SettingsLinkRow {
                title: "niri/dux Discord"
                subtitle: root.host(root.discordUrl)
                url: root.discordUrl
                leading: LogoImage {
                    source: root.assetsDir + "discord.svg"
                }
            }

            SettingsLinkRow {
                visible: (root.compositor.discordUrl ?? "") !== ""
                title: root.compositor.discordLabel ?? ""
                subtitle: root.host(root.compositor.discordUrl ?? "")
                url: root.compositor.discordUrl ?? ""
                leading: LogoImage {
                    source: root.assetsDir + "discord.svg"
                }
            }

            SettingsLinkRow {
                visible: (root.compositor.ircUrl ?? "") !== ""
                iconName: "forum"
                title: I18n.tr("LabWC IRC channel")
                subtitle: "libera.chat"
                url: root.compositor.ircUrl ?? ""
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
