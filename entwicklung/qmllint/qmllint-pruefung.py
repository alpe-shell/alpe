#!/usr/bin/env python3
"""Alpe: qmllint über die ganze Oberfläche, verglichen mit einer Grundlinie (Plan 0.8 Nr. 63).

Teil der Haltprüfung, nicht von tools/test.sh: Der Lauf braucht qmllint aus Qt 6 und dauert.

    python3 entwicklung/qmllint/qmllint-pruefung.py                vergleichen mit grundlinie.txt
    python3 entwicklung/qmllint/qmllint-pruefung.py --grundlinie   Grundlinie neu schreiben
    Optionen: --shell ORDNER (statt shell/)  --liste DATEI (alle Meldungen dieses Laufs dorthin)

Vorgehen: entwicklung/mklint.py baut in einem Temp-Ordner einen Baum, in dem qmllint die Module
qs.* auflösen kann (qmldir je Ordner, Attrappen für Quickshell). Jede Meldung wird ohne Zeile,
Spalte und Temp-Pfad festgehalten: «Stufe Datei: Text [Kategorie]». Verglichen wird als
Mehrfachmenge – dieselbe Meldung zweimal in einer Datei zählt zweimal.

Ergebnis: 0 = keine neue Meldung, 1 = neue Meldungen (einzeln einordnen: beheben oder mit
Begründung in die Grundlinie), 2 = Lauf gescheitert. qmllint: $QMLLINT, sonst /usr/lib/qt6/bin/qmllint.
"""
import collections
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
GRUNDLINIE = os.path.join(HERE, "grundlinie.txt")
MELDUNG = re.compile(r"^(Warning|Error|Info|Hint): (.+?\.qml):\d+:\d+: (.*)$")


def qmllint():
    for kandidat in (os.environ.get("QMLLINT"), "/usr/lib/qt6/bin/qmllint", shutil.which("qmllint6"), shutil.which("qmllint-qt6")):
        if kandidat and os.path.exists(kandidat):
            return kandidat
    return None


def lauf(shell, tmp):
    baum = os.path.join(tmp, "lint")
    bau = subprocess.run([sys.executable, os.path.join(REPO, "entwicklung", "mklint.py"), shell, baum], capture_output=True, text=True)
    if bau.returncode != 0:
        sys.exit("mklint.py gescheitert:\n" + bau.stdout + bau.stderr)
    wurzel = os.path.join(baum, "qs")
    dateien = sorted(os.path.join(ordner, name) for ordner, _, namen in os.walk(wurzel) for name in namen if name.endswith(".qml"))
    meldungen = collections.Counter()
    programm = qmllint()
    for start in range(0, len(dateien), 40):
        aus = subprocess.run([programm, "-I", baum] + dateien[start:start + 40], capture_output=True, text=True)
        for zeile in (aus.stderr + aus.stdout).splitlines():
            treffer = MELDUNG.match(zeile)
            if not treffer:
                continue
            stufe, datei, text = treffer.groups()
            text = text.replace(wurzel + os.sep, "qs/").replace(baum + os.sep, "")
            meldungen["%s %s: %s" % (stufe, os.path.relpath(datei, wurzel), text)] += 1
    return meldungen, len(dateien)


def lies(pfad):
    with open(pfad, encoding="utf-8") as handle:
        return collections.Counter(z.rstrip("\n") for z in handle if z.strip() and not z.startswith("#"))


def schreibe(pfad, meldungen, kopf=""):
    with open(pfad, "w", encoding="utf-8") as handle:
        handle.write(kopf)
        for zeile in sorted(meldungen.elements()):
            handle.write(zeile + "\n")


def main(args):
    programm = qmllint()
    if not programm:
        print("qmllint aus Qt 6 nicht gefunden (QMLLINT setzen oder Qt-6-Werkzeuge installieren)")
        return 2
    shell = os.path.abspath(args[args.index("--shell") + 1]) if "--shell" in args else os.path.join(REPO, "shell")
    version = subprocess.run([programm, "--version"], capture_output=True, text=True).stdout.strip()
    tmp = tempfile.mkdtemp(prefix="alpe-qmllint-", dir=os.environ.get("ALPE_LP_TMP") or None)
    try:
        meldungen, anzahl = lauf(shell, tmp)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    gesamt = sum(meldungen.values())
    print("%s über %d Dateien: %d Meldungen" % (version, anzahl, gesamt))
    if gesamt == 0:
        print("FEHLER: keine einzige Meldung – der Lauf hat nicht funktioniert")
        return 2
    if "--liste" in args:
        schreibe(args[args.index("--liste") + 1], meldungen)
    if "--grundlinie" in args:
        schreibe(GRUNDLINIE, meldungen, "# Grundlinie von qmllint über shell/ (%s): %d Meldungen. Neu schreiben:\n"
                 "# python3 entwicklung/qmllint/qmllint-pruefung.py --grundlinie (Plan 0.8 Nr. 63)\n" % (version, gesamt))
        print("Grundlinie geschrieben: %s" % os.path.relpath(GRUNDLINIE, REPO))
        return 0
    if not os.path.exists(GRUNDLINIE):
        print("keine Grundlinie – zuerst mit --grundlinie schreiben")
        return 2
    grund = lies(GRUNDLINIE)
    neu, weg = meldungen - grund, grund - meldungen
    print("Grundlinie: %d   neu: %d   nicht mehr da: %d" % (sum(grund.values()), sum(neu.values()), sum(weg.values())))
    for zeile in sorted(neu.elements()):
        print("NEU   " + zeile)
    for zeile in sorted(weg.elements()):
        print("WEG   " + zeile)
    return 1 if neu else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
