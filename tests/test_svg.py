#!/usr/bin/env python3
"""Alpe: Die eigenen SVG-Dateien laden unter QtSvg ohne Meldung (Mac-Test vom 23.11.2026: «Invalid path data»
im Protokoll stammt nicht aus dem Repository). Prüft zugleich das Skript entwicklung/svgpruefung/svg-pruefen.py.

    python3 tests/test_svg.py
"""
import importlib.util
import os
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


try:
    import PySide6  # noqa: F401
except ImportError:
    print("PySide6 fehlt – übersprungen (pip install PySide6)")
    sys.exit(0)

spec = importlib.util.spec_from_file_location("svg_pruefen", os.path.join(REPO, "entwicklung", "svgpruefung", "svg-pruefen.py"))
sp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sp)

eigene = sp.dateien([])
meldungen = sp.pruefe(eigene)
# Untergrenze 20 → 19 seit dem Nachtlauf vom 28.11.2026: shell/assets/hyprland.svg entfernt (Plan 0.8 Nr. 143)
check(len(eigene) >= 19 and meldungen == {},
      "%d eigene SVG-Dateien laden ohne Meldung von QtSvg: %s" % (len(eigene), {os.path.relpath(p, REPO): m for p, m in meldungen.items()}))

with tempfile.TemporaryDirectory() as tmp:
    gut, kaputt = os.path.join(tmp, "gut.svg"), os.path.join(tmp, "unter", "kaputt.svg")
    os.makedirs(os.path.dirname(kaputt))
    kopf = '<svg xmlns="http://www.w3.org/2000/svg" width="8" height="8" viewBox="0 0 8 8">'
    with open(gut, "w") as handle:
        handle.write(kopf + '<path d="M1 1 L7 7 Z"/></svg>')
    with open(kaputt, "w") as handle:
        handle.write(kopf + '<path d="M1 1 L7 7 X3"/></svg>')
    gefunden = sp.dateien([tmp])
    ergebnis = sp.pruefe(gefunden, "Invalid path data")
    check(sorted(os.path.basename(p) for p in gefunden) == ["gut.svg", "kaputt.svg"] and list(ergebnis) == [os.path.realpath(kaputt)],
          "Gegenprobe: eine Datei mit fehlerhaften Pfaddaten wird mit Namen genannt, die gültige nicht: %s" % ergebnis)

print("alle Prüfungen bestanden" if failures == 0 else "%d Prüfung(en) fehlgeschlagen" % failures)
sys.exit(1 if failures else 0)
