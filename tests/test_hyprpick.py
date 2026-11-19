#!/usr/bin/env python3
"""Prüft quickshell/scripts/alpe-hypr-pick.py mit Attrappen für hyprctl und slurp."""
import json
import os
import subprocess
import sys
import tempfile

SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(os.path.expanduser("~"), "dux-shell")
SCRIPT = os.path.join(SHELL, "quickshell", "scripts", "alpe-hypr-pick.py")
failures = 0
if not os.path.exists(SCRIPT):
    print(f"{SCRIPT} fehlt – zuerst den Shell-Code auf Alpe bringen (bash ~/alpe/install.sh)")
    sys.exit(1)


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


bin_dir = tempfile.mkdtemp()
clients = [
    {"class": "kitty", "title": "fish ~", "initialClass": "kitty", "initialTitle": "kitty", "at": [0, 0], "size": [1000, 800],
     "workspace": {"id": 1}, "floating": False, "focusHistoryID": 1, "mapped": True},
    {"class": "org.gnome.Nautilus", "title": "Downloads", "initialClass": "org.gnome.Nautilus", "initialTitle": "Dateien",
     "at": [200, 200], "size": [400, 300], "workspace": {"id": 1}, "floating": True, "focusHistoryID": 2, "mapped": True},
    {"class": "firefox", "title": "versteckt", "at": [0, 0], "size": [1000, 800], "workspace": {"id": 2}, "mapped": True},
]
monitors = [{"activeWorkspace": {"id": 1}, "specialWorkspace": {"id": 0}}]
active = clients[0]
open(f"{bin_dir}/data.json", "w").write(json.dumps({"clients": clients, "monitors": monitors, "activewindow": active}))
open(f"{bin_dir}/hyprctl", "w").write(f"""#!/usr/bin/env python3
import json, sys
d = json.load(open("{bin_dir}/data.json"))
print(json.dumps(d[sys.argv[-1]]))
""")
os.chmod(f"{bin_dir}/hyprctl", 0o755)


def slurp(point, code=0):
    open(f"{bin_dir}/slurp", "w").write(f"#!/bin/sh\necho '{point}'\nexit {code}\n")
    os.chmod(f"{bin_dir}/slurp", 0o755)


def run(*args):
    env = dict(os.environ, PATH=bin_dir + ":/usr/bin:/bin")
    r = subprocess.run([sys.executable, SCRIPT, *args], env=env, capture_output=True, text=True)
    return r.returncode, json.loads(r.stdout.strip().splitlines()[-1])


slurp("300 300")
code, out = run()
check(code == 0 and out["class"] == "org.gnome.Nautilus" and out["title"] == "Downloads", "Klick auf überlappende Stelle: das schwebende Fenster oben gewinnt")
slurp("50 50")
code, out = run()
check(code == 0 and out["class"] == "kitty" and out["initialTitle"] == "kitty", "Klick auf kitty liefert Klasse, Titel und Anfangswerte")
slurp("5000 5000")
code, out = run()
check(code == 1 and "kein Fenster" in out["error"], "Klick ins Leere wird gemeldet")
slurp("", 1)
code, out = run()
check(code == 1 and out["error"] == "abgebrochen", "Esc in slurp bricht ab")
code, out = run("--focus", "--delay", "0")
check(code == 0 and out["class"] == "kitty", "ohne slurp: fokussiertes Fenster nach Wartezeit")

sys.exit(1 if failures else 0)
