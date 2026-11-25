#!/usr/bin/env python3
"""Alpe-Design: das Aussehen eines Rechners festhalten und auf einem anderen einspielen.

    alpe design export [--bilder fragen|ja|nein] [--variante kde|hyprland]
        nimmt das aktuelle Aussehen auf und legt es in ~/alpe/design/<variante>/
        (KDE-PC: kde, Hyprland/Mac: hyprland – die Variante folgt der laufenden Sitzung)
    alpe design apply [--variante kde|hyprland] [--ja]
        spielt das Design ein (mit Sicherung der bisherigen Dateien)
    alpe design status
        zeigt, welche Designs im Repository liegen und ob eines eingespielt ist

Übernommen wird, was man sieht: Farben, Schriften, Leiste und ihre Elemente, Dock, Dash mit
seinen Tabs und Karten, Sperrbildschirm, Effekte und Fensterregeln unter KWin, die Einstellungen
der Alpe-Plugins, dazu die Einstellungen von kitty und fastfetch. Nicht übernommen wird, was zu einer Person oder einem Gerät gehört: Wetterort
(das Wetter folgt beim neuen Nutzer seinem Standort), Sport-Favoriten und Streaming-Links,
Bildschirm- und Geräte-Zuordnungen, eigene Befehle, Verläufe und jeder Pfad in den eigenen
Ordner. Bilder (Hintergrund, Sperrbildschirm) kommen nur mit, wenn man sie beim Export als eigene
bestätigt – fremde Fotos dürfen nicht in ein öffentliches Repository.
"""
import datetime
import filecmp
import glob
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HOME = os.path.expanduser("~")
CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.join(HOME, ".config")
STATE = os.environ.get("XDG_STATE_HOME") or os.path.join(HOME, ".local", "state")
DATA = os.environ.get("XDG_DATA_HOME") or os.path.join(HOME, ".local", "share")
ALPE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHELL_DIR = os.environ.get("ALPE_SHELL_DIR") or os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "shell")
DESIGN_ROOT = os.environ.get("ALPE_DESIGN_DIR") or os.path.join(ALPE_DIR, "design")
INSTALLED = os.path.join(DATA, "alpe", "design")       # Bilder des eingespielten Designs
MARK = os.path.join(CONFIG, "alpe", "design-eingespielt")
TOKEN = "@DESIGN@"                                       # steht in den Dateien für INSTALLED

SETTINGS = os.path.join(CONFIG, "alpe", "settings.json")
SESSION = os.path.join(STATE, "alpe", "session.json")
PLUGINS = os.path.join(CONFIG, "alpe", "plugin_settings.json")
HYPRLOCK = os.path.join(CONFIG, "hypr", "hyprlock.conf")

# ---------------------------------------------------------------- was dazugehört

# settings.json: Gerät, Person oder eigene Befehle – fällt weg (der neue Nutzer bekommt die Vorgabe)
SETTINGS_DROP = {
    "screenPreferences", "showOnLastDisplay", "displayProfiles", "displayProfileAutoSelect",
    "displayPreviousRefreshModes", "matugenTargetMonitor", "notificationFocusedMonitor",
    "lockPamPath", "lockScreenVideoPath", "updaterCustomCommand", "updaterUseCustomCommand",
    "muxCustomCommand", "muxUseCustomCommand", "customPowerActionLock", "customPowerActionLogout",
    "customPowerActionSuspend", "customPowerActionHibernate", "customPowerActionReboot",
    "customPowerActionPowerOff", "weatherLocation", "weatherCoordinates",
}
# Gerätegebundene Schlüssel an beliebiger Stelle (auch in Widgets der Leiste): fallen weg. `pciId` ist die
# Kennung der Grafikkarte im Widget gpuTemp; die Shell trägt sie auf dem neuen Rechner selbst wieder ein.
NESTED_DROP = {"pciId"}
# settings.json: Schlüssel, die bis 1.0 den Namen des Ursprungs trugen (wie die Migration der
# Shell auf Version 43, shell/Common/settings/SettingsStore.js). Ein Design aus 1.0 trifft so
# beim Einspielen dieselben Schlüssel wie die Einstellungen des Nutzers.
RENAMED_KEYS = {
    "dankLauncherV2Size": "launcherSize",
    "dankLauncherV2ShowSourceBadges": "launcherShowSourceBadges",
    "dankLauncherV2BorderEnabled": "launcherBorderEnabled",
    "dankLauncherV2BorderThickness": "launcherBorderThickness",
    "dankLauncherV2BorderColor": "launcherBorderColor",
    "dankLauncherV2ShowFooter": "launcherShowFooter",
    "dankLauncherV2UnloadOnClose": "launcherUnloadOnClose",
    "dankLauncherV2IncludeFilesInAll": "launcherIncludeFilesInAll",
    "dankLauncherV2IncludeFoldersInAll": "launcherIncludeFoldersInAll",
    "runDmsMatugenTemplates": "runMatugenTemplates",
    "dmsWindowsFloatingSeeded": "shellWindowsFloatingSeeded",
}
RENAMED_VALUES = {"alpeLockStyle": {"dms": "standard"}, "alpeHyprBlurMode": {"dms": "standard"},
                  "matugenSpec": {"dms": "alpe"}}
# Gespeicherte Kennungen (Migration auf Version 44 bzw. Session 8, dieselben Tabellen wie
# shell/Common/settings/Namen44.js; tests/test_design.py vergleicht sie): Starter-Einträge als
# Schlüssel oder Wert an beliebiger Stelle, Werte unter bestimmten Schlüsseln.
STARTER_IDS = {"dms_" + name: "alpe_" + name for name in (
    "settings", "notepad", "sysmon", "colorpicker", "settings_search", "clipboard_search",
    "power", "vpn", "qr_generator")}
VALUES_BY_KEY = {"launcherLogoMode": {"dank": "alpe"}, "islandFreeIconMode": {"dank": "alpe"}}
PAGE_LIST_KEYS = ("settingsHiddenPages",)
PAGE_IDS = {"dankbar": "bar", "dankbar_settings": "bar_settings", "dankbar_appearance": "bar_appearance",
            "dankbar_dot": "bar_dot", "dankbar_widgets": "bar_widgets", "dank_dash": "dash"}
MATERIAL_KEYS = ("materialWallpapers", "materialWallpaperProfiles")
MATERIAL_VALUES = {"preset": {"dank": "alpe"}, "shape": {"dankLogo": "alpeLogo"}}
# Wer eine Leiste oder ein Dock für einen bestimmten Bildschirm hat, bekommt sie auf allen
SCREEN_KEYS = {"screenPreferences": ["all"], "frameScreenPreferences": ["all"]}
# settings.json: so beim neuen Nutzer, egal wie beim Exportierenden
SETTINGS_FORCE = {"useAutoLocation": True}
# matugen-Vorlagen für fremde Programme, die das ausgelieferte Design nicht einschaltet (Firefox, Neovim, Zen,
# Zed): Der Export schreibt sie immer aus, egal wie beim Exportierenden. Eingespielt werden sie nur, wenn es noch
# gar keine Einstellungen gibt (frische Installation). Wer schon Einstellungen hat, behält seinen Stand – auch
# wenn der Schlüssel in seiner Datei fehlt, weil die Shell Vorgabewerte nicht ausschreibt (Vorgabe meist «an»).
SETTINGS_NUR_NEU = {"matugenTemplateFirefox": False, "matugenTemplateNeovim": False,
                    "matugenTemplateZenBrowser": False, "matugenTemplateZed": False}

# session.json: Übernommen wird nur, was hier als Gestaltung steht (Plan 0.8 Nr. 79, Liste in 7.8). Jeder
# Schlüssel aus SessionSpec.js und SharedSessionSpec.js steht in genau einer der beiden Listen; ein neuer
# Schlüssel der Shell muss hier eingeordnet werden, sonst schlägt tests/test_design.py fehl.
SESSION_GESTALTUNG = [
    # Hell/Dunkel und Hintergrund
    "isLightMode", "wallpaperPath", "wallpaperPathLight", "wallpaperPathDark", "perModeWallpaper",
    "wallpaperTransition", "includedTransitions",
    # Material-Vorlage und eigene Formen (nur der Eintrag für alle Bildschirme, siehe export)
    "materialWallpapers", "materialWallpaperProfiles",
    # Zeitplan für Hell/Dunkel
    "themeModeAutoEnabled", "themeModeAutoMode", "themeModeStartHour", "themeModeStartMinute",
    "themeModeEndHour", "themeModeEndMinute", "themeModeShareGammaSettings",
    # Nachtlicht: Farbtemperatur und Zeitplan
    "nightModeEnabled", "nightModeTemperature", "nightModeHighTemperature", "nightModeAutoEnabled",
    "nightModeAutoMode", "nightModeStartHour", "nightModeStartMinute", "nightModeEndHour",
    "nightModeEndMinute", "nightModeTransitionMinutes",
]
# Zustand: Verläufe, Anheftungen, Ort, Geräte, Bildschirme, Sprache – bleibt beim Nutzer.
SESSION_ZUSTAND = [
    # Augenblickszustand
    "doNotDisturb", "doNotDisturbUntil", "doNotDisturbHeldByScreenShare", "screenShareDndDismissed",
    "screenShareDismissedIds", "idleInhibited", "idleInhibitedUntil", "updaterNotifiedUnix",
    "updaterNotifiedCount", "showConfigReloadToast", "lastAppliedIconTheme", "builtInPluginState",
    # Verläufe und zuletzt Benutztes
    "recentColors", "launcherLastMode", "launcherLastFileSearchType", "launcherLastQuery",
    "launcherQueryHistory", "appDrawerLastMode", "notepadLastMode", "vpnLastConnected",
    "lastPlayerIdentity", "pinnedPlayerIdentity", "lastBrightnessDevice",
    # Programme des Nutzers
    "dockPins", "barPinnedApps", "hiddenTrayIds", "trayItemOrder", "hiddenApps", "appOverrides",
    "searchAppActions", "terminalOverride",
    # Ort und Sprache
    "weatherLocation", "weatherCoordinates", "latitude", "longitude", "nightModeUseIPLocation",
    "nightModeLocationName", "locale", "timeLocale",
    # Bildschirme (Schlüssel sind Bildschirmnamen oder -modelle)
    "perMonitorWallpaper", "monitorWallpapers", "monitorWallpapersLight", "monitorWallpapersDark",
    "monitorWallpaperFillModes", "monitorCyclingSettings", "desktopWidgetInstancePositions",
    "lockScreenAutoPositions", "desktopWidgetGridSettings", "lockScreenWidgetGridSettings",
    "islandFreePositions", "hyprlandOutputSettings", "activeDisplayProfile", "activeDisplayProfileModes",
    "displayGamma", "displayContrast",
    # Wechsel des Hintergrunds aus einem eigenen Ordner
    "wallpaperCyclingEnabled", "wallpaperCyclingRandom", "wallpaperCyclingRecursive", "wallpaperCyclingMode",
    "wallpaperCyclingInterval", "wallpaperCyclingTime", "wallpaperCyclingFolderPath", "wallpaperCyclingVideoEnd",
    # Geräte
    "brightnessExponentialDevices", "brightnessUserSetValues", "brightnessExponentValues",
    "nvidiaGpuTempEnabled", "nonNvidiaGpuTempEnabled", "enabledGpuPciIds", "wifiDeviceOverride",
    "bluetoothAdapterOverride", "deviceMaxVolumes", "hiddenOutputDeviceNames", "hiddenInputDeviceNames",
]
WALLPAPER_KEYS = ("wallpaperPath", "wallpaperPathLight", "wallpaperPathDark")

# plugin_settings.json: je Alpe-Plugin, was zum Aussehen und Verhalten gehört
PLUGIN_KEEP = {
    "alpeSport": ["order", "notifyGoals", "notifyStart", "notifyEnd", "barLive", "barUpcoming",
                  "refreshLive", "growDetail", "barWidgetAdded", "enabled"],
    "alpeMeteoSwiss": None,     # None: alles ausser Ort und Pfaden
    "alpeRadar": None,
}
PERSONAL_PLUGIN_KEYS = re.compile(r"(location|point|coord|lat|lon|plz|zip|city|ort|favorit|stream|token|key)", re.I)

# KWin (KDE-PC): Effekte, Animation, Fensterregeln, Sperrbildschirm
KWIN_GROUPS = [("kwinrc", "Round-Corners"), ("kwinrc", "Effect-better-blur-dx")]
KWIN_KEYS = [("kwinrc", "Plugins", "kwin4_effect_shapecornersEnabled"), ("kwinrc", "Plugins", "better_blur_dxEnabled"),
             ("kwinrc", "Plugins", "blurEnabled"), ("kdeglobals", "KDE", "AnimationDurationFactor")]
LOCK_GROUP = "Greeter/LnF/General"
LOCK_KEYS = ("Style", "Layout")

# Programme, deren Einstellungen zum Aussehen gehören: Ordner unter ~/.config
PROGRAMME = ("kitty", "fastfetch")
PROGRAMM_EXT = (".conf", ".jsonc", ".json", ".py", ".ini", ".toml")
PROGRAMM_SKIP = ("alpe-logo.txt",)                       # entsteht beim Einspielen neu (tools/fastfetch.py)
SECRET = re.compile(r"(password|passwd|token|secret|api[_-]?key)", re.I)

IMAGE_EXT = (".png", ".jpg", ".jpeg", ".webp", ".svg", ".gif", ".bmp", ".mp4", ".webm", ".mkv", ".mov")
MAX_BYTES = 50 * 1024 * 1024    # GitHub lehnt Dateien ab 100 MB ab; Videos darüber gehören nicht ins Repository
VIDEO_EXT = (".mp4", ".webm", ".mkv", ".mov")   # Videos unter IMAGE_EXT; zu ihnen gehört ein Standbild (Plan 0.8 Nr. 106)


def say(text=""):
    print(text, flush=True)


def kwin():
    path = os.path.join(SHELL_DIR, "scripts", "alpe-kwin.py")
    spec = importlib.util.spec_from_file_location("alpe_kwin", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def session_variant():
    desktop = (os.environ.get("XDG_CURRENT_DESKTOP") or "").lower()
    if "kde" in desktop or "kwin" in desktop:
        return "kde"
    if "hyprland" in desktop or os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        return "hyprland"
    return "kde" if shutil.which("kwin_wayland") else "hyprland"


def load_json(path, default=None):
    try:
        with open(path, encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, ValueError):
        return default


def save_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".alpe-neu"
    with open(tmp, "w", encoding="utf-8") as handle:
        json.dump(data, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    os.replace(tmp, path)


def personal(value):
    """Enthält der Wert (auch verschachtelt) einen Pfad in den eigenen Ordner?"""
    if isinstance(value, str):
        return HOME in value or value.startswith("~/") or "file://" + HOME in value
    if isinstance(value, dict):
        return any(personal(v) for v in value.values())
    if isinstance(value, list):
        return any(personal(v) for v in value)
    return False


def screens_to_all(value):
    if isinstance(value, dict):
        return {k: (SCREEN_KEYS[k] if k in SCREEN_KEYS else screens_to_all(v)) for k, v in value.items() if k not in NESTED_DROP}
    if isinstance(value, list):
        return [screens_to_all(v) for v in value]
    return value


def fill(value, base):
    if isinstance(value, str):
        return value.replace(TOKEN, base)
    if isinstance(value, dict):
        return {k: fill(v, base) for k, v in value.items()}
    if isinstance(value, list):
        return [fill(v, base) for v in value]
    return value


# ---------------------------------------------------------------- Bilder

class Images:
    """Sammelt Bildpfade, fragt einmal je Datei, ob sie mit darf, und kopiert die erlaubten.

    previous: Ordner bilder/ des bisherigen Exports (vor dem Abräumen gesichert) oder None – daraus kommt das
    Standbild eines Videos, wenn es neben dem Video selbst nicht liegt (standbild)."""

    def __init__(self, target, mode, ask=input, previous=None):
        self.target, self.mode, self.ask, self.previous = target, mode, ask, previous
        self.decided = {}
        self.taken, self.left = [], []

    def take(self, path):
        """Pfad im Design (@DESIGN@/bilder/…) oder None, wenn das Bild nicht mitkommt."""
        if not isinstance(path, str) or not path:
            return None
        path = path[7:] if path.startswith("file://") else path
        path = os.path.expanduser(path)
        if path in self.decided:
            return self.decided[path]
        result = None
        if not os.path.isfile(path):
            self.left.append((path, "fehlt"))
        elif os.path.getsize(path) > MAX_BYTES:
            self.left.append((path, "grösser als 50 MB"))
        else:
            allowed = self.mode == "ja"
            if self.mode == "fragen":
                answer = self.ask("   Eigenes Bild, darf öffentlich ins Repository? %s [j/N] " % path.replace(HOME, "~"))
                allowed = answer.strip().lower() in ("j", "ja", "y", "yes")
            if allowed:
                name = os.path.basename(path)
                stem, ext = os.path.splitext(name)
                n = 2
                while os.path.exists(os.path.join(self.target, name)):
                    name = "%s-%d%s" % (stem, n, ext)
                    n += 1
                os.makedirs(self.target, exist_ok=True)
                shutil.copy2(path, os.path.join(self.target, name))
                result = TOKEN + "/bilder/" + name
                self.taken.append(name)
                if name.lower().endswith(VIDEO_EXT):
                    self.standbild(path, name)
            else:
                self.left.append((path, "nicht als eigenes bestätigt"))
        self.decided[path] = result
        return result

    def standbild(self, video, name):
        """Standbild eines Videos des Designs mitnehmen (Plan 0.8 Nr. 106): gleichnamiges .jpg neben dem Video.

        Quelle ist das .jpg neben dem Video im eingespielten Design (INSTALLED, dorthin legt «apply» beides), oder –
        liegt es dort nicht – das Standbild aus dem bisherigen Export, wenn dort dasselbe Video lag (gleicher Inhalt).
        Für eigene Videos der Nutzer ausserhalb des Designs wird kein .jpg daneben genommen, wie in der Shell
        (shell/Common/VideoPoster.js). Das Bild kommt unter dem Namen des Videos mit .jpg in bilder/ und ins Manifest.
        """
        ziel = os.path.splitext(name)[0] + ".jpg"
        quelle = None
        neben = os.path.splitext(video)[0] + ".jpg"
        if os.path.realpath(video).startswith(os.path.realpath(INSTALLED) + os.sep) and os.path.isfile(neben):
            quelle = neben
        elif self.previous and os.path.isdir(self.previous):
            for alt in sorted(os.listdir(self.previous)):
                alt_video = os.path.join(self.previous, alt)
                alt_bild = os.path.splitext(alt_video)[0] + ".jpg"
                if (alt.lower().endswith(VIDEO_EXT) and os.path.isfile(alt_bild)
                        and filecmp.cmp(alt_video, video, shallow=False)):
                    quelle = alt_bild
                    break
        if not quelle:
            return
        if os.path.exists(os.path.join(self.target, ziel)) or ziel in self.taken:
            self.left.append((quelle, "Standbild: %s ist schon belegt" % ziel))
            return
        shutil.copy2(quelle, os.path.join(self.target, ziel))
        self.taken.append(ziel)


def scrub(value, images, where, dropped):
    """Jeden Pfad in den eigenen Ordner behandeln: Bilder fragen, alles andere entfernen.
    Gibt (wert, behalten?) zurück."""
    if isinstance(value, str):
        if not personal(value):
            return value, True
        if value.lower().endswith(IMAGE_EXT):
            mapped = images.take(value)
            if mapped:
                return mapped, True
        dropped.append("%s (Pfad in den eigenen Ordner)" % where)
        return None, False
    if isinstance(value, dict):
        out = {}
        for k, v in value.items():
            if k in NESTED_DROP:
                dropped.append("%s.%s (gerätegebunden)" % (where, k))
                continue
            new, keep = scrub(v, images, where + "." + k, dropped)
            if keep:
                out[k] = new
        return out, True
    if isinstance(value, list):
        out = []
        for i, v in enumerate(value):
            new, keep = scrub(v, images, "%s[%d]" % (where, i), dropped)
            if keep:
                out.append(new)
        return out, True
    return value, True


def lock_layout_images(layout, images):
    """Bilder im Layout des Sperrbildschirms (JSON des Gestalters) übernehmen oder entfernen."""
    if not isinstance(layout, dict):
        return layout
    out = json.loads(json.dumps(layout))
    background = out.get("background") or {}
    for key in ("path", "image"):
        if key in background:
            mapped = images.take(background[key])
            if mapped:
                background[key] = mapped
            else:
                background.pop(key, None)
                if background.get("source") == "image":
                    background["source"] = "desktop"
    widgets = []
    for widget in out.get("widgets") or []:
        if widget.get("type") == "image":
            mapped = images.take(widget.get("path"))
            if not mapped:
                continue
            widget["path"] = mapped
        widgets.append(widget)
    out["widgets"] = widgets
    return out


def hyprlock_images(text, images):
    """hyprlock.conf: image-Blöcke mit fremden Bildern weglassen, eigene umschreiben."""
    out, block, depth = [], [], 0
    for line in text.splitlines():
        stripped = line.strip()
        if depth == 0 and re.match(r"^(image|background)\s*\{", stripped):
            block, depth = [line], 1
            continue
        if depth:
            block.append(line)
            depth += stripped.count("{") - stripped.count("}")
            if depth == 0:
                kind = block[0].strip().split()[0]
                keep = []
                drop = False
                for item in block:
                    m = re.match(r"^(\s*)path\s*=\s*(.+?)\s*$", item)
                    if m:
                        mapped = images.take(m.group(2))
                        if mapped:
                            keep.append("%spath = %s" % (m.group(1), mapped))
                        elif kind == "image":
                            drop = True
                        # background ohne Bild: Alpe nimmt den Desktop-Hintergrund
                        continue
                    keep.append(item)
                if not drop:
                    out.extend(keep)
            continue
        out.append(line)
    return "\n".join(out) + "\n"


def renamed(settings):
    """Alte Schlüssel und Werte (bis 1.0) unter den heutigen Namen; ein schon vorhandener neuer gewinnt."""
    out = {}
    for key, value in settings.items():
        new = RENAMED_KEYS.get(key)
        if new is None:
            out[key] = value
        elif new not in settings:
            out[new] = value
    for key, values in RENAMED_VALUES.items():
        if isinstance(out.get(key), str) and out[key] in values:
            out[key] = values[out[key]]
    for key in PAGE_LIST_KEYS:
        if isinstance(out.get(key), list):
            out[key] = list(dict.fromkeys(PAGE_IDS.get(page, page) if isinstance(page, str) else page for page in out[key]))
    return deep_renamed(out, STARTER_IDS, VALUES_BY_KEY)


def deep_renamed(value, ids, by_key):
    """Kennungen im ganzen Baum umbenennen; ein schon vorhandener neuer Schlüssel gewinnt."""
    if isinstance(value, str):
        return ids.get(value, value)
    if isinstance(value, list):
        return [deep_renamed(item, ids, by_key) for item in value]
    if not isinstance(value, dict):
        return value
    out = {}
    for key, child in value.items():
        if isinstance(child, str) and child in by_key.get(key, {}):
            child = by_key[key][child]
        else:
            child = deep_renamed(child, ids, by_key)
        if key not in ids:
            out[key] = child
        elif ids[key] not in value:
            out[ids[key]] = child
    return out


def renamed_session(session):
    """Dasselbe für session.json (Starter-Einträge in Pins, Material-Vorlage «Alpe»)."""
    out = deep_renamed(session, STARTER_IDS, {})
    for key in MATERIAL_KEYS:
        if key in out:
            out[key] = deep_renamed(out[key], {}, MATERIAL_VALUES)
    return out


def known_bar_widgets():
    """Widget-Kennungen, die jede Alpe-Installation kennt: die eingebauten Widgets der Leiste
    (Modules/Bar/WidgetModel.js) und die mitgelieferten Plugins. None, wenn die Liste nicht lesbar ist."""
    try:
        with open(os.path.join(SHELL_DIR, "Modules", "Bar", "WidgetModel.js"), encoding="utf-8") as handle:
            block = re.search(r"componentNames\s*=\s*\{(.*?)\n\}", handle.read(), re.S)
    except OSError:
        return None
    if not block:
        return None
    known = set(re.findall(r'^\s*"([^"]+)"\s*:', block.group(1), re.M)) | set(PLUGIN_KEEP)
    folder = os.path.join(ALPE_DIR, "plugins")
    for name in (os.listdir(folder) if os.path.isdir(folder) else []):
        plugin_id = (load_json(os.path.join(folder, name, "plugin.json"), {}) or {}).get("id")
        if plugin_id:
            known.add(plugin_id)
    return known


def drop_foreign_widgets(settings, dropped):
    """Widgets fremder Plugins aus dem Bar-Layout nehmen: Der neue Nutzer hat das Plugin nicht,
    die Stelle bliebe leer, und die Kennung verrät, was beim Exportierenden installiert ist."""
    known = known_bar_widgets()
    if known is None:
        return
    for bar in settings.get("barConfigs") or []:
        if not isinstance(bar, dict):
            continue
        for side in ("leftWidgets", "centerWidgets", "rightWidgets"):
            kept = []
            for widget in bar.get(side) or []:
                widget_id = widget.get("id") if isinstance(widget, dict) else widget
                if widget_id in known:
                    kept.append(widget)
                else:
                    dropped.append("barConfigs.%s: Widget «%s» (fremdes Plugin)" % (side, widget_id))
            if side in bar:
                bar[side] = kept


# ---------------------------------------------------------------- Export

def export(variant, mode, ask=input):
    target = os.path.join(DESIGN_ROOT, variant)
    # Der bisherige Ordner bilder/ wird vor dem Abräumen gesichert: Aus ihm kommt das Standbild eines Videos, wenn
    # es neben dem Video im eingespielten Design fehlt (Images.standbild, Plan 0.8 Nr. 106).
    previous = tempfile.mkdtemp(prefix="alpe-design-vorher-")
    try:
        if os.path.isdir(os.path.join(target, "bilder")):
            shutil.copytree(os.path.join(target, "bilder"), os.path.join(previous, "bilder"))
        if os.path.isdir(target):
            shutil.rmtree(target)
        os.makedirs(target)
        return export_into(variant, target, mode, ask, os.path.join(previous, "bilder"))
    finally:
        shutil.rmtree(previous, ignore_errors=True)


def export_into(variant, target, mode, ask, previous):
    images = Images(os.path.join(target, "bilder"), mode, ask, previous)
    notes, dropped = [], []

    settings = renamed(load_json(SETTINGS, {}) or {})
    if not settings:
        say("   Keine Einstellungen gefunden (%s) – hier läuft Alpe noch nicht?" % SETTINGS.replace(HOME, "~"))
    drop_foreign_widgets(settings, dropped)
    out = {}
    for key, value in settings.items():
        if key in SETTINGS_DROP:
            dropped.append(key)
            continue
        if key == "customThemeFile" and value:
            theme = os.path.expanduser(value)
            if os.path.isfile(theme):
                shutil.copy2(theme, os.path.join(target, "farben.json"))
                out[key] = TOKEN + "/farben.json"
            else:
                dropped.append(key)
            continue
        value = screens_to_all(value)
        if personal(value):
            dropped.append(key)
            continue
        out[key] = value
    out.update(SETTINGS_FORCE)
    out.update(SETTINGS_NUR_NEU)
    dynamic = out.get("currentThemeName") == "dynamic"
    save_json(os.path.join(target, "settings.json"), out)

    session = renamed_session(load_json(SESSION, {}) or {})
    kept = {k: session[k] for k in SESSION_GESTALTUNG if k in session}
    for key in MATERIAL_KEYS:
        if personal(kept.get(key)):
            kept.pop(key)
            notes.append(f"session.json: {key} verweist in den eigenen Ordner und wird nicht übernommen.")
    material = kept.get("materialWallpapers")
    if isinstance(material, dict):
        # Der Eintrag "" gilt für alle Bildschirme; die übrigen Schlüssel sind Bildschirmnamen oder -modelle
        if set(material) - {""}:
            notes.append("Material-Vorlage je Bildschirm wird nicht übernommen (Bildschirme sind beim neuen Nutzer andere).")
        if "" in material:
            kept["materialWallpapers"] = {"": material[""]}
        else:
            kept.pop("materialWallpapers")
    if not session.get("perModeWallpaper"):
        # Getrennte Bilder für Hell und Dunkel nutzt nur, wer perModeWallpaper eingeschaltet hat
        kept.pop("wallpaperPathLight", None)
        kept.pop("wallpaperPathDark", None)
    for key in WALLPAPER_KEYS:
        if kept.get(key):
            mapped = images.take(kept[key])
            if mapped:
                kept[key] = mapped
            else:
                kept.pop(key)
    if session.get("perMonitorWallpaper"):
        notes.append("Hintergrund je Bildschirm wird nicht übernommen (Bildschirme sind beim neuen Nutzer andere).")
    if not any(kept.get(k) for k in WALLPAPER_KEYS):
        notes.append("Kein Hintergrundbild im Design: der neue Nutzer behält seinen.")
        if dynamic:
            notes.append("Die Farben kommen aus dem Hintergrundbild (Theme «dynamic»). Ohne Bild sehen sie beim "
                         "neuen Nutzer anders aus – dann besser ein festes Theme wählen.")
    save_json(os.path.join(target, "session.json"), kept)

    plugins = load_json(PLUGINS, {})
    plug_out = {}
    for plugin, allowed in PLUGIN_KEEP.items():
        data = plugins.get(plugin)
        if not isinstance(data, dict):
            continue
        if allowed is None:
            plug_out[plugin] = {k: v for k, v in data.items() if not PERSONAL_PLUGIN_KEYS.search(k) and not personal(v)}
        else:
            plug_out[plugin] = {k: data[k] for k in allowed if k in data}
    save_json(os.path.join(target, "plugins.json"), plug_out)

    fonts = sorted({str(v) for k, v in out.items() if "font" in k.lower() and "family" in k.lower() and v})

    if variant == "kde":
        k = kwin()
        entries = []
        for file, group in KWIN_GROUPS:
            for key, value in k.read_kconfig(file).get(group, {}).items():
                entries.append([file, group, key, value])
        for file, group, key in KWIN_KEYS:
            value = k.read_kconfig(file).get(group, {}).get(key)
            if value is not None:
                entries.append([file, group, key, value])
        for entry in [e for e in entries if personal(e[3])]:
            entries.remove(entry)
            dropped.append("%s [%s] %s (Pfad in den eigenen Ordner)" % tuple(entry[:3]))
        rules = []
        for rule in k.rule_list():
            name = rule.get("Description", rule["id"])
            if rule.get("title"):
                # «Fenster anklicken» trägt Klasse und Titel ein. Der Titel kann Dateinamen enthalten und
                # ist beim neuen Nutzer ein anderer: mit Klasse gilt die Regel für alle Fenster des
                # Programms, ohne Klasse träfe sie ohne Titel jedes Fenster – dann weg.
                has_class = rule.get("wmclass") and rule.get("wmclassmatch", "0") not in ("", "0")
                if not has_class:
                    dropped.append("Fensterregel «%s» (prüft nur den Fenstertitel)" % name)
                    continue
                rule = {key: value for key, value in rule.items() if key not in ("title", "titlematch")}
                name = re.sub(r"\s*\(.*\)$", "", name) or name
                rule["Description"] = name
                notes.append("Fensterregel «%s»: Bedingung Fenstertitel entfernt, gilt für alle Fenster des Programms." % name)
            clean = {key: value for key, value in rule.items() if key not in ("id", "other") and not personal(value)}
            rules.append(clean)
        lock = {}
        group = k.read_kconfig("kscreenlockerrc").get(LOCK_GROUP, {})
        for key in LOCK_KEYS:
            if group.get(key):
                lock[key] = group[key]
        if lock.get("Layout"):
            layout = load_json_text(lock["Layout"])
            if layout is not None:
                cleaned, _ = scrub(lock_layout_images(layout, images), images, "Sperrbildschirm", dropped)
                lock["Layout"] = json.dumps(cleaned, ensure_ascii=False, separators=(",", ":"))
                fonts += [w.get("font", {}).get("family") for w in layout.get("widgets", []) if isinstance(w.get("font"), dict)]
            else:
                lock.pop("Layout")
        save_json(os.path.join(target, "kwin.json"), {"einstellungen": entries, "regeln": rules, "sperrbildschirm": lock})
        own_conf = os.path.join(CONFIG, "alpe", "hyprlock.conf")
        if not lock.get("Layout") and os.path.isfile(own_conf):
            with open(own_conf, encoding="utf-8", errors="replace") as handle:
                text = handle.read()
            with open(os.path.join(target, "hyprlock.conf"), "w", encoding="utf-8") as handle:
                handle.write(hyprlock_images(text, images))
            fonts += re.findall(r"font_family\s*=\s*(.+)", text)
        elif not lock.get("Layout"):
            notes.append("Sperrbildschirm: kein eigenes Layout gestaltet – es gilt die neutrale Vorlage lockscreen/hyprlock.conf.")
    else:
        if os.path.isfile(HYPRLOCK):
            with open(HYPRLOCK, encoding="utf-8", errors="replace") as handle:
                text = handle.read()
            with open(os.path.join(target, "hyprlock.conf"), "w", encoding="utf-8") as handle:
                handle.write(hyprlock_images(text, images))
            fonts += re.findall(r"font_family\s*=\s*(.+)", text)

    programme = export_programme(os.path.join(target, "programme"), notes, dropped)

    manifest = {
        "variante": variant,
        "alpe": alpe_version(),
        "exportiert": datetime.date.today().isoformat(),
        "schriften": sorted({f.strip() for f in fonts if f and f.strip()}),
        "bilder": images.taken,
        "programme": programme,
        "hinweise": notes,
    }
    save_json(os.path.join(target, "manifest.json"), manifest)

    say("Design «%s» liegt in %s" % (variant, target.replace(HOME, "~")))
    say("   Einstellungen: %d übernommen, %d weggelassen (persönlich oder gerätegebunden)" % (len(out), len(dropped)))
    for item in dropped:
        say("      weggelassen: %s" % item)
    for name, files in programme.items():
        say("   %s: %d Datei(en) übernommen" % (name, len(files)))
    for name in images.taken:
        say("   Bild übernommen: bilder/%s" % name)
    for path, why in images.left:
        say("   Bild nicht übernommen (%s): %s" % (why, path.replace(HOME, "~")))
    for note in notes:
        say("   Hinweis: %s" % note)
    if manifest["schriften"]:
        say("   Schriften: %s – fehlen sie beim neuen Nutzer, nimmt die Shell Ersatz." % ", ".join(manifest["schriften"]))
    leak = [p for p in glob.glob(os.path.join(target, "*.json")) + glob.glob(os.path.join(target, "*.conf"))
            + glob.glob(os.path.join(target, "programme", "**", "*"), recursive=True)
            if os.path.isfile(p) and HOME in open(p, encoding="utf-8", errors="replace").read()]
    if leak:
        say("   ACHTUNG: noch ein Pfad in den eigenen Ordner in: %s – bitte melden." % ", ".join(os.path.basename(p) for p in leak))
        return 1
    say("Prüfen mit «git -C ~/alpe status» und «git -C ~/alpe diff», dann committen.")
    return 0


def export_programme(target, notes, dropped):
    """kitty und fastfetch: Textdateien aus ~/.config/<programm>, Pfade in den eigenen Ordner als ~,
    Zeilen mit Passwörtern oder Schlüsseln weg. Gibt {programm: [Dateien]} zurück."""
    taken = {}
    for name in PROGRAMME:
        folder = os.path.join(CONFIG, name)
        if not os.path.isdir(folder):
            continue
        files = []
        for root, dirs, names in os.walk(folder):
            dirs[:] = sorted(d for d in dirs if not d.startswith("."))
            for file in sorted(names):
                path = os.path.join(root, file)
                rel = os.path.relpath(path, folder)
                if (file.startswith(".") or file in PROGRAMM_SKIP or not file.endswith(PROGRAMM_EXT)
                        or ".vor-alpe" in file or os.path.getsize(path) > 512 * 1024):
                    continue
                with open(path, encoding="utf-8", errors="replace") as handle:
                    lines = handle.read().splitlines(keepends=True)
                kept = []
                for line in lines:
                    if SECRET.search(line) and not line.lstrip().startswith(("#", "//")):
                        dropped.append("%s/%s: Zeile mit Passwort oder Schlüssel" % (name, rel))
                        continue
                    kept.append(line.replace(HOME, "~"))
                out = os.path.join(target, name, rel)
                os.makedirs(os.path.dirname(out), exist_ok=True)
                with open(out, "w", encoding="utf-8") as handle:
                    handle.write("".join(kept))
                files.append(rel)
        if files:
            taken[name] = files
    if not taken:
        notes.append("Keine Einstellungen von kitty oder fastfetch gefunden.")
    return taken


def apply_programme(source, saved_root):
    """Dateien aus design/<variante>/programme nach ~/.config; bisherige Ordner vorher gesichert."""
    done = []
    folder = os.path.join(source, "programme")
    if not os.path.isdir(folder):
        return done
    for name in sorted(os.listdir(folder)):
        if name not in PROGRAMME:
            continue
        dest = os.path.join(CONFIG, name)
        if os.path.isdir(dest) and os.listdir(dest):
            shutil.copytree(dest, os.path.join(saved_root, "programme", name), dirs_exist_ok=True)
        shutil.copytree(os.path.join(folder, name), dest, dirs_exist_ok=True)
        done.append(name)
    return done


def load_json_text(text):
    try:
        return json.loads(text)
    except ValueError:
        return None


def alpe_version():
    brand = os.path.join(SHELL_DIR, "Common", "Brand.qml")
    try:
        m = re.search(r'version:\s*"([^"]+)"', open(brand, encoding="utf-8").read())
        return m.group(1) if m else ""
    except OSError:
        return ""


# ---------------------------------------------------------------- Einspielen

def backup_folder():
    return os.path.join(CONFIG, "alpe", "design-sicherung", datetime.datetime.now().strftime("%Y%m%d-%H%M%S"))


def backup(paths, folder=None):
    folder = folder or backup_folder()
    saved = 0
    for path in paths:
        if os.path.isfile(path):
            os.makedirs(folder, exist_ok=True)
            shutil.copy2(path, os.path.join(folder, os.path.basename(path)))
            saved += 1
    return folder if saved else None


def available():
    return [v for v in ("kde", "hyprland") if os.path.isfile(os.path.join(DESIGN_ROOT, v, "manifest.json"))]


def service(action):
    """dms.service anhalten bzw. wieder starten, damit die Shell die neuen Dateien nicht mit ihrem
    Stand im Speicher überschreibt. Unter Hyprland ohne Dienst: nach dem Schreiben neu starten."""
    if os.environ.get("ALPE_DESIGN_NO_SERVICE") or not shutil.which("systemctl"):
        return False
    if action == "stop":
        active = subprocess.run(["systemctl", "--user", "is-active", "--quiet", "dms.service"], check=False).returncode == 0
        if active:
            subprocess.run(["systemctl", "--user", "stop", "dms.service"], check=False)
        return active
    subprocess.run(["systemctl", "--user", "start", "dms.service"], check=False)
    return True


def apply(variant):
    choices = available()
    if not choices:
        say("Im Repository liegt noch kein Design (design/kde oder design/hyprland). Nichts zu tun.")
        return 0
    if variant not in choices:
        say("Kein Design für «%s», nehme «%s»." % (variant, choices[0]))
        variant = choices[0]
    source = os.path.join(DESIGN_ROOT, variant)
    base = INSTALLED
    stopped = service("stop")
    try:
        result = write_design(variant, source, base)
    finally:
        if stopped:
            service("start")
    if variant == "kde" and not os.environ.get("ALPE_DESIGN_NO_SERVICE") and shutil.which("busctl"):
        # Vorgaben von Alpe: Meta+Q schliesst, Meta+M Systemmonitor (tools/kuerzel.py)
        subprocess.run([sys.executable, os.path.join(ALPE_DIR, "tools", "kuerzel.py"), "vorgaben", "--warten", "20"], check=False)
    return result


def write_design(variant, source, base):
    kde_files = [os.path.join(CONFIG, f) for f in ("kwinrc", "kwinrulesrc", "kdeglobals", "kscreenlockerrc")]
    folder = backup_folder()
    saved = backup([SETTINGS, SESSION, PLUGINS, HYPRLOCK] + (kde_files if variant == "kde" else []), folder)
    programme = apply_programme(source, folder)
    if programme and not saved and os.path.isdir(folder):
        saved = folder
    for name in programme:
        say("   %s: Einstellungen eingespielt" % name)
    if "fastfetch" in programme:
        subprocess.run([sys.executable, os.path.join(ALPE_DIR, "tools", "fastfetch.py")], check=False)

    if os.path.isdir(os.path.join(source, "bilder")) or os.path.isfile(os.path.join(source, "farben.json")):
        os.makedirs(base, exist_ok=True)
        if os.path.isdir(os.path.join(source, "bilder")):
            shutil.copytree(os.path.join(source, "bilder"), os.path.join(base, "bilder"), dirs_exist_ok=True)
        if os.path.isfile(os.path.join(source, "farben.json")):
            shutil.copy2(os.path.join(source, "farben.json"), os.path.join(base, "farben.json"))

    settings = renamed(load_json(SETTINGS, {}) or {})
    incoming = renamed(fill(load_json(os.path.join(source, "settings.json"), {}), base))
    # Vorgaben wie «Wetter nach Standort» nur für den, der selbst noch nichts eingestellt hat
    for key in SETTINGS_FORCE:
        if key in settings:
            incoming.pop(key, None)
    # matugen-Vorlagen fremder Programme: nur bei einer frischen Installation (SETTINGS_NUR_NEU)
    if settings:
        for key in SETTINGS_NUR_NEU:
            incoming.pop(key, None)
    settings.update(incoming)
    save_json(SETTINGS, settings)

    session = renamed_session(load_json(SESSION, {}) or {})
    design_session = renamed_session(fill(load_json(os.path.join(source, "session.json"), {}), base))
    # Wie beim Export gilt nur die Gestaltung (Plan 0.8 Nr. 83): Zustand in einem Design – etwa Anheftungen
    # aus einem älteren Export – überschriebe sonst den des Nutzers.
    state = sorted(key for key in design_session if key not in SESSION_GESTALTUNG)
    if state:
        say("   Session: nicht übernommen, weil Zustand und nicht Gestaltung: " + ", ".join(state))
    design_session = {key: value for key, value in design_session.items() if key in SESSION_GESTALTUNG}
    # Eigene Formen des Nutzers bleiben neben denen des Designs bestehen (bei gleicher Kennung gewinnt das Design)
    own_profiles = session.get("materialWallpaperProfiles")
    if isinstance(own_profiles, dict) and isinstance(design_session.get("materialWallpaperProfiles"), dict):
        design_session["materialWallpaperProfiles"] = {**own_profiles, **design_session["materialWallpaperProfiles"]}
    session.update(design_session)
    save_json(SESSION, session)

    plugins = load_json(PLUGINS, {}) or {}
    for plugin, values in load_json(os.path.join(source, "plugins.json"), {}).items():
        merged = dict(plugins.get(plugin) or {})
        merged.update(values)
        plugins[plugin] = merged
    save_json(PLUGINS, plugins)

    if variant == "kde" and os.path.isfile(os.path.join(source, "kwin.json")):
        k = kwin()
        data = fill(load_json(os.path.join(source, "kwin.json"), {}), base)
        for file, group, key, value in data.get("einstellungen", []):
            if file in ("kwinrc", "kdeglobals"):
                k.kwrite(file, group, key, value)
        present = {r.get("Description") for r in k.rule_list()}
        added = 0
        for rule in data.get("regeln", []):
            if rule.get("Description") in present:
                continue
            k.rule_set({"id": None, "values": rule})
            added += 1
        for key, value in (data.get("sperrbildschirm") or {}).items():
            k.kwrite("kscreenlockerrc", LOCK_GROUP, key, value)
        if "kitty" in programme and shutil.which("kitty"):
            # Standard-Terminal von KDE (Dolphin «Terminal hier öffnen», Kürzel Ctrl+Alt+T)
            k.kwrite("kdeglobals", "General", "TerminalApplication", "kitty")
            k.kwrite("kdeglobals", "General", "TerminalService", "kitty.desktop")
            say("   Standard-Terminal: kitty")
        k.reconfigure()
        say("   KWin: Effekte und %d Fensterregel(n) eingetragen" % added)
        conf = os.path.join(source, "hyprlock.conf")
        if os.path.isfile(conf) and shutil.which(k.KWRITE):
            os.makedirs(base, exist_ok=True)
            with open(conf, encoding="utf-8") as handle:
                text = handle.read().replace(TOKEN, base)
            with open(os.path.join(base, "hyprlock.conf"), "w", encoding="utf-8") as handle:
                handle.write(text)
            subprocess.run(["bash", os.path.join(ALPE_DIR, "tools", "lockscreen.sh"), "hyprlock", os.path.join(base, "hyprlock.conf")], check=False)
        if (data.get("sperrbildschirm") or {}).get("Layout") or os.path.isfile(conf):
            say("   Sperrbildschirm gestaltet")
    if variant == "hyprland" and os.path.isfile(os.path.join(source, "hyprlock.conf")):
        with open(os.path.join(source, "hyprlock.conf"), encoding="utf-8") as handle:
            text = handle.read().replace(TOKEN, base)
        os.makedirs(os.path.dirname(HYPRLOCK), exist_ok=True)
        with open(HYPRLOCK, "w", encoding="utf-8") as handle:
            handle.write(text)
        say("   hyprlock.conf geschrieben")

    os.makedirs(os.path.dirname(MARK), exist_ok=True)
    manifest = load_json(os.path.join(source, "manifest.json"), {})
    with open(MARK, "w", encoding="utf-8") as handle:
        handle.write("%s %s %s\n" % (variant, manifest.get("exportiert", ""), datetime.datetime.now().isoformat(timespec="seconds")))
    say("Design «%s» eingespielt (Stand %s)." % (variant, manifest.get("exportiert", "?")))
    if saved:
        say("   Bisherige Dateien gesichert in %s" % saved.replace(HOME, "~"))
    missing = [f for f in manifest.get("schriften", []) if not font_installed(f) and not bundled_font(f)]
    if missing:
        say("   Schriften fehlen (die Shell nimmt Ersatz): %s" % ", ".join(missing))
    return 0


def bundled_font(family):
    """Schriften des Sperrbildschirms liefert Alpe selbst mit (Modules/Lock/Alpe/fonts)."""
    folder = os.path.join(SHELL_DIR, "Modules", "Lock", "Alpe", "fonts")
    key = re.sub(r"[^a-z]", "", family.lower()).replace("nerdfont", "").replace("mono", "", 1)
    return any(key and key in re.sub(r"[^a-z]", "", f.lower()) for f in os.listdir(folder)) if os.path.isdir(folder) else False


def font_installed(family):
    if not shutil.which("fc-list"):
        return True
    out = subprocess.run(["fc-list", ":family"], capture_output=True, text=True, check=False).stdout
    return family.lower() in out.lower()


def status():
    found = available()
    if not found:
        say("Im Repository liegt kein Design. Aufnehmen: alpe design export")
    for variant in found:
        m = load_json(os.path.join(DESIGN_ROOT, variant, "manifest.json"), {})
        say("design/%s: Stand %s (Alpe %s), %d Bild(er)" % (variant, m.get("exportiert", "?"), m.get("alpe", "?"), len(m.get("bilder", []))))
    if os.path.isfile(MARK):
        say("Eingespielt: %s" % open(MARK, encoding="utf-8").read().strip())
    else:
        say("Auf diesem Rechner noch nicht eingespielt.")
    return 0


def main(argv):
    args = argv[1:]
    cmd = args[0] if args else "status"

    def option(name, default):
        if name in args:
            i = args.index(name)
            if i + 1 < len(args):
                return args[i + 1]
        return default

    variant = option("--variante", session_variant())
    if variant not in ("kde", "hyprland"):
        sys.exit("--variante kde oder hyprland")
    if cmd == "export":
        mode = option("--bilder", "fragen" if sys.stdin.isatty() else "nein")
        if mode not in ("fragen", "ja", "nein"):
            sys.exit("--bilder fragen, ja oder nein")
        return export(variant, mode)
    if cmd == "apply":
        if "--ja" not in args and sys.stdin.isatty():
            answer = input("Design einspielen? Leiste, Dock, Dash, Farben und Sperrbildschirm werden ersetzt (mit Sicherung). [j/N] ")
            if answer.strip().lower() not in ("j", "ja", "y", "yes"):
                say("Nichts verändert.")
                return 0
        return apply(variant)
    if cmd == "status":
        return status()
    say(__doc__.strip())
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
