#!/usr/bin/env python3
"""Alpe – Standbild der Sperre aus dem Video des ausgelieferten Designs erzeugen (Plan 0.8 Nr. 106).

    python3 tools/standbild.py             design/kde/bilder/jagged-peaks-wolkenzug.jpg neu schreiben (braucht ffmpeg)
    python3 tools/standbild.py --pruefen   nur prüfen, ohne ffmpeg: Bild da, Video und Bild wie festgehalten

Läuft von Hand, nicht beim Paketbau. Das Bild liegt als fertige Datei im Repository; die Shell nimmt es vor ffmpeg
(shell/Common/VideoPoster.js), design.py kopiert es mit.

Prüfsummen: QUELLE_SHA256 ist die Prüfsumme des Videos, aus dem das Bild entstand, BILD_SHA256 die des Bilds.
tests/test_standbild.py wird rot, wenn das Video sich ändert, ohne dass das Bild neu erzeugt wurde, oder wenn das
Bild fehlt oder sich ändert. Ändert sich das Video: QUELLE_SHA256 unten (mit Edit) auf die neue Prüfsumme setzen,
dieses Skript laufen lassen und BILD_SHA256 auf die Zahl setzen, die es danach nennt. Das Skript schreibt genau
eine Datei, das Bild; die beiden Prüfsummen trägt man von Hand nach.

Aufruf von ffmpeg: derselbe wie in der Shell (FILTER und QUALITAET aus shell/Common/VideoPoster.js, verglichen in
tests/test_standbild.py). Grössengrenze: 1 MiB, wie die Prüfung neuer Dateien (tests/test_neue_dateien.py); es
gibt dort keine Ausnahme. Liegt das Bild mit dem Aufruf der Shell darüber, nimmt das Skript die feste Qualität
ERSATZ_QUALITAET (ffmpeg -q:v 5, gleiche Breite); liegt es auch dann darüber, bricht es ohne Bild ab.
Gemessen am 25.11.2026 (ffmpeg n9.0.2): mit dem Aufruf der Shell 695 295 Byte, 3440 × 1440 – die Ersatzqualität
wird heute nicht gebraucht.
"""
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VIDEO = os.path.join(REPO, "design", "kde", "bilder", "jagged-peaks-wolkenzug.mp4")
BILD = os.path.join(REPO, "design", "kde", "bilder", "jagged-peaks-wolkenzug.jpg")

QUELLE_SHA256 = "c7f6312f630de4eb2d9be885e9ba344423cfeae3e3450453ab68582d4e1db551"
BILD_SHA256 = "476032963cc1655cab578e478a84d2c9f3562dbb8ab8eb1584663dabe96d6f00"

FILTER = "thumbnail=60,scale='min(3840,iw)':-2"     # wie VideoPoster.FILTER
QUALITAET = "2"                                      # wie VideoPoster.QUALITY
ERSATZ_QUALITAET = "5"                               # nur, wenn das Bild mit QUALITAET über GRENZE liegt
GRENZE = 1024 * 1024                                 # Byte, wie tests/test_neue_dateien.py


def sha256(pfad):
    h = hashlib.sha256()
    with open(pfad, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def pruefen(video=VIDEO, bild=BILD, quelle=QUELLE_SHA256, bild_summe=BILD_SHA256):
    """Liste der Fehler (leer = in Ordnung). Braucht kein ffmpeg."""
    fehler = []
    if not os.path.isfile(video):
        fehler.append("Video fehlt: %s" % os.path.relpath(video, REPO))
    elif sha256(video) != quelle:
        fehler.append("Video geändert (Prüfsumme %s statt %s): Standbild neu erzeugen – QUELLE_SHA256 in tools/standbild.py "
                      "nachführen, Skript laufen lassen, BILD_SHA256 nachführen" % (sha256(video), quelle))
    if not os.path.isfile(bild):
        fehler.append("Standbild fehlt: %s (python3 tools/standbild.py)" % os.path.relpath(bild, REPO))
    else:
        if sha256(bild) != bild_summe:
            fehler.append("Standbild geändert (Prüfsumme %s statt %s): nicht aus dem festgehaltenen Lauf von tools/standbild.py"
                          % (sha256(bild), bild_summe))
        if os.path.getsize(bild) > GRENZE:
            fehler.append("Standbild grösser als 1 MiB (%d Byte)" % os.path.getsize(bild))
    return fehler


def erzeugen(ziel, qualitaet):
    subprocess.run(["ffmpeg", "-nostdin", "-v", "error", "-i", VIDEO, "-vf", FILTER, "-frames:v", "1", "-q:v", qualitaet,
                    "-y", ziel], check=True)
    return os.path.getsize(ziel)


def main(argv):
    if argv[1:] == ["--pruefen"]:
        fehler = pruefen()
        for f in fehler:
            print("FEHLER: " + f)
        print("Standbild in Ordnung" if not fehler else "%d Fehler" % len(fehler))
        return 1 if fehler else 0
    if argv[1:]:
        print(__doc__, file=sys.stderr)
        return 2
    if not shutil.which("ffmpeg"):
        print("FEHLER: ffmpeg fehlt – das Standbild wird nur von Hand erzeugt, nicht beim Paketbau", file=sys.stderr)
        return 2
    summe = sha256(VIDEO)
    if summe != QUELLE_SHA256:
        print("FEHLER: Das Video hat die Prüfsumme %s, festgehalten ist %s. Zuerst QUELLE_SHA256 in tools/standbild.py "
              "auf die neue Prüfsumme setzen, dann erneut aufrufen. Kein Bild geschrieben." % (summe, QUELLE_SHA256), file=sys.stderr)
        return 1
    with tempfile.TemporaryDirectory(prefix="alpe-standbild-") as tmp:
        teil = os.path.join(tmp, "standbild.jpg")
        groesse, qualitaet = erzeugen(teil, QUALITAET), QUALITAET
        if groesse > GRENZE:
            print("Mit dem Aufruf der Shell %d Byte, über 1 MiB – nehme die feste Ersatzqualität -q:v %s" % (groesse, ERSATZ_QUALITAET))
            groesse, qualitaet = erzeugen(teil, ERSATZ_QUALITAET), ERSATZ_QUALITAET
        if groesse > GRENZE:
            print("FEHLER: auch mit -q:v %s noch %d Byte – kein Bild geschrieben" % (ERSATZ_QUALITAET, groesse), file=sys.stderr)
            return 1
        shutil.copyfile(teil, BILD)
    neu = sha256(BILD)
    print("Standbild geschrieben: %s (%d Byte, -q:v %s), Prüfsumme %s" % (os.path.relpath(BILD, REPO), groesse, qualitaet, neu))
    if neu != BILD_SHA256:
        print("HINWEIS: BILD_SHA256 in tools/standbild.py auf %s setzen (sonst wird tests/test_standbild.py rot)" % neu)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
