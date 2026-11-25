#!/usr/bin/env python3
"""Alpe: PAM-Dienste und Richtlinien mit alpe-Namen (Plan 0.8 Nr. 16, 2.3.3; Nachtlauf-Auftrag E1 2.5).

    python3 tests/test_pam_dienste.py

Geschrieben werden nur /etc/pam.d/alpe und alpe-u2f mit der Blockmarke «ALPE LOCKSCREEN AUTH»; die Dienste und
Blöcke der Einrichtung von 1.0 (dankshell, dankshell-u2f, «DMS LOCKSCREEN AUTH») werden erkannt und nicht
verändert – sie stehen nur innerhalb der Bereichsmarken der Namensprüfung (Frist Umzug-Ende). Richtlinien unter
/usr/share/alpe/cli-policy.json und /etc/alpe/cli-policy.json. Der QML-Test der Sperre (shell/tests/lock/tst_Pam.qml)
läuft mit qmltestrunner, wenn es installiert ist.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(REPO, "shell")
failures = 0
MARKE = "alpe-namen-" + "ausnahme: umzug-ende"   # zusammengesetzt, sonst gälte die Zeile selbst als Marke
ALT = re.compile(r"dankshell|DMS LOCKSCREEN|/etc/dms|/usr/share/dms")


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


def lies(*teile):
    with open(os.path.join(*teile), encoding="utf-8") as handle:
        return handle.read()


def ausserhalb_der_marken(text):
    """Zeilen ausserhalb der Bereiche zwischen zwei Bereichsmarken (MARKE)."""
    drin, zeilen = False, []
    for zeile in text.splitlines():
        if MARKE in zeile:
            drin = not drin
            continue
        if not drin:
            zeilen.append(zeile)
    return zeilen


pam_go = lies(REPO, "core", "internal", "pam", "pam.go")
check('AlpePamPath    = "/etc/pam.d/alpe"' in pam_go and 'AlpeU2FPamPath = "/etc/pam.d/alpe-u2f"' in pam_go
      and 'UserLockscreenPamService = "alpe"' in pam_go, "Dienst: PAM-Dienste alpe und alpe-u2f, im Nutzerordner alpe")
check('"# BEGIN ALPE LOCKSCREEN AUTH' in pam_go and '"# END ALPE LOCKSCREEN AUTH"' in pam_go
      and '"# BEGIN ALPE LOCKSCREEN U2F AUTH' in pam_go and '"# END ALPE LOCKSCREEN U2F AUTH"' in pam_go,
      "Dienst: Blockmarken «ALPE LOCKSCREEN AUTH» und «ALPE LOCKSCREEN U2F AUTH»")
schreiben = re.findall(r"writeManagedPamFile\([^,]+, (deps\.\w+)", pam_go) + re.findall(r'"rm", "-f", (deps\.\w+)', pam_go)
check(sorted(set(schreiben)) == ["deps.alpePath", "deps.alpeU2fPath"],
      "Dienst schreibt und löscht nur die alpe-Dienste, nie die aus 1.0: %s" % sorted(set(schreiben)))
check(not re.search(r"(runSudoCmd|WriteFile|Remove|Rename)\([^)\n]*(legacy|Legacy)", pam_go)
      and set(re.findall(r"deps\.legacy\w*", pam_go)) <= {"deps.legacyPath", "deps.legacyU2fPath"}
      # gelesen nur in reportLegacyPamFile (dessen Ergebnis darf zugewiesen werden), sonst nur in einer Meldung (0.8 Nr. 118)
      and all(re.match(r"(\w+ := )?reportLegacyPamFile\(|logFunc\(fmt\.Sprintf\(\"[^\"]*\", deps\.legacyPath, deps\.alpePath\)\)$", z.strip())
              for z in pam_go.splitlines() if "deps.legacy" in z),
      "Dienst: die Pfade von 1.0 gehen nur an reportLegacyPamFile (lesen) und in Meldungen, nie an sudo, Schreiben, Löschen oder Umbenennen")
check("reportLegacyPamFile(logFunc, deps.legacyPath" in pam_go and "reportLegacyPamFile(logFunc, deps.legacyU2fPath" in pam_go,
      "Dienst: Dienste aus 1.0 werden beim Abgleich erkannt und gemeldet")

for pfad in (("core", "internal", "pam", "pam.go"), ("core", "internal", "pam", "pam_test.go"),
             ("core", "internal", "clipolicy", "clipolicy.go"), ("core", "internal", "clipolicy", "clipolicy_test.go"),
             ("shell", "Modules", "Lock", "Pam.qml"), ("shell", "Common", "settings", "Processes.qml"),
             ("shell", "tests", "lock", "tst_Pam.qml")):
    text = lies(REPO, *pfad)
    funde = [z.strip() for z in ausserhalb_der_marken(text) if ALT.search(z)]
    check(not funde and text.count(MARKE) % 2 == 0, "%s: alte Namen nur innerhalb der Marken: %s" % ("/".join(pfad), funde[:3]))

pam_qml = lies(SHELL, "Modules", "Lock", "Pam.qml")
check('path: "/etc/pam.d/alpe"' in pam_qml and 'path: "/etc/pam.d/alpe-u2f"' in pam_qml and '"/etc/pam.d/alpe-fprint"' in pam_qml
      and 'root.userPamDir + "/alpe"' in pam_qml, "Sperre: liest /etc/pam.d/alpe, alpe-u2f, alpe-fprint und den Nutzerdienst alpe")
check('systemPamWatcher.loaded ? "alpe" : (legacyPamWatcher.loaded ? "dankshell" : "")' in pam_qml,
      "Sperre: neuer Dienst zuerst, der aus 1.0 nur als Rückfall")

clipolicy = lies(REPO, "core", "internal", "clipolicy", "clipolicy.go")
check('PackagedPath = "/usr/share/alpe/cli-policy.json"' in clipolicy and 'AdminPath    = "/etc/alpe/cli-policy.json"' in clipolicy,
      "Richtlinien: /usr/share/alpe/cli-policy.json und /etc/alpe/cli-policy.json")
# Plan 0.8 Nr. 119: Rückfall nur auf die Richtlinie des Administrators aus 1.0, nie auf die des Pakets von 1.0.
check('LegacyAdminPath = "/etc/dms/cli-policy.json"' in clipolicy and "/usr/share/dms" not in clipolicy
      and "EffectiveAdminPath(fs)" in clipolicy and "warnLegacyAdmin(" in clipolicy,
      "Richtlinien: /etc/dms/cli-policy.json als Rückfall mit Meldung, /usr/share/dms nie")
check("clipolicy.EffectiveAdminPath(" in lies(REPO, "core", "cmd", "alpe-dienst", "immutable_policy.go"),
      "Richtlinien: auch die Befehlssperre (immutable_policy.go) nimmt den Rückfall")
ausnahmen = lies(REPO, "tools", "namen-ausnahmen.txt")
check(not [z for z in ausnahmen.splitlines() if z and not z.startswith("#") and len(z.split("\t")) > 2 and z.split("\t")[2] == "E1"],
      "Namens-Ausnahmeliste: keine Einträge mehr mit Frist E1")

runner = next((shutil.which(c) for c in ("qmltestrunner6", "/usr/lib/qt6/bin/qmltestrunner", "/usr/lib64/qt6/bin/qmltestrunner")
               if shutil.which(c)), None)
if runner:
    with tempfile.TemporaryDirectory(prefix="alpe-tst-pam-") as tmp:
        env = dict(os.environ, HOME=tmp, XDG_CACHE_HOME=os.path.join(tmp, "c"), XDG_CONFIG_HOME=os.path.join(tmp, "k"),
                   XDG_STATE_HOME=os.path.join(tmp, "s"), XDG_DATA_HOME=os.path.join(tmp, "d"), XDG_RUNTIME_DIR=tmp,
                   QML_DISABLE_DISK_CACHE="1", QT_QPA_PLATFORM="offscreen")
        out = subprocess.run([runner, "-import", os.path.join(SHELL, "tests", "lock", "mocks"), "-input", os.path.join(SHELL, "tests", "lock"),
                              "-o", "-,txt"], capture_output=True, text=True, env=env, timeout=300)
        summe = re.search(r"Totals: (\d+) passed, (\d+) failed", out.stdout)
        ohne_richtlinie = [z for z in out.stdout.splitlines() if z.startswith("PASS") and "test_pamStacksWithoutPolicy(" in z]
        check(out.returncode == 0 and summe is not None and summe.group(2) == "0" and int(summe.group(1)) >= 43 and len(ohne_richtlinie) == 4,
              "QML-Test der Sperre (tst_Pam.qml), mit vier Fällen ohne Richtlinie (Weg am Mac): %s"
              % (summe.group(0) if summe else out.stdout[-500:] + out.stderr[-500:]))
else:
    print("qmltestrunner fehlt – QML-Test der Sperre übersprungen")

print("\n%s" % ("alle Prüfungen bestanden" if not failures else "%d FEHLER" % failures))
sys.exit(1 if failures else 0)
