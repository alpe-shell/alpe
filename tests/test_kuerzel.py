#!/usr/bin/env python3
"""Prüft tools/kuerzel.py: Tastencodes und das Übernehmen belegter Tasten (ohne KDE, mit Attrappe)."""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "tools"))
import kuerzel  # noqa: E402

failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


Q, M, F4 = kuerzel.key_code("Meta+Q"), kuerzel.key_code("Meta+M"), kuerzel.key_code("Alt+F4")
check((Q, M, F4) == (0x10000051, 0x1000004D, 0x09000033), "Tastencodes wie Qt (Meta+Q, Meta+M, Alt+F4)")
check(kuerzel.key_text(F4) == "Alt+F4" and kuerzel.key_text(kuerzel.key_code("Meta+Shift+M")) == "Meta+Shift+M", "Tastencodes zurück in Text")


class Fake:
    def __init__(self, comps):
        self.comps = comps
        self.calls = []

    def shortcuts(self):
        return {"available": True, "components": self.comps}

    def set_keys(self, comp, action, cname, aname, keys):
        self.calls.append((comp, action, list(keys)))
        for c in self.comps:
            for a in c["actions"]:
                if c["component"] == comp and a["action"] == action:
                    a["keys"] = list(keys)
        return "ok"


fake = Fake([
    {"component": "kwin", "name": "KWin", "actions": [
        {"action": "Window Close", "name": "Fenster schliessen", "keys": [F4]},
        {"action": "alpe-processlist", "name": "Alpe: Systemmonitor", "keys": [kuerzel.key_code("Meta+Shift+M")]}]},
    {"component": "plasmashell", "name": "Plasma", "actions": [
        {"action": "manage activities", "name": "Aktivitäten", "keys": [Q, kuerzel.key_code("Meta+A")]}]},
])
code = kuerzel.vorgaben(fake, 0)
acts = {(c["component"], a["action"]): a["keys"] for c in fake.comps for a in c["actions"]}
check(code == 0 and acts[("kwin", "Window Close")] == [F4, Q], "Meta+Q kommt zu Alt+F4 dazu")
check(M in acts[("kwin", "alpe-processlist")], "Systemmonitor bekommt Meta+M")
check(acts[("plasmashell", "manage activities")] == [kuerzel.key_code("Meta+A")], "bisheriger Besitzer gibt nur Meta+Q ab")
calls = len(fake.calls)
kuerzel.vorgaben(fake, 0)
check(len(fake.calls) == calls, "zweiter Lauf ändert nichts")

missing = Fake([{"component": "kwin", "name": "KWin", "actions": [{"action": "Window Close", "name": "x", "keys": []}]}])
check(kuerzel.vorgaben(missing, 0) == 1, "fehlende Aktion (Shell läuft nicht) wird gemeldet")

print("\nalle Prüfungen bestanden" if failures == 0 else f"\n{failures} FEHLER")
sys.exit(1 if failures else 0)
