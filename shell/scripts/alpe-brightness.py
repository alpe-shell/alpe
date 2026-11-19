#!/usr/bin/env python3
"""Bildschirmhelligkeit unter KWin für Alpe.

Unter KWin regelt Plasma die Helligkeit (PowerDevil, für externe Bildschirme über DDC/CI).
Ein zweiter Zugriff daneben stört nur. Dieses Programm spricht deshalb Plasmas Schnittstelle
org.kde.ScreenBrightness an und, wo es sie nicht gibt, kscreen-doctor.

  alpe-brightness.py list              -> {"backend": "...", "devices": [{"id", "label", "percent"}]}
  alpe-brightness.py set <id> <0-100>  -> {"ok": true} oder {"ok": false, "error": "..."}
"""

import json
import re
import subprocess
import sys

TIMEOUT = 8
SERVICE = "org.kde.ScreenBrightness"
ROOT = "/org/kde/ScreenBrightness"
DISPLAY_IFACE = "org.kde.ScreenBrightness.Display"


def run(argv):
    try:
        proc = subprocess.run(argv, capture_output=True, text=True, timeout=TIMEOUT)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return 1, "", str(exc)
    return proc.returncode, proc.stdout, proc.stderr.strip()


def busctl(*args):
    code, out, err = run(["busctl", "--user", "--json=short", *args])
    if code != 0:
        return None, err
    try:
        return json.loads(out) if out.strip() else {}, ""
    except ValueError:
        return None, "unlesbare Antwort von busctl"


def unwrap(value):
    """busctl verpackt Varianten als {"type": ..., "data": ...}."""
    while isinstance(value, dict) and "data" in value and "type" in value:
        value = value["data"]
    return value


def powerdevil_displays():
    reply, err = busctl("get-property", SERVICE, ROOT, SERVICE, "DisplaysDBusNames")
    if reply is None:
        return None, err
    names = unwrap(reply)
    return ([str(name) for name in names] if isinstance(names, list) else []), ""


def powerdevil_properties(name):
    reply, err = busctl("call", SERVICE, ROOT + "/" + name, "org.freedesktop.DBus.Properties", "GetAll", "s", DISPLAY_IFACE)
    if reply is None:
        return None
    data = unwrap(reply)
    if isinstance(data, list) and data and isinstance(data[0], dict):
        data = data[0]
    if not isinstance(data, dict):
        return None
    return {str(key).lower(): unwrap(value) for key, value in data.items()}


def powerdevil_range(props):
    current = props.get("brightness")
    maximum = props.get("maxbrightness")
    if not isinstance(current, (int, float)):
        return None
    if not isinstance(maximum, (int, float)) or maximum <= 0:
        maximum = 10000 if current > 100 else 100
    return float(current), float(maximum)


def list_powerdevil():
    names, err = powerdevil_displays()
    if names is None:
        return None
    devices = []
    for name in names:
        if not re.fullmatch(r"[A-Za-z0-9_]+", name):
            continue
        props = powerdevil_properties(name)
        span = powerdevil_range(props) if props else None
        if not span:
            continue
        devices.append({
            "id": "kde:" + name,
            "label": str(props.get("label") or name),
            "percent": max(0, min(100, int(round(span[0] / span[1] * 100)))),
        })
    return devices


def kscreen_outputs():
    code, out, _ = run(["kscreen-doctor", "-j"])
    if code != 0:
        return None
    try:
        data = json.loads(out)
    except ValueError:
        return None
    outputs = []
    for item in data.get("outputs") or []:
        value = item.get("brightness")
        if not item.get("enabled") or not isinstance(value, (int, float)):
            continue
        name = str(item.get("name") or "")
        if not re.fullmatch(r"[A-Za-z0-9_.-]+", name):
            continue
        outputs.append({
            "id": "kscreen:" + name,
            "label": name,
            "percent": max(0, min(100, int(round(value * 100 if value <= 1 else value)))),
        })
    return outputs


def do_list():
    devices = list_powerdevil()
    if devices:
        return {"backend": "powerdevil", "devices": devices}
    outputs = kscreen_outputs()
    if outputs:
        return {"backend": "kscreen", "devices": outputs}
    return {"backend": "", "devices": []}


def do_set(device, percent):
    percent = max(0, min(100, percent))
    kind, _, name = device.partition(":")
    if kind == "kde" and re.fullmatch(r"[A-Za-z0-9_]+", name):
        props = powerdevil_properties(name)
        span = powerdevil_range(props) if props else None
        if not span:
            return {"ok": False, "error": "Bildschirm nicht gefunden"}
        value = int(round(span[1] * percent / 100))
        reply, err = busctl("call", SERVICE, ROOT + "/" + name, DISPLAY_IFACE, "SetBrightness", "iu", str(value), "0")
        return {"ok": reply is not None, "error": err}
    if kind == "kscreen" and re.fullmatch(r"[A-Za-z0-9_.-]+", name):
        code, _, err = run(["kscreen-doctor", "output.%s.brightness.%d" % (name, percent)])
        return {"ok": code == 0, "error": err}
    return {"ok": False, "error": "unbekanntes Gerät"}


def main():
    args = sys.argv[1:]
    if args[:1] == ["list"]:
        result = do_list()
    elif args[:1] == ["set"] and len(args) == 3 and re.fullmatch(r"\d{1,3}", args[2]):
        result = do_set(args[1], int(args[2]))
    else:
        sys.stderr.write(__doc__)
        return 2
    json.dump(result, sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
