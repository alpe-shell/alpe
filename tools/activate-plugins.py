#!/usr/bin/env python3
"""Schaltet die Alpe-Plugins ein und setzt MeteoSchweiz an die erste Stelle der Wetteranbieter.
Setzt das Element «Sport» (Live-Spiel der Favoriten) einmal rechts in die Leiste; es
blendet sich ohne laufendes Spiel selbst aus. Wer es entfernt, bekommt es nicht wieder.

Schreibt nur, was fehlt: Ein Plugin, das jemand bewusst ausgeschaltet hat, bleibt aus, und eine
schon eingerichtete Reihenfolge der Anbieter bleibt, wie sie ist. Die Shell beobachtet beide
Dateien und übernimmt die Änderung ohne Neustart.

    activate-plugins.py [--check]
"""
import json
import os
import sys

PLUGINS = ["alpeMeteoSwiss", "alpeRadar", "alpeSport"]
PROVIDER = "plugin_alpeMeteoSwiss"

config = os.environ.get("XDG_CONFIG_HOME") or os.path.join(os.path.expanduser("~"), ".config")
folder = os.path.join(config, "alpe")
check = "--check" in sys.argv[1:]


def load(name):
    path = os.path.join(folder, name)
    try:
        with open(path, encoding="utf-8") as handle:
            return json.load(handle), True
    except FileNotFoundError:
        return {}, False
    except ValueError:
        print("   übersprungen: %s ist kein gültiges JSON" % path)
        return None, True


def save(name, data):
    path = os.path.join(folder, name)
    os.makedirs(folder, exist_ok=True)
    temp = path + ".alpe.tmp"
    with open(temp, "w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, ensure_ascii=False)
        handle.write("\n")
    os.replace(temp, path)


def say(text):
    print("   " + ("würde: " if check else "") + text)


plugins, _ = load("plugin_settings.json")
if plugins is not None:
    changed = False
    for plugin in PLUGINS:
        entry = plugins.setdefault(plugin, {})
        if "enabled" not in entry:
            entry["enabled"] = True
            changed = True
            say("Plugin %s eingeschaltet" % plugin)
        else:
            print("   Plugin %s: %s" % (plugin, "an" if entry["enabled"] else "aus (bewusst, bleibt so)"))
    if changed and not check:
        save("plugin_settings.json", plugins)

settings, existed = load("settings.json")
if settings is not None:
    rows = settings.get("weatherProviders")
    if not isinstance(rows, list):
        rows = [{"id": "openmeteo", "enabled": True}, {"id": "metno", "enabled": False}]
    if any(isinstance(row, dict) and row.get("id") == PROVIDER for row in rows):
        print("   Wetteranbieter: MeteoSchweiz schon eingerichtet")
    else:
        settings["weatherProviders"] = [{"id": PROVIDER, "enabled": True}] + rows
        say("Wetteranbieter: MeteoSchweiz zuerst, die bisherigen dahinter als Rückfall")
        if not check:
            save("settings.json", settings)

# Alpe: Leisten-Element «Sport» einmalig rechts vorne in die erste Leiste
plugins, _ = load("plugin_settings.json")
settings, _ = load("settings.json")
if plugins is not None and settings is not None:
    sport = plugins.setdefault("alpeSport", {})
    bars = settings.get("barConfigs") if isinstance(settings.get("barConfigs"), list) else []
    ids = lambda bar: [w if isinstance(w, str) else (w or {}).get("id") for key in ("leftWidgets", "centerWidgets", "rightWidgets")
                       for w in (bar.get(key) or [])]
    if sport.get("barWidgetAdded"):
        print("   Leiste: Element Sport schon einmal eingerichtet")
    elif any("alpeSport" in ids(bar) for bar in bars if isinstance(bar, dict)):
        sport["barWidgetAdded"] = True
        if not check:
            save("plugin_settings.json", plugins)
    elif bars and isinstance(bars[0], dict):
        bar = next((b for b in bars if isinstance(b, dict) and b.get("enabled", True)), bars[0])
        bar["rightWidgets"] = [{"id": "alpeSport", "enabled": True}] + list(bar.get("rightWidgets") or [])
        sport["barWidgetAdded"] = True
        say("Leiste «%s»: Element Sport rechts vorne (nur sichtbar, wenn ein Favorit spielt)" % bar.get("name", bar.get("id", "")))
        if not check:
            save("settings.json", settings)
            save("plugin_settings.json", plugins)
    else:
        print("   Leiste: keine eigene Leisten-Einstellung gefunden – Element Sport unter Leiste → Widgets hinzufügen")
