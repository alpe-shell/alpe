#!/usr/bin/env python3
"""Alpe: Makefile in der Wurzel (Plan Abschnitt 1 und 6.1; Nachtlauf-Auftrag E1 2.2).

    python3 tests/test_makefile.py

Prüft in einem Temp-Ordner: «make build» baut den Dienst ohne eingebettete Oberfläche und mit der Version aus
Brand.qml; «make install DESTDIR=… PREFIX=/usr» legt den Baum nach 6.1 an (Werkzeuge nur aus der ausdrücklichen
Liste, keine Tests der Oberfläche), und die ganze Dateiliste stimmt mit dem Codeblock in Plan 6.1 überein; keine
Datei gehört zugleich dem Paket des Ursprungs (pacman -Ql, nur wenn es installiert ist; E1 2.8); «make dist» schreibt ein Quellarchiv mit vendorten Go-Modulen, aus dem sich der
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
    # -mod=… aus der Umgebung stört den Bau aus dem Repository; anderes (etwa -modcacherw, CLAUDE.md) bleibt.
    flags = [f for f in env.get("GOFLAGS", "").split() if not f.startswith("-mod=")]
    env["GOFLAGS"] = " ".join(flags)
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
    vorher = os.stat(dienst).st_mtime_ns if os.path.exists(dienst) else None
    out = make("install", "BUILD=" + bau, "DESTDIR=" + wurzel, "PREFIX=/usr", env=env)
    check(out.returncode == 0, "make install DESTDIR=… PREFIX=/usr läuft durch", out)
    check(vorher is not None and os.stat(dienst).st_mtime_ns == vorher,
          "make install baut den Dienst nicht neu (im Paketbau gingen sonst die GOFLAGS des Bauschritts verloren)")
    usr = os.path.join(wurzel, "usr")
    check(os.access(os.path.join(usr, "bin", "alpe-dienst"), os.X_OK), "/usr/bin/alpe-dienst")
    check(os.readlink(os.path.join(usr, "bin", "alpe")) == "../share/alpe/tools/alpe" if os.path.islink(os.path.join(usr, "bin", "alpe")) else False,
          "/usr/bin/alpe -> ../share/alpe/tools/alpe")
    share = os.path.join(usr, "share", "alpe")
    check(sorted(os.listdir(share)) == ["assets", "design", "lockscreen", "plugins", "shell", "tools"],
          "/usr/share/alpe/{shell,plugins,tools,design,lockscreen,assets}")
    check(os.listdir(os.path.join(share, "assets")) == ["fastfetch-logo.txt"]
          and os.path.isfile(os.path.join(share, "tools", "..", "assets", "fastfetch-logo.txt")),
          "Logo für fastfetch dort, wo tools/fastfetch.py es liest (../assets/fastfetch-logo.txt), sonst nichts aus assets/")
    check(sorted(os.listdir(os.path.join(share, "tools"))) == sorted(tools_liste), "unter /usr/share/alpe/tools genau die Werkzeuge der Liste")
    check(os.path.isfile(os.path.join(share, "shell", "shell.qml")) and not os.path.exists(os.path.join(share, "shell", "tests"))
          and not os.path.exists(os.path.join(share, "plugins", "claudeCodeUsage", "tests"))
          and not any(f.endswith(".py") for f in os.listdir(os.path.join(share, "shell", "translations"))),
          "Oberfläche und Plugins ohne Tests und ohne Übersetzungswerkzeuge")
    check(os.path.isfile(os.path.join(share, "design", "kde", "bilder", "jagged-peaks-wolkenzug.jpg")), "Design mit Standbild der Sperre")
    sperr = os.path.join(usr, "share", "plasma", "shells", "org.alpe.desktop")
    check(all(os.path.isfile(os.path.join(sperr, *p)) for p in (("metadata.json",), ("contents", "lockscreen", "LockScreen.qml"),
                                                                ("contents", "lockscreen", "HyprlockView.qml"), ("contents", "lockscreen", "layout.js")))
          and '"Version": "%s"' % brand in open(os.path.join(sperr, "metadata.json"), encoding="utf-8").read(),
          "/usr/share/plasma/shells/org.alpe.desktop zusammengesetzt, Version aus Brand.qml")
    appid = "io.github.alpe_shell.Alpe"
    pakete = ["lib/systemd/user/alpe.service", "share/applications/%s.desktop" % appid, "share/applications/%s.Notepad.desktop" % appid,
              "share/applications/alpe-open.desktop", "share/icons/hicolor/scalable/apps/%s.svg" % appid,
              "share/bash-completion/completions/alpe-dienst", "share/zsh/site-functions/_alpe-dienst",
              "share/fish/vendor_completions.d/alpe-dienst.fish"]
    fehlt = [p for p in pakete if not os.path.isfile(os.path.join(usr, p))]
    check(not fehlt, "Unit, Desktop-Dateien, Symbol und Vervollständigungen nach 6.1 installiert (fehlt: %s)" % fehlt)
    if not fehlt:
        check(open(os.path.join(usr, "share", "bash-completion", "completions", "alpe-dienst"), encoding="utf-8").read().startswith("# bash completion")
              and "#compdef alpe-dienst" in open(os.path.join(usr, "share", "zsh", "site-functions", "_alpe-dienst"), encoding="utf-8").read()
              and "complete -c alpe-dienst" in open(os.path.join(usr, "share", "fish", "vendor_completions.d", "alpe-dienst.fish"), encoding="utf-8").read(),
              "Vervollständigungen aus dem gebauten Dienst (bash, zsh, fish)")
    # Mit anderem PREFIX zeigen Unit und Desktop-Datei auf den Baum unter PREFIX.
    anders = os.path.join(tmp, "wurzel-opt")
    out = make("install", "BUILD=" + bau, "DESTDIR=" + anders, "PREFIX=/opt/alpe", env=env)
    opt = os.path.join(anders, "opt", "alpe")
    check(out.returncode == 0
          and "ExecStart=/opt/alpe/bin/alpe start --session" in open(os.path.join(opt, "lib", "systemd", "user", "alpe.service"), encoding="utf-8").read()
          and "Exec=alpe-dienst run -c /opt/alpe/share/alpe/shell" in open(os.path.join(opt, "share", "applications", appid + ".desktop"), encoding="utf-8").read(),
          "PREFIX=/opt/alpe: ExecStart und Exec zeigen auf /opt/alpe", out)
    check(all(os.path.isfile(os.path.join(usr, "share", "licenses", "alpe-shell", f)) for f in ("LICENSE", "NOTICE")),
          "/usr/share/licenses/alpe-shell/{LICENSE,NOTICE}")
    gpl_paket = os.path.join(usr, "share", "licenses", "alpe-shell", "GPL-3.0-only.txt")
    check(os.path.isfile(gpl_paket) and open(gpl_paket, "rb").read() == open(os.path.join(REPO, "LICENSES", "GPL-3.0-only.txt"), "rb").read(),
          "/usr/share/licenses/alpe-shell/GPL-3.0-only.txt = LICENSES/GPL-3.0-only.txt (go-udev im Dienst, NOTICE)")
    check(os.access(os.path.join(share, "tools", "alpe"), os.X_OK) and os.access(os.path.join(share, "shell", "scripts", "gtk.sh"), os.X_OK)
          and not os.access(os.path.join(share, "tools", "design.py"), os.X_OK),
          "Dateimodi wie im Repository (tools/alpe und shell/scripts/gtk.sh ausführbar, tools/design.py nicht)")
    # Installiert wird nur, was im Repository liegt (keine Zwischendateien aus dem Arbeitsbaum).
    if shutil.which("git"):
        im_repo = set(subprocess.run(["git", "-C", REPO, "ls-files", "shell"], capture_output=True, text=True).stdout.split())
        installiert = {os.path.relpath(os.path.join(d, f), os.path.join(share)) for d, _, fs in os.walk(os.path.join(share, "shell")) for f in fs}
        check(installiert <= im_repo, "unter /usr/share/alpe/shell nur Dateien aus dem Repository: %s" % sorted(installiert - im_repo)[:5])

    # Nachtlauf E1 2.8: die ganze Dateiliste gegen den Codeblock in Plan 6.1. Jede installierte Datei liegt unter
    # einem Eintrag, jeder Eintrag ist da. Ein Eintrag mit «/» am Ende ist ein Ordner, «{a,b}» steht für mehrere,
    # «…» in den Klammern heisst «weitere Dateien in diesem Ordner erlaubt».
    plan = open(os.path.join(REPO, "docs", "plan", "phase-a-plan.md"), encoding="utf-8").read()
    block = re.search(r"^### 6\.1 .*?^```\n(.*?)^```", plan, re.M | re.S).group(1)
    dateien, ordner, pflicht = set(), set(), set()
    for zeile in block.splitlines():
        if not zeile.startswith("/"):
            continue
        eintrag = zeile.split()[0]
        teile = re.match(r"(.*?)\{(.*?)\}(.*)$", eintrag)
        varianten = [teile.group(1) + v + teile.group(3) for v in teile.group(2).split(",")] if teile else [eintrag]
        for pfad in varianten:
            if pfad.endswith("…") or pfad.endswith("…/"):
                ordner.add(pfad[:pfad.rindex("/") + 1])
            elif pfad.endswith("/"):
                ordner.add(pfad)
                pflicht.add(pfad)
            else:
                dateien.add(pfad)
                pflicht.add(pfad)
    liste = sorted("/" + os.path.relpath(os.path.join(d, f), wurzel) for d, ds, fs in os.walk(wurzel)
                   for f in fs + [x for x in ds if os.path.islink(os.path.join(d, x))])
    ausserhalb = [p for p in liste if p not in dateien and not any(p.startswith(o) for o in ordner)]
    fehlend = [p for p in sorted(pflicht) if (p not in liste) if not p.endswith("/")] \
        + [o for o in sorted(pflicht) if o.endswith("/") and not any(p.startswith(o) for p in liste)]
    check(len(dateien) >= 10 and len(ordner) >= 6 and not ausserhalb and not fehlend,
          "Dateiliste von make install = Plan 6.1 (%d Dateien; ausserhalb von 6.1: %s; fehlt: %s)" % (len(liste), ausserhalb[:5], fehlend))
    # Kein Pfad gehört zugleich dem Paket des Ursprungs (nur gelesen mit pacman -Ql; Ordner wie /usr/share/applications
    # teilen sich alle Pakete und zählen nicht). Es darf während des Umzugs als Rückweg installiert bleiben (Plan 6.2).
    # alpe-namen-ausnahme: umzug-ende
    if shutil.which("pacman") and subprocess.run(["pacman", "-Q", "dux-shell"], capture_output=True).returncode == 0:
        fremd = {z.split(" ", 1)[1] for z in subprocess.run(["pacman", "-Ql", "dux-shell"], capture_output=True, text=True).stdout.splitlines()
                 if " " in z and not z.endswith("/")}
        check(fremd and not fremd & set(liste), "keine Datei zugleich im Paket dux-shell (%d Dateien dort): %s" % (len(fremd), sorted(fremd & set(liste))))
    else:
        print("pacman oder das Paket dux-shell fehlt – Abgleich mit dux-shell übersprungen")
    # alpe-namen-ausnahme: umzug-ende

    if shutil.which("git") and subprocess.run(["git", "-C", REPO, "rev-parse", "--git-dir"], capture_output=True).returncode == 0:
        # Erster Lauf ausdrücklich mit umask 022, der zweite unten mit 002 – sonst bewiese der Vergleich nichts,
        # wenn die Umgebung schon 002 hat.
        alt_umask = os.umask(0o022)
        try:
            out = make("dist", "BUILD=" + bau, env=env)
        finally:
            os.umask(alt_umask)
        archiv = os.path.join(bau, "alpe-%s.tar.gz" % brand)
        check(out.returncode == 0 and os.path.isfile(archiv), "make dist: Quellarchiv alpe-%s.tar.gz" % brand, out)
        if os.path.isfile(archiv):
            with tarfile.open(archiv) as handle:
                namen = handle.getnames()
                check("alpe-%s/core/vendor/modules.txt" % brand in namen and "alpe-%s/shell/shell.qml" % brand in namen
                      and "alpe-%s/COMMIT" % brand in namen and not any("/.git/" in n for n in namen),
                      "Archiv mit vendorten Go-Modulen und Datei COMMIT, ohne .git")
                handle.extractall(os.path.join(tmp, "aus"), filter="data")
            # Reproduzierbar: ein zweiter Lauf mit anderer umask ergibt dasselbe Archiv.
            bau_b = os.path.join(tmp, "bau-b")
            alt_umask = os.umask(0o002)
            try:
                out_b = make("dist", "BUILD=" + bau_b, env=env)
            finally:
                os.umask(alt_umask)
            archiv_b = os.path.join(bau_b, os.path.basename(archiv))
            gleich = out_b.returncode == 0 and os.path.isfile(archiv_b) and open(archiv, "rb").read() == open(archiv_b, "rb").read()
            check(gleich, "make dist ist reproduzierbar (zweiter Lauf mit umask 002 bytegleich)", out_b)
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
