#!/usr/bin/env python3
"""Alpe – Bild der Test-Instanz von KWin für die Ladeprüfung («Weg A», offene-faelle.md, «Ladeprüfung»).

    python3 kwinbild.py ZIEL.png --scope UNIT [--fremd ADRESSE]…

Nur für die Ladeprüfung, nur unter KWin: `alpe-dienst screenshot full` geht im virtuellen kwin_wayland nicht
(kein wlr-screencopy). Das Bild kommt darum über org.kde.KWin.ScreenShot2 am Session-Bus der Test-Instanz.
Befristete Abweichung von Plan 0.8 Nr. 71, bis über ein KWin-Backend im Dienst («Weg B», nach G1) entschieden ist.

Damit nie der echte Schreibtisch aufgenommen wird, bricht das Skript ohne Aufnahme ab, wenn
  1. DBUS_SESSION_BUS_ADDRESS fehlt oder keine eindeutige Adresse ist (genau ein Eintrag mit path= oder abstract=),
  2. die Adresse gleich einer fremden ist (--fremd: die Adresse der Sitzung des Maintainers; immer auch der
     Sitzungsbus unter /run/user/<uid>/bus),
  3. der Prozess, dem org.kde.KWin an diesem Bus gehört, nicht im Scope UNIT der Ladeprüfung läuft.
Ergebnis: 0 = Bild geschrieben, 3 = aus einem der Gründe oben abgebrochen, 1 = Aufnahme gescheitert, 2 = Aufruffehler.
"""
import json
import os
import struct
import subprocess
import sys
import zlib

# QImage::Format → Reihenfolge der Bytes je Bildpunkt im Speicher (Little Endian). Andere Formate liefert KWin
# für CaptureWorkspace nicht; kommt doch eines, wird abgebrochen statt geraten.
FORMATE = {4: "BGRX", 5: "BGRA", 6: "BGRA", 16: "RGBX", 17: "RGBA", 18: "RGBA"}


def adress_schluessel(adresse):
    """Der Ort einer D-Bus-Adresse ohne guid: ("path", "/tmp/dbus-…") oder ("abstract", "…"); sonst None."""
    teile = [t for t in (adresse or "").split(";") if t]
    if len(teile) != 1 or not teile[0].startswith("unix:"):
        return None
    felder = dict(f.split("=", 1) for f in teile[0][len("unix:"):].split(",") if "=" in f)
    for art in ("path", "abstract"):
        if felder.get(art):
            return (art, os.path.normpath(felder[art]) if art == "path" else felder[art])
    return None


def adresse_pruefen(test, fremde, uid=None):
    """None, wenn die Adresse der Test-Instanz gehören kann; sonst der Grund für den Abbruch."""
    eigen = adress_schluessel(test)
    if eigen is None:
        return "Busadresse der Test-Instanz fehlt oder ist nicht eindeutig: «%s»" % (test or "")
    uid = os.getuid() if uid is None else uid
    for fremd in list(fremde) + ["unix:path=/run/user/%d/bus" % uid]:
        if fremd and adress_schluessel(fremd) == eigen:
            return "Busadresse der Test-Instanz ist die der echten Sitzung: «%s»" % test
    return None


def im_scope(pid, unit, proc="/proc"):
    """Läuft der Prozess im systemd-Scope der Ladeprüfung? (cgroup-Pfad endet auf den Namen der Einheit)"""
    try:
        with open(os.path.join(proc, str(int(pid)), "cgroup"), encoding="utf-8") as handle:
            pfade = [zeile.rstrip("\n").split(":", 2)[-1] for zeile in handle]
    except (OSError, ValueError):
        return False
    return bool(unit) and any(unit in pfad.split("/") for pfad in pfade)


def png(breite, hoehe, zeile, form, daten):
    """Rohdaten von KWin als PNG (RGB, 8 Bit). Der Alphakanal wird verworfen: Der Schreibtisch ist deckend."""
    ordnung = FORMATE[form]
    r, g, b = ordnung.index("R"), ordnung.index("G"), ordnung.index("B")
    roh = bytearray()
    for y in range(hoehe):
        punkte = daten[y * zeile:y * zeile + breite * 4]
        roh.append(0)
        rgb = bytearray(breite * 3)
        rgb[0::3], rgb[1::3], rgb[2::3] = punkte[r::4], punkte[g::4], punkte[b::4]
        roh += rgb

    def stueck(art, inhalt):
        return struct.pack(">I", len(inhalt)) + art + inhalt + struct.pack(">I", zlib.crc32(art + inhalt) & 0xFFFFFFFF)

    return (b"\x89PNG\r\n\x1a\n" + stueck(b"IHDR", struct.pack(">IIBBBBB", breite, hoehe, 8, 2, 0, 0, 0))
            + stueck(b"IDAT", zlib.compress(bytes(roh), 6)) + stueck(b"IEND", b""))


def busctl(adresse, *args, **kw):
    return subprocess.run(["busctl", "--address=" + adresse, "--json=short", "call", *args], capture_output=True, text=True, timeout=20, **kw)


def kwin_pid(adresse):
    antwort = busctl(adresse, "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "GetConnectionUnixProcessID", "s", "org.kde.KWin")
    if antwort.returncode != 0:
        return None
    try:
        return int(json.loads(antwort.stdout)["data"][0])
    except (ValueError, KeyError, IndexError, TypeError):
        return None


def aufnehmen(adresse):
    """CaptureWorkspace über eine Pipe: (breite, hoehe, zeile, format, daten) oder eine Fehlermeldung."""
    lesen, schreiben = os.pipe()
    try:
        antwort = busctl(adresse, "org.kde.KWin", "/org/kde/KWin/ScreenShot2", "org.kde.KWin.ScreenShot2", "CaptureWorkspace",
                         "a{sv}h", "0", str(schreiben), pass_fds=(schreiben,))
    finally:
        os.close(schreiben)
    if antwort.returncode != 0:
        os.close(lesen)
        return "CaptureWorkspace gescheitert: " + (antwort.stderr or antwort.stdout).strip()
    try:
        werte = {name: wert["data"] for name, wert in json.loads(antwort.stdout)["data"][0].items()}
        breite, hoehe, zeile, form = int(werte["width"]), int(werte["height"]), int(werte["stride"]), int(werte["format"])
    except (ValueError, KeyError, IndexError, TypeError):
        os.close(lesen)
        return "Antwort von CaptureWorkspace nicht verstanden: " + antwort.stdout.strip()[:300]
    if werte.get("type") != "raw" or form not in FORMATE or not 0 < breite <= 16384 or not 0 < hoehe <= 16384 or zeile < breite * 4:
        os.close(lesen)
        return "unerwartetes Bildformat: %s" % {k: werte.get(k) for k in ("type", "format", "width", "height", "stride")}
    daten, soll = bytearray(), zeile * hoehe
    with os.fdopen(lesen, "rb") as quelle:
        while len(daten) < soll:
            teil = quelle.read(soll - len(daten))
            if not teil:
                break
            daten += teil
    if len(daten) < soll:
        return "Bilddaten unvollständig: %d von %d Bytes" % (len(daten), soll)
    return breite, hoehe, zeile, form, bytes(daten)


def main(argv):
    args = argv[1:]
    fremde, scope, ziel = [], "", ""
    while args:
        arg = args.pop(0)
        if arg == "--fremd" and args:
            fremde.append(args.pop(0))
        elif arg == "--scope" and args:
            scope = args.pop(0)
        elif not arg.startswith("--") and not ziel:
            ziel = arg
        else:
            print(__doc__, file=sys.stderr)
            return 2
    if not ziel or not scope:
        print(__doc__, file=sys.stderr)
        return 2
    adresse = os.environ.get("DBUS_SESSION_BUS_ADDRESS", "")
    grund = adresse_pruefen(adresse, fremde)
    if grund is None:
        pid = kwin_pid(adresse)
        if pid is None:
            grund = "an diesem Bus gibt es kein org.kde.KWin"
        elif not im_scope(pid, scope):
            grund = "org.kde.KWin an diesem Bus (PID %d) läuft nicht im Scope %s" % (pid, scope)
    if grund is not None:
        print("ABBRUCH, kein Bild: " + grund)
        return 3
    ergebnis = aufnehmen(adresse)
    if isinstance(ergebnis, str):
        print("FEHLER: " + ergebnis)
        return 1
    with open(ziel, "wb") as handle:
        handle.write(png(*ergebnis))
    print("KWin ScreenShot2 (Test-Instanz, Scope %s): %s, %d × %d" % (scope, ziel, ergebnis[0], ergebnis[1]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
