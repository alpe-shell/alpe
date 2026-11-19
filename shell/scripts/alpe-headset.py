#!/usr/bin/env python3
"""Akkustand kabelloser Headsets für Alpe.

UPower kennt Funk-Headsets mit eigenem USB-Empfänger nicht; ihr Akkustand lässt sich nur
über das herstellereigene HID-Protokoll lesen. Zwei freie Werkzeuge können das:

  headsetcontrol     (Sapd/HeadsetControl)        viele Hersteller
  hyper_headset_cli  (LennardKittner/HyperHeadset) HyperX, auch Cloud II Core Wireless

Dieses Programm fragt das erste vorhandene Werkzeug, das ein Gerät findet, und gibt eine
einheitliche Antwort auf der Standardausgabe aus:

  {"tool": "headsetcontrol", "tools": ["headsetcontrol"], "error": "",
   "devices": [{"name": "HyperX Cloud II Wireless", "percentage": 85,
                "charging": false, "state": "ok"}]}

state: ok | off (Headset ausgeschaltet oder ausser Reichweite) | error
error: "" | missing (kein Werkzeug installiert) | nodevice | Fehlermeldung des Werkzeugs
"""

import json
import os
import re
import shutil
import subprocess
import sys

TIMEOUT = 8
TOOLS = (
    ("headsetcontrol", ["headsetcontrol", "-b", "-o", "json"]),
    ("hyper_headset_cli", ["hyper_headset_cli", "--json"]),
)


def run(argv):
    try:
        proc = subprocess.run(argv, capture_output=True, text=True, timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        return None, "Zeitüberschreitung"
    except OSError as exc:
        return None, str(exc)
    return proc, ""


def clamp(value):
    try:
        number = int(round(float(value)))
    except (TypeError, ValueError):
        return -1
    return number if 0 <= number <= 100 else -1


def parse_headsetcontrol(text):
    data = json.loads(text)
    devices = []
    for dev in data.get("devices") or []:
        battery = dev.get("battery") or {}
        status = str(battery.get("status", ""))
        level = clamp(battery.get("level", -1))
        name = dev.get("device") or dev.get("product") or "Headset"
        # Ein ausgeschaltetes Headset meldet HeadsetControl als BATTERY_UNAVAILABLE mit Stand -1.
        if status == "BATTERY_CHARGING" or (status == "BATTERY_AVAILABLE" and level >= 0):
            state = "ok"
        elif status in ("BATTERY_ERROR", "BATTERY_TIMEOUT"):
            state = "error"
        else:
            state = "off"
        devices.append({
            "name": str(name),
            "percentage": level,
            "charging": status == "BATTERY_CHARGING",
            "state": state,
        })
    return devices


def walk(node, path=""):
    if isinstance(node, dict):
        for key, value in node.items():
            yield from walk(value, (path + "." + str(key)).lower())
    elif isinstance(node, list):
        for value in node:
            yield from walk(value, path)
    else:
        yield path, node


def truthy(value):
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return value != 0
    text = str(value).strip().lower()
    if text.startswith(("not", "no", "false", "dis", "0", "off", "unknown")):
        return False
    return text.startswith(("charging", "true", "yes", "1", "on", "full"))


def parse_generic(text):
    """HyperHeadset: Die JSON-Felder sind nicht dokumentiert, deshalb wird nach Bedeutung gesucht."""
    name, level, charging, connected = "", -1, False, True
    try:
        data = json.loads(text)
    except ValueError:
        data = None
    if data is not None:
        for path, value in walk(data):
            leaf = path.rsplit(".", 1)[-1]
            if value is None:
                continue
            if "charg" in leaf:
                charging = charging or truthy(value)
            elif "connect" in leaf:
                connected = truthy(value) if not isinstance(value, bool) else value
            elif "battery" in path and not re.search(r"volt|time|remain|status|state", leaf):
                if level < 0 and not isinstance(value, bool):
                    number = re.search(r"\d+(?:\.\d+)?", str(value))
                    if number:
                        level = clamp(number.group(0))
            elif leaf in ("name", "device", "device_name", "product", "product_name", "headset", "model") and isinstance(value, str) and not name:
                name = value.strip()
    else:
        match = re.search(r"battery[^\n\d]{0,40}?(\d{1,3})\s*%", text, re.I)
        if match:
            level = clamp(match.group(1))
        charging = bool(re.search(r"^(?!.*not).*charging", text, re.I | re.M)) and not re.search(r"not\s+charging|charging[^\n]*(false|no)\b", text, re.I)
        if re.search(r"not\s+connected|disconnected|no\s+(device|headset)", text, re.I):
            connected = False
        match = re.search(r"^(?:name|device|headset)\s*[:=]\s*(.+)$", text, re.I | re.M)
        if match:
            name = match.group(1).strip()
    if level < 0 and connected and data is None and not text.strip():
        return []
    state = "ok" if level >= 0 and connected else ("off" if not connected or level < 0 else "error")
    return [{
        "name": name or "HyperX-Headset",
        "percentage": level if connected else -1,
        "charging": bool(charging),
        "state": state,
    }]


USB_VENDORS = ("03f0", "0951")   # HP und Kingston: unter beiden gibt es HyperX-Empfänger


def usb_product_name(root="/sys/bus/usb/devices"):
    """Name des Empfängers, wie ihn der Rechner kennt (etwa «HyperX Cloud II Core Wireless»)."""
    try:
        entries = sorted(os.listdir(root))
    except OSError:
        return ""
    for entry in entries:
        base = os.path.join(root, entry)
        try:
            with open(os.path.join(base, "idVendor")) as handle:
                vendor = handle.read().strip().lower()
            with open(os.path.join(base, "product")) as handle:
                product = handle.read().strip()
        except OSError:
            continue
        if vendor in USB_VENDORS and "hyperx" in product.lower():
            return product
    return ""


def name_from_usb(devices):
    """HyperHeadset nennt das Gerät nicht; dann hilft der USB-Name weiter."""
    unnamed = [dev for dev in devices if dev.get("name") in ("", "HyperX-Headset")]
    if unnamed:
        product = usb_product_name(os.environ.get("ALPE_USB_ROOT", "/sys/bus/usb/devices"))
        if product:
            for dev in unnamed:
                dev["name"] = product
    return devices


PARSERS = {"headsetcontrol": parse_headsetcontrol, "hyper_headset_cli": parse_generic}


def query():
    present = [name for name, argv in TOOLS if shutil.which(argv[0])]
    result = {"tool": "", "tools": present, "error": "", "devices": []}
    if not present:
        result["error"] = "missing"
        return result
    last_error = "nodevice"
    for name, argv in TOOLS:
        if name not in present:
            continue
        proc, error = run(argv)
        if proc is None:
            last_error = error
            continue
        try:
            devices = PARSERS[name](proc.stdout)
        except (ValueError, AttributeError, TypeError):
            devices = []
            last_error = (proc.stderr or proc.stdout or "unlesbare Antwort").strip().splitlines()[-1][:200] if (proc.stderr or proc.stdout).strip() else "unlesbare Antwort"
        if devices:
            result["tool"] = name
            result["devices"] = name_from_usb(devices)
            return result
        if proc.returncode != 0 and (proc.stderr or "").strip():
            last_error = proc.stderr.strip().splitlines()[-1][:200]
    result["tool"] = present[0]
    result["error"] = last_error
    return result


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "--parse":
        # Für Tests: --parse <werkzeug> liest die Antwort des Werkzeugs von der Standardeingabe.
        json.dump(PARSERS[sys.argv[2]](sys.stdin.read()), sys.stdout, ensure_ascii=False)
        return 0
    os.environ.setdefault("LC_ALL", "C")
    json.dump(query(), sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
