#!/usr/bin/env python3
"""Prüft quickshell/scripts/alpe-hyprlock.py: hyprlock.conf -> Layout -> hyprlock.conf.

    python3 tests/test_hyprlock.py      nimmt ~/dux-shell (oder ALPE_SHELL_DIR)
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(os.path.expanduser("~"), "dux-shell")
SCRIPT = os.path.join(SHELL, "quickshell", "scripts", "alpe-hyprlock.py")
TEMPLATE = os.path.join(HERE, "data", "hyprlock-beispiel.conf")
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


tmp = tempfile.mkdtemp()
conf = os.path.join(tmp, "hyprlock.conf")
shutil.copy(TEMPLATE, conf)
with open(conf, "a") as handle:
    handle.write("\nauth {\n    fingerprint:enabled = false\n}\n\nanimations {\n    enabled = true\n    bezier = linear, 1, 1, 0, 0\n}\n")
env = dict(os.environ, XDG_STATE_HOME=os.path.join(tmp, "state"))


def run(*args):
    out = subprocess.run([sys.executable, "-I", SCRIPT] + list(args), env=env, capture_output=True, text=True)
    return out.stdout


first = json.loads(run(conf, "--json"))
check(len(first["widgets"]) == 10, "Vorlage: 10 Elemente")

layout = json.loads(json.dumps(first))
hours = [w for w in layout["widgets"] if w["type"] == "label"][0]
hours["position"] = ["0", "-300"]
layout["widgets"].append({"type": "label", "format": "Hallo $USER, %A", "position": ["0", "200"], "halign": "center",
                          "valign": "center", "color": "#ccffffff", "fontSize": 20, "font": {"family": "JetBrains Mono", "weight": 700}})
layout["background"].update({"source": "desktop", "blurRadius": 96})
run("write", conf, json.dumps(layout), "--locale", "de_CH", "--wallpaper", "/bilder/berge.jpg")
text = open(conf).read()
check("auth {" in text and "bezier = linear" in text and "grace = 1" in text, "general, auth, animations bleiben erhalten")
check(text.count("background {") == 1 and "path = /bilder/berge.jpg" in text and "alpe: hintergrund = desktop" in text, "Hintergrund folgt dem Desktop (Marke, Bild)")
check("blur_passes = 3" in text and "blur_size = 4" in text, "Unschärfe 96 -> 3 Durchgänge, Grösse 4")
check('text = cmd[update:1000] LC_TIME=de_CH.UTF-8 date +"Hallo $USER, %A"' in text, "eigener Text mit Datum und Sprache")
check("font_family = JetBrains Mono Bold" in text, "Strichstärke als Teil der Schriftangabe")
check(os.path.exists(conf + ".vor-alpe") and os.listdir(os.path.join(tmp, "state", "alpe", "hyprlock")), "Sicherungen angelegt")

second = json.loads(run(conf, "--json"))
check(len(second["widgets"]) == 11, "wieder eingelesen: 11 Elemente")
check([w for w in second["widgets"] if w["type"] == "label"][0]["position"] == ["0", "-300"], "Verschiebung bleibt erhalten")
check(second["background"]["source"] == "desktop", "Quelle des Hintergrunds bleibt «Desktop»")
same = all(a.get(k) == b.get(k) for a, b in zip(first["widgets"], second["widgets"]) for k in ("type", "path", "size", "fontSize", "color", "halign", "valign") if k in a)
check(same, "übrige Elemente unverändert")

out = json.loads(run("wallpaper", conf, "/bilder/see.jpg"))
check(out["changed"] and "path = /bilder/see.jpg" in open(conf).read() and "Sperre/bild1.png" in open(conf).read(), "neues Desktop-Bild: nur der Hintergrund wechselt")

layout["background"].update({"source": "image", "image": "/bilder/eigen.jpg"})
run("write", conf, json.dumps(layout))
check(json.loads(run("wallpaper", conf, "/bilder/x.jpg"))["changed"] is False and "path = /bilder/eigen.jpg" in open(conf).read(), "eigenes Bild: Desktop-Wechsel ändert nichts")

print("\nalle Prüfungen bestanden" if failures == 0 else f"\n{failures} FEHLER")
sys.exit(1 if failures else 0)
