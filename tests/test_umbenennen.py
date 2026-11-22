#!/usr/bin/env python3
"""Prüft entwicklung/umbenennen/umbenennen.py und tools/namen-pruefen.py in Wegwerf-Repositories.

    python3 tests/test_umbenennen.py
"""
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    if not cond:
        failures += 1


env = dict(os.environ, GIT_AUTHOR_NAME="t", GIT_AUTHOR_EMAIL="t@t", GIT_COMMITTER_NAME="t", GIT_COMMITTER_EMAIL="t@t",
           GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_SYSTEM="/dev/null", ALPE_QML_DIR="/nicht/da")
tmp = tempfile.mkdtemp()
repo = os.path.join(tmp, "repo")


def write(name, text):
    path = os.path.join(repo, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as handle:
        handle.write(text)


def read(name):
    with open(os.path.join(repo, name)) as handle:
        return handle.read()


def run(*args):
    return subprocess.run([sys.executable] + list(args), cwd=repo, env=env, capture_output=True, text=True)


os.makedirs(os.path.join(repo, "entwicklung", "umbenennen"))
os.makedirs(os.path.join(repo, "tools"))
shutil.copy(os.path.join(REPO, "entwicklung", "umbenennen", "umbenennen.py"), os.path.join(repo, "entwicklung", "umbenennen"))
shutil.copy(os.path.join(REPO, "tools", "namen-pruefen.py"), os.path.join(repo, "tools"))
write("shell/Services/DMSService.qml", "Item { property bool dmsBin: true }\n")
write("shell/Foo.qml", "DMSService.dmsBin\nDMSServiceX bleibt\nbackendBin schon da\n")
write("shell/Neu.qml", "Item {}\n")
write("tools/namen-ausnahmen.txt", "tools/*\t*\tdauerhaft\tWerkzeug\nshell/Foo.qml\tDMSServiceX\tE4\tTest\n")
subprocess.run(["git", "init", "-q", "-b", "main", repo], env=env, check=True)
subprocess.run(["git", "-C", repo, "add", "-A"], env=env, check=True)
subprocess.run(["git", "-C", repo, "commit", "-q", "-m", "basis"], env=env, check=True)
tool = os.path.join(repo, "entwicklung", "umbenennen", "umbenennen.py")

write("t1.tsv", "wort\tDMSService\tShellBackend\nwort\tdmsBin\tbackendBin\ndatei\tshell/Services/DMSService.qml\tshell/Services/ShellBackend.qml\n")
r = run(tool, "t1.tsv")
check(r.returncode == 1 and "KOLLISION dmsBin → backendBin" in r.stdout, "Kollision mit bestehendem Bezeichner wird gemeldet")
check(read("shell/Foo.qml").startswith("DMSService.dmsBin"), "Probelauf schreibt nichts")
r = run(tool, "t1.tsv", "--schreiben")
check(r.returncode == 1 and "Abbruch" in r.stdout and os.path.exists(os.path.join(repo, "shell/Services/DMSService.qml")), "mit Kollision wird nicht geschrieben")

write("t2.tsv", "wort\tDMSService\tShellBackend\nerlaubt\tbackendBin\nwort\tdmsBin\tbackendBin\ndatei\tshell/Services/DMSService.qml\tshell/Services/ShellBackend.qml\ndatei\tshell/Neu.qml\tshell/Foo.qml\n")
r = run(tool, "t2.tsv")
check(r.returncode == 1 and "Ziel existiert" in r.stdout, "Datei-Ziel, das es schon gibt, ist eine Kollision")
write("t2.tsv", "wort\tDMSService\tShellBackend\nerlaubt\tbackendBin\nwort\tdmsBin\tbackendBin\ndatei\tshell/Services/DMSService.qml\tshell/Services/ShellBackend.qml\nlink\tshell/Alt.qml\tFoo.qml\n")
r = run(tool, "t2.tsv", "--liste")
check(r.returncode == 0 and "shell/Foo.qml:1:" in r.stdout and "3 Ersetzungen" in r.stdout, "Probelauf mit Liste der Treffer")
r = run(tool, "t2.tsv", "--schreiben")
check(r.returncode == 0, "schreiben ohne Kollision")
check(read("shell/Foo.qml") == "ShellBackend.backendBin\nDMSServiceX bleibt\nbackendBin schon da\n", "nur ganze Bezeichner ersetzt")
check(read("shell/Services/ShellBackend.qml") == "Item { property bool backendBin: true }\n", "Datei verschoben und Inhalt unter neuem Pfad")
check(os.path.islink(os.path.join(repo, "shell/Alt.qml")) and os.readlink(os.path.join(repo, "shell/Alt.qml")) == "Foo.qml", "Übergangs-Symlink angelegt")

np = os.path.join(repo, "tools", "namen-pruefen.py")
write("shell/Rest.qml", "property bool dankRest\n")
subprocess.run(["git", "-C", repo, "add", "-A"], env=env, check=True)
r = run(np, "--liste")
check(r.returncode == 0 and "shell/Rest.qml:1:" in r.stdout and "DMSServiceX" not in r.stdout, "Namensprüfung meldet Fund, Ausnahme mit Muster greift")
r = run(np, "--streng")
check(r.returncode == 1, "--streng: rot bei Fund")
os.remove(os.path.join(repo, "shell/Rest.qml"))
subprocess.run(["git", "-C", repo, "add", "-A"], env=env, check=True)
check(run(np, "--streng").returncode == 0, "--streng: grün ohne Fund")
write("tools/namen-ausnahmen.txt", "tools/*\t*\t\tohne Frist\n")
check(run(np).returncode != 0, "Eintrag ohne Frist wird abgelehnt")

shutil.rmtree(tmp)
print("alle Prüfungen bestanden" if failures == 0 else "%d Prüfung(en) fehlgeschlagen" % failures)
sys.exit(1 if failures else 0)
