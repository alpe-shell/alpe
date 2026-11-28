#!/usr/bin/env python3
"""Alpe: Befehl «alpe» – Dienst, Neustart, Protokoll, Sperren (E4.1; Nachtlauf vom 27.11.2026, Teil 3).

    python3 tests/test_alpe_befehl.py

Prüft tools/alpe in einem Temp-Ordner, nie gegen das laufende System: eigenes HOME, eigenes XDG_RUNTIME_DIR, ohne
Session-Bus und Display. Fremde Programme kommen über Variablen (ALPE_SYSTEMCTL, ALPE_JOURNALCTL, ALPE_LOGINCTL,
ALPE_DIENST; Muster tests/data/kwinstub) als Attrappen, die jeden Aufruf in eine Liste schreiben. Vorne im PATH liegen
zusätzlich Fallen unter den echten Namen (systemctl, journalctl, loginctl, qdbus6, pacman, dnf, sudo, alpe-dienst und
der Dienst von 1.0): Erreicht ein Aufruf eine Falle, ist der Test rot.

Geprüft: «alpe restart» startet alpe.service neu, wenn die Unit nicht «inactive» ist (auch «failed»), bei «inactive»
die eigene Instanz über «alpe-dienst restart» (Plan 6.8), und bricht ab, wenn die Shell von 1.0 läuft und alpe.service
nicht «active» ist (E4.1b); «alpe log» liest das Journal von alpe.service; «alpe lock» unter KDE über logind;
übrige Befehle gehen an den Dienst – aus ALPE_DIENST, sonst neben dem eigenen Ort (<PREFIX>/bin, wenn das Werkzeug aus
<PREFIX>/share/alpe läuft), nie an den Dienst von 1.0. «alpe test» meldet im Paket (ohne tools/test.sh daneben) «nur im
Repository» mit Rückgabewert ungleich 0 (E4.4, Plan 0.8 Nr. 125 (2)).
"""
import os
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ALPE = os.path.join(REPO, "tools", "alpe")
failures = 0


def check(cond, msg, extra=None):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    if not cond and extra is not None:
        print("       " + str(extra)[-1500:])
    failures += 0 if cond else 1


tmp = tempfile.mkdtemp(prefix="alpe-test-befehl-")
try:
    heim = os.path.join(tmp, "heim")
    lauf = os.path.join(heim, "run")
    for d in (".config", ".local/share", ".local/state", ".cache"):
        os.makedirs(os.path.join(heim, d))
    os.makedirs(lauf, mode=0o700)
    liste = os.path.join(tmp, "aufrufe.txt")
    stubs = os.path.join(tmp, "stubs")
    fallen = os.path.join(tmp, "fallen")
    os.makedirs(stubs)
    os.makedirs(fallen)

    def skript(pfad, rumpf):
        with open(pfad, "w", encoding="utf-8") as handle:
            handle.write("#!/bin/sh\n" + rumpf)
        os.chmod(pfad, 0o755)

    # Attrappen: Aufruf protokollieren. systemctl: «show -p ActiveState --value alpe.service» gibt $ATTRAPPE_ZUSTAND aus
    # (Vorgabe inactive), «is-active» auf den Dienst von 1.0 antwortet nach $ATTRAPPE_ALT, jedes andere «is-active» nach
    # $ATTRAPPE_AKTIV (0 = aktiv, Vorgabe 3)
    # alpe-namen-ausnahme: umzug-ende – Unit von 1.0 in der Attrappe
    antwort_systemctl = ('case "$*" in\n'
                         '*"show -p ActiveState --value alpe.service"*) echo "${ATTRAPPE_ZUSTAND-inactive}" ;;\n'
                         '*"is-active --quiet dms.service"*) exit "${ATTRAPPE_ALT:-3}" ;;\n'
                         '*is-active*) exit "${ATTRAPPE_AKTIV:-3}" ;;\n'
                         'esac\n')
    # alpe-namen-ausnahme: umzug-ende
    for name in ("systemctl", "journalctl", "loginctl", "alpe-dienst"):
        skript(os.path.join(stubs, name),
               'echo "%s $*" >> "%s"\n' % (name, liste)
               + (antwort_systemctl if name == "systemctl" else "")
               + "exit 0\n")
    # alpe-namen-ausnahme: umzug-ende – Falle unter dem Namen des Dienstes von 1.0
    for name in ("systemctl", "journalctl", "loginctl", "qdbus6", "pacman", "dnf", "sudo", "alpe-dienst", "dms"):
        skript(os.path.join(fallen, name), 'echo "FALLE %s $*" >> "%s"\nexit 1\n' % (name, liste))
    # alpe-namen-ausnahme: umzug-ende

    basis = {k: v for k, v in os.environ.items() if k not in ("DBUS_SESSION_BUS_ADDRESS", "WAYLAND_DISPLAY", "DISPLAY",
                                                              "ALPE_SHELL_DIR", "ALPE_DIENST", "XDG_CURRENT_DESKTOP")}
    basis.update(HOME=heim, XDG_CONFIG_HOME=heim + "/.config", XDG_DATA_HOME=heim + "/.local/share",
                 XDG_STATE_HOME=heim + "/.local/state", XDG_CACHE_HOME=heim + "/.cache", XDG_RUNTIME_DIR=lauf,
                 PATH=fallen + ":" + os.environ.get("PATH", ""),
                 ALPE_SYSTEMCTL=os.path.join(stubs, "systemctl"), ALPE_JOURNALCTL=os.path.join(stubs, "journalctl"),
                 ALPE_LOGINCTL=os.path.join(stubs, "loginctl"))

    def alpe(*args, skript_pfad=ALPE, **extra):
        if os.path.exists(liste):
            os.remove(liste)
        aus = subprocess.run(["bash", skript_pfad, *args], capture_output=True, text=True, env=dict(basis, **extra), timeout=60)
        aufrufe = open(liste, encoding="utf-8").read().splitlines() if os.path.exists(liste) else []
        check(not [a for a in aufrufe if a.startswith("FALLE ")],
              "alpe %s: kein Aufruf erreicht ein echtes Programm" % " ".join(args), aufrufe)
        return aus, aufrufe

    dienst = os.path.join(stubs, "alpe-dienst")

    # E4.1b (Entscheid vom 28.11.2026): Zustand der Unit, dann die Shell von 1.0, dann Neustart oder eigene Instanz
    zeige = "systemctl --user show -p ActiveState --value alpe.service"
    neu = "systemctl --user restart alpe.service"
    # alpe-namen-ausnahme: umzug-ende – Abfrage der Unit von 1.0
    alt = "systemctl --user is-active --quiet dms.service"
    # alpe-namen-ausnahme: umzug-ende

    aus, aufrufe = alpe("restart", ATTRAPPE_ZUSTAND="active", ALPE_DIENST=dienst)
    check(aus.returncode == 0 and aufrufe == [zeige, neu],
          "restart bei aktiver Unit: genau «systemctl --user restart alpe.service», kein Aufruf des Dienstes", aufrufe)

    for zustand in ("failed", "activating", "deactivating", "reloading"):
        aus, aufrufe = alpe("restart", ATTRAPPE_ZUSTAND=zustand, ALPE_DIENST=dienst)
        check(aus.returncode == 0 and aufrufe == [zeige, alt, neu],
              "restart bei Unit «%s»: die Unit wird neu gestartet, nicht die eigene Instanz" % zustand, aufrufe)

    aus, aufrufe = alpe("restart", ATTRAPPE_ZUSTAND="inactive", ALPE_DIENST=dienst)
    check(aus.returncode == 0 and aufrufe == [zeige, alt, "alpe-dienst restart"],
          "restart bei Unit «inactive»: die eigene Instanz über «alpe-dienst restart» (Plan 6.8)", aufrufe)

    for zustand in ("inactive", "failed", "activating"):
        aus, aufrufe = alpe("restart", ATTRAPPE_ZUSTAND=zustand, ATTRAPPE_ALT="0", ALPE_DIENST=dienst)
        check(aus.returncode != 0 and "Alpe 1.0 läuft noch, zuerst alpe umzug" in aus.stdout and aufrufe == [zeige, alt],
              "restart bei Unit «%s» und laufender Shell von 1.0: Abbruch mit Meldung, kein Neustart" % zustand,
              aufrufe + [aus.returncode, aus.stdout])

    aus, aufrufe = alpe("restart", ATTRAPPE_ZUSTAND="active", ATTRAPPE_ALT="0", ALPE_DIENST=dienst)
    check(aus.returncode == 0 and aufrufe == [zeige, neu],
          "restart bei aktiver Unit, auch wenn die Unit von 1.0 aktiv gemeldet wird: Neustart von alpe.service", aufrufe)

    aus, aufrufe = alpe("restart", ATTRAPPE_ZUSTAND="", ALPE_DIENST=dienst)
    check(aus.returncode == 0 and aufrufe == [zeige, alt, "alpe-dienst restart"],
          "restart ohne Antwort von systemctl (leerer Zustand): wie «inactive», eigene Instanz", aufrufe)

    aus, aufrufe = alpe("restart", ATTRAPPE_ZUSTAND="inactive", ALPE_DIENST=os.path.join(tmp, "gibt-es-nicht"))
    check(aus.returncode != 0 and "kein Hintergrunddienst gefunden" in aus.stdout and aufrufe == [zeige, alt],
          "restart ohne Unit und ohne Dienst: Meldung, rc ≠ 0, kein Rückfall auf einen anderen Dienst", aufrufe + [aus.stdout])

    aus, aufrufe = alpe("log", ALPE_DIENST=dienst)
    check(aufrufe == ["journalctl --user -u alpe.service -n 200 -f"], "log: Journal von alpe.service", aufrufe)

    aus, aufrufe = alpe("lock", XDG_CURRENT_DESKTOP="KDE", ALPE_DIENST=dienst)
    check(aufrufe == ["loginctl lock-session"], "lock unter KDE: über logind (ALPE_LOGINCTL)", aufrufe)

    aus, aufrufe = alpe("ipc", "call", "lock", "lock", ALPE_DIENST=dienst)
    check(aufrufe == ["alpe-dienst ipc call lock lock"], "übrige Befehle gehen an den Dienst aus ALPE_DIENST", aufrufe)

    # Ohne ALPE_DIENST: tools/alpe in <PREFIX>/share/alpe/tools, der Dienst in <PREFIX>/bin (Paket, Weg ohne Paket)
    prefix = os.path.join(tmp, "prefix")
    os.makedirs(os.path.join(prefix, "share", "alpe", "tools"))
    os.makedirs(os.path.join(prefix, "bin"))
    kopie = os.path.join(prefix, "share", "alpe", "tools", "alpe")
    shutil.copy2(ALPE, kopie)
    skript(os.path.join(prefix, "bin", "alpe-dienst"), 'echo "prefix-dienst $*" >> "%s"\nexit 0\n' % liste)
    aus, aufrufe = alpe("ipc", "call", "x", skript_pfad=kopie)
    check(aufrufe == ["prefix-dienst ipc call x"], "ohne ALPE_DIENST: der Dienst neben dem eigenen Ort (<PREFIX>/bin)", aufrufe)

    # E4.4 (Plan 0.8 Nr. 125 (2)): «alpe test» im Paket – kein tools/test.sh neben dem Befehl
    aus, aufrufe = alpe("test", skript_pfad=kopie, ALPE_DIENST=dienst)
    check(aus.returncode != 0 and "nur im Repository" in aus.stdout and aufrufe == [],
          "test im Paket (ohne tools/test.sh): «nur im Repository», rc ≠ 0, kein Aufruf", [aus.returncode, aus.stdout, aus.stderr, aufrufe])
    # Im Repository: tools/test.sh neben dem Befehl läuft, mit ALPE_SHELL_DIR auf die Oberfläche daneben
    klon = os.path.join(tmp, "klon")
    os.makedirs(os.path.join(klon, "tools"))
    shutil.copy2(ALPE, os.path.join(klon, "tools", "alpe"))
    skript(os.path.join(klon, "tools", "test.sh"), 'echo "test.sh $ALPE_SHELL_DIR $*" >> "%s"\nexit 7\n' % liste)
    aus, aufrufe = alpe("test", skript_pfad=os.path.join(klon, "tools", "alpe"), ALPE_DIENST=dienst)
    check(aus.returncode == 7 and aufrufe == ["test.sh %s/shell " % klon] and "nur im Repository" not in aus.stdout,
          "test im Repository: tools/test.sh daneben läuft (Rückgabewert durchgereicht)", [aus.returncode, aus.stdout, aufrufe])

    # Ohne ALPE_DIENST und ohne Dienst neben sich: aus dem PATH – nie der Dienst von 1.0
    text = open(ALPE, encoding="utf-8").read()
    # alpe-namen-ausnahme: umzug-ende – Namen von 1.0, die nicht mehr vorkommen dürfen
    check("/usr/bin/dms" not in text and "dms.service" not in text.split("cmd_doctor()", 1)[0]
          and "restart dms.service" not in text and "-u dms.service" not in text,
          "tools/alpe: kein Dienst von 1.0 in backend(), restart und log (/usr/bin/dms, dms.service)")
    # alpe-namen-ausnahme: umzug-ende
finally:
    shutil.rmtree(tmp, ignore_errors=True)

print("\n%s" % ("alle Prüfungen bestanden" if not failures else "%d FEHLER" % failures))
sys.exit(1 if failures else 0)
