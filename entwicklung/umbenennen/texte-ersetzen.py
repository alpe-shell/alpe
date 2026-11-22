#!/usr/bin/env python3
"""Alpe: Texte, Kommentare und Testdaten mit alten Namen ersetzen – nur auf den Zeilen, die die
Namensprüfung meldet (Plan 2.3.5, D7.7e–D7.7h). Zeilen der Ausnahmeliste bleiben damit unberührt.

    python3 entwicklung/umbenennen/texte-ersetzen.py REGELN.tsv PFAD-PRÄFIX…              Probelauf
    python3 entwicklung/umbenennen/texte-ersetzen.py REGELN.tsv PFAD-PRÄFIX… --schreiben

REGELN.tsv: «MUSTER<Tab>ERSATZ» je Zeile (regulärer Ausdruck, # = Kommentar); die Regeln werden
der Reihe nach auf jede gemeldete Zeile angewendet. Am Ende steht, welche gemeldeten Zeilen
keine Regel getroffen hat.
"""
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    schreiben = "--schreiben" in sys.argv
    if len(args) < 2:
        sys.exit(__doc__)
    regeln = []
    with open(args[0], encoding="utf-8") as handle:
        for zeile in handle:
            zeile = zeile.rstrip("\n")
            if not zeile.strip() or zeile.startswith("#"):
                continue
            muster, _, ersatz = zeile.partition("\t")
            regeln.append((re.compile(muster), ersatz))
    liste = subprocess.run([sys.executable, os.path.join(REPO, "tools", "namen-pruefen.py"), "--liste"],
                           capture_output=True, text=True).stdout
    gemeldet = {}
    for eintrag in liste.splitlines():
        treffer = re.match(r"([^:]+):(\d+): ", eintrag)
        if treffer and any(treffer.group(1).startswith(p) for p in args[1:]):
            gemeldet.setdefault(treffer.group(1), set()).add(int(treffer.group(2)))
    ersetzt = offen = 0
    for name, nummern in sorted(gemeldet.items()):
        pfad = os.path.join(REPO, name)
        with open(pfad, encoding="utf-8") as handle:
            zeilen = handle.read().split("\n")
        for nummer in sorted(nummern):
            alt = neu = zeilen[nummer - 1]
            for muster, ersatz in regeln:
                neu = muster.sub(ersatz, neu)
            if neu != alt:
                ersetzt += 1
                zeilen[nummer - 1] = neu
            if re.search(r"dms|dank|dux", neu, re.IGNORECASE):
                offen += 1
                print("offen  %s:%d: %s" % (name, nummer, neu.strip()[:150]))
        if schreiben:
            with open(pfad, "w", encoding="utf-8") as handle:
                handle.write("\n".join(zeilen))
    print("%d Zeilen ersetzt, %d offen%s" % (ersetzt, offen, "" if schreiben else " – Probelauf, nichts geschrieben"))


if __name__ == "__main__":
    main()
