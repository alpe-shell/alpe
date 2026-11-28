#!/usr/bin/env python3
"""Alpe: Harness entwicklung/pageharness/kuerzel_last.py und sein Schritt in tools/test.sh (V1, Nachtlauf vom 29.11.2026).

    python3 tests/test_kuerzel_last.py

Befund vom Mac (28.11.2026): Fedoras qtlogging.ini schaltet console.log ab; die Szene meldet ihre Ergebnisse aber über
console.log, darum lief der Harness dort rot («Szene lief nicht»). kuerzel_last.py setzt deshalb vor QGuiApplication
QT_LOGGING_RULES auf «js.debug=true;qml.debug=true» (setdefault; nicht «*.debug=true», das stürzt beim Beenden ab).

Geprüft:
- statisch: die Regel steht im Wortlaut, mit setdefault, vor dem Import von QGuiApplication;
- der Schritt in tools/test.sh zählt als Fehlschlag, wenn die Ausgabe «Fehler:» enthält **oder** der Rückgabewert
  ungleich 0 ist (mit einer Attrappe des Harness, ohne PySide6);
- mit PySide6: der echte Harness läuft grün, auch wenn eine qtlogging.ini (über QT_LOGGING_CONF, wie die von Fedora)
  js.debug und qml.debug abschaltet.
Alles in einem Temp-Ordner mit eigenem HOME, eigenem XDG_RUNTIME_DIR, ohne Session-Bus und Display.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HARNESS = os.path.join(REPO, "entwicklung", "pageharness", "kuerzel_last.py")
TESTSH = os.path.join(REPO, "tools", "test.sh")
REGEL = 'os.environ.setdefault("QT_LOGGING_RULES", "js.debug=true;qml.debug=true")'
failures = 0


def check(cond, msg, extra=None):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    if not cond and extra is not None:
        print("       " + str(extra)[-1500:])
    failures += 0 if cond else 1


text = open(HARNESS, encoding="utf-8").read()
code = "\n".join(z for z in text.splitlines() if not z.lstrip().startswith("#"))
check(REGEL in code, "kuerzel_last.py setzt QT_LOGGING_RULES mit setdefault auf «js.debug=true;qml.debug=true»")
check(REGEL in code and "from PySide6.QtGui import QGuiApplication" in code
      and code.index(REGEL) < code.index("from PySide6.QtGui import QGuiApplication"),
      "die Regel steht vor dem Import von QGuiApplication")
check("*.debug=true" not in code, "keine Regel «*.debug=true» (stürzt beim Beenden ab)")

# Den Schritt aus tools/test.sh herausschneiden: die run-Zeile mit kuerzel_last.py
testsh = open(TESTSH, encoding="utf-8").read()
zeilen = [z for z in testsh.splitlines() if "kuerzel_last.py" in z and z.strip().startswith("run ")]
check(len(zeilen) == 1, "tools/test.sh ruft kuerzel_last.py in genau einer run-Zeile auf", zeilen)

basis = {k: v for k, v in os.environ.items() if k not in ("DBUS_SESSION_BUS_ADDRESS", "WAYLAND_DISPLAY", "DISPLAY",
                                                          "QT_LOGGING_RULES", "QT_LOGGING_CONF")}
tmp = tempfile.mkdtemp(prefix="alpe-test-kuerzel-")
try:
    heim = os.path.join(tmp, "heim")
    for d in (".config", ".local/share", ".local/state", ".cache"):
        os.makedirs(os.path.join(heim, d))
    lauf = os.path.join(heim, "run")
    os.makedirs(lauf, mode=0o700)
    basis.update(HOME=heim, XDG_CONFIG_HOME=heim + "/.config", XDG_DATA_HOME=heim + "/.local/share",
                 XDG_STATE_HOME=heim + "/.local/state", XDG_CACHE_HOME=heim + "/.cache", XDG_RUNTIME_DIR=lauf)

    if len(zeilen) == 1:
        # Attrappe des Harness unter dem relativen Pfad, den die Zeile benutzt; Ausgabe und rc aus der Umgebung
        baum = os.path.join(tmp, "baum")
        os.makedirs(os.path.join(baum, "entwicklung", "pageharness"))
        with open(os.path.join(baum, "entwicklung", "pageharness", "kuerzel_last.py"), "w", encoding="utf-8") as handle:
            handle.write('import os, sys\nprint(os.environ["ATTRAPPE_AUSGABE"])\nsys.exit(int(os.environ["ATTRAPPE_RC"]))\n')
        rahmen = ('fails=0\nrun() { "$@" || { fails=$((fails + 1)); echo "fehlgeschlagen"; }; }\n'
                  + zeilen[0].strip() + '\necho "FAILS=$fails"\n')

        def schritt(ausgabe, rc):
            aus = subprocess.run(["bash", "-c", rahmen], cwd=baum, capture_output=True, text=True, timeout=60,
                                 env=dict(basis, ATTRAPPE_AUSGABE=ausgabe, ATTRAPPE_RC=str(rc)))
            return aus.stdout

        check("FAILS=0" in schritt("ok     alles", 0), "Schritt: «ok» und rc 0 → kein Fehlschlag")
        check("FAILS=1" in schritt("Fehler: etwas", 0), "Schritt: «Fehler:» in der Ausgabe → Fehlschlag")
        check("FAILS=1" in schritt("ok     alles", 3), "Schritt: rc ≠ 0 ohne «Fehler:» (etwa Absturz beim Beenden) → Fehlschlag")

    try:
        import PySide6  # noqa: F401
        pyside = True
    except ImportError:
        pyside = False
    if not pyside:
        print("PySide6 fehlt – echter Lauf übersprungen")
    else:
        ini = os.path.join(tmp, "qtlogging.ini")
        with open(ini, "w", encoding="utf-8") as handle:
            handle.write("[Rules]\n*.debug=false\njs.debug=false\nqml.debug=false\n")
        aus = subprocess.run([sys.executable, HARNESS], capture_output=True, text=True, timeout=120,
                             env=dict(basis, QT_QPA_PLATFORM="offscreen", QT_LOGGING_CONF=ini))
        ausgabe = aus.stdout + aus.stderr
        check(aus.returncode == 0 and "Fehler:" not in ausgabe and re.search(r"^ok", aus.stdout, re.M),
              "echter Harness mit qtlogging.ini, die js.debug/qml.debug abschaltet (wie Fedora): grün, mit «ok»-Zeilen",
              [aus.returncode, ausgabe])
finally:
    shutil.rmtree(tmp, ignore_errors=True)

print("\n%s" % ("alle Prüfungen bestanden" if not failures else "%d FEHLER" % failures))
sys.exit(1 if failures else 0)
