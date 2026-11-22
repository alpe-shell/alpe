pragma Singleton

import QtQuick
import Quickshell
import qs.Common
import qs.Services

Singleton {
    id: root

    readonly property string pluginPrefix: "plugin:"

    readonly property var structure: [
        {
            "id": "personalization",
            "text": I18n.tr("Wallpaper & colors"),
            "icon": "wallpaper",
            "hint": I18n.tr("Theme, palette, dark mode", "settings sidebar hint for the wallpaper and colors page"),
            "tabIndex": 0,
            "hubHeader": "WallpaperColorsTab",
            "aliases": ["wallpaper", "colors", "wallpaper_colors", "theme_cursor_icons"],
            "children": [
                {
                    "id": "theme",
                    "hidden": true,
                    "text": I18n.tr("Theme & colors"),
                    "icon": "format_paint",
                    "tabIndex": 10,
                    "hint": I18n.tr("Theme, light and dark, matugen")
                },
                {
                    "id": "theme_schedule",
                    "hidden": true,
                    "text": I18n.tr("Dark mode"),
                    "icon": "dark_mode",
                    "tabIndex": 51,
                    "hint": I18n.tr("Schedule, sunset, wallpaper brightness")
                },
                {
                    "id": "wallpaper_cycling",
                    "hidden": true,
                    "text": I18n.tr("Automatic cycling"),
                    "icon": "autorenew",
                    "tabIndex": 52,
                    "hint": I18n.tr("Folder, interval, daily time")
                },
                {
                    "id": "theme_apps",
                    "advanced": true,
                    "text": I18n.tr("App theming"),
                    "icon": "apps",
                    "tabIndex": 50,
                    "hint": I18n.tr("GTK, Qt, portal, matugen templates")
                },
                {
                    "id": "palette_inject",
                    "advanced": true,
                    "text": I18n.tr("Injected palettes", "settings page title, external palette commands merged into matugen"),
                    "icon": "colorize",
                    "tabIndex": 64,
                    "hint": I18n.tr("External palette commands, namespaces", "settings sidebar hint for the injected palettes page")
                }
            ]
        },
        {
            "id": "theme_surfaces",
            "aliases": ["interface", "interface_style"],
            "text": I18n.tr("Interface style"),
            "icon": "layers",
            "tabIndex": 48,
            "hubHeader": "ThemeSurfacesTab",
            "hint": I18n.tr("Blur, shadows, corners", "settings sidebar hint for the interface style page"),
            "children": [
                {
                    "id": "surface_shadows",
                    "hidden": true,
                    "text": I18n.tr("Shadows"),
                    "icon": "tonality",
                    "tabIndex": 53,
                    "hint": I18n.tr("Intensity, color, light direction")
                }
            ]
        },
        {
            "id": "typography",
            "aliases": ["fonts", "fonts_motion"],
            "text": I18n.tr("Fonts & motion"),
            "icon": "text_fields",
            "tabIndex": 14,
            "hint": I18n.tr("Fonts, scale, animations", "settings sidebar hint for the fonts and motion page")
        },
        {
            "id": "separator_1",
            "separator": true
        },
        {
            "id": "dankbar",
            "aliases": ["bar"],
            "text": I18n.tr("Bar"),
            "icon": "toolbar",
            "hint": I18n.tr("Layout, position, appearance", "settings hub hint for the bar pages"),
            "hubHeader": "BarHubHeader",
            "children": [
                {
                    "id": "dankbar_settings",
                    "hidden": true,
                    "aliases": ["dank_island", "island"],
                    "text": I18n.tr("General", "adjective, settings page and section title for general options"),
                    "icon": "tune",
                    "tabIndex": 3,
                    "hint": I18n.tr("Position, displays, auto-hide, behavior")
                },
                {
                    "id": "dankbar_appearance",
                    "hidden": true,
                    "aliases": ["frame"],
                    "text": I18n.tr("Appearance", "settings page and section title for visual options"),
                    "icon": "palette",
                    "tabIndex": 6,
                    "hint": I18n.tr("Background, corners, spacing, widget style")
                },
                {
                    "id": "dankbar_dot",
                    "hidden": true,
                    "aliases": ["dot", "dankdot"],
                    "text": I18n.tr("Dot", "bar layout: free-floating dot that opens island activities"),
                    "icon": "blur_on",
                    "tabIndex": 65,
                    "hint": I18n.tr("A floating companion that works alongside any bar layout", "bar settings: what the dot is")
                }
            ]
        },
        {
            "id": "dankbar_widgets",
            "text": I18n.tr("Bar widgets"),
            "icon": "widgets",
            "tabIndex": 22,
            "hubHeader": "WidgetsTab",
            "aliases": ["bar_widgets", "workspaces", "workspaces_widgets"],
            "hint": I18n.tr("Add, reorder, configure", "settings sidebar hint for the bar widgets page"),
            "children": [
                {
                    "id": "bar_widget",
                    "hidden": true,
                    "titleFrom": "selectedWidgetTitle",
                    "text": I18n.tr("Widget settings"),
                    "icon": "tune",
                    "tabIndex": 54,
                    "hint": I18n.tr("Options of one widget instance")
                }
            ]
        },
        {
            "id": "dock",
            "text": I18n.tr("Dock"),
            "aliases": ["desktop", "dock_launcher"],
            "icon": "dock_to_bottom",
            "hubHeader": "DockHubHeader",
            "hint": I18n.tr("Position, pinned apps, trash", "settings sidebar hint for the dock page"),
            "children": [
                {
                    "id": "dock_general",
                    "hidden": true,
                    "text": I18n.tr("General"),
                    "icon": "tune",
                    "tabIndex": 5,
                    "hint": I18n.tr("Displays, taskbar, auto-hide")
                },
                {
                    "id": "dock_widgets",
                    "hidden": true,
                    "text": I18n.tr("Apps & widgets"),
                    "icon": "widgets",
                    "tabIndex": 57,
                    "hint": I18n.tr("Add, remove and configure dock items")
                },
                {
                    "id": "dock_appearance",
                    "hidden": true,
                    "text": I18n.tr("Appearance"),
                    "icon": "palette",
                    "tabIndex": 58,
                    "hint": I18n.tr("Size, padding, opacity, borders")
                },
                {
                    "id": "dock_advanced",
                    "advanced": true,
                    "text": I18n.tr("Advanced"),
                    "icon": "settings",
                    "tabIndex": 59,
                    "hint": I18n.tr("Layers, fullscreen, exclusive zone")
                }
            ]
        },
        {
            "id": "launcher",
            "text": I18n.tr("Launcher"),
            "icon": "grid_view",
            "tabIndex": 9,
            "hint": I18n.tr("Style, search, hidden apps", "settings sidebar hint for the launcher page")
        },
        {
            "id": "dank_dash",
            "text": I18n.tr("Dashboard", "settings page name for the dank dash popout"),
            "icon": "space_dashboard",
            "tabIndex": 43,
            "aliases": ["dashboard", "dashboards_osd"],
            "hint": I18n.tr("Tabs and weather")
        },
        {
            "id": "desktop_widgets",
            "text": I18n.tr("Desktop widgets"),
            "icon": "widgets",
            "tabIndex": 27,
            "hubHeader": "DesktopWidgetsTab",
            "hint": I18n.tr("Clocks, monitors, plugins", "settings sidebar hint for the desktop widgets page"),
            "children": [
                {
                    "id": "desktop_widget",
                    "hidden": true,
                    "titleFrom": "selectedWidgetTitle",
                    "text": I18n.tr("Widget settings"),
                    "icon": "tune",
                    "tabIndex": 63,
                    "hint": I18n.tr("Options of one widget instance")
                }
            ]
        },
        {
            "id": "separator_2",
            "separator": true
        },
        {
            "id": "notifications",
            "text": I18n.tr("Notifications"),
            "icon": "notifications",
            "tabIndex": 17,
            "hubHeader": "NotificationsTab",
            "hint": I18n.tr("Popups, do not disturb, rules"),
            "children": [
                {
                    "id": "notification_rules",
                    "hidden": true,
                    "text": I18n.tr("Rules"),
                    "icon": "rule_settings",
                    "tabIndex": 55,
                    "hint": I18n.tr("Mute, ignore and priority rules per app")
                }
            ]
        },
        {
            "id": "osd",
            "text": I18n.tr("On-screen displays"),
            "icon": "picture_in_picture",
            "tabIndex": 18,
            "hint": I18n.tr("Volume, brightness, caps lock", "settings sidebar hint for the on-screen displays page")
        },
        {
            "id": "wellbeing",
            "text": I18n.tr("Digital wellbeing", "settings page and dashboard tab title, screen time tracking"),
            "icon": "digital_wellbeing",
            "tabIndex": 67,
            "aliases": ["screen_time"],
            "hint": I18n.tr("Screen time and app limits", "settings sidebar hint and dashboard tab description for digital wellbeing")
        },
        {
            "id": "sound_media",
            "aliases": ["sound", "media"],
            "text": I18n.tr("Sound & media"),
            "icon": "volume_up",
            "children": [
                {
                    "id": "audio",
                    "text": I18n.tr("Audio", "settings page name"),
                    "icon": "headphones",
                    "tabIndex": 29,
                    "hint": I18n.tr("Output and input devices")
                },
                {
                    "id": "sounds",
                    "text": I18n.tr("Sounds", "noun, settings page name for system sounds"),
                    "icon": "volume_up",
                    "tabIndex": 15,
                    "soundsOnly": true,
                    "hint": I18n.tr("System sound theme and events")
                },
                {
                    "id": "media_player",
                    "text": I18n.tr("Media player"),
                    "icon": "music_note",
                    "tabIndex": 16,
                    "hint": I18n.tr("Visualizer, album art, excluded players")
                }
            ]
        },
        {
            "id": "separator_3",
            "separator": true
        },
        {
            "id": "displays",
            "text": I18n.tr("Displays"),
            "icon": "monitor",
            "hint": I18n.tr("Layout, scale, night mode", "settings sidebar hint for the displays page"),
            "children": [
                {
                    "id": "display_config",
                    "text": I18n.tr("Configuration", "settings page name under displays"),
                    "icon": "display_settings",
                    "tabIndex": 24,
                    "hint": I18n.tr("Arrangement, resolution, scale, profiles")
                },
                {
                    "id": "display_gamma",
                    "text": I18n.tr("Gamma control"),
                    "icon": "brightness_6",
                    "tabIndex": 25,
                    "hint": I18n.tr("Night mode, gamma, contrast")
                },
                {
                    "id": "display_widgets",
                    "text": I18n.tr("Display assignment"),
                    "icon": "widgets",
                    "tabIndex": 26,
                    "hint": I18n.tr("Which displays show the dock, popups, OSDs and wallpaper")
                }
            ]
        },
        {
            "id": "input",
            "text": I18n.tr("Input", "noun, settings page name for input devices"),
            "icon": "keyboard",
            "hint": I18n.tr("Shortcuts, keyboard, mouse", "settings sidebar hint for the input page"),
            "children": [
                {
                    "id": "keybinds",
                    "text": I18n.tr("Keyboard shortcuts"),
                    "icon": "keyboard_command_key",
                    "tabIndex": 2,
                    "shortcutsOnly": true,
                    "hint": I18n.tr("Compositor and shell key bindings")
                },
                {
                    "id": "keyboard",
                    "text": I18n.tr("Keyboard", "settings page name"),
                    "icon": "keyboard",
                    "tabIndex": 45,
                    "inputCapable": true,
                    "hint": I18n.tr("Layouts, repeat rate, num lock")
                },
                {
                    "id": "mouse_touchpad",
                    "text": I18n.tr("Mouse & touchpad"),
                    "icon": "mouse",
                    "tabIndex": 44,
                    "pointerCapable": true,
                    "hint": I18n.tr("Speed, scrolling, tap to click")
                }
            ]
        },
        {
            "id": "power_battery",
            "text": BatteryService.batteryAvailable ? I18n.tr("Power & battery") : I18n.tr("Power"),
            "icon": "power_settings_new",
            "aliases": ["power", "power_security"],
            "children": [
                {
                    "id": "power_sleep",
                    "text": I18n.tr("Power & sleep"),
                    "icon": "power_settings_new",
                    "tabIndex": 21,
                    "hint": I18n.tr("Idle timeouts, power menu, custom actions")
                },
                {
                    "id": "battery",
                    "text": I18n.tr("Battery"),
                    "icon": "battery_charging_full",
                    "tabIndex": 42,
                    "batteryOnly": true,
                    "hint": I18n.tr("Charge limit, alerts, power profiles")
                },
                {
                    "id": "alpe_peripherals",
                    "aliases": ["peripherals", "headset"],
                    "text": "Geräte-Akkus",
                    "icon": "headset_mic",
                    "tabIndex": 102,
                    "hint": "Maus, Headset, Warnung bei tiefem Stand"
                }
            ]
        },
        {
            "id": "network",
            "text": I18n.tr("Network", "noun, settings page and widget title"),
            "icon": root.wifiShown ? "wifi" : "lan",
            "hint": root.wifiShown ? I18n.tr("Wi-Fi, Ethernet, VPN", "settings sidebar hint for the network page") : "Ethernet, VPN",
            "dmsOnly": true,
            "children": [
                {
                    "id": "network_wifi",
                    "text": I18n.tr("Wi-Fi", "wireless network, page and section title"),
                    "icon": "wifi",
                    "tabIndex": 40,
                    "wifiOnly": true,
                    "hint": I18n.tr("Networks, saved networks, hotspot")
                },
                {
                    "id": "network_ethernet",
                    "text": I18n.tr("Ethernet"),
                    "icon": "settings_ethernet",
                    "tabIndex": 39,
                    "hint": I18n.tr("Adapters and saved configurations")
                },
                {
                    "id": "network_vpn",
                    "text": I18n.tr("VPN", "virtual private network, widget and page title"),
                    "icon": "vpn_key",
                    "tabIndex": 41,
                    "hint": I18n.tr("Connections and autoconnect")
                },
                {
                    "id": "network_cellular",
                    "text": I18n.tr("Cellular"),
                    "icon": "network_cell",
                    "tabIndex": 47,
                    "cellularOnly": true,
                    "hint": I18n.tr("Modem and mobile data")
                },
                {
                    "id": "network_status",
                    "advanced": true,
                    "text": I18n.tr("Status"),
                    "icon": "lan",
                    "tabIndex": 7,
                    "hint": I18n.tr("Backend and connection preference")
                }
            ]
        },
        {
            "id": "separator_4",
            "separator": true
        },
        {
            "id": "user_accounts",
            "text": I18n.tr("Users & accounts", "settings sidebar category"),
            "icon": "account_circle",
            "hubHeader": "UserAccountsTab",
            "tabIndex": 60,
            "children": [
                {
                    "id": "users",
                    "text": I18n.tr("Accounts", "settings page name for user accounts"),
                    "icon": "manage_accounts",
                    "tabIndex": 35,
                    "hint": I18n.tr("Users", "hint under the accounts settings sidebar entry")
                },
                {
                    "id": "user_create",
                    "hidden": true,
                    "text": I18n.tr("Add user", "button and settings page title, creates a new user account"),
                    "icon": "person_add",
                    "tabIndex": 61
                }
            ]
        },
        {
            "id": "security_accounts",
            "aliases": ["security"],
            "text": I18n.tr("Security"),
            "icon": "lock",
            "children": [
                {
                    "id": "lock_screen",
                    "text": I18n.tr("Lock screen"),
                    "icon": "lock",
                    "tabIndex": 11,
                    "hint": CompositorService.isKwin ? "Automatische Sperre, Sperre nach der Anmeldung" : I18n.tr("Layout, authentication, screensaver")
                },
                {
                    // Alpe: Texte, Bilder und Passwortfeld des KDE-Sperrbildschirms anordnen.
                    "id": "lock_design",
                    "aliases": ["sperrbildschirm gestalten", "lockscreen design", "hyprlock"],
                    "text": "Sperrbildschirm gestalten",
                    "icon": "brush",
                    "tabIndex": 105,
                    "hint": "Uhr, Datum, Bilder, Passwortfeld – mit Vorschau"
                }
            ]
        },
        {
            "id": "separator_5",
            "separator": true
        },
        {
            "id": "applications",
            "text": I18n.tr("Applications"),
            "icon": "apps",
            "hint": I18n.tr("Defaults, autostart, rules", "settings sidebar hint for the applications page"),
            "children": [
                {
                    "id": "default_apps",
                    "text": I18n.tr("Default apps"),
                    "icon": "star",
                    "tabIndex": 34,
                    "hint": I18n.tr("Browser, terminal, file manager, media")
                },
                {
                    "id": "autostart",
                    "text": I18n.tr("Autostart apps"),
                    "icon": "line_start",
                    "tabIndex": 36,
                    "hint": I18n.tr("Apps and commands started with the session")
                },
                {
                    "id": "window_rules",
                    "text": I18n.tr("Window rules"),
                    "icon": "select_window",
                    "tabIndex": 38,
                    "windowRulesCapable": true,
                    "hint": I18n.tr("Floating, opacity and placement rules per app")
                },
                {
                    "id": "running_apps",
                    "advanced": true,
                    "text": I18n.tr("Running apps"),
                    "icon": "app_registration",
                    "tabIndex": 19,
                    "hyprlandNiriOnly": true,
                    "hint": I18n.tr("App ID substitutions")
                }
            ]
        },
        {
            "id": "date_time_region",
            "aliases": ["datetime", "region"],
            "text": I18n.tr("Date, time & region"),
            "icon": "schedule",
            "hint": I18n.tr("Clock, weather, locale", "settings sidebar hint for the date, time and region page"),
            "children": [
                {
                    "id": "time_weather",
                    "text": I18n.tr("Time & weather"),
                    "icon": "schedule",
                    "tabIndex": 1,
                    "hint": I18n.tr("Clock format, calendar, weather location")
                },
                {
                    "id": "weather",
                    "text": I18n.tr("Weather"),
                    "icon": "partly_cloudy_day",
                    "tabIndex": 56,
                    "hint": I18n.tr("Forecast and conditions")
                },
                {
                    // Alpe: Einstellungen des Sport-Plugins
                    "id": "alpe_sport",
                    "aliases": ["sport", "fussball", "eishockey", "nba", "streaming"],
                    "text": "Sport",
                    "icon": "sports_soccer",
                    "tabIndex": 109,
                    "hint": "Wettbewerbe, Favoriten, Mitteilungen, Streamingdienste"
                },
                {
                    "id": "locale",
                    "text": I18n.tr("Locale", "settings page name for language and region"),
                    "icon": "language",
                    "tabIndex": 30,
                    "hint": I18n.tr("Language, time and date locale")
                }
            ]
        },
        {
            "id": "system",
            "text": I18n.tr("System & integrations"),
            "icon": "memory",
            "hint": I18n.tr("Updates, clipboard, %1", "settings sidebar hint for the system and integrations page, %1 is the compositor name").arg(CompositorService.displayName),
            "children": [
                {
                    "id": "updater",
                    "text": I18n.tr("Software updates", "settings page, modal and bar widget title, Alpe and system package updates"),
                    "icon": "system_update_alt",
                    "tabIndex": 20,
                    "hint": I18n.tr("Alpe and system updates", "settings sidebar hint for the software updates page")
                },
                {
                    "id": "alpe_desktop",
                    "aliases": ["kwin", "plasma"],
                    "text": "KWin & Plasma",
                    "icon": "desktop_windows",
                    "tabIndex": 100,
                    "kwinOnly": true,
                    "hint": "Fenster ziehen, Kurzbefehle, KDE-Module"
                },
                {
                    "id": "alpe_effects",
                    "aliases": ["effekte", "ecken", "blur", "animationen", "platzierung"],
                    "text": "Fenster & Effekte",
                    "icon": "auto_awesome",
                    "tabIndex": 106,
                    "hint": CompositorService.isKwin ? "Abgerundete Ecken, Weichzeichnen, neue Fenster, Animationen" : "Unschärfe: Modus, Feinheiten, was gerade gilt"
                },
                {
                    "id": "alpe_performance",
                    "aliases": ["leistung", "ram", "speicher", "performance"],
                    "text": "Leistung",
                    "icon": "speed",
                    "tabIndex": 108,
                    "hint": "Speicher und CPU der Shell, Teile abschalten"
                },
                {
                    "id": "alpe_services",
                    "aliases": ["dienste", "services", "systemd"],
                    "text": "Dienste",
                    "icon": "deployed_code",
                    "tabIndex": 107,
                    "hint": "Shell-Dienst, eigene systemd-Dienste, Autostart"
                },
                {
                    "id": "alpe_maintenance",
                    "aliases": ["maintenance", "wartung"],
                    "text": "Wartung",
                    "icon": "build",
                    "tabIndex": 101,
                    "hint": "Neustart, Zwischenspeicher, Plugins"
                },
                {
                    "id": "alpe_device",
                    "aliases": ["device", "geraet"],
                    "text": "Dieses Gerät",
                    "icon": "devices",
                    "tabIndex": 104,
                    "hint": "Erkanntes Modell und was Alpe daraus ableitet"
                },
                {
                    "id": "alpe_pages",
                    "aliases": ["pages", "seiten"],
                    "text": "Seitenauswahl",
                    "icon": "visibility_off",
                    "tabIndex": 103,
                    "hint": "Einstellungsseiten ein- und ausblenden"
                },
                {
                    "id": "clipboard",
                    "text": I18n.tr("Clipboard", "noun, settings page name and launcher section title"),
                    "icon": "content_paste",
                    "tabIndex": 23,
                    "clipboardOnly": true,
                    "hint": I18n.tr("History size, retention, paste behavior")
                },
                {
                    "id": "compositor_layout",
                    "text": CompositorService.displayName,
                    "icon": "layers",
                    "tabIndex": 37,
                    "layoutCapable": true,
                    "hint": I18n.tr("Gaps, window borders, corner radius")
                },
                {
                    "id": "multiplexers",
                    "advanced": true,
                    "text": I18n.tr("Multiplexers", "settings page name for terminal multiplexers like tmux"),
                    "icon": "terminal",
                    "tabIndex": 32,
                    "hint": I18n.tr("tmux, zellij, and herdr sessions", "settings page description for terminal multiplexer sessions; tmux, zellij, and herdr are product names")
                },
                {
                    "id": "printers",
                    "advanced": true,
                    "text": I18n.tr("Printers", "settings page name and control center widget title"),
                    "icon": "print",
                    "tabIndex": 8,
                    "cupsOnly": true,
                    "hint": I18n.tr("CUPS printers, jobs and classes")
                }
            ]
        },
        {
            "id": "plugins",
            "text": I18n.tr("Plugins"),
            "icon": "extension",
            "hint": "Installierte Plugins verwalten",
            "tabIndex": 12,
            "hubHeader": "PluginsHubHeader",
            "children": [
                {
                    "id": "plugins_manage",
                    "hidden": true,
                    "text": "Plugin-Ordner",
                    "icon": "folder_open",
                    "tabIndex": 28,
                    "hint": "Ordner und Suche nach Plugins"
                }
            ]
        },
        {
            "id": "separator_6",
            "separator": true
        },
        {
            "id": "about",
            "text": I18n.tr("About", "settings page name"),
            "icon": "info",
            "hint": "Version, Herkunft, Werkzeuge",
            "tabIndex": 13
        }
    ]

    // Alpe: Seiten, die auf diesem Rechner nichts zu tun haben, fallen weg. Akku und WLAN
    // richten sich nach der Hardware, alles Weitere nach der Seitenauswahl.
    readonly property var pinnedPages: ["about", "system", "alpe_pages", "updater"]
    // Vorgabe je Gerät: Ein Rechner ohne Akku hängt am Kabel und braucht die WLAN-Seite nicht,
    // ein Laptop schon. Sie gilt, solange in der Liste "auto" steht, also bis zur ersten eigenen Wahl.
    readonly property bool isLaptop: BatteryService.batteryAvailable
    readonly property var deviceHiddenPages: isLaptop ? [] : ["network_wifi"]
    readonly property var hiddenList: {
        const stored = SettingsData.settingsHiddenPages || [];
        if (!stored.includes("auto"))
            return stored;
        return stored.filter(id => id !== "auto").concat(deviceHiddenPages.filter(id => !stored.includes(id)));
    }
    readonly property var hiddenPages: {
        const out = {};
        for (const id of hiddenList)
            out[id] = true;
        return out;
    }
    readonly property bool wifiPresent: (NetworkService.wifiDevices?.length ?? 0) > 0
    readonly property bool wifiShown: wifiPresent && !hiddenPages["network_wifi"]

    function isPinned(id) {
        return pinnedPages.includes(id);
    }

    function isHiddenByUser(id) {
        return !!hiddenPages[id] && !isPinned(id);
    }

    function setPageHidden(id, hidden) {
        if (isPinned(id))
            return;
        const list = hiddenList.filter(entry => entry !== id);
        if (hidden)
            list.push(id);
        SettingsData.set("settingsHiddenPages", list);
    }

    // Für die Suche: die Seite und ihre Gruppe müssen sichtbar sein. Die Sperrbildschirm-Seite
    // des Ursprungsprojekts ist unter KWin ersetzt, ihre Einträge gelten dort nicht.
    function isSearchable(id, own) {
        const entry = page(id);
        if (!entry || entry.kind === "plugin")
            return true;
        if ((id === "lock_screen" || id === "keybinds" || id === "window_rules") && CompositorService.isKwin && !own)
            return false;
        if (!isVisible(entry))
            return false;
        return !entry.parentId || isVisible(pageMap[entry.parentId]);
    }

    // Ob eine Seite ohne Rücksicht auf die Seitenauswahl überhaupt in Frage käme.
    function isAvailable(entry) {
        return isVisible(entry, true);
    }

    readonly property var pageMap: buildPageMap(structure)
    readonly property var normalizedIds: buildNormalizedIds(pageMap)
    readonly property var tabIndexToPage: buildTabIndexMap(pageMap)
    readonly property var pluginHubRows: buildPluginRows(PluginService.availablePluginsList)

    function buildPageMap(entries) {
        const map = {};
        for (const entry of entries) {
            if (entry.separator)
                continue;
            const hub = Object.assign({}, entry, {
                "kind": entry.children ? "hub" : "leaf",
                "parentId": ""
            });
            map[entry.id] = hub;
            for (const child of entry.children || []) {
                map[child.id] = Object.assign({}, child, {
                    "kind": "leaf",
                    "parentId": entry.id
                });
            }
        }
        return map;
    }

    function buildNormalizedIds(map) {
        const out = {};
        for (const id in map) {
            out[normalizeId(id)] = id;
            for (const alias of map[id].aliases || [])
                out[normalizeId(alias)] = id;
        }
        return out;
    }

    function buildTabIndexMap(map) {
        const out = {};
        for (const id in map) {
            const entry = map[id];
            if (entry.tabIndex === undefined)
                continue;
            if (out[entry.tabIndex] === undefined || entry.kind === "leaf")
                out[entry.tabIndex] = id;
        }
        return out;
    }

    function buildPluginRows(plugins) {
        const rows = (plugins || []).map(plugin => ({
                    "id": pluginPrefix + plugin.id,
                    "kind": "plugin",
                    "parentId": "plugins",
                    "pluginId": plugin.id,
                    "text": plugin.name || plugin.id,
                    "icon": plugin.icon || "extension",
                    "hint": plugin.description || "",
                    "hasSettings": !!plugin.settings && plugin.type !== "desktop"
                }));
        rows.sort((a, b) => a.text.localeCompare(b.text));
        return rows;
    }

    function normalizeId(name) {
        const normalized = String(name).toLowerCase().replace(/[_\-\s]/g, "");
        return normalized === "compositor" ? "workspaces" : normalized;
    }

    function isPluginPage(id) {
        return String(id).startsWith(pluginPrefix);
    }

    function pluginIdOf(id) {
        return String(id).slice(pluginPrefix.length);
    }

    function page(id) {
        if (!id)
            return null;
        if (isPluginPage(id))
            return pluginPage(pluginIdOf(id));
        return pageMap[id] ?? null;
    }

    function pluginPage(pluginId) {
        const row = pluginHubRows.find(candidate => candidate.pluginId === pluginId);
        if (row)
            return row;
        return {
            "id": pluginPrefix + pluginId,
            "kind": "plugin",
            "parentId": "plugins",
            "pluginId": pluginId,
            "text": pluginId,
            "icon": "extension",
            "hint": "",
            "hasSettings": false
        };
    }

    function parentOf(id) {
        return page(id)?.parentId ?? "";
    }

    function tabIndexForPage(id) {
        const entry = page(id);
        if (!entry || entry.tabIndex === undefined)
            return -1;
        return entry.tabIndex;
    }

    function pageForTabIndex(tabIndex) {
        return tabIndexToPage[tabIndex] ?? "";
    }

    function isVisible(entry, ignoreUserChoice) {
        if (!entry)
            return false;
        if (!ignoreUserChoice && isHiddenByUser(entry.id))
            return false;
        if (entry.batteryOnly && !BatteryService.batteryAvailable)
            return false;
        if (entry.wifiOnly && !wifiPresent)
            return false;
        if (entry.kwinOnly && !CompositorService.isKwin)
            return false;
        if (entry.dmsOnly && !NetworkService.networkAvailable)
            return false;
        if (entry.cupsOnly && !CupsService.cupsAvailable)
            return false;
        // Alpe: unter KWin gibt es eigene Seiten für Kürzel und Fensterregeln.
        if (entry.shortcutsOnly && !KeybindsService.available && !CompositorService.isKwin)
            return false;
        if (entry.soundsOnly && MultimediaService.unavailable)
            return false;
        if (entry.hyprlandNiriOnly && !CompositorService.isHyprland)
            return false;
        if (entry.windowRulesCapable && !CompositorService.supportsWindowRules && !CompositorService.isKwin)
            return false;
        if (entry.layoutCapable && !CompositorService.supportsLayoutConfig)
            return false;
        if (entry.inputCapable && !CompositorService.supportsInputConfig)
            return false;
        if (entry.pointerCapable && !CompositorService.supportsPointerConfig)
            return false;
        if (entry.clipboardOnly && (!ShellBackend.isConnected || ShellBackend.apiVersion < 23))
            return false;
        if (entry.autostartOnly)
            DesktopService.ensureProbed();
        if (entry.autostartOnly && !DesktopService.autostartAvailable)
            return false;
        if (entry.cellularOnly && (NetworkService.cellularDevices?.length ?? 0) === 0)
            return false;
        if (entry.kind === "hub" && !entry.hubHeader && visibleLeaves(entry.id, ignoreUserChoice).length === 0)
            return false;
        return true;
    }

    function visibleLeaves(hubId, ignoreUserChoice) {
        const hub = pageMap[hubId];
        if (!hub?.children)
            return [];
        return hub.children.filter(child => isVisible(child, ignoreUserChoice));
    }

    readonly property var groupAccents: ["purple", "blue", "green", "orange", "pink", "teal", "yellow", "red"]

    function accentFor(pageId) {
        const entry = page(pageId);
        if (!entry)
            return "";
        const topId = entry.parentId || entry.id;
        let group = 0;
        for (const item of structure) {
            if (item.separator) {
                group++;
                continue;
            }
            if (item.id === topId)
                return groupAccents[group] ?? "";
        }
        return "";
    }

    function hubHint(entry) {
        return entry.hint || visibleLeaves(entry.id).filter(child => entry.hubHeader || !child.hidden).map(child => child.text).join(", ");
    }

    function hubMainRows(hubId) {
        const hub = pageMap[hubId];
        if (!hub?.children)
            return [];
        return hub.children.filter(child => !child.advanced && !child.hidden && isVisible(child));
    }

    function hubMoreRows(hubId) {
        const hub = pageMap[hubId];
        if (!hub?.children)
            return [];
        return hub.children.filter(child => child.advanced && !child.hidden && isVisible(child));
    }

    function hubRows(hubId) {
        return hubMainRows(hubId).concat(hubMoreRows(hubId));
    }

    function resolvePage(name) {
        if (!name)
            return "";
        const raw = String(name).trim();
        if (isPluginPage(raw))
            return raw;
        const id = normalizedIds[normalizeId(raw)];
        if (!id)
            return "";
        const entry = pageMap[id];
        // Alpe: Eine Seite, die es hier nicht gibt (Akku ohne Akku, ausgeblendetes WLAN), ist auch
        // über Zahnräder, Suche und Befehle nicht erreichbar; der Aufruf landet in ihrem Bereich.
        if (entry.kind === "leaf" && entry.parentId && !isVisible(entry))
            return isVisible(pageMap[entry.parentId]) ? resolveHub(entry.parentId) : "";
        if (entry.kind !== "hub" || entry.hubHeader)
            return id;
        return resolveHub(id);
    }

    function resolveHub(id) {
        const leaves = visibleLeaves(id);
        return leaves.length === 1 && !pageMap[id].hubHeader ? leaves[0].id : id;
    }

    function listPageIds() {
        const ids = [];
        for (const entry of structure) {
            if (entry.separator)
                continue;
            ids.push(entry.id);
            for (const child of entry.children || [])
                ids.push(child.id);
        }
        for (const row of pluginHubRows)
            ids.push(row.id);
        return ids;
    }
}
