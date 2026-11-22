#!/usr/bin/env python3
"""Prüft tools/design.py: Export lässt Persönliches weg, Einspielen ergibt dasselbe Aussehen.

    python3 tests/test_design.py        nimmt shell/ im Repository (oder ALPE_SHELL_DIR) für alpe-kwin.py
"""
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
TOOL = os.path.join(os.path.dirname(HERE), "tools", "design.py")
STUB = os.path.join(HERE, "data", "kwinstub")
SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "shell")
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    if not cond:
        failures += 1


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text if isinstance(text, str) else json.dumps(text))


def home(name):
    h = os.path.join(tmp, name)
    os.makedirs(h)
    return h


def run(h, *args, stdin=""):
    env = dict(os.environ, HOME=h, XDG_CONFIG_HOME=os.path.join(h, ".config"), XDG_STATE_HOME=os.path.join(h, ".local", "state"),
               XDG_DATA_HOME=os.path.join(h, ".local", "share"), XDG_DATA_DIRS=os.path.join(h, "sys"),
               ALPE_SHELL_DIR=SHELL, ALPE_DESIGN_DIR=design, ALPE_KWRITECONFIG=os.path.join(STUB, "kwriteconfig6"),
               ALPE_BUSCTL=os.path.join(STUB, "busctl"), ALPE_KWIN_VERSION="6.8.3", XDG_CURRENT_DESKTOP="KDE", ALPE_DESIGN_NO_SERVICE="1")
    return subprocess.run([sys.executable, TOOL] + list(args), env=env, input=stdin, capture_output=True, text=True)


tmp = tempfile.mkdtemp()
design = os.path.join(tmp, "repo-design")

# ---------------------------------------------------------------- Rechner des Autors
a = home("autor")
pics = os.path.join(a, "Bilder")
write(os.path.join(pics, "berg.jpg"), "JPEG")             # eigenes Foto
write(os.path.join(pics, "fremd.png"), "PNG")              # fremdes Foto
write(os.path.join(a, ".config", "alpe", "farben.json"), {"primary": "#ffffff"})
write(os.path.join(a, ".config", "alpe", "settings.json"), {
    "configVersion": 7,
    "currentThemeName": "custom",
    "customThemeFile": os.path.join(a, ".config", "alpe", "farben.json"),
    "fontFamily": "Inter Variable",
    "cornerRadius": 18,
    "barConfigs": [{"id": "default", "position": 0, "screenPreferences": ["DP-2"],
                    "leftWidgets": ["launcherButton", {"id": "gpuTemp", "enabled": True, "selectedGpuIndex": 0, "pciId": "1234:abcd"}]}],
    "dockConfigs": [{"id": "dock", "screenPreferences": [{"name": "DP-2"}]}],
    "dashTabs": ["overview", "weather", "plugin_alpeRadar", "plugin_alpeSport"],
    "screenPreferences": {"notifications": ["DP-2"]},
    "updaterCustomCommand": "update-all",
    "updaterUseCustomCommand": True,
    "useAutoLocation": False,
    "lockScreenVideoPath": os.path.join(a, "Videos", "berge.mp4"),
    "launcherLogoCustomPath": os.path.join(a, "Bilder", "logo.svg"),
})
write(os.path.join(a, ".local", "state", "alpe", "session.json"), {
    "isLightMode": False,
    "wallpaperPath": os.path.join(pics, "berg.jpg"),
    "wallpaperPathLight": os.path.join(pics, "alt-hell.png"),
    "perModeWallpaper": False,
    "weatherLocation": "Brunnen",
    "weatherCoordinates": "46.99,8.60",
    "latitude": 46.99,
    "deviceMaxVolumes": {"HyperX": 100},
    "vpnLastConnected": "ProtonVPN CH",
    "launcherQueryHistory": ["kontoauszug"],
    "dockPins": {"dock": ["kitty", "org.kde.dolphin", "gibtsnicht"]},
    "nightModeEnabled": True,
})
write(os.path.join(a, ".config", "alpe", "plugin_settings.json"), {
    "alpeSport": {"favorites": ["hockey:101144"], "favoriteNames": {"hockey:101144": {"name": "EV Zug"}},
                  "streams": {"nl": {"name": "MySports", "url": "https://x"}}, "order": ["nl", "nba"], "growDetail": True, "notifyGoals": False},
    "alpeMeteoSwiss": {"pointName": "Brunnen", "units": "metric", "showRain": True},
    "fremdesPlugin": {"x": 1},
})
cfg = os.path.join(a, ".config")
write(os.path.join(cfg, "kwinrc"), "[Plugins]\nbetter_blur_dxEnabled=true\nkwin4_effect_shapecornersEnabled=true\n\n[Round-Corners]\nSize=14\n\n"
      "[Effect-better-blur-dx]\nBlurStrength=9\nWindowClasses=dev.zed.Zed\\nwingdrive\n\n[Windows]\nPlacement=Centered\n")
write(os.path.join(cfg, "kdeglobals"), "[KDE]\nAnimationDurationFactor=0.5\n")
write(os.path.join(cfg, "kwinrulesrc"), "[General]\nOrder=titel,zed,brief,wing\n\n[titel]\nDescription=Alpe: ohne Titelleiste\ndecorationpolicy=none\ndecorationpolicyrule=2\ntypes=33\n\n"
      "[zed]\nDescription=Zed\nwmclass=dev.zed.Zed\nwmclassmatch=1\nopacityactive=86\nopacityactiverule=2\n\n"
      "[brief]\nDescription=Bewerbung\ntitle=Bewerbung_Meier.docx\ntitlematch=1\nabove=true\naboverule=2\n\n"
      "[wing]\nDescription=WingDrive (WingDrive)\nwmclass=wingdrive\nwmclassmatch=1\ntitle=WingDrive\ntitlematch=1\nopacityactive=90\nopacityactiverule=2\n")
layout = {"background": {"source": "image", "image": os.path.join(pics, "berg.jpg"), "path": os.path.join(pics, "berg.jpg"),
                         "fallback": os.path.join(a, ".cache", "alpe", "lock-standbild.jpg")},
          "reference": {"profile": os.path.join(a, ".config", "alpe", "lockprofil")},
          "widgets": [{"type": "image", "path": os.path.join(pics, "fremd.png")}, {"type": "image", "path": os.path.join(pics, "berg.jpg")},
                      {"type": "label", "text": "{date:%H}", "font": {"family": "AlfaSlabOne"}}]}
write(os.path.join(cfg, "kscreenlockerrc"), "[Greeter][LnF][General]\nStyle=hyprlock\nLayout=" + json.dumps(layout) + "\n")

# Antworten: berg.jpg ja, fremd.png nein (in dieser Reihenfolge gefragt: Hintergrund zuerst)
out = run(a, "export", "--bilder", "fragen", stdin="j\nn\n")
check(out.returncode == 0, "Export läuft durch\n" + out.stdout + out.stderr)
d = os.path.join(design, "kde")
s = json.load(open(os.path.join(d, "settings.json")))
check(s["fontFamily"] == "Inter Variable" and s["cornerRadius"] == 18 and s["dashTabs"][-1] == "plugin_alpeSport", "Aussehen übernommen (Schrift, Ecken, Dash-Tabs)")
check(s["barConfigs"][0]["screenPreferences"] == ["all"] and s["dockConfigs"][0]["screenPreferences"] == ["all"], "Leiste und Dock auf allen Bildschirmen statt DP-2")
check("screenPreferences" not in s and "updaterCustomCommand" not in s and "updaterUseCustomCommand" not in s, "Bildschirm-Zuordnung und eigener Aktualisierungsbefehl weg")
check(s["useAutoLocation"] is True, "Wetter folgt beim neuen Nutzer dem Standort")
check("lockScreenVideoPath" not in s and "launcherLogoCustomPath" not in s, "Pfade in den eigenen Ordner weggelassen")
check(s["barConfigs"][0]["leftWidgets"] == ["launcherButton", {"id": "gpuTemp", "enabled": True, "selectedGpuIndex": 0}],
      "Kennung der Grafikkarte (pciId) im Widget gpuTemp weggelassen, das Widget bleibt")
check(s["customThemeFile"] == "@DESIGN@/farben.json" and os.path.isfile(os.path.join(d, "farben.json")), "eigenes Farbschema kommt mit")
se = json.load(open(os.path.join(d, "session.json")))
check(se["wallpaperPath"] == "@DESIGN@/bilder/berg.jpg" and os.path.isfile(os.path.join(d, "bilder", "berg.jpg")), "bestätigtes eigenes Hintergrundbild kommt mit")
check(not {"weatherLocation", "weatherCoordinates", "latitude", "deviceMaxVolumes", "vpnLastConnected", "launcherQueryHistory"} & set(se), "Wetterort, Geräte, VPN, Suchverlauf weg")
p = json.load(open(os.path.join(d, "plugins.json")))
check(p["alpeSport"] == {"order": ["nl", "nba"], "growDetail": True, "notifyGoals": False}, "Sport: Reihenfolge und Schalter, keine Favoriten und Streams")
check(p["alpeMeteoSwiss"] == {"units": "metric", "showRain": True} and "fremdesPlugin" not in p, "MeteoSchweiz ohne Ort; fremde Plugins nicht")
k = json.load(open(os.path.join(d, "kwin.json")))
keys = {(e[0], e[1], e[2]) for e in k["einstellungen"]}
check(("kwinrc", "Round-Corners", "Size") in keys and ("kdeglobals", "KDE", "AnimationDurationFactor") in keys and ("kwinrc", "Windows", "Placement") not in keys, "KWin: Ecken, Unschärfe, Animation – nicht das Verhalten")
check([r["Description"] for r in k["regeln"]] == ["Alpe: ohne Titelleiste", "Zed", "WingDrive"], "Fensterregeln: nur-Titel-Regel weg, «Fenster anklicken»-Regel ohne Titel behalten " + str([r["Description"] for r in k["regeln"]]))
wing = [r for r in k["regeln"] if r["Description"] == "WingDrive"][0]
check("title" not in wing and wing["wmclass"] == "wingdrive" and wing["opacityactive"] == "90", "WingDrive: Klasse und Deckkraft bleiben, Titel weg")
check("wallpaperPathLight" not in se and not os.path.exists(os.path.join(d, "bilder", "alt-hell.png")), "ungenutztes Hell-Bild nicht gefragt und nicht übernommen")
lay = json.loads(k["sperrbildschirm"]["Layout"])
check("fallback" not in lay["background"] and "profile" not in lay.get("reference", {}), "Sperrbildschirm: unbekannte Felder mit Pfad entfernt")
check([w.get("path") for w in lay["widgets"] if w["type"] == "image"] == ["@DESIGN@/bilder/berg.jpg"], "Sperrbildschirm: fremdes Bild entfernt, eigenes umgeschrieben")
check(lay["background"]["image"] == "@DESIGN@/bilder/berg.jpg" and not os.path.exists(os.path.join(d, "bilder", "fremd.png")), "fremdes Foto nicht im Repository")
everything = "".join(open(os.path.join(d, f)).read() for f in os.listdir(d) if f.endswith(".json"))
check(a not in everything and "Brunnen" not in everything and "EV Zug" not in everything and "Bewerbung" not in everything, "kein Pfad, Ort, Favorit oder Dateiname im Design")
m = json.load(open(os.path.join(d, "manifest.json")))
check("AlfaSlabOne" in m["schriften"] and "Inter Variable" in m["schriften"] and m["bilder"] == ["berg.jpg"], "Manifest: Schriften und Bilder")

# ---------------------------------------------------------------- neuer Nutzer
b = home("neu")
for app in ("kitty.desktop", "org.kde.dolphin.desktop"):
    write(os.path.join(b, "sys", "applications", app), "[Desktop Entry]\nName=x\nExec=x\n")
write(os.path.join(b, ".config", "alpe", "settings.json"), {"fontFamily": "Noto Sans", "eigenerSchluessel": 1, "useAutoLocation": False,
                                                         "dankLauncherV2ShowFooter": False, "alpeLockStyle": "dms",
                                                         "matugenSpec": "dms", "eigeneListe": ["dms_power", "dms_powerx"],
                                                         "eigeneWidgets": [{"id": "launcherButton", "launcherLogoMode": "dank"}]})
write(os.path.join(b, ".local", "state", "alpe", "session.json"), {"weatherLocation": "Bern", "materialWallpapers": {"": {"shared": {"preset": "dank", "seed": "#d0bcff"}}},
                                                                 "materialWallpaperProfiles": {"eigen": {"name": "dank", "layers": [{"shape": "dankLogo"}]}}})
write(os.path.join(b, ".config", "kwinrulesrc"), "[General]\nOrder=eigen\n\n[eigen]\nDescription=Firefox\nwmclass=firefox\n")
out = run(b, "apply", "--ja")
check(out.returncode == 0 and "eingespielt" in out.stdout, "Einspielen läuft durch\n" + out.stdout + out.stderr)
base = os.path.join(b, ".local", "share", "alpe", "design")
s2 = json.load(open(os.path.join(b, ".config", "alpe", "settings.json")))
check(s2["fontFamily"] == "Inter Variable" and s2["eigenerSchluessel"] == 1, "Design gewinnt, eigene andere Einstellungen bleiben")
check(s2.get("launcherShowFooter") is False and "dankLauncherV2ShowFooter" not in s2 and s2.get("alpeLockStyle") == "standard", "Schlüssel und Werte aus 1.0 unter den neuen Namen")
check(s2["customThemeFile"] == os.path.join(base, "farben.json") and os.path.isfile(s2["customThemeFile"]), "Farbschema an Ort und Stelle")
check(s2["matugenSpec"] == "alpe" and s2["eigeneListe"] == ["alpe_power", "dms_powerx"] and s2["eigeneWidgets"][0]["launcherLogoMode"] == "alpe",
      "Kennungen der Version 44: matugen-Spec, Starter-Einträge, Logo-Modus")
check(not any(key.startswith("dms_") for key in s2.get("builtInPluginSettings", {})), "Starter-Einträge des Designs heissen alpe_*")
se2 = json.load(open(os.path.join(b, ".local", "state", "alpe", "session.json")))
check(se2["materialWallpapers"][""]["shared"]["preset"] == "alpe" and se2["materialWallpaperProfiles"]["eigen"] == {"name": "dank", "layers": [{"shape": "alpeLogo"}]},
      "Session: Material-Vorlage «Alpe» und Form alpeLogo, eigene Namen bleiben")
check(se2["wallpaperPath"] == os.path.join(base, "bilder", "berg.jpg") and os.path.isfile(se2["wallpaperPath"]), "Hintergrund eingespielt")
check(se2["weatherLocation"] == "Bern" and s2["useAutoLocation"] is False, "eigener Wetterort bleibt (kein Umschalten auf Standort)")
c = home("leer")
run(c, "apply", "--ja")
check(json.load(open(os.path.join(c, ".config", "alpe", "settings.json")))["useAutoLocation"] is True, "frischer Nutzer: Wetter nach Standort")
check(se2["dockPins"] == {"dock": ["kitty", "org.kde.dolphin"]}, "Dock: nur installierte Programme angeheftet")
rules = open(os.path.join(b, ".config", "kwinrulesrc")).read()
check("Description=Firefox" in rules and "Description=Zed" in rules and "Description=Alpe: ohne Titelleiste" in rules and "rules=" not in rules, "Fensterregeln dazu, eigene bleiben, Format KWin 6.8")
lock = open(os.path.join(b, ".config", "kscreenlockerrc")).read()
check(base + "/bilder/berg.jpg" in lock and "@DESIGN@" not in lock, "Sperrbildschirm mit dem eingespielten Bild")
check(os.path.isdir(os.path.join(b, ".config", "alpe", "design-sicherung")), "bisherige Dateien gesichert")
out = run(b, "apply", "--ja")
check(open(os.path.join(b, ".config", "kwinrulesrc")).read().count("Description=Zed") == 1, "zweites Einspielen legt Regeln nicht doppelt an")
check("Eingespielt: kde" in run(b, "status").stdout, "status nennt das eingespielte Design")

# ---------------------------------------------------------------- KDE ohne gestaltetes Layout, mit eigener Vorlage
e = home("autor2")
write(os.path.join(e, "Bilder", "logo.png"), "PNG")
write(os.path.join(e, "Bilder", "fremd.png"), "PNG")
write(os.path.join(e, ".config", "alpe", "settings.json"), {"fontFamily": "Inter"})
write(os.path.join(e, ".config", "alpe", "hyprlock.conf"),
      "background {\n    path = %s/Bilder/fremd.png\n    blur_passes = 3\n}\n\nimage {\n    path = %s/Bilder/logo.png\n    size = 300\n}\n\n"
      "image {\n    path = %s/Bilder/fremd.png\n    size = 200\n}\n\nlabel {\n    text = $TIME\n    font_family = AlfaSlabOne\n}\n" % (e, e, e))
out = run(e, "export", "--bilder", "fragen", stdin="n\nj\n")
conf = open(os.path.join(design, "kde", "hyprlock.conf")).read()
check("@DESIGN@/bilder/logo.png" in conf and "fremd" not in conf and conf.count("image {") == 1 and "blur_passes = 3" in conf and "label {" in conf,
      "eigene hyprlock-Vorlage: fremdes Bild samt Block weg, Hintergrund ohne Bild bleibt, eigenes umgeschrieben\n" + conf)

# ---------------------------------------------------------------- kitty und fastfetch
f = home("autor3")
write(os.path.join(f, ".config", "alpe", "settings.json"), {"fontFamily": "Inter"})
write(os.path.join(f, ".config", "kitty", "kitty.conf"),
      "font_family JetBrains Mono\ninclude themes/alpe.conf\nbackground_image %s/Bilder/x.png\nremote_control_password geheim\n# password-Kommentar bleibt\n" % f)
write(os.path.join(f, ".config", "kitty", "themes", "alpe.conf"), "background #13212C\n")
write(os.path.join(f, ".config", "kitty", "kitty.conf.vor-alpe"), "alt\n")
write(os.path.join(f, ".config", "fastfetch", "config.jsonc"),
      json.dumps({"logo": {"type": "file", "source": f + "/.config/fastfetch/alpe-logo.txt"}, "modules": ["title", "separator", "kernel"]}))
write(os.path.join(f, ".config", "fastfetch", "alpe-logo.txt"), "LOGO")
out = run(f, "export", "--bilder", "nein")
pk = os.path.join(design, "kde", "programme")
kconf = open(os.path.join(pk, "kitty", "kitty.conf")).read()
check(os.path.isfile(os.path.join(pk, "kitty", "themes", "alpe.conf")) and "~/Bilder/x.png" in kconf and "geheim" not in kconf
      and "password-Kommentar" in kconf and not os.path.exists(os.path.join(pk, "kitty", "kitty.conf.vor-alpe"))
      and not os.path.exists(os.path.join(pk, "fastfetch", "alpe-logo.txt")) and f not in open(os.path.join(pk, "fastfetch", "config.jsonc")).read(),
      "kitty und fastfetch exportiert: Pfade als ~, Passwortzeile und Sicherungen weg\n" + out.stdout)
g = home("neu3")
write(os.path.join(g, ".config", "kitty", "kitty.conf"), "font_size 9\n")
out = run(g, "apply", "--ja")
ff = open(os.path.join(g, ".config", "fastfetch", "config.jsonc")).read()
saved = [d for d in os.listdir(os.path.join(g, ".config", "alpe", "design-sicherung"))]
check("JetBrains Mono" in open(os.path.join(g, ".config", "kitty", "kitty.conf")).read()
      and os.path.isfile(os.path.join(g, ".config", "kitty", "themes", "alpe.conf"))
      and any(os.path.isfile(os.path.join(g, ".config", "alpe", "design-sicherung", d, "programme", "kitty", "kitty.conf")) for d in saved)
      and os.path.join(g, ".config", "fastfetch", "alpe-logo.txt") in ff and "alpe version --short" in ff,
      "kitty und fastfetch eingespielt, bisherige kitty.conf gesichert, fastfetch mit Logo und Version\n" + out.stdout + out.stderr)

# ---------------------------------------------------------------- Tabellen der Version 44
# design.py und die Migration der Shell (Namen44.js) führen dieselben Paare alt → neu.
import importlib.util
import re
spec = importlib.util.spec_from_file_location("alpe_design", TOOL)
werkzeug = importlib.util.module_from_spec(spec)
spec.loader.exec_module(werkzeug)
quelle = open(os.path.join(SHELL, "Common", "settings", "Namen44.js"), encoding="utf-8").read()
paare_shell = set(re.findall(r'"(\w+)": "(\w+)"', quelle))
paare_werkzeug = set(werkzeug.STARTER_IDS.items()) | {("dms", "alpe")} | set(werkzeug.PAGE_IDS.items())
for tabelle in (werkzeug.VALUES_BY_KEY, werkzeug.MATERIAL_VALUES):
    for werte in tabelle.values():
        paare_werkzeug |= set(werte.items())
check(paare_shell == paare_werkzeug and len(paare_shell) == 18, "design.py und Namen44.js führen dieselben Kennungen\n%s" % sorted(paare_shell ^ paare_werkzeug))
check(werkzeug.RENAMED_VALUES["matugenSpec"] == {"dms": "alpe"} and all(key in quelle for key in list(werkzeug.VALUES_BY_KEY) + list(werkzeug.PAGE_LIST_KEYS) + list(werkzeug.MATERIAL_KEYS) + list(werkzeug.MATERIAL_VALUES)),
      "dieselben Schlüssel in beiden Tabellen")

seiten = werkzeug.renamed({"settingsHiddenPages": ["auto", "dank_dash", "dankbar_dot", "dash", "printers"], "anderes": ["dank_dash"]})
check(seiten == {"settingsHiddenPages": ["auto", "dash", "bar_dot", "printers"], "anderes": ["dank_dash"]},
      "ausgeblendete Seiten tragen die neuen Seiten-IDs, ohne Doppel; andere Listen bleiben\n%s" % seiten)

print("\nalle Prüfungen bestanden" if failures == 0 else f"\n{failures} FEHLER")
sys.exit(1 if failures else 0)
