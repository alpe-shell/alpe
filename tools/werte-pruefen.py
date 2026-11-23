#!/usr/bin/env python3
"""Alpe – persönliche Werte im Repository suchen (CLAUDE.md: «Persönliches gehört nie ins Repo»).

    python3 tools/werte-pruefen.py            das Repository, in dem das Skript liegt
    python3 tools/werte-pruefen.py ORDNER     ein anderer Ordner (etwa ein Temp-Worktree oder ein Plugin-Repo)
    Optionen: --ohne-ausnahmen   Ausnahmeliste nicht anwenden (alle Funde zeigen)
              --ausnahmen        Ausnahmeliste mit Frist, Grund und Zahl der Treffer zeigen

Durchsucht alle versionierten Textdateien (git ls-files; ohne Git alle Dateien ausser .git) nach
Pfaden in ein Home-Verzeichnis, Benutzer- und Rechnernamen, IP- und MAC-Adressen und Gerätekennungen.
Benutzer- und Rechnername stehen nicht hier (sie wären selbst ein persönlicher Wert), sondern kommen
vom Rechner, auf dem das Skript läuft; Allerweltsnamen und Namen unter vier Zeichen werden nicht gesucht.

Ausnahmen stehen in tools/werte-ausnahmen.txt, gleich aufgebaut wie tools/namen-ausnahmen.txt:
PFAD-GLOB, ART, WERT-MUSTER, FRIST, GRUND. Eine Ausnahme gilt nur für genau den erwarteten Wert;
ein anderer Fund in derselben Datei schlägt an. Ergebnis: 0 = keine Funde, 1 = Funde, 2 = Aufruffehler.
"""
import fnmatch
import os
import pwd
import re
import socket
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUSNAHMEN_DATEI = os.path.join(REPO, "tools", "werte-ausnahmen.txt")

PLATZHALTER = {"u", "x", "me", "user", "nutzer", "test", "name", "benutzer"}          # /home/<Platzhalter>/… ist kein Fund
ALLERWELTSNAMEN = {"root", "user", "nutzer", "runner", "build", "builder", "mockbuild", "nobody", "claude", "localhost",
                   "archlinux", "fedora", "cachyos"}
HOME = "Pfad in ein Home-Verzeichnis"
HOME_PFAD = re.compile(r"(?<![\w.-])/(?:home|Users)/([^/\s\"'<>$*{}\\)|`,;:]+)")
MUSTER = [
    ("IP-Adresse", re.compile(r"(?<![\d.\w])(?!127\.|0\.0\.0\.0|255\.)(?:\d{1,3}\.){3}\d{1,3}(?![\d.\w])")),
    ("MAC-Adresse", re.compile(r"(?<![0-9A-Fa-f:.-])[0-9A-Fa-f]{2}(?:[:-][0-9A-Fa-f]{2}){5}(?![0-9A-Fa-f:-])")),
    ("Gerätekennung", re.compile(r"(?<![0-9A-Fa-f:\w])[0-9a-f]{4}:[0-9a-f]{4}(?![0-9A-Fa-f:\w])")),
]
RECHNERABHAENGIG = ("Benutzername", "Rechnername")   # der gesuchte Wert kommt vom Rechner, auf dem die Prüfung läuft
ARTEN = [HOME, *RECHNERABHAENGIG] + [art for art, _muster in MUSTER]
ENDUNGEN = (".json", ".jsonc", ".conf", ".txt", ".md", ".lua", ".toml", ".ini", ".css", ".qml", ".py", ".sh", ".js", ".mjs",
            ".go", ".tsv", ".yml", ".yaml", ".xml", ".desktop", ".service", ".spec", ".fish", ".templ", ".mod", ".kvconfig",
            ".theme", ".html", ".patch", ".diff")


def lade_ausnahmen(datei=AUSNAHMEN_DATEI):
    """Zeilen PFAD-GLOB<Tab>ART<Tab>WERT-MUSTER<Tab>FRIST<Tab>GRUND; alle fünf Felder sind Pflicht."""
    eintraege = []
    with open(datei, encoding="utf-8") as handle:
        for nummer, zeile in enumerate(handle.read().splitlines(), 1):
            if not zeile.strip() or zeile.startswith("#"):
                continue
            teile = [teil.strip() for teil in zeile.split("\t")]
            if len(teile) != 5 or not all(teile) or teile[1] not in ARTEN:
                raise ValueError("%s:%d: erwartet PFAD-GLOB, ART (%s), WERT-MUSTER, FRIST, GRUND" % (datei, nummer, ", ".join(ARTEN)))
            eintraege.append({"glob": teile[0], "art": teile[1], "muster": re.compile(teile[2]), "text": teile[2],
                              "frist": teile[3], "grund": teile[4], "zeile": nummer, "treffer": 0})
    return eintraege


def eigener_name(name):
    name = (name or "").split(".")[0]
    return name if len(name) >= 4 and name.lower() not in ALLERWELTSNAMEN | PLATZHALTER else ""


def funde(pfad, text, benutzer="", rechner="", ausnahmen=()):
    """Persönliche Werte in einem Text: Liste (pfad, zeile, art, wert). Ausgenommen ist nur der erwartete Wert."""
    namen = [(art, re.compile(r"(?i)(?<![A-Za-z0-9])%s(?![A-Za-z0-9])" % re.escape(n)))
             for art, n in (("Benutzername", benutzer), ("Rechnername", rechner)) if n]
    ergebnis = []
    for nummer, zeile in enumerate(text.splitlines(), 1):
        werte = [(HOME, m.group(0)) for m in HOME_PFAD.finditer(zeile) if m.group(1) not in PLATZHALTER]
        werte += [(art, m.group(0)) for art, muster in MUSTER + namen for m in muster.finditer(zeile)]
        for art, wert in werte:
            erlaubt = [a for a in ausnahmen if a["art"] == art and fnmatch.fnmatch(pfad, a["glob"]) and a["muster"].fullmatch(wert)]
            if erlaubt:
                erlaubt[0]["treffer"] += 1
            else:
                ergebnis.append((pfad, nummer, art, wert))
    return ergebnis


def dateien(wurzel):
    liste = subprocess.run(["git", "-C", wurzel, "ls-files", "-z"], capture_output=True)
    if liste.returncode == 0 and liste.stdout:
        return sorted(p for p in liste.stdout.decode("utf-8", "replace").split("\0") if p)
    return sorted(os.path.relpath(os.path.join(ordner, d), wurzel) for ordner, _dirs, ds in os.walk(wurzel)
                  for d in ds if ".git" not in ordner.split(os.sep))


def durchsuche(wurzel, ausnahmen=(), benutzer=None, rechner=None):
    """Alle versionierten Textdateien unter wurzel: (Zahl gelesener Dateien, Funde)."""
    benutzer = eigener_name(pwd.getpwuid(os.getuid()).pw_name) if benutzer is None else benutzer
    rechner = eigener_name(socket.gethostname()) if rechner is None else rechner
    gelesen, ergebnis = 0, []
    for pfad in dateien(wurzel):
        voll = os.path.join(wurzel, pfad)
        # Bewusste Regel: Die Ausnahmeliste wird als ganze Datei nicht durchsucht. Sie muss die ausgenommenen Werte
        # nennen (Spalte WERT-MUSTER) und wäre sonst selbst ein Fund. Ausgenommen ist nur die Liste, die dieser Lauf
        # anwendet (tools/werte-ausnahmen.txt neben diesem Skript, verglichen über den absoluten Pfad) – keine
        # gleichnamige Datei in einem anderen durchsuchten Ordner. Folge: Kommentare und Begründungen in der Liste
        # prüft niemand; persönliche Werte gehören dort so wenig hin wie anderswo (docs/technik.md, «Tests»).
        if os.path.abspath(voll) == AUSNAHMEN_DATEI:
            continue
        if not (pfad.endswith(ENDUNGEN) or "." not in os.path.basename(pfad)) or not os.path.isfile(voll) or os.path.islink(voll):
            continue
        try:
            with open(voll, encoding="utf-8") as handle:
                text = handle.read()
        except (UnicodeDecodeError, OSError):
            continue
        gelesen += 1
        ergebnis += funde(pfad, text, benutzer, rechner, ausnahmen)
    return gelesen, ergebnis


def ueberholte(ausnahmen, ergebnis, benutzer, rechner):
    """Ausnahmen ohne Treffer – aber nur solche, über die dieser Lauf etwas aussagen kann.

    Eine Ausnahme gilt nur als überholt, wenn ihre Art in diesem Lauf gesucht wurde. Benutzer- und Rechnername
    kommen vom Rechner: In der CI (Allerweltsname) wird die Art gar nicht gesucht; auf einem Rechner mit einem
    anderen Namen wird zwar gesucht, aber nach einem Wert, der im Repository nirgends steht – auch dieser Lauf
    weiss nichts über die Ausnahme. Für diese beiden Arten zählt darum zusätzlich, dass der gesuchte Name im
    Repository überhaupt vorkommt (als Fund oder als ausgenommener Treffer).
    """
    gesucht = dict(zip(RECHNERABHAENGIG, (benutzer, rechner)))
    liste = []
    for a in ausnahmen:
        if a["treffer"]:
            continue
        if a["art"] in gesucht:
            vorkommen = sum(b["treffer"] for b in ausnahmen if b["art"] == a["art"]) + sum(1 for f in ergebnis if f[2] == a["art"])
            if not gesucht[a["art"]] or not vorkommen:
                continue
        liste.append(a)
    return liste


def zeile(fund):
    return "%s:%d %s «%s»" % fund


def main(argv):
    optionen = [a for a in argv[1:] if a.startswith("--")]
    ordner = [a for a in argv[1:] if not a.startswith("--")]
    if len(ordner) > 1 or set(optionen) - {"--ohne-ausnahmen", "--ausnahmen"}:
        print(__doc__, file=sys.stderr)
        return 2
    wurzel = os.path.abspath(ordner[0]) if ordner else REPO
    ausnahmen = [] if "--ohne-ausnahmen" in optionen else lade_ausnahmen()
    gelesen, ergebnis = durchsuche(wurzel, ausnahmen)
    for fund in ergebnis:
        print(zeile(fund))
    if "--ausnahmen" in optionen:
        for a in ausnahmen:
            print("Ausnahme %s | %s | %s | Frist: %s | %s | %d Treffer" % (a["glob"], a["art"], a["text"], a["frist"], a["grund"], a["treffer"]))
    print("%d Dateien gelesen, %d Funde in %d Dateien" % (gelesen, len(ergebnis), len({f[0] for f in ergebnis})))
    return 1 if ergebnis else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
