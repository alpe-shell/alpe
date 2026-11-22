# Phase A – Plan zur Umsetzung (Alpe 1.1 «Zugerberg»)

Stand: 21. November 2026, Branch `phase-a`. **Freigegeben am 21.11.2026** mit den Entscheiden in 0.4. Grundlage: `docs/plan/phase-a.md`, `CLAUDE.md`,
`KONTEXT.md`, Erkundung von `~/alpe` (Commit c988364) und `~/dux-shell` (Branch `alpe` =
v2.1.2 + 2 Schichten). Umgesetzt bis D6 (Halt), siehe «Stand»; Entscheide nach D3 in 0.7, nach D6 in 0.8 (D7 wieder
aufgenommen, Abschnitt 2.3); offene Einzelfälle in
`docs/plan/offene-faelle.md`.

---

## Stand (22.11.2026, nach D6; D7 freigegeben)

### Erledigt

| Commit | Inhalt | Prüfung |
|---|---|---|
| A0, A1, B1–B3 | Plan, CI, Einverleiben (vor dieser Sitzung) | – |
| `19fc86b` | Plan 6.8 (`alpe-dienst` startet keine systemd-Units), `CLAUDE.md`: kein `pkill` | – |
| `ee40068` | Ladeprüfung der ganzen Shell (`entwicklung/ladepruefung/`) | – |
| `012a459` | **C1** Ursprungs-Infrastruktur entfernt (Installer `duxinstall`, Installationsassistent in `internal/tui`, Pre-Commit, Beispiel-Plugins, Entwicklerskripte), `go.mod` bereinigt | test.sh grün, Ladeprüfung KWin/Hyprland ohne Neues |
| `5caf121` | Grundlinien der Ladeprüfung: KWin 30, Hyprland 39 Einträge (je 3 Läufe) | – |
| `eb97e37` | **C2** niri entfernt (Shell und Dienst) | test.sh grün |
| `e175ce4` | **C3** mango, sway, scroll, miracle, labwc, umbriel, river entfernt; nur noch Hyprland und KWin; `doctor` kennt KWin | test.sh grün |
| `2c92ce4` | Ladeprüfung vergleicht ohne Zeilennummern | Endstand: test.sh grün; Ladeprüfung KWin 30/30, Hyprland 39/39, nichts neu |
| `f6b06c7` | Plan 0.5 (Entscheide nach C3), C5, offene Fälle | – |
| `9c008a6` | **C4** Greeter | je Commit: test.sh grün, go/Node-Tests mit denselben bekannten Fehlschlägen, Ladeprüfung KWin + Hyprland ohne Neues |
| `f1b6842` | **C4** Aktualisierungs-/Versionshinweise, Willkommen | dito |
| `7043bb7` | **C4** Version allein aus `Brand.qml` (Makefile per ldflags, `tests/test_version.py`) | dito |
| `95744af` | **C4** Plugin- und Theme-Browser samt Registern | dito (KWin im 2. Lauf, siehe offene Fälle) |
| `4580f06` | **C4** Tailscale (go.mod −17 Module) | dito; Grundlinien KWin 29, Hyprland 38 |
| `10c0e1b` | **C4** `internal/distros`, `update`/`migrate`/`setup`/`switch`; neu `internal/osinfo` | dito |
| `bb67ffe` | **C4** Übersetzungen nur de (+ en als Quelltexte) | dito |
| `f631f56` | **C4** VS-Code-Farbschema (vsix) | dito |
| `c88c3f3` | **C4** Community-Links und Assets des Ursprungs | dito |
| `ae2a925` | **C5** Fensterregel-Editor ohne niri/Mango | dito, zusätzlich qmllint |
| `8cb116f` | **C5** Tastenkürzel-Editor ohne niri/Mango | dito |
| `e6c7d59` | **C5** Arbeitsflächen-Umschalter: Zieh-Pfad, Übersichts-Pille | dito |
| `5a3e441` | Plan 0.6 (Mac-Test): `alpe.service` auch unter Hyprland, Umzug 7.4 | – |
| `4c43cdb` | Einstellungssuche: abgebaute Karten (SettingsSearchRegistration) | test.sh grün, Node-Test neu, Ladeprüfung KWin + Hyprland ohne Neues |
| `ca4fadc` … `918a7d7` | **C6** leere Übersichts-Funktionen, `fullscreenAutoHide`, `_bindsStale`, `duxinstall`-Logger, tote Entwicklerwerkzeuge (5 Commits) | je Commit test.sh grün, Go/Node wie bekannt, Ladeprüfung (siehe Halt-Meldung) |
| `51f6c6a` | **D1** Go-Modulpfad `github.com/alpe-shell/alpe/core` | dito |
| `d6d0408` | **D1** `alpe-dienst`, Socket `alpe-<pid>.sock`, `ALPE_*`, Kürzel-Aktionen `alpe-dienst ipc …` (alte gelten beim Einlesen weiter) | dito, Node-Test neu |
| `0b6325a` | **D1** Plan 6.8: kein Start/Stopp/Neustart von Units; Neustart über `alpe restart` | dito, Go-Tests neu |
| `1c1602c` | **D2** versteckte DMS-1.x-Ordnermigration entfernt | dito |
| `9cdc770` | **D2** `~/.config|state|cache/alpe` (Dienst, Oberfläche, Werkzeuge, die Shell-Dateien schreiben) | dito; Grundlinien: nur Pfade umbenannt |
| `1094e90` | **D2** System-Plugins `/usr/share/alpe/plugins` | dito |
| `95ce578` | **D2** `hypr/alpe/`, `require("alpe.…")`; versteckte ICC-Migration entfernt | dito |
| `bca3795` | **D3** App-ID `io.github.alpe_shell.Alpe`, D-Bus `….NMAgent`, `….KwinBridge` | dito |
| `d3343e9` | **D3** unbenutzte DMS-Logos im Dienst entfernt | dito |
| `0da9b8a` | **D4** KWin-Brücke `alpe-bridge.js`, Pfad `/AlpeBridge`, Kürzel `alpe-*`, `alpe-cmd-*` | ab hier je Commit test.sh grün (0.7 Nr. 6) |
| `dd31ebf` | **D5** Einstellungen: `dankLauncherV2*` → `launcher*`, `runMatugenTemplates`, `shellWindowsFloatingSeeded`, Werte `"dms"` → `"standard"`; Migration v43, `settings.v<alt>.json`; `design.py` benennt mit um | Test `tests/test_einstellungen.mjs` (1.0-Datei) |
| `f2a34f7` | **D6** Übersetzungen: 393 Begriffe entfernter Seiten weg (DCommon jetzt ausdrücklich ausgelassen) | dito |
| `204aaa7` | **D6** Übersetzungen: ss statt ß (79 Einträge) | dito |
| `bbb57be` | **D6** `Brand.apply` weg, «Alpe» direkt in Quelltexten und `de.json` | dito |
| `0515150` | **Fehler aus D2:** eigene Hyprland-Fensterregeln galten als fremd (`dms/windowrules`) | Test `tests/test_pfade.py` |
| `eab4f12` | **D6** Suchindex: Skript nachgerüstet, Index neu erzeugt | dito |
| `15b2072` | Reste aus D1: `ALPE_LOG_*` im Dienst, `alpe-dienst auth sync`, Rückfall `brand.Binary` | Go wie bekannt |
| `b7c73d8` | **D6** Dienst: Hilfe, Meldungen, Mitteilungs-Absender, Terminaltitel | Go wie bekannt (Tests angepasst) |
| `7be57f9` | **D6** Alpe-Zeichen unter eigenem Dateinamen, `dank.svg` weg | dito |
| `b53ecd3` | **D6** Über-Seite: Beschreibung, Herkunft, Lizenz | dito |
| `713749c`, `17a5f36` | **D6** übrige Oberflächentexte (Kürzelkategorie, `dms setup`-Hinweise, Plugin-Basisversion, Kopfzeilen, Testmitteilungen) | dito; Node-Tests config-include, plugin-reload, settings-search-cards neu in test.sh |
| `459a476` | Ladeprüfung auf dem Endstand: KWin 29/29, Hyprland 38/38, nur die 2 geänderten Meldungen; Grundlinien nachgeführt | – |
| | **D7** (Entscheide 0.8 Nr. 20–24, Commits nach 2.3.5; Hash siehe `git log`) | |
| D7.G | `tools/neue-dateien-pruefen.sh` in test.sh: rot bei neuen Dateien > 1 MB oder ELF gegenüber `origin/phase-a` (auch vorgemerkt und unversioniert-nicht-ignoriert) | Test `tests/test_neue_dateien.py` |
| D7.N | Alle Node-Tests der Oberfläche in test.sh (`tools/node-tests.py`), feste Liste der 10 bekannten Fehlschläge `tests/data/node-bekannte-fehlschlaege.txt`; neuer Fehlschlag = rot | Test `tests/test_node_tests.py` |
| D7.0 | Werkzeug `entwicklung/umbenennen/umbenennen.py` (Tabellen je Bereich, Probelauf, `--liste`, Kollisionsprüfung gegen Repo, Qt, Quickshell); `tools/namen-pruefen.sh` mit Ausnahmeliste `tools/namen-ausnahmen.txt` (Fristen), in test.sh nur meldend. Ausgangswert: 4048 Fundstellen in 596 Dateien | Test `tests/test_umbenennen.py` |
| D7.1 | Plugin-Beschreibung: `requires_alpe` (gegen `Brand.version`, Hinweis statt Ladesperre), `requires_dms` nicht mehr gelesen; alpeSport `bar-widget`; Alpe-Plugins `requires_alpe: >=1.0` (G1 hebt auf 1.1); Tabelle `d7-1-plugins.tsv` | plugin-reload-Test angepasst |
| D7.2a | Module nur per `git mv` (463 Dateien, inhaltlich unverändert): `DCommon/` → `Alpe/`, `Modules/DDash/` → `Alpe/Dash/`, `DBar` → `Bar`, `DIsland` → `Island`, `Modals/DLauncherV2` → `Modals/Launcher`, Harness-Ordner; Symlinks unter den alten Pfaden (Tabelle `d7-2a-module.tsv`) | test.sh grün |
| D7.2b | Alle Importe auf `qs.Alpe.*`, `qs.Modules.Bar`/`Island`, `qs.Modals.Launcher` samt relativer Pfade (Shell, Plugins, Harnesse, Tests, Makefile, doctor, Grundlinien); Symlinks weg; 115 `D*`-Typen (124 Dateien): 95 Bibliothek → `Alpe*`, 18 intern ohne «D», `DToplevels` → `Toplevels`, `DSearchService` → `FileSearchService` (`DMS*` bleibt für D7.4/D7.5); Importname `DCommon` → `Alpe`; 88 Übergangs-Hüllen `shell/DCommon/Widgets/` (erzeugt von `d7-2b-huellen.py`, Ausnahmeliste Frist D7.8); `namen-pruefen` meldet auch Importe über `qs.DCommon` (Tabelle `d7-2b-importe.tsv`) | test.sh grün; Namensprüfung 4042 Fundstellen, kein `qs.DCommon` ausserhalb der Hüllen; Ladeprüfung KWin auf diesem Stand: 29/29, nichts neu, nichts weg (0.8 Nr. 28) |
| D7.3a | claudeCodeUsage 1.3.6 (MIT, Nicolas Bellamy) nach `plugins/claudeCodeUsage/`: `Dank*` → `Alpe*` aus `qs.Alpe.Widgets`, `bar-widget`, `requires_alpe: >=1.0`, README mit Herkunft, NOTICE; ohne `.git`, `.github` und Bildschirmfoto; nicht automatisch eingeschaltet; eigene Tests in test.sh | test.sh grün (QML der Plugin-Seiten nicht geladen) |
| D7.3b | `docs/plugins-anpassen.md` für hueManager und sathiAi; ausserhalb des Repos: `~/alpe-plugins` (lokal, Branch `main`, Commit `88b4806`, kein Remote) mit calculator 0.3.5 (AGPL-3.0 unverändert, `CHANGES.md`, Kopfvermerk; `alpe-dienst cl copy`, `requires_alpe`) | test.sh grün; Node-Tests des calculator grün |
| D7.N2 | `namen-pruefen` meldet die 115 alten `D*`-Typnamen (`tools/namen-verboten.txt`, ganze Bezeichner, auch in Dateinamen); Hüllen unter `shell/DCommon/Widgets/` bis D7.8 ausgenommen (0.8 Nr. 34) | Test in `tests/test_umbenennen.py`; kein Fund ausserhalb der Ausnahmen |
| D7.4 | Schnittstelle Dienst ↔ Oberfläche: `ShellBackend`, `BackendNetworkService` (Dateien), `backendBin`, `checkBackendCapabilities`, `backendReachable`; JSON `fragmentStatus`, `bindsAfterFragment`/`rulesAfterFragment`, `bindsFragmentIncluded`/`rulesFragmentIncluded` samt Go-Typen (`FragmentStatus`, `BindsFragmentStatus` …); Kürzel-Quelle `"shell"`/`"shell-default"`, `isShellManaged` (Tabelle `d7-4-schnittstelle.tsv`, 823 Ersetzungen in 128 Dateien) | test.sh grün; Go-Tests keybinds, windowrules, configfrag, cmd grün |
| D7.5a | Oberfläche: `ShellMain.qml`/`ShellIpc.qml`; 64 Bezeichner `dankBar…`/`dankDash…`/`dankIsland…`/`dankLauncherV2…`/`DankDot` ohne Marke (alte Einstellungsschlüssel der Migration bleiben); Kürzel-Aktionen `isShellAction`, `SHELL_ACTION_ARGS` …, Aktionsart **`"shell-action"`** statt des geplanten `"shell"` (schon vergeben für `spawn_shell`; Kollision von 2.3.2 übersehen); `DLogoShape.js` → `LogoShape.js` (0.8 Nr. 35) (Tabelle `d7-5-oberflaeche.tsv`, 530 Ersetzungen in 46 Dateien) | test.sh grün |
| D7.5b | Notizblock: Anbindung an `dankNotepadModule` samt nur davon gespeister Vorschau weg (`SESSION_BACKED_PLUGIN_IDS` in `SettingsStore.js` bleibt für Altdaten); «Create»-Knopf (Wallpaper creator), `dms://wallpaper/install/` in Shell und `alpe-dienst open`, Installations-Nutzlast in `MaterialWallpaper.js`; Doku-Links (`Site.qml`, Go-Paket `internal/site`, doctor-URLs, Hilfetexte, Autostart-Hinweis, Themen-Fehlermeldung); adw-gtk3-Link auf die Projektseite | test.sh grün |
| – | Plan: Entscheide nach D7.5 (0.8 Nr. 36–40), `offene-faelle.md` (Markdown-Vorschau vor G1, Hinweis bei veralteter Benutzerkopie), `CLAUDE.md` (Go-Modul-Cache) | – |
| D7.6 | Gespeicherte Kennungen: Starter-Einträge `alpe_*`, Seiten-IDs `bar…`/`dash` (Selbst-Aliasse und Aliasse `dank_island`/`dankdot` weg), Logo-Modus `"alpe"`, Material-Vorlage «Alpe» mit Form `alpeLogo`, matugen-Spec `"alpe"` (`SpecAlpe`), IPC-Ziel `dankdash` weg (Tabelle `d7-6-kennungen.tsv`, 142 Ersetzungen in 30 Dateien). **Migration v44** (Einstellungen) und **Session v8** über `Common/settings/Namen44.js`; Sicherung `settings.v<alt>.json` wie in D5, neu auch `session.v<alt>.json`; `design.py` führt dieselben Tabellen, `design/kde` auf v44. **Alpe-Zeichen:** `Alpe/Widgets/LogoShape.js` ist die einzige Quelle der Pfaddaten (Vielecke); daraus die Form `alpeLogo` (Material-Vorlage), der Logo-Modus (zeichnet die Form statt die SVG-Datei zu laden) und die beiden SVG-Dateien (byte-gleich, vom Test geprüft). Übersetzungsbegriff «Dank» weg, Suchindex neu erzeugt | Tests `tests/test_einstellungen.mjs` (Datei aus 1.0 und auf v43, Session), `tests/test_logoform.mjs`, `tests/test_design.py`; test.sh grün; Go `internal/matugen` wie bekannt; Namensprüfung 2665 |
| D7.6 (Nachtrag) | Session-Migration v8 mit Dateitest (`session.json` aus 1.0, Sicherung `session.v7.json`, zweiter Lauf), migrierter Stand wird gleich geschrieben; v44 zieht die Seiten-IDs in `settingsHiddenPages` mit; Prüfung aller in D7 umbenannten Kennungen auf gespeicherte Vorkommen (0.8 Nr. 41–42) | test.sh grün; Go: die drei bekannten Fehlschläge (0.8 Nr. 43) |
| D7.7a | Restliche `"dms"`-Werte (0.8 Nr. 38): Kürzel-Kategorie «Alpe» bekommt ihren Platz in der Reihenfolge (stand vorher unter `"dms"` und fiel damit ans Ende), `"dms"` bleibt übergangsweise erkannt (Ausnahmeliste, Umzug-Ende); Prozessliste `isShell`, Neustart-Art `"shell"`; doctor `getShellVersion` (Tabelle `d7-7a-werte.tsv`, 27 Ersetzungen in 3 Dateien). Die übrigen Bezeichner der Oberfläche folgen als D7.7a2 | Test `tests/test_werte.py`; test.sh grün; go build/vet wie Ausgangsstand, Go-Tests `cmd` grün; Namensprüfung 2650 | D7.7a2 |
| D7.7a2 | Übrige Bezeichner der Oberfläche: 60 Bezeichner `dms…`/`Dms…` → `shell…`/`backend…`, Kalender `dank…` → `dux…` (`CalendarDuxBackend.qml`), **Layer-Namensräume `dms:…` → `alpe:…`** (`dms:dankisland` → `alpe:island`; Dienst schneidet `alpe:` ab), `app-alpe-…`, IPC-Antworten `ISLAND_…`/`DOT_…`, `ALPE_BAR_LAYER`/`ALPE_ISLAND_LAYER`, `alpe-open`, Kommentare (Tabelle `d7-7a2-oberflaeche.tsv`, 402 Ersetzungen in 138 Dateien). Ausnahmeliste: PAM in `shell/` (E1), Lesen von 1.0-Kürzeln und -Anzeigeprofilen (Umzug-Ende), Scheintreffer `…dMs`. Folgen für F1/E3 in 2.3.5 | `tests/test_werte.py` erweitert; test.sh grün; go build/vet wie Ausgangsstand, Go-Tests `screenshot` grün; Namensprüfung 2231. QML-Laufzeit prüft die Ladeprüfung am Zwischenhalt | D7.7b |
| D7.6/D7.7 (Auflagen) | Go-Tests lesen die Oberfläche unter `shell/` statt am Ursprungspfad `quickshell/`: die drei bekannten Fehlschläge sind grün, der Katalogtest der Hyprland-Kürzel läuft jetzt mit (0.8 Nr. 49). `i18nsync.py`/`i18nsync_plugins.py` entfernt (kein Aufrufer in test.sh, Skripten oder CI); **Übersetzungen werden ab jetzt nur im Repo gepflegt** (`shell/translations/poexports/de.json`, Quelltexte `en.json`) | test.sh grün; Go-Tests ohne bekannte Fehlschläge; qmllint (Qt 6.12) über `shell/`: 5600 Meldungen vor D7.7a wie danach, keine neue |
| D7.7b1 | Cache `colors.json`/`typography.json`; matugen-Vorlagen `alpe.json`, `alpe-zed.json`, `alpe-emacs.el`, Abschnitte `[templates.alpe…]`; Vorlagen-Variablen `palette16`/`palette16term` (589 Stellen), **`dank16`/`dank16term` werden bis F1 zusätzlich mit denselben Werten eingespeist** (`withLegacyPaletteNames`, Ausnahmeliste Frist F1) (Tabelle `d7-7b1-vorlagen.tsv`, 654 Ersetzungen in 38 Dateien) | Go-Test `altnamen_test.go` (beide Namen identisch, eigene Palette gewinnt); test.sh grün; go build/vet wie Ausgangsstand; Go-Tests matugen, screenshot, cmd grün |
| D7.7b2 | Ausgabedateien für Fremdprogramme heissen `alpe*` (kitty, GTK, Alacritty, WezTerm, Ghostty, foot, Discord-Clients, pywalfox, fcitx5, KDE-Farbschema `AlpeMatugen*`, Zed «Alpe …», Emacs `alpe-emacs`), `design/kde` mit; `Theme.palette16`. **Übergang bis F1** (`altnamen.go`): alte Namen bleiben als Symlink bzw. zweite Fassung aktuell, solange es sie gibt; GTK- und KDE-Erkennung gelten auch für Einbindungen aus 1.0; `gtk.sh` erkennt Marken und Sicherungen aus 1.0. Neovim unverändert (Frage). Tabelle je Programm in 0.8 Nr. 48 (`d7-7b2-ausgaben.tsv`, 245 Ersetzungen in 36 Dateien, dazu `gtk.sh` und Dienst von Hand) | Go-Tests `altnamen_test.go` (kein alter Name → nichts; Link; zweite Fassung mit alten Namen; Erkennung); test.sh grün; go build/vet wie Ausgangsstand; Go-Tests matugen, config, cmd grün; Namensprüfung 1297 |
| D7.7b3 | Fensterregeln: Marke `-- ALPE-RULE:`, IDs `alpe-floating-windows`, `alpe-window-opaque`, automatische IDs `alpe_rule_N`. Dateien aus 1.0 (`-- DMS-RULE:`, alte IDs) werden gelesen und beim nächsten Schreiben ersetzt, ohne zweiten Eintrag (`windowrules.CurrentRuleID`; Ausnahmeliste Umzug-Ende) | Go-Test `providers/altnamen_test.go`; test.sh grün; go build/vet wie Ausgangsstand; Go-Tests windowrules, cmd grün |
| D7.7b4 | `packaging/alpe-open.desktop` (`Exec=alpe-dienst open %u`, ohne das Schema `dms://`) für die Auswahl «jedes Mal fragen» der Standardprogramme; Installation in E3, `mimeapps.list` in F1 (0.8 Nr. 50) | `tests/test_werte.py` (Name = Auswahl-Eintrag, `desktop-file-validate`); test.sh grün |
| – | Plan: Entscheide nach D7.7b (0.8 Nr. 57–63), F1-Tabellen 7.6/7.7, `offene-faelle.md` (Vencord), `CLAUDE.md` (qmllint in der Haltprüfung) | – |
| D7.7b5 | **Sicherungen aus 1.0 bleiben unverändert** (0.8 Nr. 57): `gtk-theme.dms-backup`, `icon-theme.dms-backup` werden nicht mehr umbenannt; gelesen wird der neue Name, sonst der alte, das Symbolthema einmal kopiert (Marke im Zustandsordner). Skripte in `shell/Common/settings/Sicherungen.js`; Ausnahmeliste: Sicherungen und Marken in `gtk.sh` mit Frist Umzug-Ende | Test `tests/test_sicherungen.mjs` (alte Sicherung nach jedem Zugriff unverändert: Inhalt, Zeit, Inode); test.sh grün |
| – | `shell/translations/WORKFLOW.md` entfernt, README des Übersetzungsordners: nur `de` und `en`, nur im Repo, kein externer Abgleich (0.8 Nr. 61); Ausnahmeliste: alte Ausgabenamen und GTK-Import mit Frist Umzug-Ende (0.8 Nr. 59), Neovim ohne offene Frage (0.8 Nr. 60) | test.sh grün |
| D7.7c | **Hotspot:** neu «Alpe Hotspot» (Kennung `alpe-hotspot`); die Verbindung aus 1.0 («DankMaterialShell Hotspot», `dms-hotspot`) wird erkannt und unter ihrem Namen weiter benutzt, es entsteht kein zweites Profil; gibt es beide, gewinnt die Alpe-Verbindung. **CUPS:** Besitzername der Abonnements = Benutzer des Prozesses (`os/user`, Rückfall `alpe`); beim ersten Abonnieren einmal `Get-Subscriptions`, gekündigt werden nur Abonnements des Besitzers `dms` mit den Ereignissen und dem Zustellweg (`ippget`, `dbus:`) des Dienstes, danach Marke `~/.local/state/alpe/cups-abos-1.0-gekuendigt`; bei Fehler keine Marke, nächster Start versucht es wieder. `pkg/ipp`: Request-Decoder liest die Abonnement-Gruppe, Attribut `notify-subscriber-user-name` (Tabelle `d7-7c-hotspot.tsv`) | Go-Tests mit **IPP-Attrappe** (HTTP-Server mit echtem Drahtformat, kündigen darf nur der Besitzer): `cups/legacy_subscriptions_test.go` (nur passende Abonnements, zweiter Lauf ohne Anfrage, Fehler → keine Marke, neue Abonnements gehören dem Benutzer), `network/…hotspot_altnamen_test.go`; test.sh grün; go build ohne Meldung, go vet wie Ausgangsstand (nur `internal/mocks`); Namensprüfung 1183 |
| D7.7d | Dienst: Paket `internal/dank16` → `internal/palette16` (Dateien per `git mv`), Befehl `alpe-dienst palette16` (Tabelle `d7-7d-palette16.tsv`, 43 Ersetzungen in 7 Dateien). Die alten Vorlagen-Namen `dank16`/`dank16term` in `internal/matugen` bleiben bis F1 | test.sh grün; go build ohne Meldung, go vet nur `internal/mocks`; Go-Tests palette16, matugen, cmd grün (abgeschottet) |
| D7.7e | Dienst intern: `internal/config`, `configfrag`, `luaconfig`, `keybinds`, `windowrules` – 50 Bezeichner ohne Marke (`appDir`, `LoadShellRules`, `ParseHyprlandKeysWithShell`, `ShellSeen`, `BindsLuaConfig` …; `dms.go` → `shellconfig.go`, `LocateShellConfig` sucht unter `quickshell/alpe` statt `quickshell/dms`), Tabelle `d7-7e-konfiguration.tsv` (243 Ersetzungen in 22 Dateien); Texte, Kommentare und Testdaten auf den gemeldeten Zeilen mit `texte-ersetzen.py` + `d7-7e-texte.tsv` (113 Zeilen). **Marken `-- ALPE_STARTUP_BEGIN/END`** (alte werden gelesen, geschrieben werden nur die neuen; heute liest sie nur die eigene Vorlage, in Dateien der Nutzer bleiben die alten als Kommentar stehen). **Sicherungsordner `.alpe-backups`**; `.dms-backups` wird weder umbenannt noch beschrieben (0.8 Nr. 57). **Drei übersehene alte Namen in den eingebetteten Hyprland-Vorlagen behoben:** `SUPER + D` und die Helligkeitstasten riefen noch `dms ipc call …`, die Vorlage sendete `dms:geometry` (die Shell hört seit D7.7a2 auf `alpe:geometry`), die Layer-Regel traf `^dms:.*` statt `^alpe:.*`; der Start ohne systemd rief `dms run` statt `alpe-dienst run`. Der Deployer hat weiterhin keinen Aufrufer (`offene-faelle.md`) | Go-Tests `config/altnamen_test.go` (alte Marken, Vorlagen ohne alte Namen, `.dms-backups` unverändert), `keybinds/providers/altnamen_test.go`; test.sh grün; go build ohne Meldung, go vet nur `internal/mocks`; Go-Tests der fünf Pakete und `cmd` grün; Namensprüfung 805 |
| D7.7f | Dienst intern: `internal/matugen` (Rest) – `paletteJSON`, `generatePaletteVariants`, `isGTKColorsActive` (auch der Verweis in `gtk.sh`), `cssUsesShellColors`, `newAlpeScheme`; Kommentare (Tabellen `d7-7f-matugen.tsv`, 42 Ersetzungen in 8 Dateien, und `d7-7f-texte.tsv`, 23 Zeilen). Alte Vorlagen-Namen und `altnamen.go` bleiben (Ausnahmeliste) | test.sh grün; go build ohne Meldung, go vet nur `internal/mocks`; Go-Tests matugen grün |
| D7.7g | Dienst intern: `cmd/alpe-dienst`, `internal/version`, `internal/log` (`duxlog`), Pakete unter `internal/server` – 29 Bezeichner (Tabelle `d7-7g-dienst.tsv`, 129 Ersetzungen in 11 Dateien), Texte/Testdaten `d7-7g-texte.tsv` (106 Zeilen). **Nach aussen sichtbar:** D-Bus-Objektpfade `/io/github/alpe_shell/Alpe/…` (BlueZ-Agent, MPRIS-Spieler, iwd-Agent; vorher `/com/danklinux/…`), logind-Sperren unter dem Namen «Alpe», User-Agent `Alpe/1 (+https://github.com/alpe-shell/alpe)` für Liedtexte und Wetter, Temp-Namen `alpe-*`, Archivname `alpe-backup-<Zeit>.tar.gz`, Hilfetexte (`alpe-dienst qr`, `--spec alpe`). Richtlinien-Befehle werden gegen `alpe-dienst …` statt `dms …` normalisiert (Pfade der Richtlinien folgen in E1). `internal/version`: `GetInstalledShellVersion` … (nur `CompareVersions` hat Aufrufer – Frage zum Halt). **Unverändert bis E4:** Paketnamen des Ursprungs in `sysupdate` (Ausnahmeliste). Ausnahmeliste neu: `dux-calendar`/`dux-files` in doctor (optionale fremde Programme), Sockets/Einheit eines daneben laufenden DMS, `…dMsg`. `internal/mocks/version` folgt mit der Neuerzeugung in D7.7h | test.sh grün; go build ohne Meldung, go vet nur `internal/mocks`; Go-Tests cmd, version, log, server/**, backup grün (24 Pakete, abgeschottet) |
<!-- D7-Stand -->

Go-Tests (`go test ./...`, abgeschottet): dieselben 3 Fehlschläge wie vor C1 (siehe offene
Fälle). Node-Tests des Ursprungs: 10 Fehlschläge, alle schon vor C1 rot. Jeder Commit nach D3
einzeln mit test.sh geprüft (Zwischenstände in einem Temp-Worktree).

**Zwischenfall (22.11.2026, behoben):** Commit «Dienst: sichtbare Texte» enthielt versehentlich
die gebaute Binärdatei `core/alpe-dienst` (47 MB; `go build ./...` legt sie in `core/` ab,
`.gitignore` kannte nur `core/dms`). Nur lokal, nie gepusht. Aus der Geschichte entfernt
(Commits ab diesem neu angeordnet, Bäume sonst identisch), `core/alpe-dienst` steht jetzt in
`.gitignore`. Deshalb tragen die D6-Commits ab dort neue Hashes (Tabelle nachgeführt).

Offene Fragen aus C4 (Deployer in `internal/config`, Hinweistexte auf `dms setup`) stehen in
`docs/plan/offene-faelle.md` unter «Nach C4: Liste für D», Folgen von D1–D3 unter «Nach D1» und
«Nach D2/D3».

### Entscheide nach C3 (Punkte 1–4)

Stand: **entschieden am 21.11.2026, siehe 0.5.** Ursprüngliche Vorschläge:

1. `core/internal/distros` (genutzt von `doctor`, `update`, `migrate`, `setup`, `switch`;
   hält `deps.WindowManagerNiri`/`WindowManagerMango` am Leben) – Vorschlag: in C4 entfernen
   samt der Befehle, die nur Distributions-Installation betreffen; `GetOSInfo` für `doctor`
   als kleines eigenes Paket behalten.
2. `shell/VERSION` und `CODENAME` (gelesen von `bootstrap.sh`, `ShellVersionService`,
   `commands_common.go`) – Vorschlag: in C4 zusammen mit `ShellVersionService` entfernen,
   Version allein aus `Brand.qml`.
3. Bildschirmfreigabe-Symbol (Kontrollzentrum, Sperrbildschirm) zeigte nur unter niri etwas
   und ist jetzt immer aus – Vorschlag: an `PrivacyService.screensharingActive` hängen oder
   samt Option entfernen.
4. Abgeschaltete Zweige (niri/Mango-Felder im Fensterregel- und Kürzel-Editor, Zieh-Pfad
   zum Umsortieren der Arbeitsflächen, Übersichts-Pille, `fullscreenAutoHide`-Kette) –
   Vorschlag: eigener Aufräum-Commit vor D7.

### Als Nächstes

- ~~Mac-Test des Stands nach C5~~ erledigt, Befunde in 0.6.
- ~~**C4**, **C5**~~ erledigt.
- ~~SettingsSearchRegistration, **C6**, **D1–D3**~~ erledigt; Halt nach D3 am 22.11.2026
  abgenommen, Entscheide in 0.7. Ladeprüfung bis D3: jeder Commit einzeln, Endstand `170c7d1`
  KWin 29/29, Hyprland 38/38.
- ~~D4, D5, D6~~ erledigt; **Halt nach D6** (22.11.2026). Fragen zum Halt in
  `offene-faelle.md`, Abschnitt «Nach D4–D6: Fragen».
- Mac-Test des Stands nach D6 (Anleitung in `offene-faelle.md`, Abschnitt «Mac-Test»).
- **0.8: D7 kommt wieder**, 2.3 am 22.11.2026 freigegeben mit Änderungen (0.8 Nr. 6–19).
- **D7 läuft** (Entscheide 0.8 Nr. 20–24): D7.G, D7.N, D7.0–D7.7 nach 2.3.5, Zwischenhalt
  nach D7.7; D7.8 erst nach Bestätigung, dass die Plugins an PC und Mac umgestellt sind.
- **Erledigt bis D7.2b** (dazu 0.8 Nr. 25–30). Ladeprüfung KWin auf D7.2b ohne Neues (0.8 Nr. 28). D7.3 erledigt. Entscheide nach D7.3: 0.8 Nr. 31–35. Verbotene `D*`-Namen in der Namensprüfung (0.8 Nr. 34). D7.4, D7.5 erledigt. Entscheide nach D7.5: 0.8 Nr. 36–40. D7.6 erledigt, Nachträge dazu 0.8 Nr. 41–46. **Nächster Schritt: D7.7h** (Aufteilung D7.7a–D7.7i in 2.3.5), danach Ladeprüfung mit allen Repo-Plugins (0.8 Nr. 33) und Zwischenhalt (0.8 Nr. 29, 45). Installierte Kopien von alpeSport/alpeRadar unter `~/.config/dms/plugins` importieren noch `qs.Modules.DDash` und müssen mit 1.1 durch die Repo-Fassung ersetzt werden.
  Für jeden Bereich eine Tabelle `entwicklung/umbenennen/<bereich>.tsv` anlegen, Probelauf mit
  `--liste` prüfen, dann `--schreiben`; `bash tools/test.sh` muss grün sein, Namensprüfung zeigt
  die sinkende Zahl. D7.2a: nur `git mv` plus Symlinks unter den alten Pfaden (Werkzeug-Art
  `link`); D7.2b: Importe, Typen, Symlinks weg, Übergangs-Hüllen `shell/DCommon/Widgets/D*.qml`
  für sathiAi (2.3.0). Go-Tests abgeschottet mit Temp-HOME (Socket-Pfade unter 108 Zeichen).
  Fehlschläge der Node-Tests stehen in `tests/data/node-bekannte-fehlschlaege.txt`; ändern sich
  Testnamen durch die Umbenennung, die Liste im selben Commit nachführen.
- Halt nach D7 → Mac-Test → Vorlage 6.7 → E1 (0.8 Nr. 6).

---

## 0. Befunde vorab

### 0.1 Warum der CI-Lauf zu 1.0 rot ist

Die **Tests** sind auf allen Commits grün (auch auf c988364 und auf `v1.0`). Rot ist ein
**Release**-Lauf:

| Zeit (UTC) | Workflow | Ref | Commit | Ergebnis |
|---|---|---|---|---|
| 19.11. 19:27 | Release | v1.0 | dd66c9d | grün – Release mit Archiv angelegt |
| 19.11. 21:36 | Release | v1.0 | 713bb47 | **rot**: `a release with the same tag name already exists: v1.0` |
| 19.11. 22:25 | (nur Tests) | v1.0 | c988364 | grün – kein Release-Lauf mehr |

Ursache: Der Tag `v1.0` wurde zweimal verschoben (dd66c9d → 713bb47 → c988364). `release.yml`
ruft stur `gh release create` auf und scheitert, sobald es den Release gibt.

Folge, die schwerer wiegt als das rote Kreuz: **Das Archiv `alpe-zugerberg-1.0.tar.gz` am Release
stammt von dd66c9d, nicht vom heutigen Tag-Commit c988364.** Wer «alpe update ARCHIV» mit dem
Release-Archiv macht, bekommt einen älteren Stand als `git pull`. (Bisher 1 Download.)

Korrektur in Phase A (Commit A1):
- `release.yml` idempotent: gibt es den Release schon, `gh release upload --clobber` und
  `gh release edit --notes …`, sonst `create`.
- Prüfschritt: Tag-Name muss zu `version` in `Brand.qml` und zum obersten Eintrag in
  `CHANGELOG.md` passen, sonst Abbruch (verhindert Release mit falscher Nummer).
- Ab 1.1 hängt der Release-Lauf zusätzlich Quell-Tarball mit vendorten Go-Modulen an (für
  PKGBUILD/COPR, siehe 6.3).
- `actions/checkout@v4`, `setup-node@v4`, `setup-python@v5`, `setup-go@v5` laufen auf
  Node 20 (Warnung im Log) → auf die aktuellen Hauptversionen heben.
- Das falsche 1.0-Archiv korrigiere ich nicht (Release-Arbeit gehört dem Maintainer) – siehe Frage 13.

### 0.2 Repository und Branch

- Das GitHub-Repo ist umgezogen: `alpemessi/alpe` leitet auf **`alpe-shell/alpe`** (Organisation)
  um. `get.sh`, `Brand.url`, README, `release.yml`-Kommentare zeigen noch auf `alpemessi/alpe`.
  Die Umleitung hält, solange niemand unter `alpemessi` ein neues Repo `alpe` anlegt.
- `origin/main` ist einen Commit weiter als das lokale `main`: e3de976 «Fix logo path in README
  for dark mode» (README-Pfad `assets/logo/logo/…`). `phase-a` hängt an c988364. Vor dem ersten
  Umsetzungs-Commit: `git fetch` und `phase-a` auf `origin/main` setzen (bisher liegen nur die
  ungetrackten Plan-Dateien darauf, also verlustfrei). Nebenbei: der doppelte Ordner
  `assets/logo/logo/` wird zu `assets/logo/`.

### 0.3 Laufendes System (nur gelesen)

- `dms.service` aus dem Paket `dux-shell 2.1.2-1.1` (cachyos-extra-v3), Drop-ins:
  `kwin.conf` (ExecStart `-c ~/dux-shell/quickshell`, **`QT_QPA_PLATFORMTHEME=kde`** – das muss
  in den neuen Dienst unter KDE mit), `zz-alpe-backend.conf` (eigener Bau
  `~/.local/lib/alpe/alpe`), `zz-alpe-name.conf` (`MALLOC_ARENA_MAX=2`). Ein `alpe.conf`, wie
  `phase-a.md` annimmt, gibt es auf dem PC nicht – die Umzugslogik muss beliebige Drop-ins
  auswerten, nicht feste Namen.
- `~/.local/state/DankMaterialShell` ist ein **Symlink auf `dms`** (Altlast); `alpe backup`
  sichert noch über diesen Pfad.
- `~/.config/dms/plugins/` enthält neben den drei Alpe-Plugins ein fremdes Plugin und
  `.repos` – der Umzug darf nur die Alpe-Plugins ersetzen.
- `~/.config/alpe/` und `~/.local/state/alpe/` existieren schon (Marken, `hyprlock.conf`,
  `update.json`, `lockstil-1.4.3`) – **keine Namenskollision** mit den DMS-Dateien
  (`settings.json`, `plugin_settings.json`, `plugins/`, `plugins.lock.json`, `config.d/`,
  `firefox.css`, `zen.css`, `settings.v*.json`, `session.json`, `appusage.json`, `pam/`,
  `wellbeing/`). Der Umzug prüft das trotzdem dateiweise.
- `kwinrulesrc` enthält keinen Verweis auf dms/dux/quickshell.
- `settings.json` enthält Werte mit «dank» (`dankLauncherV2`) → Einstellungs-Migration nötig.
- Installiert ist auch `dux-gop` (`/usr/bin/dgop`). Die Shell braucht das Programm nicht (der
  Dienst bindet die Go-Bibliothek `dux-gop/gops` direkt ein) – Kandidat zum Entfernen am Schluss.

### 0.4 Freigabe: Entscheide und Änderungen (21.11.2026)

Antworten auf Abschnitt 12:

| # | Entscheid |
|---|---|
| 1 | `alpe` (CLI) + `alpe-dienst` (Go) |
| 2 | App-ID `io.github.alpe_shell.Alpe` |
| 3 | `phase-a` auf `origin/main` gesetzt (erledigt), alle URLs auf `alpe-shell/alpe`; `main` und `v1.0` bleiben unberührt |
| 4 | Übersetzungen nur de + en |
| 5 | Greeter weg; Aktualisierung/Changelog/Willkommen des Ursprungs weg; Plugin- und Theme-Browser **inklusive `internal/registries` ganz entfernen** (eigener Commit, lokales Laden von Plugins bleibt); vsix weg; **Tailscale weg** (QML-Service, `internal/server/tailscale`, Abhängigkeit `tailscale.com`, Einstellungen, Leisten-Widget) |
| 6 | ~~D7 als letzte Etappe mit eigenem Halt~~ geändert in 0.7 Nr. 3 (D7 entfällt), **zurückgenommen in 0.8 Nr. 1:** D7 nach D6 mit eigenem Halt (2.3) |
| 7 | Eigenes COPR `alpe-shell/alpe` mit selbst gebautem Quickshell (Vorlage: errornointernet), bei Bedarf matugen. Mac-Ausgaben inkl. `getconf PAGESIZE` folgen |
| 8 | ~~Hyprland startet über `exec-once = alpe start`~~ **geändert in 0.6 Nr. 1:** Hyprland startet `alpe.service` über `hyprland-session.target` |
| 9 | dux-go/dux-gop bleiben, Ausnahme in der Namensprüfung |
| 10 | AUR-Veröffentlichung zum Release von 1.1 durch den Maintainer; bis dahin baut `get.sh` aus dem PKGBUILD im Repo |
| 11 | Alte Ordner bleiben bis `alpe umzug aufraeumen`; `alpe doctor` erinnert daran |
| 12 | `~/alpe` am Mac bleibt |
| 13 | Archiv aus c988364 bauen, `gh release upload`-Befehl dem Maintainer geben |
| 14 | Bilder bestätigt: `wallpaper.jpg`, `wall.png`, `jagged-peaks-wolkenzug.mp4` sind selbst erstellt bzw. frei weitergebbar und bleiben |
| 15 | Herkunftsvermerk in NOTICE genügt |
| 16 | KWin-Patch v1–v4: vom Maintainer mit Claude vom 15. bis 17.11.2026 gegen DMS v2.1.2 geschrieben, kein fremder Code; in NOTICE als Teil von Alpe (MIT) |
| 17 | `dux-gop` zum Entfernen anbieten (zuerst `--print`) |

Änderungen am Plan:
- **Sperrbildschirm unter `/usr/share`:** `lockscreen.sh` schreibt heute `layout.js` und Bilder ins
  installierte Design. Wo nutzerspezifische Sperr-Dateien künftig liegen und was das für Umzug,
  `design apply/export` und `alpe entfernen` heisst, wird als Abschnitt 6.7 **vor E1 vorgelegt**.
- **Neuer Befehl `alpe start`:** fehlt `~/.config/alpe/settings.json` und gibt es
  `~/.config/dms/settings.json`, zuerst `alpe umzug --nur-dateien`, dann
  `exec alpe-dienst -c … run`. `alpe.service` (ExecStart) und die Hyprland-Startzeile nutzen
  beide `alpe start`; das `ExecStartPre` entfällt.
- **`alpe.service`** bekommt `Conflicts=dms.service` und `After=dms.service`. Das Paket bleibt
  ohne `conflicts`.
- `CLAUDE.md` wird committet, neutral formuliert.
- **Fremde Plugins** (alles ausser `alpe*`) und `.repos` fassen weder der Umzug noch
  `alpe entfernen --alles` an.
- **Sport-Musterdaten:** Der Testlauf darf eingecheckte Dateien nie verändern; `make_fixtures.py`
  bzw. die Szenen schreiben in ein Temp-Verzeichnis. Eigener Commit in C1.
- B3 ist in zwei Commits geteilt: Schicht 0001 übernehmen (Baumvergleich), dann Schichten
  auflösen und Werkzeuge/Tests/CI auf den eigenen Baum umstellen (`ALPE_SHELL_DIR` = Verzeichnis
  mit `shell.qml`, Vorgabe `shell/`).
- Gearbeitet wird im Worktree `~/alpe-phase-a`; `~/alpe` bleibt bis zum Ende von Phase A auf
  eacdaa4 (dort hängt die laufende 1.0-Einrichtung).
- **Halte:** nach A1, nach B3 (Baumvergleich), nach C4 (seit 0.5: nach C5), nach D6, **nach D7** (0.8), nach E4,
  nach F2, zuletzt G1 – jeweils mit Zusammenfassung und Diffstat.

### 0.5 Entscheide nach C3 (21.11.2026)

| # | Entscheid |
|---|---|
| 1 | **C4** = Grenzfälle nach 0.4/4.3, zusätzlich: `core/internal/distros` samt den Befehlen `update`, `migrate`, `setup` und `switch` weg. Vorher prüfen, ob Oberfläche oder `tools/` einen davon aufrufen; wenn ja, bleibt genau dieser und kommt auf die Liste für D. `doctor` bleibt, ohne Distributionsprüfung (`GetOSInfo` als kleines eigenes Paket). Damit dürfen `deps.WindowManagerNiri`/`WindowManagerMango` weg. |
| 2 | `shell/VERSION` und `CODENAME` samt `ShellVersionService` weg. **Einzige Quelle der Version ist `Brand.qml`.** `bootstrap.sh` und `commands_common.go` lesen sie daraus; das Makefile setzt sie beim Bau des Go-Dienstes per `-ldflags` aus `Brand.qml`. Ein Test prüft, dass `dms version` (später `alpe-dienst version`) und `Brand.qml` übereinstimmen. |
| 3 | Bildschirmfreigabe-Symbol: **nicht in Phase A**, bleibt unverändert; in `offene-faelle.md` mit dem Vorschlag, es nach 1.1 an `PrivacyService.screensharingActive` zu hängen. |
| 4 | **C5** = Aufräumen der abgeschalteten Zweige (Fensterregel- und Kürzel-Editor, Zieh-Pfad zum Umsortieren der Arbeitsflächen, Übersichts-Pille). Nur nachweislich toten Code entfernen, Ladeprüfung unter KWin und Hyprland. |
| 5 | Weiterhin ein Thema pro Commit. **Halt nach C5** (statt nach C4). |

### 0.6 Befunde aus dem Mac-Test nach C5 (21.11.2026)

Mac-Test auf `2271063`: Shell startet unter Hyprland 0.57.2 (Fedora Asahi 45, aarch64, Quickshell
0.3.2 aus COPR `avengemedia/quickshell`), alle Plugins geladen, keine QML-Fehler im Log;
`doctor` erkennt Hyprland, 1 Warnung (`QT_QPA_PLATFORMTHEME=gtk3`).

| # | Befund | Entscheid / Folge |
|---|---|---|
| 1 | Am Mac läuft die Shell als `dms.service` (enabled, active), gestartet über `hyprland-session.target`, nicht per `exec-once`. | **Entscheid 8 geändert:** Unter Hyprland startet `alpe.service` wie heute `dms.service` über `hyprland-session.target` (`hyprland-session.target.wants/alpe.service`), unter KDE über `graphical-session.target`. Ein gemeinsamer Startweg: `ExecStart=/usr/bin/alpe start --session` in der Unit für KWin und Hyprland, keine `exec-once`-Zeile. Angepasst: 6.1, 6.4, 6.6, 6.8, 7.2 Schritt 7, 7.4. |
| 2 | Die Testshell schreibt beim Start `~/.config/hypr/dms/layout.lua` (`HyprlandService`). | Mac-Anleitung sichert `~/.config/hypr` mit. Umzug: Die Shell erzeugt Dateien im Hypr-Ordner selbst (`outputs`, `layout`, `cursor`, `input`, `windowrules`, über matugen `colors`); beim Wechsel auf `hypr/alpe/` siehe 7.4. |
| 3 | `hyprctl descriptions parse failed: SyntaxError: JSON.parse` (`HyprlandService.qml:257`) unter Hyprland 0.57.2, auch schon in 1.0. | In `offene-faelle.md`, nicht in Phase A. |
| 4 | Fremde Plugins (Mac: hueManager, calculator; PC: sathiAi, claudeCodeUsage) benutzen DMS-Namen (`DankIcon` …). | Vorschlag in `offene-faelle.md` («Plugin-Kompatibilität»); angenommen in 0.7 Nr. 3. |

Weiter: SettingsSearchRegistration beheben (eigener Commit), **C6** Aufräumen (Reste aus C5 und
der Liste «Nach C4»), dann D1–D3. **Halt nach D3.**

### 0.7 Entscheide nach dem Halt D3 (22.11.2026)

| # | Entscheid |
|---|---|
| 1 | Entfernte versteckte Migrationen (DMS-1.x-Ordner, ICC aus `hypr/dms/`, Zwischenablage aus `dms-clipboard`): einverstanden. Umgezogen wird allein über `alpe umzug`. |
| 2 | Hyprland-Kürzel mit `dms ipc …`/`dms screenshot` schreibt der Umzug (F1) auf `alpe-dienst` um (`offene-faelle.md`, «Nach D1»). |
| 3 | **Ersetzt durch 0.8.** ~~Plugin-Kompatibilität wie vorgeschlagen: die 40 `Dank*`-Weiterleitungen in `shell/Widgets/` bleiben, `requires_dms` wird weiter gelesen, **kein** `/usr/bin/dms`. **D7 entfällt:** Interne Bezeichner (`DMSService`, `DankBar`, `dmsBin`, `isDmsAction`, `source: "dms"` …) kommen auf die Ausnahmeliste der Namensprüfung (G1) und werden erst in Phase C angefasst. Ersetzt 0.4 Nr. 6 und Antwort 12.6.~~ |
| 4 | Root-Helfer der Prozessliste (`process.restartService`, System-Dienste auf Klick) bleibt; 6.8 betrifft nur `alpe.service`. |
| 5 | Werkzeuge mit `dms.service` und 1.0-Pfaden (`tools/alpe`, `entfernen.sh`, `install.sh`, `design.py`): wie geplant in E4. |
| 6 | **Prüfregel ab D4:** `bash tools/test.sh` nach jedem Commit. Die Ladeprüfung läuft **einmal pro Halt** auf dem Endstand unter KWin und Hyprland; nur wenn sie neue Meldungen zeigt, werden die Commits dazwischen einzeln geprüft. Keine Überwachungen, die sich periodisch neu stellen. **Ergänzt (0.8 Nr. 63):** Zur Haltprüfung gehört qmllint (`/usr/lib/qt6/bin/qmllint`) über `shell/` gegen die Grundlinie von 5600 Meldungen; neue Meldungen werden einzeln eingeordnet. |
| 7 | Mac-Test nach D6 statt nach D3. |

### 0.8 Entscheide nach dem Halt D6 (22.11.2026)

| # | Entscheid |
|---|---|
| 1 | **Korrektur zu 0.7 Nr. 3: D7 bleibt.** Vollständige Umbenennung der internen Namen (`DankBar`, `DMSService`, `Dank*`-Widgets usw.). Kompatibilität mit dem DMS-Plugin-Store braucht Alpe nicht; ein eigener Store kommt allenfalls später. |
| 2 | **Keine `Dank*`-Weiterleitungen** (auch nicht `Modules/DankBar`, `Modules/DankDash`, `Common/Dank*`, `DankModal`). Die Plugin-Beschreibung bekommt eigene Namen (`requires_alpe` statt `requires_dms` …); `alpeSport`, `alpeMeteoSwiss`, `alpeRadar` im selben Zug. |
| 3 | **Fremde Plugins** hueManager, calculator (Mac) und sathiAi (PC) werden an die neuen Namen angepasst. Lizenz vorher prüfen: Erlaubt sie es, kommen sie als von Alpe gepflegte Plugins ins Repo, sonst Anleitung für die lokalen Kopien. Befund siehe 2.3.4. |
| 4 | **Kein `/usr/bin/dms`.** |
| 5 | **D7 nach D6 mit eigenem Halt**, skriptbasiert, ein Commit pro Bereich, Ladeprüfung auf dem Endstand unter KWin und Hyprland (Prüfregel 0.7 Nr. 6). Die Weiterleitungen fallen erst weg, wenn alle Plugins angepasst sind (letzter Commit von D7). |

Freigabe von 2.3 am 22.11.2026 mit diesen Entscheiden und Änderungen:

| # | Entscheid |
|---|---|
| 6 | **Reihenfolge:** D7 direkt nach D6, vor E1 (E1–E3 legen Dateinamen und Pfade fest und bauen auf den endgültigen Namen auf). Halt nach D7 → Mac-Test → Vorlage 6.7 → E1. |
| 7 | **Namensregel** (2.3.0): interne Typen ohne Marke; nach aussen sichtbare Kennungen mit `alpe`; Widget-Bibliothek mit Präfix `Alpe`; jeder neue Name wird gegen bestehende Alpe-, Qt- und Quickshell-Typen geprüft, Kollisionen stehen in der Tabelle. |
| 8 | **Namen freigegeben:** `DMSService` → `ShellBackend`, `dank_dash` → `dash`, `dms_*` → `alpe_*`, `dank16` → `palette16` (geprüft: weder Oberfläche, matugen-Vorlagen noch Dateien im HOME des Maintainers rufen `dank16` auf). |
| 9 | **claudeCodeUsage** kommt ins Alpe-Repo wie die Alpe-Plugins (MIT-LICENSE und Copyright bleiben) und wird in D7 angepasst. |
| 10 | **calculator** (AGPL-3.0) nicht ins Alpe-Repo, sondern in ein eigenes lokales Repo `~/alpe-plugins` (Branch `main`, eigener Ordner, unveränderte LICENSE, Copyright-Hinweis, Änderungen gekennzeichnet, README mit Herkunft und Lizenz). GitHub `alpe-shell/alpe-plugins` legt der Maintainer an und pusht. Installation entscheiden E3/E4, bis dahin als Klon. |
| 11 | **sathiAi** (Quell-Repo unbekannt) und **hueManager** (ohne Lizenz): nicht ins Repo, Anleitung für die lokalen Kopien. Anleitungen und calculator-Anpassung sind **vor D7.8 fertig**; D7.8 erst nach Bestätigung des Maintainers. |
| 12 | `requires_alpe`: Entscheid in 2.3.4 (Prüfung gegen `Brand.version`, Hinweis statt Ladesperre). Versionsangaben beziehen sich auf Alpe (1.1), nicht auf die Basis des Ursprungs. |
| 13 | Halt-D6-Frage 2: Material-Vorlage heisst «Alpe», Form = Alpe-Zeichen, Wert `"dank"` → `"alpe"` in v44. Nicht entfernen. |
| 14 | Halt-D6-Frage 4: Doku-Links nach `duxlabs.dev` (Autostart-Seite, doctor) entfernen; **«Wallpaper creator» samt Code entfernen** (ohne `/usr/bin/dms` gibt es keinen Handler für `dms://`), auch die `dms://`-Annahme in `alpe-dienst open` und `DMSShell.qml`. Als mögliche eigene Funktion in `offene-faelle.md`. |
| 15 | Halt-D6-Frage 5: Prüfliste Sie-Form → `docs/plan/sie-form.md` (Schlüssel, alter Text, Vorschlag in Du-Form); Freigabe vor G1, Umsetzung danach. |
| 16 | Halt-D6-Frage 6: **keine dauerhafte Ausnahme.** PAM-Dienst, `/usr/share/dms`-Richtlinien und alle anderen paketierten Pfade werden **in E1 zwingend** umbenannt (`alpe-shell` muss ohne `conflicts` neben `dms` installierbar sein). Hotspot: alten Verbindungsnamen erkennen, neu nur den Alpe-Namen anlegen (D7). CUPS-Benutzer `dms`: geklärt, Befund in `offene-faelle.md`. |
| 17 | Halt-D6-Frage 7: `Brand.heldPackages` mit E4 entfernen. |
| 18 | **Ausnahmeliste** enthält nur noch von aussen vorgegebene Namen; jeder Eintrag hat eine Phase, bis wann er erledigt ist (2.3.3). |
| 19 | **Node-Tests in `tools/test.sh`** mit den 10 bekannten Fehlschlägen als fester Liste: neuer Fehlschlag = rot, bekannter nicht. Eigener Commit vor D7.0. |

Folgen: Die Fragen 1 und 3 zum Halt D6 (Kennungen `dms_*`, Logo-Modus `"dank"`) erledigt D7.5.

Entscheide zum Start von D7 (22.11.2026):

| # | Entscheid |
|---|---|
| 20 | **Widget-Bibliothek Variante B:** Die `D*`-Typen aus DCommon heissen überall `Alpe*`; die `Dank*`-Hüllen fallen weg statt umbenannt zu werden. Pro Widget genau ein Typ; die Plugin-API ist dieselbe Bibliothek, die die Shell benutzt. |
| 21 | **Modulnamen** `DCommon`, `DBar`, `DDash`, `DIsland` fallen unter die Namensregel. Module, die Plugins importieren, sind Plugin-API und bekommen eine gepunktete URI im Namensraum Alpe; rein interne Module neutrale Namen, sofern die Kollisionsprüfung nichts findet. Verzeichnisse und `qmldir` mit `git mv` in einem eigenen Commit ohne Inhaltsänderung. Zuordnung 2.3.2. |
| 22 | **CUPS:** Besitzername der Abonnements = Benutzername des laufenden Prozesses (`os/user`), Rückfall `alpe`, nichts fest codiert. Alte Abonnements des Besitzers `dms`: gewählter Weg in 2.3.3. |
| 23 | **«Phase C»** ist im Plan nicht definiert und wird durch einen Auslöser ersetzt: Das Lesen alter Namen bei der Migration fällt weg, sobald der Umzug von 1.0 nicht mehr unterstützt wird, frühestens mit dem ersten Release nach Abschluss von Phase B. |
| 24 | **Prüfung nach dem Zwischenfall `core/alpe-dienst`:** `tools/test.sh` wird rot, wenn ein Commit gegenüber `origin/phase-a` eine Datei über 1 MB oder eine ELF-Binärdatei hinzufügt. Eigener Commit vor bzw. mit D7.N. |
| 25 | **`qs.Alpe.*` freigegeben.** Importpfad der Widget-Bibliothek für Plugin-Autoren: **`import qs.Alpe.Widgets`** (Ordner `shell/Alpe/Widgets/`, bisher `qs.DCommon.Widgets`); dazu `qs.Alpe.Common`, `qs.Alpe.Dash` (2.3.2). |
| 26 | **`DSearchService` → `FileSearchService`** (Regel 1, nach Funktion; Kollisionsprüfung ohne Fund). Das Programm `dsearch` stammt aus dem Umfeld des Ursprungs (`github.com/duxlabs-dev/dux-search`, im Starter als Bezugsquelle genannt, in doctor als «dux-search»): Programmname und Bezugsquelle kommen mit Frist auf die Ausnahmeliste; die Abhängigkeit wird in E3/E4 vermerkt (optional, Paket oder Hinweis). |
| 27 | **Symlinks in D7.2a** freigegeben, mit Bedingungen: D7.2b stellt **alle** Importe um und entfernt die Symlinks im selben Commit, sodass keine Datei über zwei Pfade geladen wird (QML-Typen und Singletons werden über die URL identifiziert). Nach D7.2b findet `namen-pruefen.sh` keinen Import über `qs.DCommon` mehr ausser im markierten Ordner für sathiAi. Dieser Ordner enthält nur Hüllen, keine eigenen Singletons; braucht sathiAi einen Singleton, verweist die Hülle auf den unter `qs.Alpe`. |
| 28 | **Ladeprüfung nach D7.2b** (Ausnahme von 0.7 Nr. 6): unter KWin auf diesem Stand gegen die Grundlinie, bevor D7.3 beginnt; neue Meldungen werden vor D7.3 behoben. |
| 29 | **Zwischenhalt nach D7.7:** hueManager, calculator, sathiAi und claudeCodeUsage werden ins Temp-HOME der Ladeprüfung kopiert und mitgeladen – einmal auf dem Stand D7.7, einmal mit einem nicht committeten Probelauf von D7.8 ohne Hüllen, beide Male mit den Anpassungen aus den Anleitungen. Bericht: laden alle vier ohne neue Meldungen? |
| 30 | **CUPS-Marke** nach der einmaligen Kündigung liegt unter `~/.local/state/alpe/` (nicht unter `~/.config`). |
| 31 | **`requires_alpe` in G1, als Regel:** Jedes Plugin, das mit Alpe ausgeliefert oder von Alpe gepflegt wird (alles unter `plugins/` im Repo und alles in `~/alpe-plugins`), verlangt ab G1 mindestens die Fassung, für die es zuletzt angepasst wurde, also `>=1.1`. G1 hebt `Brand.version` und alle diese Angaben im selben Commit. |
| 32 | **Benutzerkopien ausgelieferter Plugins.** Befund (22.11.2026): Einen Befehl `alpe start` gibt es noch nicht (kommt mit E4/F1, 7.2 «Sicherheitsnetz»); heute kopiert nichts aus `~/.config/dms` nach `~/.config/alpe`. Nach 7.2 Schritt 4 wird `plugins/` nicht übernommen (`alpe*` ausgenommen, fremde bleiben unberührt). Liegt ein Plugin mit derselben ID im Benutzerordner und im Systemordner, **gewinnt die Benutzerkopie** (`PluginService._onManifestParsed`: `user` ersetzt `system`, die Systemfassung gilt als verdeckt). Darum für F1: Benutzerkopien von Plugins, die Alpe selbst mitliefert (jede ID unter `/usr/share/alpe/plugins`, heute alpeSport, alpeRadar, alpeMeteoSwiss, claudeCodeUsage), werden beim Umzug **nicht übernommen, sondern mit Rückweg zur Seite gelegt** (protokolliert, `alpe umzug --zurueck` holt sie zurück). Die Mac-Test-Anleitung für den D7-Stand legt die alten Kopien von alpeSport und alpeRadar für den Test zur Seite und holt sie danach zurück (`offene-faelle.md`, «Mac-Test»). |
| 33 | **Ladeprüfung mit allen Repo-Plugins:** Im Temp-HOME werden alle Plugins unter `plugins/` eingeschaltet, nicht nur die drei, die `activate-plugins.py` für Nutzer einschaltet. So werden Plugins im Repo bei jedem Halt mitgeprüft. Umgesetzt spätestens für den Zwischenhalt nach D7.7 (Prüfregel 9/10, `CLAUDE.md`). |
| 34 | **Alte `D*`-Namen verboten:** Die 115 alten Typnamen aus `d7-2b-importe.tsv` kommen als verbotene Namen in `namen-pruefen` (ganze Bezeichner, kein allgemeines Muster wie `D[A-Z]`); ausgenommen bis D7.8 die Hüllen unter `shell/DCommon/Widgets/`. Eigener Commit mit Test vor D7.4. |
| 35 | **`DLogoShape.js`** wird in D7.5 umbenannt. Befund: Die Datei zeichnet die Logoform des Ursprungs (Kommentar «Dux Shell logo (assets/danklogonormal.svg)», benutzt von `MaterialShapes.js`). Darum stellt D7.6 sie zusammen mit der Material-Vorlage auf das Alpe-Zeichen um; beides wird gemeinsam geprüft. |

Entscheide nach D7.5 (22.11.2026):

| # | Entscheid |
|---|---|
| 36 | **Aktionsart `"shell-action"` bestätigt** (statt `"shell"` aus 2.3.2; `"shell"` ist für `spawn_shell` vergeben). |
| 37 | **Markdown-Vorschau im Notizblock:** Die Entfernung (D7.5b) bleibt in D7. Vor G1 wird die Vorschau ohne Plugin mit `Text.MarkdownText` neu gebaut, damit 1.1 gegenüber 1.0 keine Funktion verliert (`offene-faelle.md`, Frist vor G1). `SESSION_BACKED_PLUGIN_IDS` (`SettingsStore.js`, Altdaten von `dankNotepadModule`) steht mit Frist «Umzug-Ende» auf der Ausnahmeliste. |
| 38 | **Restliche `"dms"`-Werte gehören zu D7.7:** Kategorie `"dms"` und `lower.includes("dms")` in `KeybindsContent.qml`, `case "dms"` in `ProcessActions.qml`, `getDMSShellVersion` in doctor. Die Erkennung in `KeybindsContent.qml` erkennt künftig `alpe` und übergangsweise zusätzlich `dms` (die Hyprland-Binds des Maintainers enthalten bis F1 noch `dms`-Befehle); der Übergang steht mit Frist «Umzug-Ende» auf der Ausnahmeliste. |
| 39 | **Veraltete Benutzerkopie eines Plugins:** Ist eine Benutzerkopie älter als die mitgelieferte Fassung, zeigt die Plugin-Seite einen Hinweis. Ohne Frist in Phase A (`offene-faelle.md`). |
| 40 | **Go-Modul-Cache:** Abgeschottete Go-Tests (Temp-HOME) verwenden `GOMODCACHE` auf den bestehenden Cache oder `GOFLAGS=-modcacherw`, damit nichts schreibgeschützt im Temp-Ordner liegen bleibt. Merkregel in `CLAUDE.md`. |

Entscheide und Befunde vor D7.7 (22.11.2026):

| # | Entscheid |
|---|---|
| 41 | **Session-Migration v8 mit Dateitest** wie die Einstellungen: `tests/data/einstellungen-1.0/session.json` (Version 7) wird migriert, `session.v7.json` entsteht, ein zweiter Lauf ändert nichts (`tests/test_einstellungen.mjs`). Dazu: Die Sicherung läuft über `SessionStore.backupFor` (im Node-Test prüfbar), und `SessionData` schreibt den migrierten Stand gleich nach dem Laden zurück statt erst beim nächsten Speichern – vorher blieb `session.json` bis zur ersten Änderung auf Version 7 und die Sicherung wurde bei jedem Start neu geschrieben. Das Schreiben über `FileView` selbst prüft die Ladeprüfung (Session aus 1.0 im Temp-HOME, Zwischenhalt). |
| 42 | **Gespeicherte Kennungen aus D7, geprüft** (Tabelle unten). Einziger Nachzug: `settingsHiddenPages` (Seitenauswahl) speichert Seiten-IDs; v44 zieht `dankbar`, `dankbar_settings`, `dankbar_appearance`, `dankbar_dot`, `dankbar_widgets`, `dank_dash` mit (`Namen44.PAGE_IDS`, `design.py` dieselbe Tabelle, Tests). v44 war noch nicht gepusht und lief auf keinem Rechner, darum Erweiterung von v44 statt v45. |
| 43 | **`TestTerminalPaletteOnlyReachesTerminalTemplates` gehört zu den drei bekannten Go-Fehlschlägen** (`offene-faelle.md`, seit dem Stand nach C3 geführt). Ursache unverändert: Der Test liest `../../../quickshell/matugen/configs/*.toml` am Ursprungspfad. Lauf vor D7.7: genau diese drei (matugen 1, qmlchecks 2), sonst alles grün. |
| 44 | **`dankdash` bekommt keinen Übergang.** F1 schreibt **alle** alten IPC-Ziele und Befehle in den Hyprland-Konfigurationen und in den KWin-Kürzeln **aller Nutzer** um, nicht nur in denen des Maintainers (7.2 Schritt 6, 7.4 Schritt 6). Die Mac-Test-Anleitung für den D7-Stand vermerkt, dass Kürzel mit alten Zielen dort erwartungsgemäss nicht greifen. |
| 45 | **Zwischenhalt nach D7.7 prüft zusätzlich** den Logo-Modus `"alpe"` mit einem Widget (Starter-Knopf in der Leiste) und die Materialform `alpeLogo` als Hintergrund (Material-Vorlage «Alpe» in der Session des Temp-HOME). |
| 46 | **Aufteilung von D7.7** in D7.7a–D7.7h (2.3.5). Go-Bezeichner typbewusst: `gopls` ist auf dem PC nicht installiert, darum `umbenennen.py` mit ganzen Bezeichnern je Paketgruppe; nach jedem Schritt `go build ./...` und `go vet ./...` (bekannte Signaturwarnungen in `internal/mocks` ausgenommen), Go-Tests abgeschottet mit denselben drei Fehlschlägen. |

Entscheide nach dem Halt vor D7.7b (22.11.2026):

| # | Entscheid |
|---|---|
| 47 | **Vorlagen-Variablen:** neu `palette16`/`palette16term`; `dank16`/`dank16term` werden bis F1 zusätzlich mit denselben Werten eingespeist (Test `altnamen_test.go`: beide Namen identisch). **F1 schreibt die eigenen matugen-Vorlagen der Nutzer um** (`~/.config/matugen/config.toml` und die dort genannten Vorlagen: `{{dank16.` → `{{palette16.`, `{{dank16term.` → `{{palette16term.`), nicht nur die mitgelieferten; danach fällt die doppelte Einspeisung. |
| 48 | **Ausgabedateien für Fremdprogramme** heissen `alpe*`. Übergang bis F1 (`core/internal/matugen/altnamen.go`): **Solange es eine Datei unter dem alten Namen gibt** (Datei aus 1.0 oder der eigene Link), hält Alpe sie aktuell – als Symlink auf die neue Datei, oder als zweite Fassung, wo ein Link nicht trägt. Auf frisch eingerichteten Rechnern entsteht nichts. Auslöser ist die alte Datei, nicht die Einbindung selbst: Sie ist die Voraussetzung jeder funktionierenden alten Einbindung, und die Einbindung lässt sich nicht bei jedem Programm zuverlässig finden (Emacs, WezTerm). Die Erkennung «ist aktiv» (GTK, KDE) gilt auch für alte Einbindungen. Weg je Programm: Tabelle unten. **F1 schreibt die Einbindungen um** (Tabelle 7.6); Links und doppeltes Schreiben fallen mit «Umzug-Ende» weg (Nr. 59). |
| 49 | **Null bekannte Go-Fehlschläge:** Alle drei bekannten Fehlschläge lasen die Oberfläche am Ursprungspfad `../../../quickshell/…` (`TestTerminalPaletteOnlyReachesTerminalTemplates`: Vorlagen; `TestLockScreenPasswordFieldBypassesTextInputIME`: prüft in `LockAuthWidget.qml`, dass das Passwortfeld die Eingabemethode umgeht; `TestLockScreenFprintProfileMatchesPamQml`: vergleicht `assets/pam/fprint` mit dem Profil in `Pam.qml`). Sie lesen jetzt `shell/…` und sind grün; der Katalogtest der Hyprland-Kürzel übersprang sich deshalb still und läuft jetzt mit. |
| 50 | **`alpe-open.desktop`** kommt in D7.7b ins Repo (`packaging/`), installiert wird sie in E3, `mimeapps.list` schreibt F1 um. Befund am PC (nur gelesen): `/usr/share/applications/dms-open.desktop` gibt es, sie gehört zum Paket `dux-shell 2.1.2-1.1` (`Exec=dms open %u`); `mimeapps.list` nennt sie für Archive. «Jedes Mal fragen» funktioniert dort heute also nur, solange das Paket des Ursprungs installiert ist. |
| 51 | **`i18nsync.py`, `i18nsync_plugins.py` entfernt.** Übersetzungen werden nur noch im Repo gepflegt. |
| 52 | **Werkzeuge** `tools/backend.sh`, `entfernen.sh`, `alpe`, `maclock.sh` werden **vor D7.8** umgestellt (Schritt D7.7i): Namen, die Alpe selbst bezeichnen, werden umbenannt; Verweise auf 1.0-Artefakte bleiben mit Kommentar am Ort und je einem Eintrag auf der Ausnahmeliste (Frist «solange Update von 1.0 unterstützt wird»). Keine Ausnahme für ganze Dateien. |
| 53 | **v44 lag nirgends:** `origin/phase-a` steht auf Version 43 (D7.6 ist nicht gepusht), Mac und VM beziehen den Stand nur von dort; am PC liegt Version 42 (1.0). Die Erweiterung von v44 um `settingsHiddenPages` bleibt darum v44. |
| 54 | **`go vet` im Ausgangsstand:** Meldungen nur in `internal/mocks` (von mockery erzeugte `MarshalJSON`-Attrappen mit abweichender Signatur, Prüfung `stdmethods`). `go build` ohne Meldung. Behoben in **D7.7h** (dort wird `.mockery.yml` ohnehin angefasst): ~~Die Attrappen werden von dieser einen Prüfung ausgenommen~~ – ersetzt durch Nr. 62 (neu erzeugen statt ausnehmen); Ziel zum Zwischenhalt: `go vet` ohne Meldung. |
| 55 | **JSON-Schlüssel nach den Umbenennungen geprüft:** Alle in D7.4 umbenannten Felder, die über JSON laufen, tragen ein ausdrückliches Tag; die Schlüssel (`fragmentStatus`, `bindsAfterFragment` …) wurden in D7.4 bewusst auf beiden Seiten umgestellt. Ohne Tag sind nur `configfrag.Status` und die Parser-Ergebnisse (`HyprlandParseResult` …); sie werden nie serialisiert. Kein still geänderter Schlüssel. |
| 56 | **qmllint** (Qt 6.12, erzeugte `qmldir` je Ordner) über `shell/`: 5600 Meldungen vor D7.7a, 5600 danach; die 17 abweichenden Zeilen unterscheiden sich nur im Temp-Pfad bzw. im umbenannten `CalendarDuxBackend.qml`. Keine neue Meldung. |

Entscheide nach D7.7b (22.11.2026):

| # | Entscheid |
|---|---|
| 57 | **Sicherungen werden nie umbenannt, gelöscht oder verändert.** `gtk-theme.dms-backup` und `icon-theme.dms-backup` werden nicht mehr auf `*.alpe-backup` umbenannt (so stand es in D7.7b2): Alpe liest den neuen Namen und, wenn es ihn nicht gibt, den alten; wo nötig, wird kopiert, nie umbenannt. Umsetzung (`shell/Common/settings/Sicherungen.js`): Die Sicherung des GTK-Themas schreibt die Shell nur – gibt es eine unter einem der beiden Namen, entsteht keine zweite. Die Sicherung des Symbolthemas verbraucht die Shell beim Zurückgeben (lesen, löschen); die Sicherung aus 1.0 wird darum genau einmal unter den neuen Namen kopiert, eine Marke `~/.local/state/alpe/sicherung-1.0-icon-theme.uebernommen` verhindert, dass sie nach dem Verbrauch der Kopie ein zweites Mal gilt. Den alten Namen (und die Marke) räumt erst «Umzug-Ende» ab (0.8 Nr. 23). Test `tests/test_sicherungen.mjs`: alte Sicherung nach jedem Zugriff unverändert vorhanden (Inhalt, Änderungszeit, Inode). **Dasselbe gilt in F1:** Beim Umschreiben alter IPC-Ziele und Befehle (7.4 Schritt 6) sind Sicherungsordner wie `~/.config/hypr/.dms-backups/` ausgenommen und werden nicht verändert. Am Mac kommt `dankdash` nur in einer solchen Sicherung vor, aktiv benutzt wird es nicht. Der Dienst legt neue Sicherungen der Hyprland-Dateien ab D7.7e unter `.alpe-backups/` an; der alte Ordner bleibt, wie er ist. |
| 58 | **Fensterregeln, Rückweg:** `alpe umzug --zurueck` setzt `-- ALPE-RULE:` und die neuen Regel-IDs (`alpe-floating-windows`, `alpe-window-opaque`, `alpe_rule_N`) gezielt auf `-- DMS-RULE:` und die alten IDs zurück, damit 1.0 nach dem Rückweg auch Regeln bearbeiten kann, die nach dem Umzug geändert wurden. Mit Test in F1. **Allgemein (7.2 «Rückweg»):** Der Rückweg stellt den Zustand zum Zeitpunkt des Umzugs wieder her; was danach geändert wurde und nicht ausdrücklich zurückgesetzt wird, ist aufzuzählen (Liste in 7.7, vom Umzug am Ende von `--zurueck` ausgegeben). |
| 59 | **Ausgabedateien: Auslöser «alte Datei existiert» bestätigt** (Nr. 48). F1 stellt je Programm die Einbindung auf den neuen Namen um (Tabelle 7.6); **Links und doppeltes Schreiben fallen erst mit «Umzug-Ende» weg**, nicht schon mit F1 (bis dahin trägt der alte Name auch den Rückweg). `alpe-shell` liefert `alpe-open.desktop` selbst aus (E3, 6.1); F1 stellt `mimeapps.list` von `dms-open.desktop` auf `alpe-open.desktop` um. Ob Vencord beim Wechsel über den Link neu lädt: `offene-faelle.md`, ohne Frist. |
| 60 | **Neovim:** Die base46-Anbindung (`nvim/colors/dms.lua`, Lualine-Thema `dms`, `_DMS_SUPPORT`) bleibt unverändert und steht mit «solange die Anbindung besteht» auf der Ausnahmeliste. Keine offene Frage mehr. |
| 61 | **`shell/translations/WORKFLOW.md` entfernt.** Ersatz: ein kurzer Absatz im README des Übersetzungsordners – `de` und `en` werden nur im Repo gepflegt, einen externen Abgleich gibt es nicht mehr. |
| 62 | **`go vet` und die mockery-Attrappen** (ersetzt den Weg aus Nr. 54): Die Dateien in `internal/mocks` werden nicht von Hand geändert und nicht von der Prüfung ausgenommen, sondern mit dem aktuellen mockery neu erzeugt bzw. über `.mockery.yml` so eingestellt, dass die Meldung nicht mehr entsteht (D7.7h). Ziel bleibt `go vet ./...` ohne Meldung am Zwischenhalt. |
| 63 | **qmllint wird Teil der Haltprüfung**, nicht von `tools/test.sh`: `/usr/lib/qt6/bin/qmllint` über `shell/`, Grundlinie 5600 Meldungen (Nr. 56). Bei jedem Halt vergleichen; neue Meldungen werden einzeln eingeordnet (behoben oder mit Begründung in die Grundlinie). Prüfregel 0.7 Nr. 6 und `CLAUDE.md` nachgeführt. |

Ausgabedateien für Fremdprogramme (0.8 Nr. 48). Basis: `~/.config`, sofern nichts anderes steht.

| Programm | Alter Name | Neuer Name | Weg | Begründung, Einbindung (für F1) |
|---|---|---|---|---|
| GTK 3/4 | `gtk-3.0/dank-colors.css`, `gtk-4.0/dank-colors.css` | `alpe-colors.css` | Symlink | `@import` in `gtk.css` bzw. `gtk.css` als Link; GTK folgt Links. `gtk.sh` erkennt Import, Marken (`.dms-copy`) und Sicherungen (`*.dms-backup`) aus 1.0 weiter |
| kitty | `kitty/dank-theme.conf`, `dank-tabs.conf` | `alpe-theme.conf`, `alpe-tabs.conf` | Symlink | `include` in `kitty.conf` liest über den Link |
| Alacritty | `alacritty/dank-theme.toml` | `alpe-theme.toml` | Symlink | `import` in `alacritty.toml` |
| WezTerm | `wezterm/colors/dank-theme.toml` | `alpe-theme.toml` | Symlink | Schema-Name = Dateiname (`color_scheme = "dank-theme"`) |
| Ghostty | `ghostty/themes/dankcolors` | `alpecolors` | Symlink | `theme = dankcolors` |
| foot | `foot/dank-colors.ini` | `alpe-colors.ini` | Symlink | `include=` in `foot.ini` |
| Equibop, Vesktop, Vencord | `…/themes/dank-discord.css` | `alpe-discord.css` | Symlink | Auswahl über den Dateinamen; bis F1 stehen beide Namen in der Themenliste |
| pywalfox | `~/.cache/wal/dank-pywalfox.json` | `alpe-pywalfox.json` | Symlink | Zweitkopie; pywalfox selbst liest `wal/colors.json` (unverändert) |
| fcitx5 | `~/.local/share/fcitx5/themes/dms/` | `themes/alpe/` | doppelt schreiben | `Theme=dms` in `classicui.conf` meint den Ordner; ein echter Ordner aus 1.0 wird nicht durch einen Link ersetzt |
| KDE-Farbschema | `~/.local/share/color-schemes/DankMatugen{,Light,Dark}.colors` | `AlpeMatugen…` | doppelt schreiben, alter Name im Inhalt | Name steht in der Datei (`ColorScheme=`, `Name=`); `kdeglobals`, `qt5ct.conf`/`qt6ct.conf` (`color_scheme_path`) und qtengine verweisen darauf. Wer auf dem alten Schema steht, bekommt weiter das alte angewendet |
| Zed | `zed/themes/dank-zed-theme.json` (Themen «DankShell …») | `alpe-zed-theme.json` («Alpe …») | doppelt schreiben, alte Themennamen | Auswahl in `settings.json` über den Themennamen im Inhalt; ein Link ergäbe dieselben Namen doppelt |
| Emacs | `themes/dank-emacs-theme.el` (Thema `dank-emacs`) | `alpe-emacs-theme.el` | doppelt schreiben, alter Themenname | Dateiname und `provide-theme` müssen übereinstimmen |
| Neovim | `nvim/colors/dms.lua`, `nvim/lua/lualine/themes/dms.lua` | unverändert | – | Anbindung an ein fremdes base46 mit `_DMS_SUPPORT`; Name von aussen vorgegeben (Ausnahmeliste «solange die Anbindung besteht», Nr. 60) |
| Shell selbst | `~/.cache/alpe/dms-colors.json`, `dms-typography.json` | `colors.json`, `typography.json` | kein Übergang | liest nur die Shell selbst; alte Dateien räumt F1 weg |
| Sicherungen | `gtk-3.0/gtk-theme.dms-backup`, `icon-theme.dms-backup` | `*.alpe-backup` | **alte bleibt unverändert** (Nr. 57): gelesen wird neu, sonst alt; Symbolthema einmal kopiert | enthält das Thema, das beim Abschalten zurückkommt; alter Name weg mit «Umzug-Ende» |

Gespeicherte Kennungen aus D7 (0.8 Nr. 42): wo sie liegen können und was mit ihnen geschieht.

| Kennung (alt → neu) | Kann gespeichert sein in | Ergebnis |
|---|---|---|
| Starter-Einträge `dms_*` → `alpe_*` | `settings.json` (`builtInPluginSettings`, überall im Baum), `session.json` (`dockPins`, `barPinnedApps`, `hiddenApps`, `appOverrides` …) | v44 / Session v8, ganzer Baum; Tests mit Dateien aus 1.0 |
| dieselben | `~/.cache/…/launcher_cache.json` | keine Migration nötig: Kern-Einträge werden beim Laden gegen die lebenden Einträge geprüft, veraltete fallen weg, der Cache wird neu geschrieben |
| dieselben | `appusage.json` | kommt nicht vor: Starter-Einträge werden nicht gezählt (nur Desktop-Einträge) |
| Seiten-IDs `dankbar…`, `dank_dash` → `bar…`, `dash` | `settings.json` `settingsHiddenPages` | **neu in v44** (Nr. 42) |
| dieselben und die Aliasse `dank_island`, `dankdot` | Argument von `ipc call settings …` in eigenen Kürzeln | nicht in Dateien der Shell; F1 (Nr. 44) |
| Logo-Modus und Punkt-Symbol `"dank"` → `"alpe"` | `settings.json` (`launcherLogoMode`, `islandFreeIconMode` in Leisten-, Dock-, Insel-Widgets) | v44, unter diesen Schlüsseln in jeder Tiefe |
| Material-Vorlage `"dank"`, Form `dankLogo` | `session.json` (`materialWallpapers`, `materialWallpaperProfiles`) | Session v8 |
| matugen-Spec `"dms"` → `"alpe"` | `settings.json` `matugenSpec`; `cache.json` (`matugenAppliedKey`, Vorschauen) | v44; der Cache-Schlüssel passt einmal nicht, matugen läuft dann einmal neu |
| Einstellungsschlüssel `dankLauncherV2*`, `runDmsMatugenTemplates`, `dmsWindowsFloatingSeeded`, Werte `"dms"` | `settings.json` | v43 (D5) |
| Plugin `dankNotepadModule` | `session.json` `builtInPluginState`, `plugin_settings.json` | bleibt als Altdaten liegen (0.8 Nr. 37), wird nicht mehr gelesen |
| IPC-Ziel `dankdash`, Befehle `dms …`, `dank16`, `dms://` | Hyprland-Dateien, KWin-Kürzel (`alpe-cmd-*`, `net.local.*`), `hypridle.conf`, eigene Skripte | F1 (Nr. 44) |
| Bar-Widget-Kennungen (`launcherButton`, `clock` …) | `settings.json` `barConfigs` | in D7 nicht umbenannt (geprüft: kein Widget-ID-Literal mit altem Namen entfernt) |
| Fähigkeit `dankbar-widget`, `requires_dms` | `plugin.json` fremder Plugins | keine Migration: Die Fähigkeit wertet die Shell nicht aus, `requires_dms` wird nicht mehr gelesen (Hinweis entfällt); Anleitung `docs/plugins-anpassen.md` |
| Module und Typen `qs.DCommon.*`, `D*`, `Dank*`, Funktionen `PopoutService.toggleDankLauncherV2` u. ä. | QML fremder Plugins | Hüllen bis D7.8, Anleitung; nicht in Datendateien |
| Kürzel-Quelle `"dms"`, Aktionsart `"dms"`, JSON-Felder `dmsStatus` … | nur zur Laufzeit zwischen Dienst und Oberfläche | nichts gespeichert |
| Layer-Namensräume `dms:…` → `alpe:…` (D7.7a2) | eigene `layerrule`/`layer_rule` in Hyprland-Dateien; KWin kennt keine Layer-Regeln (Fensterregeln in `kwinrulesrc` treffen Fensterklassen, nicht Namensräume) | **F1 deckt ab** (7.4 Schritt 6). PC (nur gelesen): kommt nicht vor |
| `ALPE_DANKBAR_LAYER`, `ALPE_DANKISLAND_LAYER` → `ALPE_BAR_LAYER`, `ALPE_ISLAND_LAYER` (D7.7a2) | `env =` in Hyprland-Dateien, `~/.config/environment.d/*.conf`, Drop-ins von `alpe.service` | **F1 deckt ab** (7.4 Schritt 6, 7.2 Schritt 7). PC: kommt nicht vor |
| systemd-Einheit `app-dms-…` → `app-alpe-…` (D7.7a2) | Overrides unter `~/.config/systemd/user/app-dms-*.d/` | **F1 deckt ab**: Ordner umbenennen (7.2 Schritt 7). PC: keine Overrides |
| IPC-Antworten `DANK_ISLAND_…`/`DANK_DOT_…` → `ISLAND_…`/`DOT_…` (D7.7a2) | eigene Skripte, die die Antwort auswerten | **F1 deckt nicht ab** (Skripte der Nutzer werden nicht umgeschrieben): Hinweis im Protokoll des Umzugs und im CHANGELOG. PC: kommt nicht vor |
| Auswahl-Eintrag `dms-open` → `alpe-open` (D7.7a2) | `mimeapps.list` | **F1 deckt ab** (0.8 Nr. 50). PC: fünf Einträge für Archive |
---

## 1. Zielstruktur des Repos

```
alpe/
├── shell/                 QML (bisher dux-shell/quickshell/), Einstieg shell/shell.qml
│   ├── DCommon/           bisher Submodul dux-qml-common/DCommon – jetzt normaler Ordner
│   ├── Common/ Services/ Modules/ Modals/ Widgets/ Shaders/ matugen/ assets/ scripts/
│   ├── translations/      (Umfang: Frage 4)
│   └── tests/             Node-Tests des Ursprungs (*.test.mjs), soweit sie bleiben
├── core/                  Go-Dienst (bisher dux-shell/core/), Modul github.com/alpe-shell/alpe/core
│   └── cmd/alpe-dienst/   bisher cmd/dms
├── plugins/               alpeMeteoSwiss, alpeRadar, alpeSport (unverändert)
├── lockscreen/            org.alpe.desktop (KDE-Sperre) + hyprlock-Vorlage
├── tools/                 alpe (CLI), design.py, einrichten.sh (bisher install.sh), umzug.py (neu),
│                          kde-sitzung.sh, lockscreen.sh, kuerzel.py, titelleisten.py, …
├── packaging/
│   ├── arch/PKGBUILD
│   ├── fedora/alpe-shell.spec
│   ├── systemd/alpe.service
│   └── desktop/           *.desktop, Icon
├── design/  assets/  docs/  entwicklung/  tests/
├── Makefile               build | install DESTDIR=… PREFIX=… | test | dist
├── get.sh                 Einzeiler-Installation (neu: installiert das Paket)
├── LICENSE                MIT, Alpe (Copyright-Zeile wie bisher)
├── NOTICE                 Herkunft DMS + alle Fremdteile (siehe 3)
├── CHANGELOG.md  README.md
```

Begründung:
- **`shell/` und `core/`** statt `quickshell/`: der Ordner enthält Alpes Oberfläche, nicht
  Quickshell. `core/` bleibt `core/` – in Phase B wird der Go-Dienst durch Rust ersetzt; ein
  sprechender, technikneutraler Name überlebt das.
- `DCommon` behält seinen Namen (Import-Namespace in Hunderten Dateien; «D» trifft keine der
  Suchen nach dms/dux/dank). Ebenso `DBar`, `DDash`, `DIsland`, `DListView` usw.
- **Installierter Baum spiegelt das Repo** unter `/usr/share/alpe/` (`shell/`, `plugins/`,
  `tools/`, `design/`, `lockscreen/`). So findet `tools/alpe` alles über denselben relativen Pfad
  wie im Repo – Entwicklung und Paket nutzen denselben Code ohne Sonderfälle.
- `BASE`, `shell/*.patch`, `rerere/`, `tools/upstream.sh`, der Rebuild in `install.sh`,
  `tools/backend.sh` und `~/dux-shell` entfallen.

Das Go-Binary bettet die Oberfläche **nicht** mehr ein (Bau ohne Tag `withshell`). Der Dienst
startet mit `-c /usr/share/alpe/shell`. Vorteil: Werkzeuge (lockscreen.sh, alpe-kwin.py,
Seitenprüfungen) lesen dieselben Dateien, die laufen; kein Entpacken nach `~/.cache` beim Start;
das Binary wird deutlich kleiner. Entwicklung: `-c ~/alpe/shell` (siehe 6.5).

---

## 2. Namensentscheide

### 2.1 Dienst-Binary vs. CLI «alpe» – Entscheid

**Zwei Programme mit klarer Rolle:**

| Programm | Was | Pfad |
|---|---|---|
| `alpe` | Befehl für Menschen (heute `tools/alpe`, Bash): doctor, update, design, kde, kuerzel, entfernen, umzug, entwicklung, … Unbekannte Befehle gehen an `alpe-dienst` weiter (`alpe ipc call …`, `alpe restart` usw.) | `/usr/bin/alpe` → `/usr/share/alpe/tools/alpe` |
| `alpe-dienst` | Go-Dienst + dessen Unterbefehle (bisher `dms`) | `/usr/bin/alpe-dienst` |

Begründung:
- **Phase A schreibt nichts neu.** Ein einziges Programm hiesse, entweder die Alpe-Befehle in Go
  nachzubauen oder das Bash-Skript als Go-Unterbefehle einzuhängen. Beides ist Neubau, und in
  Phase B fliegt der Go-Teil ohnehin raus. Das heutige Muster (CLI vorne, Dienst dahinter) ist
  erprobt.
- **Zusammenstösse vermeiden:** Beide kennen `doctor`, `version`, `backup`, `restart`, `update`
  mit verschiedener Bedeutung. Getrennte Namen halten das sauber; `alpe` entscheidet, was es
  selbst macht.
- **Leistung:** Die Oberfläche ruft den Dienst an 50+ Stellen direkt auf (`dms cl copy`,
  `dms matugen queue`, `dms ipc …`). Diese Aufrufe gehen künftig direkt an `alpe-dienst`, ohne
  einen Bash-Start dazwischen.
- `alpe-dienst` ist 11 Zeichen – passt in `comm` (15), heisst so in `ps`, `top`, `systemctl`.
- Deutsch statt `alped`/`alpe-core`, weil der Name in Prozessanzeigen sichtbar ist und
  Oberflächentexte deutsch sind. (Wer lieber `alped` will: Frage 1.)

### 2.2 Umbenennungstabelle

| Heute | Neu |
|---|---|
| Paket `dux-shell` / `dms-shell` | Paket **`alpe-shell`** (Arch und Fedora), ohne `conflicts` (siehe 6.2) |
| `/usr/bin/dms` | `/usr/bin/alpe-dienst` |
| `dms.service` | **`alpe.service`** (user unit, im Paket; `MALLOC_ARENA_MAX=2` fest drin; `BusName=org.freedesktop.Notifications` bleibt) |
| Drop-in `kwin.conf` (`QT_QPA_PLATFORMTHEME=kde`) | `alpe.service.d/kde.conf`, geschrieben von `alpe kde ein` (nicht im Paket – unter Hyprland falsch) |
| `~/.config/dms/` | `~/.config/alpe/` (zusammengeführt, siehe 7) |
| `~/.local/state/dms/` (+ Symlink `DankMaterialShell`) | `~/.local/state/alpe/` |
| `~/.cache/dms/` | `~/.cache/alpe/` (nur Zwischenablage-Verlauf und Mitteilungsverlauf ziehen um, Rest baut sich neu) |
| `~/.config/hypr/dms/*.lua` | `~/.config/hypr/alpe/*.lua` (siehe 7.4: heutiges `hypr/alpe.conf` ist eine **Datei** und kollidiert – fällt weg) |
| `/etc/xdg/quickshell/dms-plugins` (System-Plugins) | `/usr/share/alpe/plugins` |
| `$XDG_RUNTIME_DIR/dms-<pid>.sock`, Suche nach `dms`/`danklinux` | `alpe-<pid>.sock` |
| Umgebungsvariablen `DMS_*` (≈40, z. B. `DMS_SHELL_DIR`, `DMS_SOCKET`, `DMS_POLICY_*`) | `ALPE_*` (Achtung bei bestehenden `ALPE_*` der Werkzeuge: Liste wird auf Kollisionen geprüft) |
| Desktop-ID/App-ID `dev.duxlabs.shell` (+ `.notepad`, `dms-open.desktop`) | **`io.github.alpe_shell.Alpe`** (+ `.Notepad`, `.Open`) – Vorschlag, Frage 2 |
| D-Bus `dev.duxlabs.KwinBridge`, `dev.duxlabs.NMAgent`, `com.danklinux.dms` | `io.github.alpe_shell.Alpe.KwinBridge`, `….NMAgent`, `io.github.alpe_shell.Alpe` |
| KWin-Skript `Services/kwin/dms-bridge.js`, Skriptname `dms-bridge`, Befehle `dms-cmd-*` | `alpe-bridge.js`, `alpe-bridge`, `alpe-cmd-*` |
| kglobalaccel-Aktionen `dms-launcher`, `dms-clipboard`, … (Komponente `kwin`) | `alpe-launcher`, `alpe-clipboard`, … – Tasten werden übernommen (7.3) |
| kitty `dank-theme.conf`, `dank-tabs.conf` (matugen-Vorlagen, Design) | `alpe-theme.conf`, `alpe-tabs.conf` (+ `include`-Zeilen in kitty.conf) |
| matugen-Vorlagen `dank*.json`, `dank-zed.json`, `dank-emacs.el`, `dms-theme.vsix` | `alpe*` (VS-Code-Erweiterung: Frage 5) |
| Go-Modul `github.com/duxlabs-dev/dux-shell/core` | `github.com/alpe-shell/alpe/core` |
| QML-Typen/Dateien `DMSService`, `DMSNetworkService`, `DMSShell*.qml`, `DankBar`, `DankDash`, `dankLauncherV2` … | siehe 2.3.2 (D7, Namensregel 2.3.0) |
| Einstellungs-Schlüssel/-Werte mit dank/dms (`dankLauncherV2`, `alpeLockStyle: "dms"`, …) | umbenannt **mit Migration** in `SettingsData` (Versionssprung, alte Datei als `settings.v<N>.json`) |
| Texte «DMS», «Dux Modular Shell», «DankMaterialShell», Willkommens-/Changelog-Dialog | weg bzw. «Alpe»; `Brand.apply()`-Ersetzung entfällt; Über-Seite: «basiert ursprünglich auf der Dux Modular Shell (MIT)» |
| `Brand.heldPackages: ["dux-shell","dms","dms-cli"]` | entfällt (Alpe wird normal über die Paketverwaltung aktualisiert) |
| Prozessname über `~/.local/share/applications/dev.duxlabs.shell.desktop` | entfällt – das Paket liefert die eigene Desktop-Datei |

**Begründete Ausnahmen** (bleiben, werden in der Abnahme-Liste geführt; massgeblich ist seit 0.8 die Ausnahmeliste mit Fristen in 2.3.3):
- Go-Abhängigkeiten `github.com/duxlabs-dev/dux-go` und `dux-gop` (MIT, Avenge Media). Beide sind
  sauber parametrisiert (z. B. `shellapp.ID`), enthalten selbst keine sichtbaren Namen. Sie stehen
  in `go.mod`/`go.sum` und in Importzeilen. Alternative: Frage 9.
- Umzugscode und Tests dazu (`tools/umzug.py`, `tests/test_umzug.py`, Testdaten): müssen die
  alten Namen kennen.
- `NOTICE`, README-Abschnitt «Herkunft», `CHANGELOG.md`, `LICENSE`-Verweis.

### 2.3 D7: Umbenennung der internen Namen (0.8, freigegeben 22.11.2026)

Ziel: Nach D7 trifft eine Suche nach `dms|dank|dux` (Gross/klein) in `shell/`, `core/`, `plugins/`
und `tools/` nur noch die Einträge der Ausnahmeliste (2.3.3). Skriptbasiert, ein Commit pro
Bereich, `bash tools/test.sh` nach jedem Commit, Ladeprüfung auf dem Endstand. Reihenfolge:
direkt nach D6, vor E1 (0.8 Nr. 6).

#### 2.3.0 Namensregel (0.8 Nr. 7)

1. **Interne Typen und Bezeichner ohne Marke**, nach ihrer Rolle: `ShellBackend`, `dash`,
   `palette16`.
2. **Nach aussen sichtbare Kennungen mit `alpe`:** D-Bus-Namen, App-ID, CLI (`alpe`,
   `alpe-dienst`), Plugin-Namensraum (`requires_alpe`, Starter-Plugins `alpe_*`), gespeicherte
   Kennungen, die Nutzer oder Fremdprogramme sehen (Regel-IDs, Vorlagen- und Themennamen).
3. **Ausnahme Widget-Bibliothek: Präfix `Alpe`** (`AlpeButton`, `AlpeTextField`, `AlpeIcon` …),
   weil neutrale Namen mit QtQuick.Controls kollidieren (geprüft: `Button`, `TextField`,
   `Slider`, `Switch`, `ListView`, `Popup`, `Dialog`, `ToolTip`, `Icon` gibt es dort) und weil
   das die Plugin-API ist.
4. **Kollisionsprüfung** für jeden neuen Namen gegen bestehende Alpe-Typen und -Bezeichner
   (Dateinamen und `git grep -w`), Qt-Typen (1208 aus `/usr/lib/qt6/qml/**/*.qmltypes`) und
   Quickshell-Typen (139). Das Skript (D7.0) wiederholt die Prüfung vor jedem Lauf.

**Lesart von Nr. 3: Variante B** (0.8 Nr. 20). Die 77 `D*`-Typen aus DCommon (`DButton`,
`DIcon` …, ≈1330 Verwendungen in der Shell) heissen `Alpe*`. Abgeleitet aus Regel 1 und 3 für die
übrigen 36 `D*`-Typen ausserhalb von DCommon: Was in einem Modul liegt, das Plugins importieren,
und ein Baustein ist (`qs.Widgets`: `DPopout`, `DTooltip`, `DContextMenu`, `DSeekbar` …;
`qs.Modals.Common`: `DModal`, `DModalHost`), gehört zur Bibliothek und heisst `Alpe*`; rein
interne Typen verlieren das «D» (`DBarWindow` → `BarWindow`, `DDashPopout` → `DashPopout`,
`DIslandSurface` → `IslandSurface`, Einstellungsseiten `DBarTab` → `BarTab` …). `DSearchService` heisst nach seiner Funktion `FileSearchService` (0.8 Nr. 26). Die genaue
Liste erzeugt D7.0 (Zuordnungstabelle im Repo) mit Kollisionsprüfung.

**Module (0.8 Nr. 21).** Quickshell lädt Shell-Module nur über `qs.<Pfad>` (der Baum hat keine
eigenen `qmldir`; Verzeichnis = Modul). Der Namensraum Alpe ist darum `qs.Alpe.*` (Ordner
`shell/Alpe/`); eine URI ohne `qs.` (`Alpe.Common`) bräuchte einen eigenen QML-Importpfad samt
`qmldir` neben dem Mechanismus von Quickshell und ist nicht vorgesehen. Gemessen, was Plugins
importieren (Alpe-Plugins und die vier fremden): `qs.Common` 76, `qs.DCommon.Widgets` 52,
`qs.Services` 18, `qs.Modules.Plugins` 17, `qs.Widgets` 14, `qs.Modules.DDash` 6 (alpeSport,
alpeRadar), `qs.Modals.Common` 3. Zuordnung in 2.3.2.

**Übergang für fremde Plugins bis D7.8:** sathiAi benutzt `qs.DCommon.Widgets` und `D*`-Typen
direkt (`DActionButton`, `DTextField`, `DDropdown`, `DButton`, `DToggle`, `DSpinner`), hueManager,
claudeCodeUsage und calculator die `Dank*`-Hüllen aus `qs.Widgets`. Damit lokale Kopien bis zur
Bestätigung weiterladen, bleiben bis D7.8 vorübergehend: die `Dank*`-Hüllen (auf `Alpe*`
umgestellt) und ein Ordner `shell/DCommon/Widgets/` mit erzeugten `D*`-Hüllen auf `Alpe*`. Beides
ist markiert und fällt in D7.8 vollständig weg.

#### 2.3.1 Umfang (gemessen, Stand `fab0760`)

| Was | Menge |
|---|---|
| Dateien mit dms/dank im Namen (`shell/`, `core/`) | 105, davon **91 reine Weiterleitungen** (40 `Widgets/Dank*`, 33 `Modules/DankBar/Widgets/*`, 14 `Modules/DankDash/*`, 3 `Common/Dank*`, `Modals/Common/DankModal`) – die Shell selbst benutzt keine davon |
| echte Dateien | `DMSShell.qml`, `DMSShellIPC.qml`, `Services/DMSService.qml`, `Services/DMSNetworkService.qml`, `Services/CalendarDankBackend.qml`, `core/internal/dank16/`, `core/internal/config/dms.go`, matugen `dank.json`, `dank-zed.json`, `dank-emacs.el` |
| Bezeichner Oberfläche (QML/JS, mit DCommon) | 311 verschiedene, ≈2000 Vorkommen (`DMSService` 472, `dmsBin` 73, `DMSNetworkService` 65, `DankBar` 35, `dankDashPopout` 32, `dankLauncherV2Modal` 31 …) |
| Bezeichner Dienst (Go) | 161 verschiedene, ≈1170 Vorkommen (`dmsDir`, `dmsPath`, `DMSStatus`, `dank16` …) |
| Gespeicherte Kennungen | Seiten-IDs `dankbar*`, `dank_dash`, Starter-Plugins `dms_*`, Logo-Modus und Material-Vorlage `"dank"`, matugen-Spec `"dms"`, Kürzel-Quelle `"dms"`/`"dms-default"`, Regel-IDs `dms-floating-windows`/`dms-window-opaque`, Marke `-- DMS-RULE:` |
| Dateien bei Fremdprogrammen | Cache `dms-colors.json`, `dms-typography.json`; kitty `dank-theme.conf`/`dank-tabs.conf`; fcitx5-Thema `dms`; Lualine-Thema `dms` |
| IPC | Ziel `dankdash` (Doppel zu `dash`) |
| Plugin-Beschreibung | `requires_dms`, Fähigkeit `dankbar-widget` (alpeSport); `requires: ["dms"]` (calculator, nur Information, wird nicht ausgewertet) |

#### 2.3.2 Zuordnung (freigegeben; nach Regel 2.3.0 geprüft)

Spalte «R» = Regel aus 2.3.0. Kollisionen: geprüft wie in 2.3.0 Nr. 4; gefundene stehen in der
letzten Spalte mit der Ausweichlösung.

| Heute | Neu | R | Kollision |
|---|---|---|---|
| `DMSService` | `ShellBackend` | 1 | keine |
| `DMSNetworkService` | `BackendNetworkService` | 1 | keine |
| `DMSShell.qml`, `DMSShellIPC.qml` | `ShellMain.qml`, `ShellIpc.qml` | 1 | `ShellRoot` (erste Wahl) ist ein Quickshell-Typ → `ShellMain`; `AlpeShell*` aus der ersten Fassung widerspricht Regel 1 |
| `CalendarDankBackend.qml` | `CalendarDuxBackend.qml` | – | keine; «Dux» ist hier der Name der fremden App (Ausnahmeliste) |
| `Proc.dmsBin`, `checkDMSCapabilities` | `backendBin`, `checkBackendCapabilities` | 1 | keine |
| `dmsAvailable` | `backendReachable` | 1 | `backendAvailable` gibt es schon (`ThemeAutoService`, andere Bedeutung) |
| `isDmsAction`, `dmsActions`, `DMS_ACTION_ARGS`, Aktionsart `"dms"` | `isShellAction`, `shellActions`, `SHELL_ACTION_ARGS`, `"shell-action"` | 1 | `"shell"` ist schon die Aktionsart von `spawn_shell` → `"shell-action"` (0.8 Nr. 36) |
| `DankBar…`, `dankBar…` (Rest-Bezeichner) | `Bar…`, `bar…` | 1 | keine (`Bar` ist weder Qt- noch Quickshell-Typ) |
| `DankDash…`, `dankDashPopout(Loader)` | `Dash…`, `dashPopout(Loader)` | 1 | keine |
| `DankIsland…`, `dankIsland…`, `DankDot` | `Island…`, `island…`, `Dot` | 1 | keine |
| `dankLauncherV2Modal(Loader)` u. ä. | `launcherModal(Loader)` | 1 | keine |
| `hyprDmsDir`, `dmsParsedArgs` | `hyprAppDir`, `shellParsedArgs` | 1 | keine |
| `dmsStatus` (QML, JSON zwischen Dienst und Oberfläche) | `fragmentStatus` | 1 | `includeStatus` gibt es schon (`DisplayConfigState`) |
| Go: `dmsDir`, `dmsState`, `DMSStatus`, `LoadDMSRules` … | `appDir`, `appState`, `FragmentStatus`, `LoadShellRules` … | 1 | keine |
| Go: `dmsPath` (Pfad der Oberfläche) | `shellConfigPath` | 1 | `shellPath` gibt es schon (doctor, Schriftprüfung) |
| Go-Paket `internal/dank16`, Befehl `alpe-dienst dank16` | `internal/palette16`, Befehl `palette16` | 1 | keine; kein Aufrufer ausserhalb des Dienstes |
| Importname `danklog` (dux-go bleibt) | `duxlog` | – | keine; «dux» = Name des fremden Moduls (Ausnahmeliste) |
| Widget-Typen `D*` (77 in DCommon, Bibliotheks-Typen in `qs.Widgets` und `qs.Modals.Common`) | `Alpe*` (`AlpeButton`, `AlpeIcon`, `AlpeTextField` …); die 44 `Dank*`-Hüllen entfallen (D7.8) | 3 | keine mit Qt/Quickshell; keine mit bestehenden `Alpe*`-Dateien (`AlpeKwinTab` … sind Seiten). Vollständige Liste in der Zuordnungstabelle (D7.0) |
| übrige `D*`-Typen (intern) | ohne «D» (`BarWindow`, `DashPopout`, `IslandSurface`, `BarTab` …) | 1 | Prüfung je Name in D7.0 |
| Modul `qs.DCommon.*` (Ordner `DCommon/`: Common, Widgets, Session, FileBrowser, Shaders, assets, translations) | `qs.Alpe.*` (Ordner `Alpe/`); **Widget-Bibliothek für Plugins: `import qs.Alpe.Widgets`** (`shell/Alpe/Widgets/`), dazu `qs.Alpe.Common`, `qs.Alpe.Session`, `qs.Alpe.FileBrowser` | API | Plugins importieren `qs.DCommon.Widgets`; keine Kollision (`Modules/Lock/Alpe` ist `qs.Modules.Lock.Alpe`) |
| Modul `qs.Modules.DDash` (+ Overview, Media, Weather, Wellbeing, utils) | `qs.Alpe.Dash` (Ordner `Alpe/Dash/`) | API | alpeSport, alpeRadar importieren es; keine |
| Modul `qs.Modules.DBar` (+ Widgets, Popouts) | `qs.Modules.Bar` | 1 | intern; keine (weder Ordner noch Qt-/Quickshell-Typ `Bar`) |
| Modul `qs.Modules.DIsland` (+ Activities) | `qs.Modules.Island` | 1 | intern; keine |
| Modul `qs.Modals.DLauncherV2` | `qs.Modals.Launcher` | 1 | intern; keine |
| Harness-Module `entwicklung/*/qs/DCommon/**/qmldir` | `…/qs/Alpe/**/qmldir` | – | im Verschiebe-Commit mit |
| Seiten-IDs `dankbar`, `dankbar_appearance`, `dankbar_dot`, `dankbar_settings`, `dankbar_widgets`, `dank_dash` | `bar`, `bar_appearance`, `bar_dot`, `bar_settings`, `bar_widgets`, `dash` | 1 | im Skript gegen bestehende Seiten-IDs prüfen |
| Starter-Plugins `dms_settings` … `dms_vpn` | `alpe_settings` … `alpe_vpn` | 2 | keine |
| Logo-Modus `"dank"`, Material-Vorlage `"dank"` (Ebene `dankLogo`) | `"alpe"`, Vorlage «Alpe», Form = Alpe-Zeichen (0.8 Nr. 13) | 2 | keine |
| matugen-Spec `"dms"` (`SpecDMS`) | `"alpe"` | 2 | keine |
| Kürzel-Quelle `"dms"`, `"dms-default"` | `"shell"`, `"shell-default"` | 1 | intern zwischen Dienst und Oberfläche; keine |
| Regel-IDs `dms-floating-windows`, `dms-window-opaque`; Marke `-- DMS-RULE:` | `alpe-floating-windows`, `alpe-window-opaque`; `-- ALPE-RULE:` (alte Marke wird gelesen, beim nächsten Schreiben ersetzt) | 2 | keine |
| Cache `dms-colors.json`, `dms-typography.json` | `colors.json`, `typography.json` | 1 | keine im Ordner `~/.cache/alpe` |
| matugen-Vorlagen `dank.json`, `dank-zed.json`, `dank-emacs.el`, kitty `dank-*.conf`, fcitx5-/Lualine-Thema `dms` | `alpe*` | 2 | keine; Einbindung in den Fremdprogrammen schreibt F1 um |
| IPC-Ziel `dankdash` | entfällt (`dash` bleibt) | – | – |
| Hotspot-Verbindung «DankMaterialShell Hotspot» | «Alpe Hotspot»; die alte wird erkannt und weiter benutzt, neu angelegt wird nur der Alpe-Name (0.8 Nr. 16) | 2 | keine |
| `plugin.json`: `requires_dms`, Fähigkeit `dankbar-widget` | `requires_alpe`, `bar-widget` | 2 | keine |
| Plugin `dankNotepadModule` (Store-Plugin des Ursprungs, Sonderweg im Notizblock) | Anbindung entfällt | – | – |
| «Wallpaper creator», Annahme von `dms://` | entfällt (0.8 Nr. 14) | – | – |
| 91 Weiterleitungen, `Common/Deprecation.qml` | entfallen (D7.8) | – | – |

Gespeicherte Kennungen ziehen mit **Migration v44** um (wie v43, `settings.v43.json` bleibt
liegen; Session-Daten wie `builtInPluginState` im selben Zug).

#### 2.3.3 Ausnahmeliste (0.8 Nr. 18: nur von aussen vorgegebene Namen, je mit Frist)

| Eintrag | Warum von aussen vorgegeben | Erledigt bis |
|---|---|---|
| Go-Module `github.com/duxlabs-dev/dux-go`, `dux-gop` (Importpfade, `go.mod`/`go.sum`), Importname `duxlog` | fremde Bibliotheken (0.4 Nr. 9) | Abschluss von Phase B (Go-Dienst durch Rust ersetzt) |
| Herkunft: NOTICE, LICENSE-Vermerk, `LICENSE_CHANGE_12_11_2025.md`, README «Herkunft», `CHANGELOG.md`, `Brand.upstream*`, Herkunftszeile der Über-Seite | Rechtspflicht bzw. historische Angabe | dauerhaft |
| Lesen alter Namen bei der Migration: `SettingsStore` v43/v44, `SESSION_BACKED_PLUGIN_IDS` (Altdaten von `dankNotepadModule`, 0.8 Nr. 37), Kopfzeile «DMS Include Configs», Marke `-- DMS-RULE:`, Hotspot-Name, Erkennung von `dms`-Befehlen in eigenen Kürzeln (`KeybindsContent.qml`, 0.8 Nr. 38), Sicherungen `gtk-theme.dms-backup`/`icon-theme.dms-backup` und Marken `.dms-copy` (nie umbenannt, 0.8 Nr. 57), alte Ausgabenamen für Fremdprogramme (Links und zweite Fassungen, 0.8 Nr. 59), Umzugscode `tools/umzug.py` und seine Tests/Testdaten | Daten aus 1.0 auf den Rechnern der Nutzer | sobald der Umzug von 1.0 nicht mehr unterstützt wird, frühestens mit dem ersten Release nach Abschluss von Phase B (0.8 Nr. 23) |
| Fremde App «Dux Calendar»: `dev.duxlabs.calendar`, Socket `dankcal`, `CalendarDuxBackend.qml` | Namen der fremden App | solange die Anbindung besteht |
| Fremdes Programm `dsearch` («dux-search», `github.com/duxlabs-dev/dux-search`): Programmname, Bezugsquelle im Starter-Hinweis, doctor-Eintrag | Name und Quelle des fremden Programms (0.8 Nr. 26) | solange die Anbindung besteht; in E3 optionale Abhängigkeit (`optdepends` im PKGBUILD, `Recommends:` in der RPM-Spec), keine harte |
| PAM-Dienste `dankshell`, `dankshell-u2f`, Blockmarken «DMS LOCKSCREEN AUTH»; Richtlinien `/usr/share/dms`, `/etc/dms`; alle anderen paketierten Pfade | heute vom Paket `dux-shell`/`dms` belegt | **E1** (zwingend, 0.8 Nr. 16; alte Blöcke erkennen) |
| CUPS `requesting-user-name` `dms` | Besitzerkennung von Abonnements in cupsd (Befund in `offene-faelle.md`) | D7.7: Benutzername zur Laufzeit (`os/user`, Rückfall `alpe`); `dms` nur noch beim einmaligen Kündigen alter Abonnements (siehe unten), Frist wie Migration |
| Dateien fremder Plugins im Original, Herkunftsvermerke im README von `~/alpe-plugins` | Lizenz/Herkunft | dauerhaft |
| `Brand.heldPackages` (`dux-shell`, `dms`, `dms-cli`) | Paketnamen des Ursprungs | **E4** (0.8 Nr. 17) |
| Neovim: `nvim/colors/dms.lua`, Lualine-Thema `dms`, `_DMS_SUPPORT` | Anbindung an ein fremdes base46, das diese Namen erwartet (0.8 Nr. 60) | solange die Anbindung besteht |

**Alte CUPS-Abonnements (0.8 Nr. 22), gewählt: einmal kündigen.** Der Dienst legte Abonnements
mit Laufzeit 0 (Abfrageweg; bei cupsd bedeutet 0 «ohne Ende», sofern `MaxLeaseDuration` es
zulässt – `cupsd.conf` ist nur für root lesbar und liess sich nicht prüfen) bzw. 86400 s (D-Bus)
an. Auf ein Auslaufen ist also kein Verlass. Beim ersten Start fragt der Dienst darum einmal
`Get-Subscriptions` ab und kündigt nur Abonnements mit Besitzer `dms`, deren Ereignisliste und
Zustellweg (`ippget` bzw. `dbus://`) denen des Dienstes entsprechen; danach eine Marke in
`~/.local/state/alpe/` (0.8 Nr. 30; nicht unter `~/.config`). Befund am PC (22.11.2026, lesend über IPP): kein Abonnement mit Besitzer
`dms`, eines von `fabian` (`dbus://`, Auftragsereignisse, 3600 s – nicht vom Dienst). Test mit
einer IPP-Attrappe.

Alles andere ist nach D7 ein Fehler der Namensprüfung. `tools/namen-pruefen.sh` (aus G1
vorgezogen) meldet ab D7.0 und schlägt ab D7.8 in `tools/test.sh` fehl.

#### 2.3.4 Plugins

**`requires_alpe` (0.8 Nr. 12), Entscheid:** `PluginService` prüft das Feld gegen
`Brand.version` (Alpe, z. B. 1.1) mit derselben Ausdruckssyntax wie heute (`>=1.1`, `<2` …).
Ergebnis ist **ein Hinweis, keine Ladesperre** – wie heute bei `requires_dms`: Markierung in der
Plugin-Liste und Hinweis auf der Plugin-Seite («Braucht Alpe 1.2»). Begründung: Eine Sperre
schützt vor nichts, was der Hinweis nicht auch zeigt, nähme aber Plugins weg, deren Angabe zu
streng ist. `requires_dms` wird nicht mehr gelesen; der Test in `plugin-reload.test.mjs` prüft
gegen `Brand.version`.

Alpe-Plugins (alpeSport, alpeMeteoSwiss, alpeRadar): keine `Dank*`-Typen; `requires_alpe`
dazu, alpeSport `dankbar-widget` → `bar-widget`.

| Plugin | Lizenz (Repo geprüft 22.11.2026) | Benutzt vom Ursprung | Weg (0.8) |
|---|---|---|---|
| claudeCodeUsage (Nicolas Bellamy) | MIT, LICENSE mit Copyright | `DankTextField`, `DankIcon`, `DankButton` | **ins Alpe-Repo** `plugins/claudeCodeUsage/` mit LICENSE, Copyright in NOTICE; angepasst in D7.3 |
| calculator (rochacbruno/DankCalculator) | AGPL-3.0 (Standardtext; Autor laut README Bruno Cesar Rocha) | `["dms","cl","copy"]`, `requires_dms` | **eigenes Repo `~/alpe-plugins`** (lokal `git init`, Branch `main`), Ordner `calculator/`, LICENSE unverändert, Copyright-Hinweis, Änderungen im Kopf der Dateien und in `CHANGES.md` gekennzeichnet, README mit Herkunft und Lizenz. GitHub `alpe-shell/alpe-plugins` und Push: Maintainer. Installation: E3/E4, bis dahin Klon |
| hueManager (derethil/dms-hue-manager) | keine Lizenz | `DankIcon` (7), `DankSlider`, `DankListView`, `DankToggle`, `DankDropdown`, `DankButton` | **Anleitung** `docs/plugins-anpassen.md` |
| sathiAi (Shinda Singh) | README sagt MIT, LICENSE fehlt, Repo unbekannt | `dms notify`, `dms ipc call settings …` | **Anleitung** wie hueManager |

Anpassung (Repo, `~/alpe-plugins` oder Anleitung): `import qs.Widgets` bzw. `qs.DCommon.Widgets`
→ Modul der Widget-Bibliothek, `DankX` → `AlpeX`, `dms …` → `alpe-dienst …`,
`requires_dms` → `requires_alpe`, Ablage `~/.config/alpe/plugins`. Plugins im Repo behalten ihre
ID (`plugin_settings.json` passt weiter), der Umzug kopiert ihre Nutzerkopien nicht. Die
Anleitungen und die calculator-Anpassung sind fertig, bevor D7.8 beginnt; **D7.8 erst nach
Bestätigung des Maintainers**, dass PC und Mac umgestellt sind.

#### 2.3.5 Commits D7

| # | Bereich |
|---|---|
| D7.G | `tools/test.sh`: rot bei neuen Dateien über 1 MB oder ELF-Binärdateien gegenüber `origin/phase-a` (0.8 Nr. 24) |
| D7.N | Node-Tests der Oberfläche in `tools/test.sh` mit fester Liste der 10 bekannten Fehlschläge (neuer Fehlschlag = rot) – vor D7.0 (0.8 Nr. 19) |
| D7.0 | Werkzeug `entwicklung/umbenennen/` (Skript, Zuordnungstabelle, Probelauf, Kollisionsprüfung nach 2.3.0); `tools/namen-pruefen.sh` mit Ausnahmeliste 2.3.3, nur meldend |
| D7.1 | Plugin-Beschreibung: `requires_alpe` gegen `Brand.version`, `bar-widget`; Alpe-Plugins; Tests |
| D7.2a | Module verschieben, **nur `git mv`, ohne Inhaltsänderung** (0.8 Nr. 21): `DCommon/` → `Alpe/`, `Modules/DDash/` → `Alpe/Dash/`, `Modules/DBar/` → `Modules/Bar/`, `Modules/DIsland/` → `Modules/Island/`, `Modals/DLauncherV2/` → `Modals/Launcher/`, Harness-`qmldir`-Ordner. Damit dieser Commit grün bleibt, zeigen Symlinks unter den alten Pfaden auf die neuen (neue Dateien, keine Inhaltsänderung); `git log --follow` behält die Geschichte |
| D7.2b | Importe auf die neuen Module, **alle** Importe und Symlinks im selben Commit (0.8 Nr. 27); danach Ladeprüfung KWin gegen die Grundlinie, neue Meldungen vor D7.3 beheben (0.8 Nr. 28); `D*` → `Alpe*` bzw. ohne «D» (Dateien per `git mv`, dann Bezüge); Übergangs-Hüllen `shell/DCommon/Widgets/D*.qml` und umgestellte `Dank*`-Hüllen bis D7.8 |
| D7.3 | Plugins: claudeCodeUsage ins Repo und angepasst, NOTICE; `~/alpe-plugins` mit calculator; `docs/plugins-anpassen.md` für hueManager und sathiAi |
| D7.4 | Schnittstelle Dienst ↔ Oberfläche: `ShellBackend`, `BackendNetworkService`, `backendBin`, JSON-Felder (`fragmentStatus`, Kürzel-Quelle) samt Go-Gegenstücken |
| D7.5 | Oberfläche: `ShellMain.qml`/`ShellIpc.qml`, Bezeichner Bar/Dash/Island/Launcher, Kürzel-Aktionen; `DLogoShape.js` umbenennen (0.8 Nr. 35); `dankNotepadModule`-Anbindung, «Wallpaper creator», `dms://` und Doku-Links nach `duxlabs.dev` weg |
| D7.6 | Gespeicherte Kennungen, Migration v44 (Seiten-IDs, Starter-Plugins, Logo-Modus, Material-Vorlage «Alpe» mit Alpe-Zeichen samt Logoform aus D7.5 statt der des Ursprungs, gemeinsam geprüft (0.8 Nr. 35), matugen-Spec), IPC-Ziel `dankdash` weg; Test mit Einstellungen aus 1.0 und v43 |
| D7.7a | Restliche `"dms"`-Werte (0.8 Nr. 38) und übrige Bezeichner der Oberfläche: Kürzel-Kategorie und -Erkennung (`alpe`, übergangsweise auch `dms`), `case "dms"` in `ProcessActions.qml`, `getDMSShellVersion` in doctor, verbliebene `dms…`/`dank…`-Bezeichner in `shell/` |
| D7.7a2 | Übrige Bezeichner der Oberfläche (`shell…`/`backend…` statt `dms…`, Kalender `dux…`), sichtbare Kennungen: Layer-Namensräume `alpe:…` (auch `alpe:island`), systemd-Einheit `app-alpe-…`, IPC-Antworten `ISLAND_…`/`DOT_…`, `ALPE_BAR_LAYER`/`ALPE_ISLAND_LAYER`, Auswahl-Eintrag `alpe-open` |
| D7.7b | Erzeugte Dateien und Vorlagen: Cache `colors.json`/`typography.json`, matugen-Vorlagen und -Ausgaben (`alpe*.json`, kitty, GTK, fcitx5, Lualine), Vorlagen-Variablen `dank16.*` → `palette16.*`, Regel-IDs `alpe-*`, Marke `-- ALPE-RULE:` (alte wird gelesen) – Oberfläche und Dienst gemeinsam, weil beide Seiten dieselben Dateinamen kennen |
| D7.7b3 | Regel-IDs `alpe-floating-windows`, `alpe-window-opaque`, Marke `-- ALPE-RULE:` (alte Marke und IDs werden gelesen, beim nächsten Schreiben ersetzt) |
| D7.7b4 | `packaging/alpe-open.desktop` (Installation E3, `mimeapps.list` F1) |
| D7.7c | Hotspot («Alpe Hotspot», alte Verbindung wird erkannt und weiter benutzt) und CUPS (Benutzername zur Laufzeit, einmaliges Kündigen alter Abonnements des Besitzers `dms`, Marke unter `~/.local/state/alpe/`) mit IPP-Attrappe als Test |
| D7.7d | Dienst intern: Paket `internal/dank16` → `internal/palette16`, Befehl `alpe-dienst palette16` |
| D7.7e | Dienst intern: `internal/config`, `configfrag`, `luaconfig`, `keybinds`, `windowrules` (`dmsDir` → `appDir`, `dmsPath` → `shellConfigPath`, `LoadDMSRules` → `LoadShellRules` …), Marken `-- DMS_STARTUP_BEGIN`/`…_END` (alte werden gelesen), Sicherungsordner `.alpe-backups` (der alte bleibt unberührt, 0.8 Nr. 57) |
| D7.7f | Dienst intern: `internal/matugen` (Rest nach D7.7b) |
| D7.7g | Dienst intern: `cmd/alpe-dienst`, `internal/version`, `internal/log` und die Pakete unter `internal/server` |
| D7.7h | Dienst intern: übrige Pakete, `core/README.md`, `Makefile`, `.mockery.yml`; Attrappen in `internal/mocks` mit dem aktuellen mockery neu erzeugt bzw. Konfiguration angepasst, bis `go vet ./...` ohne Meldung läuft (0.8 Nr. 62); Prüfung, dass weder Paketverzeichnisse noch `go.mod` alte Namen tragen (ausser Ausnahmeliste: `dux-go`, `dux-gop`) |
| D7.7i | Werkzeuge `tools/backend.sh`, `entfernen.sh`, `alpe`, `maclock.sh` (0.8 Nr. 52) – vor dem Zwischenhalt |
| D7.8 | **Nach Bestätigung:** `Dank*`-Hüllen, Übergangs-Hüllen `DCommon/Widgets`, `Modules/DankBar`, `Modules/DankDash` und `Deprecation.qml` weg; Namensprüfung schlägt ab jetzt fehl |

Dazu im Lauf von D7 (Doku, kein Code): `docs/plan/sie-form.md` (0.8 Nr. 15).

Zwischenhalt nach D7.7 (dazu 0.8 Nr. 45: Logo-Modus `"alpe"` mit einem Widget, Materialform
`alpeLogo` als Hintergrund, Session aus 1.0 im Temp-HOME): `~/alpe-plugins` mit calculator lokal fertig, Anleitungen für
hueManager und sathiAi (PC und Mac, fish-tauglich) in `offene-faelle.md`; Ladeprobe aller vier
fremden Plugins im Temp-HOME auf D7.7 und mit nicht committetem D7.8-Probelauf (0.8 Nr. 29);
D7.8 erst nach Bestätigung. Nach jedem Commit wird «Stand» nachgeführt.

Prüfung: je Commit `bash tools/test.sh`; Go-Tests wie bekannt; Ladeprüfung einmal auf dem
Endstand unter KWin und Hyprland (Meldungen mit umbenannten Namen werden in den Grundlinien
nachgeführt, jede andere Abweichung einzeln erklärt); dazu bei jedem Halt qmllint
(`/usr/lib/qt6/bin/qmllint`) über `shell/` gegen die Grundlinie von 5600 Meldungen, neue Meldungen
einzeln eingeordnet (0.8 Nr. 63), und `go vet ./...` ohne Meldung (0.8 Nr. 62).
**Halt nach D7**, Mac-Test, dann 6.7, E1.

Folgen für F1 (Umzug), zusätzlich zu 7.2: kitty-`include`-Zeilen, fcitx5- und Lualine-
Themenwahl, **alle alten IPC-Ziele und Befehle in den Hyprland-Dateien und KWin-Kürzeln aller
Nutzer** (0.8 Nr. 44; Liste in 7.2 Schritt 6 und 7.4 Schritt 6), Regel-IDs und `-- DMS-RULE:` in eigenen
Hyprland-Dateien; Nutzerkopien der Repo-Plugins nicht kopieren; Hotspot-Verbindung bleibt.
Dazu aus D7.7a2: eigene Hyprland-Regeln mit Layer-Namensraum `dms:…` (`layerrule`, `layer_rule`)
→ `alpe:…` (`dms:dankisland` → `alpe:island`); `mimeapps.list` mit `dms-open.desktop` → `alpe-open.desktop`.
Dazu aus 0.8 Nr. 57–59: Sicherungsordner bleiben beim Umschreiben unberührt; der Rückweg setzt
Marke und IDs der Fensterregeln gezielt zurück; Einbindungen der Ausgabedateien je Programm nach 7.6.
Folgen für E3: `alpe-shell` liefert `alpe-open.desktop` selbst aus (`packaging/alpe-open.desktop`
→ `/usr/share/applications/`; Auswahl «jedes Mal fragen» der Standardprogramme, ruft
`alpe-dienst open`); bisher lieferte das Paket des Ursprungs `dms-open.desktop` (0.8 Nr. 50, 59).
Folgen für E1: PAM-Dienste, Richtlinien und alle paketierten Pfade mit `alpe`-Namen (2.3.3).

---

## 3. Lizenzprüfung

Ergebnis: **Alles weiterverteilbar.** Pflichten: Copyright- und Lizenzhinweise beilegen,
CC-BY-SA-Klänge kennzeichnen, Apache-2.0-Teile mit Lizenztext. Alles kommt in `NOTICE`
(Repo-Wurzel) und wird vom Paket nach `/usr/share/licenses/alpe-shell/` installiert.

| Teil | Ort (heute) | Lizenz | Copyright / Herkunft |
|---|---|---|---|
| Dux Modular Shell 2.1.2 (QML + Go) | gesamter Baum | MIT | © 2025 Avenge Media LLC; Relizenzierung GPL-3.0 → MIT am 11.12.2025 mit Zustimmung aller 21 Mitwirkenden (`LICENSE_CHANGE_12_11_2025.md`, PR #686) – die Datei bleibt als Beleg erhalten |
| dux-qml-common (DCommon) | Submodul | MIT | © 2025–2026 Avenge Media LLC |
| KWin-Unterstützung «Patch v4» | `shell/0000-…patch` | **offen** – im Patch steht nur noch alpemessi als Autor; laut KONTEXT auf Basis eines fremden Patches → Frage 16 |
| Google Sans Flex, DM Serif Display, Gochi Hand, Notable | `DCommon/assets/fonts/*` | SIL OFL 1.1 | OFL.txt liegt jeweils bei |
| FiraCode Nerd Font | `DCommon/assets/fonts/nerd-fonts` | SIL OFL 1.1 | The Fira Code Project Authors |
| Material Symbols Rounded | `DCommon/assets/fonts/material-design-icons` | Apache 2.0 | Google |
| Alfa Slab One, JetBrains Mono | `Modules/Lock/Alpe/fonts`, `lockscreen/…/fonts` | SIL OFL 1.1 | OFL-Dateien liegen bei |
| Klänge «freedesktop» | `assets/sounds/freedesktop` | CC-BY-SA / CC-BY 3.0 / GPLv2+ je Datei | `CREDITS` – bleibt unverändert dabei |
| Klänge «Harmony 2» (Plasma) | `assets/sounds/plasma` | CC-BY-SA 4.0 | LICENSE + README bleiben |
| suncalc.js | `Common/suncalc.js` | BSD-2-Clause | © Vladimir Agafonkin |
| chroma-Lexer (Syntaxhervorhebung) | `core/internal/highlight` | MIT | © 2017 Alec Thomas (`COPYING`) |
| IPP-Bibliothek | `core/pkg/ipp` | Apache 2.0 | LICENSE liegt bei |
| Wayland-Protokollbindungen | `core/internal/proto/*` | MIT-artig (Protokoll-Copyright im Kopf) | Chromium Authors, Simon Ser, Purism, Intel, Collabora … – Köpfe bleiben |
| matugen-VS-Code-Theme | `matugen/vsix-build` | MIT | © 2025 DankLinux |
| Quell-Farbwahl «ported from caelestia-cli» | `core/internal/matugen/sourcecolor.go` | **zu prüfen** – nur Gewichtungs-Konstanten (stammen ursprünglich aus Material Color Utilities, Apache 2.0). Kein übernommener Code erkennbar → Hinweis in NOTICE, Frage 15 |
| Go-Abhängigkeiten (≈90 Module) | `go.mod` | MIT/BSD/Apache/ISC u. a. | Liste wird beim Umsetzen mit `go-licenses report` erzeugt und in `NOTICE` bzw. `packaging/LICENSES-go.txt` abgelegt; GPL-Module würden auffallen (bisher keines erkannt) |
| Logos Dritter | `assets/` (niri, sway, mango, labwc, miracle, umbriel, hyprland, discord, reddit, matrix, flatpak, snap, nix, appimage) | Marken | fallen bis auf `hyprland.svg` und die Paketquellen-Symbole weg (Kandidaten-Liste 4) |
| DMS-Logos | `danklogo*.svg`, `dank.svg`, `dev.duxlabs.shell.svg`, `core/assets/*` | MIT, aber fremde Marke | **werden entfernt**, Ersatz: Alpe-Logo aus `assets/logo` |
| Alpe-Design-Bilder | `design/kde/bilder/` (wallpaper.jpg, wall.png, jagged-peaks-wolkenzug.mp4) | laut Export als eigene bestätigt | Frage 14 (kurze Bestätigung, weil «keine fremden Bilder» Projektregel ist) |
| MeteoSchweiz-Daten | Laufzeit | Open Government Data, Quellenangabe | wie bisher |

Was ich nicht prüfen kann: ob jeder MIT-Teil des Ursprungs wirklich frei von früherem GPL-Code
ist. Die Relizenzierungsurkunde deckt das ab; wir übernehmen sie als Beleg.

---

## 4. Zu entfernende Teile (Kandidaten)

Legende: **sicher** = gehört zu nicht unterstützten Compositors oder ist Ursprungs-Infrastruktur;
**Grenzfall** = der Maintainer entscheidet (Frage 5).

### 4.1 Ursprungs-Infrastruktur (sicher)

`distro/` (Debian/Ubuntu/openSUSE/Void/FreeBSD/Nix/OBS/PPA), `flake.nix`, `flake.lock`,
`.github/` des Ursprungs (17 Workflows), `.agents/`, `AGENTS.md`, `CONTRIBUTING.md`,
`.pre-commit-config.yaml`, `scripts/` des Ursprungs (port, release-notes, vendor-hash …),
`quickshell/README.md`, `CHANGELOG.MD`, `CODENAME`, `VERSION` (Version kommt aus `Brand.qml`),
`qmlformat-all.sh`, `PLUGINS/` (Beispiel-Plugins), `core/cmd/duxinstall`,
`core/build_duxinstall.sh`, `core/install.sh`, `core/internal/distros/` (Installer für 10
Distributionen), `quickshell/scripts/spam-notifications.sh` u. ä.

### 4.2 Nicht unterstützte Compositors (sicher)

QML:
- `Services/NiriService.qml` (2001 Z.), `NiriFullscreen.js`, `NiriOutputCycle.qml`,
  `niri-wpblur.kdl`, `MangoService.qml` (821), `LabwcService.qml`, `UmbrielService.qml`
- `CompositorService.qml` (2183 Z.): Zweige `isNiri`, `isMango`, `isSway`, `isScroll`,
  `isMiracle`, `isLabwc`, `isUmbriel` raus; es bleiben `isHyprland` und `isKwin`
  (61 Dateien fragen Niri ab, 40 die übrigen – je Datei Zweig entfernen, nicht umschreiben)
- Einstellungsseiten bzw. Teile: `CompositorLayoutTab.qml` (niri/mango-Layout), Niri-/Mango-
  Abschnitte in `KeybindsTab`, `DisplayConfig`, `WindowRulesTab`, Fenster-/Workspace-Overlays,
  die nur unter niri arbeiten (`Modules/WorkspaceOverlays`: einzeln prüfen)
- matugen-Konfigurationen `niri.toml`, `mangowc.toml`; Assets `niri.svg`, `sway.svg`,
  `mango.png`, `labwc.png`, `miraclewm.svg`, `umbriel.svg`
- Node-Tests in `quickshell/tests/`, die nur diese Wege prüfen

Go:
- `internal/keybinds/providers/{niri,mangowc,sway,scroll,miracle}*`
- `internal/windowrules/providers/{niri,mango}_parser*`
- `internal/mangoconf/`, Niri-/Mango-Teile in `internal/config` (Deployer, eingebettete
  `niri-*.kdl`, `mango-*`), `commands_setup.go`-Zweige, `commands_doctor.go`-Prüfungen für
  niri/mango, `mango-monitor-rules`, `wlcontext`-Sonderfälle
- `internal/server/wlroutput` nur, falls weder Hyprland noch KWin es nutzt (KWin: kscreen,
  Hyprland: eigenes IPC) → beim Umsetzen messen, sonst bleibt es

### 4.3 Grenzfälle (Frage 5)

| Teil | Was es tut | Mein Vorschlag |
|---|---|---|
| Greeter (`GreeterTab`, `GreeterAuthTab`, `commands_greeter.go`, `dux-greeter`) | greetd-Anmeldebildschirm im DMS-Stil | **weg** – Alpe nutzt SDDM/Plasma-Login bzw. die Anmeldung von Fedora |
| Selbst-Aktualisierung des Ursprungs (`ShellVersionService`, `ChangelogService`, `FirstLaunchService`, `RepoMoveNotice.js`, `releases.json`-Abfrage, `ChangelogTab`, Willkommen/`Modals/Greeter/*`) | prüft GitHub-Releases von DMS, zeigt deren Versionshinweise | **weg** (zeigt sonst DMS-Releases); Alpe-eigene Hinweise später |
| Plugin- und Theme-Browser (`PluginDiscover`, `PluginBrowser`, `ThemeBrowser`, `RegistryBrowserWindow`, `internal/registries`) | lädt Plugins/Themes aus dem DMS-Register im Netz | **ausblenden, Code behalten** in 1.1; das Register gehört dem Ursprung, Kompatibilität ungewiss |
| Tailscale (`TailscaleService`, `internal/server/tailscale`, `tailscale.com` ≈ grösste Go-Abhängigkeit) | Tailnet-Status in der Leiste | Entscheid offen (siehe 0.4) |
| Übersetzungen (22 Sprachen, 6,4 MB) | | **de + en** behalten (en = Quelltexte), Rest weg |
| `dms-theme.vsix` + `vsix-build` | VS-Code-Farbschema aus matugen | weg (Zed-Vorlage bleibt) |
| matugen-Vorlagen für equibop/vencord/vesktop/pywalfox/zenbrowser/firefox/emacs/neovim/ghostty/alacritty/wezterm/foot | Farbübernahme in Fremdprogramme | behalten (kostet nichts, schaltbar) |
| Notepad, Mux (tmux/zellij), Lyrics, Wellbeing, Drucker (CUPS), ICC, Fcitx5 | Funktionen | behalten – nicht compositorspezifisch, nichts davon neu |
| `assets/discord.svg`, `reddit.svg`, `matrix-logo-white.svg` | Community-Links des Ursprungs auf der Über-Seite | weg |
| `dux-gop`-Paket (`dgop`) | Programm | wird nicht gebraucht; am Ende zum Entfernen anbieten |

Vor dem Löschen erzeuge ich je Kandidat eine Referenzliste (`git grep`), damit nichts Verwaistes
oder fälschlich Entferntes übrig bleibt, und führe danach die Ladeprüfung der ganzen Shell aus
(siehe 9).

---

## 5. Einverleiben – technisch

1. Exakter Baum: frischer Klon `v2.1.2` mit Submodul, `git am` beider Schichten → muss Baum-gleich
   mit `~/dux-shell@alpe` (b5e13ed) sein (Prüfung per `git rev-parse HEAD^{tree}`).
2. Commit **«DMS 2.1.2 einverleibt»**: unveränderter Ursprungsstand v2.1.2 (Submodul als normale
   Dateien, Symlink `DCommon` aufgelöst) unter `shell/` und `core/` – ohne Ursprungs-Git-Geschichte.
3. Commit **«KWin-Unterstützung (Patch v4)»** und **«Alpe 1.0 «Zugerberg» (bisherige Schicht)»**:
   die zwei Schichten auf den neuen Pfaden. So bleibt im Alpe-Log nachvollziehbar, was Ursprung,
   was KWin-Patch und was Alpe ist. Prüfung: Baum unter `shell/`+`core/` = `~/dux-shell@alpe`.
4. Danach `BASE`, Patches, `rerere/`, `upstream.sh` weg; `install.sh`-Rebuild weg.

`~/dux-shell` bleibt auf dem PC unberührt liegen, bis der Maintainer umgezogen ist (er läuft daraus).

---

## 6. Paketierung und Installation

### 6.1 Was das Paket installiert (Arch und Fedora gleich)

```
/usr/bin/alpe-dienst                         Go-Dienst (ohne eingebettete Oberfläche)
/usr/bin/alpe -> ../share/alpe/tools/alpe    CLI
/usr/share/alpe/{shell,plugins,tools,design,lockscreen}/
/usr/share/plasma/shells/org.alpe.desktop/   KDE-Sperre, beim Bau mit der Ansicht aus shell/Modules/Lock/Alpe zusammengesetzt
/usr/lib/systemd/user/alpe.service
/usr/share/applications/io.github.alpe_shell.Alpe{,.Notepad,.Open}.desktop
/usr/share/applications/alpe-open.desktop    Auswahl «jedes Mal fragen» (packaging/alpe-open.desktop, 0.8 Nr. 59)
/usr/share/icons/hicolor/scalable/apps/io.github.alpe_shell.Alpe.svg
/usr/share/{bash-completion,zsh,fish}/…/alpe-dienst
/usr/share/licenses/alpe-shell/{LICENSE,NOTICE,…}
```

`alpe.service` (aus `dms.service` abgeleitet):
`Description=Alpe`, `PartOf/After/Requisite=graphical-session.target`, `Type=notify`,
`BusName=org.freedesktop.Notifications`, `Environment=QS_DISABLE_CRASH_HANDLER=1 MALLOC_ARENA_MAX=2`,
`Conflicts=dms.service`, `After=dms.service` (nie zwei Shells gleichzeitig),
`ExecStart=/usr/bin/alpe start --session` (siehe 6.6: `alpe start` holt bei Bedarf die Dateien
aus `~/.config/dms` und ersetzt sich dann per `exec` durch `alpe-dienst -c … run`),
`WantedBy=graphical-session.target`.

Eingeschaltet wird die Unit je Compositor wie heute `dms.service` (0.6 Nr. 1): unter KDE
`systemctl --user enable alpe.service` (→ `graphical-session.target.wants`), unter Hyprland
`alpe-dienst systemd enable` (→ `hyprland-session.target.wants/alpe.service`; Hyprland ≥ 0.57
liefert die Target-Unit selbst und startet sie). Derselbe `ExecStart` für beide; keine
`exec-once`-Zeile.

Hinweis zu `Type=notify`: `alpe start` muss per `exec` in `alpe-dienst` übergehen (gleiche PID),
sonst passt `NotifyAccess=main` nicht.

Per Benutzer bleibt (das Paket fasst `$HOME` nie an): `alpe einrichten` (bisher `install.sh`
ohne Schichten-Teil: Plugins einschalten, Sperrbildschirm prüfen/aktivieren, Titelleisten,
Kürzel, fastfetch, Proton-VPN-Kopfleiste), `alpe kde ein`, `alpe design apply`.

### 6.2 Arch / CachyOS: `packaging/arch/PKGBUILD`

- `pkgname=alpe-shell`, `arch=(x86_64 aarch64)`, `license=(MIT)`
- `depends=(quickshell>=0.3.2 qt6-base qt6-declarative qt6-multimedia qt6-svg accountsservice python matugen wtype)`
  (`quickshell>=0.3.2`: so verlangt es die Systemprüfung des Ursprungs)
- `makedepends=(go make git)`
- `optdepends`: `python-h5py` (Radar), `ffmpeg` (Video-Hintergrund auf der Sperre), `kitty`,
  `fastfetch`, `kwin-effects-better-blur-dx` / `kwin-effect-rounded-corners` (AUR, Unschärfe/Ecken),
  `hyprlock`, `hypridle`, `slurp`, `cava`, `cups-pk-helper`, `power-profiles-daemon`,
  `networkmanager`, `i2c-tools`, `qt6ct`, `headsetcontrol`
- **kein `conflicts`/`replaces`**: Die Pakete teilen keine Datei; nur die Dienste dürfen nicht
  beide laufen. Das regeln Umzug und `alpe kde ein` (schalten `dms.service` ab), `alpe doctor`
  warnt. So kann `dux-shell` während des Umzugs als Rückweg installiert bleiben. `replaces`
  würde ausserdem auf fremden Rechnern DMS still austauschen.
- Quelle: Release-Tarball `alpe-<v>.tar.gz` **mit vendorten Go-Modulen** (vom Release-Workflow
  gebaut) → Bau ohne Netz, reproduzierbar; `GOFLAGS=-mod=vendor -trimpath -buildmode=pie`,
  `CGO_ENABLED=0` wie beim Ursprung
- `make install DESTDIR="$pkgdir" PREFIX=/usr`
- Prüfung im Bau: `go test ./...` in `check()`, `namcap` in CI
- Veröffentlichung im AUR macht der Maintainer (Frage 10). Bis dahin baut `get.sh` das PKGBUILD aus dem
  Repo mit `makepkg -si` (braucht `base-devel`).

### 6.3 Fedora / Asahi: `packaging/fedora/alpe-shell.spec` (COPR)

- Chroots: `fedora-43-x86_64`, `fedora-43-aarch64`, `fedora-44-…` (Asahi Remix folgt Fedora)
- `Requires: quickshell >= 0.3.2, matugen, python3, accountsservice, qt6-qtmultimedia, wtype`;
  `Recommends: python3-h5py, ffmpeg-free, slurp, hyprlock, hypridle, kitty, fastfetch`
- **Woher kommen Quickshell und matugen unter Fedora?**
  - Quickshell: im offiziellen Fedora-Repo (Fedora 44/Rawhide), laut Paketseite aber Stand 0.2.1
    – **zu alt** für die verlangte 0.3.2. Aktuelle Builds mit aarch64 im COPR
    `errornointernet/quickshell` (betreut vom Fedora-Paketierer) und `avengemedia/quickshell`
    (DMS-Projekt; von dort kommt es vermutlich heute auf dem Mac, weil der DMS-Installer es
    einrichtet).
  - matugen: offiziell `rust-matugen` (Stand 3.1.0), Arch hat 4.2.0. Ob 3.x reicht, prüfe ich
    beim Umsetzen gegen die Aufrufe in `core/internal/matugen`; sonst COPR.
  - Vorschlag: eigenes COPR `alpe-shell/alpe` mit `alpe-shell` **und** nachgebautem `quickshell`
    (und bei Bedarf `matugen`) – ein einziges `dnf copr enable`, keine Abhängigkeit vom
    DMS-COPR. Frage 7.
- **Go-Version:** `go.mod` verlangt Go ≥ 1.27.3. Fedora-Builder haben kein Netz für
  `GOTOOLCHAIN=auto`. Prüfen, welche `golang`-Version Fedora 43/44 liefert; reicht sie nicht,
  `go`-Direktive senken (nur wenn keine Abhängigkeit es verlangt) oder Toolchain als Source1.
- **Asahi-Risiko:** 16-KB-Seiten. Quickshell hängt auf Arch an jemalloc; ein für 4-KB-Seiten
  gebautes jemalloc stürzt auf Asahi ab. Fedora baut jemalloc für aarch64 mit grösseren Seiten –
  am Mac mit `alpe doctor` prüfen, bevor das COPR-Quickshell ausgerollt wird.

### 6.4 `get.sh` neu

1. Rechner/Sitzung prüfen (wie heute).
2. Paket installieren: Arch → AUR-Helfer (`paru`/`yay -S alpe-shell`), sonst PKGBUILD aus dem
   Repo per `makepkg -si`; Fedora → `dnf copr enable alpe-shell/alpe` + `dnf install alpe-shell`.
   **Kein DMS-Installer, kein `dux-shell` mehr.** Ist `dux-shell` installiert und `dms.service`
   aktiv: `alpe umzug` statt Neuinstallation.
3. Optionale Pakete (h5py, ffmpeg, kitty, fastfetch, KWin-Effekte) wie heute, mit Merkliste.
4. `alpe einrichten`, unter KDE `alpe kde ein --jetzt`, unter Hyprland
   `alpe-dienst systemd enable` (`hyprland-session.target` will `alpe.service`, 0.6 Nr. 1); eine
   vorhandene `exec-once`-Zeile mit `dms run`/`alpe start` wird mit Sicherung auskommentiert,
   sonst liefen zwei Shells.
5. Design einspielen (wie heute).
- Fallback ohne Paket für Entwicklung: `make install PREFIX=$HOME/.local` + Unit nach
  `~/.config/systemd/user/` (Option `--aus-quelle`).
- `ALPE_REPO_URL` zeigt auf `alpe-shell/alpe`; `~/alpe` wird für Benutzer nicht mehr gebraucht
  (nur noch für Entwicklung).

### 6.5 Entwicklung auf dem PC (ersetzt `backend.sh`)

`alpe entwicklung ein [PFAD]`: baut `core/` nach `~/.local/lib/alpe/alpe-dienst` und legt
`alpe.service.d/entwicklung.conf` an (`ExecStart=… -c ~/alpe/shell run --session`).
`alpe entwicklung aus` nimmt das zurück. `alpe doctor` zeigt deutlich, wenn der Entwicklungsstand
läuft.

### 6.6 Angepasste Befehle

- `alpe doctor`: prüft `alpe.service`, Version Dienst = Oberfläche (beide aus demselben Paket),
  Rest wie heute; Hinweis, wenn noch `dms.service` aktiv oder `dux-shell` installiert ist.
- `alpe update`: Paketweg (`paru -S alpe-shell` bzw. `dnf upgrade alpe-shell`) + `alpe einrichten`;
  im Entwicklungsmodus `git pull` + Neubau. Archiv-Weg entfällt.
- `alpe entfernen [--alles]`: `alpe.service` aus, `kde aus`, Sicherungen zurück wie heute; mit
  `--alles` zusätzlich `~/.config/alpe`, `~/.local/state/alpe`, `~/.cache/alpe`,
  `~/.config/hypr/alpe/`, Paket `alpe-shell` und gemerkte Pakete (zuerst `pacman -Rs --print`).
- `alpe backup`: Pfadliste auf die neuen Namen.
- `alpe log`: `journalctl --user -u alpe.service`.
- **`alpe start [ARGS]`** (neu): fehlt `~/.config/alpe/settings.json` und gibt es
  `~/.config/dms/settings.json`, zuerst `alpe umzug --nur-dateien`; danach
  `exec alpe-dienst -c <Oberfläche> run ARGS`. Oberfläche = `/usr/share/alpe/shell`, im
  Entwicklungsmodus der Repo-Baum. Einziger Startweg: `ExecStart` von `alpe.service`, unter KWin
  und Hyprland gleich (0.6 Nr. 1).
- `alpe doctor` erinnert an `alpe umzug aufraeumen`, solange die alten DMS-Ordner liegen.

### 6.7 Sperrbildschirm: nutzerspezifische Dateien (wird vor E1 vorgelegt)

Heute kopiert `lockscreen.sh` das Design nach `~/.local/share/plasma/shells/org.alpe.desktop` und
schreibt dort das erzeugte `layout.js` und die Bilder hinein. Ein Paket unter
`/usr/share/plasma/shells/` ist schreibgeschützt. Entscheidungsvorlage (Varianten: Greeter liest
aus `~/.config/alpe`, oder bewusst erzeugte Nutzerkopie) mit Folgen für Umzug,
`design apply/export` und `alpe entfernen` folgt vor E1.

### 6.8 `alpe-dienst` startet nie eine systemd-Unit (D1)

Heute leitet der Dienst `dms restart` über den Haken `TryManagedRestart` (`core/cmd/dms/shellapp.go:34`
→ `systemd_restart.go`) an systemd weiter: Ist `dms.service` aktiv, ruft er
`systemctl --user restart dms.service` auf; sonst unter Umständen `systemctl --user start dms.service`
(`trySystemdStart`). Ausgelöst wird das durch `dms restart`: Energiemenü «Neu starten»
(`SessionService.qml:692`), Neustart nach Systemaktualisierung (`SystemUpdateService.qml:436`),
Prozessliste (`ProcessActions.qml:240`), `dms update` (`commands_features.go:117`). Ein von Hand oder in
einem Test gestarteter Dienst kann so die Unit des laufenden Systems neu starten.

Ab D1:
- `alpe-dienst` ruft nie `systemctl start/stop/restart` auf und nutzt keinen Haken, der das tut
  (`TryManagedRestart` entfällt, ebenso `trySystemdStart`; `runSystemctl` bleibt nur für lesende
  Abfragen in `doctor`). `alpe-dienst systemd enable/disable` setzt bzw. entfernt nur die
  Wants-Verknüpfung (Datei, `daemon-reload`); die Option `--now` (startet/stoppt die Unit) entfällt.
  Der Deployer in `internal/config` (`startInLiveSession`) hat keinen Aufrufer; bleibt er nach
  E4/F2, verliert er den `start`-Aufruf ebenfalls.
- `alpe-dienst restart` startet nur die eigene Instanz neu (wie der Weg ohne systemd heute). Läuft der
  Dienst unter systemd (`INVOCATION_ID`/`NOTIFY_SOCKET` gesetzt), meldet `alpe-dienst restart`, dass die
  Unit über `alpe restart` neu zu starten ist, und ändert nichts. Läuft er nicht unter systemd, meldet er
  das beim Start einmal im Log und läuft normal weiter.
- Den bewussten Neustart der Unit übernimmt allein die CLI `alpe restart` (Benutzerhandlung). Die
  Aufrufer in der Oberfläche (Energiemenü, Aktualisierung, Prozessliste) rufen künftig `alpe restart`
  statt `dms restart` auf.
- Test (`core/cmd/alpe-dienst/…_test.go`): `runSystemctl` wird durch eine Attrappe ersetzt, die jeden
  Aufruf protokolliert; `restart` mit und ohne systemd-Umgebung darf kein `start`, `stop` oder
  `restart` erzeugen; ohne systemd erscheint die Log-Meldung und der Dienst läuft weiter. Zusätzlich
  meldet die Ladeprüfung jeden abgefangenen `start`/`stop`/`restart` in `stubs.log`.

---

## 7. Umzug 1.0 → 1.1 (`tools/umzug.py`, Befehl `alpe umzug`)

### 7.1 Wie der Umzug ausgelöst wird

Auf 1.0 heisst «aktualisieren»: `alpe update` = `git pull` in `~/alpe` + `bash install.sh`.
Darum bleibt in 1.1 ein **schlankes `install.sh` als Übergang**: Es erkennt eine 1.0-Einrichtung
(`dms.service`-Drop-ins von Alpe, `~/dux-shell` auf Zweig `alpe`, Link `~/.local/bin/alpe` ins
Repo) und ruft `tools/umzug.py` aus dem frisch gezogenen Repo auf. Damit klappt Abnahme 4 («Mac:
`alpe update` ohne Handarbeit»; sudo-Passwort für die Paketinstallation ausgenommen).
Ohne 1.0-Spuren sagt `install.sh` nur, dass es durch Paket + `alpe einrichten` ersetzt ist.

### 7.2 Ablauf (idempotent, jeder Schritt protokolliert in `~/.config/alpe/umzug-1.1/protokoll.json`)

1. **Prüfen** (`--check` zeigt nur): 1.0 erkannt? Sitzung KDE/Hyprland? Paket `alpe-shell`
   installierbar? Freier Platz? Alles Folgende wird zuerst als Liste gezeigt.
2. **Sichern** nach `~/.config/alpe/umzug-1.1/sicherung.tar.gz`: `~/.config/dms`,
   `~/.local/state/dms` (+ Symlink), `~/.cache/dms/{clipboard,notification_history.json}`,
   `~/.config/alpe`, `~/.config/systemd/user/dms.service.d`, `kglobalshortcutsrc`,
   `kwinrc`, `kwinrulesrc`, `kscreenlockerrc`, `plasmashellrc`, `~/.config/hypr` (ohne Bilder),
   `~/.config/kitty`, `~/.local/share/plasma/shells/org.alpe.desktop`,
   `~/.local/share/applications/dev.duxlabs.shell.desktop`, `~/.local/bin/alpe` (Link),
   `~/.local/lib/alpe`.
3. **Paket**: `alpe-shell` installieren (Arch: AUR-Helfer/makepkg; Fedora: COPR). Es teilt nach
   der Umbenennung keine Datei mit `dux-shell`, beide Pakete stehen also für die Dauer des Umzugs
   nebeneinander. Damit bleibt der Rückweg bis Schritt 9 offen. (Deshalb **kein** `conflicts` im
   Paket, siehe 6.2.)
4. **Dateien**: `~/.config/dms/*` → `~/.config/alpe/` kopieren (nie überschreiben; Kollisionen
   ins Protokoll, Alpe-Datei gewinnt, DMS-Datei bleibt in der Sicherung). Ausnahme
   `plugins/alpe*` (kommen jetzt aus `/usr/share/alpe/plugins`; eine Nutzerkopie würde das Paket
   verdecken). **Allgemein (0.8 Nr. 32):** Kopien von Plugins, deren ID Alpe selbst mitliefert,
   werden weder übernommen noch gelöscht, sondern – auch wenn sie schon in `~/.config/alpe/plugins`
   liegen – nach `~/.config/alpe/plugins.beiseite/<Zeitpunkt>/` gelegt und protokolliert; der
   Rückweg holt sie zurück. **Fremde Plugins und `.repos` bleiben unberührt** in `~/.config/dms/plugins`
   (weder kopiert noch verschoben); `alpe doctor` nennt sie, damit man sie bei Bedarf selbst
   nach `~/.config/alpe/plugins` holt. Auch `alpe entfernen --alles` lässt sie stehen.
   `~/.local/state/dms/*` → `~/.local/state/alpe/`. Aus `~/.cache/dms` nur Zwischenablage und
   Mitteilungsverlauf. **Alte Ordner bleiben unangetastet** (Rückweg); weg mit
   `alpe umzug aufraeumen` oder `alpe entfernen --alles` (Frage 11).
   Schlüssel/Werte in `settings.json` benennt die Shell selbst beim ersten Start um
   (`SettingsData`-Migration, legt `settings.v<alt>.json` an) – eine Stelle, auch für Leute,
   die alte Sicherungen zurückspielen.
5. **Sperrbildschirm (KDE)**: Nutzerkopie `~/.local/share/plasma/shells/org.alpe.desktop` in die
   Sicherung verschieben (sie würde das Paket verdecken), dann `lockscreen.sh install` – Probe mit
   dem Systempaket, `ShellPackage` nur bei Erfolg. Layout in `kscreenlockerrc` bleibt.
6. **Kürzel (KDE, während KWin läuft)** – Reihenfolge ist wichtig, weil kglobalaccel eine
   Vorgabe-Taste nicht doppelt vergibt:
   a) aktuelle Tasten aller `dms-*`-Aktionen der Komponente `kwin` lesen (kglobalaccel per D-Bus,
      Ersatz: `kglobalshortcutsrc`) und ins Protokoll;
   b) `dms.service` stoppen, Skript `dms-bridge` in KWin entladen, `dms-*`-Aktionen abmelden
      (`unregister`, wie `alpe-kwin.py shortcut-remove`);
   c) `alpe.service` starten → `alpe-bridge` meldet `alpe-*` an;
   d) gemerkte Tasten mit `setForeignShortcutKeys` auf `alpe-*` setzen (damit bleiben auch
      eigene Änderungen, nicht nur die Vorgaben).
   e) **Befehle in Kürzeln umschreiben (0.8 Nr. 44), für jeden Nutzer, nicht nur für den
      Maintainer:** In allen Befehlskürzeln (`alpe-cmd-*`/`dms-cmd-*` der Brücke, eigene
      `net.local.*`-Einträge samt ihren `.desktop`-Dateien) werden alte Befehle und IPC-Ziele nach
      derselben Tabelle wie in 7.4 Schritt 6 ersetzt. Der Umzug sucht nach dem Muster, nicht nach
      einer festen Liste von Kürzeln; jede Ersetzung steht im Protokoll, `--zurueck` nimmt sie zurück.
   Tasten der eigenen Programm-/Befehlskürzel (`net.local.*`) und Meta+Q/Meta+M sind nicht betroffen.
   `kwinrc [Effect-better-blur-dx] WindowClasses` und `kwinrulesrc`: Fensterklasse
   `dev.duxlabs.shell` → neue App-ID, falls vorhanden (auf dem PC heute nicht).
7. **Dienste**: `dms.service` disable; Drop-ins aus `dms.service.d/` in die Sicherung;
   Inhalt übersetzen: `QT_QPA_PLATFORMTHEME*` → `alpe.service.d/kde.conf`, eigener Bau →
   ggf. `alpe entwicklung ein` (nur wenn er auf ein Repo zeigt, sonst verworfen),
   `MALLOC_ARENA_MAX` steckt im Paket. `alpe.service` wird von denselben Targets gewollt wie
   bisher `dms.service`: jede Verknüpfung `<target>.wants/dms.service` unter
   `~/.config/systemd/user/` wird zu `<target>.wants/alpe.service` (PC: `graphical-session.target`,
   Mac: `hyprland-session.target`), die alte kommt in die Sicherung. Unter KDE bleibt
   `plasma-plasmashell.service` maskiert (geprüft, nicht geändert).
8. **Hyprland (Mac)**: siehe 7.4.
9. **Aufräumen**: Link `~/.local/bin/alpe` (zeigt ins Repo, verdeckt `/usr/bin/alpe`) entfernen,
   `~/.local/lib/alpe/`, `~/.local/share/applications/dev.duxlabs.shell.desktop` in die
   Sicherung. Einbindungen der Ausgabedateien in den Fremdprogrammen auf die neuen Namen
   umstellen (Tabelle 7.6; die Dateien unter den alten Namen bleiben bis «Umzug-Ende» liegen und
   aktuell). `mimeapps.list`: `dms-open.desktop` → `alpe-open.desktop`. Erst jetzt, nach erfolgreichem Start und `alpe doctor` ohne Fehler:
   **`dux-shell` (und `dux-gop`) zum Entfernen anbieten** – `pacman -Rs --print dux-shell dux-gop`
   zeigen, dann `sudo pacman -Rns …`; Fedora: `dnf remove dms dms-cli dgop` zeigen. Hinweis auf
   die `IgnorePkg`-Zeile in `/etc/pacman.conf` (die fasse ich nicht an).
   `~/dux-shell` und `~/alpe` bleiben (PC: Entwicklung; Mac: Frage 12).
10. Marke `~/.config/alpe/umzug-1.1/fertig`.

**Rückweg** `alpe umzug --zurueck` (solange `dux-shell` noch installiert ist): `alpe.service`
aus, Sicherung zurückspielen, `dms.service` + Drop-ins an, Kürzel `dms-*` wieder setzen,
Hyprland-Zeilen zurück. Danach läuft 1.0 wie vorher.

**Was der Rückweg leistet (0.8 Nr. 58):** Er stellt den Zustand **zum Zeitpunkt des Umzugs**
wieder her. Was nach dem Umzug geändert wurde, kommt nur zurück, wenn es ausdrücklich
zurückgesetzt wird; beides zählt 7.7 auf, und `--zurueck` gibt die Liste am Ende aus.

**Sicherheitsnetz** `alpe umzug --nur-dateien` (aufgerufen von `alpe start`): Gibt es
`~/.config/dms/settings.json`, aber kein `~/.config/alpe/settings.json`, nur Schritt 4 – damit
startet Alpe nie mit Werkseinstellungen, falls jemand das Paket ohne Umzug installiert.

### 7.3 Was nicht umzieht

DMS-eigene Dateien ohne Bedeutung für Alpe (`releases.json`, `launcher_cache.json`,
`imagecache/`, `lyrics/`, `video-wallpaper/`) – bauen sich neu.

### 7.4 Hyprland (Mac)

Heute (Mac-Test nach C5, 0.6): `dms.service` ist eingeschaltet und wird von
`hyprland-session.target` gestartet; Hyprland 0.57 liefert und startet das Target selbst.
`bootstrap.sh` nahm noch `exec-once = dms run` an – das ist am Mac nicht der Fall. Dazu
`source = ~/.config/hypr/alpe.conf` (Datei mit `env = DMS_SHELL_DIR,…`) ganz oben, und – vom
DMS-Setup – Includes aus `~/.config/hypr/dms/*.lua` (binds, colors, layout, outputs, cursor,
input, windowrules, binds-user).

**Die Shell schreibt selbst in diesen Ordner** (0.6 Nr. 2): `HyprlandService` erzeugt beim Start
bzw. bei Änderungen `outputs.lua`, `layout.lua`, `cursor.lua`, `input.lua` und legt
`windowrules.lua` an, matugen schreibt `colors.lua`, der Kürzel-Editor `binds-user.lua`. Ab D2
schreibt Alpe nach `hypr/alpe/`. Folge: Startet Alpe 1.1 einmal vor dem Umzug (z. B. Paket ohne
Umzug, `alpe start`), liegen in `hypr/alpe/` schon frisch erzeugte Dateien, die
`hyprland.lua` noch nicht einbindet.

Umzug:
1. `hypr/alpe.conf` und ihre `source`-Zeile entfernen (die Umlenkung ist überflüssig).
2. `hypr/dms/` → `hypr/alpe/` kopieren, alte bleibt bis zum Aufräumen. Kollisionen: Für die
   erzeugten Dateien (`outputs`, `layout`, `cursor`, `input`, `colors`) gewinnt die Fassung aus
   `hypr/dms/` nur, wenn `hypr/alpe/` sie noch nicht hat – die Shell erzeugt sie ohnehin aus den
   Einstellungen neu. Von Hand gepflegte Dateien (`binds-user.lua`, `windowrules.lua`, alles
   Unbekannte) gewinnen aus `hypr/dms/`; eine abweichende Datei in `hypr/alpe/` geht als
   `*.vor-umzug` daneben und ins Protokoll.
3. Alle Verweise `hypr/dms/` in `hyprland.conf`/`hyprland.lua` und Unterdateien auf `hypr/alpe/`
   umschreiben (Sicherung `*.vor-alpe-1.1`).
4. Start: Verknüpfung `hyprland-session.target.wants/dms.service` → `…/alpe.service` (7.2
   Schritt 7). Eine `exec-once`-Zeile mit `dms run` gibt es am Mac nicht; findet der Umzug doch
   eine, wird sie auskommentiert (sonst zwei Shells).
5. Wirksam nach Ab-/Anmelden; `--jetzt` stoppt `dms.service` und startet `alpe.service` (nur
   mit dieser Option und nach Rückfrage im Umzug).
6. **Alte IPC-Ziele und Befehle umschreiben (0.8 Nr. 44), für jeden Nutzer:** in
   `hyprland.conf`/`hyprland.lua`, allen von dort eingebundenen Dateien, `hypr/alpe/*.lua`
   (auch `binds-user.lua`), `hypridle.conf` und `hyprlock.conf` (Sicherung `*.vor-alpe-1.1`,
   Protokoll, `--zurueck`). **Ausgenommen sind Sicherungen (0.8 Nr. 57):** Ordner wie
   `~/.config/hypr/.dms-backups/` und `.alpe-backups/`, Dateien `*.vor-alpe-1.1`, `*.vor-umzug`,
   `*.bak`, `*.dms-backup`, `*.alpe-backup` werden weder umgeschrieben noch sonst verändert, auch
   wenn sie alte Ziele enthalten (am Mac steht `dankdash` nur in einer solchen Sicherung). Der
   Test prüft, dass ein Sicherungsordner mit alten Zielen nach dem Umzug Byte für Byte gleich ist.
   Tabelle, gemeinsam mit 7.2 Schritt 6 e:

   | Alt | Neu |
   |---|---|
   | `dms ipc …`, `dms ipc call …` | `alpe-dienst ipc …` |
   | `dms screenshot …`, `dms cl …`, `dms notify …` und alle übrigen Unterbefehle von `dms` | `alpe-dienst …` |
   | `dms run`, `dms restart`, `dms kill` | `alpe start` bzw. `alpe restart` (6.8); eine `exec-once`-Zeile wird auskommentiert (Schritt 4) |
   | IPC-Ziel `dankdash` (`ipc call dankdash wallpaper`) | `dash` (`ipc call dash toggle wallpaper`) |
   | Seiten-IDs als Argument (`ipc call settings …`): `dankbar`, `dankbar_settings`, `dankbar_appearance`, `dankbar_dot`, `dankbar_widgets`, `dank_dash`, Aliasse `dank_island`, `dankdot` | `bar`, `bar_settings`, `bar_appearance`, `bar_dot`, `bar_widgets`, `dash`, `island`, `dot` |
   | `dms dank16 …` | `alpe-dienst palette16 …` |
   | `dms://…` (Aufruf über `dms open`) | entfällt (0.8 Nr. 14): Zeile bleibt, Hinweis im Protokoll |
   | Layer-Namensraum in `layerrule`/`layer_rule`: `dms:…`, `dms:dankisland` | `alpe:…`, `alpe:island` |
   | `env = ALPE_DANKBAR_LAYER,…`, `ALPE_DANKISLAND_LAYER` (auch `~/.config/environment.d/`) | `ALPE_BAR_LAYER`, `ALPE_ISLAND_LAYER` |

   Ohne Übergang in der Shell: Bis zum Umzug greifen Kürzel mit alten Zielen nicht (`dms` spricht
   nur DMS-Sockets an; `dankdash` gibt es nicht mehr).

### 7.5 Test

`tests/test_umzug.py` mit `tests/data/umzug-1.0/` – einer echten 1.0-Struktur, lesend aus echten
Dateien gezogen und anonymisiert (Pfade `/home/<name>` → `@HOME@`, Wetterort/Favoriten/Bildschirm-
namen raus über die Schrubb-Logik von `tools/design.py`). Dazu eine Hyprland-Variante (künstlich
nach bootstrap.sh, solange keine Mac-Dateien vorliegen). Stubs für `systemctl`, `kwriteconfig6`,
`kreadconfig6`, `busctl`/kglobalaccel, `pacman`/`dnf` (Muster `tests/data/kwinstub`). Geprüft:
- Endzustand (Dateien, Drop-ins, Hyprland-Zeilen, kitty-Includes, Kürzel-Aufrufe in richtiger
  Reihenfolge);
- zweiter Lauf ändert nichts;
- `--zurueck` ergibt Byte für Byte den Ausgangsbaum;
- fremdes Plugin bleibt, Alpe-Plugins nicht als Nutzerkopie;
- Kollision in `~/.config/alpe` → Alpe-Datei gewinnt, Protokolleintrag;
- Sicherungsordner (`hypr/.dms-backups/` mit alten IPC-Zielen) und `*.dms-backup` nach Umzug und
  nach `--zurueck` unverändert (0.8 Nr. 57);
- Fensterregeln: Nach dem Umzug wird eine Regel geändert und eine neue angelegt (`-- ALPE-RULE:`,
  `alpe_rule_N`); `--zurueck` setzt Marke und IDs auf `-- DMS-RULE:` und die alten IDs, der
  Parser von 1.0 (Marke `DMS-RULE`) findet alle Regeln (0.8 Nr. 58);
- Einbindungen je Programm aus 7.6 stehen nach dem Umzug auf dem neuen Namen, nach `--zurueck`
  wieder auf dem alten; `mimeapps.list` ebenso.

### 7.6 Einbindungen der Ausgabedateien (0.8 Nr. 48, 59)

Der Umzug stellt die Einbindung in jedem Programm auf den neuen Namen um – nur dort, wo die alte
Einbindung tatsächlich steht (Muster, keine feste Zeile), je Datei mit Sicherung `*.vor-alpe-1.1`
und Protokolleintrag. Die Dateien unter den alten Namen (Links bzw. zweite Fassungen aus
`core/internal/matugen/altnamen.go`) bleiben liegen und aktuell; **Links und doppeltes Schreiben
fallen mit «Umzug-Ende» weg** (0.8 Nr. 23), dann räumt Alpe auch die alten Namen ab.

| Programm | Datei mit der Einbindung | Alt → neu |
|---|---|---|
| KDE-Farbschema | `~/.config/kdeglobals` (`[General] ColorScheme`) | `DankMatugen{,Light,Dark}` → `AlpeMatugen{,Light,Dark}` |
| qt5ct, qt6ct | `~/.config/qt5ct/qt5ct.conf`, `~/.config/qt6ct/qt6ct.conf` (`color_scheme_path`); qtengine-Konfiguration, falls sie das Schema nennt | `…/color-schemes/DankMatugen….colors` → `…/AlpeMatugen….colors` |
| Zed | `~/.config/zed/settings.json` (`theme`, auch die Form mit `light`/`dark`) | Themennamen «… DankShell …» → «… Alpe …» (dieselben Paare wie `altnamen.go`) |
| kitty | `~/.config/kitty/kitty.conf` und eingebundene Dateien (`include`) | `dank-theme.conf`, `dank-tabs.conf` → `alpe-theme.conf`, `alpe-tabs.conf` |
| Ghostty | `~/.config/ghostty/config` (`theme =`) | `dankcolors` → `alpecolors` |
| Alacritty | `~/.config/alacritty/alacritty.toml` (`import` bzw. `general.import`) | `dank-theme.toml` → `alpe-theme.toml` |
| foot | `~/.config/foot/foot.ini` (`include=`) | `dank-colors.ini` → `alpe-colors.ini` |
| WezTerm | `~/.config/wezterm/wezterm.lua` bzw. `~/.wezterm.lua` (`color_scheme`) | `"dank-theme"` → `"alpe-theme"` |
| Emacs | `init.el`/`early-init.el` im Emacs-Ordner, `~/.emacs` (`load-theme`, `custom-enabled-themes`) | `dank-emacs` → `alpe-emacs` |
| GTK 3/4 | `~/.config/gtk-3.0/gtk.css`, `gtk-4.0/gtk.css` (`@import`; oder `gtk.css` als Link auf die Farbdatei) | `dank-colors.css` → `alpe-colors.css` |
| fcitx5 | `~/.config/fcitx5/conf/classicui.conf` (`Theme=`, `DarkTheme=`) | `dms` → `alpe` |
| Discord-Clients | Equibop, Vesktop: `settings/settings.json` (`enabledThemes`); Vencord: dieselbe Liste in seinen Einstellungen | `dank-discord.css` → `alpe-discord.css` |
| Standardprogramme | `~/.config/mimeapps.list` | `dms-open.desktop` → `alpe-open.desktop` (liefert `alpe-shell`, 6.1) |

Nicht umgestellt: Neovim (Namen bleiben, 0.8 Nr. 60), pywalfox (liest `wal/colors.json`).
Läuft ein Programm während des Umzugs, sieht es die Umstellung je nach Programm erst nach
Neuladen; ob Vencord beim Wechsel über den Link neu lädt, steht in `offene-faelle.md`.

### 7.7 Rückweg: was zurückgesetzt wird und was nicht (0.8 Nr. 58)

Grundsatz: `alpe umzug --zurueck` stellt den Zustand zum Zeitpunkt des Umzugs wieder her
(Sicherung, Protokoll). Stand der Liste: D7.7; F1 führt sie zu Ende und gibt sie aus.

Ausdrücklich zurückgesetzt, auch wenn nach dem Umzug geändert:
- **Fensterregeln:** `-- ALPE-RULE:` → `-- DMS-RULE:`, `alpe-floating-windows` →
  `dms-floating-windows`, `alpe-window-opaque` → `dms-window-opaque`, `alpe_rule_N` → `dms_rule_N` (die Form
  der automatischen IDs von 1.0) – im aktuellen Stand der Regeldatei, nicht aus der Sicherung;
  so bleiben Regeln erhalten, die nach dem Umzug geändert oder angelegt wurden.
- Alles, was der Umzug selbst umgeschrieben hat (Protokoll): Hyprland-Zeilen, Kürzel und ihre
  Befehle, Einbindungen nach 7.6, `mimeapps.list`, Verknüpfungen der Dienste, zur Seite gelegte
  Plugin-Kopien.

Nicht zurückgesetzt (bleibt auf dem Stand des Umzugs bzw. geht 1.0 verloren):
- Einstellungen und Session, die nach dem Umzug in `~/.config/alpe` und `~/.local/state/alpe`
  geändert wurden (1.0 liest `~/.config/dms` und `~/.local/state/dms` im Stand des Umzugs);
- Kürzel und Anzeigeprofile, die nach dem Umzug unter `hypr/alpe/` bzw. über die KWin-Brücke
  `alpe-*` angelegt wurden;
- nach dem Umzug installierte oder geänderte Plugins unter `~/.config/alpe/plugins`;
- Zwischenablage und Mitteilungsverlauf seit dem Umzug;
- eigene matugen-Vorlagen, die nach dem Umzug mit `palette16` geschrieben wurden (1.0 kennt nur
  `dank16`);
- Sicherungen unter neuem Namen (`*.alpe-backup`, `hypr/.alpe-backups/`), die 1.0 nicht kennt;
  die Sicherungen aus 1.0 liegen unverändert daneben (0.8 Nr. 57);
- die Hotspot-Verbindung «Alpe Hotspot», falls sie nach dem Umzug neu angelegt wurde (1.0 legt
  seine eigene wieder an), und gekündigte CUPS-Abonnements des Besitzers `dms` (1.0 abonniert neu).

---

## 8. Doku und Version

`README.md` (Installation per Paket, Abschnitt «Herkunft: basiert ursprünglich auf der Dux
Modular Shell 2.1.2, MIT»), `docs/technik.md` (neue Struktur, Namen, Dienst, Entwicklung),
`design/README.md`, `CHANGELOG.md` (1.1: eigenständig, Paket, Umzug), `Brand.qml`
`version: "1.1"`, `url` → `alpe-shell/alpe`. Eine Tabelle «alter Name → neuer Name» in
`docs/technik.md` für alle, die Skripte gegen `dms ipc` geschrieben haben.

---

## 9. Tests und CI nach der Abspaltung

- `tools/test.sh` arbeitet auf dem Repo selbst (`ALPE_SHELL_DIR` Vorgabe `./shell`, kein
  `~/dux-shell` mehr); CI klont nichts mehr vom Ursprung.
- Go: `go vet ./...`, `go test ./...` (bisher nur `TestReadAlpeOff`), `make build`.
- Node-Tests des Ursprungs (`shell/tests/*.test.mjs`, 72 Stück), soweit sie nach dem Entschlacken
  übrig sind, kommen in `tools/test.sh`.
- **Neu: Ladeprüfung der ganzen Shell.** Bisher laden nur die Alpe-Seiten mit Attrappen. Nach so
  vielen Umbenennungen braucht es einen Lauf, der `shell/shell.qml` wirklich startet: in einem
  Arch-Container (wie die QML-Tests des Ursprungs) mit `quickshell` unter einem verschachtelten
  Compositor ohne Bildschirm (`kwin_wayland --virtual` bzw. Hyprland headless) und Abbruch bei
  jedem `ReferenceError`/`is not a type`/`module … not installed` im Log. Läuft auch lokal in
  einem Temp-`HOME`.
- Paket-Prüfungen in CI: PKGBUILD in `archlinux:latest` bauen (`makepkg`, `namcap`), Spec mit
  `rpmbuild` in `fedora:latest` (x86_64; aarch64 erst im COPR).
- Abnahme-Grep als Test: `tools/namen-pruefen.sh` listet jeden Treffer von `dms|dux|dank`
  ausserhalb einer Ausnahmeliste und schlägt fehl, wenn etwas Neues dazukommt.
  Auf der Ausnahmeliste stehen die Ausnahmen aus 2.2 und 2.3.3 (0.8: interne Bezeichner und
  `Dank*`-Weiterleitungen nicht mehr). Vorgezogen nach D7 (2.3.5).

---

## 10. Reihenfolge der Commits (Branch `phase-a`)

Jeder Commit: `bash tools/test.sh` grün (ab F1 zusätzlich Umzugstest). Ladeprüfung: von C3 bis D3
je Commit; **ab D4 einmal pro Halt auf dem Endstand** unter KWin und Hyprland, bei neuen
Meldungen die Commits dazwischen einzeln (0.7 Nr. 6). Im Temp-HOME sind dabei **alle Plugins
unter `plugins/`** eingeschaltet (0.8 Nr. 33).

| # | Commit | Inhalt |
|---|---|---|
| A0 | Plan Phase A | `docs/plan/phase-a*.md` + `CLAUDE.md` (neutral formuliert) |
| A1 | CI: Release idempotent | release.yml, Versionsprüfung, Actions-Versionen; Repo-URL `alpe-shell/alpe` überall |
| B1 | DMS 2.1.2 einverleibt | unveränderter Ursprung unter `shell/`, `core/`; `NOTICE` |
| B2 | KWin-Unterstützung (Patch v4) | Schicht 0000 auf neuen Pfaden |
| B3 | Alpe 1.0 im Quellbaum | Schicht 0001; Baumvergleich mit `~/dux-shell@alpe`; Patches, `BASE`, `rerere/`, `upstream.sh` weg; `tools/test.sh`/CI auf Repo-Baum |
| C1 | Ursprungs-Infrastruktur entfernt | 4.1 |
| C2 | niri entfernt | QML + Go + Assets + Tests |
| C3 | mango, sway, scroll, miracle, labwc, umbriel, river entfernt | dito; CompositorService auf Hyprland + KWin |
| C4 | Grenzfälle entfernt | nach Entscheid des Maintainers (4.3), je Thema ein Commit |
| C5 | Abgeschaltete Zweige aufgeräumt | 0.5 Nr. 4: nur nachweislich toter Code; Ladeprüfung KWin + Hyprland |
| C6 | Aufräumen der Reste (0.6) | leere `CompositorService`-Funktionen (`toggleOverview`, `workspaceSecondaryAction`, `overviewActiveForScreen`) samt Aufrufern, `fullscreenAutoHide`-Kette, `_bindsStale`, `duxinstall`-Dateilogger, veraltete Entwicklerwerkzeuge; davor eigener Commit: SettingsSearchRegistration |
| D1 | Go: Modulpfad, Binary `alpe-dienst`, Socket, Umgebungsvariablen; **kein Neustart von systemd-Units** (6.8) | zentrale Konstanten in `core/internal/brand`; Test zu 6.8 |
| D2 | Go/QML: Pfade `~/.config|state|cache/alpe`, System-Plugins, hypr-Ordner | zentrale Stellen `Paths.qml`/`brand` statt verstreuter Literale |
| D3 | App-ID, Desktop-Dateien, D-Bus-Namen, Icon | |
| D4 | KWin-Brücke `alpe-bridge`, Aktionen `alpe-*` | Test test_bridge.js angepasst |
| D5 | Einstellungen: Schlüssel/Werte + Migration | Test mit alter settings.json |
| D6 | Sichtbare Texte, Über-Seite, Brand.apply weg, Übersetzungen | |
| D7.N, D7.0–D7.8 | Node-Tests in test.sh; interne Namen, Widget-Bibliothek `Alpe*`, Plugin-Beschreibung, Plugins, Migration v44; Weiterleitungen weg (D7.8 erst nach Bestätigung) | **direkt nach D6, vor E1** (0.8 Nr. 6), Bereiche in 2.3.5; Halt nach D7, Mac-Test, dann 6.7 |
| E1 | Makefile, systemd-Unit, Desktop-Dateien; **PAM-Dienste, Richtlinien und alle paketierten Pfade mit `alpe`-Namen** (0.8 Nr. 16) | `make install DESTDIR` getestet in Temp-Wurzel; Dateiliste ohne Überschneidung mit dem Paket `dms`/`dux-shell` |
| E2 | PKGBUILD | CI-Bau |
| E3 | RPM-Spec; `dsearch` (dux-search) wird **optionale** Abhängigkeit, keine harte, weil die Dateisuche ohne das Programm läuft: `optdepends` im PKGBUILD, `Recommends:` in der RPM-Spec (0.8 Nr. 26) | CI-Bau x86_64 |
| E4 | Werkzeuge: `alpe` CLI, einrichten.sh, entwicklung, doctor/update/entfernen/backup, kde-sitzung, lockscreen, kuerzel, titelleisten, design.py | bestehende Tests nachgeführt |
| F1 | Umzug: `tools/umzug.py`, `install.sh`-Übergang, Testdaten, Test; Benutzerkopien ausgelieferter Plugins mit Rückweg zur Seite legen (0.8 Nr. 32) | |
| F2 | get.sh neu | Probelauf `--check` in Temp-`HOME` mit Attrappen |
| G1 | Doku, Brand 1.1, CHANGELOG, Namensprüfung + Ausnahmeliste; `Brand.version` auf 1.1 und **im selben Commit** `requires_alpe: >=1.1` für jedes Plugin, das Alpe ausliefert oder pflegt (`plugins/` im Repo, `~/alpe-plugins`; 0.8 Nr. 31). Bis dahin `>=1.0`, solange `Brand.version` noch 1.0 meldet | |

**Halte** (Zusammenfassung + Diffstat, dann Freigabe abwarten): nach A1, nach B3
(Baumvergleich), nach C5 (statt C4, siehe 0.5), nach D3 (0.6, abgenommen), nach D6, nach D7 (0.8), nach E4, nach F2, zuletzt G1. Vor B2 zusätzlich,
falls die Herkunft des KWin-Patches nicht als MIT belegt ist; vor C4 wegen Tailscale; vor E1 mit
der Vorlage 6.7.

Danach Zusammenfassung mit fish-tauglichen Testanleitungen (VM «frisch», PC-Umzug, Mac-Umzug,
Messung Speicher/Startzeit vorher/nachher mit `alpe doctor`). Kein Push, kein Tag.

Grössenordnung: B1 ≈ 2800 Dateien (inkl. Schriften, Übersetzungen). Umbenennungen laufen
skriptbasiert und nachvollziehbar; geprüft wird nach 0.7 Nr. 6.

---

## 11. Risiken

| Risiko | Gegenmassnahme |
|---|---|
| Umbenennung von Tausenden Bezeichnern bricht unauffällig etwas (QML meldet Fehler erst zur Laufzeit) | volle Ladeprüfung (9), Namensprüfung, kleine Commits; externe Schnittstellen zuerst, interne zuletzt und abschaltbar |
| Kürzel gehen beim Umzug verloren oder kollidieren | Reihenfolge 7.2/6, Tasten vorher protokolliert, Rückweg |
| Zwei Shells gleichzeitig (`BusName` Mitteilungen, Leisten doppelt) | Umzug stoppt `dms.service` vor dem Start von `alpe.service`; `alpe doctor` warnt |
| Einstellungs-Migration verliert Werte | Shell sichert `settings.v<N>.json`; Umzug sichert alles; Test mit echter (anonymisierter) Datei |
| Quickshell unter Fedora zu alt / aus fremdem COPR | eigenes COPR (Frage 7); `alpe doctor` prüft Version ≥ 0.3.2 |
| jemalloc/16-KB-Seiten auf Asahi | vor Ausrollen am Mac prüfen |
| Go ≥ 1.27.3 im COPR ohne Netz | vendorter Tarball, Go-Version der Chroots prüfen |
| Keine Ursprungs-Korrekturen mehr (auch Sicherheit) | bewusster Preis der Abspaltung; ich notiere in `docs/technik.md`, wie man einzelne Ursprungs-Commits gezielt prüft (Liste beobachteter Bereiche: PAM/Sperre, Mitteilungen, Netzwerk) |
| Sperrbildschirm: Nutzerkopie verdeckt Systempaket, oder Systempaket lädt nicht → blaues Notdesign | Umzug verschiebt Nutzerkopie, `lockscreen.sh install` schaltet nur nach erfolgreicher Probe um |
| Hyprland-Konfiguration am Mac weicht von der Annahme ab | Umzug ändert nur erkannte Zeilen, alles andere als Hinweis; Mac-Dateien vorher ansehen (Frage 7/8) |
| AUR-Name `alpe-shell` vergeben | vor Veröffentlichung prüfen (Maintainer) |
| Ich arbeite auf dem PC, auf dem Alpe läuft | Ich fasse `~/dux-shell`, Dienste, KWin, kglobalaccel und `$HOME` nicht an; alle Läufe in Temp-`HOME`; reale Umzüge macht der Maintainer |
| Speicher/Start schlechter | Ohne Einbettung entfällt das Entpacken; weniger Code lädt; trotzdem vorher/nachher messen (Abnahme 7) |

---

## 12. Offene Fragen an den Maintainer (beantwortet, siehe 0.4)

1. **Namen:** CLI `alpe` (Bash) + Dienst `alpe-dienst` (Go), wie in 2.1 begründet – einverstanden?
   Oder `alped`/`alpe-core`?
2. **App-ID / Reverse-Domain:** `io.github.alpe_shell.Alpe` (übliche Form für GitHub-Organisationen)
   – oder hast du eine eigene Domain (z. B. `ch.…`)?
3. **Repo-URL** überall auf `github.com/alpe-shell/alpe` umstellen und `phase-a` vor dem Start auf
   `origin/main` (e3de976) setzen – einverstanden?
4. **Übersetzungen:** nur Deutsch (+ Englisch als Quelle) behalten?
5. **Grenzfälle (4.3):** Greeter weg? Ursprungs-Aktualisierung/Changelog/Willkommen weg?
   Plugin-/Theme-Browser ausblenden? **Nutzt du Tailscale?** VS-Code-vsix weg?
6. **Tiefe der Umbenennung:** auch rein interne Bezeichner (`DMSService` → …, `DankBar` …, ≈ 4000
   Stellen) in Phase A? Die Abnahme («grep trifft nur Herkunft») verlangt es; Alternative wäre,
   interne Namen als Ausnahme zu führen und in Phase B mit dem Neubau zu erledigen. Meine
   Empfehlung: ja, skriptbasiert in D7, weil es danach nie billiger wird. → Geändert in 0.7 Nr. 3:
   D7 entfällt; **zurückgenommen in 0.8:** D7 nach D6 mit eigenem Halt (2.3).
7. **Fedora:** eigenes COPR mit nachgebautem Quickshell (+ matugen), oder fremde COPRs als
   Abhängigkeit? Und bitte vom Mac (fish):
   `rpm -qi quickshell matugen`
   `dnf repolist`
   `ls -la ~/.config/hypr ~/.config/hypr/dms`
   `grep -rn dms ~/.config/hypr`
   `systemctl --user cat dms.service`
   `alpe version`
8. **Hyprland-Start:** weiter `exec-once = alpe-dienst … run` (wie heute) oder über
   `alpe.service` (setzt eine `graphical-session.target` unter Hyprland voraus, z. B. uwsm)?
   Empfehlung für 1.1: `exec-once`, keine zweite Baustelle. → Nach dem Mac-Test geändert:
   `alpe.service` über `hyprland-session.target` (0.6 Nr. 1).
9. **dux-go / dux-gop** als Go-Abhängigkeiten behalten (Ausnahme in der Namensprüfung) oder
   vendoren und umbenennen (= weiterer Fork von ~2 MB Code)? Empfehlung: behalten.
10. **AUR:** Veröffentlichst du `alpe-shell` im AUR (und später `alpe-shell-git`)? Bis dahin baut
    `get.sh` aus dem PKGBUILD im Repo.
11. **Alte Ordner** (`~/.config/dms`, `~/.local/state/dms`, `~/.cache/dms`, `~/.config/hypr/dms`)
    nach dem Umzug liegen lassen bis `alpe umzug aufraeumen` – oder gleich löschen?
12. **`~/alpe` am Mac** nach dem Umzug entfernen (Benutzer brauchen es nicht mehr) oder liegen lassen?
13. **Release v1.0:** Das angehängte Archiv stammt von dd66c9d, nicht vom Tag-Commit. Willst du es
    ersetzen (`gh release upload v1.0 … --clobber` mit einem Archiv aus c988364 – mache ich nicht
    selbst) oder so lassen?
14. **Bilder** in `design/kde/bilder/` (`wallpaper.jpg` vom Februar 2026, `wall.png`,
    `jagged-peaks-wolkenzug.mp4`): bestätigst du, dass alle drei von dir stammen bzw. frei sind?
15. **caelestia-Hinweis** in `sourcecolor.go`: nur übernommene Gewichtungszahlen (ursprünglich aus
    Material Color Utilities, Apache 2.0). Reicht dir ein Herkunftsvermerk in `NOTICE`?
16. **KWin-Patch v4:** Von wem stammt die ursprüngliche Fassung, und unter welcher Lizenz (PR an
    DMS → MIT)? Ich nenne die Person in `NOTICE`, sofern du nichts dagegen hast.
17. **`dux-gop`/`dgop`** am Ende des Umzugs mit zum Entfernen anbieten? (Wird nach meiner Prüfung
    nicht gebraucht.)
