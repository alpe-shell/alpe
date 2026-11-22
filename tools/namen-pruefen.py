#!/usr/bin/env python3
"""Alpe: Namensprüfung (Plan 9, 2.3.3). Sucht dms/dank/dux (Gross/klein) in Inhalt und Pfaden der
versionierten Dateien unter shell, core, plugins, tools, tests, entwicklung, design, lockscreen,
packaging und meldet alles, was nicht auf der Ausnahmeliste tools/namen-ausnahmen.txt steht.

    bash tools/namen-pruefen.sh              meldet (Übersicht je Datei), Ergebnis immer 0
    bash tools/namen-pruefen.sh --liste      jede Fundstelle
    bash tools/namen-pruefen.sh --streng     Ergebnis 1 bei jedem Fund (ab D7.8 in tools/test.sh)

Ausnahmeliste: je Zeile «PFAD-GLOB<Tab>ZEILEN-MUSTER<Tab>FRIST<Tab>GRUND». ZEILEN-MUSTER ist ein
regulärer Ausdruck, «*» heisst ganze Datei (auch der Pfad). Jeder Eintrag braucht eine Frist.
"""
import collections
import fnmatch
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BEREICH = ["shell", "core", "plugins", "tools", "tests", "entwicklung", "design", "lockscreen", "packaging"]
SUCHE = re.compile(r"dms|dank|dux", re.IGNORECASE)
AUSNAHMEN = os.path.join(REPO, "tools", "namen-ausnahmen.txt")


def ausnahmen():
    eintraege = []
    with open(AUSNAHMEN, encoding="utf-8") as handle:
        for nummer, zeile in enumerate(handle, 1):
            if not zeile.strip() or zeile.startswith("#"):
                continue
            teile = zeile.rstrip("\n").split("\t")
            if len(teile) < 4 or not teile[2].strip():
                sys.exit("%s:%d: Eintrag braucht Pfad, Muster, Frist und Grund" % (AUSNAHMEN, nummer))
            eintraege.append((teile[0], None if teile[1] == "*" else re.compile(teile[1]), teile[2]))
    return eintraege


def erlaubt(pfad, zeile, liste):
    for glob, pat, _frist in liste:
        if fnmatch.fnmatch(pfad, glob) and (pat is None or (zeile is not None and pat.search(zeile))):
            return True
    return False


def main():
    liste_zeigen = "--liste" in sys.argv
    streng = "--streng" in sys.argv
    regeln = ausnahmen()
    namen = subprocess.run(["git", "-C", REPO, "ls-files", "-z", "--"] + BEREICH, capture_output=True, text=True, check=True).stdout.split("\0")
    funde = collections.Counter()
    zeilen = []
    for pfad in filter(None, namen):
        if SUCHE.search(pfad) and not erlaubt(pfad, None, regeln):
            funde[pfad] += 1
            zeilen.append("%s: (Dateiname)" % pfad)
        voll = os.path.join(REPO, pfad)
        if os.path.islink(voll) or not os.path.isfile(voll):
            continue
        with open(voll, "rb") as handle:
            daten = handle.read()
        if b"\0" in daten[:8192]:
            continue
        for nummer, zeile in enumerate(daten.decode("utf-8", "replace").splitlines(), 1):
            if SUCHE.search(zeile) and not erlaubt(pfad, zeile, regeln):
                funde[pfad] += 1
                zeilen.append("%s:%d: %s" % (pfad, nummer, zeile.strip()[:140]))
    gesamt = sum(funde.values())
    if liste_zeigen:
        print("\n".join(zeilen))
    else:
        for pfad, anzahl in funde.most_common(15):
            print("%6d  %s" % (anzahl, pfad))
        if len(funde) > 15:
            print("   …  und %d weitere Dateien" % (len(funde) - 15))
    print("Namensprüfung: %d Fundstellen in %d Dateien ausserhalb der Ausnahmeliste (%d Einträge)" % (gesamt, len(funde), len(regeln)))
    return 1 if (streng and gesamt) else 0


if __name__ == "__main__":
    sys.exit(main())
