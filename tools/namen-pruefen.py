#!/usr/bin/env python3
"""Alpe: Namensprüfung (Plan 9, 2.3.3). Sucht dms/dank/dux (Gross/klein) und Importe über das alte
Modul qs.DCommon (0.8 Nr. 27) sowie die alten D*-Typnamen aus tools/namen-verboten.txt (ganze
Bezeichner, 0.8 Nr. 34) in Inhalt und Pfaden der
versionierten Dateien unter shell, core, plugins, tools, tests, entwicklung, design, lockscreen,
packaging und meldet alles, was nicht auf der Ausnahmeliste tools/namen-ausnahmen.txt steht.

    bash tools/namen-pruefen.sh              meldet (Übersicht je Datei), Ergebnis immer 0
    bash tools/namen-pruefen.sh --liste      jede Fundstelle
    bash tools/namen-pruefen.sh --streng     Ergebnis 1 bei jedem Fund (ab D7.8 in tools/test.sh)

    bash tools/namen-pruefen.sh --bereiche   die Bereiche zwischen zwei Marken (Datei, Zeilen, Frist)

Ausnahmeliste: je Zeile «PFAD-GLOB<Tab>ZEILEN-MUSTER<Tab>FRIST<Tab>GRUND». ZEILEN-MUSTER ist ein
regulärer Ausdruck, «*» heisst ganze Datei (auch der Pfad). Jeder Eintrag braucht eine Frist.

Marken im Code (0.8 Nr. 64): Ein Bereich, der beim Umzug alte Namen lesen muss, steht zwischen zwei
Kommentarzeilen mit «alpe-namen-ausnahme: umzug-ende» (Anfang und Ende gleich). Alles von der ersten
bis zur zweiten Marke ist ausgenommen, ohne Eintrag je Zeile in der Ausnahmeliste. Die Frist steht in
der Marke; erlaubt ist nur, was MARKEN_FRISTEN nennt. Eine Marke ohne Gegenstück, eine unbekannte
Frist oder zwei verschiedene Fristen an Anfang und Ende sind Fundstellen (rot mit --streng).
"""
import collections
import fnmatch
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BEREICH = ["shell", "core", "plugins", "tools", "tests", "entwicklung", "design", "lockscreen", "packaging"]
SUCHE = re.compile(r"dms|dank|dux|qs\.DCommon", re.IGNORECASE)
AUSNAHMEN = os.path.join(REPO, "tools", "namen-ausnahmen.txt")
VERBOTEN = os.path.join(REPO, "tools", "namen-verboten.txt")
# Marke im Code: «alpe-namen-ausnahme: <frist>» in einer Kommentarzeile, paarweise (Anfang, Ende).
MARKE = re.compile(r"alpe-namen-ausnahme:[ \t]*([A-Za-z0-9-]*)")
MARKEN_FRISTEN = {"umzug-ende": "Lesen alter Namen bei der Migration (Plan 2.3.3)"}


def verbotene_namen():
    if not os.path.exists(VERBOTEN):
        return None
    with open(VERBOTEN, encoding="utf-8") as handle:
        namen = [z.strip() for z in handle if z.strip() and not z.startswith("#")]
    if not namen:
        return None
    return re.compile(r"(?<![A-Za-z0-9_])(?:" + "|".join(map(re.escape, sorted(namen, key=len, reverse=True))) + r")(?![A-Za-z0-9_])")


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
        # Ohne Zeile geht es um den Dateinamen: Das Muster gilt dann für den Pfad (z. B. fremder Schriftname).
        if fnmatch.fnmatch(pfad, glob) and (pat is None or pat.search(pfad if zeile is None else zeile)):
            return True
    return False


def markierte_zeilen(zeilen):
    """Zeilen zwischen zwei Marken. Ergebnis: (ausgenommene Zeilennummern, Bereiche, Fehler).

    Bereiche: (erste Zeile, letzte Zeile, Frist); Fehler: (Zeilennummer, Text)."""
    frei, bereiche, fehler = set(), [], []
    offen = None  # (Zeilennummer, Frist) der Anfangsmarke
    for nummer, zeile in enumerate(zeilen, 1):
        treffer = MARKE.search(zeile)
        if not treffer:
            continue
        frist = treffer.group(1)
        if frist not in MARKEN_FRISTEN:
            fehler.append((nummer, "Marke mit unbekannter Frist «%s» (erlaubt: %s)" % (frist, ", ".join(sorted(MARKEN_FRISTEN)))))
            continue
        if offen is None:
            offen = (nummer, frist)
            continue
        if frist != offen[1]:
            fehler.append((nummer, "Marke am Ende nennt «%s», am Anfang (Zeile %d) «%s»" % (frist, offen[0], offen[1])))
        bereiche.append((offen[0], nummer, offen[1]))
        frei.update(range(offen[0], nummer + 1))
        offen = None
    if offen is not None:
        fehler.append((offen[0], "Marke ohne Ende – der Bereich braucht eine zweite Marke"))
    return frei, bereiche, fehler


def main():
    liste_zeigen = "--liste" in sys.argv
    bereiche_zeigen = "--bereiche" in sys.argv
    streng = "--streng" in sys.argv
    regeln = ausnahmen()
    alt = verbotene_namen()

    def fund(text):
        return SUCHE.search(text) or (alt is not None and alt.search(text))
    namen = subprocess.run(["git", "-C", REPO, "ls-files", "-z", "--"] + BEREICH, capture_output=True, text=True, check=True).stdout.split("\0")
    funde = collections.Counter()
    zeilen = []
    markiert = []  # (Pfad, erste Zeile, letzte Zeile, Frist, ausgenommene Fundstellen)
    for pfad in filter(None, namen):
        if fund(pfad) and not erlaubt(pfad, None, regeln):
            funde[pfad] += 1
            zeilen.append("%s: (Dateiname)" % pfad)
        voll = os.path.join(REPO, pfad)
        if os.path.islink(voll) or not os.path.isfile(voll):
            continue
        with open(voll, "rb") as handle:
            daten = handle.read()
        if b"\0" in daten[:8192]:
            continue
        text = daten.decode("utf-8", "replace").splitlines()
        # Die Dateien, die die Marke beschreiben oder prüfen, tragen sie als Text, nicht als Marke.
        frei, bereiche, fehler = (set(), [], []) if erlaubt(pfad, None, regeln) else markierte_zeilen(text)
        for nummer, meldung in fehler:
            funde[pfad] += 1
            zeilen.append("%s:%d: %s" % (pfad, nummer, meldung))
        gespart = collections.Counter()
        for nummer, zeile in enumerate(text, 1):
            if fund(zeile) and not erlaubt(pfad, zeile, regeln):
                if nummer in frei:
                    gespart[next(b for b in bereiche if b[0] <= nummer <= b[1])] += 1
                    continue
                funde[pfad] += 1
                zeilen.append("%s:%d: %s" % (pfad, nummer, zeile.strip()[:140]))
        for bereich in bereiche:
            markiert.append((pfad,) + bereich + (gespart[bereich],))
            if not gespart[bereich]:
                # Eine Marke, die nichts mehr ausnimmt, ist überholt und soll verschwinden.
                funde[pfad] += 1
                zeilen.append("%s:%d: Marke nimmt keine Fundstelle aus (Zeilen %d–%d) – entfernen" % (pfad, bereich[0], bereich[0], bereich[1]))
    gesamt = sum(funde.values())
    if bereiche_zeigen:
        for pfad, von, bis, frist, anzahl in markiert:
            print("%s:%d-%d\t%s\t%d Fundstellen" % (pfad, von, bis, frist, anzahl))
    elif liste_zeigen:
        print("\n".join(zeilen))
    else:
        for pfad, anzahl in funde.most_common(15):
            print("%6d  %s" % (anzahl, pfad))
        if len(funde) > 15:
            print("   …  und %d weitere Dateien" % (len(funde) - 15))
    print("Namensprüfung: %d Fundstellen in %d Dateien ausserhalb der Ausnahmeliste (%d Einträge)" % (gesamt, len(funde), len(regeln)))
    if markiert:
        print("Marken «alpe-namen-ausnahme»: %d Bereiche in %d Dateien, %d Fundstellen ausgenommen (Liste: --bereiche)"
              % (len(markiert), len(set(m[0] for m in markiert)), sum(m[4] for m in markiert)))
    return 1 if (streng and gesamt) else 0


if __name__ == "__main__":
    sys.exit(main())
