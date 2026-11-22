#!/usr/bin/env python3
"""Alpe: skriptbasierte Umbenennung für D7 (Plan 2.3). Eine Tabelle je Bereich, erst Probelauf.

    python3 entwicklung/umbenennen/umbenennen.py TABELLE.tsv              Probelauf: Treffer je Datei, Kollisionen
    python3 entwicklung/umbenennen/umbenennen.py TABELLE.tsv --liste      dazu jede Trefferzeile
    python3 entwicklung/umbenennen/umbenennen.py TABELLE.tsv --schreiben  ausführen (nur ohne Kollisionen)

Tabelle (Tabulator-getrennt, # = Kommentar):
    wort    ALT    NEU    [PFADE]   ganzer Bezeichner (Wortgrenzen, Gross/klein genau)
    text    ALT    NEU    [PFADE]   wörtliche Zeichenkette
    regex   MUSTER ERSATZ [PFADE]   regulärer Ausdruck (Python), Ersatz mit \\1 …
    datei   ALT    NEU              Datei oder Ordner per «git mv» (Pfad relativ zum Repo)
    link    ALT    ZIEL             Symlink ALT → ZIEL anlegen (Übergang, D7.2a)
    ohne    PFADE                   diese Pfade nie anfassen (Glob, mehrere durch Komma)
    erlaubt NAME                    bekannte, geprüfte Kollision für NAME zulassen
PFADE: Globs relativ zum Repo, durch Komma getrennt; leer = shell, core, plugins, tools, tests,
entwicklung, design, lockscreen.

Kollisionsprüfung (Plan 2.3.0 Nr. 4) für jeden neuen Namen aus «wort» und «datei»: existiert er
schon als Bezeichner bzw. Datei im Repo, als Qt-Typ (/usr/lib/qt6/qml/**/*.qmltypes) oder als
Quickshell-Typ? Dann Abbruch, ausser er steht unter «erlaubt».
"""
import fnmatch
import glob
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
STANDARD = ["shell", "core", "plugins", "tools", "tests", "entwicklung", "design", "lockscreen"]
QML_DIR = os.environ.get("ALPE_QML_DIR", "/usr/lib/qt6/qml")


def git(*args, check=True):
    return subprocess.run(["git", "-C", REPO] + list(args), capture_output=True, text=True, check=check).stdout


def lese_tabelle(pfad):
    regeln, ohne, erlaubt = [], [], set()
    with open(pfad, encoding="utf-8") as handle:
        for nummer, zeile in enumerate(handle, 1):
            zeile = zeile.rstrip("\n")
            if not zeile.strip() or zeile.lstrip().startswith("#"):
                continue
            teile = zeile.split("\t")
            art = teile[0]
            if art == "ohne":
                ohne += [g.strip() for g in teile[1].split(",") if g.strip()]
            elif art == "erlaubt":
                erlaubt.add(teile[1])
            elif art in ("wort", "text", "regex", "datei", "link") and len(teile) >= 3:
                pfade = [g.strip() for g in teile[3].split(",")] if len(teile) > 3 and teile[3].strip() else []
                regeln.append({"art": art, "alt": teile[1], "neu": teile[2], "pfade": pfade, "zeile": nummer})
            else:
                sys.exit("%s:%d: Zeile nicht verstanden: %r" % (pfad, nummer, zeile))
    return regeln, ohne, erlaubt


def dateien(pfade, ohne):
    namen = git("ls-files", "-z", "--", *(pfade or STANDARD)).split("\0")
    out = []
    for name in namen:
        if not name or any(fnmatch.fnmatch(name, g) for g in ohne):
            continue
        voll = os.path.join(REPO, name)
        if os.path.islink(voll) or not os.path.isfile(voll):
            continue
        with open(voll, "rb") as handle:
            if b"\0" in handle.read(8192):
                continue  # binär
        out.append(name)
    return out


def muster(regel):
    if regel["art"] == "wort":
        return re.compile(r"(?<![A-Za-z0-9_])" + re.escape(regel["alt"]) + r"(?![A-Za-z0-9_])")
    if regel["art"] == "text":
        return re.compile(re.escape(regel["alt"]))
    return re.compile(regel["alt"])


def fremde_typen():
    typen = set()
    for datei in glob.glob(os.path.join(QML_DIR, "**", "*.qmltypes"), recursive=True):
        with open(datei, encoding="utf-8", errors="replace") as handle:
            for treffer in re.finditer(r'exports:\s*\[([^\]]*)\]', handle.read()):
                typen.update(re.findall(r'"[^"/]*/([A-Za-z_][A-Za-z0-9_]*) ', treffer.group(1)))
    return typen


def kollisionen(regeln, ohne, erlaubt):
    funde = []
    alt_namen = {r["alt"] for r in regeln if r["art"] == "wort"}
    qt = fremde_typen()
    if not qt:
        print("Hinweis: keine Qt-/Quickshell-Typen gefunden unter %s – Prüfung dagegen entfällt" % QML_DIR)
    alle = dateien([], ohne)
    for regel in regeln:
        neu = regel["neu"]
        if regel["art"] == "wort":
            if neu in erlaubt or neu in alt_namen:
                continue
            pat = re.compile(r"(?<![A-Za-z0-9_])" + re.escape(neu) + r"(?![A-Za-z0-9_])")
            orte = []
            for name in dateien(regel["pfade"], ohne) if regel["pfade"] else alle:
                with open(os.path.join(REPO, name), encoding="utf-8", errors="replace") as handle:
                    if pat.search(handle.read()):
                        orte.append(name)
            if orte:
                funde.append("%s → %s: gibt es schon in %s%s" % (regel["alt"], neu, ", ".join(orte[:3]), " …" if len(orte) > 3 else ""))
            if neu in qt:
                funde.append("%s → %s: Qt-/Quickshell-Typ" % (regel["alt"], neu))
        elif regel["art"] == "datei":
            if os.path.lexists(os.path.join(REPO, neu)):
                funde.append("%s → %s: Ziel existiert" % (regel["alt"], neu))
            typ = os.path.splitext(os.path.basename(neu))[0]
            if typ in qt and typ not in erlaubt:
                funde.append("%s → %s: Qt-/Quickshell-Typ %s" % (regel["alt"], neu, typ))
    return funde


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    tabelle = sys.argv[1]
    schreiben = "--schreiben" in sys.argv
    liste = "--liste" in sys.argv
    regeln, ohne, erlaubt = lese_tabelle(tabelle)

    funde = kollisionen(regeln, ohne, erlaubt)
    for fund in funde:
        print("KOLLISION " + fund)

    textregeln = [r for r in regeln if r["art"] in ("wort", "text", "regex")]
    geaendert = {}
    gesamt = 0
    for regel in textregeln:
        pat = muster(regel)
        anzahl = 0
        for name in dateien(regel["pfade"], ohne):
            voll = os.path.join(REPO, name)
            with open(voll, encoding="utf-8", errors="surrogateescape") as handle:
                inhalt = geaendert.get(name, handle.read())
            neu_inhalt, n = pat.subn(regel["neu"], inhalt)
            if n:
                anzahl += n
                if liste:
                    for nummer, zeile in enumerate(inhalt.splitlines(), 1):
                        if pat.search(zeile):
                            print("   %s:%d: %s" % (name, nummer, zeile.strip()[:140]))
                geaendert[name] = neu_inhalt
        gesamt += anzahl
        print("%-6s %-40s → %-34s %5d Treffer" % (regel["art"], regel["alt"][:40], regel["neu"][:34], anzahl))
    for regel in regeln:
        if regel["art"] in ("datei", "link"):
            if regel["art"] == "datei":
                zustand = "ok" if os.path.lexists(os.path.join(REPO, regel["alt"])) else "QUELLE FEHLT"
            else:
                zustand = "wird angelegt" if not os.path.lexists(os.path.join(REPO, regel["alt"])) else "GIBT ES SCHON"
            print("%-6s %-40s → %-34s %s" % (regel["art"], regel["alt"], regel["neu"], zustand))
    print("%d Ersetzungen in %d Dateien" % (gesamt, len(geaendert)))

    if not schreiben:
        print("Probelauf – nichts geschrieben" + (" (Kollisionen!)" if funde else ""))
        return 1 if funde else 0
    if funde:
        print("Abbruch: Kollisionen")
        return 1
    for regel in regeln:
        if regel["art"] == "datei":
            os.makedirs(os.path.dirname(os.path.join(REPO, regel["neu"])) or REPO, exist_ok=True)
            git("mv", regel["alt"], regel["neu"])
    for name, inhalt in geaendert.items():
        # Nach einem «datei»-Schritt liegt die Datei unter dem neuen Pfad.
        ziel = name
        for regel in regeln:
            if regel["art"] == "datei" and (name == regel["alt"] or name.startswith(regel["alt"].rstrip("/") + "/")):
                ziel = regel["neu"] + name[len(regel["alt"]):]
        with open(os.path.join(REPO, ziel), "w", encoding="utf-8", errors="surrogateescape") as handle:
            handle.write(inhalt)
    for regel in regeln:
        if regel["art"] == "link":
            ziel = os.path.join(REPO, regel["alt"])
            os.makedirs(os.path.dirname(ziel), exist_ok=True)
            os.symlink(regel["neu"], ziel)
            git("add", regel["alt"])
    print("geschrieben")
    return 0


if __name__ == "__main__":
    sys.exit(main())
