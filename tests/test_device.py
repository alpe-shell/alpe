#!/usr/bin/env python3
"""Prüft quickshell/scripts/alpe-root.sh (Ladegrenze, Zuklappen) in einem Attrappen-Verzeichnis."""
import os
import subprocess
import sys
import tempfile

SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(os.path.expanduser("~"), "dux-shell")
SCRIPT = os.path.join(SHELL, "quickshell", "scripts", "alpe-root.sh")
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


root = tempfile.mkdtemp()
for name, kind in (("macsmc-battery", "Battery"), ("macsmc-ac", "Mains")):
    os.makedirs(f"{root}/sys/class/power_supply/{name}")
    open(f"{root}/sys/class/power_supply/{name}/type", "w").write(kind + "\n")
open(f"{root}/sys/class/power_supply/macsmc-battery/charge_control_end_threshold", "w").write("100\n")
env = dict(os.environ, ALPE_ROOT_PREFIX=root)
run = lambda *a: subprocess.run(["sh", SCRIPT] + list(a), env=env, capture_output=True, text=True)
read = lambda p: open(root + p).read().strip()

check(run("charge", "80").returncode == 0 and read("/sys/class/power_supply/macsmc-battery/charge_control_end_threshold") == "80", "Ladegrenze 80 % am Akku macsmc-battery")
unit = read("/etc/systemd/system/alpe-ladegrenze.service")
check(read("/etc/alpe/ladegrenze") == "80" and "$$b/charge_control_end_threshold" in unit, "beim Start wiederhergestellt; $$ für systemd")
check(not os.path.exists(f"{root}/sys/class/power_supply/macsmc-ac/charge_control_end_threshold"), "Netzteil bleibt unberührt")
check(run("charge", "100").returncode == 0 and not os.path.exists(f"{root}/etc/systemd/system/alpe-ladegrenze.service"), "100 %: Startdienst entfernt")
check(run("charge", "40").returncode == 2 and run("charge", "80; reboot").returncode == 2, "ungültige Werte abgewiesen")
check(run("lid", "suspend", "lock", "ignore").returncode == 0, "Zuklappen gesetzt")
conf = read("/etc/systemd/logind.conf.d/60-alpe-deckel.conf")
check("HandleLidSwitch=suspend" in conf and "HandleLidSwitchExternalPower=lock" in conf and "HandleLidSwitchDocked=ignore" in conf, "logind-Ergänzung geschrieben")
check(run("lid", "suspend", "rm", "ignore").returncode == 2, "ungültiges Verhalten abgewiesen")

print("\nalle Prüfungen bestanden" if failures == 0 else f"\n{failures} FEHLER")
sys.exit(1 if failures else 0)
