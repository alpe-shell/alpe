#!/usr/bin/env python3
"""Alpe: Paketdateien unter packaging/ (Plan 6.1; Nachtlauf-Auftrag E1 2.4).

    python3 tests/test_paketdateien.py

Prüft ohne Bau: die Benutzer-Unit alpe.service nach 6.1, die Desktop-Dateien der App-ID io.github.alpe_shell.Alpe
(Shell, Notizblock, Auswahl «jedes Mal fragen» alpe-open) und dass ihre Befehle und Symbole zur Shell passen.
desktop-file-validate läuft, wenn es installiert ist.
"""
import configparser
import os
import re
import shutil
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(REPO, "shell")
APPID = "io.github.alpe_shell.Alpe"
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


def lies_ini(pfad):
    p = configparser.ConfigParser(interpolation=None, strict=False, delimiters=("=",))
    p.optionxform = str
    p.read(pfad, encoding="utf-8")
    return p


# --- Unit (Plan 6.1)
unit_pfad = os.path.join(REPO, "packaging", "systemd", "alpe.service")
unit = lies_ini(unit_pfad)
text = open(unit_pfad, encoding="utf-8").read()
check(unit["Unit"]["Description"] == "Alpe", "Unit: Description=Alpe")
check(unit["Unit"]["PartOf"] == "graphical-session.target" and unit["Unit"]["Requisite"] == "graphical-session.target"
      and "graphical-session.target" in unit["Unit"]["After"].split(), "Unit: PartOf, After, Requisite = graphical-session.target")
check(unit["Unit"]["Conflicts"] == "dms.service" and "dms.service" in unit["Unit"]["After"].split(),
      "Unit: Conflicts=dms.service und After=dms.service (nie zwei Shells gleichzeitig)")
check(unit["Service"]["Type"] == "notify" and unit["Service"]["NotifyAccess"] == "main"
      and unit["Service"]["BusName"] == "org.freedesktop.Notifications", "Unit: Type=notify, NotifyAccess=main, BusName")
umgebung = unit["Service"]["Environment"].split()
check({"QS_DISABLE_CRASH_HANDLER=1", "MALLOC_ARENA_MAX=2"} <= set(umgebung), "Unit: Environment QS_DISABLE_CRASH_HANDLER=1 MALLOC_ARENA_MAX=2")
session = open(os.path.join(SHELL, "Services", "SessionService.qml"), encoding="utf-8").read()
check("ALPE_SHELL_ARENA=1" in umgebung and 'Quickshell.env("ALPE_SHELL_ARENA") === "1"' in session,
      "Unit: ALPE_SHELL_ARENA=1 – die Shell gibt MALLOC_ARENA_MAX nicht an gestartete Programme weiter (wie 1.0)")
check(unit["Service"]["ExecStart"] == "/usr/bin/alpe start --session", "Unit: ExecStart=/usr/bin/alpe start --session")
check(unit["Install"]["WantedBy"] == "graphical-session.target", "Unit: WantedBy=graphical-session.target")
check(not re.search(r"\bdms\b(?!\.service)", text.split("[Unit]", 1)[1]) and "/usr/bin/dms" not in text,
      "Unit: kein Befehl oder Pfad des Ursprungs (nur dms.service in Conflicts/After)")

# --- Desktop-Dateien (6.1; .Open ist überholt, der Auswahl-Eintrag heisst alpe-open, 0.8 Nr. 50/59)
ordner = os.path.join(REPO, "packaging", "desktop")
namen = sorted(f for f in os.listdir(ordner) if f.endswith(".desktop"))
check(namen == ["alpe-open.desktop", APPID + ".Notepad.desktop", APPID + ".desktop"],
      "packaging/desktop: genau die drei Desktop-Dateien (Shell, Notizblock, alpe-open): %s" % namen)
eintraege = {n: lies_ini(os.path.join(ordner, n))["Desktop Entry"] for n in namen}
check(all(e["Icon"] == APPID and e["NoDisplay"] == "true" and e["Type"] == "Application" for e in eintraege.values()),
      "alle drei: Icon=%s, NoDisplay=true" % APPID)
check(eintraege[APPID + ".desktop"]["Exec"] == "alpe-dienst run -c /usr/share/alpe/shell",
      "Shell: Exec=alpe-dienst run -c /usr/share/alpe/shell (Dienst ohne eingebettete Oberfläche)")
ipc = open(os.path.join(SHELL, "ShellIpc.qml"), encoding="utf-8").read()
block = re.search(r'IpcHandler \{((?:(?!IpcHandler \{).)*?)target: "notepad"', ipc, re.S)
check(eintraege[APPID + ".Notepad.desktop"]["Exec"] == "alpe-dienst ipc call notepad openFile %f"
      and block is not None and "function openFile(path: string)" in block.group(1),
      "Notizblock: Exec ruft das IPC-Ziel notepad mit openFile, das es in ShellIpc.qml gibt")
check(eintraege[APPID + ".Notepad.desktop"]["MimeType"] == "text/plain;text/markdown;", "Notizblock: Textdateien und Markdown")
check(all("dms" not in e["Exec"] and "dank" not in e["Exec"].lower() for e in eintraege.values()), "kein Befehl des Ursprungs")
check(os.path.isfile(os.path.join(REPO, "assets", "logo", "logo", "alpe-zeichen.svg"))
      and "assets/logo/logo/alpe-zeichen.svg" in open(os.path.join(REPO, "Makefile"), encoding="utf-8").read(),
      "Symbol der App-ID: das Alpe-Zeichen (assets/logo/logo/alpe-zeichen.svg, installiert unter dem Namen der App-ID)")
if shutil.which("desktop-file-validate"):
    out = subprocess.run(["desktop-file-validate"] + [os.path.join(ordner, n) for n in namen], capture_output=True, text=True)
    check(out.returncode == 0 and not out.stdout.strip(), "desktop-file-validate ohne Meldung: %s" % (out.stdout + out.stderr).strip())
else:
    print("desktop-file-validate fehlt – übersprungen")

print("\n%s" % ("alle Prüfungen bestanden" if not failures else "%d FEHLER" % failures))
sys.exit(1 if failures else 0)
