#!/usr/bin/env python3
"""Prüft tools/maclock.sh (Hyprland: hyprlock -> Sperre der Shell) an Musterdateien.

Abgeschottet: eigenes HOME, eigenes XDG_RUNTIME_DIR, ohne Session-Bus und Display; vorne im PATH Fallen unter den
Namen von Programmen, die das Werkzeug nie aufrufen darf (systemctl, hyprctl, loginctl, sudo, qdbus6) – erreicht ein
Aufruf eine Falle, ist der Test rot. E4.8b: «undo» kopiert zurück, die Sicherungen *.vor-alpe bleiben bytegleich
liegen, und die Sicherungsordner des Dienstes (.alpe-backups, .dms-backups) werden nicht durchsucht (Plan 0.8 Nr. 57).
"""
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "..", "tools", "maclock.sh")
failures = 0


def check(cond, msg, extra=None):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    if not cond and extra is not None:
        print("       " + str(extra)[-1500:])
    failures += 0 if cond else 1


cfg = tempfile.mkdtemp()
hypr = os.path.join(cfg, "hypr")
os.makedirs(os.path.join(hypr, "user"))
os.makedirs(os.path.join(cfg, "alpe"))
files = {
    "hypridle.conf": "general {\n    lock_cmd = pidof hyprlock || hyprlock\n    before_sleep_cmd = loginctl lock-session\n}\n",
    "hyprland.conf": "exec-once = dms run\nexec-once = sleep 1 && hyprlock --immediate\nbind = SUPER, L, exec, hyprlock\n# hyprlock im Kommentar\nsource = ~/.config/hypr/hyprlock.conf\n",
    "user/binds.lua": 'hl.bind("SUPER", "L", hl.exec("pidof hyprlock || hyprlock"))\nhl.exec_once("hyprlock --immediate")\n-- hyprlock im Kommentar\n',
    "hyprlock.conf": "label {\n  text = hyprlock\n}\n",
}
for name, body in files.items():
    open(os.path.join(hypr, name), "w").write(body)
open(os.path.join(cfg, "alpe", "settings.json"), "w").write('{"x": 1}')
# Sicherungen (Plan 0.8 Nr. 57): Ordner des Dienstes, auch der aus Alpe 1.0, bleiben unberührt.
backups = {
    ".dms-backups/2026-03-01_12-00-00/hyprland.lua": 'hl.bind("SUPER", "L", hl.exec("hyprlock"))\nhl.exec_once("hyprlock --immediate")\n',
    ".alpe-backups/2026-11-22_09-00-00/alpe/binds.lua": 'hl.bind("SUPER", "L", hl.exec("pidof hyprlock || hyprlock"))\n',
}
for name, body in backups.items():
    os.makedirs(os.path.dirname(os.path.join(hypr, name)), exist_ok=True)
    open(os.path.join(hypr, name), "w").write(body)
heim = tempfile.mkdtemp()
lauf = os.path.join(heim, "run")
os.makedirs(lauf, mode=0o700)
fallen = os.path.join(heim, "fallen")
os.makedirs(fallen)
aufrufe = os.path.join(heim, "aufrufe.txt")
for name in ("systemctl", "hyprctl", "loginctl", "sudo", "qdbus6"):
    with open(os.path.join(fallen, name), "w") as handle:
        handle.write('#!/bin/sh\necho "FALLE %s $*" >> "%s"\nexit 1\n' % (name, aufrufe))
    os.chmod(os.path.join(fallen, name), 0o755)
env = {k: v for k, v in os.environ.items() if k not in ("DBUS_SESSION_BUS_ADDRESS", "WAYLAND_DISPLAY", "DISPLAY")}
env.update(HOME=heim, XDG_CONFIG_HOME=cfg, XDG_DATA_HOME=heim + "/.local/share", XDG_STATE_HOME=heim + "/.local/state",
           XDG_CACHE_HOME=heim + "/.cache", XDG_RUNTIME_DIR=lauf, PATH=fallen + ":" + os.environ.get("PATH", ""))


def run(*args):
    aus = subprocess.run(["bash", SCRIPT] + list(args), env=env, capture_output=True, text=True)
    erreicht = open(aufrufe).read().splitlines() if os.path.exists(aufrufe) else []
    check(not erreicht, "maclock.sh %s: kein Aufruf erreicht ein Programm ohne Attrappe %s" % (" ".join(args) or "(Probe)", erreicht))
    return aus


def summe(pfad):
    return hashlib.sha256(open(pfad, "rb").read()).hexdigest()


def read(name):
    return open(os.path.join(hypr, name)).read()


out = run()
check(out.returncode == 0 and "apply" in out.stdout, "Probe zeigt Änderungen und den Befehl zum Umstellen")
check(read("hyprland.conf") == files["hyprland.conf"], "Probe schreibt nichts")

run("apply")
idle, conf, lua = read("hypridle.conf"), read("hyprland.conf"), read("user/binds.lua")
check("lock_cmd = alpe-dienst ipc call lock lock" in idle and "loginctl lock-session" in idle, "hypridle: lock_cmd ersetzt, before_sleep bleibt")
check("bind = SUPER, L, exec, alpe-dienst ipc call lock lock" in conf, "Tastenkürzel ruft die Sperre der Shell")
check("# Alpe:" in conf and "exec-once = dms run" in conf, "Sperren beim Start auskommentiert, dms run bleibt")
check("source = ~/.config/hypr/hyprlock.conf" in conf and "# hyprlock im Kommentar" in conf, "hyprlock.conf-Verweis und Kommentare unberührt")
check('hl.exec("alpe-dienst ipc call lock lock")' in lua and "-- Alpe:" in lua, "Lua: Aufruf ersetzt, exec_once auskommentiert")
check(read("hyprlock.conf") == files["hyprlock.conf"], "hyprlock.conf selbst unberührt")
check(json.load(open(os.path.join(cfg, "alpe", "settings.json"))).get("lockAtStartup") is True, "lockAtStartup eingeschaltet, übrige Einstellungen bleiben")
check(os.path.exists(os.path.join(hypr, "hyprland.conf.vor-alpe")), "Sicherung angelegt")
check(all(read(name) == body for name, body in backups.items()), "Sicherungsordner (.dms-backups, .alpe-backups) unverändert")
check(not any(os.path.exists(os.path.join(hypr, name + ".vor-alpe")) for name in backups), "in den Sicherungsordnern entsteht nichts")
check(".dms-backups" not in out.stdout and ".alpe-backups" not in out.stdout, "die Probe nennt keine Datei aus einer Sicherung")

second = run("apply")
check("nichts zu tun" in second.stdout, "zweiter Lauf: nichts mehr zu tun")

# Vor «undo»: Prüfsummen aller Sicherungen *.vor-alpe; dazu je eine *.vor-alpe in den Sicherungsordnern des Dienstes,
# die «undo» nicht anfassen darf (ihr Original dort entsteht nicht)
im_ordner = [".dms-backups/2026-03-01_12-00-00/hyprland.lua.vor-alpe", ".alpe-backups/2026-11-22_09-00-00/alpe/binds.lua.vor-alpe"]
for name in im_ordner:
    open(os.path.join(hypr, name), "w").write("alt\n")
vorher = {}
for base, _dirs, names in os.walk(hypr):
    for name in names:
        if name.endswith(".vor-alpe"):
            vorher[os.path.join(base, name)] = summe(os.path.join(base, name))
check(len(vorher) == 5, "vor undo: drei Sicherungen von apply und zwei in den Sicherungsordnern", sorted(vorher))
backup_vorher = {name: read(name) for name in backups}

aus = run("undo")
check(aus.returncode == 0, "undo endet mit 0")
check(read("hyprland.conf") == files["hyprland.conf"] and read("user/binds.lua") == files["user/binds.lua"]
      and read("hypridle.conf") == files["hypridle.conf"], "undo stellt die Dateien wieder her")
check(all(os.path.isfile(p) and summe(p) == s for p, s in vorher.items()),
      "undo: jede Sicherung *.vor-alpe bleibt liegen und ist bytegleich (zurückkopieren statt verschieben)")
check(all(read(name) == body for name, body in backup_vorher.items()), "undo: Dateien in den Sicherungsordnern unverändert")
check(".dms-backups" not in aus.stdout and ".alpe-backups" not in aus.stdout,
      "undo nennt und kopiert nichts aus den Sicherungsordnern", aus.stdout)
check(read(".alpe-backups/2026-11-22_09-00-00/alpe/binds.lua") != "alt\n" and read(".dms-backups/2026-03-01_12-00-00/hyprland.lua") != "alt\n",
      "die Originale in den Sicherungsordnern tragen nicht den Inhalt der dortigen *.vor-alpe")

# Zweites «undo»: dasselbe Ergebnis, die Sicherungen bleiben weiter bytegleich
run("undo")
check(all(os.path.isfile(p) and summe(p) == s for p, s in vorher.items()), "zweites undo: Sicherungen weiter bytegleich")

shutil.rmtree(cfg, ignore_errors=True)
shutil.rmtree(heim, ignore_errors=True)
print("\nalle Prüfungen bestanden" if failures == 0 else f"\n{failures} FEHLER")
sys.exit(1 if failures else 0)
