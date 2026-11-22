#!/usr/bin/env python3
"""Alpe D7.2b (Plan 2.3.0, 0.8 Nr. 27): Übergangs-Hüllen unter shell/DCommon/Widgets/ erzeugen.

Fremde Plugins (sathiAi) importieren noch qs.DCommon.Widgets und benutzen D*-Typen. Für jeden Typ
aus shell/Alpe/Widgets/ entsteht eine Hülle unter dem alten Namen, die vom Typ unter qs.Alpe.Widgets
erbt und beim Laden einen Hinweis ausgibt. Keine eigenen Singletons. Fällt in D7.8 weg.

    python3 entwicklung/umbenennen/d7-2b-huellen.py   schreibt die Hüllen neu (vorhandene werden ersetzt)
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
QUELLE = os.path.join(REPO, "shell", "Alpe", "Widgets")
ZIEL = os.path.join(REPO, "shell", "DCommon", "Widgets")
KOPF = "// Übergang bis D7.8 (Plan 2.3.0): Hülle für Plugins, die noch qs.DCommon.Widgets importieren.\n"


def main():
    os.makedirs(ZIEL, exist_ok=True)
    for alt in os.listdir(ZIEL):
        if alt.endswith(".qml"):
            os.remove(os.path.join(ZIEL, alt))
    anzahl = 0
    for datei in sorted(os.listdir(QUELLE)):
        if not datei.endswith(".qml"):
            continue
        with open(os.path.join(QUELLE, datei), encoding="utf-8") as handle:
            if re.search(r"^pragma Singleton", handle.read(), re.M):
                continue
        neu = datei[:-4]
        if neu.startswith("Alpe"):
            alt = "D" + neu[4:]
            hinweis = 'Deprecation.type(shim, "%s", "%s", "qs.Alpe.Widgets")' % (alt, neu)
        else:
            alt = neu
            hinweis = 'Deprecation.module(shim, "%s", "qs.DCommon.Widgets", "qs.Alpe.Widgets")' % neu
        with open(os.path.join(ZIEL, alt + ".qml"), "w", encoding="utf-8") as handle:
            handle.write(KOPF + "import QtQuick\nimport qs.Common\nimport qs.Alpe.Widgets as Alpe\n\n"
                         "Alpe.%s {\n    id: shim\n    Component.onCompleted: %s\n}\n" % (neu, hinweis))
        anzahl += 1
    print("%d Hüllen in %s" % (anzahl, os.path.relpath(ZIEL, REPO)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
