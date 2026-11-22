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
# Plan 0.8 Nr. 75: Die Pipette des Dienstes heisst alpe:eyedropper, klar verschieden vom Modal alpe:color-picker.
check(sorted(r for _d, r in raeume) == ["alpe:eyedropper", "alpe:screenshot"], "Dienst: Layer alpe:eyedropper und alpe:screenshot: " + str(raeume))
check('layerNamespace: "alpe:color-picker"' in read(SHELL, "Modals", "ColorPickerModal.qml"), "Oberfläche: das Farbwähler-Modal behält alpe:color-picker")
for wurzel, _verzeichnisse, dateien in os.walk(SHELL):
    for datei in dateien:
        if datei.endswith(".qml"):
            # Jede Zeichenkette auf einer Zeile, die einen Namensraum setzt; «:anhang» hängt an einen Namensraum an.
            for zeile in re.findall(r'^\s*(?:WlrLayershell\.namespace|layerNamespace)\s*:(.*)$', read(wurzel, datei), re.M):
                raeume += [(datei, m) for m in re.findall(r'"([^"]+)"', zeile) if not m.startswith(":")]
ausserhalb = sorted(set((d, r) for d, r in raeume if not r.startswith("alpe:")))
check(len(raeume) > 60 and ausserhalb == [], "alle Layer-Namensräume folgen dem Schema alpe:<name> (%d geprüft): %s" % (len(raeume), ausserhalb))
check(all(any(regel.search(r) for regel in regeln) for _d, r in raeume), "die Regeln der Hyprland-Vorlage erfassen jeden Layer-Namensraum")

# Der Schriftzug in der Hilfe des Dienstes ist Blockgrafik – die Namensprüfung sieht ihn nicht.
schriftzug = read(core, "cmd", "alpe-dienst", "ui.go")
check("██████╗ ███╗   ███╗███████╗" not in schriftzug and " █████╗ ██╗     ██████╗ ███████╗" in schriftzug,
      "Hilfe des Dienstes zeigt den Schriftzug ALPE, nicht den des Ursprungs")

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

# Halt nach D7: Die Registrierung für die Einstellungssuche hängt als Eigenschaft an Zeile und Karte, nicht als
# Kind in `data` – sonst meldet Qt beim Abbau einer halb erzeugten Zeile sporadisch «Cannot find member data».
kinder, eigenschaften = [], 0
for ordner, _dirs, dateien in os.walk(SHELL):
    for d in dateien:
        if d.endswith(".qml"):
            for zeile in read(ordner, d).splitlines():
                if re.match(r"\s*SettingsSearchRegistration\s*\{", zeile):
                    kinder.append(d)
                eigenschaften += bool(re.match(r"\s*readonly property SettingsSearchRegistration \w+: SettingsSearchRegistration\s*\{", zeile))
check(kinder == [] and eigenschaften >= 3, "SettingsSearchRegistration nur als Eigenschaft (%d), nie als Kind: %s" % (eigenschaften, kinder))

# Halt nach D7: Jede Widget-Kennung im Bar-Layout des ausgelieferten Designs ist ein registriertes Widget der Leiste
# (WidgetModel.js) oder ein Plugin aus plugins/. Eine umbenannte Kennung, die das Design nicht mitmacht, fiele sonst
# nur als leere Stelle in der Leiste auf.
import json
registriert = set(re.findall(r'^\s*"([^"]+)"\s*:', re.search(r"componentNames\s*=\s*\{(.*?)\n\}", read(SHELL, "Modules", "Bar", "WidgetModel.js"), re.S).group(1), re.M))
plugin_ids = {json.loads(read(REPO, "plugins", name, "plugin.json"))["id"] for name in os.listdir(os.path.join(REPO, "plugins"))
              if os.path.isfile(os.path.join(REPO, "plugins", name, "plugin.json"))}
# Persönliches gehört nicht in ein ausgeliefertes Design (CLAUDE.md): keine Pfade in ein Home-Verzeichnis, keine
# Adressen, Geräte- oder Bildschirmkennungen, kein Wetterort, keine Rechner- oder Netznamen.
PERSOENLICH = [
    ("Pfad in ein Home-Verzeichnis", r"/home/|/Users/|file://~"),
    ("IP-Adresse", r"(?<![\d.])(?:\d{1,3}\.){3}\d{1,3}(?![\d.])"),
    ("MAC-Adresse", r"\b[0-9A-Fa-f]{2}(?:[:-][0-9A-Fa-f]{2}){5}\b"),
    ("PCI-/USB-Kennung", r"(?<![0-9A-Fa-f:])[0-9a-f]{4}:[0-9a-f]{4}(?![0-9A-Fa-f:])"),
    ("Bildschirmname", r"\b(?:eDP|DP|HDMI-A|HDMI|DVI-[DI]|VGA|LVDS|DSI)-\d+\b"),
    ("Koordinaten", r"\b\d{1,2}\.\d{3,}\s*,\s*\d{1,3}\.\d{3,}\b"),
    ("E-Mail-Adresse", r"[\w.+-]+@[\w-]+\.[\w.-]+"),
]
PERSOENLICHE_SCHLUESSEL = re.compile(r'"(weatherLocation|weatherCoordinates|pciId|hostname|hostName|serial|serialNumber|ssid|bssid|macAddress|'
                                     r'username|userName|latitude|longitude|lockPamPath|matugenTargetMonitor)"\s*:\s*(?="[^"]|\[\s*[^\]\s]|-?[1-9])')
TEXT_ENDUNGEN = (".json", ".jsonc", ".conf", ".txt", ".md", ".lua", ".toml", ".ini", ".css", ".qml")
funde, gelesen = [], 0
for ordner, _dirs, dateien in os.walk(os.path.join(REPO, "design")):
    for d in dateien:
        if not d.endswith(TEXT_ENDUNGEN):
            continue
        gelesen += 1
        rel = os.path.relpath(os.path.join(ordner, d), REPO)
        for nummer, zeile in enumerate(read(ordner, d).splitlines(), 1):
            for art, muster in PERSOENLICH:
                if re.search(muster, zeile):
                    funde.append("%s:%d %s" % (rel, nummer, art))
            if PERSOENLICHE_SCHLUESSEL.search(zeile):
                funde.append("%s:%d Schlüssel %s" % (rel, nummer, PERSOENLICHE_SCHLUESSEL.search(zeile).group(1)))
check(gelesen >= 6 and funde == [], "ausgelieferte Designs ohne persönliche Werte (%d Dateien): %s" % (gelesen, funde[:8]))
for art, probe in (("Pfad in ein Home-Verzeichnis", "/home/x/bild.png"), ("IP-Adresse", "192.168.1.20"), ("MAC-Adresse", "aa:bb:cc:dd:ee:ff"),
                   ("PCI-/USB-Kennung", '"1234:abcd"'), ("Bildschirmname", '["DP-2"]'), ("Koordinaten", "47.123, 8.456"), ("E-Mail-Adresse", "a@b.ch")):
    check(any(a == art and re.search(m, probe) for a, m in PERSOENLICH), "Muster erkennt: " + art)
check(PERSOENLICHE_SCHLUESSEL.search('"weatherLocation": "Ort"') and not PERSOENLICHE_SCHLUESSEL.search('"weatherLocation": ""')
      and not re.search(PERSOENLICH[3][1], "aa:bb:cc:dd:ee:ff") and not re.search(PERSOENLICH[1][1], '"1.2.3"'),
      "Schlüssel mit Wert erkannt, leere Werte, Versionsnummern und Teile einer MAC-Adresse nicht")

# ---------------------------------------------------------------- persönliche Werte im ganzen Repo
# Nicht nur design/: Alle versionierten Textdateien werden auf Pfade in ein Home-Verzeichnis, Benutzer- und
# Rechnernamen, IP- und MAC-Adressen und Gerätekennungen durchsucht. Benutzer- und Rechnername stehen nicht hier
# im Test (sie wären selbst ein persönlicher Wert), sondern kommen vom Rechner, auf dem er läuft; Allerweltsnamen
# und Namen unter vier Zeichen werden dabei nicht gesucht. Die strengeren Muster oben (Bildschirmnamen,
# Koordinaten, E-Mail-Adressen, Schlüssel mit Wert) gelten weiterhin nur für design/.
# Suche und Muster stehen in tools/werte-pruefen.py (läuft auch gegen andere Ordner), die Ausnahmen in
# tools/werte-ausnahmen.txt: je Datei, Art und erwartetem Wert, mit Frist und Grund.
import importlib.util

_spec = importlib.util.spec_from_file_location("werte_pruefen", os.path.join(REPO, "tools", "werte-pruefen.py"))
wp = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(wp)
ausnahmen = wp.lade_ausnahmen()
repo_gelesen, repo_treffer = wp.durchsuche(REPO, ausnahmen)
benutzer, rechner = wp.eigener_name(__import__("pwd").getpwuid(os.getuid()).pw_name), wp.eigener_name(__import__("socket").gethostname())
check(repo_gelesen > 1500 and repo_treffer == [],
      "ganzes Repo ohne persönliche Werte (%d Dateien; Benutzername %s, Rechnername %s): %s"
      % (repo_gelesen, "gesucht" if benutzer else "nicht gesucht", "gesucht" if rechner else "nicht gesucht", [wp.zeile(f) for f in repo_treffer[:12]]))
ueberholt = ["%s %s %s" % (a["glob"], a["art"], a["text"]) for a in ausnahmen if a["treffer"] == 0
             and not (a["art"] in ("Benutzername", "Rechnername") and not (benutzer if a["art"] == "Benutzername" else rechner))]
check(ueberholt == [], "jede Ausnahme trifft mindestens einen Fund (sonst ist sie überholt): %s" % ueberholt)
check(len(ausnahmen) <= 30 and all(a["frist"] and len(a["grund"]) >= 15 for a in ausnahmen),
      "Ausnahmeliste kurz (%d Einträge), jede mit Frist und Begründung" % len(ausnahmen))
for art, probe in (("Pfad in ein Home-Verzeichnis", "source = /home/erika/bild.png"), ("IP-Adresse", "host 192.168.1.20"), ("MAC-Adresse", "aa:bb:cc:dd:ee:ff"),
                   ("Gerätekennung", '"1234:abcd"'), ("Benutzername", "Ordner von Erika."), ("Rechnername", "ssh werkbank")):
    check(any(f[2] == art for f in wp.funde("x/probe.txt", probe, "erika", "werkbank")), "Repo-Muster erkennt: " + art)
check(wp.funde("x/probe.txt", "/home/nutzer/a ~/b $HOME/c 127.0.0.1 0.0.0.0 v1.2.3 12:34:56 erikas instances/home/projekt", "erika", "werkbank") == [],
      "Repo-Muster: Platzhalter, Loopback, Versionen, Uhrzeiten und Wortteile sind kein Fund")
probe_ausnahme = [{"glob": "a/*_test.go", "art": "IP-Adresse", "muster": re.compile(r"10\.0\.0\.2"), "treffer": 0}]
check(wp.funde("a/b_test.go", "10.0.0.2", ausnahmen=probe_ausnahme) == [] and probe_ausnahme[0]["treffer"] == 1
      and [f[3] for f in wp.funde("a/b_test.go", "10.0.0.2 10.0.0.3 /home/erika/x", ausnahmen=probe_ausnahme)] == ["/home/erika", "10.0.0.3"]
      and len(wp.funde("a/c.go", "10.0.0.2", ausnahmen=probe_ausnahme)) == 1,
      "Ausnahme gilt nur für Datei, Art und genau den erwarteten Wert – ein neuer Fund in derselben Datei schlägt an")
check(wp.eigener_name("pc") == "" and wp.eigener_name("runner") == "" and wp.eigener_name("werkbank.lan") == "werkbank",
      "kurze Namen und Allerweltsnamen werden nicht gesucht")

# Kein fremdes Plugin im Bar-Layout: sathiAi stand bis zum Halt nach D7 im ausgelieferten Design.
FREMD_IM_DESIGN = set()
for variante in sorted(os.listdir(os.path.join(REPO, "design"))):
    datei = os.path.join(REPO, "design", variante, "settings.json")
    if not os.path.isfile(datei):
        continue
    kennungen = [(w["id"] if isinstance(w, dict) else w) for leiste in json.loads(read(datei)).get("barConfigs", [])
                 for seite in ("leftWidgets", "centerWidgets", "rightWidgets") for w in leiste.get(seite, [])]
    unbekannt = sorted(set(kennungen) - registriert - plugin_ids)
    check(len(registriert) >= 25 and len(kennungen) >= 5 and set(unbekannt) <= FREMD_IM_DESIGN,
          "design/%s: alle %d Widget-Kennungen der Leiste sind registriert oder Repo-Plugins (fremd: %s)" % (variante, len(kennungen), unbekannt))

# ---------------------------------------------------------------- Dienst: Systembus nur über internal/systembus
# godbus hält in dbus.SystemBus() eine paketweite Sperre über den Verbindungsaufbau ohne Zeitgrenze; ein Bus,
# der nicht antwortet, hielt so den Start des ganzen Dienstes auf (docs/plan/dienst-systembus.md). Die eine
# Verbindung baut internal/systembus mit Zeitgrenze auf; sonst ruft im Dienst nichts diese Funktionen auf.
eigene_verbindungen = []
for ordner, _, dateien in os.walk(os.path.join(REPO, "core")):
    if os.path.join("core", "internal", "systembus") in ordner or os.path.join("core", "internal", "mocks") in ordner:
        continue
    for datei in dateien:
        if not datei.endswith(".go"):
            continue
        pfad = os.path.join(ordner, datei)
        for nummer, zeile in enumerate(open(pfad, encoding="utf-8"), 1):
            code = zeile.split("//")[0]
            if re.search(r"\bdbus\.(SystemBus|ConnectSystemBus|SystemBusPrivate|SystemBusPrivateHandler)\(", code):
                eigene_verbindungen.append("%s:%d" % (os.path.relpath(pfad, REPO), nummer))
check(not eigene_verbindungen, "kein eigener Verbindungsaufbau zum Systembus ausserhalb von core/internal/systembus\n%s" % "\n".join(eigene_verbindungen))
systembus_go = read(REPO, "core", "internal", "systembus", "systembus.go")
check("dbus.ConnectSystemBus(dbus.WithContext(" in systembus_go and "time.AfterFunc(" in systembus_go and "context.WithTimeout" not in systembus_go.split("func Verbinden")[1].split("\nfunc ")[0].replace("Ein context.WithTimeout", ""),
      "systembus.Verbinden: Zeitgrenze über Timer und abbrechbaren Context, nicht über WithTimeout (das schlösse die Verbindung auch nach Erfolg)")

print("\nalle Prüfungen bestanden" if failures == 0 else f"\n{failures} FEHLER")
sys.exit(1 if failures else 0)
