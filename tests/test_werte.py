#!/usr/bin/env python3
"""Alpe: restliche Werte mit altem Namen (Plan 0.8 Nr. 38, D7.7a).

Kürzel-Kategorie eigener Aktionen heisst «Alpe» und wird einsortiert; Kategorien aus Kürzeln von 1.0
werden übergangsweise weiter erkannt. Prozessliste und doctor kennen den alten Namen nicht mehr.
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(REPO, "shell")
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


def read(*parts):
    with open(os.path.join(*parts), encoding="utf-8") as handle:
        return handle.read()


content = read(SHELL, "Modals", "KeybindsContent.qml")
service = read(SHELL, "Services", "KeybindsService.qml")
kategorie = re.search(r'isShellAction\(bind\.action\) \? "(\w+)"', service)
check(kategorie is not None and kategorie.group(1) == "Alpe", "eigene Kürzel stehen in der Kategorie «Alpe»")
prio = dict(re.findall(r'^\s+"([a-z -]+)": (\d+),?', content, re.M))
check(prio.get("alpe") == "7", "die Kategorie «Alpe» hat ihren Platz in der Reihenfolge (vorher 99)")
check(prio.get("dms") == prio.get("alpe"), "Kategorie aus Kürzeln von 1.0 wird übergangsweise gleich einsortiert")
check('lower === "alpe" || lower.includes("dms")' in content, "Symbol: alpe, übergangsweise auch dms")

actions = read(SHELL, "Modules", "ProcessList", "ProcessActions.qml")
check(not re.search(r"dms", actions, re.I), "Prozessliste ohne alten Namen")
check('return "shell";' in actions and 'case "shell":' in actions and "Proc.shellRestartCommand" in actions,
      "eigener Prozess: Neustart über die Art «shell»")

doctor = os.path.join(REPO, "core", "cmd", "alpe-dienst", "commands_doctor.go")
if os.path.exists(doctor):
    text = read(doctor)
    check("getShellVersion()" in text and "getDMSShellVersion" not in text, "doctor: getShellVersion")

print("\nalle Prüfungen bestanden" if failures == 0 else f"\n{failures} FEHLER")
sys.exit(1 if failures else 0)
