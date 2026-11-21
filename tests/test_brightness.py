"""Prüft scripts/alpe-brightness.py aus dem Shell-Code (Schicht 0010) gegen Attrappen.

    python3 tests/test_brightness.py         nimmt shell/ im Repository
"""
import json, os, stat, subprocess, sys, tempfile

SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "shell")
SCRIPT = os.path.join(SHELL, "scripts", "alpe-brightness.py")
if not os.path.exists(SCRIPT):
    print("übersprungen: %s fehlt" % SCRIPT); sys.exit(0)

BUSCTL = r'''
echo "$*" >> "$LOG"
case "$*" in
  *get-property*DisplaysDBusNames*) echo '{"type":"as","data":["display0","display1"]}' ;;
  *"/display0 org.freedesktop.DBus.Properties GetAll"*) echo '{"type":"a{sv}","data":[{"Label":{"type":"s","data":"Odyssey G85SD"},"Brightness":{"type":"i","data":7000},"MaxBrightness":{"type":"i","data":10000}}]}' ;;
  *"/display1 org.freedesktop.DBus.Properties GetAll"*) echo '{"type":"a{sv}","data":[{"Label":{"type":"s","data":"Zweit"},"Brightness":{"type":"i","data":40}}]}' ;;
  *SetBrightness*) echo '{"type":"","data":[]}' ;;
  *) exit 1 ;;
esac
'''
KSCREEN = r'''
echo "$*" >> "$LOG"
[ "$1" = "-j" ] && echo '{"outputs":[{"name":"DP-2","enabled":true,"brightness":0.8},{"name":"HDMI-A-1","enabled":false,"brightness":1}]}'
exit 0
'''
checks = 0
def expect(got, want, what):
    global checks
    assert got == want, "%s: %r statt %r" % (what, got, want)
    checks += 1

def session(tools):
    folder = tempfile.mkdtemp()
    for name, body in tools.items():
        path = os.path.join(folder, name)
        with open(path, "w") as handle:
            handle.write("#!/bin/sh\n" + body + "\n")
        os.chmod(path, os.stat(path).st_mode | stat.S_IEXEC)
    env = dict(os.environ, PATH=folder, LOG=os.path.join(folder, "log"))
    def call(*args):
        out = subprocess.run([sys.executable, SCRIPT, *args], capture_output=True, text=True, env=env)
        return json.loads(out.stdout)
    def log():
        with open(env["LOG"]) as handle:
            return handle.read().splitlines()
    return call, log

call, log = session({"busctl": BUSCTL})
res = call("list")
expect(res["backend"], "powerdevil", "Plasma gefunden")
expect([(d["id"], d["label"], d["percent"]) for d in res["devices"]], [("kde:display0", "Odyssey G85SD", 70), ("kde:display1", "Zweit", 40)], "Bildschirme und Prozentwerte (auch ohne MaxBrightness)")
expect(call("set", "kde:display0", "55")["ok"], True, "setzen")
expect(log()[-1].endswith("SetBrightness iu 5500 0"), True, "55 % von 10000 sind 5500")
expect(call("set", "kde:x;rm -rf", "10")["ok"], False, "unsaubere Gerätenamen abgewiesen")
expect(call("set", "kde:display9", "10")["ok"], False, "unbekannter Bildschirm")

call, log = session({"busctl": "exit 1", "kscreen-doctor": KSCREEN})
res = call("list")
expect((res["backend"], [(d["id"], d["percent"]) for d in res["devices"]]), ("kscreen", [("kscreen:DP-2", 80)]), "ohne Plasma-Dienst: kscreen-doctor, nur aktive Ausgänge")
expect(call("set", "kscreen:DP-2", "30")["ok"], True, "setzen über kscreen-doctor")
expect(log()[-1], "output.DP-2.brightness.30", "Aufruf von kscreen-doctor")

call, log = session({"busctl": "exit 1"})
expect(call("list"), {"backend": "", "devices": []}, "nichts vorhanden")
print("alle %d Prüfungen bestanden" % checks)
