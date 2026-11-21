#!/usr/bin/env python3
"""Prüft tools/maclock.sh (Hyprland: hyprlock -> Sperre der Shell) an Musterdateien."""
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "..", "tools", "maclock.sh")
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
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
env = dict(os.environ, XDG_CONFIG_HOME=cfg)


def run(*args):
    return subprocess.run(["bash", SCRIPT] + list(args), env=env, capture_output=True, text=True)


def read(name):
    return open(os.path.join(hypr, name)).read()


out = run()
check(out.returncode == 0 and "apply" in out.stdout, "Probe zeigt Änderungen und den Befehl zum Umstellen")
check(read("hyprland.conf") == files["hyprland.conf"], "Probe schreibt nichts")

run("apply")
idle, conf, lua = read("hypridle.conf"), read("hyprland.conf"), read("user/binds.lua")
check("lock_cmd = dms ipc call lock lock" in idle and "loginctl lock-session" in idle, "hypridle: lock_cmd ersetzt, before_sleep bleibt")
check("bind = SUPER, L, exec, dms ipc call lock lock" in conf, "Tastenkürzel ruft die Sperre der Shell")
check("# Alpe:" in conf and "exec-once = dms run" in conf, "Sperren beim Start auskommentiert, dms run bleibt")
check("source = ~/.config/hypr/hyprlock.conf" in conf and "# hyprlock im Kommentar" in conf, "hyprlock.conf-Verweis und Kommentare unberührt")
check('hl.exec("dms ipc call lock lock")' in lua and "-- Alpe:" in lua, "Lua: Aufruf ersetzt, exec_once auskommentiert")
check(read("hyprlock.conf") == files["hyprlock.conf"], "hyprlock.conf selbst unberührt")
check(json.load(open(os.path.join(cfg, "alpe", "settings.json"))).get("lockAtStartup") is True, "lockAtStartup eingeschaltet, übrige Einstellungen bleiben")
check(os.path.exists(os.path.join(hypr, "hyprland.conf.vor-alpe")), "Sicherung angelegt")

second = run("apply")
check("nichts zu tun" in second.stdout, "zweiter Lauf: nichts mehr zu tun")

run("undo")
check(read("hyprland.conf") == files["hyprland.conf"] and read("user/binds.lua") == files["user/binds.lua"], "undo stellt die Dateien wieder her")

print("\nalle Prüfungen bestanden" if failures == 0 else f"\n{failures} FEHLER")
sys.exit(1 if failures else 0)
