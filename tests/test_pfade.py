#!/usr/bin/env python3
"""Prüft, dass die Oberfläche keine Pfade der 1.0-Einrichtung (DMS) mehr erwartet.

Seit D2 liegen die Hyprland-Teile unter ~/.config/hypr/alpe/ und der Dienst meldet Quellen wie
«…/hypr/alpe/windowrules.lua». Ein Vergleich mit «dms/…» in der Oberfläche trifft dann nichts
mehr (eigene Fensterregeln erschienen so als fremd).

    python3 tests/test_pfade.py        nimmt shell/ im Repository (oder ALPE_SHELL_DIR)
"""
import os
import re
import sys

SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "shell")
# «dms/…» oder «hypr/dms» in einer Zeichenkette; Kommentare zählen nicht.
PATTERN = re.compile(r"""["'`][^"'`\n]*(?<![\w-])(?:dms/|hypr/dms)""")
# Bewusste Ausnahme: Migration alter DMS-1.x-Anzeigeprofile (nur lesend).
ALLOWED = {os.path.join("Common", "OutputModel.js")}

failures = []
for root, dirs, files in os.walk(SHELL):
    dirs[:] = [d for d in dirs if d not in ("tests", "translations")]
    for name in files:
        if not name.endswith((".qml", ".js")):
            continue
        path = os.path.join(root, name)
        rel = os.path.relpath(path, SHELL)
        if rel in ALLOWED:
            continue
        with open(path, encoding="utf-8") as handle:
            for number, line in enumerate(handle, 1):
                code = line.split("//", 1)[0] if not line.lstrip().startswith("*") else ""
                # Verweise auf Webseiten (Site.docs + "/dms/…") sind keine Pfade.
                if PATTERN.search(code) and "Site." not in code:
                    failures.append("%s:%d: %s" % (rel, number, line.strip()[:120]))

for failure in failures:
    print("FEHLER " + failure)
print("ok    keine dms/-Pfade in der Oberfläche" if not failures else "%d Stelle(n) mit dms/-Pfad" % len(failures))
sys.exit(1 if failures else 0)
