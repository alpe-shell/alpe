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

# ---------------------------------------------------------------- D7.7a2: sichtbare Kennungen
# Layer-Namensräume heissen alpe:…; der Dienst schneidet denselben Vorsatz ab (Bildschirmfoto-Ziele).
alt, neu = [], 0
for ordner, _dirs, dateien in os.walk(SHELL):
    if any(teil in ordner for teil in ("/Modules/DankBar", "/Modules/DankDash", "/DCommon", "/translations", "/tests")):
        continue
    for datei in dateien:
        if not datei.endswith((".qml", ".js")):
            continue
        text = read(ordner, datei)
        neu += len(re.findall(r'["^]alpe:[a-z]', text))
        if re.search(r'["^\'`]dms:[a-z.$"]', text):
            alt.append(os.path.relpath(os.path.join(ordner, datei), SHELL))
check(not alt and neu > 80, "Layer-Namensräume: %d mal alpe:…, keiner mehr mit dms: %s" % (neu, alt[:5]))
types = os.path.join(REPO, "core", "internal", "screenshot", "types.go")
if os.path.exists(types):
    check('strings.TrimPrefix(s.Name, "alpe:")' in read(types), "Dienst: Bildschirmfoto-Ziele ohne Vorsatz alpe:")
hypr = read(SHELL, "Services", "HyprlandService.qml")
check('"^alpe:.*$"' in hypr and '"^alpe:island$"' in hypr, "Hyprland-Regeln der Shell treffen alpe:…")
check('`app-alpe-${' in read(SHELL, "Common", "LaunchUnit.js"), "gestartete Programme laufen als app-alpe-…")
insel = read(SHELL, "Modules", "Island", "Island.qml")
check('"DOT" : "ISLAND"' in insel and "DANK" not in insel, "IPC-Antworten der Insel: ISLAND_…/DOT_…")

# ---------------------------------------------------------------- D7.7b4: «jedes Mal fragen»
# Die Standardprogramme bieten den Eintrag alpe-open an; die Desktop-Datei dazu liegt im Repo
# (Installation: E3, mimeapps.list: F1 – Plan 0.8 Nr. 50).
desktop = os.path.join(REPO, "packaging", "alpe-open.desktop")
if os.path.isdir(os.path.join(REPO, "packaging")):
    eintrag = dict(zeile.split("=", 1) for zeile in read(desktop).splitlines() if "=" in zeile)
    tab = read(SHELL, "Modules", "Settings", "DefaultAppsTab.qml")
    kennung = re.search(r'shellChooserId: "([\w-]+)"', tab)
    check(kennung is not None and kennung.group(1) + ".desktop" == os.path.basename(desktop),
          "Desktop-Datei heisst wie der Auswahl-Eintrag der Standardprogramme")
    check(eintrag.get("Exec") == "alpe-dienst open %u" and eintrag.get("NoDisplay") == "true",
          "ruft alpe-dienst open, erscheint nicht im Starter")
    check("x-scheme-handler/http;" in eintrag.get("MimeType", "") and "dms" not in read(desktop).lower(),
          "meldet sich für Links an, kein Schema des Ursprungs")
    import shutil
    import subprocess
    if shutil.which("desktop-file-validate"):
        check(subprocess.run(["desktop-file-validate", desktop]).returncode == 0, "desktop-file-validate")

print("\nalle Prüfungen bestanden" if failures == 0 else f"\n{failures} FEHLER")
sys.exit(1 if failures else 0)
