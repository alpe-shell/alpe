#!/usr/bin/env python3
"""Alpe: Lizenzangaben in NOTICE, LICENSES/ und Makefile passen zum Code (Entscheide des Maintainers vom 25.11.2026).

    python3 tests/test_lizenzen.py

go-udev (GPL-3.0-only) im Dienst: NOTICE nennt das Modul mit der Fassung aus core/go.mod und jede Datei, die es
einbindet; der Lizenztext liegt unter LICENSES/ und make install legt ihn nach /usr/share/licenses/alpe-shell.
Ohne Bau, ohne Netz.
"""
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


def lies(*teile):
    with open(os.path.join(REPO, *teile), encoding="utf-8") as handle:
        return handle.read()


notice = lies("NOTICE")
makefile = lies("Makefile")
gomod = lies("core", "go.mod")


def block(modul):
    """Der Eintrag eines Go-Moduls in NOTICE: Kopfzeile mit dem Modulpfad, dann eingerückte Zeilen."""
    treffer = re.search(r"^%s\n((?:  .*\n)+)" % re.escape(modul), notice, re.M)
    return treffer.group(1) if treffer else ""


def go_dateien_mit_import(paket):
    """Go-Dateien unter core/ (ohne Tests und vendor/), die das Paket einbinden."""
    funde = []
    for wurzel, ordner, dateien in os.walk(os.path.join(REPO, "core")):
        ordner[:] = [o for o in ordner if o != "vendor"]
        for datei in dateien:
            if datei.endswith(".go") and not datei.endswith("_test.go"):
                pfad = os.path.join(wurzel, datei)
                with open(pfad, encoding="utf-8") as handle:
                    if '"%s' % paket in handle.read():
                        funde.append(os.path.relpath(pfad, REPO))
    return sorted(funde)


# --- go-udev (Entscheid 1.1) ---
modul = "github.com/pilebones/go-udev"
fassung = re.search(r"^\s*%s (v\S+)" % re.escape(modul), gomod, re.M)
check(fassung is not None, "core/go.mod führt %s" % modul)
eintrag = block(modul)
check(eintrag != "", "NOTICE hat einen eigenen Eintrag für %s" % modul)
if fassung and eintrag:
    check(re.search(r"Fassung:\s+%s\b" % re.escape(fassung.group(1)), eintrag) is not None,
          "NOTICE nennt die Fassung aus core/go.mod (%s)" % fassung.group(1))
    check("GPL-3.0-only" in eintrag and "LICENSES/GPL-3.0-only.txt" in eintrag
          and "/usr/share/licenses/alpe-shell/GPL-3.0-only.txt" in eintrag,
          "NOTICE: Lizenz GPL-3.0-only, Lizenztext im Repository und im Paket")
    check("MIT" in eintrag and "alpe-dienst als Ganzes" in eintrag,
          "NOTICE: Quelltext MIT, das Programm alpe-dienst als Ganzes unter den Bedingungen der GPL-3.0")
    benutzt = go_dateien_mit_import(modul)
    genannt = sorted(re.findall(r"core/\S+\.go", eintrag))
    check(benutzt and benutzt == genannt, "NOTICE nennt jede Datei, die %s einbindet (Code: %s; NOTICE: %s)" % (modul, benutzt, genannt))

gpl = os.path.join(REPO, "LICENSES", "GPL-3.0-only.txt")
check(os.path.isfile(gpl) and lies("LICENSES", "GPL-3.0-only.txt").lstrip().startswith("GNU GENERAL PUBLIC LICENSE\n                       Version 3, 29 June 2007"),
      "LICENSES/GPL-3.0-only.txt ist der Text der GPL, Version 3")
check(re.search(r"^\tinstall -Dm644 LICENSES/GPL-3\.0-only\.txt \$\(DESTDIR\)\$\(PREFIX\)/share/licenses/alpe-shell/GPL-3\.0-only\.txt$",
                makefile, re.M) is not None,
      "make install legt den Text der GPL-3.0 nach /usr/share/licenses/alpe-shell")
# Im Quellarchiv (git archive HEAD) ist nur, was versioniert ist.
if subprocess.run(["git", "-C", REPO, "rev-parse", "--git-dir"], capture_output=True).returncode == 0:
    versioniert = subprocess.run(["git", "-C", REPO, "ls-files", "--error-unmatch", "LICENSES/GPL-3.0-only.txt"],
                                 capture_output=True).returncode == 0
    check(versioniert, "LICENSES/GPL-3.0-only.txt ist versioniert (kommt damit ins Quellarchiv)")

print("\n%s" % ("alle Prüfungen bestanden" if not failures else "%d FEHLER" % failures))
sys.exit(1 if failures else 0)
