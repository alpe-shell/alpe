#!/usr/bin/env python3
"""Alpe: tools/test-commit.sh – tools/test.sh auf genau einem Commit (CLAUDE.md, «Prüfen vor jedem Commit»).

Der Test legt ein kleines Git-Repository in einem Temp-Ordner an, mit einer Kopie des Skripts und einem
Ersatz für tools/test.sh (grün auf dem ersten Commit, rot auf dem zweiten). Das echte tools/test.sh ruft er
nicht auf (es riefe sonst sich selbst).
"""
import os
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKRIPT = os.path.join(REPO, "tools", "test-commit.sh")
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


ERSATZ = """#!/usr/bin/env bash
cd "$(dirname "$0")/.." || exit 2
echo "HOME=$HOME"
if [ -f rot ]; then echo "1 Prüfung(en) fehlgeschlagen"; exit 1; fi
echo "alles grün"
"""

tmp = tempfile.mkdtemp(prefix="alpe-testcommit-")
try:
    repo, protokolle, arbeit = os.path.join(tmp, "repo"), os.path.join(tmp, "protokolle"), os.path.join(tmp, "arbeit")
    os.makedirs(os.path.join(repo, "tools"))
    os.makedirs(arbeit)
    shutil.copy(SKRIPT, os.path.join(repo, "tools", "test-commit.sh"))
    with open(os.path.join(repo, "tools", "test.sh"), "w", encoding="utf-8") as handle:
        handle.write(ERSATZ)
    umgebung = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
    umgebung.update(GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_SYSTEM="/dev/null", GIT_AUTHOR_NAME="Test", GIT_AUTHOR_EMAIL="test@example.org",
                    GIT_COMMITTER_NAME="Test", GIT_COMMITTER_EMAIL="test@example.org", ALPE_TEST_PROTOKOLLE=protokolle, TMPDIR=arbeit)

    def git(*args):
        return subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True, env=umgebung, check=True).stdout.strip()

    def lauf(*args):
        return subprocess.run(["bash", os.path.join(repo, "tools", "test-commit.sh"), *args], capture_output=True, text=True, env=umgebung)

    def protokoll(hash_):
        pfad = os.path.join(protokolle, "test-%s.log" % hash_)
        if not os.path.exists(pfad):
            return None
        with open(pfad, encoding="utf-8") as handle:
            return handle.read().splitlines()

    git("init", "-q", "-b", "arbeit")
    git("add", "-A")
    git("commit", "-q", "-m", "gruen")
    gruen = git("rev-parse", "HEAD")
    open(os.path.join(repo, "rot"), "w").close()
    git("add", "-A")
    git("commit", "-q", "-m", "rot")
    rot = git("rev-parse", "HEAD")

    # Nur volle Hashes: Alles andere wird abgelehnt, bevor irgendetwas läuft.
    for lage, angabe in (("HEAD", ["HEAD"]), ("Branch-Name", ["arbeit"]), ("gekürzter Hash", [gruen[:12]]), ("HEAD~1", ["HEAD~1"]),
                         ("Grossbuchstaben", [gruen.upper()]), ("voller Hash, den es nicht gibt", ["0123456789abcdef0123456789abcdef01234567"]),
                         ("voller Hash und HEAD gemischt", [gruen, "HEAD"]), ("ohne Angabe", [])):
        aus = lauf(*angabe)
        check(aus.returncode == 2 and not os.path.exists(protokolle) and os.listdir(arbeit) == [],
              "abgelehnt (2), kein Protokoll, kein Worktree: " + lage)
    check("kein voller Hash" in lauf("HEAD").stderr and "HEAD" in lauf("HEAD").stderr, "die Ablehnung nennt den Grund und die Angabe")

    # Lauf auf dem grünen Commit: Ausgabe und Protokoll nennen den vollen Hash, HOME ist ein Temp-Ordner.
    aus = lauf(gruen)
    zeilen = protokoll(gruen) or [""]
    check(aus.returncode == 0 and ("tools/test.sh auf %s: grün" % gruen) in aus.stdout, "grüner Commit: Rückgabewert 0, die Ausgabe nennt den geprüften Hash")
    check(zeilen[0].startswith("### tools/test.sh auf Commit %s, " % gruen) and zeilen[-1].endswith(", Commit %s, Rückgabewert 0" % gruen)
          and "alles grün" in zeilen, "Protokoll: erste und letzte Zeile nennen den vollen Hash, die letzte den Rückgabewert")
    heim = [z for z in zeilen if z.startswith("HOME=")]
    check(len(heim) == 1 and heim[0] != "HOME=" + os.environ.get("HOME", "") and heim[0].startswith("HOME=" + arbeit),
          "der Lauf hat ein eigenes HOME im Temp-Ordner")
    check(os.listdir(arbeit) == [] and git("worktree", "list").count("\n") == 0, "Temp-Worktree und Temp-HOME sind danach weg")
    # Geprüft wird der Commit, nicht der Arbeitsbaum: Im Arbeitsbaum liegt «rot», der grüne Commit bleibt grün.
    check(os.path.exists(os.path.join(repo, "rot")), "geprüft wurde der Commit selbst (im Arbeitsbaum läge schon die Datei des roten Commits)")

    # Sammellauf über beide: einer rot → Rückgabewert 1, jedes Protokoll mit eigenem Hash.
    aus = lauf(gruen, rot)
    zeilen_rot = protokoll(rot) or [""]
    check(aus.returncode == 1 and ("auf %s: grün" % gruen) in aus.stdout and ("auf %s: ROT (Rückgabewert 1)" % rot) in aus.stdout,
          "Sammellauf: je Commit eine Zeile mit vollem Hash, roter Commit macht den Lauf rot")
    check(zeilen_rot[-1].endswith(", Commit %s, Rückgabewert 1" % rot), "Protokoll des roten Commits nennt Rückgabewert 1")

    # --gruen: Schranke vor der Haltprüfung.
    check(lauf("--gruen", gruen).returncode == 0 and lauf("--gruen", rot).returncode == 1, "--gruen: 0 nur für den Commit mit grünem Protokoll")
    check(lauf("--gruen", "HEAD").returncode == 2 and lauf("--gruen").returncode == 2 and lauf("--gruen", gruen, rot).returncode == 2,
          "--gruen nimmt genau einen vollen Hash")
    ohne = "f" * 40
    check(lauf("--gruen", ohne).returncode == 1 and "kein Protokoll" in lauf("--gruen", ohne).stdout, "--gruen ohne Protokoll: 1 mit Begründung")
    # Ein grünes Protokoll unter dem Namen eines anderen Commits gilt nicht (der Hash steht auch im Inhalt).
    shutil.copy(os.path.join(protokolle, "test-%s.log" % gruen), os.path.join(protokolle, "test-%s.log" % rot))
    check(lauf("--gruen", rot).returncode == 1, "--gruen: ein Protokoll, dessen Inhalt einen anderen Commit nennt, gilt nicht")
    # Ein abgebrochener Lauf (Schlusszeile fehlt) gilt nicht.
    with open(os.path.join(protokolle, "test-%s.log" % gruen), "w", encoding="utf-8") as handle:
        handle.write("\n".join(zeilen[:-1]) + "\n")
    check(lauf("--gruen", gruen).returncode == 1, "--gruen: ein Protokoll ohne Schlusszeile gilt nicht")

    with open(os.path.join(REPO, "CLAUDE.md"), encoding="utf-8") as handle:
        regeln = handle.read()
    check("tools/test-commit.sh" in regeln and "--gruen" in regeln, "CLAUDE.md nennt das Skript und die Schranke vor der Haltprüfung")
finally:
    shutil.rmtree(tmp, ignore_errors=True)

print("\nalle Prüfungen bestanden" if failures == 0 else f"\n{failures} FEHLER")
sys.exit(1 if failures else 0)
