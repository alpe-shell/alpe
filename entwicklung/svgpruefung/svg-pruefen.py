#!/usr/bin/env python3
"""Alpe – SVG-Dateien mit QtSvg laden und die Meldungen je Datei nennen.

    python3 entwicklung/svgpruefung/svg-pruefen.py                 die SVG-Dateien des Repositories
    python3 entwicklung/svgpruefung/svg-pruefen.py ORDNER [ORDNER…]  alle *.svg unter den Ordnern (etwa ein Symbolthema)
    Option: --nur TEXT    nur Meldungen, die TEXT enthalten (etwa "Invalid path data")

Anlass (Mac-Test vom 23.11.2026): Im Protokoll der Shell steht «qt.svg: Invalid path data; path truncated»
ohne Dateinamen. Dieses Skript lädt jede Datei einzeln mit QSvgRenderer und ordnet die Meldungen zu.
Braucht PySide6. Ergebnis: 0 = keine Meldung, 1 = Meldungen, 2 = Aufruffehler oder PySide6 fehlt.
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def dateien(ordner):
    if not ordner:
        liste = subprocess.run(["git", "-C", REPO, "ls-files", "-z", "*.svg"], capture_output=True, check=True)
        return sorted(os.path.join(REPO, p) for p in liste.stdout.decode("utf-8", "replace").split("\0") if p)
    gefunden = set()
    for wurzel in ordner:
        for pfad, _dirs, namen in os.walk(wurzel, followlinks=True):
            gefunden.update(os.path.realpath(os.path.join(pfad, n)) for n in namen if n.endswith(".svg"))
    return sorted(gefunden)


def pruefe(pfade, nur=""):
    """Meldungen von QtSvg je Datei: {pfad: [meldung, …]}."""
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    from PySide6.QtCore import qInstallMessageHandler
    from PySide6.QtGui import QGuiApplication
    from PySide6.QtSvg import QSvgRenderer

    app = QGuiApplication.instance() or QGuiApplication([])
    aktuell, meldungen = [None], {}

    def handler(_art, _kontext, text):
        if aktuell[0] is not None and nur in text:
            meldungen.setdefault(aktuell[0], []).append(text)

    alt = qInstallMessageHandler(handler)
    try:
        for pfad in pfade:
            aktuell[0] = pfad
            if not QSvgRenderer(pfad).isValid() and not nur:
                meldungen.setdefault(pfad, []).append("Datei lässt sich nicht laden")
    finally:
        aktuell[0] = None
        qInstallMessageHandler(alt)
    del app
    return meldungen


def main(argv):
    args, nur = argv[1:], ""
    if "--nur" in args:
        stelle = args.index("--nur")
        if stelle + 1 >= len(args):
            print(__doc__, file=sys.stderr)
            return 2
        nur = args[stelle + 1]
        del args[stelle:stelle + 2]
    if any(a.startswith("--") for a in args):
        print(__doc__, file=sys.stderr)
        return 2
    try:
        import PySide6  # noqa: F401
    except ImportError:
        print("PySide6 fehlt (pip install PySide6)", file=sys.stderr)
        return 2
    pfade = dateien(args)
    meldungen = pruefe(pfade, nur)
    for pfad in sorted(meldungen):
        for text in sorted(set(meldungen[pfad])):
            print("%s: %d × %s" % (pfad, meldungen[pfad].count(text), text))
    print("%d Dateien geladen, %d mit Meldung" % (len(pfade), len(meldungen)))
    return 1 if meldungen else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
