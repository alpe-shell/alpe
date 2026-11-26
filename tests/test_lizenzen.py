#!/usr/bin/env python3
"""Alpe: Lizenzangaben in NOTICE, LICENSES/ und Makefile passen zum Code (Entscheide des Maintainers vom 25.11.2026).

    python3 tests/test_lizenzen.py

go-udev (GPL-3.0-only) im Dienst: NOTICE nennt das Modul mit der Fassung aus core/go.mod und jede Datei, die es
einbindet; der Lizenztext liegt unter LICENSES/ und make install legt ihn nach /usr/share/licenses/alpe-shell.
golang/freetype (Alpe wählt die FTL): NOTICE nennt Fassung, Wahl, Nennung des FreeType-Teams und jede Datei, die
go-qrcode/writer/standard einbindet; make dist und make install legen licenses/ftl.txt ab (Inhalt: test_makefile.py).
yeqown/reedsolomon (MIT, am Ursprung belegt): NOTICE nennt Fassung, Lizenz mit Fundstelle und jede Datei, die
go-qrcode/v2 einbindet. Klänge (1.4): NOTICE beschreibt genau die ausgelieferten Dateien unter shell/assets/sounds/.
Zeichen Dritter und Code-Teile (1.5): NOTICE nennt genau die fremden SVG unter shell/assets/ (Flatpak CC BY 3.0,
Snapcraft CC BY-SA 3.0, Hyprland ARR nach Markenrichtlinie) und fzf.js, Hct.js, MaterialShapeData.js mit der Lizenz,
die im Kopf der Datei steht.
Ohne Bau, ohne Netz.
"""
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


def lies(*teile):
    with open(os.path.join(REPO, *teile), encoding="utf-8") as handle:
        return handle.read()


notice = lies("NOTICE")
makefile = lies("Makefile")
gomod = lies("core", "go.mod")


def block(modul):
    """Der Eintrag eines Go-Moduls in NOTICE: Kopfzeile mit dem Modulpfad, dann eingerückte Zeilen."""
    treffer = re.search(r"^%s\n((?:  .*\n)+)" % re.escape(modul), notice, re.M)
    return treffer.group(1) if treffer else ""


def go_dateien_mit_import(paket):
    """Go-Dateien unter core/ (ohne Tests und vendor/), die das Paket einbinden."""
    funde = []
    for wurzel, ordner, dateien in os.walk(os.path.join(REPO, "core")):
        ordner[:] = [o for o in ordner if o != "vendor"]
        for datei in dateien:
            if datei.endswith(".go") and not datei.endswith("_test.go"):
                pfad = os.path.join(wurzel, datei)
                with open(pfad, encoding="utf-8") as handle:
                    if '"%s' % paket in handle.read():
                        funde.append(os.path.relpath(pfad, REPO))
    return sorted(funde)


# --- go-udev (Entscheid 1.1) ---
modul = "github.com/pilebones/go-udev"
fassung = re.search(r"^\s*%s (v\S+)" % re.escape(modul), gomod, re.M)
check(fassung is not None, "core/go.mod führt %s" % modul)
eintrag = block(modul)
check(eintrag != "", "NOTICE hat einen eigenen Eintrag für %s" % modul)
if fassung and eintrag:
    check(re.search(r"Fassung:\s+%s\b" % re.escape(fassung.group(1)), eintrag) is not None,
          "NOTICE nennt die Fassung aus core/go.mod (%s)" % fassung.group(1))
    check("GPL-3.0-only" in eintrag and "LICENSES/GPL-3.0-only.txt" in eintrag
          and "/usr/share/licenses/alpe-shell/GPL-3.0-only.txt" in eintrag,
          "NOTICE: Lizenz GPL-3.0-only, Lizenztext im Repository und im Paket")
    check("MIT" in eintrag and "alpe-dienst als Ganzes" in eintrag,
          "NOTICE: Quelltext MIT, das Programm alpe-dienst als Ganzes unter den Bedingungen der GPL-3.0")
    benutzt = go_dateien_mit_import(modul)
    genannt = sorted(re.findall(r"core/\S+\.go", eintrag))
    check(benutzt and benutzt == genannt, "NOTICE nennt jede Datei, die %s einbindet (Code: %s; NOTICE: %s)" % (modul, benutzt, genannt))

gpl = os.path.join(REPO, "LICENSES", "GPL-3.0-only.txt")
check(os.path.isfile(gpl) and lies("LICENSES", "GPL-3.0-only.txt").lstrip().startswith("GNU GENERAL PUBLIC LICENSE\n                       Version 3, 29 June 2007"),
      "LICENSES/GPL-3.0-only.txt ist der Text der GPL, Version 3")
check(re.search(r"^\tinstall -Dm644 LICENSES/GPL-3\.0-only\.txt \$\(DESTDIR\)\$\(PREFIX\)/share/licenses/alpe-shell/GPL-3\.0-only\.txt$",
                makefile, re.M) is not None,
      "make install legt den Text der GPL-3.0 nach /usr/share/licenses/alpe-shell")
# --- golang/freetype: Alpe wählt die FTL (Entscheid 1.2) ---
modul = "github.com/golang/freetype"
fassung = re.search(r"^\s*%s (v\S+)" % re.escape(modul), gomod, re.M)
eintrag = block(modul)
check(fassung is not None and eintrag != "", "NOTICE hat einen eigenen Eintrag für %s (in core/go.mod)" % modul)
if fassung and eintrag:
    check(re.search(r"Fassung:\s+%s\b" % re.escape(fassung.group(1)), eintrag) is not None,
          "NOTICE nennt die Fassung aus core/go.mod (%s)" % fassung.group(1))
    check("Alpe wählt die FreeType" in eintrag and "core/vendor/github.com/golang/freetype/licenses/ftl.txt" in eintrag
          and "/usr/share/licenses/alpe-shell/FTL.txt" in eintrag and "FreeType-Teams" in eintrag,
          "NOTICE: Wahl der FTL, Orte des Lizenztexts, Nennung des FreeType-Teams")
    # freetype kommt über fogleman/gg aus go-qrcode/writer/standard ins Programm; jede einbindende Datei steht im Eintrag.
    benutzt = go_dateien_mit_import("github.com/yeqown/go-qrcode/writer/standard")
    genannt = sorted(re.findall(r"core/\S+\.go", eintrag))
    check(benutzt and benutzt == genannt,
          "NOTICE nennt jede Datei, die go-qrcode/writer/standard (und damit freetype) einbindet (Code: %s; NOTICE: %s)" % (benutzt, genannt))
check(re.search(r"^FTL_VENDOR := core/vendor/\$\(FREETYPE\)/licenses/ftl\.txt$", makefile, re.M) is not None
      and re.search(r"^FREETYPE := github\.com/golang/freetype$", makefile, re.M) is not None
      and "install -Dm644 \"$$dir/licenses/ftl.txt\" $(BUILD_ABS)/dist/alpe-$(DIST_VERSION)/$(FTL_VENDOR)" in makefile
      and "install -Dm644 \"$$src\" $(DESTDIR)$(PREFIX)/share/licenses/alpe-shell/FTL.txt" in makefile,
      "make dist legt licenses/ftl.txt in den vendor-Baum, make install nach /usr/share/licenses/alpe-shell/FTL.txt")

# --- yeqown/reedsolomon: MIT, am Ursprung belegt (1.3); die Fassung im Modul hat keine Lizenzdatei ---
modul = "github.com/yeqown/reedsolomon"
fassung = re.search(r"^\s*%s (v\S+)" % re.escape(modul), gomod, re.M)
eintrag = block(modul)
check(fassung is not None and eintrag != "", "NOTICE hat einen eigenen Eintrag für %s (in core/go.mod)" % modul)
if fassung and eintrag:
    check(re.search(r"Fassung:\s+%s\b" % re.escape(fassung.group(1)), eintrag) is not None,
          "NOTICE nennt die Fassung aus core/go.mod (%s)" % fassung.group(1))
    check(re.search(r"^  Lizenz:\s+MIT\b", eintrag, re.M) is not None and "c5f4bc9af094852b52e593a5f964647c43028c51" in eintrag
          and "https://github.com/yeqown/reedsolomon/blob/master/LICENSE" in eintrag,
          "NOTICE: Lizenz MIT mit Fundstelle (Commit und Adresse der LICENSE am Ursprung)")
    benutzt = go_dateien_mit_import("github.com/yeqown/go-qrcode/v2")
    genannt = sorted(re.findall(r"core/\S+\.go", eintrag))
    check(benutzt and benutzt == genannt,
          "NOTICE nennt jede Datei, die go-qrcode/v2 (und damit reedsolomon) einbindet (Code: %s; NOTICE: %s)" % (benutzt, genannt))

# --- Klänge (1.4): NOTICE nennt genau die Klangdateien, die im Repository liegen (und damit ausgeliefert werden) ---
klaenge = re.search(r"^Klänge \(shell/assets/sounds/\)\n((?:  .*\n)+)", notice, re.M)
check(klaenge is not None, "NOTICE hat den Abschnitt «Klänge (shell/assets/sounds/)»")
if klaenge:
    genannt = set()
    ordner = None
    for zeile in klaenge.group(1).splitlines():
        kopf = re.match(r"^  (\w+)/\s", zeile)
        if kopf:
            ordner = kopf.group(1)
        for name, endungen in re.findall(r"([\w-]+)\.((?:oga|ogg|wav)(?:/\.(?:oga|ogg|wav))*)\b", zeile):
            for endung in endungen.split("/."):
                genannt.add("%s/%s.%s" % (ordner, name, endung))
    klang_ordner = os.path.join(REPO, "shell", "assets", "sounds")
    vorhanden = {os.path.relpath(os.path.join(d, f), klang_ordner) for d, _, fs in os.walk(klang_ordner)
                 for f in fs if f.endswith((".oga", ".ogg", ".wav"))}
    check(vorhanden and genannt == vorhanden,
          "NOTICE nennt genau die Klangdateien im Repository (nur in NOTICE: %s; nicht in NOTICE: %s)"
          % (sorted(genannt - vorhanden), sorted(vorhanden - genannt)))
    check("desktop-login" not in klaenge.group(1), "desktop-login steht nicht mehr unter den Klängen (entfernt, 1.4)")
    # Entscheid vom 26.11.2026: die freedesktop-Klänge kommen aus dem installierten Klangthema, keine Kopien, kein CREDITS
    check(not os.path.exists(os.path.join(klang_ordner, "freedesktop")) and not genannt & {"freedesktop/" + n for n in (
          "audio-volume-change.oga", "message.oga", "message-new-instant.oga")}
          and "sound-theme-freedesktop" in klaenge.group(1),
          "Klänge: keine Kopien aus dem freedesktop-Klangthema (auch kein CREDITS), NOTICE verweist auf sound-theme-freedesktop")

# --- Zeichen Dritter und Code-Teile (1.5) ---
zeichen = re.search(r"^Zeichen Dritter \(shell/assets/\), nur zur Bezeichnung\n((?:  .*\n)+)", notice, re.M)
check(zeichen is not None, "NOTICE hat den Abschnitt «Zeichen Dritter (shell/assets/), nur zur Bezeichnung»")
if zeichen:
    assets = os.path.join(REPO, "shell", "assets")
    fremd = {os.path.relpath(os.path.join(d, f), assets) for d, _, fs in os.walk(assets) for f in fs
             if f.endswith(".svg") and not f.startswith("alpe-zeichen")}
    genannt = set(re.findall(r"^  ([\w/.-]+\.svg)\s", zeichen.group(1), re.M))
    check(fremd and fremd == genannt, "NOTICE nennt genau die Zeichen Dritter unter shell/assets/ (nur in NOTICE: %s; fehlt: %s)"
          % (sorted(genannt - fremd), sorted(fremd - genannt)))
    check("nur, um das jeweilige Programm oder" in zeichen.group(1), "NOTICE: Zeichen nur zur Bezeichnung")
    # Simple Icons ist CC0, die Zeichen darin nicht (Nachbesserung zu 1.5): Flatpak CC BY 3.0, Snapcraft CC BY-SA 3.0,
    # Hyprland ARR nach der Markenrichtlinie des Inhabers.
    eintraege = re.split(r"\n(?=  [\w/.-]+\.svg\s)", zeichen.group(1))
    def eintrag_zu(name):
        return next((e for e in eintraege if e.lstrip().startswith(name)), "")
    def lizenz_des_zeichens(name):
        """Text nach «Lizenz des Zeichens» bis zum Satzende «.» vor einer Klammer oder dem Eintragsende."""
        teil = eintrag_zu(name).split("Lizenz des Zeichens", 1)
        return teil[1].split("(Simple Icons selbst", 1)[0] if len(teil) == 2 else ""
    check("(CC BY 3.0)" in lizenz_des_zeichens("package-sources/flatpak.svg") and "CC0" not in lizenz_des_zeichens("package-sources/flatpak.svg"),
          "NOTICE: flatpak.svg unter CC BY 3.0 (nicht CC0)")
    check("(CC BY-SA 3.0)" in lizenz_des_zeichens("package-sources/snap.svg") and "CC0" not in lizenz_des_zeichens("package-sources/snap.svg"),
          "NOTICE: snap.svg unter CC BY-SA 3.0 (nicht CC0)")
    check("ARR" in eintrag_zu("hyprland.svg") and "https://hypr.land/trademark-usage/" in eintrag_zu("hyprland.svg"),
          "NOTICE: hyprland.svg mit Hinweis auf ARR und die Markenrichtlinie")
check(not os.path.exists(os.path.join(REPO, "shell", "assets", "discord.svg"))
      and not os.path.exists(os.path.join(REPO, "shell", "assets", "reddit.svg")), "discord.svg und reddit.svg sind entfernt (1.5)")
for datei, lizenz, im_kopf in (("shell/Alpe/Common/fzf.js", "BSD-3-Clause", "BSD 3-Clause License"),
                               ("shell/Alpe/Common/Hct.js", "Apache License 2.0", "Apache-2.0"),
                               ("shell/Alpe/Widgets/MaterialShapeData.js", "Apache License 2.0", "Apache-2.0")):
    zeile = re.search(r"^  %s\s*\n?\s+(.*)$" % re.escape(datei), notice, re.M)
    kopf = "".join(open(os.path.join(REPO, datei), encoding="utf-8").readlines()[:12]) if os.path.isfile(os.path.join(REPO, datei)) else ""
    check(im_kopf in kopf and zeile is not None and zeile.group(1).startswith(lizenz),
          "NOTICE nennt %s mit %s, wie im Kopf der Datei («%s»)" % (datei, lizenz, im_kopf))

# Im Quellarchiv (git archive HEAD) ist nur, was versioniert ist.
if subprocess.run(["git", "-C", REPO, "rev-parse", "--git-dir"], capture_output=True).returncode == 0:
    versioniert = subprocess.run(["git", "-C", REPO, "ls-files", "--error-unmatch", "LICENSES/GPL-3.0-only.txt"],
                                 capture_output=True).returncode == 0
    check(versioniert, "LICENSES/GPL-3.0-only.txt ist versioniert (kommt damit ins Quellarchiv)")

print("\n%s" % ("alle Prüfungen bestanden" if not failures else "%d FEHLER" % failures))
sys.exit(1 if failures else 0)
