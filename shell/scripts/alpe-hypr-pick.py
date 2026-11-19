#!/usr/bin/env python3
"""Alpe: ein Fenster unter Hyprland auswählen (für «Fenster wählen» in den Fensterregeln).

Mit slurp: Fadenkreuz, der Klick auf ein Fenster liefert dessen Klasse und Titel.
Ohne slurp: kurze Wartezeit, dann wird das fokussierte Fenster genommen.
Ausgabe: eine JSON-Zeile {"class", "title", "initialClass", "initialTitle", "floating"}
oder {"error": "..."}; Exit 0 bzw. 1.
"""
import json
import shutil
import subprocess
import sys
import time


def hypr(*args):
    out = subprocess.run(["hyprctl", "-j", *args], capture_output=True, text=True, timeout=5)
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip() or "hyprctl fehlgeschlagen")
    return json.loads(out.stdout or "null")


def describe(c):
    return {
        "class": c.get("class", ""),
        "title": c.get("title", ""),
        "initialClass": c.get("initialClass", ""),
        "initialTitle": c.get("initialTitle", ""),
        "floating": bool(c.get("floating")),
    }


def window_at(clients, monitors, x, y):
    visible = set()
    for m in monitors or []:
        visible.add((m.get("activeWorkspace") or {}).get("id"))
        sw = (m.get("specialWorkspace") or {}).get("id")
        if sw:
            visible.add(sw)
    hits = []
    for c in clients or []:
        if not c.get("mapped", True) or c.get("hidden"):
            continue
        if (c.get("workspace") or {}).get("id") not in visible:
            continue
        (cx, cy), (w, h) = c.get("at", [0, 0]), c.get("size", [0, 0])
        if cx <= x < cx + w and cy <= y < cy + h:
            hits.append(c)
    if not hits:
        return None
    # Oben liegt: Spezial-Workspace vor normal, schwebend vor gekachelt,
    # danach das zuletzt fokussierte (kleinste focusHistoryID).
    hits.sort(key=lambda c: (
        0 if (c.get("workspace") or {}).get("id", 0) < 0 else 1,
        0 if c.get("floating") else 1,
        c.get("focusHistoryID", 99),
    ))
    return hits[0]


def parse_point(text):
    # slurp -p -f '%x %y' liefert «x y»
    parts = text.split()
    return int(float(parts[0])), int(float(parts[1]))


def main(argv):
    delay = 3.0
    if "--delay" in argv:
        delay = float(argv[argv.index("--delay") + 1])
    if shutil.which("slurp") and "--focus" not in argv:
        r = subprocess.run(["slurp", "-p", "-f", "%x %y"], capture_output=True, text=True, timeout=120)
        if r.returncode != 0:
            print(json.dumps({"error": "abgebrochen"}))
            return 1
        x, y = parse_point(r.stdout)
        c = window_at(hypr("clients"), hypr("monitors"), x, y)
        if not c:
            print(json.dumps({"error": "An dieser Stelle liegt kein Fenster"}))
            return 1
        print(json.dumps(describe(c)))
        return 0
    time.sleep(delay)
    c = hypr("activewindow")
    if not c or not c.get("class"):
        print(json.dumps({"error": "Kein fokussiertes Fenster gefunden"}))
        return 1
    print(json.dumps(describe(c)))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except Exception as e:  # noqa: BLE001
        print(json.dumps({"error": str(e)}))
        sys.exit(1)
