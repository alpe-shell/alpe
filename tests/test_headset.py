"""Prüft scripts/alpe-headset.py aus dem Shell-Code (Schicht 0005).

    python3 tests/test_headset.py            nimmt shell/ im Repository
    ALPE_SHELL_DIR=/pfad/zur/shell python3 tests/test_headset.py
"""
import json, os, stat, subprocess, sys, tempfile

SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "shell")
SCRIPT = os.path.join(SHELL, "scripts", "alpe-headset.py")
if not os.path.exists(SCRIPT):
    print("übersprungen: %s fehlt" % SCRIPT); sys.exit(0)

def parse(tool, text):
    out = subprocess.run([sys.executable, SCRIPT, "--parse", tool], input=text, capture_output=True, text=True, check=True)
    return json.loads(out.stdout)

def query(tools, usb=None):
    with tempfile.TemporaryDirectory() as folder:
        for name, body in tools.items():
            path = os.path.join(folder, name)
            with open(path, "w") as handle:
                handle.write("#!/bin/sh\n" + body + "\n")
            os.chmod(path, os.stat(path).st_mode | stat.S_IEXEC)
        env = dict(os.environ, PATH=folder, ALPE_USB_ROOT=os.path.join(folder, "usb"))
        for index, (vendor, product) in enumerate(usb or []):
            base = os.path.join(folder, "usb", "1-%d" % index)
            os.makedirs(base)
            with open(os.path.join(base, "idVendor"), "w") as handle:
                handle.write(vendor + "\n")
            with open(os.path.join(base, "product"), "w") as handle:
                handle.write(product + "\n")
        out = subprocess.run([sys.executable, SCRIPT], capture_output=True, text=True, env=env, check=True)
        return json.loads(out.stdout)

HC = '{"name":"HeadsetControl","api_version":"1.9","device_count":1,"devices":[{"status":"%s","device":"HyperX Cloud II Wireless","battery":{"status":"%s","level":%d}}]}'
checks = 0
def expect(got, want, what):
    global checks
    assert got == want, "%s: %r statt %r" % (what, got, want)
    checks += 1

dev = parse("headsetcontrol", HC % ("success", "BATTERY_AVAILABLE", 85))[0]
expect((dev["name"], dev["percentage"], dev["charging"], dev["state"]), ("HyperX Cloud II Wireless", 85, False, "ok"), "HeadsetControl verfügbar")
dev = parse("headsetcontrol", HC % ("success", "BATTERY_CHARGING", 40))[0]
expect((dev["percentage"], dev["charging"], dev["state"]), (40, True, "ok"), "HeadsetControl lädt")
dev = parse("headsetcontrol", HC % ("partial", "BATTERY_UNAVAILABLE", -1))[0]
expect((dev["percentage"], dev["state"]), (-1, "off"), "HeadsetControl ausgeschaltet")
expect(parse("headsetcontrol", '{"device_count":0}'), [], "HeadsetControl ohne Gerät")

dev = parse("hyper_headset_cli", '{"device_name":"HyperX Cloud II Core Wireless","battery_level":72,"charging":false,"connected":true}')[0]
expect((dev["name"], dev["percentage"], dev["charging"], dev["state"]), ("HyperX Cloud II Core Wireless", 72, False, "ok"), "HyperHeadset flach")
dev = parse("hyper_headset_cli", '{"headset":{"name":"Core","battery":{"level":"64%","charging":"Charging","voltage":3900}}}')[0]
expect((dev["percentage"], dev["charging"]), (64, True), "HyperHeadset verschachtelt")
dev = parse("hyper_headset_cli", '{"battery_level":null,"connected":false}')[0]
expect((dev["percentage"], dev["state"]), (-1, "off"), "HyperHeadset getrennt")
dev = parse("hyper_headset_cli", "Battery level: 55%\nCharging status: Not charging\n")[0]
expect((dev["percentage"], dev["charging"]), (55, False), "HyperHeadset Text")
expect(parse("hyper_headset_cli", ""), [], "HyperHeadset leer")

res = query({})
expect((res["error"], res["devices"]), ("missing", []), "kein Werkzeug")
res = query({"headsetcontrol": "echo '%s'" % (HC % ("success", "BATTERY_AVAILABLE", 61))})
expect((res["tool"], res["devices"][0]["percentage"]), ("headsetcontrol", 61), "nur HeadsetControl")
res = query({"headsetcontrol": "echo '{\"device_count\":0,\"devices\":[]}'", "hyper_headset_cli": "echo '{\"battery_level\": 33, \"charging\": true}'"})
expect((res["tool"], res["devices"][0]["percentage"], res["devices"][0]["charging"]), ("hyper_headset_cli", 33, True), "Ausweichen auf HyperHeadset")
res = query({"headsetcontrol": "echo 'No supported device found' >&2; exit 1"})
expect((res["devices"], res["error"]), ([], "No supported device found"), "Fehlermeldung durchgereicht")
nameless = {"hyper_headset_cli": "echo '{\"battery_level\": 63, \"charging\": false}'"}
res = query(nameless, usb=[("1d6b", "xHCI Host Controller"), ("03f0", "HyperX Cloud II Core Wireless")])
expect(res["devices"][0]["name"], "HyperX Cloud II Core Wireless", "Name vom USB-Empfänger")
res = query(nameless, usb=[("046d", "USB Receiver")])
expect(res["devices"][0]["name"], "HyperX-Headset", "ohne passenden Empfänger bleibt der Ersatzname")
print("alle %d Prüfungen bestanden" % checks)
