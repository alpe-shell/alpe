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
write("shell/Alt2.qml", "import qs." + "DCommon.Widgets\n")  # geteilt, damit diese Datei kein Fund ist
subprocess.run(["git", "-C", repo, "add", "-A"], env=env, check=True)
check("shell/Alt2.qml:1:" in run(np, "--liste").stdout, "Namensprüfung meldet Import über das alte Modul")
os.remove(os.path.join(repo, "shell/Alt2.qml"))
alt_name = "D" + "Knopf"  # zusammengesetzt, damit diese Datei kein Fund ist
write("tools/namen-verboten.txt", "# Kommentar\n" + alt_name + "\n")
write("shell/Alt3.qml", alt_name + " {}\n" + alt_name + "Gross {}\nAlpe" + alt_name[1:] + " {}\n")
write("shell/" + alt_name + ".qml", "Item {}\n")
subprocess.run(["git", "-C", repo, "add", "-A"], env=env, check=True)
ausgabe = run(np, "--liste").stdout
check("shell/Alt3.qml:1:" in ausgabe and "shell/Alt3.qml:2:" not in ausgabe and "shell/Alt3.qml:3:" not in ausgabe,
      "verbotener alter Name nur als ganzer Bezeichner gemeldet")
check("shell/%s.qml: (Dateiname)" % alt_name in ausgabe, "verbotener alter Name im Dateinamen gemeldet")
os.remove(os.path.join(repo, "shell/Alt3.qml"))
os.remove(os.path.join(repo, "shell/" + alt_name + ".qml"))
os.remove(os.path.join(repo, "shell/Rest.qml"))
subprocess.run(["git", "-C", repo, "add", "-A"], env=env, check=True)
check(run(np, "--streng").returncode == 0, "--streng: grün ohne Fund")

# Marken im Code (Plan 0.8 Nr. 64): Bereich zwischen zwei Marken ist ausgenommen, alles davor und danach nicht.
marke = "// alpe-namen-" + "ausnahme: umzug-ende"  # geteilt geschrieben, wie die alten Namen oben
alt = "da" + "nkAlt"


def marken_lauf(inhalt):
    write("shell/Marke.js", inhalt)
    subprocess.run(["git", "-C", repo, "add", "-A"], env=env, check=True)
    return run(np, "--liste").stdout, run(np, "--streng").returncode


ausgabe, code = marken_lauf("var a = s.%s0;\n%s\nvar b = s.%s1;\nvar c = s.%s2;\n%s\nvar d = s.%s3;\n" % (alt, marke, alt, alt, marke, alt))
check("shell/Marke.js:1:" in ausgabe and "shell/Marke.js:6:" in ausgabe, "Marke: Zeilen vor und nach dem Bereich bleiben Fundstellen")
check("shell/Marke.js:3:" not in ausgabe and "shell/Marke.js:4:" not in ausgabe, "Marke: Zeilen im Bereich sind ausgenommen")
check("2 Fundstellen in 1 Dateien" in ausgabe and "1 Bereiche in 1 Dateien, 2 Fundstellen ausgenommen" in ausgabe, "Marke: Zusammenfassung zählt Bereiche und Ausgenommenes")
check(code == 1, "Marke: --streng bleibt rot wegen der Zeilen ausserhalb")
check("shell/Marke.js:2-5\tumzug-ende\t2 Fundstellen" in run(np, "--bereiche").stdout, "Marke: --bereiche nennt Datei, Zeilen und Frist")
ausgabe, code = marken_lauf("%s\nvar b = s.%s1;\n%s\n%s\nvar c = s.%s2;\n%s\n" % (marke, alt, marke, marke, alt, marke))
check(code == 0 and "2 Bereiche" in ausgabe, "Marke: zwei Bereiche in einer Datei, grün")
ausgabe, code = marken_lauf("%s\nvar b = s.%s1;\nvar c = s.%s2;\n" % (marke, alt, alt))
check(code == 1 and "shell/Marke.js:1: Marke ohne Ende" in ausgabe and "shell/Marke.js:2:" in ausgabe and "shell/Marke.js:3:" in ausgabe,
      "Marke ohne Ende: gemeldet, nimmt nichts aus")
ausgabe, code = marken_lauf("%s\nvar b = s.%s1;\n%s\n" % (marke.replace("umzug-ende", "irgendwann"), alt, marke.replace("umzug-ende", "irgendwann")))
check(code == 1 and "unbekannter Frist «irgendwann»" in ausgabe and "shell/Marke.js:2:" in ausgabe, "Marke mit unbekannter Frist: gemeldet, nimmt nichts aus")
ausgabe, code = marken_lauf("%s\nvar b = s.%s1;\n%s\n" % (marke.replace(" umzug-ende", ""), alt, marke.replace(" umzug-ende", "")))
check(code == 1 and "unbekannter Frist «»" in ausgabe, "Marke ohne Frist: gemeldet")
ausgabe, code = marken_lauf("%s\nvar b = 1;\n%s\n" % (marke, marke))
check(code == 1 and "shell/Marke.js:1: Marke nimmt keine Fundstelle aus" in ausgabe, "Marke um einen Bereich ohne alten Namen: gemeldet (überholt)")
os.remove(os.path.join(repo, "shell/Marke.js"))
subprocess.run(["git", "-C", repo, "add", "-A"], env=env, check=True)
check(run(np, "--streng").returncode == 0, "--streng: grün nach dem Entfernen")
write("tools/namen-ausnahmen.txt", "tools/*\t*\t\tohne Frist\n")
check(run(np).returncode != 0, "Eintrag ohne Frist wird abgelehnt")

shutil.rmtree(tmp)
print("alle Prüfungen bestanden" if failures == 0 else "%d Prüfung(en) fehlgeschlagen" % failures)
sys.exit(1 if failures else 0)
