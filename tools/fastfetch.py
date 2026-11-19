#!/usr/bin/env python3
"""fastfetch auf Alpe einrichten: Bergkette als Logo und die Version der Shell, automatisch.

    fastfetch.py [--check]

Ändert die vorhandene Einstellungsdatei (~/.config/fastfetch/config.jsonc oder config.json):
  - logo: Datei assets/fastfetch-logo.txt (nach ~/.config/fastfetch/alpe-logo.txt kopiert),
    Farben 1 Schnee, 2 Fels, 3 Schrift; Abstände (padding) bleiben, wie sie waren
  - die eigene Zeile mit «Alpe …» (type custom) wird zu type command mit «alpe version --short»;
    gibt es keine, kommt sie nach dem Trennstrich
Vorher eine Sicherung daneben (.vor-alpe). Fehlt die Datei, entsteht eine schlichte neue.
Kommentare (//) in einer .jsonc-Datei gehen verloren; die Sicherung behält sie.
"""
import json
import os
import re
import shutil
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.join(os.path.expanduser("~"), ".config")
FOLDER = os.path.join(CONFIG, "fastfetch")
LOGO = os.path.join(FOLDER, "alpe-logo.txt")
VERSION_COMMAND = "alpe version --short"


def strip_comments(text):
    """// und /* */ ausserhalb von Zeichenketten entfernen, dazu Kommas vor } oder ]."""
    out, i, quoted = [], 0, False
    while i < len(text):
        c = text[i]
        if quoted:
            out.append(c)
            if c == "\\":
                out.append(text[i + 1:i + 2]); i += 1
            elif c == '"':
                quoted = False
        elif c == '"':
            quoted = True; out.append(c)
        elif text.startswith("//", i):
            while i < len(text) and text[i] != "\n":
                i += 1
            continue
        elif text.startswith("/*", i):
            end = text.find("*/", i + 2)
            i = len(text) if end < 0 else end + 2
            continue
        else:
            out.append(c)
        i += 1
    return re.sub(r",(\s*[}\]])", r"\1", "".join(out))


def is_alpe_line(module):
    return isinstance(module, dict) and (
        (module.get("type") == "custom" and "alpe" in str(module.get("format", "")).lower())
        or (module.get("type") == "command" and "alpe" in str(module.get("text", "")).lower()))


def adapt(config):
    logo = config.get("logo") if isinstance(config.get("logo"), dict) else {}
    config["logo"] = {
        "type": "file",
        "source": LOGO,
        "padding": logo.get("padding") or {"top": 2, "left": 2},
        "color": {"1": "white", "2": "blue", "3": "magenta"},
    }
    modules = config.setdefault("modules", [])
    line = {"type": "command", "key": "󰣇 OS     ", "text": VERSION_COMMAND}
    for i, module in enumerate(modules):
        if is_alpe_line(module):
            line["key"] = module.get("key", line["key"])
            modules[i] = line
            return config
    at = next((i + 1 for i, m in enumerate(modules) if m == "separator" or (isinstance(m, dict) and m.get("type") == "separator")), 0)
    modules.insert(at, line)
    return config


def main(check):
    path = next((os.path.join(FOLDER, n) for n in ("config.jsonc", "config.json") if os.path.exists(os.path.join(FOLDER, n))), None)
    if path:
        text = open(path, encoding="utf-8").read()
        try:
            config = json.loads(strip_comments(text))
        except ValueError as error:
            print("   übersprungen: %s ist kein gültiges JSON (%s)" % (path, error))
            return 1
    else:
        path = os.path.join(FOLDER, "config.jsonc")
        text = None
        config = {"$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
                  "modules": ["title", "separator", "kernel", "host", "packages", "break", "cpu", "gpu", "memory", "break", "colors"]}
    new = adapt(json.loads(json.dumps(config)))
    if new == config and os.path.exists(LOGO):
        print("   fastfetch: schon eingerichtet (%s)" % path)
        return 0
    if check:
        print("   würde: %s anpassen (Logo Bergkette, Version über «%s»)" % (path, VERSION_COMMAND))
        return 0
    os.makedirs(FOLDER, exist_ok=True)
    shutil.copyfile(os.path.join(HERE, "..", "assets", "fastfetch-logo.txt"), LOGO)
    if text is not None:
        backup = path + ".vor-alpe"
        if os.path.exists(backup):
            backup += "-" + time.strftime("%Y%m%d-%H%M%S")
        shutil.copyfile(path, backup)
        print("   Sicherung: %s" % backup)
    tmp = path + ".alpe.tmp"
    with open(tmp, "w", encoding="utf-8") as handle:
        json.dump(new, handle, indent=4, ensure_ascii=False)
        handle.write("\n")
    os.replace(tmp, path)
    print("   fastfetch: %s angepasst (Logo %s)" % (path, LOGO))
    return 0


if __name__ == "__main__":
    sys.exit(main("--check" in sys.argv[1:]))
