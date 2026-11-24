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
import re
import shutil
import subprocess
import sys
import tempfile
import time

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

    def run(probe, offen=False):
        return subprocess.run([sys.executable, script, "-", fremd, "1" if probe else "0", session_1_0, "1" if offen else "0"],
                              env=env, capture_output=True, text=True)

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
          and session["wallpaperPath"] == "", "Probe: Session aus 1.0 (Version 7, Vorlage des Ursprungs) ohne Bild und Farbe, damit die Material-Vorlage gezeichnet wird")
    ebene = session["materialWallpaperProfiles"]["eigen"]["layers"][0]
    check(ebene["shape"] == "dankLogo" and all(k in ebene for k in ("x", "y", "size", "fill")), "Probe: eigenes Profil vollständig, Form noch die des Ursprungs")
    check(read(session_1_0)["wallpaperPath"] == "", "die Testdaten selbst bleiben unverändert")

    # Stand der Probe für die Auswertung weiter unten festhalten, bevor die Varianten die Dateien überschreiben.
    home = os.path.join(tmp, "home")
    os.makedirs(os.path.join(home, ".local", "state", "alpe"))
    os.makedirs(os.path.join(home, ".config", "alpe"))
    shutil.copy(os.path.join(config, "alpe", "settings.json"), os.path.join(home, ".config", "alpe", "settings.json"))
    shutil.copy(os.path.join(state, "alpe", "session.json"), os.path.join(home, ".local", "state", "alpe", "session.json"))

    # Variante «offen» (Plan 0.8 Nr. 70): ohne Sperre beim Start, Hintergrund leer. «gesperrt» lässt beides stehen.
    with open(os.path.join(config, "alpe", "settings.json"), "w") as handle:
        json.dump({"lockAtStartup": True, "barConfigs": [{"leftWidgets": [{"id": "workspaceSwitcher", "enabled": False},
                                                                          {"id": "launcherButton", "enabled": False}, {"id": "clock", "enabled": False}]}]}, handle)
    with open(os.path.join(state, "alpe", "session.json"), "w") as handle:
        json.dump({"wallpaperPath": "#101010", "monitorWallpapers": {"DP-1": "/bild.png"},
                   "materialWallpapers": {"": {"shared": {"preset": "alpe"}}}}, handle)
    out = run(False)
    check(out.returncode == 0 and read(config, "alpe", "settings.json")["lockAtStartup"] is True
          and read(state, "alpe", "session.json")["wallpaperPath"] == "#101010"
          and not any(w["enabled"] for w in read(config, "alpe", "settings.json")["barConfigs"][0]["leftWidgets"]),
          "gesperrt: Sperre beim Start, Hintergrund und Leiste bleiben wie im Design")
    out = run(False, offen=True)
    session = read(state, "alpe", "session.json")
    check(out.returncode == 0 and read(config, "alpe", "settings.json")["lockAtStartup"] is False, "offen: lockAtStartup ausgeschaltet")
    check(session["wallpaperPath"] == "" and session["monitorWallpapers"] == {} and session["materialWallpapers"][""]["shared"]["preset"] == "alpe",
          "offen: kein Bild und keine Farbe, die Material-Vorlage bleibt")
    check(read(config, "alpe", "settings.json")["barConfigs"][0]["leftWidgets"] ==
          [{"id": "workspaceSwitcher", "enabled": True}, {"id": "launcherButton", "enabled": True, "launcherLogoMode": "alpe"}, {"id": "clock", "enabled": False}],
          "offen: Abdeckungs-Zusätze – Arbeitsflächen-Anzeige und Starter-Knopf mit Logo-Modus alpe an, sonst nichts (0.8 Nr. 77)")
    check(lp.logo_mode() == "alpe" and lp.logo_mode(tmp) == "alpe", "Logo-Modus des Endstands ist alpe")
    skript = lp.session_script("/b", "/d", "/b/x.png")
    check("grim" not in skript and "screenshot full" in skript, "Bild: fester Weg alpe-dienst screenshot full, ohne grim (0.8 Nr. 71)")
    # «Weg A»: Unter KWin kommt das Bild über kwinbild.py von der Test-Instanz, nie vom Bus der echten Sitzung.
    echt = "unix:path=/run/user/%d/bus" % os.getuid()
    skript_kwin = lp.session_script("/b", "/d", "/b/x.png", kwin_scope="alpe-ladepruefung-1.scope", fremde_busse=[echt + ",guid=abc", ""])
    check("kwinbild.py" in skript_kwin and "screenshot full" not in skript_kwin and "--scope alpe-ladepruefung-1.scope" in skript_kwin
          and "--fremd " + lp.q(echt + ",guid=abc") in skript_kwin and skript_kwin.count("--fremd") == 1,
          "Bild unter KWin: kwinbild.py mit Scope und der Busadresse der echten Sitzung als fremd (befristet, nur KWin)")
    kb_spec = importlib.util.spec_from_file_location("kwinbild", os.path.join(os.path.dirname(lp.__file__), "kwinbild.py"))
    kb = importlib.util.module_from_spec(kb_spec)
    kb_spec.loader.exec_module(kb)
    test_bus = "unix:path=/tmp/dbus-AbCdEf,guid=0123"
    check(kb.adresse_pruefen(test_bus, [echt]) is None and kb.adresse_pruefen(test_bus, ["", "unix:path=/tmp/dbus-anders"]) is None,
          "kwinbild: eigener Bus der Test-Instanz wird angenommen")
    for lage, adresse, fremde in (("leer", "", []), ("gleich der Sitzung des Maintainers", "unix:path=/tmp/dbus-AbCdEf,guid=9", ["unix:path=/tmp/dbus-AbCdEf"]),
                                  ("gleich trotz anderer Schreibweise", "unix:path=/tmp//dbus-AbCdEf", ["unix:guid=7,path=/tmp/dbus-AbCdEf"]),
                                  ("Sitzungsbus unter /run/user, auch ohne --fremd", echt, []),
                                  ("abstrakter Name gleich", "unix:abstract=/tmp/dbus-x,guid=1", ["unix:abstract=/tmp/dbus-x"]),
                                  ("zwei Adressen", test_bus + ";unix:path=/tmp/dbus-zwei", []), ("kein Unix-Socket", "tcp:host=localhost,port=1", []),
                                  ("autolaunch", "autolaunch:", [])):
        check(kb.adresse_pruefen(adresse, fremde) is not None, "kwinbild bricht ab – Busadresse " + lage)
    proc_attrappe = os.path.join(tmp, "proc")
    for pid, pfad in ((11, "0::/user.slice/user-1000.slice/user@1000.service/app.slice/alpe-ladepruefung-1.scope\n"),
                      (12, "0::/user.slice/user-1000.slice/user@1000.service/session.slice/plasma-kwin_wayland.service\n"),
                      (13, "0::/user.slice/user-1000.slice/user@1000.service/app.slice/alpe-ladepruefung-10.scope\n")):
        os.makedirs(os.path.join(proc_attrappe, str(pid)))
        with open(os.path.join(proc_attrappe, str(pid), "cgroup"), "w") as handle:
            handle.write(pfad)
    check(kb.im_scope(11, "alpe-ladepruefung-1.scope", proc_attrappe) and not kb.im_scope(12, "alpe-ladepruefung-1.scope", proc_attrappe)
          and not kb.im_scope(13, "alpe-ladepruefung-1.scope", proc_attrappe) and not kb.im_scope(99, "alpe-ladepruefung-1.scope", proc_attrappe)
          and not kb.im_scope(11, "", proc_attrappe),
          "kwinbild: nur ein KWin im Scope der Ladeprüfung gilt (das KWin der Sitzung, ein anderer Scope, ein fehlender Prozess nicht)")
    ohne_bus = subprocess.run([sys.executable, kb.__file__, os.path.join(tmp, "k.png"), "--scope", "alpe-ladepruefung-1.scope"], capture_output=True,
                              text=True, env={k: v for k, v in os.environ.items() if k != "DBUS_SESSION_BUS_ADDRESS"})
    mit_echtem = subprocess.run([sys.executable, kb.__file__, os.path.join(tmp, "k.png"), "--scope", "alpe-ladepruefung-1.scope", "--fremd", "unix:path=/tmp/dbus-echt"],
                                capture_output=True, text=True, env=dict(os.environ, DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/dbus-echt,guid=1"))
    check(ohne_bus.returncode == 3 and mit_echtem.returncode == 3 and "ABBRUCH, kein Bild" in mit_echtem.stdout and not os.path.exists(os.path.join(tmp, "k.png")),
          "kwinbild als Programm: ohne Busadresse und mit der Adresse der echten Sitzung Abbruch (3), kein Bild, kein Busaufruf")
    # Jede Abbruchbedingung durch main() selbst (Plan 0.8 Nr. 103): Nur busctl ist eine Attrappe, /proc ein Temp-Ordner.
    # Die Attrappe schreibt jeden Aufruf mit; vor bestandener Prüfung darf CaptureWorkspace nie aufgerufen werden.
    import contextlib
    import io
    attrappen = os.path.join(tmp, "kb-bin")
    os.makedirs(attrappen)
    with open(os.path.join(attrappen, "busctl"), "w", encoding="utf-8") as handle:
        handle.write("""#!/bin/bash
echo "$*" >> "$KB_LOG"
case "$*" in
*GetConnectionUnixProcessID*)
    case "$KB_FALL" in
        kein-kwin) echo "Call failed: Could not get PID of name 'org.kde.KWin': no such name" >&2; exit 1 ;;
        fremd) echo '{"type":"u","data":[12]}' ;;
        *) echo '{"type":"u","data":[11]}' ;;
    esac ;;
*CaptureWorkspace*)
    case "$KB_FALL" in
        verweigert) echo "Call failed: The process is not authorized to take a screenshot" >&2; exit 1 ;;
        verweigert-name) echo "Call failed: org.kde.KWin.ScreenShot2.Error.NoAuthorized" >&2; exit 1 ;;
        gescheitert) echo "Call failed: etwas anderes" >&2; exit 1 ;;
        *) for letztes; do :; done
           printf '\\012\\024\\036\\377' >&"$letztes"
           echo '{"type":"a{sv}","data":[{"type":{"type":"s","data":"raw"},"format":{"type":"u","data":16},"width":{"type":"u","data":1},"height":{"type":"u","data":1},"stride":{"type":"u","data":4}}]}' ;;
    esac ;;
esac
""")
    os.chmod(os.path.join(attrappen, "busctl"), 0o755)
    kb_log = os.path.join(tmp, "kb-aufrufe.log")

    def kb_lauf(fall, adresse=test_bus, fremde=(echt,)):
        """kwinbild.main() mit der busctl-Attrappe: (Rückgabewert, Ausgabe, Aufrufe von busctl, Bild entstanden?)."""
        ziel = os.path.join(tmp, "kb-%s.png" % fall)
        alt = {name: os.environ.get(name) for name in ("PATH", "DBUS_SESSION_BUS_ADDRESS", "KB_FALL", "KB_LOG")}
        open(kb_log, "w").close()
        os.environ.update(PATH=attrappen + os.pathsep + alt["PATH"], DBUS_SESSION_BUS_ADDRESS=adresse, KB_FALL=fall, KB_LOG=kb_log)
        ausgabe = io.StringIO()
        try:
            with contextlib.redirect_stdout(ausgabe):
                code = kb.main(["kwinbild.py", ziel, "--scope", "alpe-ladepruefung-1.scope"] + [t for f in fremde for t in ("--fremd", f)], proc=proc_attrappe)
        finally:
            for name, wert in alt.items():
                if wert is None:
                    os.environ.pop(name, None)
                else:
                    os.environ[name] = wert
        with open(kb_log, encoding="utf-8") as handle:
            aufrufe = handle.read()
        return code, ausgabe.getvalue(), aufrufe, os.path.exists(ziel)

    code, text, aufrufe, da = kb_lauf("adresse-fremd", adresse=echt)
    check(code == 3 and "ABBRUCH, kein Bild" in text and aufrufe == "" and not da,
          "kwinbild main(): Adresse der echten Sitzung – Abbruch (3), busctl wird gar nicht aufgerufen")
    code, text, aufrufe, da = kb_lauf("adresse-sitzungsbus", adresse=echt, fremde=())
    check(code == 3 and "ABBRUCH, kein Bild" in text and aufrufe == "" and not da,
          "kwinbild main(): Sitzungsbus unter /run/user ohne --fremd – Abbruch (3) durch die eingebaute Regel, busctl wird nicht aufgerufen")
    for lage, adresse in (("zwei Adressen", test_bus + ";unix:path=/tmp/dbus-zwei"), ("kein Unix-Socket", "tcp:host=localhost,port=1"), ("autolaunch", "autolaunch:")):
        code, text, aufrufe, da = kb_lauf("adresse-uneindeutig", adresse=adresse)
        check(code == 3 and "nicht eindeutig" in text and aufrufe == "" and not da,
              "kwinbild main(): Busadresse nicht eindeutig (%s) – Abbruch (3), busctl wird nicht aufgerufen" % lage)
    code, text, aufrufe, da = kb_lauf("kein-kwin")
    check(code == 3 and "kein org.kde.KWin" in text and "CaptureWorkspace" not in aufrufe and "GetConnectionUnixProcessID" in aufrufe and not da,
          "kwinbild main(): an diesem Bus gibt es kein org.kde.KWin – Abbruch (3), keine Aufnahme")
    code, text, aufrufe, da = kb_lauf("fremd")
    check(code == 3 and "PID 12" in text and "nicht im Scope" in text and "CaptureWorkspace" not in aufrufe and not da,
          "kwinbild main(): KWin ausserhalb des Scopes (das der Sitzung) – Abbruch (3), keine Aufnahme")
    for fall in ("verweigert", "verweigert-name"):
        code, text, aufrufe, da = kb_lauf(fall)
        check(code == 3 and "ABBRUCH, kein Bild: KWin verweigert die Aufnahme" in text and "NoAuthorized" in text
              and "KWIN_SCREENSHOT_NO_PERMISSION_CHECKS" in text and not da,
              "kwinbild main(): KWin meldet NoAuthorized (%s) – Abbruch (3) mit klarer Meldung, kein Bild"
              % ("Fehlertext, wie busctl ihn ausgibt" if fall == "verweigert" else "Fehlername"))
    code, text, aufrufe, da = kb_lauf("gescheitert")
    check(code == 1 and text.startswith("FEHLER: CaptureWorkspace gescheitert") and not da, "kwinbild main(): anderer Fehler der Aufnahme bleibt ein Fehlschlag (1)")
    code, text, aufrufe, da = kb_lauf("gut")
    check(code == 0 and da and aufrufe.count("\n") == 2 and "CaptureWorkspace" in aufrufe,
          "kwinbild main(): Gegenprobe – KWin im Scope, Aufnahme erlaubt: Bild geschrieben (die Attrappe erreicht die Aufnahme also)")
    with open(kb.__file__, encoding="utf-8") as handle:
        kb_quelle = handle.read()
    with open(lp.__file__, encoding="utf-8") as handle:
        lp_quelle = handle.read()
    check("os.environ[" not in kb_quelle and "putenv" not in kb_quelle and not re.search(r"KWIN_SCREENSHOT_NO_PERMISSION_CHECKS\s*=", kb_quelle + lp_quelle)
          and "KWIN_SCREENSHOT_NO_PERMISSION_CHECKS" not in lp_quelle,
          "KWIN_SCREENSHOT_NO_PERMISSION_CHECKS wird nirgends gesetzt (auf KWin 6.8 wirkungslos, Plan 0.8 Nr. 103)")
    import struct
    import zlib
    roh = bytes([10, 20, 30, 255, 40, 50, 60, 255, 0, 0, 0, 0]) + bytes([70, 80, 90, 255, 1, 2, 3, 255, 0, 0, 0, 0])   # 2 × 2, Zeilenlänge 12
    bild_rgbx, bild_bgrx = kb.png(2, 2, 12, 16, roh), kb.png(2, 2, 12, 4, roh)
    def punkte(datei):
        idat = datei[datei.index(b"IDAT") + 4:datei.index(b"IEND") - 8]
        return zlib.decompress(idat)
    check(bild_rgbx[:8] == b"\x89PNG\r\n\x1a\n" and struct.unpack(">II", bild_rgbx[16:24]) == (2, 2)
          and punkte(bild_rgbx) == bytes([0, 10, 20, 30, 40, 50, 60, 0, 70, 80, 90, 1, 2, 3])
          and punkte(bild_bgrx) == bytes([0, 30, 20, 10, 60, 50, 40, 0, 90, 80, 70, 3, 2, 1]),
          "kwinbild: Rohdaten RGBX und BGRX werden zu einem PNG mit richtiger Farbreihenfolge, Füllbytes der Zeile fallen weg")
    aufruf = subprocess.run([sys.executable, lp.__file__, "kwin", "--offen", "--bild-sperre", os.path.join(tmp, "x.png")], capture_output=True, text=True)
    check(aufruf.returncode == 2 and "gesperrt" in aufruf.stdout + aufruf.stderr, "--bild-sperre mit --offen wird abgelehnt")
    # Unter KWin gibt es kein Bild der Sperre (dort sperrt KDE): Abbruch mit Begründung, bevor etwas gebaut oder gestartet wird.
    sperre_kwin = os.path.join(tmp, "sperre-kwin.png")
    aufruf = subprocess.run([sys.executable, lp.__file__, "kwin", "--bild-sperre", sperre_kwin], capture_output=True, text=True)
    ausgabe = aufruf.stdout + aufruf.stderr
    check(aufruf.returncode == 2 and "--bild-sperre gibt es unter KWin nicht" in ausgabe and "--no-lockscreen" in ausgabe and "hyprland --bild-sperre" in ausgabe
          and "Dienst bauen" not in ausgabe and "== Lauf" not in ausgabe and not os.path.exists(sperre_kwin),
          "--bild-sperre unter KWin bricht mit klarer Meldung ab: kein Bau, kein Lauf, kein Bild (statt des Schreibtischs)")
    aufruf = subprocess.run([sys.executable, lp.__file__, "kwin", "--bild", os.path.join(tmp, "x.png")], capture_output=True, text=True)
    check(aufruf.returncode == 2 and "--offen" in aufruf.stdout + aufruf.stderr, "--bild ohne --offen wird abgelehnt")
    # Probe für das Papierkorb-Symbol im Dock: nur mit Schalter liegt etwas im Papierkorb des Temp-HOME.
    schalter = os.environ.pop("ALPE_LP_PAPIERKORB", None)
    try:
        leer = lp.runner_script("/b", "kwin", "/b/sb", "/b/sitzung.sh")
        os.environ["ALPE_LP_PAPIERKORB"] = "voll"
        voll = lp.runner_script("/b", "kwin", "/b/sb", "/b/sitzung.sh")
        check("Trash" not in leer and '"$XDG_DATA_HOME/Trash/files/probe.txt"' in voll and "probe.txt.trashinfo" in voll
              and voll.index("Trash/files") < voll.index("kwin_wayland"),
              "ALPE_LP_PAPIERKORB=voll legt vor dem Start eine Datei in den Papierkorb des Temp-HOME, ohne Schalter nichts")
        aufruf = subprocess.run([sys.executable, lp.__file__, "kwin", "--grundlinie"], capture_output=True, text=True, env=dict(os.environ))
        check(aufruf.returncode == 2 and "ALPE_LP_PAPIERKORB" in aufruf.stdout + aufruf.stderr, "mit vollem Papierkorb wird keine Grundlinie geschrieben")
    finally:
        os.environ.pop("ALPE_LP_PAPIERKORB", None)
        if schalter is not None:
            os.environ["ALPE_LP_PAPIERKORB"] = schalter

    # Sporadische Meldungen in der Grundlinie (Plan 0.8 Nr. 76).
    text = lp.baseline_text({"WARN immer": 3, "WARN manchmal": 1}, 3)
    check(text == "WARN immer\nSPORADISCH 1/3: WARN manchmal\n", "Grundlinie kennzeichnet, was nicht in jedem Lauf vorkam, mit der Häufigkeit")
    fest, sporadisch = lp.read_baseline("# Kopf\n" + text + "\n")
    check(fest == {"WARN immer"} and sporadisch == {"WARN manchmal": "1/3"}, "Grundlinie lesen: feste und sporadische Meldungen getrennt")
    check(lp.compare({"WARN immer"}, fest, sporadisch) == ([], [], []), "eine sporadische Meldung darf fehlen")
    check(lp.compare({"WARN immer", "WARN manchmal", "WARN fremd"}, fest, sporadisch) == (["WARN fremd"], [], ["WARN manchmal"]),
          "eine sporadische Meldung darf auftreten und ist nicht neu; eine fremde ist neu")
    check(lp.compare(set(), fest, sporadisch) == ([], ["WARN immer"], []), "eine feste Meldung, die fehlt, ist weg")

    # Hyprland-IPC: zu langer Temp-Ordner wird abgelehnt, ein Lauf ohne Sockets gilt als gescheitert.
    check(not lp.socket_path_too_long("/tmp") and not lp.socket_path_too_long("/tmp/claude-1000") and lp.socket_path_too_long("/tmp/claude-1000/h7/lp"),
          "Länge des Socket-Pfads: /tmp und /tmp/claude-1000 gehen, ein tieferer Ordner nicht")
    if shutil.which("kwin_wayland") and shutil.which("Hyprland"):
        lang = subprocess.run([sys.executable, lp.__file__, "hyprland"], capture_output=True, text=True,
                              env=dict(os.environ, ALPE_LP_TMP=os.path.join(tmp, "ein-langer-ordner")))
        check(lang.returncode == 2 and "zu lang" in lang.stdout, "hyprland mit zu langem $ALPE_LP_TMP bricht vor dem Start ab")
    gut = {"abbruch": "", "hung": False, "limit": 1, "shell.log": "Configuration Loaded\nbackend ready\n INFO ShellBackend: Connected (API v2, CLI 1.1) - []\n", "ipc.log": "--- bereit\nEnde nach Plan\n",
           "compositor": "hyprland", "umgebung.log": "HYPRLAND_INSTANCE_SIGNATURE=abc_1_2\nXDG_RUNTIME_DIR=/r\nSocket .socket.sock da\nSocket .socket2.sock da\n"}
    check(lp.health(gut) == [], "Lauf unter Hyprland mit Signatur und beiden Sockets ist in Ordnung")
    check(len(lp.health(dict(gut, **{"umgebung.log": "HYPRLAND_INSTANCE_SIGNATURE=abc\nSocket .socket.sock da\nSocket .socket2.sock fehlt\n"}))) == 1,
          "fehlender Socket beim Start der Shell: Lauf gescheitert")
    check(len(lp.health(dict(gut, **{"umgebung.log": "HYPRLAND_INSTANCE_SIGNATURE=\nSocket .socket.sock fehlt\nSocket .socket2.sock fehlt\n"}))) == 2,
          "fehlende Signatur: Lauf gescheitert")
    check(len(lp.health(dict(gut, **{"shell.log": gut["shell.log"] + "WARN quickshell.hyprland.ipc: Error making request: QLocalSocket::ServerNotFoundError\n"}))) == 1,
          "ServerNotFoundError der Shell: Lauf gescheitert, nichts für die Grundlinie")
    check(lp.health(dict(gut, compositor="kwin", **{"umgebung.log": ""})) == [], "unter KWin spielt das keine Rolle")
    # Mit Verbindung zum Dienst erscheinen dessen Fehlermeldungen; die Nummer der Anfrage darf den Vergleich nicht stören.
    check(lp.normalize("ERROR  go: ipc error: id=1795378623798 method-error=loginctl manager not initialized", "/x")
          == lp.normalize("ERROR  go: ipc error: id=17 method-error=loginctl manager not initialized", "/x")
          == "ERROR  go: ipc error: id=<ID> method-error=loginctl manager not initialized", "Nummer der Anfrage in Fehlermeldungen des Dienstes wird ausgeblendet")
    # Laufabhängige Nummern in sporadischen Meldungen: Zeitstempel im Namen eines Notizblock-Reiters, Nummer eines QML-Typs.
    check(lp.normalize("WARN qml: [NotepadStorageService:196] Tab file does not exist: /x/.local/state/alpe/notepad-files/untitled-1795381314052.txt", "/x")
          == "WARN qml: [NotepadStorageService:<Z>] Tab file does not exist: <TMP>/.local/state/alpe/notepad-files/untitled-<ID>.txt",
          "Zeitstempel im Namen eines Notizblock-Reiters wird ausgeblendet")
    check(lp.normalize("WARN scene: @Common/DeferredAction.qml[47:22]: TypeError: Property 'flush' of object DeferredAction_QMLTYPE_382(0x55aa) is not a function", "/x")
          == "WARN scene: @Common/DeferredAction.qml[<Z>]: TypeError: Property 'flush' of object DeferredAction_QMLTYPE_<N>(0x…) is not a function",
          "Nummer eines QML-Typs wird ausgeblendet")
    for name in ("grundlinie-hyprland.txt", "grundlinie-hyprland-offen.txt", "grundlinie-kwin.txt", "grundlinie-kwin-offen.txt"):
        text = open(os.path.join(os.path.dirname(lp.__file__), name), encoding="utf-8").read()
        check(not re.search(r"untitled-\d|_QMLTYPE_\d", text), name + ": keine laufabhängigen Nummern")
    # Verbindung zum Dienst (Plan 0.8 Nr. 81): ohne «Connected» ist der Lauf gescheitert, unter beiden Compositors.
    for compositor in ("kwin", "hyprland"):
        ohne = lp.health(dict(gut, compositor=compositor, **{"shell.log": "Configuration Loaded\nbackend ready\n"}))
        check(len(ohne) == 1 and "Connected" in ohne[0], "%s: Lauf ohne «Connected (API v…)» gilt als gescheitert" % compositor)
    # Der Ersatz-Systembus muss antworten: Ohne die receive-Regeln wartet ein Client endlos auf die Antwort zu «Hello».
    check('<type>system</type>' in lp.SYSTEMBUS and all(regel in lp.SYSTEMBUS for regel in (
        '<allow user="*"/>', '<allow send_destination="*"/>', '<allow receive_type="method_return"/>', '<allow receive_type="error"/>',
        '<allow receive_type="signal"/>', '<allow send_requested_reply="true" send_type="method_return"/>')),
        "Richtlinie des Ersatz-Systembusses erlaubt Antworten")
    # Gegenprobe mit stummem Bus (Plan 0.8 Nr. 84): eigene Richtlinie ohne Antwort-Regeln, nur über den Schalter;
    # bestanden ist sie, wenn der Dienst den Ausfall genau einmal meldet.
    check("receive_type" not in lp.SYSTEMBUS_STUMM and '<type>system</type>' in lp.SYSTEMBUS_STUMM, "stumme Richtlinie erlaubt keine Antworten")
    schalter = os.environ.pop("ALPE_LP_STUMMER_BUS", None)
    check(not lp.stummer_bus(), "ohne Schalter antwortet der Ersatz-Systembus")
    os.environ["ALPE_LP_STUMMER_BUS"] = "1"
    check(lp.stummer_bus(), "ALPE_LP_STUMMER_BUS=1 schaltet die Gegenprobe ein")
    if schalter is None:
        del os.environ["ALPE_LP_STUMMER_BUS"]
    else:
        os.environ["ALPE_LP_STUMMER_BUS"] = schalter
    meldung = " WARN go: System bus unavailable (system bus unavailable: no answer within 3s); dependent managers disabled, retrying in background\n"
    check(lp.stumm_probleme({"shell.log": gut["shell.log"] + meldung}) == [], "Gegenprobe: Ausfall einmal gemeldet")
    check(len(lp.stumm_probleme({"shell.log": gut["shell.log"]})) == 1 and len(lp.stumm_probleme({"shell.log": gut["shell.log"] + meldung * 2})) == 1,
          "Gegenprobe: keine oder mehrfache Meldung gilt als gescheitert")
    if shutil.which("dbus-daemon") and shutil.which("dbus-send"):
        # Echte Probe im Temp-Ordner: Der Bus beendet sich über timeout selbst, beendet wird nichts über Namen.
        kurz = tempfile.mkdtemp(prefix="sb")
        sock = os.path.join(kurz, "sb")
        with open(os.path.join(kurz, "systembus.conf"), "w") as handle:
            handle.write(lp.SYSTEMBUS.format(sock=sock))
        bus = subprocess.Popen(["timeout", "10", "dbus-daemon", "--config-file=" + os.path.join(kurz, "systembus.conf"), "--nofork"],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(50):
            if os.path.exists(sock):
                break
            time.sleep(0.1)
        antwort = subprocess.run(["timeout", "5", "dbus-send", "--bus=unix:path=" + sock, "--print-reply", "--reply-timeout=3000",
                                  "--dest=org.freedesktop.DBus", "/", "org.freedesktop.DBus.ListNames"], capture_output=True, text=True)
        bus.terminate()
        bus.wait()
        shutil.rmtree(kurz, ignore_errors=True)
        check(antwort.returncode == 0 and "org.freedesktop.DBus" in antwort.stdout, "Ersatz-Systembus antwortet auf einen Aufruf\n" + antwort.stdout + antwort.stderr)

    # Testkonfiguration für Hyprland: ohne Logo, ohne Hinweisbalken zum Start ohne start-hyprland (er läge im Bild).
    hypr = os.path.join(tmp, "hypr")
    os.makedirs(hypr)
    lp.hyprland_files(hypr, "/bin/true")
    with open(os.path.join(hypr, "hyprland.lua"), encoding="utf-8") as handle:
        lua = handle.read()
    check("disable_watchdog_warning = true" in lua and "disable_hyprland_logo = true" in lua and 'hl.exec_cmd("/bin/true")' in lua,
          "Hyprland-Testkonfiguration schaltet Logo und Hinweisbalken ab und startet die Session")
    check(os.access(os.path.join(hypr, "hyprland-start.sh"), os.X_OK), "Startskript für Hyprland ist ausführbar")

    # Auswertung nach dem Lauf: erkennt eine umgezogene und eine nicht umgezogene Session.
    check(any(line.startswith("FEHLER") for line in lp.probe_report(home)), "Auswertung meldet eine Session, die nicht umgezogen ist")
    migrated = {"configVersion": 8, "materialWallpapers": {"": {"shared": {"preset": "alpe"}}},
                "materialWallpaperProfiles": {"eigen": {"name": "dank", "layers": [{"shape": "alpeLogo"}]}}}
    with open(os.path.join(home, ".local", "state", "alpe", "session.json"), "w") as handle:
        json.dump(migrated, handle)
    open(os.path.join(home, ".local", "state", "alpe", "session.v7.json"), "w").write("{}")
    report = lp.probe_report(home)
    check(len(report) == 3 and all(line.startswith("ok") for line in report), "Auswertung bestätigt Umzug, Sicherung und Logo-Modus")
finally:
    shutil.rmtree(tmp, ignore_errors=True)

print("\nalle Prüfungen bestanden" if failures == 0 else f"\n{failures} FEHLER")
sys.exit(1 if failures else 0)
