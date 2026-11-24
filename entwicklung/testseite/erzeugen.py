#!/usr/bin/env python3
"""Alpe – Drucker-Testseite erzeugen (core/internal/config/embedded/testpage.pdf).

    python3 entwicklung/testseite/erzeugen.py            schreibt die eingebettete Datei neu
    python3 entwicklung/testseite/erzeugen.py DATEI      schreibt nach DATEI
    python3 entwicklung/testseite/erzeugen.py --pruefen  vergleicht nur (0 = gleich, 1 = verschieden)

Die Seite ist von Hand als PDF 1.4 geschrieben: eine Seite A4, Schrift Helvetica (eine der 14 Standardschriften,
nichts eingebettet), Inhalt und Metadaten unkomprimiert und ohne Datum – dieselbe Eingabe gibt dieselbe Datei, und
jede Suche nach Namen sieht den ganzen Text. Der Dienst druckt die Datei über «Testseite drucken».
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ZIEL = os.path.join(REPO, "core", "internal", "config", "embedded", "testpage.pdf")
TITEL = "Alpe – Drucker-Testseite"
BREITE, HOEHE = 595, 842          # A4 in Punkten
RAND = 56


def text(wort):
    """PDF-Zeichenkette in WinAnsiEncoding (Latin-1 deckt die Umlaute; der Halbgeviertstrich ist 0x96)."""
    roh = wort.replace("–", "\x96").encode("latin-1")
    return "(" + "".join("\\%03o" % b if b > 126 or b in b"()\\" else chr(b) for b in roh) + ")"


def utf16(wort):
    return "<FEFF" + wort.encode("utf-16-be").hex().upper() + ">"


def inhalt():
    z = []

    def zeile(x, y, groesse, wort, fett=False):
        z.append("BT /%s %d Tf %d %d Td %s Tj ET" % ("F2" if fett else "F1", groesse, x, y, text(wort)))

    zeile(RAND, 770, 26, "Alpe", fett=True)
    zeile(RAND, 746, 13, "Drucker-Testseite")
    z.append("0.6 w %d 734 m %d 734 l S" % (RAND, BREITE - RAND))

    zeile(RAND, 700, 12, "Graustufen", fett=True)
    stufen, breite = 11, (BREITE - 2 * RAND) / 11
    for i in range(stufen):
        z.append("%.2f g %.2f 640 %.2f 44 re f" % (i / (stufen - 1), RAND + i * breite, breite))
    z.append("0 g 0.6 w %d 640 %d 44 re S" % (RAND, BREITE - 2 * RAND))

    zeile(RAND, 600, 12, "Farben", fett=True)
    farben = [(1, 0, 0), (0, 1, 0), (0, 0, 1), (0, 1, 1), (1, 0, 1), (1, 1, 0)]
    breite = (BREITE - 2 * RAND) / len(farben)
    for i, (r, g, b) in enumerate(farben):
        z.append("%d %d %d rg %.2f 540 %.2f 44 re f" % (r, g, b, RAND + i * breite, breite))
    z.append("0 g")

    zeile(RAND, 500, 12, "Schrift", fett=True)
    satz = "Zwölf Boxkämpfer jagen Viktor quer über den grossen Sylter Deich. 0123456789"
    y = 478
    for groesse in (14, 11, 9, 7):
        zeile(RAND, y, groesse, satz)
        y -= groesse + 8

    zeile(RAND, 370, 12, "Linien", fett=True)
    y = 350
    for staerke in (0.25, 0.5, 1, 2, 4):
        z.append("%.2f w %d %d m %d %d l S" % (staerke, RAND, y, BREITE - RAND, y))
        y -= 14
    for i in range(41):
        x = RAND + i * (BREITE - 2 * RAND) / 40
        z.append("0.4 w %.2f 270 m %.2f %d l S" % (x, x, 250 if i % 5 else 240))

    zeile(RAND, 200, 12, "Ränder", fett=True)
    zeile(RAND, 182, 9, "Der Rahmen liegt 20 Punkte (rund 7 mm) vom Blattrand; fehlt eine Seite, schneidet der Drucker dort ab.")
    z.append("0.5 w 20 20 %d %d re S" % (BREITE - 40, HOEHE - 40))

    z.append("0.6 w %d 96 m %d 96 l S" % (RAND, BREITE - RAND))
    zeile(RAND, 78, 9, "Gedruckt mit Alpe, der Desktop-Shell für Linux – https://github.com/alpe-shell/alpe")
    return "\n".join(z) + "\n"


def pdf():
    strom = inhalt().encode("latin-1")
    schrift = "<< /Type /Font /Subtype /Type1 /BaseFont /%s /Encoding /WinAnsiEncoding >>"
    objekte = [
        "<< /Type /Catalog /Pages 2 0 R >>",
        "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 %d %d] /Contents 4 0 R "
        "/Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> >>" % (BREITE, HOEHE),
        None,
        schrift % "Helvetica",
        schrift % "Helvetica-Bold",
        "<< /Title %s /Subject %s /Creator %s /Producer %s >>"
        % (utf16(TITEL), utf16("Testseite für Drucker"), utf16("Alpe"), utf16("entwicklung/testseite/erzeugen.py")),
    ]
    aus = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    stellen = []
    for nummer, objekt in enumerate(objekte, 1):
        stellen.append(len(aus))
        aus += b"%d 0 obj\n" % nummer
        if objekt is None:
            aus += b"<< /Length %d >>\nstream\n" % len(strom) + strom + b"endstream"
        else:
            aus += objekt.encode("latin-1")
        aus += b"\nendobj\n"
    xref = len(aus)
    aus += b"xref\n0 %d\n0000000000 65535 f \n" % (len(objekte) + 1)
    for stelle in stellen:
        aus += b"%010d 00000 n \n" % stelle
    aus += b"trailer\n<< /Size %d /Root 1 0 R /Info %d 0 R >>\nstartxref\n%d\n%%%%EOF\n" % (len(objekte) + 1, len(objekte), xref)
    return bytes(aus)


def main(argv):
    args = argv[1:]
    daten = pdf()
    if args == ["--pruefen"]:
        with open(ZIEL, "rb") as handle:
            gleich = handle.read() == daten
        print("testpage.pdf entspricht dem Erzeuger" if gleich else "testpage.pdf weicht vom Erzeuger ab – neu erzeugen")
        return 0 if gleich else 1
    if len(args) > 1 or (args and args[0].startswith("--")):
        print(__doc__, file=sys.stderr)
        return 2
    ziel = args[0] if args else ZIEL
    with open(ziel, "wb") as handle:
        handle.write(daten)
    print("%s: %d Bytes" % (ziel, len(daten)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
