#!/usr/bin/env python3
"""Alpe: Vorbereitung der Ladeprüfung (Plan 0.8 Nr. 29, 33, 41, 45).

Im Temp-HOME der Ladeprüfung werden alle Plugins unter plugins/ eingeschaltet, zusätzliche
Plugin-Kopien (--plugins) mitgenommen und für die Probe (--probe-zeichen) der Starter-Knopf mit dem
Logo-Modus "alpe" und eine Session aus 1.0 mit der Material-Vorlage eingerichtet. Der Test führt
nur diese Vorbereitung aus, in einem eigenen Temp-Ordner; die Shell startet er nicht.
"""
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


spec = importlib.util.spec_from_file_location("ladepruefung", os.path.join(REPO, "entwicklung", "ladepruefung", "ladepruefung.py"))
lp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lp)

tmp = tempfile.mkdtemp(prefix="alpe-lp-test-")
try:
    config, state = os.path.join(tmp, "config"), os.path.join(tmp, "state")
    plugins = os.path.join(config, "alpe", "plugins")
    shutil.copytree(os.path.join(REPO, "plugins"), plugins)
    with open(os.path.join(config, "alpe", "plugin_settings.json"), "w") as handle:
        json.dump({"alpeSport": {"enabled": False, "x": 1}}, handle)   # bewusst aus – in der Prüfung trotzdem an
    with open(os.path.join(config, "alpe", "settings.json"), "w") as handle:
        json.dump({"barConfigs": [{"leftWidgets": [{"id": "launcherButton", "enabled": False, "launcherLogoMode": "os"}, {"id": "clock"}]}]}, handle)
    fremd = os.path.join(tmp, "quelle", "fremdesPlugin")
    os.makedirs(os.path.join(fremd, ".git"))
    with open(os.path.join(fremd, "plugin.json"), "w") as handle:
        json.dump({"id": "fremdesPlugin", "name": "Fremd"}, handle)
    script = os.path.join(tmp, "vorbereitung.py")
    with open(script, "w", encoding="utf-8") as handle:
        handle.write(lp.VORBEREITUNG)
    session_1_0 = os.path.join(REPO, "tests", "data", "einstellungen-1.0", "session.json")
    env = dict(os.environ, XDG_CONFIG_HOME=config, XDG_STATE_HOME=state)

    def run(probe):
        return subprocess.run([sys.executable, script, "-", fremd, "1" if probe else "0", session_1_0], env=env, capture_output=True, text=True)

    def read(*parts):
        with open(os.path.join(*parts), encoding="utf-8") as handle:
            return json.load(handle)

    out = run(False)
    check(out.returncode == 0, "Vorbereitung läuft durch" + ("" if out.returncode == 0 else ": " + out.stderr[-300:]))
    settings = read(config, "alpe", "plugin_settings.json")
    repo_ids = sorted(read(REPO, "plugins", name, "plugin.json")["id"] for name in os.listdir(os.path.join(REPO, "plugins"))
                      if os.path.isfile(os.path.join(REPO, "plugins", name, "plugin.json")))
    check(len(repo_ids) >= 4 and all(settings.get(i, {}).get("enabled") is True for i in repo_ids),
          "alle Plugins unter plugins/ sind eingeschaltet: " + ", ".join(repo_ids))
    check(settings["alpeSport"].get("x") == 1, "übrige Einstellungen eines Plugins bleiben")
    check(settings.get("fremdesPlugin", {}).get("enabled") is True and os.path.isfile(os.path.join(plugins, "fremdesPlugin", "plugin.json")),
          "zusätzliches Plugin kopiert und eingeschaltet")
    check(not os.path.exists(os.path.join(plugins, "fremdesPlugin", ".git")), "ohne .git kopiert")
    check(read(config, "alpe", "settings.json")["barConfigs"][0]["leftWidgets"][0]["launcherLogoMode"] == "os"
          and not os.path.exists(os.path.join(state, "alpe", "session.json")), "ohne Probe bleiben Einstellungen und Session unberührt")

    out = run(True)
    knopf = read(config, "alpe", "settings.json")["barConfigs"][0]["leftWidgets"][0]
    check(out.returncode == 0 and knopf == {"id": "launcherButton", "enabled": True, "launcherLogoMode": "alpe"},
          "Probe: Starter-Knopf eingeschaltet mit Logo-Modus alpe")
    session = read(state, "alpe", "session.json")
    check(session.get("configVersion") == 7 and session["materialWallpapers"][""]["shared"]["preset"] == "dank"
          and session["wallpaperPath"].startswith("#"), "Probe: Session aus 1.0 (Version 7, Vorlage des Ursprungs) mit einfarbigem Hintergrund")
    check(read(session_1_0)["wallpaperPath"] == "", "die Testdaten selbst bleiben unverändert")

    # Auswertung nach dem Lauf: erkennt eine umgezogene und eine nicht umgezogene Session.
    home = os.path.join(tmp, "home")
    os.makedirs(os.path.join(home, ".local", "state", "alpe"))
    os.makedirs(os.path.join(home, ".config", "alpe"))
    shutil.copy(os.path.join(config, "alpe", "settings.json"), os.path.join(home, ".config", "alpe", "settings.json"))
    shutil.copy(os.path.join(state, "alpe", "session.json"), os.path.join(home, ".local", "state", "alpe", "session.json"))
    check(any(line.startswith("FEHLER") for line in lp.probe_report(home)), "Auswertung meldet eine Session, die nicht umgezogen ist")
    migrated = {"configVersion": 8, "materialWallpapers": {"": {"shared": {"preset": "alpe"}}},
                "materialWallpaperProfiles": {"eigen": {"layers": [{"shape": "alpeLogo"}]}}}
    with open(os.path.join(home, ".local", "state", "alpe", "session.json"), "w") as handle:
        json.dump(migrated, handle)
    open(os.path.join(home, ".local", "state", "alpe", "session.v7.json"), "w").write("{}")
    report = lp.probe_report(home)
    check(len(report) == 3 and all(line.startswith("ok") for line in report), "Auswertung bestätigt Umzug, Sicherung und Logo-Modus")
finally:
    shutil.rmtree(tmp, ignore_errors=True)

print("\nalle Prüfungen bestanden" if failures == 0 else f"\n{failures} FEHLER")
sys.exit(1 if failures else 0)
