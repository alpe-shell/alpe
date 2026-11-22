#!/usr/bin/env python3
"""Alpe: restliche Werte mit altem Namen (Plan 0.8 Nr. 38, D7.7a).

Kürzel-Kategorie eigener Aktionen heisst «Alpe» und wird einsortiert; Kategorien aus Kürzeln von 1.0
werden übergangsweise weiter erkannt. Prozessliste und doctor kennen den alten Namen nicht mehr.
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(REPO, "shell")
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


def read(*parts):
    with open(os.path.join(*parts), encoding="utf-8") as handle:
        return handle.read()


content = read(SHELL, "Modals", "KeybindsContent.qml")
service = read(SHELL, "Services", "KeybindsService.qml")
kategorie = re.search(r'isShellAction\(bind\.action\) \? "(\w+)"', service)
check(kategorie is not None and kategorie.group(1) == "Alpe", "eigene Kürzel stehen in der Kategorie «Alpe»")
prio = dict(re.findall(r'^\s+"([a-z -]+)": (\d+),?', content, re.M))
check(prio.get("alpe") == "7", "die Kategorie «Alpe» hat ihren Platz in der Reihenfolge (vorher 99)")
check(prio.get("dms") == prio.get("alpe"), "Kategorie aus Kürzeln von 1.0 wird übergangsweise gleich einsortiert")
check('lower === "alpe" || lower.includes("dms")' in content, "Symbol: alpe, übergangsweise auch dms")

actions = read(SHELL, "Modules", "ProcessList", "ProcessActions.qml")
check(not re.search(r"dms", actions, re.I), "Prozessliste ohne alten Namen")
check('return "shell";' in actions and 'case "shell":' in actions and "Proc.shellRestartCommand" in actions,
      "eigener Prozess: Neustart über die Art «shell»")

doctor = os.path.join(REPO, "core", "cmd", "alpe-dienst", "commands_doctor.go")
if os.path.exists(doctor):
    text = read(doctor)
    check("getShellVersion()" in text and "getDMSShellVersion" not in text, "doctor: getShellVersion")

# ---------------------------------------------------------------- D7.7a2: sichtbare Kennungen
# Layer-Namensräume heissen alpe:…; der Dienst schneidet denselben Vorsatz ab (Bildschirmfoto-Ziele).
alt, neu = [], 0
for ordner, _dirs, dateien in os.walk(SHELL):
    if any(teil in ordner for teil in ("/translations", "/tests")):
        continue
    for datei in dateien:
        if not datei.endswith((".qml", ".js")):
            continue
        text = read(ordner, datei)
        neu += len(re.findall(r'["^]alpe:[a-z]', text))
        if re.search(r'["^\'`]dms:[a-z.$"]', text):
            alt.append(os.path.relpath(os.path.join(ordner, datei), SHELL))
check(not alt and neu > 80, "Layer-Namensräume: %d mal alpe:…, keiner mehr mit dms: %s" % (neu, alt[:5]))
types = os.path.join(REPO, "core", "internal", "screenshot", "types.go")
if os.path.exists(types):
    check('strings.TrimPrefix(s.Name, "alpe:")' in read(types), "Dienst: Bildschirmfoto-Ziele ohne Vorsatz alpe:")
hypr = read(SHELL, "Services", "HyprlandService.qml")
check('"^alpe:.*$"' in hypr and '"^alpe:island$"' in hypr, "Hyprland-Regeln der Shell treffen alpe:…")
check('`app-alpe-${' in read(SHELL, "Common", "LaunchUnit.js"), "gestartete Programme laufen als app-alpe-…")
insel = read(SHELL, "Modules", "Island", "Island.qml")
check('"DOT" : "ISLAND"' in insel and "DANK" not in insel, "IPC-Antworten der Insel: ISLAND_…/DOT_…")

# ---------------------------------------------------------------- D7.7b4: «jedes Mal fragen»
# Die Standardprogramme bieten den Eintrag alpe-open an; die Desktop-Datei dazu liegt im Repo
# (Installation: E3, mimeapps.list: F1 – Plan 0.8 Nr. 50).
desktop = os.path.join(REPO, "packaging", "alpe-open.desktop")
if os.path.isdir(os.path.join(REPO, "packaging")):
    eintrag = dict(zeile.split("=", 1) for zeile in read(desktop).splitlines() if "=" in zeile)
    tab = read(SHELL, "Modules", "Settings", "DefaultAppsTab.qml")
    kennung = re.search(r'shellChooserId: "([\w-]+)"', tab)
    check(kennung is not None and kennung.group(1) + ".desktop" == os.path.basename(desktop),
          "Desktop-Datei heisst wie der Auswahl-Eintrag der Standardprogramme")
    check(eintrag.get("Exec") == "alpe-dienst open %u" and eintrag.get("NoDisplay") == "true",
          "ruft alpe-dienst open, erscheint nicht im Starter")
    check("x-scheme-handler/http;" in eintrag.get("MimeType", "") and "dms" not in read(desktop).lower(),
          "meldet sich für Links an, kein Schema des Ursprungs")
    import shutil
    import subprocess
    if shutil.which("desktop-file-validate"):
        check(subprocess.run(["desktop-file-validate", desktop]).returncode == 0, "desktop-file-validate")

# D7.7h: Der Dienst trägt die alten Namen weder in Verzeichnissen noch in go.mod (ausser den
# fremden Modulen dux-go und dux-gop), und die Attrappen sind unverändert aus mockery erzeugt.
core = os.path.join(REPO, "core")
alt = re.compile(r"dms|dank|dux", re.IGNORECASE)
ordner = []
for wurzel, verzeichnisse, _dateien in os.walk(core):
    verzeichnisse[:] = [v for v in verzeichnisse if v not in (".git", "bin")]
    ordner += [os.path.relpath(os.path.join(wurzel, v), core) for v in verzeichnisse if alt.search(v)]
check(ordner == [], "kein Paketverzeichnis mit altem Namen" + (": " + ", ".join(ordner) if ordner else ""))
gomod = [z.strip() for z in read(core, "go.mod").splitlines() if alt.search(z)]
erlaubt = [z for z in gomod if re.match(r"github\.com/duxlabs-dev/dux-(go|gop) v", z)]
check(len(gomod) == 2 and gomod == erlaubt, "go.mod nennt alte Namen nur für die Module dux-go und dux-gop")
check(read(core, "go.mod").splitlines()[0] == "module github.com/alpe-shell/alpe/core", "Modulpfad des Dienstes")
attrappen = []
for wurzel, _verzeichnisse, dateien in os.walk(os.path.join(core, "internal", "mocks")):
    attrappen += [os.path.join(wurzel, d) for d in dateien if d.endswith(".go")]
check(len(attrappen) > 10 and all("// template: testify (core/.mockery/testify.templ)" in read(a) for a in attrappen),
      "alle Attrappen stammen aus der Vorlage core/.mockery/testify.templ")
check(not any(re.search(r"_Expecter\) (Unm|M)arshalJSON\(", read(a)) for a in attrappen),
      "keine Attrappe hat einen Expecter-Helfer für MarshalJSON (go vet, Plan 0.8 Nr. 62)")
check("file://.mockery/testify.templ" in read(core, ".mockery.yml"), ".mockery.yml benutzt die eigene Vorlage")
check("MOCKERY_VERSION = v3.9.1" in read(core, "Makefile") and "mockery v3.9.1" in read(REPO, "CLAUDE.md"),
      "mockery-Version steht im Makefile und in CLAUDE.md (Plan 0.8 Nr. 66)")
check(not os.path.exists(os.path.join(core, "internal", "netfetch", "release.go")) and not os.path.isdir(os.path.join(core, "internal", "mocks", "version"))
      and re.findall(r"^func (\w+)", read(core, "internal", "version", "version.go"), re.M) == ["CompareVersions"],
      "Aktualisierungsprüfung des Ursprungs ist weg, internal/version hat nur CompareVersions (Plan 0.8 Nr. 65)")
agenten = []
for wurzel, _verzeichnisse, dateien in os.walk(core):
    if os.sep + "mocks" in wurzel:
        continue
    for datei in dateien:
        if datei.endswith(".go") and not datei.endswith("_test.go"):
            agenten += [(os.path.relpath(os.path.join(wurzel, datei), core), m) for m in re.findall(r'"(Alpe[ /][^"]*)"', read(wurzel, datei))
                        if "github.com/alpe-shell" in m or re.match(r"Alpe/\d", m)]
check(agenten == [], "kein fest eingetragener User-Agent im Dienst, alle über brand.UserAgent() (Plan 0.8 Nr. 67): " + str(agenten))

# Layer-Namensräume (Plan 0.8 Nr. 68): ein Schema «alpe:<name>» in Oberfläche und Dienst; die Regel der
# eingebetteten Hyprland-Vorlage erfasst jeden davon.
vorlage = read(core, "internal", "config", "embedded", "hyprland.lua")
regeln = [re.compile(m) for m in re.findall(r'hl\.layer_rule\(\{ match = \{ namespace = "([^"]+)" \}, no_anim = true \}\)', vorlage)]
check(len(regeln) == 2, "Hyprland-Vorlage: zwei Regeln ohne Animation (quickshell, alpe:…)")
raeume = []
for wurzel, _verzeichnisse, dateien in os.walk(core):
    for datei in dateien:
        if datei.endswith(".go") and not datei.endswith("_test.go") and os.sep + "mocks" not in wurzel:
            raeume += [(datei, m) for m in re.findall(r'GetLayerSurface\(\s*[^,]+,\s*[^,]+,\s*[^,]+,\s*"([^"]*)"', read(wurzel, datei))]
check(len(raeume) >= 2, "Dienst: Layer-Flächen gefunden (%d)" % len(raeume))
for wurzel, _verzeichnisse, dateien in os.walk(SHELL):
    for datei in dateien:
        if datei.endswith(".qml"):
            # Jede Zeichenkette auf einer Zeile, die einen Namensraum setzt; «:anhang» hängt an einen Namensraum an.
            for zeile in re.findall(r'^\s*(?:WlrLayershell\.namespace|layerNamespace)\s*:(.*)$', read(wurzel, datei), re.M):
                raeume += [(datei, m) for m in re.findall(r'"([^"]+)"', zeile) if not m.startswith(":")]
ausserhalb = sorted(set((d, r) for d, r in raeume if not r.startswith("alpe:")))
check(len(raeume) > 60 and ausserhalb == [], "alle Layer-Namensräume folgen dem Schema alpe:<name> (%d geprüft): %s" % (len(raeume), ausserhalb))
check(all(any(regel.search(r) for regel in regeln) for _d, r in raeume), "die Regeln der Hyprland-Vorlage erfassen jeden Layer-Namensraum")

# D7.8: Hüllen und Weiterleitungen für fremde Plugins sind weg, die Namensprüfung ist streng.
reste = []
for ordner, _dirs, dateien in os.walk(SHELL):
    rel = os.path.relpath(ordner, SHELL)
    if rel.split(os.sep)[0] == "DCommon" or os.sep.join(rel.split(os.sep)[:2]) in ("Modules/DankBar", "Modules/DankDash"):
        reste.append(rel)
    reste += [os.path.join(rel, d) for d in dateien if re.match(r"Dank[A-Z]\w*\.qml$", d) or d == "Deprecation.qml"]
check(reste == [], "keine Dank*-Hüllen, kein DCommon, keine Weiterleitungen, kein Deprecation.qml (D7.8): " + str(reste[:5]))
check(not any("Deprecation." in read(ordner, d) for ordner, _dirs, dateien in os.walk(SHELL) for d in dateien if d.endswith((".qml", ".js"))),
      "nichts in der Oberfläche ruft Deprecation auf")
check("bash tools/namen-pruefen.sh --streng" in read(REPO, "tools", "test.sh"), "tools/test.sh ruft die Namensprüfung streng auf (D7.8)")

print("\nalle Prüfungen bestanden" if failures == 0 else f"\n{failures} FEHLER")
sys.exit(1 if failures else 0)
