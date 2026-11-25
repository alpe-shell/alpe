#!/usr/bin/env python3
"""Alpe: Makefile in der Wurzel (Plan Abschnitt 1 und 6.1; Nachtlauf-Auftrag E1 2.2).

    python3 tests/test_makefile.py

Prüft in einem Temp-Ordner: «make build» baut den Dienst ohne eingebettete Oberfläche und mit der Version aus
Brand.qml; «make install DESTDIR=… PREFIX=/usr» legt den Baum nach 6.1 an (Werkzeuge nur aus der ausdrücklichen
Liste, keine Tests der Oberfläche); «make dist» schreibt ein Quellarchiv mit vendorten Go-Modulen, aus dem sich der
Dienst ohne Netz bauen lässt. Ohne make, go oder git (oder mit ALPE_SKIP_GO) wird der Teil übersprungen.
"""
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
failures = 0


def check(cond, msg, out=None):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg + ("" if cond or out is None else "\n" + out.stdout[-3000:] + out.stderr[-3000:]))
    failures += 0 if cond else 1


def make(*args, cwd=REPO, env=None):
    return subprocess.run(["make", "-s", "-C", cwd, *args], capture_output=True, text=True, env=env)


brand = re.search(r'readonly property string version:\s*"([^"]+)"', open(os.path.join(REPO, "shell", "Common", "Brand.qml"), encoding="utf-8").read()).group(1)
makefile = open(os.path.join(REPO, "Makefile"), encoding="utf-8").read()
for ziel in ("build", "install", "test", "dist"):
    check(re.search(r"^%s:" % ziel, makefile, re.M) is not None, "Makefile hat das Ziel «%s»" % ziel)
check("withshell" not in makefile.replace("ohne Tag «withshell»", ""), "Makefile baut den Dienst nie mit dem Tag withshell")
tools_liste = re.search(r"^TOOLS := (.*?)(?<!\\)\n", makefile, re.M | re.S).group(1).replace("\\\n", " ").split()
VERBOTEN = {"test.sh", "test-commit.sh", "node-tests.py", "namen-pruefen.sh", "namen-pruefen.py", "namen-ausnahmen.txt",
            "namen-verboten.txt", "werte-pruefen.py", "werte-ausnahmen.txt", "neue-dateien-pruefen.sh", "release-pruefen.sh",
            "standbild.py", "build-basemap.py", "radar-probe.py", "backend.sh"}
check(tools_liste and not set(tools_liste) & VERBOTEN and all(os.path.isfile(os.path.join(REPO, "tools", t)) for t in tools_liste),
      "Werkzeuge des Pakets: ausdrückliche Liste ohne Prüf- und Entwicklungsskripte (%s)" % " ".join(tools_liste))
# Jedes Werkzeug unter tools/ ist eingeordnet: im Paket oder ausdrücklich nicht.
alle = {t for t in os.listdir(os.path.join(REPO, "tools")) if os.path.isfile(os.path.join(REPO, "tools", t))}
check(alle <= set(tools_liste) | VERBOTEN, "jede Datei unter tools/ ist eingeordnet (Paket oder nicht): %s" % sorted(alle - set(tools_liste) - VERBOTEN))

if not shutil.which("make") or not shutil.which("go") or os.environ.get("ALPE_SKIP_GO"):
    print("make oder go fehlt, oder ALPE_SKIP_GO – Bau, Installation und Archiv übersprungen")
    sys.exit(1 if failures else 0)

tmp = tempfile.mkdtemp(prefix="alpe-make-")
try:
    env = dict(os.environ)
    env.pop("GOFLAGS", None)
    bau = os.path.join(tmp, "bau")
    out = make("build", "BUILD=" + bau, env=env)
    dienst = os.path.join(bau, "alpe-dienst")
    check(out.returncode == 0 and os.access(dienst, os.X_OK), "make build: Dienst gebaut", out)
    if out.returncode == 0:
        version = subprocess.run([dienst, "version"], capture_output=True, text=True).stdout.strip()
        check(version == "alpe-dienst " + brand, "Version aus Brand.qml: %s" % version)
        info = subprocess.run(["go", "version", "-m", dienst], capture_output=True, text=True).stdout
        check("withshell" not in info and "-trimpath=true" in info, "ohne eingebettete Oberfläche (kein Tag withshell), -trimpath")

    wurzel = os.path.join(tmp, "wurzel")
    out = make("install", "BUILD=" + bau, "DESTDIR=" + wurzel, "PREFIX=/usr", env=env)
    check(out.returncode == 0, "make install DESTDIR=… PREFIX=/usr läuft durch", out)
    usr = os.path.join(wurzel, "usr")
    check(os.access(os.path.join(usr, "bin", "alpe-dienst"), os.X_OK), "/usr/bin/alpe-dienst")
    check(os.readlink(os.path.join(usr, "bin", "alpe")) == "../share/alpe/tools/alpe" if os.path.islink(os.path.join(usr, "bin", "alpe")) else False,
          "/usr/bin/alpe -> ../share/alpe/tools/alpe")
    share = os.path.join(usr, "share", "alpe")
    check(sorted(os.listdir(share)) == ["design", "lockscreen", "plugins", "shell", "tools"], "/usr/share/alpe/{shell,plugins,tools,design,lockscreen}")
    check(sorted(os.listdir(os.path.join(share, "tools"))) == sorted(tools_liste), "unter /usr/share/alpe/tools genau die Werkzeuge der Liste")
    check(os.path.isfile(os.path.join(share, "shell", "shell.qml")) and not os.path.exists(os.path.join(share, "shell", "tests"))
          and not os.path.exists(os.path.join(share, "plugins", "claudeCodeUsage", "tests"))
          and not any(f.endswith(".py") for f in os.listdir(os.path.join(share, "shell", "translations"))),
          "Oberfläche und Plugins ohne Tests und ohne Übersetzungswerkzeuge")
    check(os.path.isfile(os.path.join(share, "design", "kde", "bilder", "jagged-peaks-wolkenzug.jpg")), "Design mit Standbild der Sperre")
    check(all(os.path.isfile(os.path.join(usr, "share", "licenses", "alpe-shell", f)) for f in ("LICENSE", "NOTICE")),
          "/usr/share/licenses/alpe-shell/{LICENSE,NOTICE}")
    check(os.access(os.path.join(share, "tools", "alpe"), os.X_OK) and os.access(os.path.join(share, "shell", "scripts", "gtk.sh"), os.X_OK)
          and not os.access(os.path.join(share, "tools", "design.py"), os.X_OK),
          "Dateimodi wie im Repository (tools/alpe und shell/scripts/gtk.sh ausführbar, tools/design.py nicht)")
    # Installiert wird nur, was im Repository liegt (keine Zwischendateien aus dem Arbeitsbaum).
    if shutil.which("git"):
        im_repo = set(subprocess.run(["git", "-C", REPO, "ls-files", "shell"], capture_output=True, text=True).stdout.split())
        installiert = {os.path.relpath(os.path.join(d, f), os.path.join(share)) for d, _, fs in os.walk(os.path.join(share, "shell")) for f in fs}
        check(installiert <= im_repo, "unter /usr/share/alpe/shell nur Dateien aus dem Repository: %s" % sorted(installiert - im_repo)[:5])

    if shutil.which("git") and subprocess.run(["git", "-C", REPO, "rev-parse", "--git-dir"], capture_output=True).returncode == 0:
        out = make("dist", "BUILD=" + bau, env=env)
        archiv = os.path.join(bau, "alpe-%s.tar.gz" % brand)
        check(out.returncode == 0 and os.path.isfile(archiv), "make dist: Quellarchiv alpe-%s.tar.gz" % brand, out)
        if os.path.isfile(archiv):
            with tarfile.open(archiv) as handle:
                namen = handle.getnames()
                check("alpe-%s/core/vendor/modules.txt" % brand in namen and "alpe-%s/shell/shell.qml" % brand in namen
                      and not any("/.git/" in n for n in namen), "Archiv mit vendorten Go-Modulen, ohne .git")
                handle.extractall(os.path.join(tmp, "aus"), filter="data")
            quelle = os.path.join(tmp, "aus", "alpe-%s" % brand)
            # Bau aus dem Archiv wie im Paketbau: ohne Netz, mit den vendorten Modulen.
            env_vendor = dict(env, GOFLAGS="-mod=vendor", GOPROXY="off")
            out = make("build", "BUILD=" + os.path.join(tmp, "bau2"), cwd=quelle, env=env_vendor)
            check(out.returncode == 0 and subprocess.run([os.path.join(tmp, "bau2", "alpe-dienst"), "version"], capture_output=True, text=True).stdout.strip()
                  == "alpe-dienst " + brand, "aus dem Archiv ohne Netz gebaut (-mod=vendor, GOPROXY=off), Version stimmt", out)
    else:
        print("kein Git-Repository – make dist übersprungen")
finally:
    shutil.rmtree(tmp, ignore_errors=True)

print("\n%s" % ("alle Prüfungen bestanden" if not failures else "%d FEHLER" % failures))
sys.exit(1 if failures else 0)
