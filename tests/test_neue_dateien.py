#!/usr/bin/env python3
"""Prüft tools/neue-dateien-pruefen.sh in einem Wegwerf-Repository.

    python3 tests/test_neue_dateien.py
"""
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
TOOL = os.path.join(os.path.dirname(HERE), "tools", "neue-dateien-pruefen.sh")
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    if not cond:
        failures += 1


tmp = tempfile.mkdtemp()
repo = os.path.join(tmp, "repo")
os.makedirs(os.path.join(repo, "tools"))
shutil.copy(TOOL, os.path.join(repo, "tools"))
env = dict(os.environ, GIT_AUTHOR_NAME="t", GIT_AUTHOR_EMAIL="t@t", GIT_COMMITTER_NAME="t", GIT_COMMITTER_EMAIL="t@t",
           GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_SYSTEM="/dev/null")


def git(*args):
    subprocess.run(["git", "-C", repo] + list(args), env=env, check=True, capture_output=True)


def run(**extra):
    return subprocess.run(["bash", os.path.join(repo, "tools", "neue-dateien-pruefen.sh")], env=dict(env, **extra),
                          capture_output=True, text=True)


def write(name, data):
    with open(os.path.join(repo, name), "wb") as handle:
        handle.write(data)


git("init", "-q", "-b", "main")
write("klein.txt", b"hallo\n")
git("add", "-A")
git("commit", "-q", "-m", "basis")
git("update-ref", "refs/remotes/origin/phase-a", "HEAD")

r = run()
check(r.returncode == 0 and "ok" in r.stdout, "sauberer Stand: grün")

r = run(ALPE_PRUEF_BASIS="origin/gibtsnicht")
check(r.returncode == 0 and "übersprungen" in r.stdout, "fehlender Vergleichsstand: nur Hinweis")

write("gross.bin", b"x" * (1024 * 1024 + 1))
r = run()
check(r.returncode == 1 and "gross.bin" in r.stdout, "neue, nicht ignorierte Datei über 1 MB: rot")

git("add", "gross.bin")
git("commit", "-q", "-m", "gross")
r = run()
check(r.returncode == 1 and "zu gross" in r.stdout, "committete Datei über 1 MB: rot")
git("rm", "-q", "gross.bin")
git("commit", "-q", "-m", "weg")
check(run().returncode == 0, "wieder entfernt: grün")

write("programm", b"\x7fELF" + b"\0" * 60)
git("add", "programm")
r = run()
check(r.returncode == 1 and "ELF" in r.stdout, "vorgemerkte ELF-Datei: rot")
git("rm", "-q", "--cached", "programm")
write(".gitignore", b"programm\n")
check(run().returncode == 0, "ignorierte ELF-Datei im Arbeitsbaum: grün")

write("genau.bin", b"x" * (1024 * 1024))
check(run().returncode == 0, "genau 1 MB: grün")

shutil.rmtree(tmp)
print("alle Prüfungen bestanden" if failures == 0 else "%d Prüfung(en) fehlgeschlagen" % failures)
sys.exit(1 if failures else 0)
