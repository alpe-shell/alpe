# Phase A – Plan zur Umsetzung (Alpe 1.1 «Zugerberg»)

Stand: 21. November 2026, Branch `phase-a`. **Freigegeben am 21.11.2026** mit den Entscheiden in 0.4. Grundlage: `docs/plan/phase-a.md`, `CLAUDE.md`,
`KONTEXT.md`, Erkundung von `~/alpe` (Commit c988364) und `~/dux-shell` (Branch `alpe` =
v2.1.2 + 2 Schichten). Umgesetzt bis D6 (Halt), siehe «Stand»; Entscheide nach D3 in 0.7, nach D6 in 0.8 (D7 wieder
aufgenommen, Abschnitt 2.3); offene Einzelfälle in
`docs/plan/offene-faelle.md`.

---

## Stand (24.11.2026, Halt nach D7 abgenommen, Mac-Test auf `b04b1bf` bestanden; Runde nach dem Mac-Test umgesetzt, Halt vor E1; 6.7 vollständig entschieden; kora, Papierkorb und Dock entschieden)

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
| D7.6/D7.7 (Auflagen) | Go-Tests lesen die Oberfläche unter `shell/` statt am Ursprungspfad `quickshell/`: die drei bekannten Fehlschläge sind grün, der Katalogtest der Hyprland-Kürzel läuft jetzt mit (0.8 Nr. 49). `i18nsync.py`/`i18nsync_plugins.py` entfernt (kein Aufrufer in test.sh, Skripten oder CI); **Übersetzungen werden ab jetzt nur im Repo gepflegt** (`shell/translations/poexports/de.json`, Quelltexte `en.json`) | test.sh grün; Go-Tests ohne bekannte Fehlschläge; qmllint (Qt 6.12) über `shell/`: vor D7.7a wie danach dieselben Meldungen, keine neue (Zahl: 0.8 Nr. 63) |
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
| D7.7h | Dienst intern: übrige Pakete (`duxerrdefs`, `RequiresAlpe`/`requires_alpe`, Zwischenablage `/var/tmp/alpe/clipboard`, Sperr- und Temp-Namen `alpe-*`, **Layer-Namensräume `alpe-colorpicker`, `alpe-screenshot`** (F1: 7.4 Schritt 6), `netfetch`: User-Agent `Alpe/1.0`, Release-Adressen des eigenen Repos), `core/README.md`, Tabellen `d7-7h-uebrige.tsv`, `d7-7h-texte.tsv`. **Attrappen neu erzeugt** mit mockery 3.9.1 über die eigene Vorlage `core/.mockery/testify.templ` (0.8 Nr. 62; NOTICE). Ausnahmeliste: `.dankrev` (Dateiname von dux-go vorgegeben, Phase B), fremde Lexer-Definitionen, `%dms`. **Im Dienst bleibt kein Fund ausserhalb der Ausnahmeliste.** | **`go vet ./...` ohne Meldung**, go build ohne Meldung, `go test ./...` abgeschottet: 54 Pakete grün, kein Fehlschlag; `tests/test_werte.py` (kein Paketverzeichnis mit altem Namen, go.mod nur dux-go/dux-gop, Attrappen aus der Vorlage und ohne Expecter für MarshalJSON); test.sh grün |
| D7.7i | Werkzeuge (0.8 Nr. 52): `tools/alpe` (Dienst `alpe-dienst` zuerst gesucht und erkannt), `backend.sh` (Befehl `alpe-dienst`; ein neuer Bau muss sich als `alpe-dienst <Version>` melden), `maclock.sh` (**`alpe-dienst ipc call lock lock`**), `entfernen.sh`. Verweise auf die Einrichtung von 1.0 (`dms.service`, `~/.local/bin/dms`, Ordner von DMS, `dms run`) bleiben mit Kommentar am Ort und je einem Eintrag auf der Ausnahmeliste (Frist Umzug-Ende; keine Ausnahme für ganze Dateien). **`maclock.sh` überspringt Sicherungsordner** (`.dms-backups`, `.alpe-backups`; 0.8 Nr. 57) – vorher hätte es `hyprlock`-Aufrufe auch in Sicherungen umgeschrieben. Ausnahmeliste: Tests, die alte Namen als Testdaten oder zur Gegenprobe führen | `tests/test_maclock.py` (neuer Aufruf, Sicherungsordner unverändert); test.sh grün |
| – | **Ladeprüfung mit allen Repo-Plugins** (0.8 Nr. 33): Im Temp-HOME werden alle Plugins unter `plugins/` eingeschaltet (heute vier, auch claudeCodeUsage). Neu `--plugins ORDNER[,…]` (Kopien fremder Plugins, 0.8 Nr. 29) und `--probe-zeichen` (Starter-Knopf mit Logo-Modus `"alpe"`, Session aus 1.0 mit Material-Vorlage und einfarbigem Hintergrund; nach dem Lauf wird geprüft, dass die Shell die Session auf Version 8 umgezogen, `session.v7.json` geschrieben und `alpeLogo` eingesetzt hat; 0.8 Nr. 41, 45). **qmllint-Haltprüfung** `entwicklung/qmllint/qmllint-pruefung.py` mit `grundlinie.txt` (4902 Meldungen, Befund in 0.8 Nr. 63); `mklint.py` nimmt ein Ziel; `CLAUDE.md` nachgeführt | `tests/test_ladepruefung.py`; test.sh grün; Ladeprüfung auf diesem Stand: KWin 29/29, Hyprland 38/38, nichts neu, nichts weg (Grundlinien unverändert) |
| – | **Zwischenhalt nach D7.7** (22.11.2026). Ladeprüfung mit den vier Repo-Plugins, den angepassten Kopien von hueManager, calculator, sathiAi und `--probe-zeichen`, je KWin und Hyprland, auf dem Stand D7.7 und mit einer nicht committeten Probekopie von D7.8 (180 Dateien weg: `Dank*`-Hüllen, `DCommon/Widgets`, `Modules/DankBar`, `Modules/DankDash`, `Deprecation.qml`): **beide Stände gleich**, alle sieben Plugins laden. Neu gegenüber der Grundlinie nur: zwei Meldungen aus dem eigenen Code der fremden Plugins (hueManager `Color.js` «used before its declaration», sathiAi `Sathi.qml` «Unable to assign [undefined] to bool»), unter Hyprland dazu die Farbmeldungen des einfarbigen Probe-Hintergrunds und eine Qt-Meldung `textinput … disableSurface`. Probe: Session aus 1.0 auf Version 8 umgezogen und zurückgeschrieben (`session.v7.json`), Vorlage `alpe`, Form `alpeLogo`, Starter-Knopf mit Logo-Modus `alpe`. Die Probe vervollständigt das eigene Profil der Testdaten (sonst verwirft die Shell es beim Laden). qmllint: D7.7 4902/4902, D7.8-Probe 4900, keine neue. matugen echt gerendert (Sandbox, dunkel und hell): alle Vorlagen, kein offener Platzhalter, alte Namen nur bei Neovim; mit Dateien aus 1.0 entstehen Links bzw. zweite Fassungen. `Theme.dank16`: in keinem fremden Plugin. **Offen vor D7.8:** 166 Fundstellen der Namensprüfung ausserhalb der Dateien, die D7.8 entfernt (66 in `SettingsStore.js`, Übersetzungen, Harness-Kopien) | test.sh grün |
| – | **Nachprüfungen zum Zwischenhalt** (22.11.2026, vor D7.8a). **1. `tools/test.sh` auf `d981ca2`** nachgeholt (Temp-Worktree, eigenes HOME/XDG, Go-Caches übernommen): grün, 31 Schritte, nichts übersprungen. **2. CUPS-Tests und der echte cupsd:** `go test ./internal/server/cups ./pkg/ipp` spricht nur die IPP-Attrappe an (`pkg/ipp` hat keine Tests). Belege: (a) im Quelltext entsteht jeder Client der Tests aus `httptest` (`127.0.0.1:<Zufallsport>`), `NewManager`, `NewPkHelper` und der System-Bus werden von keinem Test erreicht; (b) das Testprogramm läuft in einem eigenen Netz- und Mount-Namensraum, in dem `/run/cups` und `/run/dbus` verdeckt sind, vollständig durch (107 bestanden, 0 fehlgeschlagen, 0 übersprungen), und ein Lauscher auf `127.0.0.1:631`/`[::1]:631` zählt dabei 0 Verbindungen (Selbstprobe des Lauschers: 1); (c) `access_log` von cupsd seit 01:38: zwei `Create-Printer-Subscriptions` – 11:55:01 (Nr. 198, Anmeldung; Auftragsereignisse, 3600 s, nicht die Ereignisliste des Dienstes) und 14:30:56 (Nr. 199, laut Journal vom laufenden 1.0-Dienst für die laufende Shell angelegt und um 14:31:13 von ihm gekündigt); (d) lesend über IPP (`Get-Subscriptions`) besteht nur Nr. 198; in `~/.local/state/alpe` liegt keine Marke der Kündigung. Kein neues Abonnement. Der genaue Zeitpunkt des damaligen Laufs mit echtem HOME lässt sich nicht rekonstruieren; belegt ist, dass jedes `Create` im Protokoll einen anderen Urheber hat. **3. Gegenprobe zu den Meldungen des Zwischenhalts** (sechs Läufe, je KWin und Hyprland): unveränderte Originale von hueManager (`4492939`) und sathiAi (`e6dfc24`) auf `ba4ddbc` (vor D7.2a); Endstand nur mit `--probe-zeichen`; Endstand nur mit den angepassten Kopien. Zuordnung jeder Meldung: hueManager `Color.js` «used before its declaration» und sathiAi `Sathi.qml` «Unable to assign [undefined] to bool» – **eigener Code der Plugins**, erscheinen mit den Originalen vor D7.2 unter beiden Compositors genauso und ohne Probe mit den angepassten Kopien; **nicht von der Anpassung**, die Anleitung bleibt darin unverändert. `CachingImage … Cannot open …imagecache` weg (KWin, Hyprland) – **Probe** (einfarbiger Hintergrund statt Bild; fehlt auch im Lauf nur mit Probe, nicht im Lauf nur mit Plugins). Hyprland `Theme worker: Building theme: hex #1d2a33` und `Using dynamic theme from hex` neu, `Building theme: image …`, `Seed color: …` und `Using dynamic theme from image …` weg – **Probe** (Farbe statt Bild als Quelle des Themas). Hyprland `qt.qpa.wayland.textinput … disableSurface` neu – **tritt nur mit der Probe auf** (bis zum Halt in 6 von 7 Läufen mit Probe, in keinem von 4 ohne; unabhängig von den Plugins, und auch auf `ba4ddbc` vor D7.2 mit derselben Probe – also nicht aus D7); welcher Teil der Probe sie auslöst, ist nicht eingegrenzt. Damit ist KWin +2/−1 und Hyprland +5/−4 vollständig zugeordnet; keine Meldung stammt aus D7. Nebenbefund: Die nach Anleitung erzeugten Fassungen sind bytegleich mit den geladenen Kopien (hueManager bis auf eine doppelte Importzeile in der geladenen Kopie, sathiAi bis auf die lokalen Änderungen des Maintainers, calculator bis auf den Änderungsvermerk). **4. qmllint:** eingechecktes Skript über `shell/` von `6305cb1`: 4902 Meldungen – das ist die Grundlinie (0.8 Nr. 63). Entscheide 0.8 Nr. 64–69 | – |
| D7.8a | **Vorstufe (0.8 Nr. 64–68).** *Namensprüfung:* Marken `alpe-namen-ausnahme: umzug-ende` (Anfang und Ende) nehmen einen Bereich aus; `--bereiche` listet sie; ein Zeilenmuster der Ausnahmeliste gilt auch für den Dateinamen. *Dienst:* User-Agent `brand.UserAgent()` = `Alpe/<Version dreistellig> (+Repo)` für Liedtexte, Wetter und `netfetch` (Version über das Makefile aus `Brand.qml`, sonst `Alpe/dev`; `alpe-dienst dl --help` nennt ihn); Layer-Namensräume `alpe:colorpicker`, `alpe:screenshot`; `internal/version` nur noch `CompareVersions`, `netfetch/release.go` und die Attrappe `mocks/version` weg; `make -C core mocks` mit mockery v3.9.1. *Oberfläche:* **167 Fundstellen einzeln eingeordnet** (`entwicklung/umbenennen/d7-8a-fundstellen.tsv`): 69 Migration (8 Bereiche mit Marke in `SettingsStore.js`, `AudioService.qml`, `alpe-bridge.js`, `alpe-perf.py`; der Zeileneintrag für v43 in der Ausnahmeliste entfällt dafür), 55 umbenannt (`d7-8a-texte.tsv`: Kontexte für Übersetzende in QML, `en.json`, `template.json`; Kommentare, Meldungen, Testdaten; drei veraltete Kopien unter `entwicklung/pageharness/qs/` durch den Stand aus `shell/` ersetzt; `settings_search_index.json` neu erzeugt), **3 behoben, weil der alte Name wirkte:** Notizblock «In die Zwischenablage» rief `dms clipboard copy` (jetzt `alpe-dienst`), die Meldung zum Terminal-Rückfall nannte `dms auth sync`, die Auswahl des Punkt-Symbols zeigte «Dux» für den Modus `alpe`; 40 auf der Ausnahmeliste (15 neue Einträge, je mit Frist). Nicht umbenannt und als Frage in `offene-faelle.md`: WirePlumber-Datei `51-dms-audio-aliases.conf` (F1), Übersetzungsskripte des Ursprungs (G1). Testdaten der Einrichtung von 1.0 in den Harness-Szenen (`component: "dms"`, `dms.service`) bleiben wie in `tests/test_kwin.py` bis E4. **Ausserhalb der Dateien, die D7.8 entfernt, meldet die Namensprüfung nichts mehr** | `tests/test_umbenennen.py` (Marken, Dateiname), `tests/test_werte.py` (User-Agent, Layer-Schema und Regeln der Hyprland-Vorlage, toter Code weg, mockery-Version), `tests/test_version.py` (User-Agent des gebauten Dienstes), Go-Test `internal/brand`; go build und `go vet ./...` ohne Meldung; test.sh grün |
| D7.8 | **Hüllen und Weiterleitungen weg** (180 Dateien, dieselbe Liste wie in der Probe zum Zwischenhalt): 44 `Dank*`-Hüllen (`shell/Widgets`, `shell/Common`, `shell/Modals/Common`), 88 Dateien `shell/DCommon/Widgets/`, `shell/Modules/DankBar/` (33), `shell/Modules/DankDash/` (14), `shell/Common/Deprecation.qml`. Ein unangepasstes fremdes Plugin lädt damit nicht mehr (`docs/plugins-anpassen.md`). **Die Namensprüfung ist streng:** `tools/test.sh` ruft `namen-pruefen.sh --streng`; 0 Fundstellen ausserhalb der Ausnahmeliste (101 Einträge, 8 Bereiche mit Marke). Der Eintrag für `shell/DCommon/Widgets/*` ist von der Ausnahmeliste gestrichen | `tests/test_werte.py` (keine Hülle, kein Aufruf von `Deprecation`, test.sh streng); test.sh grün |
| – | **Halt nach D7** (22.11.2026, Endstand nach D7.8). **Ladeprüfung** mit allen vier Repo-Plugins: KWin 29/29, Hyprland 38/38, nichts neu, nichts weg – die Grundlinien bleiben unverändert. **qmllint:** 4900 Meldungen über 1013 Dateien gegen die Grundlinie 4902: keine neue, zwei weg (`Modules/Lock/Lock.qml`, `missing-property` und `redundant-optional-chaining` zu `QuickshellScreenInfo`); die Grundlinie bleibt bei 4902. **Namensprüfung** streng und grün (0 Fundstellen). **`go vet ./...`** ohne Meldung, `go test ./...` abgeschottet: 55 Pakete grün (mit kurzem Temp-HOME; mit einem langen Pfad scheitern `dmenuipc` und ein Test in `server/network` an der Länge des Socket-Pfads). **Nebenbefund behoben:** Die Hilfe des Dienstes zeigte den Schriftzug des Ursprungs als Blockgrafik (für die Namensprüfung unsichtbar) – jetzt «ALPE», mit Test. **Bildschirmfoto im verschachtelten Hyprland** (neu `--bild DATEI`; **grim ist am PC nicht installiert**, das Bild stammt darum von `alpe-dienst screenshot full` – mit grim wird es benutzt, sobald es da ist): Starter-Knopf oben links mit dem Alpe-Zeichen (Logo-Modus `alpe`), als Hintergrund die Material-Vorlage «Alpe» mit der Form `alpeLogo` (zwei Gipfel) rechts. **Zwei Fehler der Probe selbst dabei gefunden und behoben:** (1) Das ausgelieferte Design sperrt beim Start (`lockAtStartup`), das erste Bild zeigte nur den Sperrbildschirm – jede Ladeprüfung läuft also hinter der Sperre; für `--bild` wird sie im Temp-HOME ausgeschaltet, die Vergleichsläufe bleiben wie bisher. (2) `--probe-zeichen` setzte eine Hintergrundfarbe; die Shell zeichnet die Material-Vorlage aber nur ohne Bild und ohne Farbe. **Die Form war darum am Zwischenhalt nie zu sehen** – geprüft war dort nur der Umzug der Session-Datei. Die Probe lässt den Hintergrund jetzt leer. **Offen, nicht eingeordnet:** Mit sichtbarer Material-Vorlage meldet die Shell neu `QML SettingsSearchRegistration at @Modules/Settings/Widgets/SettingsRow.qml: Cannot find member data` (1 Lauf, Hyprland). Auf `ba4ddbc` (vor D7.2) erscheint sie mit derselben Probe nicht – sie ist also zwischen D7.2a und D7.8 entstanden oder hängt an etwas, das die Probe dort anders trifft; der Commit ist noch nicht eingegrenzt, unter KWin nicht geprüft. Bis das geklärt ist, gilt der Halt in diesem Punkt als nicht abgeschlossen. Mac-Test-Anleitung für den D7-Stand in `offene-faelle.md` | `tests/test_ladepruefung.py`, `tests/test_werte.py`; test.sh grün |
| – | **Abschluss des Halts nach D7, Zwischenstand** (22.11.2026, abends; **noch nicht abgeschlossen**). **Commits:** `5a8c5ec` Ladeprüfung in den Varianten «gesperrt»/«offen», Bild nur mit `alpe-dienst screenshot full`; `261c454` Layer `alpe:eyedropper`; `a3aa8ff` Übersetzungsskripte; `7b1c670` WirePlumber bei F1; `c84edb6` Einstellungssuche; `2c9de8c` sporadische Meldungen in Grundlinien; `d19788e` Lauf ohne Hyprland-IPC gilt als gescheitert; danach die Abdeckungs-Zusätze der Variante «offen» (0.8 Nr. 77). **`tools/test.sh` auf dem Commit selbst im Temp-Worktree** (0.8 Nr. 72): `a364d81`, `46941e1`, `c29f610`, `5a8c5ec`, `261c454` grün mit 31 Schritten; `a3aa8ff`, `7b1c670`, `c84edb6`, `2c9de8c`, `d19788e` grün mit 32 Schritten (neu `tests/test_uebersetzung.py`), nichts übersprungen. **Übersetzungsskripte eingeordnet (0.8 Nr. 74):** entfernt `check_term_freeze.py` (Textsperre vor dem Abgleich), `replace_qstr.py` (einmaliges Umschreiben auf das Schlüsselschema des Übersetzungsdienstes), `template.json` (Importvorlage); behalten und angepasst `extract_translations.py` (liest jetzt auch `Alpe/` – seit D7.2 lagen dort Dash und Dateiwähler, `en.json` war darum unvollständig: 81 Einträge fehlten, 5 waren überzählig; schreibt ohne Zeilennummern; `--pruefen`), `check_term_variants.py` (Prüfung der Quelltexte), `extract_settings_index.py` (erzeugt den Suchindex, unverändert). 42 Texte ohne deutsche Übersetzung stehen in `tests/data/uebersetzung-bekannte-luecken.txt`. **`Cannot find member data` (SettingsRow):** kein Fehler aus D7 – in `offene-faelle.md` schon auf `d3343e9` (29 Commits vor `ba4ddbc`) geführt; kein Bisect (0.8 Nr. 76). Behoben in `c84edb6` als eigener Commit (Registrierung als Eigenschaft statt als Kind in `data`). **Belegt ist die Behebung durch den Strukturtest in `tests/test_werte.py`; die Messläufe stützen sie nur**, weil bei einer Rate um ein Drittel wenige Läufe allein nichts beweisen. Gültige Messung unter KWin, Variante «offen» (noch ohne Zusätze): `ba4ddbc` 1 von 3 Läufen mit der Meldung, mit Behebung 0 von 3. **Ungültig: die Hyprland-Raten dieser Sitzung** (Endstand 1 von 3, `ba4ddbc` 0 von 3, mit Behebung 0 von 4) – diese Läufe liefen ohne Hyprland-IPC; die Hyprland-Rate wird mit der Neumessung auf gültigen Läufen erhoben. **Hyprland-IPC:** Mit `ALPE_LP_TMP=/tmp/claude-1000/h7/lp` (in dieser Sitzung gesetzt) wurde der Pfad von `.socket2.sock` 111 Zeichen lang; Hyprland startete ohne IPC («path is too long»), die Shell meldete sechs Zeilen `ServerNotFoundError`. `HYPRLAND_INSTANCE_SIGNATURE` und `XDG_RUNTIME_DIR` kamen an; `b28b002` hat an der Startreihenfolge nichts geändert. **Gültig** (mit IPC, 38 Meldungen, belegt durch das Fehlen dieser Zeilen im Vergleich): die Hyprland-Läufe von 01:31, 14:49 (Zwischenhalt nach D7.7, 38/38), 15:02, 16:17, 16:39 (Halt nach D7, 38/38) und 20:19; 17:08 (`ba4ddbc`, Probe) ohne Vergleichszeile, nicht belegt. **Ungültig und zu wiederholen:** alle Hyprland-Läufe von 17:53 bis 20:07 (19 Läufe, beide Varianten, Endstand und `ba4ddbc`) samt der daraus geschriebenen Grundlinie «offen». KWin ist nicht betroffen: «gesperrt» 29/29 ohne Neues. **Vergleich «offen»/Hyprland Endstand gegen `ba4ddbc`** (aus den ungültigen Läufen, nur als Anhalt): fünf Zeilen unterscheiden sich nur in umbenannten Namen (`alpe-floating-windows`, `FileSearchService`, `palette16`, `BarTab.qml`, `colors.json`), dazu die sporadische SettingsRow-Meldung. **qmllint** 4900 gegen 4902, keine neue, dieselben zwei weg; **`go vet`** ohne Meldung; **Namensprüfung** streng und grün (100 Einträge der Ausnahmeliste). **Bilder «offen»/Hyprland mit Zusätzen und IPC:** `ba4ddbc` und Endstand zeigen oben links die Arbeitsflächen-Pille und den Starter-Knopf mit dem Alpe-Zeichen, in der Mitte Uhr und Wetter («--°C»), rechts Lautsprecher (stumm) und Mikrofon; als Material-Vorlage auf `ba4ddbc` das Zeichen des Ursprungs, auf dem Endstand das Alpe-Zeichen mit zwei Gipfeln (`alpeLogo`). **Offen und vor der Abnahme zu entscheiden** (`offene-faelle.md`, «Ladeprüfung»): Unter dem verschachtelten Hyprland verbindet sich die Oberfläche nie mit dem Dienst (er bleibt bei `Attempting to initialize Wayland gamma control...` stehen) – darum sind `cpuTemp`, `gpuTemp`, `cpuUsage` links unsichtbar; gleich auf `ba4ddbc`, also kein Fehler aus D7, aber eine Lücke der Hyprland-Prüfung seit jeher. **Noch ausstehend:** Grundlinien «offen» (KWin, Hyprland) und «gesperrt» (Hyprland) mit Zusätzen und IPC auf `ba4ddbc` und Endstand neu messen, SettingsRow-Rate unter Hyprland daraus, Grundlinien committen, Halt abschliessen. | `tests/test_ladepruefung.py`, `tests/test_werte.py`, `tests/test_uebersetzung.py` |
| – | **Runde nach dem Mac-Test** (24.11.2026; Mac-Test auf `b04b1bf` am 23.11.2026 **in Ordnung**, Ergebnis, Plattform-Fall Nachtlicht und Zwischenfall in `offene-faelle.md`, «Mac-Test»). **Commits:** `a95f6a1` Ergebnis; `24d3d26` `docs/plugins-anpassen.md` (absolute Pfade, kein `cd`, Rechner und Prüfbefehl je Block, Import-Prüfung ohne Pipe, Hinweis zum Verlauf des calculator; Tabellenkopf und «### calculator» standen nicht doppelt); `5d4eabc` Mac-Test-Anleitung; `7e55586` Codec-Test überspringt sich ohne `lua`; `4ac9a6c` Werteprüfung mit Rechnernamen wie «Asahi»; `09021df` CUPS-Ausfall einmal melden, dann Rückzug 5 s bis 1 min; `6b2bb9c` SVG-Prüfung; `899fefc` `hyprlock.conf` ohne `eDP-1`; `19a16c4` Design ohne vier matugen-Vorlagen; `d3602df` Bild unter KWin (Weg A) und `--bild-sperre`; `5f1a4e9` Drucker-Testseite neu; `8be2e75` `NOTICE`; `54bb5c0` qmllint-Grundlinie 4900, `CLAUDE.md`. Befunde und Auflagen: 0.8 Nr. 96–106, 6.2–6.4, Abschnitt 10 (E2–E4, F1). **«Connected» im Protokoll:** keine Verbindungsabbrüche – die Oberfläche schreibt die Zeile bei jedem `server`-Ereignis: nach jedem neuen Aufbau der Abonnement-Verbindung (`ShellBackend.subscribe`, ausgelöst durch jedes `addSubscription`/`removeSubscription`, etwa `cups`, und durch neu erschienene Fähigkeiten) und bei jeder Meldung geänderter Fähigkeiten des Dienstes; die Anfrage-Verbindung bleibt stehen. Im Lauf mit stummem Systembus steht die Zeile in zwei Minuten zehnmal. `git worktree prune` hat den verwaisten Eintrag `wt-alt` entfernt. **Haltprüfung auf `54bb5c0`:** Ladeprüfung KWin «gesperrt» 39/39, KWin «offen» 38/38, Hyprland «gesperrt» 39/39, je nichts neu, nichts weg; **Hyprland «offen»: in vier Läufen drei Meldungen ausserhalb der Grundlinie, je in einem Lauf** (Notizblock-Paar, `DeferredAction` «stop of null», `ShaderEffect` «source»), auf `b04b1bf` in drei Läufen keine – **nicht eingeordnet, Grundlinie unverändert** (seither entschieden, 0.8 Nr. 107: nicht in die Grundlinie; mit zwölf ruhigen Läufen ohne fremde Meldung gilt die Haltprüfung auf `54bb5c0` für Hyprland «offen» als bestanden), Fall in `offene-faelle.md` («Ladeprüfung», Nachtrag vom 24.11.2026). Gegenprobe mit stummem Systembus (KWin): bestanden. qmllint 4900/4900. `go vet ./...` ohne Meldung, `go test ./...` abgeschottet: 57 Pakete grün. **Bilder:** Hyprland «offen» – Arbeitsflächen-Pille, Starter-Knopf mit Alpe-Zeichen, Temperatur- und CPU-Anzeigen mit Werten, Uhr, Wetter, rechts Lautsprecher (stumm) und Mikrofon, Material-Vorlage mit dem Alpe-Zeichen (zwei Gipfel), Dock nur mit Papierkorb; KWin «offen» über Weg A dasselbe in 1920 × 1080; Hyprland Sperre – Stunden und Minuten gross übereinander, Datum, Passwortfeld auf unscharfem Bergbild. **Unter KWin gibt es kein Bild der Sperre:** `--bild-sperre` zeigt dort den Schreibtisch, weil die Test-Instanz mit `--no-lockscreen` läuft und unter KWin KDE sperrt (`offene-faelle.md`). **Offen beim Maintainer:** Pragmas in `shell.qml` (Nr. 97), Standbild der Sperre (Nr. 106), sporadische Meldungen, Bild der KDE-Sperre, Ergänzung von `CHANGES.md` in `~/alpe-plugins` (Vorschlag in der Haltmeldung) – *seither am 24.11.2026 entschieden: Pragmas entfernt (Nr. 97), Standbild angenommen (Nr. 106), sporadische Meldungen nicht in die Grundlinie (Nr. 107); siehe die Zeile «Nachtlauf» unten* | je Commit `tools/test.sh` im Temp-Worktree grün (32, ab `6b2bb9c` 33 Schritte) |
| – | **Nachtlauf vom 24.11.2026** (Nachrunde zum Halt vor E1; Bericht lokal in `docs/plan/nachtlauf-2026-11-24.md`, nicht im Repository). `e0f4a99` 2.1: `kwinbild.py` bricht bei `NoAuthorized` ab, Test je Abbruchbedingung durch `main()`, 0.8 Nr. 103 berichtigt (ScreenShot2 ohne Berechtigungsprüfung am Quelltext von KWin belegt); Nachbesserung nach dem Urteil des Prüfers im Folgecommit (auch «Adresse nicht eindeutig» und der Sitzungsbus ohne `--fremd` durch `main()` geprüft). `14618ae` 2.2: Werteprüfung meldet einen mehrdeutigen oder kurzen Rechnernamen auch im Rechnerfeld von Journal-Zeilen im Syslog-Format; Namen unter vier Zeichen werden nicht mehr übergangen, sondern wie mehrdeutige nur im Zusammenhang gesucht (Nachbesserung `dc72cf6`). 2.3 (dieser Commit): Werteprüfung durchsucht die 61 Binärdateien roh (Bytes und ohne NUL-Bytes für UTF-16) nach denselben Werten – kein Fund; 52 Textdateien mit anderer Endung (`.svg`, `.frag` …) bleiben undurchsucht und werden gezählt (`caab717`; Nachbesserung im Folgecommit: auch der Inhalt von Hex-Zeichenketten, wie PDF sie für Titel und Erzeuger schreibt, wird durchsucht). 2.4: `CLAUDE.md`, neuer Abschnitt «Dateien ändern» – nur mit Edit; geht Edit nicht, anhalten und den Grund nennen (Anlass: fünf Dateien waren am 23./24.11.2026 per `sed` oder Skript geändert worden, ohne dass Edit je gescheitert wäre; `d5c2a9d`). 2.5 (dieser Commit): `tools/test-commit.sh` – `tools/test.sh` auf einem Commit oder als Sammellauf, nur mit vollen Hashes (`HEAD`, Branch-Namen, gekürzte Hashes abgelehnt), Ausgabe und Protokoll nennen den geprüften Hash; `--gruen <Hash>` als Schranke vor der Haltprüfung (`CLAUDE.md`; `6f77e24`). `ef30b93`: Auflage aus der Gegenprüfung zu 2.3 (Testfall «Textendung mit NUL-Byte»). 2.6 (dieser Commit): `ladepruefung.py kwin --bild-sperre` bricht mit einer Meldung ab (Rückgabewert 2, kein Bau, kein Lauf), statt den Schreibtisch zu liefern (`73ab9c5`). 2.7 (dieser Commit): Haltbilder heissen `halt-<compositor>-<variante>.png` (`CLAUDE.md`); Bild der Variante «gesperrt» unter Hyprland auf `73ab9c5` aufgenommen (Ladeprüfung dabei 39/39, nichts neu); Bildsatz des Halts künftig Hyprland «offen», Hyprland «gesperrt», KWin «offen» (`70e7e73`). 2.8 (dieser Commit): `CLAUDE.md` – Ladeprüfungen nur in Ruhe, nie neben Tests, Builds oder anderen Läufen; Wiederholungsregel für die drei bekannten sporadischen Meldungen (bis zu zwei Wiederholungen in Ruhe, Zählung aller Läufe in den Bericht, jede andere fremde Meldung bleibt ein Fehler; `3b93621`). 3.1 (dieser Commit): sporadische Meldungen unter Hyprland «offen» nicht in der Grundlinie, sondern mit Zählungen in `offene-faelle.md`; Haltprüfung auf `54bb5c0` für Hyprland «offen» gilt als bestanden (0.8 Nr. 107; `9026a04`). 3.2 (dieser Commit): Pragmas `RenderControl` und `DiskCache` aus `shell/shell.qml` entfernt, die vier Grundlinien der Ladeprüfung um genau die zwei Warnungen «Unrecognized pragma» bereinigt (0.8 Nr. 97; `8e053b4`). 3.3 (dieser Commit): Nr. 106 angenommen, Standbild der Sperre als erster Schritt von E1 eingetragen (nichts gebaut; `712e34b`). 3.4 (dieser Commit): `NOTICE` nennt je CC-BY-Quelle (Hero Patterns, Musterdatei von MeteoSchweiz) Urheber, Lizenzverweis und ob die Datei verändert wurde (Radardatei: Prüfsumme gleich der im Katalog von MeteoSchweiz); Lizenzfeld der Pakete MIT, CC-BY-4.0 und CC0-1.0 in 6.2, 6.3 und Abschnitt 10 (`09b1012`). 3.5 (dieser Commit): dnf in 0.8 Nr. 99 berichtigt – bei gleicher Priorität gewinnt die höhere Version, `cost` entscheidet nur zwischen Repos mit demselben Paket in derselben Version; die Folgerung für die Spec bleibt (`459b8e0`). Nachbesserung zu 3.4 (dieser Commit, dazu Auflagen aus den Gegenprüfungen zu 3.1 bis 3.3, die schon `09b1012` teils einlöste): `NOTICE` zu Hero Patterns nach dem Vergleich mit den Download-Dateien der Website (unverändert bis auf einen Zeilenumbruch am Dateiende bei sechs von sieben); offene Frage zum Lizenzfeld der Pakete in `offene-faelle.md` (`d6411d0`). 3.6 (dieser Commit): `wireplumber` bleibt harte Abhängigkeit, Begründung in 0.8 Nr. 96; der Zweig mit `pkill -x wireplumber` in `AudioService.qml` als Aufgabe für E in `offene-faelle.md` (nicht geändert; `19b5f88`). Nachbesserung zu 3.5 (dieser Commit): in 0.8 Nr. 99 steht jetzt, worauf sich die Aussage zu `cost` stützt (Handbuch wörtlich anders; Entscheid des Maintainers, gestützt durch libsolv; ein Schritt nicht nachgeschlagen); dazu der Verweis auf die offene Lizenzfrage in 6.2 und bei E2 (`87b58fc`). 3.7 (dieser Commit): Aufgabe «Bild der KDE-Sperre über `kscreenlocker_greet --testing` im Test-Scope» mit Aufwand eingetragen (0.8 Nr. 108; Alpe liefert das Paket `lockscreen/org.alpe.desktop/` aus), nichts gebaut (`41434f0`). 3.8 (dieser Commit): Liste für den nächsten Mac-Test in `offene-faelle.md` ergänzt (hyprlock ohne `eDP-1`, matugen-Vorlagen aus, CUPS-Rückzug, Passwortfeld und Streifen im Bild der Sperre); dazu Auflagen aus den Gegenprüfungen zu 3.5 (dnf5-Quelle in Nr. 99) und 3.6 (genaue Bedingung des `pkill`-Zweigs). `CHANGES.md` im Plugin-Repo ausserhalb dieses Repos folgt getrennt (`508d768`; im lokalen Repo `alpe-plugins` danach Commit `7c2e349` auf `main`, nicht gepusht: `calculator/CHANGES.md` nennt den Vermerk am Anfang von `README.md`). Nachbesserung zu 3.7 (dieser Commit): in 0.8 Nr. 108 die Art des Fensters der KDE-Sperre im Testmodus berichtigt (Layer-Shell-Fläche, nach dem Quelltext von kscreenlocker), Bildname als Vorschlag gekennzeichnet. Die Nachbesserung zu 3.8 (Mac-Liste: welche `hyprlock.conf` geprüft wird, Ort und Wortlaut der CUPS-Warnung, matugen-Punkt am Mac nicht prüfbar) folgt als eigener Commit (`a9071f5`, `bed3349`). **Abschluss-Commit des Nachtlaufs (dieser Commit):** Auflage aus der zweiten Gegenprüfung zu 3.8 (die Shell-Sperre liest keine `hyprlock.conf`, sondern `alpeLockLayout` bzw. `layout.js`) und diese «Stand»-Zeile. Alle Punkte 2.1 bis 3.8 sind vom Prüfer als bestanden beurteilt; die geparkten Fragen an den Maintainer stehen im lokalen Bericht. Die Haltprüfung auf der Spitze folgt nach diesem Commit; ihr Ergebnis steht im lokalen Bericht und wird hier erst mit dem nächsten Plan-Commit nachgetragen | je Commit `tools/test.sh` auf dem vollen Hash im Temp-Worktree: `e0f4a992399e5f24ac5a34051158215c99b0ad2c` grün (33 Schritte), `14618aed5f3c0f3ccb4731812967ae4d150c44af` grün (33 Schritte), `2fab65b32cd1b9f37b5d26760e7ad70c791372b2` (Nachbesserung 2.1) grün (33 Schritte), `dc72cf684516e584d58ff68a3da5cca1b77752ef` (Nachbesserung 2.2: `journalctl -o short-full`, Grenzen genannt) grün (33 Schritte), `caab7179f210d164c046bac4cd1a281d37705cca` (2.3) grün (33 Schritte), `d5c2a9dd52022d6d1699e098b3f6bcd1739a2c0d` (2.4) grün (33 Schritte), `0eeaaf4522cef5b604d556c2357d8e12381c6b9f` (Nachbesserung 2.3) grün (33 Schritte), `6f77e24767dd0d4ecd66f1228410f64ab5cb9a28` (2.5, geprüft mit `tools/test-commit.sh` selbst) grün (34 Schritte, neu `tests/test_testcommit.py`), `ef30b932b44ce6facb4a17728a10544914f0ef08` und `73ab9c523a636512e79197cddc4ffa85c5c5bf61` (2.6) im Sammellauf grün (je 34 Schritte), `70e7e73190084e166eb3a4a1819353b1f18c6b72` (2.7) grün (34 Schritte), `3b936215c2014f74e49c3b0bdfdbb56b8c7aa389` (2.8) grün (34 Schritte), `9026a04121acd452ffecab75575bf6f0d05a4589` (3.1) grün (34 Schritte), `50d17e6da2ddd7694576484d4588cbe5421a6e0e` (Nachbesserung 3.1) grün (34 Schritte), `8e053b451e4e7e777dd1ada178137b2d4a15b757` (3.2) grün (34 Schritte; davor Ladeprüfung KWin «gesperrt» auf dem Arbeitsbaum 37/37, nichts neu), `712e34ba0d5dcca41baf6084fc28aa837d29fcdb` (3.3) grün (34 Schritte), `09b1012278c5652b513bd805d7eef5ba02376a15` (3.4) grün (34 Schritte), `459b8e08118c166519f3ef469aeebdc33af5c2a4` (3.5) grün (34 Schritte), `d6411d00655acfd0dfdc656e46a680c7ec0105b7` (Nachbesserung 3.4) grün (34 Schritte), `19b5f88cb8c34ec7115b158894d4963de57e0dec` (3.6) grün (34 Schritte), `87b58fce99eab9cfbb7ee5a8b7c3e5d5c2cc67c1` (Nachbesserung 3.5) grün (34 Schritte), `41434f0ba20436a3d273b86fee505ebdfe0458d9` (3.7) grün (34 Schritte), `508d768388d5a19a5b803bf2f6bb5ffdeb464a34` (3.8) grün (34 Schritte), `a9071f520d38c0158a439fce951b4897b29e24a7` (Nachbesserung 3.7) grün (34 Schritte), `bed33492b960614a1b00ee11a4c3dc001297715b` (Nachbesserung 3.8) grün (34 Schritte) |
| – | **Nachtrag zum Nachtlauf vom 24.11.2026: Test und Haltprüfung auf `4d71036`** (Bericht lokal in `docs/plan/nachtlauf-2026-11-24.md`, «Haltprüfung auf der neuen Spitze»). `4d71036` ist am **25.11.2026 vom Maintainer gepusht** (`origin/phase-a` = `4d71036414d23fcbbaba379ebd59044ed44df1ef`). **Haltprüfung auf `4d71036`** (25.11.2026, 00:06–00:23 Uhr, alle Läufe einzeln nacheinander, Schranke `--gruen` vorher 0): Ladeprüfung KWin «gesperrt» 37/37, KWin «offen» mit Bild 36/36, Hyprland «gesperrt» mit Bild der Sperre 37/37 (sporadisch 0 von 2), Hyprland «offen» mit Bild 37/37 (sporadisch 0 von 1), je 0 neu, 0 weg, je ein Lauf ohne fremde Meldung, keine Wiederholung; Gegenprobe stummer Systembus (KWin «gesperrt») bestanden; qmllint 4900/4900, neu 0, weg 0; `go vet ./...` ohne Meldung; `go test ./...` abgeschottet 57 Pakete grün. Drei Haltbilder: Hyprland «offen», KWin «offen» (über `kwinbild.py`, 1920 × 1080), Hyprland «gesperrt» (Sperre der Shell). Vom Prüfer als bestanden beurteilt. **Die Belege lagen unter `/tmp/claude-1000/nachtlauf/` und haben den Neustart des PCs nicht überlebt** (Protokolle, Haltbilder, Testprotokoll); erhalten sind nur der lokale Bericht und die Wortlaute der Urteile darin. Ab dem Nachtlauf vom 25.11.2026 liegen Belege ausserhalb von `/tmp`. `git worktree prune` am 25.11.2026: die Einträge der Mess-Worktrees `m/alt` und `m/neu` entfernt | `4d71036414d23fcbbaba379ebd59044ed44df1ef` grün (`tools/test-commit.sh`, Rückgabewert 0, 25.11.2026, 00:03:18–00:05:58; Schrittzahl im Bericht nicht genannt, Protokoll verloren) |
| – | **Nachtlauf vom 25.11.2026** (Teil 0, Teil 1 = Entscheide des Maintainers vom 25.11.2026, Teil 2 = E1; Bericht lokal in `docs/plan/nachtlauf-2026-11-25.md`, Belege ausserhalb von `/tmp`). `14a9c37` 0.2: Nachtrag zu `4d71036` (Zeile oben). `0dfe14f` 1.1: Entscheide zu den geparkten Fragen in 0.8 Nr. 109 (Nr. 107 «offen» damit geschlossen). `b2b02ab` 1.2: Werteprüfung durchsucht jede Textdatei, IP-Adressen in SVG-Pfaddaten zählen nicht (0.8 Nr. 110). `4a60f07` Nachbesserung zu 1.2: Proben für `id`, `data-d`, `xlink:d` (Fund) und `d='…'` (kein Fund), Grenze «ohne XML-Parser» in `docs/technik.md`. `865f6ed` 1.3: `CLAUDE.md` «Dateien ändern» gilt für alle Dateien, Werkzeug-Ausnahme nur noch Attrappen und gemessene Grundlinien; Suchindex und Massenumbenennung offen (0.8 Nr. 111); dazu Auflagen des Prüfers zu 0.2 und 1.1 (Zeit des Testlaufs auf `4d71036`, Fundstelle in Nr. 109 (2)). `ee3e185` 1.4: `ladepruefung.py kwin --bild-schreibtisch` (0.8 Nr. 112; Lauf in Ruhe auf `ee3e185`: KWin «gesperrt» 37/37, nichts neu, nichts weg, Bild 1920 × 1080 zeigt das ausgelieferte Design ohne Zusätze). `c8c6ce5` 1.5: vier Haltbilder Pflicht, `CLAUDE.md` und 0.8 Nr. 71; Nachtrag in `offene-faelle.md` («Ladeprüfung», Weg A). `ce6b6f7` 1.6: Mac-Liste in `offene-faelle.md` – Punkt 1 mit `hyprlock --config` in der echten Sitzung, Rückweg über eine zweite Anmeldung, `hyprlock --help`; Punkte 4 und 5 erst nach F1; neu 6 (drei sporadische Meldungen), 7 (kein «Unrecognized pragma»), 8 (kurzer Benutzername in der Werteprüfung), 9 (`dnf repolist -v`); «Offen» zu `SPORADISCH` in `offene-faelle.md` geschlossen (Nr. 109 (6)); Nachbesserung `2eab128`: Rückweg bei hängender hyprlock-Sperre (Sitzung bleibt gesperrt, Befehle des roten Bildschirms), dnf5 ohne `-v` (`dnf repoinfo` ergänzt), Suchbefehle genauer. `8045b79` 1.7: 0.8 Nr. 108 – Bildname `halt-kwin-kdesperre.png`, Etappe E1, nicht in einem unbeaufsichtigten Lauf; Lizenzfeld vollständig aus der Dateiliste von `make install`, festgelegt am Ende von E1 (6.2, 6.3, Abschnitt 10, `offene-faelle.md`); dazu Auflagen des Prüfers zu 1.4 und 1.5 (Schluss von Nr. 108, 0.7 Nr. 6 nachgeführt, `CLAUDE.md`: jedes Haltbild ansehen und beschreiben). 1.8: nur lesend, kein Commit (Befund im lokalen Bericht: die zwei dunklen Bogen unten rechts in den «offen»-Bildern sind Täler der Form `softBurst` der Material-Vorlage, 1–2 px über dem Bildrand). `f2bbe5a` Auflagen-Commit: Herkunft der Regel «Bildlauf = Lauf seiner Variante» und Halbsatz in `CLAUDE.md`, F1-Zeile (Passwortfeld und Streifen der Sperre), Quellenvermerke in der Mac-Liste. **E1** `c20f69a` 2.1: Standbild der Sperre (0.8 Nr. 106) – `design/kde/bilder/jagged-peaks-wolkenzug.jpg` über `tools/standbild.py`, Auswahl in der Shell nur für Videos des eingespielten Designs, `design.py export` erhält es, `NOTICE`; dazu freiwillige Hinweise aus der Prüfung des Auflagen-Commits (6.3, F1-Zeile «am Mac»); Lauf in Ruhe KWin «gesperrt» 37/37, kein Cache-Bild mehr (Gegenprobe auf `f2bbe5a`: ffmpeg erzeugt es). `3447fb6` Nachbesserung zu 2.1: Video des Designs ohne `.jpg` und ohne ffmpeg wartet nicht ewig (Nr. 106), Node-Test des Ablaufs, ganzer ffmpeg-Aufruf und Ersatzqualität getestet, Ordner in Shell und `design.py` gleich abgegrenzt, F1-Zeile; Lauf in Ruhe KWin «gesperrt» 37/37. `48b4aaf` 2.2: Makefile in der Wurzel (`build`, `install`, `test`, `dist`; 6.1). `766d53f` Nachbesserung zu 2.2: Logo für fastfetch im Paket, `install` ohne Neubau, `dist` reproduzierbar (feste Modi, Version und Commit aus `HEAD`), `-buildvcs=false`, `EXTRA_LDFLAGS`; Stellen, die noch `~/alpe` erwarten, in `offene-faelle.md` für E4. `c79e95e` 2.3: Sperrpaket `org.alpe.desktop` beim Bau zusammengesetzt (`make sperrpaket`, Teil von `build`), Version aus `Brand.qml` (0.8 Nr. 86), installiert unter `/usr/share/plasma/shells/`; dazu Auflagen der Prüfung zu 2.2 (6.1-Block, 6.4 `make build install`, `dist` mit leerer Version bricht ab, Test mit umask 022 im ersten Lauf). `acb8c32` 2.4: `packaging/systemd/alpe.service` nach 6.1, Desktop-Dateien unter `packaging/desktop/` (`alpe-open.desktop` dorthin verschoben; `.Open` überholt), Symbol aus dem Alpe-Zeichen, Vervollständigungen für `alpe-dienst`; Sperrpaket erst unter `.neu` zusammengesetzt; Vermerke für E4. `fc6004b` Auflagen-Commit zu 2.4: `offene-faelle.md` – zwei Units mit demselben Busnamen (`alpe.service`/`dms.service`, in der VM zu messen), `Exec` der Desktop-Datei bei E4; Pfad von `alpe-open.desktop` in den Folgen für E3. `cc82f2d` 2.5: PAM-Dienste `alpe`/`alpe-u2f`, Blockmarke «ALPE LOCKSCREEN AUTH», Richtlinien unter `/usr/share/alpe` und `/etc/alpe`; Dienste aus 1.0 erkannt, nicht verändert; Einträge der Ausnahmeliste mit Frist E1 weg (2.3.3); qmllint-Grundlinie gemessen (eine Meldung neu benannt, 4900); Lauf in Ruhe Hyprland «gesperrt» 37/37. `8a849d8` Nachbesserung zu 2.5: QML-Test der Sperre auch ohne Richtlinie (Weg am Mac, vier Fälle), alter Dienst vor jeder Sperre neu gelesen, statische Prüfung «Pfade von 1.0 nur lesen» verschärft; `offene-faelle.md` berichtigt (Mac statt VM, Umfang des Tests) und um zwei offene Folgen ergänzt (eigene `dankshell` wird durch `auth sync` abgelöst; Richtlinie `/etc/dms` aus 1.0 nicht mehr gelesen). `8899bd4` 2.6: `alpe-dienst doctor` findet die Oberfläche im installierten Baum `<Datenordner>/alpe/shell` (Paket: `/usr/share/alpe/shell`), Go-Test `internal/config/shellconfig_test.go`. `5482555` Auflagen der Prüfung zu 2.6: Kommentar zur Reihenfolge berichtigt; `offene-faelle.md` nennt, wann die Suche greift, und «Install Type» für den Weg ohne Paket als Aufgabe für E4. `4dd171f` 2.7: `AudioService.qml` ohne den Zweig mit `pkill -x wireplumber` – ohne das Programm `systemctl` kein Neustart, sondern ein Hinweis; Test `shell/tests/wireplumber-restart.test.mjs`, zwei neue Texte mit Deutsch. `c85998c` 2.8: Prüfung von E1 – `tests/test_makefile.py` vergleicht die ganze Dateiliste von `make install` mit dem Codeblock in 6.1 und mit dem Paket `dux-shell` (keine gemeinsame Datei); Vorschlag für das vollständige Lizenzfeld mit offenen Punkten (u. a. `go-udev` GPL-3.0 im Dienst, Klänge, drei Code-Teile und Zeichen Dritter ohne `NOTICE`-Eintrag) in `offene-faelle.md`, «Lizenzfeld der Pakete». `65a65a2` Auflagen der Prüfung zu 2.8: Herkunft der Klänge berichtigt (drei bytegleich mit dem freedesktop-Klangthema, `desktop-login` gehört nicht dazu, `message-new-instant` ungeklärt) | je Commit `tools/test-commit.sh` auf dem vollen Hash: `14a9c373b1f89921f19d0e235fef0f0c19a0a913` grün (34 Schritte), `0dfe14f918cdaf8751012dd425eb2308a7f49aed` grün (34 Schritte), `b2b02abb29fd6071fa91515285f60bdefe9c5120` grün (34 Schritte), `4a60f079ecf8695c2704e57762f1ed42ab6c3968` grün (34 Schritte), `865f6ed34962ccf36ba732dfcfb994628208f372` grün (34 Schritte), `ee3e185c0ce93c43678929b6680c8af13f68f6b1` grün (34 Schritte), `c8c6ce5de7c3e77e9a1ef7d7f0efb686e6bb166c` grün (34 Schritte), `ce6b6f7ca987cf36e2405b09a8f219c4bcd12d7d` grün (34 Schritte), `8045b7968a68f9ef5f43d66eeabca7a1386062d5` grün (34 Schritte), `2eab128b96b81bfd10bcd70a4a2f7e0e2d92d5c0` grün (34 Schritte), `f2bbe5ac35877b1c18df6b4331643eb9d4d049e7` grün (34 Schritte), `c20f69aea2f4fdad4f6a3e39500e99366e434bd2` grün (35 Schritte, neu `tests/test_standbild.py`), `3447fb623ff77f9999353c77ee55ce994b2afbdc` grün (35 Schritte), `48b4aafc7d3dd89d002bcf8368c7f8ac09e06068` grün (36 Schritte, neu `tests/test_makefile.py`), `766d53f8aa1539e53caf49d7a9813d210e59d27f` grün (36 Schritte), `c79e95e3255e1b634124fac47c8c682f889300a3` grün (36 Schritte), `acb8c32fc19005e863feb33205a3fd5e40a2a7e7` grün (37 Schritte, neu `tests/test_paketdateien.py`), `fc6004b6a8a30ae17754c2c6ca9ddd588d745875` grün (37 Schritte), `cc82f2d291153f0c5135256231b1fd61d2e7c054` grün (38 Schritte, neu `tests/test_pam_dienste.py`), `8a849d8ad1742cc1ffe7dfa2cc97652677de3ddc` grün (38 Schritte), `8899bd4f2c0b436da4982c625310afcd46957e4a` grün (38 Schritte), `5482555e7cbacefeb4a285b1fc672f4774f611e6` grün (38 Schritte), `4dd171f99e6653c6bbc0eb80fb35adb7120cd3f6` grün (38 Schritte), `c85998c65fc048e835d925257dcd44e9a0594e85` grün (38 Schritte), `65a65a216c751ad62950cad5f94f2befd5976719` grün (38 Schritte; 25.11.2026, 22:19) |
| – | **Haltprüfung auf `65a65a2`** (25.11.2026, 22:19–22:37 nach dem Ende von `tools/test.sh` um 22:19, Ladeprüfungen ab 22:20, in Ruhe; Bericht lokal in `docs/plan/nachtlauf-2026-11-25.md`, «Haltprüfung»). Ladeprüfung gegen die Grundlinien: KWin «gesperrt» mit `--bild-schreibtisch` 37/37, KWin «offen» 36/36, Hyprland «gesperrt» mit `--bild-sperre` 37/37, Hyprland «offen» 37/37 – je nichts neu, nichts weg, jeder Lauf mit `Connected`, Wiederholungsregel nicht gebraucht. Gegenprobe mit stummem Ersatz-Systembus (KWin «gesperrt») bestanden. qmllint 4900, neu 0, weg 0. `go vet ./...` ohne Meldung, `go test ./...` (abgeschottet) 57 Pakete ohne Fehlschlag. Archiv von `make dist`: `LICENSE` von `go-udev` enthalten, von `golang/freetype` nur `LICENSE` (nicht `licenses/ftl.txt`/`gpl.txt`), `yeqown/reedsolomon` ohne Lizenzdatei. Vier Pflichtbilder angesehen und beschrieben; im Bild Hyprland «offen» liegen die zwei dunklen Bogen der Form `softBurst` in der letzten Bildzeile an den in 1.8 gerechneten Stellen. **Halt bestanden.** `65a65a2` ist **am 25.11.2026 gepusht** (vom Maintainer; `origin/phase-a` = `65a65a216c751ad62950cad5f94f2befd5976719`). | Tor `tools/test-commit.sh --gruen 65a65a216c751ad62950cad5f94f2befd5976719`: Rückgabewert 0 |
| – | **Nachtlauf vom 26.11.2026** (Teil 0, Teil 1 = Entscheide des Maintainers vom 25.11.2026, Teil 2 = E2; Bericht lokal in `docs/plan/nachtlauf-2026-11-26.md`). `575ac1a` 0.1: Testvermerk und Haltprüfung zu `65a65a2` (Zeile oben), Klänge in `offene-faelle.md` nach dem Befund aus 2.8. `a5b0c35` 1.1: `go-udev` (GPL-3.0-only) in `NOTICE`, `LICENSES/GPL-3.0-only.txt` ins Paket (0.8 Nr. 113), dazu Auflagen der Prüfung zu 0.1. `208df3c` 1.2: `golang/freetype` unter der FTL, `licenses/ftl.txt` unverändert in Quellarchiv und Paket (0.8 Nr. 114), dazu Auflage der Prüfung zu 1.1 (GPL-3.0-only in 6.3 und Abschnitt 10). `bfbd06b` Auflagen der Prüfung zu 1.2: jede Einbindung von freetype in `NOTICE` (auch WLAN-QR), FTL im Lizenzfeld des Plans, verständlicher Abbruch ohne Modul-Cache. `b7034df` 1.3: `yeqown/reedsolomon` MIT, am Ursprung belegt (0.8 Nr. 115), `go list -mod=readonly`. `fbc70a5` 1.4: `desktop-login` entfernt (Herkunft inzwischen belegt, Rückfrage im Bericht), Anmeldeklang fällt ohne Systemthema still weg, `NOTICE` nennt genau die ausgelieferten Klänge (0.8 Nr. 116); dazu Auflagen der Prüfung zu 1.3. `d5ce994` 1.5: Zeichen Dritter und `fzf.js`, `Hct.js`, `MaterialShapeData.js` in `NOTICE`, `discord.svg`/`reddit.svg` entfernt (0.8 Nr. 117), dazu Auflagen der Prüfung zu 1.4. `3afadff` Nachbesserung zu 1.5: Flatpak CC BY 3.0, Snapcraft CC BY-SA 3.0 (nicht CC0), Hyprland-Zeichen ARR nach der Markenrichtlinie. `8847ea6` 1.6: eigene `dankshell` ohne `alpe` – `auth sync` schreibt `alpe` nicht und meldet es (0.8 Nr. 118). `890510c` 1.7: `/etc/dms/cli-policy.json` als Rückfall mit Meldung (0.8 Nr. 119), dazu Auflagen der Prüfung zu 1.6. `fea436a` Auflagen der Prüfung zu 1.7: nicht lesbare Richtlinie aus 1.0 fällt nicht still weg. `41fad2f` 1.8: `alpe.service` ohne `BusName=` (0.8 Nr. 120), Liste für den Installationstest in der VM | je Commit `tools/test-commit.sh` auf dem vollen Hash: `575ac1a8c3988e6d046929aafc4fa1bfdd742387` grün (38 Schritte), `a5b0c355510849586ace9a193b762fe7298d27c4` grün (39 Schritte, neu `tests/test_lizenzen.py`), `208df3c59da60a30c0be126a0b41886abbddce71` grün (39 Schritte), `bfbd06b1261ef128b7ed0b276ea363d81be1f130` grün (39 Schritte), `b7034dfe7cc5145c44e69011dd2a8ecb8ff5867f` grün (39 Schritte), `fbc70a5a2cc3c8e1658f104ea9910ca976c3a507` grün (39 Schritte; die erste Fassung `326259e` war rot – `tests/test_werte.py` verlangte mindestens 61 Binärdateien –, nur lokal, mit `--amend` neu aufgebaut), `d5ce994c7767fc73920dadcffa02de3a1e3be6cc` grün (39 Schritte), `3afadff5ea058882bf30dcbbdcd2be4fed5049ba` grün (39 Schritte), `8847ea609e6f83dee6188663945a46f884837c38` grün (39 Schritte; erste Fassung `201d11d` rot – statische Prüfung in `tests/test_pam_dienste.py` –, nur lokal, mit `--amend` neu aufgebaut; `go test ./internal/pam/` abgeschottet grün), `890510c5411ff0216a4d5bd001f083797654f541` grün (39 Schritte; `go test` von `internal/clipolicy` und `cmd/alpe-dienst` abgeschottet grün), `fea436aa630e70f8dbb1b6121bfcac2e5c293d36` grün (39 Schritte; dieselben Go-Pakete abgeschottet grün), `41fad2f8e99a418b37311170ec115e34cff79a30` grün (39 Schritte) |
<!-- D7-Stand -->

Go-Tests (`go test ./...`, abgeschottet): dieselben 3 Fehlschläge wie vor C1 (siehe offene
Fälle). Node-Tests des Ursprungs: 10 Fehlschläge, alle schon vor C1 rot. Jeder Commit nach D3
einzeln mit test.sh geprüft (Zwischenstände in einem Temp-Worktree).

**Zwischenfall (22.11.2026, behoben):** Commit «Dienst: sichtbare Texte» enthielt versehentlich
die gebaute Binärdatei `core/alpe-dienst` (47 MB; `go build ./...` legt sie in `core/` ab,
`.gitignore` kannte nur `core/dms`). Nur lokal, nie gepusht. Aus der Geschichte entfernt
(Commits ab diesem neu angeordnet, Bäume sonst identisch), `core/alpe-dienst` steht jetzt in
`.gitignore`. Deshalb tragen die D6-Commits ab dort neue Hashes (Tabelle nachgeführt).

**Zwischenfall (22.11.2026, behoben):** Der Commit «Plan: Nachprüfungen zum Zwischenhalt» enthielt
zuerst auch zwei Löschungen, die erst zum Dienst-Commit gehören (`netfetch/release.go`, Attrappe
`mocks/version`): `git rm` hatte sie vorgemerkt, und der Commit nahm den ganzen Index mit. Damit
bauten dieser und der folgende Commit nicht (test.sh im Temp-Worktree rot: `test_version.py`,
Go-Test). Nur lokal, nie gepusht. Die drei Commits sind neu aufgebaut (Löschungen im Dienst-Commit,
Endbaum identisch); jeder ist einzeln mit test.sh geprüft und grün. Seither wird vor jedem Commit
der Index angesehen.

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
- **Erledigt bis D7.2b** (dazu 0.8 Nr. 25–30). Ladeprüfung KWin auf D7.2b ohne Neues (0.8 Nr. 28). D7.3 erledigt. Entscheide nach D7.3: 0.8 Nr. 31–35. Verbotene `D*`-Namen in der Namensprüfung (0.8 Nr. 34). D7.4, D7.5 erledigt. Entscheide nach D7.5: 0.8 Nr. 36–40. D7.6 erledigt, Nachträge dazu 0.8 Nr. 41–46. **Zwischenhalt nach D7.7 erreicht** (D7.7c–D7.7i und Ladeprüfung mit allen Repo-Plugins erledigt); D7.8 erst nach Bestätigung (Aufteilung D7.7a–D7.7i in 2.3.5), danach Ladeprüfung mit allen Repo-Plugins (0.8 Nr. 33) und Zwischenhalt (0.8 Nr. 29, 45). Installierte Kopien von alpeSport/alpeRadar unter `~/.config/dms/plugins` importieren noch `qs.Modules.DDash` und müssen mit 1.1 durch die Repo-Fassung ersetzt werden.
  Für jeden Bereich eine Tabelle `entwicklung/umbenennen/<bereich>.tsv` anlegen, Probelauf mit
  `--liste` prüfen, dann `--schreiben`; `bash tools/test.sh` muss grün sein, Namensprüfung zeigt
  die sinkende Zahl. D7.2a: nur `git mv` plus Symlinks unter den alten Pfaden (Werkzeug-Art
  `link`); D7.2b: Importe, Typen, Symlinks weg, Übergangs-Hüllen `shell/DCommon/Widgets/D*.qml`
  für sathiAi (2.3.0). Go-Tests abgeschottet mit Temp-HOME (Socket-Pfade unter 108 Zeichen).
  Fehlschläge der Node-Tests stehen in `tests/data/node-bekannte-fehlschlaege.txt`; ändern sich
  Testnamen durch die Umbenennung, die Liste im selben Commit nachführen.
- **Halt nach D7 erreicht** (22.11.2026): D7.8a und D7.8 erledigt, Haltprüfung in der Tabelle oben.
  Offen beim Maintainer: die angepassten Fassungen der fremden Plugins unter
  `~/.config/alpe/plugins` anlegen (PC: hueManager, sathiAi; Mac: hueManager, calculator;
  `docs/plugins-anpassen.md`), Mac-Test des D7-Stands (`offene-faelle.md`, «Anleitung für den
  Stand nach D7»), zwei Fragen aus D7.8a (`offene-faelle.md`).
- **Abschluss des Halts nach D7 läuft noch** (22.11.2026, abends; Zwischenstand in der Tabelle oben). Seither
  dazugekommen: `aae5998` und `21f6ff2` (Design ohne fremdes Plugin, `pciId`, angeheftete Programme und
  programmbezogene Regeln; Export filtert `pciId` und Widgets fremder Plugins; Test gegen persönliche Werte),
  `76f42f0` (Diagnose `ALPE_LP_STAPEL=1`); alle im Temp-Worktree grün (32 Schritte), ebenso `44f99d1`.
  **Ursache der fehlenden Verbindung zum Dienst unter Hyprland gefunden:** Der Dienst wartet nicht auf den
  Compositor, sondern ohne Zeitgrenze auf die Antwort des Ersatz-Systembusses der Ladeprüfung auf `Hello`
  (dessen Richtlinie erlaubt keine Antworten; nachgestellt mit `dbus-send`); unter Hyprland blockiert das über
  die Ruhezustands-Überwachung der Gamma-Initialisierung den Start der Schnittstelle, unter KWin hängen
  Netzwerk-, Loginctl- und Freedesktop-Manager still im Hintergrund. Der Eintrag in `offene-faelle.md`
  («Ladeprüfung») nennt noch Gamma als mögliche Ursache und ist zu berichtigen.
  **Offen, in dieser Reihenfolge:**
  1. **Entschieden (0.8 Nr. 80–82):** erst die Prüfumgebung (Richtlinie des Ersatz-Systembusses, eigener
     Commit; ein Lauf ohne `Connected` gilt als gescheitert), dann der Dienst (Zeitgrenze für alle Verbindungen
     zum Systembus; Plan `docs/plan/dienst-systembus.md` zur Freigabe, vorher keine Umsetzung), Grundlinien erst
     messen, wenn beides committet ist. **Prüfumgebung erledigt:** Die Richtlinie des Ersatz-Systembusses
     erlaubt Antworten (nachgestellt mit `dbus-send`: alte Richtlinie keine Antwort, neue antwortet; Test in
     `tests/test_ladepruefung.py`), sein Protokoll steht in `systembus.log`, `health()` verlangt
     `Connected (API v…)`. Probelauf «gesperrt» unter Hyprland (1 Lauf, gültig, 149 s): die Oberfläche meldet
     `Connected (API v40 …)`; gegen die alte Grundlinie 22 gleich, 25 neu, 16 weg – erwartet, weil der Dienst
     jetzt erreichbar ist (neu: Meldungen des Dienstes zu fehlendem logind, BlueZ, NetworkManager, GeoClue,
     UPower, polkit, CUPS; weg: `dgop is not available`, `Server unavailable, running synchronously` samt
     den Zeilen des synchronen Theme-Laufs, die Zeitüberschreitungen von Bluetooth, UPower, polkit).
     Die Nummer der Anfrage in `ipc error: id=…` wird beim Vergleich ausgeblendet. **Die eingecheckten
     Grundlinien waren damit bis zur Neumessung (Punkt 6, erledigt in `9685ebe`) überholt;** unter KWin noch kein Lauf mit der neuen
     Richtlinie.
     **Plan für den Dienst vorgelegt, nicht freigegeben:** `docs/plan/dienst-systembus.md` (vier Fragen
     darin). Geklärt: Die Sperre, auf die Gamma wartete, ist `systemBusLck` von godbus in
     `dbus.SystemBus()`, gehalten vom Loginctl-Manager in `Hello` (Goroutinen-Stapel). Eintrag in
     `offene-faelle.md` berichtigt, drei offene Fälle dazu (stummer Compositor, Session-Bus,
     gonetworkmanager/Abriss im Betrieb). **Freigegeben (0.8 Nr. 84) und umgesetzt:** `0dbeb27` (Paket
     `systembus`), danach Manager, Gamma und Gegenprobe; Abweichungen in `dienst-systembus.md`, 5a
     (Freedesktop wartet als Ganzes, Ortung wechselt nicht nachträglich, Go-Test 5 kleiner als geplant,
     kein Changelog-Eintrag vor G1). `go vet ./...` ohne Meldung, `go test ./...` abgeschottet: alle
     Pakete grün (vorher 56 mit `systembus`, nachher dieselben; neu Tests in `systembus`, `wayland`,
     `server`, `server/dbus`, mit `-race`). **Gegenprobe mit stummem Systembus bestanden:** Hyprland
     (319 s) und KWin (263 s), `Connected` und genau eine Meldung zum Ausfall.
     **Erledigt (0.8 Nr. 83):** `tools/design.py` wendet `SESSION_GESTALTUNG` auch beim Einspielen an
     (Zustand aus einem Design wird nicht übernommen und beim Einspielen genannt), mit Test; 7.8 nachgeführt,
     der Pin-Filter `installed_pins` ist entfallen.
  2. Behebung im Dienst als eigener Commit mit Test und Eintrag in `offene-faelle.md` (Fehler aus der Zeit vor
     Phase A); Mac-Anleitung: Nachtlicht prüfen.
  3. Prüfen: `Connected` im Protokoll unter dem verschachtelten Hyprland, `cpuUsage` links in der Leiste.
  4. **Export-Ergänzung: erledigt** (0.8 Nr. 79, Liste in 7.8; `recentColors` aus `design/kde/session.json`
     entfernt; kein Stash `export-liste-abgebrochen` vorhanden). Ursprünglicher Auftrag:
     `tools/design.py` nimmt aus `session.json`
     nur eine feste Liste von Schlüsseln, die zur Gestaltung gehören (etwa Material-Vorlage und Form), statt
     einzelne Zustandswerte herauszufiltern. Befund beim Einlesen: Die Liste `SESSION_KEEP` gibt es schon, sie
     enthält aber Zustand (`dockPins`, `barPinnedApps`, `trayItemOrder`, `recentColors`) und kennt
     `materialWallpapers`/`materialWallpaperProfiles` nicht. Zu tun: alle Schlüssel der Session (88 in
     `SessionSpec.js`, dazu die geteilten aus `SharedSessionSpec.js`) in Gestaltung und Zustand einordnen,
     Liste im Code festlegen, Test in `tests/test_design.py`, Liste hier im Plan; `recentColors` kommt damit
     auch aus `design/kde/session.json`. Eigener Commit.
  5. **Vorgelegt, nicht freigegeben:** `docs/plan/sie-form.md` (103 Übersetzungen in Sie-Form, je Schlüssel,
     heutiger Text und Vorschlag; vier Fragen am Ende) und `docs/plan/uebersetzung-luecken.md` (Vorschlag für
     die 42 fehlenden deutschen Texte). Schlüssel und heutige Texte beider Listen sind maschinell mit dem
     Katalog bzw. `tests/data/uebersetzung-bekannte-luecken.txt` abgeglichen. Freigabe durch den Maintainer
     vor G1, Umsetzung in `de.json` danach.
  6. **Neumessung erledigt (`9685ebe`, 22.11.2026).** Endstand `ad91d3f` und `ba4ddbc` (Worktree `wt-alt`
     mit der Ladeprüfung des Endstands), je «gesperrt» und «offen» unter Hyprland und KWin, je 3 Läufe,
     dazu der Lauf für das Bild: 25 Läufe, alle gültig (Compositor und Dienst mit Exit 0, `Connected`,
     Hyprland-IPC), 143–148 s je Lauf. Einträge je Grundlinie: Hyprland 41 / «offen» 40, KWin 39 / «offen»
     38; auf `ba4ddbc` 39 / 39 / 39 / 38. **Unterschiede Endstand gegen `ba4ddbc`: nur umbenannte Namen**
     (`alpe-floating-windows`, `FileSearchService`, `BarTab.qml`, `colors.json`,
     `@Alpe/Widgets/CachingImage.qml`), dazu drei sporadische Meldungen unter Hyprland, je 1 von 3 Läufen
     (Notizblock-Reiter ohne Datei, zwei Zeilen, «gesperrt»; `DeferredAction` `flush`, «offen») –
     **Herkunft offen, Frist vor G1** (`offene-faelle.md`): Die beiden Dateien sind seit `ba4ddbc`
     unverändert, ihre Aufrufer nicht zwingend (D7 hat Aufrufer umbenannt); die Gegenmessung (0 von 6 auf
     `ba4ddbc`) kann bei dieser Häufigkeit nicht belegen, dass sie neu oder alt sind. Die Normalisierung blendet den Zeitstempel
     im Reiternamen und die Nummer des QML-Typs aus. **SettingsRow («Cannot find member data»): in keinem
     der 25 Läufe.** Gegenüber den alten Grundlinien neu: die Meldungen des Dienstes (kein logind, BlueZ,
     NetworkManager, GeoClue am Ersatz-Systembus) statt der Zeitüberschreitungen. **Bild** («offen»,
     Hyprland, Lauf gegen die neue Grundlinie 39 gleich, nichts neu): Leiste oben mit Arbeitsflächen-Umschalter,
     Starter mit Alpe-Logo, drei Systemwerten (48°, 44°, 2 %), Uhr und Wetter in der Mitte, Ton und Mikrofon
     rechts; Material-Vorlage als Hintergrund mit grossem Alpe-Logo; unten in der Mitte das Dock nur mit dem
     Papierkorb; darüber der Hinweisbalken von Hyprland zum Start ohne `start-hyprland`.
     **Haltprüfung im Übrigen:** qmllint 4900 gegen 4902, nichts neu (die zwei weggefallenen wie am Halt
     vermerkt); `go vet ./...` ohne Meldung (auf `6529f85`, seither kein Go geändert); Gegenprobe mit
     stummem Systembus für diesen Halt: bestanden unter beiden Compositors (Punkt 1). Ab jetzt läuft sie
     bei jedem Halt einmal mit (0.8 Nr. 85).
  Rückfragen aus `21f6ff2`, **beantwortet am 22.11.2026 (0.8 Nr. 78, 79):** `dockPins` entfernt statt geleert
  und `WindowClasses` des Unschärfe-Effekts ganz entfernt sind bestätigt; `recentColors` kommt aus
  `design/kde/session.json` heraus; der Export nimmt aus `session.json` nur die feste Liste der
  Gestaltungs-Schlüssel (Punkt 4).
- **Halt nach D7 abgenommen (22.11.2026), vorbehaltlich des Mac-Tests.** Nachgeführt danach:
  1. Sporadische Meldungen (Notizblock «Tab file does not exist» samt `FileView`-Meldung,
     `DeferredAction` `flush`): **Herkunft offen, Frist vor G1**; bei `DeferredAction` vor G1 die
     Aufrufer prüfen, die `flush` erwarten (`offene-faelle.md`, «Ladeprüfung»).
  2. Mac-Anleitung für den Stand nach D7 ergänzt: Dock ohne angeheftete Programme, Symbol des
     Papierkorbs.
  3. Hinweisbalken von Hyprland in der Ladeprüfung abgeschaltet (`1d91c2b`,
     `misc.disable_watchdog_warning`, mit Test; test.sh auf dem Commit im Temp-Worktree grün).
     Bildlauf «offen» unter Hyprland danach: gültig, 148 s, gegen die Grundlinie 39 gleich, nichts
     neu. **Bild:** kein Balken mehr; Leiste oben links mit Arbeitsflächen-Anzeige (leere Pille),
     Starter mit Alpe-Zeichen, drei Systemwerten (48°, 47°, 3 %), in der Mitte Uhr und Wetter,
     rechts Ton (stumm) und Mikrofon; Material-Vorlage mit grossem Alpe-Zeichen rechts. **Unten
     in der Mitte der Papierkorb mit richtigem Symbol, aber auf einem schwarzen, scharfkantigen
     Quadrat statt in einem gerundeten Dock** – offener Fall, **Frist jetzt vor E1**
     (`offene-faelle.md`, «Ladeprüfung»; Gegenprobe mit Anheftungen im Punkt «Ergänzungen zu 6.7»
     unten), Gegenprobe am Mac.
  4. `docs/plan/sie-form.md` und `docs/plan/uebersetzung-luecken.md`: **nicht freigegeben**; die
     drei Stilfragen beantwortet der Maintainer nach der Durchsicht. Bis dahin nichts in `de.json`.
  5. Der Worktree `/tmp/claude-1000/h7/wt-alt` (`ba4ddbc`) bleibt bis nach dem Mac-Test stehen.
- **Vorlage 6.7 vorgelegt, nicht entschieden:** `docs/plan/sperrbildschirm-dateien.md` (Empfehlung:
  Systempaket unverändert, Eigenes nur in `kscreenlockerrc`; vier Fragen). **Nebenbefund daraus,
  nicht behoben (Entscheid nötig, Frage 3 der Vorlage):** `shell/Modules/Lock/Alpe/layout.js` enthält
  absolute Pfade in zwei Home-Verzeichnisse (seit `bfc7243`, laut lokalem Stand der Remote-Zweige
  auch auf `origin/phase-a`); `tests/test_werte.py` prüft darauf nur `design/`. **Inzwischen
  behoben, siehe nächster Punkt;** die Geschichte ist unverändert.
- **Ergänzungen des Maintainers zu 6.7 (22.11.2026, nachts), umgesetzt:**
  - **Version des Sperrpakets (Frage 4): entschieden.** `metadata.json` bekommt die Version beim
    Paketbau aus derselben Quelle wie `Brand.version`; **Umsetzung mit E1** (dazu Prüfung in
    `tests/test_version.py`).
  - **`layout.js` neutral (`56fcedd`):** aus `lockscreen/hyprlock.conf` neu erzeugt (drei Texte,
    Passwortfeld, keine Bilder, kein Pfad mit `/home/`, kein Datum); der Umsetzer kennt dafür
    `--quelle NAME`, `tests/test_hyprlock.py` vergleicht die eingecheckte Datei mit seiner Ausgabe.
    Die Shell-Sperre zeigt damit ohne eigenes Layout die neutrale Vorlage.
  - **Wo die Pfade liegen:** `bfc7243` ist **weder in `main` noch im Tag `v1.0`** (nur `phase-a`
    und `origin/phase-a`). **Dieselben Pfade stehen aber schon in `v1.0` und `main`**, in
    `shell/0001-Alpe-1.0-Zugerberg.patch` (acht Stellen); Einzelheiten in
    `sperrbildschirm-dateien.md`, Abschnitt 2. Über die Geschichte entscheidet der Maintainer.
  - **Prüfung auf persönliche Werte im ganzen Repo (`016d986`):** `tests/test_werte.py` durchsucht
    alle versionierten Textdateien (2618) nach Pfaden in ein Home-Verzeichnis, Benutzer- und
    Rechnernamen, IP- und MAC-Adressen, Gerätekennungen; Ausnahmeliste mit 11 Einträgen je Datei
    und Art. Benutzer- und Rechnername kommen vom Rechner, auf dem der Test läuft (nicht im
    Repo hinterlegt); Allerweltsnamen und Namen aus einem Zeichen werden nicht gesucht, mehrdeutige
    Namen nur in eindeutigem Zusammenhang (seit `4ac9a6c`), Namen unter vier Zeichen ebenso (seit
    dem 24.11.2026; vorher wurden sie gar nicht gesucht); **in der CI wird keiner der beiden gesucht.** Dabei
    bereinigt: Pfad im Sport-Fixture, `pciId` in den Umzugs-Testdaten (jetzt erfunden), ein Name
    als Bezeichner in `tests/test_tools.py`, zwei Stellen im Plan.
  - **Dock (Frist jetzt vor E1):** Gegenprobe mit vier Anheftungen im Temp-HOME, Bild angesehen:
    Mit Anheftungen gerundete dunkle Dock-Fläche um alle Symbole, der Papierkorb darin weiterhin
    auf schwarzem Quadrat. Also: Das Quadrat gehört zum Papierkorb-Symbol und ist keine Folge von
    `dockPins`; ~~ohne Anheftungen fehlt aber die Dock-Fläche ganz~~ **berichtigt am 23.11.2026:
    Die Fläche ist auch ohne Anheftungen da** (klein, gerundet, auf dem dunklen Hintergrund fast
    unsichtbar; siehe unten). Nicht behoben (`offene-faelle.md`, «Ladeprüfung»).
  - `56fcedd` und `016d986` je auf dem Commit im Temp-Worktree mit `tools/test.sh` grün (32 Schritte).
- **6.7 ist vollständig entschieden (0.8 Nr. 86):** Variante A; eigene `hyprlock.conf` einmal
  übernehmen (F1); `layout.js` neutral (`56fcedd`, bestätigt); Version des Sperrpakets mit E1.
  **Die Geschichte wird nicht umgeschrieben** (0.8 Nr. 87), Behebung nur nach vorne.
- **E1 beginnt erst** nach dem Ergebnis des Mac-Tests (0.8 Nr. 6); davor ist ausserdem der
  Entscheid zum Dock nötig (0.8 Nr. 89).
  Offen beim Maintainer: Mac-Test, Entscheid zum Papierkorb-Symbol und zum Dock ohne Anheftungen
  (Möglichkeiten in `offene-faelle.md`, «Ladeprüfung»), Durchsicht der beiden Übersetzungslisten.
  Kein Schritt wurde wegen fehlender Freigabe übersprungen; von E1 ist nichts begonnen.
- **Nachprüfungen vom 23.11.2026:**
  - **Patch-Datei:** `shell/0001-Alpe-1.0-Zugerberg.patch` gibt es auf `phase-a` nicht mehr (in
    `bfc7243` lag sie unter `schichten/`, entfernt in `4a9a1c2` «Schichten aufgelöst»); sie steht
    in keiner Ausnahmeliste, nichts liest sie. Nichts zu löschen. Nebenbefund: `docs/technik.md`
    beschreibt noch `tools/upstream.sh` und `schichten/*.patch`, die es nicht mehr gibt (Doku, 8.).
  - **Werteprüfung (0.8 Nr. 88):** `16ff71d` Ausnahmen je Datei, Art und erwartetem Wert in
    `tools/werte-ausnahmen.txt` (24 Einträge: 20 dauerhaft, 2 «Phase B», je 1 «Umzug-Ende» und
    «G1»), Suche in `tools/werte-pruefen.py`. **Zwischenfall:** `16ff71d` war mit `tools/test.sh`
    im Temp-Worktree **rot** – die Liste nennt die ausgenommenen Werte und wurde, einmal
    versioniert, selbst als Fund gemeldet (im Arbeitsbaum war sie noch unversioniert und darum
    grün). Behoben nach vorne in `d96b0ae` (die Liste wird nicht durchsucht), grün. Nur lokal.
    **Gegenproben** (Temp-Worktrees, wieder entfernt): `bfc7243` 49 Funde in 15 Dateien, darunter
    je 8 Pfade in `layout.js` und `schichten/0001-Alpe-1.0-Zugerberg.patch`; `v1.0` 25 Funde in
    8 Dateien, darunter 8 Pfade in `shell/0001-Alpe-1.0-Zugerberg.patch`. `~/alpe-plugins` (nur
    gelesen): 19 Dateien, kein Fund. Die erfundene `pciId` in den Umzugs-Testdaten hat das Format der echten
    (zweimal vier Hex-Stellen); der Umzug wertet den Wert nicht aus, die Shell vergleicht ihn nur
    auf Gleichheit mit der Kennung, die der Dienst meldet.
  - **`wt-alt`:** `/tmp/claude-1000/h7/wt-alt` ist ein Git-Worktree dieses Repos auf `ba4ddbc`
    («Plan: Stand nach D7.1, Einstieg D7.2a», der Vergleichsstand vor D7.2), losgelöst; darin
    unversioniert `entwicklung/lp-offen/`, die heutige Ladeprüfung, mit der die Grundlinien auf
    dem alten Stand gegengemessen wurden. Bleibt bis nach dem Mac-Test.
  - **Dock:** Ursachen untersucht, Berichtigung und Möglichkeiten in `offene-faelle.md`,
    «Ladeprüfung»: Das schwarze Quadrat ist das Papierkorb-Symbol aus dem Ersatzthema Adwaita, das
    Qt 6.12 mit schwarzem Grund rendert (kein Fehler im Code von Alpe, 1.0 gleich; das Design
    nennt das Symbolthema kora, das niemand mitliefert); **die Dock-Fläche fehlt ohne
    Anheftungen nicht** – die Angabe vom 22.11.2026 war falsch. Nichts behoben, Entscheid offen.
- **Haltprüfung auf dem Endstand `d96b0ae` (23.11.2026):** Ladeprüfung, je 1 Lauf, alle gültig
  (`Connected`, Exit 0, 143–151 s): Hyprland «gesperrt» 39 gleich (von 41 Einträgen, 2
  `SPORADISCH`, keine gesehen), Hyprland «offen» 39 gleich (von 40, 1 `SPORADISCH`), KWin
  «gesperrt» 39 von 39, KWin «offen» 38 von 38 – **nirgends etwas neu oder weg.** Gegenprobe mit
  stummem Systembus unter KWin bestanden (263 s, verbunden, Ausfall einmal gemeldet). qmllint
  4900 gegen 4902, nichts neu (dieselben zwei weg). `go vet ./...` ohne Meldung.
  **Bild «offen» unter Hyprland:** wie am 22.11.2026 ohne Hinweisbalken – Leiste, Material-Vorlage
  mit Alpe-Zeichen, unten der Papierkorb auf schwarzem Quadrat in der kleinen Dock-Fläche.
  **Sperrbildschirm mit der neuen `layout.js`** (Bild unter Hyprland, Variante «gesperrt», aus
  einem Temp-Worktree mit aufgehobener Sperre für `--bild`): unscharfes Bergbild als Hintergrund,
  in der Mitte die Uhr in zwei Zeilen (Stunde über Minute, Alfa Slab One), darunter «Montag,
  23. November» und das Passwortfeld; keine leeren Bildstellen. **Unter KWin gibt es kein Bild:**
  `alpe-dienst screenshot full` meldet dort `compositor does not support
  wlr-screencopy-unstable-v1` (im virtuellen `kwin_wayland`; offener Fall in `offene-faelle.md`).
  Der Lauf «gesperrt» unter KWin lädt die Sperre mit der neuen Vorlage ohne neue Meldung.
- **Zweiter Zwischenfall (23.11.2026):** Der Plan-Commit `f5a5256` war ebenfalls **rot** – der
  «Stand» zitierte die erfundene Gerätekennung der Testdaten, und die Werteprüfung meldete sie
  (so soll sie arbeiten). Der Fehllauf im Arbeitsbaum blieb unbemerkt, weil die Ausgabe durch
  `tail` lief und dessen Rückgabewert galt. Behoben nach vorne im folgenden Commit. Nur lokal.
- **Angehalten (23.11.2026).** `1d91c2b`, `554fd44`, `e9c62c1`, `56fcedd`, `016d986`, `669d08f`,
  `d96b0ae` je auf dem Commit im Temp-Worktree mit `tools/test.sh` grün (32 Schritte), `16ff71d`
  und `f5a5256` rot (siehe oben); keine Läufe und keine Scopes der Ladeprüfung mehr offen; Worktrees: nur der
  Arbeitsbaum und `wt-alt`.
- **Nach dem Halt zur Werteprüfung (23.11.2026, abends; Entscheide 0.8 Nr. 90–94).**
  - **Rote Commits zusammengelegt (0.8 Nr. 90).** Vorprüfung: `origin/phase-a` (`d17558a`) ist
    Vorfahr von `16ff71d`. Sicherung: lokaler **Zweig** `sicherung/vor-zusammenlegen` auf `53c5121`
    (ein Zweig statt eines Tags, weil `CLAUDE.md` das Setzen von Tags ausschliesst). Alt → neu:
    `16ff71d` + `d96b0ae` → **`a7018dc`**; `f5a5256` + `53c5121` → **`3adf214`**. Bäume gleich
    (`a7018dc` = Baum von `d96b0ae`, `3adf214` = Baum von `53c5121`), `git diff` gegen die Sicherung
    leer, `origin/phase-a` unverändert. `tools/test.sh` im Temp-Worktree: beide grün, 32 Schritte.
    Die Hashes `16ff71d`, `d96b0ae`, `f5a5256`, `53c5121` in den Absätzen oben gibt es nur noch auf
    dem Sicherungszweig.
  - **Commits danach**, je im Temp-Worktree grün (32 Schritte, nichts übersprungen): `d1e972f`
    (`CLAUDE.md`: Pipes), `fb85d70` (Werteprüfung: überholte Ausnahmen, Regel zur Ausnahmeliste),
    `ae4e394` (MAC-Adressen aus dem Dokumentationsbereich), `5e062cc` (Design ohne fremde Schrift),
    `016b2d4` (Ladeprüfung: Probe mit vollem Papierkorb).
  - **Werteprüfung.** (a) Die Ausnahmeliste wird als ganze Datei nicht durchsucht (Vergleich des
    absoluten Pfads mit der Liste neben dem Skript) – als bewusste Regel im Skript und in
    `docs/technik.md`, «Tests». (b) Befund: In der CI setzte die Prüfung auf überholte Ausnahmen
    schon richtig aus (Art nicht gesucht); mit einem **anderen Benutzernamen** (Mac) wurde die Art
    aber gesucht, die Ausnahme der LICENSE traf nichts und galt als überholt – der Test wäre dort
    rot gewesen. Behoben (`werte-pruefen.ueberholte`), der Test stellt CI und anderen Rechner nach.
    (c) Beide MAC-Adressen ersetzt, im Bluetooth-Test auch die des namenlosen Geräts, damit die
    geprüfte Reihenfolge dieselbe bleibt; 22 Ausnahmen statt 24.
  - **kora (0.8 Nr. 91).** Installiert: `kora-icon-theme` **2.0.6-1** (AUR, GPL3; liefert `kora` und
    `kora-pgrey`, kein `kora-light`). Gegen die Kopie im Home: `index.theme` gleich
    (`Inherits=breeze,hicolor`, keine Versionszeile); 9821 Dateien und 13707 Symlinks gegen 9823
    und 13706, keiner kaputt; nur im System `apps/scalable/proton-mail.svg` (Symlink), nur im Home
    ein Hilfsskript und eine doppelte Datei mit Leerzeichen im Namen; Inhalt verschieden nur bei
    `application-x-drawy.svg` und dem Cache. Die Kopie im Home ist also praktisch derselbe Stand;
    der Symlink-Verlust von 2.0.0 betrifft 2.0.6 nicht. **Auflösung** (Index der Shell mit
    `IconThemeIndex.js` nachgebildet, nur Systemordner): feste Namen `user-trash`,
    `user-trash-full`, `application-x-executable`, `image-missing` aus kora; von 52 Symbolnamen
    (diese vier und die sichtbaren Desktop-Einträge unter `/usr/share/applications`) 44 aus kora,
    7 aus hicolor (eigene Symbole von Programmen, die kein Thema führt), 1 gar nicht (`hwloc`),
    **keiner aus breeze**. Kette: kora → breeze → hicolor, danach das Ersatzthema von Qt. Die sieben
    Ersatzsymbole und die Papierkörbe aus kora und breeze ausserhalb der Shell gerendert: Ecken
    durchsichtig; alle Dateien von kora, breeze und hicolor: kein Symbol mit schwarzen Ecken,
    Adwaita: 16 (`offene-faelle.md`). Nebenbefund für E2/E3: Das AUR-Paket führt breeze nur als
    `optdepends` (6.2).
  - **Designs:** Befunde und Vorschlag für einen Test in `offene-faelle.md`, «Ladeprüfung»
    («Verweise im ausgelieferten Design»). Kein eigenes Symbolthema für hell.
  - **Bergbild der Sperre:** Standbild, das die Shell mit `ffmpeg` aus
    `design/kde/bilder/jagged-peaks-wolkenzug.mp4` zieht (im Temp-HOME des Laufs
    `~/.cache/alpe/video-wallpaper/<MD5 des Pfads>.jpg`; die eingespielte Videodatei ist byte-gleich
    mit der im Repo). **Die Lizenz ist im Repo nicht belegt:** `NOTICE` nennt die drei Dateien unter
    `design/kde/bilder` nicht, die Dateien tragen keine Urheberangabe; es gibt nur die allgemeine
    Aussage, Bilder kämen beim Export nur als bestätigte eigene mit. Offen beim Maintainer.
  - **`wt-alt`:** lag unter `/tmp/claude-1000/h7` und **hat den Neustart vom 23.11.2026 (18:22) nicht
    überlebt** – `/tmp` ist flüchtig; Git führt den Worktree noch als «prunable». Gebraucht wird er,
    bis die sporadischen Meldungen (Notizblock «Tab file does not exist», `DeferredAction` «flush is
    not a function») geklärt sind. Wiederherstellen: `git worktree prune`, dann `git worktree add
    --detach <Ordner> ba4ddbc` und die heutige Ladeprüfung als unversionierte Kopie nach
    `entwicklung/lp-offen/` darin. Nicht neu angelegt.
  - **Haltprüfung auf dem Endstand `016b2d4`** (kora aus dem System; je 1 Lauf, alle gültig,
    143–148 s): Hyprland «gesperrt» 39 gleich, Hyprland «offen» 39 gleich, KWin «gesperrt» 39 von
    39 – nichts neu, nichts weg. **KWin «offen»: 38 gleich und eine neue Meldung**,
    `@Alpe/Widgets/AlpeTextField.qml: TypeError: Property 'snapTo' of object SpringMotion… is not a
    function`. Gegengemessen (0.8 Nr. 76), je drei weitere Läufe: Endstand 0 von 3, Stand vor den
    heutigen Änderungen (`53c5121`) 0 von 3 – zusammen **1 von 4 auf dem Endstand, 0 von 3 davor**;
    das belegt weder Herkunft noch Alter. Die Oberfläche unterscheidet sich zwischen beiden Ständen
    nur um die entfernte Schrift des abgeschalteten Uhr-Widgets. Nicht in die Grundlinie
    aufgenommen, offener Fall. Gegenprobe mit stummem Systembus unter KWin bestanden (263 s).
    qmllint 4900 gegen 4902, nichts neu (dieselben zwei weg). `go vet ./...` ohne Meldung.
    **Bilder «offen» unter Hyprland:** Leiste mit Arbeitsflächen-Pille, Starter mit Alpe-Zeichen,
    46°, 48°, 2 %, Uhr, Wetter (3 °C), Ton und Mikrofon; Material-Vorlage mit Alpe-Zeichen; unten in
    der kleinen gerundeten Dock-Fläche **der Papierkorb aus kora, ohne schwarzes Quadrat** – leer
    ein grauer Eimer, mit `ALPE_LP_PAPIERKORB=voll` derselbe Eimer mit Papier darin.
  - **Zwischenfall (23.11.2026):** Ein einzelner Go-Testlauf von Hand
    (`HOME=<Temp> GOMODCACHE=$(go env GOMODCACHE) … go test ./internal/server/network`) legte einen
    schreibgeschützten Modul-Cache (80 MB) unter `/tmp/claude-1000/k/gh` an: Die Shell wertete
    `go env` schon mit dem Temp-HOME aus. Kein Schaden am Repo oder am echten HOME; der Ordner liegt
    noch dort (nicht entsperrt), verschwindet mit dem nächsten Neustart. Die Werte künftig vorher in
    eigene Variablen lesen.
  - **Angehalten.** Keine Läufe und keine Scopes offen; Worktrees: nur der Arbeitsbaum (und der
    verwaiste Eintrag `wt-alt`). Nichts gepusht.
- **Zweite Runde am 23.11.2026 (nur Doku, kein Code; darum keine Ladeprüfung).**
  - **`1afca9b` NOTICE (0.8 Nr. 95):** Bilder des Designs vom Maintainer, teils mit KI-Werkzeugen
    erstellt, CC0 1.0. Bestand der übrigen Medien ohne Herkunftsangabe in `offene-faelle.md`
    («Medien ohne Herkunftsangabe»): Logos unter `assets/logo/logo/`, Karten des Radar-Plugins,
    Radar-Musterdatei, sieben Hintergrundmuster, Markenzeichen und Paketformat-Zeichen aus dem
    Ursprung, fcitx5-Bilder, Drucker-Testseite (PDF-Titel noch mit dem Namen des Ursprungs).
  - **`docs/plugins-anpassen.md` überarbeitet.** Geprüft: Alle 44 früheren `Dank*`-Hüllen waren
    reine Weiterleitungen; `DButton`/`DankButton`, `DDropdown`/`DankDropdown`, `DToggle`/`DankToggle`
    führen je zum selben Typ, und die Schnittstellen von neun geprüften Typen sind gegenüber dem
    Stand des Ursprungs unverändert; `AlpeListView` und `AlpeSpinner` gibt es. **Abweichung in der
    Anleitung, berichtigt:** Die Tabelle schrieb alle `Dank*`-Typen `qs.Alpe.Widgets` zu; zehn
    bleiben in `qs.Widgets` bzw. `qs.Modals.Common`, drei liegen in `qs.Alpe.Common`. Die
    `plugin.json` von hueManager 0.5.0 und sathiAi 1.26.46 (nur gelesen) enthalten weder
    `requires_dms` noch `dankbar-widget` noch `"requires"` – keine Pflichtänderung. Die Seiten-ID
    `plugins` gilt in 1.1 weiter. Neue Prüfbefehle je Plugin, an Kopien in einem Temp-Ordner
    durchgespielt. `">=1.0"` gilt nur bis G1 (Aufgabe bei G1 in 10).
  - **`~/alpe-plugins` (nur gelesen):** kein Remote, ein Commit. Vorhanden: Änderungsvermerk mit
    Datum im Kopf von `CalculatorLauncher.qml`, `CHANGES.md`, `LICENSE` byte-gleich mit dem
    Original. **Es fehlt:** `CHANGES.md` nennt die geänderte `README.md` (vorangestellter Hinweis
    zu Alpe) nicht. Vor dem ersten Push nachtragen; die Umstellung auf `">=1.1"` in G1 braucht
    einen eigenen datierten Eintrag.
  - **Mac-Test für den Stand nach D7 neu gefasst** (`offene-faelle.md`): eigenständiger Ablauf,
    Sicherungen `.vor-d7` (F1 lässt `.vor-phase-a` und `.vor-d7` aus, 10), Sperre nicht auslösen,
    `lockAtStartup` in der Kopie ausschalten, alle vier Repo-Plugins, Nachtlicht, Papierkorb in
    zwei Durchgängen (kora-Tag `v2.0.6` im Ursprung vorhanden), Tabelle für Commit und Ergebnis.
    Der Abschnitt «Rückweg zu 1.0 nach dem Test» ist gestrichen (ohne Zweck).
  - **Geprüft:** `1afca9b`, `308ff7d` (Plugin-Anleitung), `48cf23c` (Plan, Mac-Test) je auf dem
    Commit im Temp-Worktree mit `tools/test.sh` grün (32 Schritte, nichts übersprungen). Kein
    Commit dieser Runde ändert Code der Shell oder des Dienstes; die Haltprüfung auf `016b2d4`
    gilt weiter. **Angehalten**, nichts gepusht.

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
| 6 | **Prüfregel ab D4:** `bash tools/test.sh` nach jedem Commit. Die Ladeprüfung läuft **einmal pro Halt** auf dem Endstand unter KWin und Hyprland; nur wenn sie neue Meldungen zeigt, werden die Commits dazwischen einzeln geprüft. Keine Überwachungen, die sich periodisch neu stellen. **Ergänzt (0.8 Nr. 63):** Zur Haltprüfung gehört qmllint (`/usr/lib/qt6/bin/qmllint`) über `shell/` gegen `entwicklung/qmllint/grundlinie.txt` (4902 Meldungen, gezählt mit dem eingecheckten Skript auf `6305cb1`); neue Meldungen werden einzeln eingeordnet. **Ergänzt (0.8 Nr. 70–72):** Die Ladeprüfung läuft bei jedem Halt in beiden Varianten – «gesperrt» und «offen» (`--offen`) –, je unter KWin und Hyprland, gegen die jeweilige Grundlinie; dazu ein Bild der Variante «offen» unter Hyprland mit `alpe-dienst screenshot full` (`--bild`), das angesehen und beschrieben wird. Vor jedem Commit `git diff --cached --name-status` gegen die beabsichtigte Liste, Commit nur mit genannten Pfaden; `tools/test.sh` auf dem Commit selbst im Temp-Worktree. **Ergänzt (0.8 Nr. 76):** Grundlinien können Meldungen als sporadisch kennzeichnen, mit beobachteter Häufigkeit (`SPORADISCH k/n: …`); eine neue Meldung, die nicht in jedem Lauf auftritt, wird vor dem Einordnen mehrfach gegen den Stand vor der Änderung gegengemessen. **Ergänzt (0.8 Nr. 77):** «offen» ist das ausgelieferte Design **plus Abdeckungs-Zusätze** im Temp-HOME (`workspaceSwitcher` und `launcherButton` im Logo-Modus `"alpe"` eingeschaltet), nicht das Design selbst; ein Hyprland-Lauf ohne IPC (Sockets fehlen, `ServerNotFoundError`) ist gescheitert und liefert nichts für die Grundlinie. **Ergänzt (0.8 Nr. 81):** Der Ersatz-Systembus der Ladeprüfung antwortet; ein Lauf, in dem die Oberfläche nicht `Connected (API v…)` meldet, ist unter beiden Compositors gescheitert und liefert nichts für die Grundlinie. **Ergänzt (0.8 Nr. 84):** Die Gegenprobe mit stummem Ersatz-Systembus (`ALPE_LP_STUMMER_BUS=1`) gehört **nicht** zur Haltprüfung; sie lief einmal nach der Behebung im Dienst unter beiden Compositors und läuft danach nur bei Bedarf (Änderungen am Start des Dienstes oder an `core/internal/systembus`). **Geändert (0.8 Nr. 85), ersetzt den Satz davor:** Die Gegenprobe mit stummem Ersatz-Systembus **gehört zur Haltprüfung** – bei jedem Halt einmal, unter einem Compositor (Variante «gesperrt» genügt). Sie besteht, wenn die Oberfläche `Connected` meldet und der Dienst den Ausfall genau einmal meldet; mit der Grundlinie wird sie nicht verglichen. **Ergänzt (0.8 Nr. 71, 103, 112; 25.11.2026):** Pflicht bei jedem Halt sind vier Haltbilder – `halt-hyprland-offen.png`, `halt-hyprland-gesperrt.png`, `halt-kwin-offen.png`, `halt-kwin-gesperrt-schreibtisch.png` –, jedes angesehen und beschrieben; die zwei KWin-Bilder über `kwinbild.py`, solange Weg A besteht. Ein Bildlauf gilt zugleich als Lauf seiner Variante gegen die Grundlinie (`kwin --bild-schreibtisch` also als KWin «gesperrt»; Herkunft: Antwort der Gegenprüfung zu 1.5 im Nachtlauf vom 25.11.2026, wie bei der Haltprüfung auf `4d71036` gehandhabt). |
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
| 56 | **qmllint** (Qt 6.12, erzeugte `qmldir` je Ordner) über `shell/`: vor D7.7a und danach gleich viele Meldungen; die 17 abweichenden Zeilen unterscheiden sich nur im Temp-Pfad bzw. im umbenannten `CalendarDuxBackend.qml`. Keine neue Meldung. Die damals genannte Zahl stammte aus einem nicht eingecheckten Aufruf und gilt nicht mehr; massgebend ist Nr. 63. |

Entscheide nach D7.7b (22.11.2026):

| # | Entscheid |
|---|---|
| 57 | **Sicherungen werden nie umbenannt, gelöscht oder verändert.** `gtk-theme.dms-backup` und `icon-theme.dms-backup` werden nicht mehr auf `*.alpe-backup` umbenannt (so stand es in D7.7b2): Alpe liest den neuen Namen und, wenn es ihn nicht gibt, den alten; wo nötig, wird kopiert, nie umbenannt. Umsetzung (`shell/Common/settings/Sicherungen.js`): Die Sicherung des GTK-Themas schreibt die Shell nur – gibt es eine unter einem der beiden Namen, entsteht keine zweite. Die Sicherung des Symbolthemas verbraucht die Shell beim Zurückgeben (lesen, löschen); die Sicherung aus 1.0 wird darum genau einmal unter den neuen Namen kopiert, eine Marke `~/.local/state/alpe/sicherung-1.0-icon-theme.uebernommen` verhindert, dass sie nach dem Verbrauch der Kopie ein zweites Mal gilt. Den alten Namen (und die Marke) räumt erst «Umzug-Ende» ab (0.8 Nr. 23). Test `tests/test_sicherungen.mjs`: alte Sicherung nach jedem Zugriff unverändert vorhanden (Inhalt, Änderungszeit, Inode). **Dasselbe gilt in F1:** Beim Umschreiben alter IPC-Ziele und Befehle (7.4 Schritt 6) sind Sicherungsordner wie `~/.config/hypr/.dms-backups/` ausgenommen und werden nicht verändert. Am Mac kommt `dankdash` nur in einer solchen Sicherung vor, aktiv benutzt wird es nicht. Der Dienst legt neue Sicherungen der Hyprland-Dateien ab D7.7e unter `.alpe-backups/` an; der alte Ordner bleibt, wie er ist. |
| 58 | **Fensterregeln, Rückweg:** `alpe umzug --zurueck` setzt `-- ALPE-RULE:` und die neuen Regel-IDs (`alpe-floating-windows`, `alpe-window-opaque`, `alpe_rule_N`) gezielt auf `-- DMS-RULE:` und die alten IDs zurück, damit 1.0 nach dem Rückweg auch Regeln bearbeiten kann, die nach dem Umzug geändert wurden. Mit Test in F1. **Allgemein (7.2 «Rückweg»):** Der Rückweg stellt den Zustand zum Zeitpunkt des Umzugs wieder her; was danach geändert wurde und nicht ausdrücklich zurückgesetzt wird, ist aufzuzählen (Liste in 7.7, vom Umzug am Ende von `--zurueck` ausgegeben). |
| 59 | **Ausgabedateien: Auslöser «alte Datei existiert» bestätigt** (Nr. 48). F1 stellt je Programm die Einbindung auf den neuen Namen um (Tabelle 7.6); **Links und doppeltes Schreiben fallen erst mit «Umzug-Ende» weg**, nicht schon mit F1 (bis dahin trägt der alte Name auch den Rückweg). `alpe-shell` liefert `alpe-open.desktop` selbst aus (E3, 6.1); F1 stellt `mimeapps.list` von `dms-open.desktop` auf `alpe-open.desktop` um. Ob Vencord beim Wechsel über den Link neu lädt: `offene-faelle.md`, ohne Frist. |
| 60 | **Neovim:** Die base46-Anbindung (`nvim/colors/dms.lua`, Lualine-Thema `dms`, `_DMS_SUPPORT`) bleibt unverändert und steht mit «solange die Anbindung besteht» auf der Ausnahmeliste. Keine offene Frage mehr. |
| 61 | **`shell/translations/WORKFLOW.md` entfernt.** Ersatz: ein kurzer Absatz im README des Übersetzungsordners – `de` und `en` werden nur im Repo gepflegt, einen externen Abgleich gibt es nicht mehr. |
| 62 | **`go vet` und die mockery-Attrappen** (ersetzt den Weg aus Nr. 54): Die Dateien in `internal/mocks` werden nicht von Hand geändert und nicht von der Prüfung ausgenommen, sondern mit dem aktuellen mockery neu erzeugt bzw. über `.mockery.yml` so eingestellt, dass die Meldung nicht mehr entsteht (D7.7h). Ziel bleibt `go vet ./...` ohne Meldung am Zwischenhalt. **Umgesetzt in D7.7h:** Neu erzeugen allein genügt nicht – auch mockery 3.9.1 schreibt für jede Schnittstellen-Methode einen gleichnamigen Expecter-Helfer, und `go vet` (stdmethods) meldet `MarshalJSON` mit fremder Signatur (7 Attrappen der gonetworkmanager-Schnittstellen). mockery kennt keine Einstellung, um einzelne Methoden auszulassen (nur `boilerplate-file`, `mock-build-tags`, `unroll-variadic`). Darum Konfiguration: `.mockery.yml` benutzt `template: file://.mockery/testify.templ`, eine Kopie der Vorlage «testify» aus mockery 3.9.1 (BSD-3-Clause, in NOTICE) mit einer einzigen Bedingung: kein Expecter-Helfer für `MarshalJSON`/`UnmarshalJSON`. Kein Test benutzte ihn. Alle 22 Attrappen sind damit neu erzeugt, `go vet ./...` ist ohne Meldung. |
| 63 | **qmllint wird Teil der Haltprüfung**, nicht von `tools/test.sh`: `/usr/lib/qt6/bin/qmllint` über `shell/` gegen eine eingecheckte Grundlinie. Bei jedem Halt vergleichen; neue Meldungen werden einzeln eingeordnet (behoben oder mit Begründung in die Grundlinie). Prüfregel 0.7 Nr. 6 und `CLAUDE.md` nachgeführt. **Befund bei der Umsetzung:** Das Skript `entwicklung/qmllint/qmllint-pruefung.py` (Baum aus `entwicklung/mklint.py`, Aufruf `qmllint -I <Baum>`, Meldungen ohne Zeile/Spalte/Temp-Pfad als Mehrfachmenge) zählt **4902** Meldungen. Die Liste von Nr. 56 enthielt darüber hinaus `missing-property` (683) und `incompatible-type` (15) auf eigenen Singletons (`FileBrowserMetrics`, `SettingsMetrics`, `DisplayConfigState` …) aus dem damaligen, nicht eingecheckten Aufruf – mit dem eingecheckten lassen sie sich nicht nachstellen (geprüft: `mklint.py` erkennt alle 145 Singletons). **Nachprüfung zum Zwischenhalt (22.11.2026):** Das eingecheckte Skript, unverändert vom Endstand, über `shell/` von `6305cb1` (D7.6, Temp-Worktree, `--shell`): **4902 Meldungen** über 1193 Dateien; gegenüber `grundlinie.txt` unterscheidet sich eine Zeile nur im Dateinamen (`CalendarDankBackend.qml`, seit D7.7a2 `CalendarDuxBackend.qml`). **Die Grundlinie ist 4902** (`entwicklung/qmllint/grundlinie.txt`); die frühere Zahl aus Nr. 56 fällt weg. |
| 64 | **Vorstufe D7.8a vor D7.8** (Entscheid 22.11.2026): Die Fundstellen der Namensprüfung ausserhalb der Dateien, die D7.8 entfernt (167 auf `efb3216`; 166 zum Zwischenhalt, dazu eine Zeile des Tests der Probe), werden einzeln eingeordnet (Tabelle `entwicklung/umbenennen/d7-8a-fundstellen.tsv`). **Stellen, die bei der Migration alte Namen lesen müssen, werden nicht umbenannt**, sondern gehören zur Ausnahme «Lesen alter Namen bei der Migration» (2.3.3), Frist «Umzug-Ende». Solche Bereiche stehen zwischen zwei Kommentarzeilen `alpe-namen-ausnahme: umzug-ende` (Anfang und Ende); `tools/namen-pruefen.py` wertet die Marken aus, statt dass jede Zeile in `namen-ausnahmen.txt` steht. Eine Marke ohne Gegenstück, mit unbekannter Frist oder um einen Bereich ohne Fundstelle ist selbst ein Fund; `--bereiche` listet alle Bereiche. Test in `tests/test_umbenennen.py`. **Übersetzungsschlüssel und Kopien in den Testumgebungen werden umbenannt.** |
| 65 | **`internal/version`:** `CompareVersions` bleibt (Aufrufer in `cmd/alpe-dienst` und `internal/config`, darum bleibt das Paket als gemeinsamer Ort). Der Rest der Aktualisierungsprüfung des Ursprungs ist toter Code und wird entfernt: `VersionFetcher`, `GetInstalledShellVersion`, `GetLatestShellVersion`, `GetShellVersionInfo…`, die Attrappe `internal/mocks/version` samt Eintrag in `.mockery.yml`, `internal/netfetch/release.go`. Eine eigene Aktualisierungsprüfung gegen `alpe-shell/alpe` kommt allenfalls in Phase B (`offene-faelle.md`). |
| 66 | **mockery-Vorlage `core/.mockery/` freigegeben.** Die benutzte Version **mockery v3.9.1** steht im Repo: `MOCKERY_VERSION` in `core/Makefile`, Ziel `make -C core mocks` (bricht bei einer anderen Version ab), `CLAUDE.md`. |
| 67 | **User-Agent mit der echten Version**, Form `Alpe/1.1.0 (+https://github.com/alpe-shell/alpe)`: Die Nummer kommt aus derselben Quelle wie `Brand.version` (`shell/Common/Brand.qml`, vom Makefile beim Bau eingesetzt), auf drei Stellen ergänzt. Gilt für alle eigenen Abrufe des Dienstes (Liedtexte, Wetter, `netfetch`); ein Bau ohne Makefile meldet `Alpe/dev`. Kein fest eingetragenes `Alpe/1` mehr. |
| 68 | **D-Bus-Objektpfade `/io/github/alpe_shell/Alpe/…` freigegeben** (D7.7g). **Layer-Namensräume des Dienstes:** `alpe-colorpicker` und `alpe-screenshot` waren freigegeben, mit der Auflage zu prüfen, ob die Layer-Regeln der eingebetteten Hyprland-Vorlagen alle Alpe-Layer erfassen. **Befund:** nein. Die Vorlage `hyprland.lua` schaltet Animationen für `^(quickshell)$` und `^alpe:.*` ab; die beiden Flächen des Dienstes (Pipette, Bildschirmfoto-Auswahl) trugen einen Bindestrich und fielen durch – ebenso die Regel der Oberfläche `^alpe:.*$` (xray). **Im Ursprung war es gleich:** Oberfläche `dms:<name>`, Dienst `dms-colorpicker`/`dms-screenshot`, Regel `^dms:.*`; die Lücke ist geerbt, nicht in D7 entstanden. **Vereinheitlicht:** ein Schema `alpe:<name>` für alle Layer, der Dienst benutzt `alpe:colorpicker` und `alpe:screenshot`. Test: kein Layer-Namensraum in `shell/` und `core/` ausserhalb des Schemas, die Regel der Vorlage erfasst alle. F1 (7.4 Schritt 6) schreibt eigene Regeln auf die neuen Namen um. |
| 69 | **Fremde Plugins: zwei Ordner.** Die angepassten Fassungen kommen nach `~/.config/alpe/plugins`; die Kopien unter `~/.config/dms/plugins` bleiben für 1.0 unverändert, weil auf beiden Rechnern noch 1.0 läuft. `docs/plugins-anpassen.md` führt das getrennt für PC (hueManager, sathiAi) und Mac (hueManager, calculator), fish-tauglich. **Für F1:** Der Umzug kopiert keine unangepassten Fremd-Plugins über vorhandene Fassungen unter `~/.config/alpe/plugins` und meldet unbekannte Plugins, die ohne Anpassung unter 1.1 nicht laden (7.2). |
| 70 | **Ladeprüfung in zwei Varianten** (Entscheide zum Halt nach D7, 22.11.2026): **«gesperrt»** wie bisher (das ausgelieferte Design sperrt beim Start, `lockAtStartup`) und **«offen»** ohne `lockAtStartup` und mit sichtbarer Material-Vorlage (kein Bild, keine Farbe als Hintergrund; `--offen`). Beide gehören ab jetzt zu jedem Halt, unter KWin und Hyprland, je mit eigener Grundlinie (`grundlinie-<compositor>.txt`, `grundlinie-<compositor>-offen.txt`). |
| 71 | **Bild beim Halt:** `alpe-dienst screenshot full` im verschachtelten Hyprland der Variante «offen» ist der feste Weg (`--bild DATEI`); grim wird nicht installiert und nicht mehr gesucht. Das Bild wird angesehen und dem Maintainer beschrieben. **Ergänzt am 25.11.2026 (Entscheid des Maintainers): Pflicht bei jedem Halt sind vier Haltbilder** – `halt-hyprland-offen.png` (`hyprland --offen --bild`), `halt-hyprland-gesperrt.png` (`hyprland --bild-sperre`, Sperre der Shell), `halt-kwin-offen.png` (`kwin --offen --bild`) und `halt-kwin-gesperrt-schreibtisch.png` (`kwin --bild-schreibtisch`, Nr. 112: Schreibtisch im ausgelieferten Design, nicht die Sperre). Jedes wird angesehen und beschrieben. Die zwei KWin-Bilder entstehen über `kwinbild.py` und gelten, solange Weg A besteht (Nr. 103) (Folgerung, nicht Teil des Entscheids: fällt Weg A, ist neu zu entscheiden). Festgeschrieben in `CLAUDE.md`. |
| 72 | **Commits:** Vor jedem Commit `git diff --cached --name-status` gegen die beabsichtigte Liste prüfen und nur mit ausdrücklich genannten Pfaden committen (`git commit -- PFAD…`), nie den ganzen Index. `tools/test.sh` läuft immer **auf dem Commit selbst in einem Temp-Worktree**, nicht auf einem baumgleichen Vorgänger und nicht auf dem Arbeitsbaum. Nachgeprüft so: `a364d81`, `46941e1` (Ergebnis im «Stand»). |
| 73 | **WirePlumber:** F1 benennt `~/.config/wireplumber/wireplumber.conf.d/51-dms-audio-aliases.conf` in `51-alpe-audio-aliases.conf` um; danach schreibt `AudioService` nur noch den neuen Namen. Der Rückweg benennt zurück. **Es existieren nie beide Dateien gleichzeitig** (WirePlumber läse beide). Bis F1 schreibt die Shell den alten Namen (Ausnahmeliste, Frist F1); F1 stellt `AudioService.qml` im selben Schritt um (7.2, 7.6). |
| 74 | **Übersetzungsskripte des Ursprungs:** Skripte für den Abgleich mit dem Ursprung oder POEditor werden entfernt. Das Skript, das die Texte aus `qsTr()`/`I18n.tr()` herauszieht, damit `de.json` und `en.json` vollständig bleiben, wird angepasst und behalten. Einordnung je Skript im «Stand». |
| 75 | **Layer der Pipette:** Die Fläche des Dienstes heisst `alpe:eyedropper` statt `alpe:colorpicker` (Nr. 68), damit sie sich klar vom Modal `alpe:color-picker` unterscheidet. Mit Test. F1 schreibt Layer-Regeln mit `dms-colorpicker` auf `alpe:eyedropper` um (7.4 Schritt 6). |
| 76 | **Sporadische Meldungen** (Entscheid 22.11.2026, nach der Messung zu `Cannot find member data`): Eine Grundlinie der Ladeprüfung kann eine Meldung als sporadisch kennzeichnen, mit der beobachteten Häufigkeit (`SPORADISCH k/n: <Meldung>`; `--grundlinie` schreibt die Marke selbst, wenn eine Meldung nicht in jedem Lauf vorkommt). Eine sporadische Meldung darf auftreten oder fehlen; sie zählt weder als neu noch als weg. **Eine neue Meldung, die nicht in jedem Lauf auftritt, wird vor dem Einordnen mehrfach gegen den Stand vor der Änderung gegengemessen** – wenige Läufe allein beweisen bei einer niedrigen Rate weder Herkunft noch Behebung; ein `git bisect` setzt eine Meldung voraus, die auf dem schlechten Stand verlässlich erscheint. Prüfregel 0.7 Nr. 6 und `CLAUDE.md` nachgeführt. |
| 77 | **Variante «offen» = ausgeliefertes Design plus Abdeckungs-Zusätze** (Entscheid 22.11.2026): Im Temp-HOME der Variante «offen» werden zusätzlich eingeschaltet: die Arbeitsflächen-Anzeige (`workspaceSwitcher`) und der Starter-Knopf (`launcherButton`) im Logo-Modus `"alpe"` – beide sind im ausgelieferten Design aus. So berühren Lauf und Bild die Anbindung an den Compositor und das Alpe-Zeichen. **Das Testprofil «offen» ist damit nicht das ausgelieferte Design**; dieses prüft die Variante «gesperrt». **Hyprland-IPC:** Ein Lauf unter Hyprland gilt nur, wenn Signatur und beide Sockets bei der Shell ankommen (`umgebung.log`) und die Shell kein `ServerNotFoundError` meldet; `$ALPE_LP_TMP` darf höchstens 19 Zeichen lang sein (`/tmp/claude-1000` geht), sonst bricht der Lauf ab. Prüfregel 0.7 Nr. 6 und `CLAUDE.md` nachgeführt. |
| 78 | **Design ohne Zustand, bestätigt** (Entscheid 22.11.2026 zu den Rückfragen aus `21f6ff2`): `dockPins` ist aus dem ausgelieferten Design **entfernt, nicht geleert** (ein leeres Dock im Design überschriebe beim Einspielen die Anheftungen des Nutzers). `WindowClasses` des Unschärfe-Effekts ist **ganz entfernt**. `recentColors` kommt aus `design/kde/session.json` heraus. |
| 79 | **Export der Session über eine feste Liste** (Entscheid 22.11.2026): `tools/design.py` übernimmt aus `session.json` nur Schlüssel, die zur Gestaltung gehören (etwa Material-Vorlage und Form), statt einzelne Zustandswerte herauszufiltern. Jeder Schlüssel der Session ist im Code als Gestaltung oder Zustand eingeordnet; ein Test verlangt die Einordnung für jeden Schlüssel aus `SessionSpec.js` und `SharedSessionSpec.js`. Die Liste steht in 7.8. Eigener Commit. |
| 80 | **Dienst hängt am Systembus – Reihenfolge der Behebung** (Entscheid 22.11.2026): (1) zuerst die Prüfumgebung, (2) dann der Dienst, (3) die Grundlinien der Ladeprüfung erst messen, wenn beides committet ist. |
| 81 | **Prüfumgebung** (eigener Commit): Die Richtlinie des Ersatz-Systembusses der Ladeprüfung wird so ergänzt, dass er antwortet. **Jeder Lauf prüft, dass die Oberfläche `Connected` meldet; fehlt die Meldung, gilt der Lauf als gescheitert und liefert nichts für die Grundlinie** (wie beim fehlenden Hyprland-IPC, Nr. 77). Prüfregel 0.7 Nr. 6 und `CLAUDE.md` nachgeführt. |
| 82 | **Dienst: Zeitgrenze für alle Verbindungen zum Systembus**, nicht nur für Gamma. Zuerst ein kurzer Plan unter `docs/plan/` (`dienst-systembus.md`), Umsetzung erst nach Freigabe. Als erster Vorschlag zu prüfen: eine einzige, vom Dienst selbst aufgebaute Systembus-Verbindung mit Zeitgrenze über einen Context (godbus v5), an alle Manager weitergereicht, kein Aufruf von `dbus.SystemBus()` mehr; bei Scheitern gelten die betroffenen Manager als nicht verfügbar (eine Meldung, erneute Versuche im Hintergrund mit wachsendem Abstand); der Wayland-Teil von Gamma bleibt synchron, nur die Überwachung des Ruhezustands wird nach dem Start der Schnittstelle nebenher eingerichtet; Grundsatz: keine Sperre über einen Bus- oder Netzaufruf hinweg. Ob der Wayland-Teil bei einem stummen Compositor hängen kann, ist nicht belegt und bleibt ein offener Fall ohne Umbau. Grundlinien, Vorschlagsdatei der Übersetzungen und der Rest des Halts kommen nach der Behebung. |
| 83 | **Einspielen filtert die Session wie der Export** (Entscheid 22.11.2026, ergänzt Nr. 79): `tools/design.py` wendet die feste Liste `SESSION_GESTALTUNG` auch beim Einspielen an. Zustandswerte aus einem Design (etwa Anheftungen aus älteren Designs) werden nicht übernommen. Mit Test. Eigener Commit, **nach der Behebung im Dienst**; danach die Neumessung der Grundlinien wie geplant (Nr. 80). |
| 84 | **Plan `docs/plan/dienst-systembus.md` freigegeben wie vorgeschlagen** (22.11.2026): NetworkManager-Backend erst, wenn die Verbindung steht, kein Patch von `gonetworkmanager`; 3 s für den Aufbau, erneute Versuche ab 2 s verdoppelnd bis 60 s, ohne Ende; Abriss der Verbindung im Betrieb bleibt draussen (offener Fall). **Gegenprobe mit stummem Systembus** in der Ladeprüfung (Schalter `ALPE_LP_STUMMER_BUS=1`): läuft einmal nach der Behebung unter beiden Compositors, **danach nur bei Bedarf, nicht bei jedem Halt** (Prüfregel 0.7 Nr. 6 nachgeführt). Reihenfolge: Behebung im Dienst, Commit zum Einspielen (Nr. 83), Neumessung der Grundlinien. |
| 85 | **Gegenprobe mit stummem Systembus bei jedem Halt** (Entscheid 22.11.2026, ersetzt in Nr. 84 «danach nur bei Bedarf, nicht bei jedem Halt»): Sie läuft bei jedem Halt einmal mit, unter einem Compositor. Grund: Der Go-Test prüft nur die Bausteine; eine Rückkehr des Fehlers in der Startreihenfolge des Dienstes bliebe sonst unbemerkt. Prüfregel 0.7 Nr. 6 und `CLAUDE.md` nachgeführt. **Für G1 vermerkt:** `CHANGELOG.md`, Abschnitt 1.1, Eintrag zur Behebung «Dienst hing bei stummem Systembus, Oberfläche verband sich nie». |
| 86 | **6.7 vollständig entschieden** (22./23.11.2026, Vorlage `docs/plan/sperrbildschirm-dateien.md`). **Frage 1: Variante A** – das Systempaket des KDE-Sperrbildschirms (`/usr/share/plasma/shells/org.alpe.desktop`) bleibt unverändert, Eigenes steht in `kscreenlockerrc`, unter `~/.local/share/plasma/shells` liegt nichts mehr von Alpe. **Frage 2:** Eine vorhandene eigene `~/.config/alpe/hyprlock.conf` wird einmal übernommen (wenn `Layout` leer ist), danach nicht mehr gelesen; Umsetzung in F1. **Frage 3:** `layout.js` sofort aus der neutralen Vorlage – mit `56fcedd` erledigt und nachträglich bestätigt; die Prüfung auf persönliche Werte gilt für das ganze Repo (Nr. 88). **Frage 4:** Die Version in `metadata.json` des Sperrpakets wird beim Paketbau aus derselben Quelle wie `Brand.version` gesetzt; Umsetzung mit E1. **Umgesetzt am 25.11.2026 (E1):** `make sperrpaket` (Teil von `make build`) setzt das Paket unter `build/plasma/org.alpe.desktop` zusammen – `lockscreen/org.alpe.desktop`, dazu `HyprlockView.qml`, `layout.js` und der ganze Ordner `fonts` aus `shell/Modules/Lock/Alpe` – und schreibt die Version aus `Brand.qml` in `metadata.json` (die Datei im Repository bleibt, wie sie ist); `make install` legt es nach `/usr/share/plasma/shells/org.alpe.desktop`. Prüfung in `tests/test_version.py`. Das `OFL.txt` aus der Shell ersetzt dabei das gleichlautende des Pakets (nur andere Zeilenenden). |
| 87 | **Geschichte wird nicht umgeschrieben** (23.11.2026): weder `phase-a` noch `main` noch `v1.0`. Die persönlichen Pfade, die dort stehen (`layout.js` ab `bfc7243` auf `phase-a`; `shell/0001-Alpe-1.0-Zugerberg.patch` und fünf weitere Dateien in `v1.0`/`main`), bleiben in der Geschichte; **Behebung nur nach vorne.** |
| 88 | **Prüfung auf persönliche Werte im ganzen Repo** (22./23.11.2026): `tests/test_werte.py` durchsucht über `tools/werte-pruefen.py` alle versionierten Textdateien nach Pfaden in ein Home-Verzeichnis, Benutzer- und Rechnernamen, IP- und MAC-Adressen und Gerätekennungen. Ausnahmen in `tools/werte-ausnahmen.txt`, aufgebaut wie `tools/namen-ausnahmen.txt`: je Datei, Art und **erwartetem Wert**, dauerhafte mit Begründung, vorübergehende mit Frist; ein neuer Fund in derselben Datei schlägt an, eine Ausnahme ohne Fund gilt als überholt. |
| 89 | **Dock ohne angeheftete Programme: Frist vor E1** statt vor G1 (22.11.2026), weil es das Erste ist, was ein neuer Nutzer sieht. Ursachen untersucht am 23.11.2026 (`offene-faelle.md`, «Ladeprüfung»); über die Behebung entscheidet der Maintainer. |

Entscheide nach dem Halt zur Werteprüfung (23.11.2026):

| # | Entscheid |
|---|---|
| 90 | **«Geschichte nicht umschreiben» (Nr. 87) betrifft nur Veröffentlichtes.** Lokale Commits, die nach `origin/phase-a` liegen, dürfen zusammengelegt werden. So geschehen mit den beiden roten Commits: Sicherung als lokaler Zweig `sicherung/vor-zusammenlegen`, Zusammenlegen nicht-interaktiv (fixup über `GIT_SEQUENCE_EDITOR`), Endstand byte-gleich, `tools/test.sh` auf jedem neuen Commit im Temp-Worktree (Hashes im «Stand»). |
| 91 | **Symbolthema kora bleibt** das Symbolthema der mitgelieferten Designs und wird **als Abhängigkeit mitgeliefert, nicht ins Paket `alpe-shell` gelegt**. Arch: `depends` auf `kora-icon-theme` (AUR). Fedora: `kora-icon-theme` wird im eigenen COPR mitgebaut, `alpe-shell` verlangt es mit `Requires`. `get.sh` (F2) installiert kora auf beiden Systemen mit. Lizenz von kora: GPL-3.0, als getrenntes Paket verträglich mit MIT. Umsetzung in E3/E4 (6.2, 6.3, 6.4, Tabelle in 10). Befunde zur Systemfassung 2.0.6 im «Stand». |
| 92 | **Papierkorb im Dock: kein eigenes Symbol.** Mit kora als Abhängigkeit kommt der Papierkorb aus kora (belegt mit der Ladeprüfung «offen» unter Hyprland, leer und voll, «Stand»). Der Befund zu Adwaita 51 unter Qt 6.12 betrifft nur Nutzer, die selbst auf Adwaita umstellen (`offene-faelle.md`, ohne Frist, vor G1 neu beurteilen). |
| 93 | **Dock ohne Anheftungen: so lassen für 1.1.** Das ausgelieferte Design heftet nichts an; ein neuer Nutzer sieht das kleine Dock nur mit dem Papierkorb. Die Sichtbarkeit der Dock-Fläche wird **beim Mac-Test auf anderem Hintergrund neu beurteilt**. Der Fall mit Frist vor E1 (Nr. 89) ist damit geschlossen. |
| 94 | **Ausgaben von Prüfungen nicht durch eine Pipe kürzen** (`tail`, `head`, `grep`), ohne `pipefail` zu setzen; bevorzugt Ausgabe in eine Datei, Rückgabewert des Prüfbefehls selbst auswerten, danach den Schluss lesen (`CLAUDE.md`). **Neue eigene Testdaten** verwenden MAC-Adressen aus `00:00:5E:00:53:00/24` und IP-Adressen aus `192.0.2.0/24`, `198.51.100.0/24` oder `203.0.113.0/24`; die Werteprüfung nimmt genau diese Bereiche aus (`CLAUDE.md`, `docs/technik.md`). Die beiden MAC-Adressen mit Frist Phase B sind ersetzt, ihre Ausnahmen gestrichen. **Überholte Ausnahmen:** Eine Ausnahme gilt nur als überholt, wenn ihre Art in diesem Lauf gesucht wurde; für Benutzer- und Rechnernamen zusätzlich nur, wenn der gesuchte Name im Repository vorkommt. |
| 95 | **Bilder unter `design/kde/bilder`** (`jagged-peaks-wolkenzug.mp4`, `wallpaper.jpg`, `wall.png`): stammen vom Maintainer, teils mit KI-Werkzeugen erstellt, **Lizenz CC0 1.0** für alle drei. Abschnitt in `NOTICE` mit derselben Urheberangabe wie in `LICENSE` (Angabe des Maintainers vom 23.11.2026). Weitere Bilder, Videos und Klänge ohne Herkunftsangabe in `NOTICE` stehen als Liste in `offene-faelle.md` («Medien ohne Herkunftsangabe»); **nichts davon wird ohne Angabe des Maintainers eingetragen.** |

Nach dem Mac-Test vom 23.11.2026 (Auftrag des Maintainers vom 24.11.2026; Ergebnis und Zwischenfall in
`offene-faelle.md`, «Mac-Test»):

| # | Entscheid / Befund |
|---|---|
| 96 | **`lua` ist keine Abhängigkeit, `wireplumber` ist eine.** Weder Shell noch Dienst rufen das Programm `lua` auf (gesucht in `shell/`, `core/`, `plugins/`, `tools/`); `shell/scripts/bluez-card-profile.lua` startet `BluetoothService.qml` mit **`wpexec`** (Lua-Laufzeit von WirePlumber; unter Arch im Paket `wireplumber`, unter Fedora vor E3 mit `rpm -qf /usr/bin/wpexec` bestätigen). `lua` braucht nur `shell/tests/bluez-codec.test.mjs`; der Test überspringt sich ohne `lua` mit Begründung. **Ohne `wpexec`:** Die Codec-Auswahl meldet «Codec switching is unavailable. WirePlumber wpexec was not found.», der Rest von Bluetooth läuft. **E2/E3:** `wireplumber` in `depends` bzw. `Requires` (6.2, 6.3); `lua` nicht. **Bestätigt am 24.11.2026: `wireplumber` bleibt harte Abhängigkeit** (nicht `optdepends`/`Recommends`). Begründung: (1) `shell/Services/AudioService.qml` startet WirePlumber nach dem Schreiben der Alias-Datei selbst neu – `writeWireplumberConfig()` ruft `reloadWireplumberConfig()`, mit systemd `systemctl --user restart wireplumber`; die Shell setzt den Sitzungsverwalter also voraus, sobald jemand einem Audiogerät einen eigenen Namen gibt. (2) **Der Betrieb ohne WirePlumber ist nicht belegt:** Lautstärke und Geräteauswahl laufen über PipeWire, das einen Sitzungsverwalter braucht, und auf beiden Zielrechnern ist das WirePlumber; ob ein Rechner mit einem anderen Sitzungsverwalter brauchbar wäre, hat niemand geprüft. Dass F1 WirePlumber nicht voraussetzt (die Alias-Datei wird nur umbenannt, wenn es sie gibt, 7.2 Schritt 4), ändert daran nichts. Offen für E: der Zweig ohne systemd in derselben Funktion ruft `pkill -x wireplumber` (`offene-faelle.md`, «Aufgabe für E: `pkill -x wireplumber` …»; heute nicht geändert). |
| 97 | **Quickshell: Mindestversion bleibt 0.3.2; die Pragmas `RenderControl` und `DiskCache` kennt keine veröffentlichte Fassung.** Belege: (1) Das Programm `quickshell` 0.3.2 von Arch enthält die Pragma-Namen `UseQApplication`, `NativeTextRendering`, `IgnoreSystemSettings`, `RespectSystemStyle`, `DropExpensiveFonts`, `IconTheme`, `AppId`, `ShellId`, `DataDir`, `StateDir`, `CacheDir`, `Env`, `DefaultEnv` – die beiden nicht; die Warnung «Unrecognized pragma» stand darum bis zum 24.11.2026 auch am PC in allen vier Grundlinien der Ladeprüfung. (2) `src/launch/launch.cpp` auf `master` des Ursprungs (Spiegel `quickshell-mirror/quickshell`, gelesen am 24.11.2026) kennt dieselbe Liste, die Änderungsprotokolle bis `v0.3.2` und `next.md` nennen die beiden nicht. (3) Die beiden Zeilen stammen aus `shell.qml` der Dux Modular Shell (`a21d715`); welcher Bau von Quickshell sie versteht, ist **nicht belegt**. **Was ohne sie fehlt:** nichts Nachweisbares – auf beiden Rechnern lief Alpe nie mit einem Quickshell, das sie kennt. **Untergrenze 0.3.0** aus dem Protokoll des Ursprungs: «Unrecognized pragmas are no longer a hard error» – mit einer älteren Fassung lädt `shell.qml` gar nicht. **E2/E3:** `quickshell >= 0.3.2` (wie 6.2/6.3, getestet an PC und Mac). ~~Offen für den Maintainer: die zwei Zeilen stehen lassen (kosten zwei Warnungen) oder entfernen.~~ **Entscheid des Maintainers vom 24.11.2026: entfernt.** Die Zeilen `//@ pragma RenderControl` und `//@ pragma DiskCache` stammen aus `shell.qml` der Dux Modular Shell und werden von keinem verfügbaren Quickshell-Bau verstanden (belegt für das Arch-Paket 0.3.2 am PC und für `master` des Ursprungs, Belege 1 und 2; für das COPR-Paket 0.3.2 am Mac aus der gleichen Version gefolgert, nicht gemessen; ob es je einen Bau gab, der sie verstand, bleibt nach Beleg 3 offen); sie bewirkten nur die zwei Warnungen «Unrecognized pragma». `shell/shell.qml` trägt sie nicht mehr. **Die vier Grundlinien der Ladeprüfung sind um genau diese zwei Warnungen bereinigt, von Hand und sonst unverändert** – die einzige Stelle, an der Grundlinien in dieser Runde geändert wurden; neu gemessen wurden sie dafür nicht. Neue Zahlen der Einträge: KWin «gesperrt» 37, KWin «offen» 36, Hyprland «gesperrt» 39 (davon 2 sporadisch), Hyprland «offen» 38 (davon 1 sporadisch). Sollte ein künftiges Quickshell die beiden Pragmas einführen, ist neu zu entscheiden. |
| 98 | **«qt.svg: Invalid path data; path truncated» stammt nicht aus dem Repository.** Alle 23 SVG-Dateien des Repos laden unter QtSvg ohne Meldung (`tests/test_svg.py`); die fremden Plugins am PC enthalten keine SVG-Dateien; kora 2.0.6 am PC (45 975 Dateien) zeigt die Meldung nicht, **breeze am PC bei 7 Dateien** (`devices/64/camera-photo.svg`, `camera-web.svg`, `computer-laptop.svg`, `cups.svg`, `input-tablet.svg`, `input-touchpad.svg`, `preferences/32/preferences-desktop-touchpad.svg`; weitere Namen sind Links darauf). Am Mac ist breeze nicht installiert, kora dort ist ein jüngerer Git-Stand – welche Dateien es dort sind, zeigt `python3 entwicklung/svgpruefung/svg-pruefen.py --nur "Invalid path data" /usr/share/icons/kora` (braucht PySide6). Nichts zu beheben, da keine eigenen Dateien. |
| 99 | **kora unter Fedora: eigenes COPR baut `kora-icon-theme` für fc45 auf aarch64 und x86_64** (E3; die Chroots in 6.3 entsprechend, Asahi Remix 45). **Zwei COPRs mit demselben Paketnamen** (am Mac: `hazel-bunny/ricing`, 2.0.6-1.20260824git7a75842.fc43): dnf wählt zuerst nach `priority` des Repos (kleinster Wert gewinnt, Vorgabe 99, «possibly despite being … a lower version»), **bei gleicher Priorität gewinnt die höhere Version** (Epoch, Version, Release); **`cost` (Vorgabe 1000) entscheidet nur zwischen Repos, die dasselbe Paket in derselben Version anbieten** – also darüber, aus welchem Repo geladen wird, nicht darüber, welche Fassung gewinnt (berichtigt am 24.11.2026 nach dem Entscheid des Maintainers; vorher stand hier «bei Gleichstand nach `cost`, sonst die höchste Version»). **Worauf sich das stützt:** Für `priority` ist das dnf- und dnf5-Handbuch (`conf_ref`, `dnf5.conf`) die Quelle. Zu `cost` sagt das Handbuch wörtlich nur «This value is compared when the priorities of two repositories are the same. The repository with the lowest cost is picked.» – von «nur bei gleicher Version» steht dort nichts; die alte Lesart folgte diesem Wortlaut. Die Berichtigung folgt dem Entscheid des Maintainers und ist in der Sache gestützt durch libsolv (`src/policy.c`: `prune_to_best_version()` vergleicht zuerst Epoch, Version und Release; die Nachrangigkeit des Repos dient dort nur als Reihenfolge unter gleichen Fassungen). Für dnf5 ist auch der Schritt dazwischen an der Quelle gelesen (von der Gegenprüfung am 24.11.2026, nicht von der Hauptsitzung): `libdnf5/repo/repo.cpp` setzt `set_subpriority(-cost)`, kleineres `cost` ergibt also die höhere Nachrangigkeit, und die wirkt in libsolv erst nach dem Vergleich der Fassung. **Nicht nachgeschlagen:** dieselbe Abbildung in dnf 4 (libdnf), welche dnf-Fassung am Mac läuft, und das Verhalten in der Praxis; ob COPR-Repodateien `priority` setzen, ist ebenfalls nicht belegt (am Mac mit `dnf repolist -v` oder einem Blick in die Repodateien zu klären). Folge: Bei gleicher Priorität bleibt am Mac das fremde Paket installiert, weil sein Release `1.20260824git…` höher zählt als `1.fc45`. **Die Spec berücksichtigt das so:** `alpe-shell` verlangt nur `Requires: kora-icon-theme` ohne Version, Release oder Herkunft und verlässt sich nur auf `/usr/share/icons/kora/index.theme`; keine `Epoch`, kein `Obsoletes`, keine eigene `priority` in der Repodatei (träfe auch `quickshell`). `alpe doctor` nennt die Herkunft des installierten kora als Hinweis. |
| 100 | **`~/.config/alpe` gibt es bei Nutzern von 1.0 schon vor dem Umzug** (Liste abgeschalteter Dienst-Teile `aus`, `core/internal/server/alpe_off.go`; Marken, `hyprlock.conf`; am Mac dazu die angepassten Plugins). **Beleg, soweit heute möglich:** `tools/umzug.py` und `alpe start` gibt es noch nicht; der Plan hängt beide Entscheide an `settings.json` (6.6: «fehlt `~/.config/alpe/settings.json` und gibt es `~/.config/dms/settings.json`»; 7.2 Schritt 4 kopiert dateiweise, ohne zu überschreiben; die Erkundung in 0.3 nennt den Ordner als schon vorhanden). Im heutigen Code entscheidet nichts am blossen Vorhandensein des Ordners (gesucht in `tools/`, `get.sh`, `install.sh`, `bootstrap.sh`, `core/`, `shell/Common`). **Auflage für F1 und E4:** Kein Zweig fragt, ob der Ordner existiert; der Test von F1 stellt ein `~/.config/alpe` mit `aus`, `plugins/` und `hyprlock.conf`, aber ohne `settings.json` nach und verlangt den vollen Umzug. |
| 101 | **Den laufenden Baum nie in Teilschritten verändern.** Am Mac läuft 1.0 aus `~/dux-shell/quickshell`; Quickshell lädt geänderte Dateien des laufenden Baums sofort neu (beim Zwischenfall vom 23.11.2026: «Config reload failed»). **F1 und E4:** Umzug und Aktualisierung schreiben den neuen Stand zuerst vollständig an einen anderen Ort und schalten dann um (umbenennen bzw. Dienst neu starten) – oder stoppen die Shell vorher. Kein `git pull`, `sed`, `cp` oder `rsync` in einen Baum, aus dem gerade eine Shell läuft; das gilt auch für `alpe update` im Entwicklungsmodus (6.6). |
| 102 | **Alte Adresse `alpemessi/alpe`:** Im Repository steht sie nur noch in 0.2 dieses Plans als Beschreibung des damaligen Stands; `get.sh`, `Brand.qml`, README, Werkzeuge, Go-Modulpfad und User-Agent zeigen auf `alpe-shell/alpe`, ebenso `origin` dieses Klons. Nichts umzustellen. (Der Name `alpemessi` als Urheber in `LICENSE`, `NOTICE` und den `plugin.json` ist keine Adresse und bleibt.) |
| 103 | **Bild unter KWin: Weg A umgesetzt, befristet.** `entwicklung/ladepruefung/kwinbild.py` holt das Bild über `org.kde.KWin.ScreenShot2` der Test-Instanz. **Abweichung von Nr. 71 nur für KWin und nur, bis Weg B (KWin-Backend im Dienst) nach G1 entschieden ist.** Schutz: Abbruch ohne Aufnahme, wenn `DBUS_SESSION_BUS_ADDRESS` im Lauf fehlt, keine eindeutige Unix-Adresse ist, der Adresse der Sitzung des Maintainers oder `/run/user/<uid>/bus` gleicht oder wenn der Prozess hinter `org.kde.KWin` an diesem Bus nicht im Scope des Laufs läuft (`/proc/<pid>/cgroup`). Neu `--bild-sperre` für ein Bild der Variante «gesperrt» (seit dem Nachtlauf vom 24.11.2026 nur unter Hyprland; unter KWin bricht der Aufruf mit einer Meldung ab, statt den Schreibtisch zu liefern – dort sperrt KDE, nicht die Shell). **Die Aussage «KWin 6.8.3 prüft an ScreenShot2 keine Berechtigung» ist belegt (berichtigt am 24.11.2026, vorher «unbelegt»):** Bis 6.7 prüfte das Screenshot-Plugin den Aufrufer über die Desktop-Datei (`X-KDE-DBUS-Restricted-Interfaces`, `checkPermissions()` in `src/plugins/screenshot/screenshotdbusinterface2.cpp`, Fehler `org.kde.KWin.ScreenShot2.Error.NoAuthorized`); der KWin-Commit `0ea31ae72eb052cb9c9cc508318fc3f0f329ed53` («plugins/screenshot: Drop X-KDE-DBUS-Restricted-Interfaces») entfernt die Prüfung, er ist in `v6.7.90` und `v6.8.0` enthalten, in `v6.7.6` nicht. Stelle im Tag `v6.8.0`: dieselbe Datei, `ScreenShotDBusInterface2::CaptureWorkspace` ab Zeile 415 – die PID des Aufrufers (`determineCallerPid()`, Zeile 417) dient nur noch `pidToHide` (Zeile 426), `checkPermissions` wird nirgends mehr aufgerufen, die Fehlernamen (Zeilen 147–158) enthalten kein `NoAuthorized`. Gelesen aus einem Klon von `invent.kde.org/plasma/kwin` mit `git show <Tag>:<Pfad>`; die Nummer des Merge-Requests ist nicht selbst nachgeschlagen und steht darum nicht hier. **`KWIN_SCREENSHOT_NO_PERMISSION_CHECKS` wird nicht gesetzt:** Auf dem einzigen unterstützten KWin (6.8) gibt es die Variable im Quelltext nicht mehr, sie wäre wirkungslos und täuschte einen Schalter vor (`tests/test_ladepruefung.py` prüft, dass weder `kwinbild.py` noch `ladepruefung.py` sie setzen). **Folge: Die Abbruchbedingungen von `kwinbild.py` sind die einzige Schranke zwischen der Ladeprüfung und der Sitzung des Maintainers** – KWin selbst hält seit 6.8 keinen Aufrufer am Session-Bus mehr ab. Bedingungen und Test je Bedingung (alle durch `main()` selbst, nur `busctl` als Attrappe und `/proc` als Temp-Ordner): (1) Busadresse fehlt oder ist nicht eindeutig; (2) Busadresse gleich der Sitzung des Maintainers oder `/run/user/<uid>/bus` – `busctl` wird gar nicht aufgerufen; (3) an diesem Bus gibt es kein `org.kde.KWin`; (4) KWin an diesem Bus läuft nicht im Scope des Laufs; (5) neu: KWin meldet `NoAuthorized` (ein KWin bis 6.7) – Abbruch mit klarer Meldung statt Umgehung; erkannt am Fehlernamen und am Fehlertext, weil `busctl` nur den Text ausgibt. In (3) und (4) wird `CaptureWorkspace` nachweislich nicht aufgerufen; eine Gegenprobe (KWin im Scope, Aufnahme erlaubt) schreibt ein Bild. Die Ladeprüfung wertet jeden dieser Abbrüche als ungültigen Lauf. |
| 104 | **Ausgeliefertes Design ohne matugen-Vorlagen für Firefox, Neovim, Zen und Zed.** `design.py export` schreibt die vier immer aus (`SETTINGS_NUR_NEU`), auch wenn der Exportierende sie eingeschaltet hat; `apply` spielt sie nur ein, wenn es noch keine Einstellungen gibt. Bestehende Einstellungen bleiben, auch wenn der Schlüssel fehlt (die Shell schreibt Vorgabewerte nicht aus; Vorgabe für Firefox, Zen und Zed ist «an»). |
| 105 | **`breeze-icons` als Abhängigkeit** (kora erbt davon): Arch `depends=(… breeze-icons hicolor-icon-theme)` (E2), Fedora `Requires: breeze-icon-theme` (E3; Name am Mac bestätigt: 6.32.0-1.fc45, dort nicht installiert). **F2:** `get.sh` baut auf dem Weg ohne AUR-Helfer `kora-icon-theme` **vor** `alpe-shell`, weil `pacman` und `makepkg -s` keine AUR-Abhängigkeiten auflösen; ist ein AUR-Helfer da (`paru`, `yay`), übernimmt er beides. |
| 106 | **Standbild der Sperre ohne `ffmpeg` – Einschätzung, nicht umgesetzt.** Heute erzeugt `VideoWallpaperService.qml` das Standbild beim ersten Bedarf mit `ffmpeg` nach `<Cache>/…/<md5 des Videopfads>.jpg`; ohne `ffmpeg` gibt es weder Standbild noch Farben aus dem Video. Mitliefern geht, **besser als fertige Datei im Repository als beim Paketbau**: (a) Bild einmal mit demselben `ffmpeg`-Aufruf erzeugen und neben das Video legen (`design/kde/bilder/jagged-peaks-wolkenzug.jpg`, unter 1 MB, eigene Ableitung des eigenen Videos, CC0 wie in Nr. 95); (b) der Dienst der Shell nimmt ein gleichnamiges `.jpg` neben dem Video, bevor er `ffmpeg` fragt (rund 15 Zeilen, Node-Test); (c) `design.py` kopiert es mit. Beim Paketbau (E1) erzeugen hiesse `ffmpeg` in `makedepends`/`BuildRequires` und ein vom Bau abhängiges Bild – davon rate ich ab. `ffmpeg` bleibt für eigene Videos der Nutzer `optdepends`/`Recommends`. Aufwand: zwei bis drei Stunden; ~~Entscheid des Maintainers offen.~~ **Angenommen am 24.11.2026; Umsetzung als erster Schritt von E1** (Abschnitt 10), noch nichts gebaut. Auflagen des Maintainers: (1) das Standbild liegt als **fertige Datei im Repository** (neben dem Video, `design/kde/bilder/jagged-peaks-wolkenzug.jpg`); (2) ein **Erzeugungsskript unter `tools/`** schreibt genau diese Datei aus dem Video (derselbe `ffmpeg`-Aufruf wie `VideoWallpaperService.qml`), läuft von Hand und nicht beim Paketbau; (3) ein **Test über die Prüfsumme der Quelle**: Das Skript hält die Prüfsumme des Videos fest, aus dem das Bild entstand, und der Test wird rot, wenn sich das Video ändert, ohne dass das Bild neu erzeugt wurde – er braucht selbst kein `ffmpeg`; (4) ein **Eintrag in `NOTICE`** (Herkunft: eigene Ableitung des eigenen Videos, Lizenz wie das Video, Nr. 95). Dazu wie oben (b) und (c): die Shell nimmt ein gleichnamiges `.jpg` neben dem Video, bevor sie `ffmpeg` fragt, und `design.py` kopiert es mit. **Für die Umsetzung in E1 festzuhalten (aus der Gegenprüfung vom 24.11.2026):** (i) `design.py export` räumt `design/<variante>` ab und übernimmt nur Bilder, auf die Einstellungen verweisen – das Standbild muss beim Export erhalten bleiben und ins Manifest; der Test wird auch rot, wenn das Bild fehlt. (ii) «Unter 1 MB» ist nicht gemessen: Der Aufruf der Shell liefert ein JPEG in voller Grösse; liegt es darüber, schlägt die Prüfung neuer Dateien an (Frage an den Maintainer: Qualität oder Breite im Skript senken, oder Ausnahme). (iii) Der Cache-Name des Standbilds hängt am Videopfad; ob ein umgezogener Nutzer ohne `ffmpeg` das Bild bekommt, ist bei F1 zu klären. (iv) Offen ist, ob die Auswahl «`.jpg` neben dem Video» für jedes Video gilt oder nur im Ordner des Designs (Frage an den Maintainer). **Entscheide des Maintainers vom 25.11.2026 und Umsetzung (E1, Nachtlauf 2.1):** zu (ii) – liegt das Bild mit dem Aufruf der Shell über 1 MB, senkt das Skript die Qualität auf einen festen, im Skript dokumentierten Wert (`-q:v 5`); keine Ausnahme in der Grössenprüfung. Gemessen: mit dem Aufruf der Shell 695 295 Byte, 3440 × 1440 (ffmpeg n9.0.2), die Ersatzqualität wird nicht gebraucht. Zu (iv) – **nur für Videos im Ordner des eingespielten Designs** (`<XDG_DATA_HOME>/alpe/design/`, dorthin legt `design.py apply` Video und Bild), nicht für eigene Videos der Nutzer. Zu (i) – `design.py export` erhält das Standbild (neben dem Video im eingespielten Design, sonst aus dem bisherigen Export, wenn dort dasselbe Video lag) und führt es im Manifest. Dateien: `design/kde/bilder/jagged-peaks-wolkenzug.jpg` (**erzeugt über das Erzeugungsskript nach Auflage (2)**, nicht mit Edit – die einzige Datei, die es schreibt; die Prüfsummen von Video und Bild stehen als Konstanten im Skript und werden von Hand nachgeführt), `tools/standbild.py` (`--pruefen` ohne ffmpeg), `shell/Common/VideoPoster.js` (Auswahl und sh-Skript; das mitgelieferte Bild wird vor `ffmpeg` genommen, auch wenn `ffmpeg` fehlt), `shell/Services/VideoWallpaperService.qml`, `tools/design.py`, `NOTICE`, Manifest. Tests: `tests/test_standbild.py` (Prüfsumme der Quelle, rot ohne Bild, gleicher Aufruf wie die Shell, NOTICE, Manifest, Export), `shell/tests/video-poster.test.mjs` (Auswahl, Skript ohne `ffmpeg`). (iii) bleibt für F1 – **dazu seit dem 25.11.2026:** Für Videos des Designs hängt das Standbild nicht mehr am Cache-Namen, sondern daran, dass das `.jpg` im Ordner des eingespielten Designs liegt; wer aus 1.0 kommt, hat dort nur das `.mp4`, bis das Design neu eingespielt ist. **Nachbesserung (Prüfung zu 2.1):** Fehlt ffmpeg und liegt neben einem Video des Designs kein `.jpg`, gilt das Video nach einem Lauf als gescheitert – `framePending()` wartet nicht ewig, der Rückfall auf die Samenfarbe bleibt wie vorher (reine Funktionen `outcome`, `pending`, `mayRequest` in `VideoPoster.js`, Node-Test des Ablaufs); `BUNDLED_EXIT` zählt nur mit einem mitgelieferten Bild. Shell und `design.py` grenzen den Ordner gleich ab: wörtlicher Pfad, Links werden nicht aufgelöst. **Bekannte Grenzen (vermerkt, nicht geändert):** `design.py apply` kopiert mit `dirs_exist_ok` – ein altes `.jpg` mit dem Namen eines Videos bleibt liegen, wenn ein neues Design dasselbe Video ohne `.jpg` bringt, und die Shell nimmt es ungeprüft; beim Export wird ein Standbild, dessen Name schon von einem anderen übernommenen Bild belegt ist, nur gemeldet, das fremde Bild steht dann unter dem Namen des Standbilds. |
| 107 | **Sporadische Meldungen unter Hyprland «offen»: nicht in die Grundlinie; die Haltprüfung auf `54bb5c0` gilt als bestanden** (Entscheid des Maintainers vom 24.11.2026). Notizblock «Tab file does not exist» (samt `FileView`-Zeile), `DeferredAction.qml` «Cannot read property 'stop' of null» und ShaderEffect «'source' does not have a matching property» erschienen je einmal in 4 Läufen unter Last und in 12 + 12 ruhigen Läufen auf `b04b1bf` und `54bb5c0` nie (die geführte `flush`-Meldung in diesen 24 Läufen ebenfalls nie). Vermerk: **nur unter Last beobachtet, Herkunft offen**; das Notizblock-Paar steht auf `b04b1bf` schon in der Grundlinie «gesperrt». Geführt werden die drei mit den Zählungen in `offene-faelle.md` («Ladeprüfung»), nicht in `grundlinie-hyprland-offen.txt`. **Für Hyprland «offen» gilt die Haltprüfung auf `54bb5c0` mit den zwölf ruhigen Läufen als bestanden** (jeder 39/39, nichts neu, nichts weg). Folge für jeden weiteren Halt: Ladeprüfungen nur in Ruhe, Wiederholungsregel für genau diese drei (`CLAUDE.md`). ~~**Offen beim Maintainer:** ob `SPORADISCH`-Einträge von Hand in eine Grundlinie dürfen.~~ **Entschieden am 25.11.2026 (Nr. 109):** nie von Hand, Grundlinien werden nur gemessen. |
| 108 | **Aufgabe: Bild der KDE-Sperre über `kscreenlocker_greet --testing` im Test-Scope** (Entscheid des Maintainers vom 24.11.2026; noch nichts gebaut). **Anlass:** Alpe liefert Dateien für die KDE-Sperre aus – das Paket `lockscreen/org.alpe.desktop/` (`metadata.json`, `contents/lockscreen/LockScreen.qml`, `CapsLock.qml`, `config.xml`, Schrift mit `OFL.txt`); `tools/lockscreen.sh` kopiert es nach `~/.local/share/plasma/shells`, erzeugt `layout.js` aus `hyprlock.conf` hinein und schaltet es ein. Unter KWin sperrt also KDE mit diesem Paket, nicht die Shell; die Haltbilder zeigen es bisher nie (`kwin --bild-sperre` bricht seit dem 24.11.2026 ab, Nr. 103). **Aufgabe:** In der Ladeprüfung unter KWin das Paket ins Temp-HOME legen (die Kopierschritte von `lockscreen.sh install` nachbilden, ohne `kscreenlockerrc` der echten Sitzung zu berühren), `kscreenlocker_greet --testing --shell org.alpe.desktop` als gewöhnlichen Wayland-Klienten der Test-Instanz im Scope des Laufs starten, zwei bis drei Sekunden warten, Bild über `kwinbild.py` (dessen Abbruchbedingungen gelten unverändert), dann genau diesen einen Kindprozess über seine PID beenden – kein Beenden über Namen. Dazu ein Test (Skripttext, Abbruch mit Meldung, wenn das Programm fehlt). Zu den Kopierschritten gehört mehr als das Paket im Repo: `lockscreen.sh install` legt auch `HyprlockView.qml`, `layout.js` und die Schrift aus `shell/Modules/Lock/Alpe` hinein und schreibt `plasmashellrc` und eine Marke – im Lauf nur im Temp-HOME. **Bildname – entschieden am 25.11.2026:** `halt-kwin-kdesperre.png` (vorher Vorschlag) (die Regel `halt-<compositor>-<variante>.png` kennt «kdesperre» nicht als Variante; `halt-kwin-gesperrt.png` täuschte einen Lauf der Variante «gesperrt» vor). **Aufwand: zwei bis drei Stunden.** **Was das Bild nicht zeigt:** den echten Sperrweg (`ksld`, PAM, Nachfrist) und das Zusammenspiel mit der Shell. **Zur Art des Fensters (berichtigt am 24.11.2026; vorher stand hier «im Testmodus ein gewöhnliches Fenster»):** Nach `greeter/greeterapp.cpp` von kscreenlocker (Tag `v6.8.3`, von der Gegenprüfung gelesen, nicht von der Hauptsitzung) wird die Ansicht unter Wayland auch im Testmodus eine Layer-Shell-Fläche (oberste Ebene, ganze Bildschirmfläche, Tastatur exklusiv); vom Testmodus hängt nur der Fensterrahmen ab. Die Sperre füllt den Bildschirm der Test-Instanz danach voraussichtlich ganz und beansprucht dort die Tastatur – in der Reihenfolge des Sitzungsskripts zu beachten. **Nicht geprüft:** das Verhalten am installierten Paket in der verschachtelten KWin-Instanz und ob ScreenShot2 die Fläche aufnimmt. ~~**Zeitpunkt:** keiner Etappe zugeordnet; hängt am befristeten Weg A (`kwinbild.py`, Nr. 103) und ist darum vor dem Entscheid über Weg B nach G1 sinnvoll – Zuordnung durch den Maintainer.~~ **Zeitpunkt – entschieden am 25.11.2026: Etappe E1, aber ausdrücklich nicht in einem unbeaufsichtigten Lauf zu bauen**. ~~Verwandte offene Frage: ob es unter KWin zusätzlich ein Bild des Schreibtischs im ausgelieferten Design geben soll (heute zeigt unter KWin kein Haltbild das ausgelieferte Design ohne Abwandlung).~~ **Beantwortet am 25.11.2026 (Nr. 112):** `kwin --bild-schreibtisch`, Haltbild `halt-kwin-gesperrt-schreibtisch.png`, Pflicht bei jedem Halt (Nr. 71); die KDE-Sperre selbst zeigt weiter kein Haltbild, bis diese Aufgabe gebaut ist. |
| 109 | **Entscheide des Maintainers vom 25.11.2026 zu den geparkten Fragen des Nachtlaufs vom 24.11.2026** (ohne Codeänderung). (1) **Aussage zur Länge des PC-Namens:** Die frühere Plan-Zeile, die die Länge des Rechnernamens nennt, bleibt in der Git-Geschichte stehen (Nr. 87, 90: Veröffentlichtes wird nicht umgeschrieben); berichtigt ist nur der heutige Text (`dc72cf6`). (2) **Rechnername in Binärdateien:** wird roh nicht gesucht, wenn er kürzer als vier Zeichen ist (komprimierte Daten enthalten jede kurze Bytefolge irgendwo); die Grenze bleibt dokumentiert – im Kopf von `tools/werte-pruefen.py` und bei `roh_funde` sowie in `docs/technik.md` (Absatz «Binärdateien» der Werteprüfung). (3) **Paket:** `tools/test-commit.sh` und alle reinen Entwicklungs- und Prüfskripte kommen nicht ins Paket; die Liste der installierten Werkzeuge ist ausdrücklich (E1, 6.1). (4) **Keine harte Sperre in `ladepruefung.py`** für die Schranke `--gruen`; sie bleibt eine Regel in `CLAUDE.md`. (5) **Wiederholungsregel, weite Lesart** wie in `CLAUDE.md` committet: Die fremden Meldungen eines Laufs stammen ausschliesslich aus den drei bekannten, beliebig viele davon. (6) **`SPORADISCH`-Einträge kommen nie von Hand in eine Grundlinie; Grundlinien werden nur gemessen** (`--grundlinie`; schliesst die offene Frage aus Nr. 107). (7) **Der Commit `7c2e349` auf `main` im Plugin-Repo** (`calculator/CHANGES.md`) bleibt. |
| 110 | **Werteprüfung durchsucht jede Textdatei** (Entscheid des Maintainers vom 25.11.2026, Option c der geparkten Frage aus dem Nachtlauf vom 24.11.2026): Die 52 Textdateien mit einer Endung ausserhalb von `ENDUNGEN` (23 `.svg`, 21 `.frag`, 3 `.colors`, je eine `.gitignore`, `.sum`, `.MD`, `.NOTICE`, `.el`) werden zeilenweise durchsucht wie alle anderen. **In SVG-Dateien zählt eine IP-Adresse innerhalb von Pfaddaten (Attribut `d`, auch über mehrere Zeilen) nicht als Fund**; nur diese Art, nur Dateien mit Endung `.svg`. Vorher gemessen: 15 scheinbare IP-Adressen, alle in Pfaddaten von `topography.svg` (14) und `shell/assets/hyprland.svg` (1); sonst kein Fund. Keine neue Ausnahme in `tools/werte-ausnahmen.txt`. Test in `tests/test_werte.py` |
| 111 | **`CLAUDE.md`, «Dateien ändern»: die Regel gilt für alle Dateien** (Entscheid des Maintainers vom 25.11.2026): «versionierte» gestrichen. Die Werkzeug-Ausnahme ist auf das Entschiedene gekürzt: **Attrappen über `make -C core mocks`** (Nr. 62, 66) und **gemessene Grundlinien über `--grundlinie`** (`ladepruefung.py`, `qmllint-pruefung.py`; Nr. 63, 70, 76). **Offen, zu entscheiden, wenn sie anstehen:** (a) der Suchindex der Einstellungen (`settings_search_index.json`, erzeugt von `shell/translations/extract_settings_index.py`; Nr. 74); (b) Massenumbenennungen mit `entwicklung/umbenennen/umbenennen.py` bzw. `texte-ersetzen.py` samt Tabelle (2.3). Bis zum Entscheid steht keiner der beiden in der Ausnahme. |
| 112 | **Bild des Schreibtischs im ausgelieferten Design unter KWin** (Entscheid des Maintainers vom 25.11.2026; beantwortet die verwandte Frage in Nr. 108): `ladepruefung.py kwin --bild-schreibtisch DATEI` – nur unter KWin, nur in der Variante «gesperrt» (ohne `--offen`, also ohne Abdeckungs-Zusätze, mit `lockAtStartup` wie ausgeliefert), Aufnahme über `kwinbild.py` wie `--bild` (Weg A, Nr. 103). Haltbild **`halt-kwin-gesperrt-schreibtisch.png`**: Der Name sagt, dass es nicht die Sperre zeigt – unter KWin sperrt KDE, die Test-Instanz läuft mit `--no-lockscreen`, auf dem Bildschirm liegt der Schreibtisch. `kwin --bild-sperre` bricht weiter ab. Abgelehnt mit Rückgabewert 2 vor Bau und Lauf: mit `--offen`, `--bild`, `--bild-sperre`, unter Hyprland, mit `--grundlinie`. Test in `tests/test_ladepruefung.py` |
| 113 | **`go-udev` bleibt im Dienst, `GPL-3.0-only` ins Lizenzfeld** (Entscheid des Maintainers vom 25.11.2026, Option (a) der geparkten Frage aus E1 2.8). `github.com/pilebones/go-udev` v0.10.0 (GPL-3.0, ohne «or later»), eingebunden nur in `core/internal/server/brightness/udev_linux.go`. **`NOTICE`** hat einen eigenen Eintrag (Modul, Fassung, wo benutzt): Der Quelltext von Alpe ist MIT, das Programm `alpe-dienst` als Ganzes wird unter den Bedingungen der GPL-3.0 weitergegeben. Der Lizenztext liegt unter `LICENSES/GPL-3.0-only.txt` (bytegleich mit `LICENSE` des Moduls) und kommt mit `make install` nach `/usr/share/licenses/alpe-shell/GPL-3.0-only.txt`. **Kein Ersatz in Phase A** (kein eigener Netlink-Code, keine Abfrage über `/sys`): **Phase B löst den Go-Dienst ab** (Rust, Abschnitt 1), damit fällt `go-udev` weg; ab dann gilt das Feld ohne `GPL-3.0-only` neu zu bilden. Stellen in README, Über-Seite und Paketdateien, die «MIT» ohne diese Einschränkung für das Ganze nennen, sind gemeldet (lokaler Bericht des Nachtlaufs vom 26.11.2026, Punkt 1.1) und nicht geändert. Test: `tests/test_lizenzen.py` (Eintrag mit der Fassung aus `go.mod`, jede einbindende Datei genannt, Text und Installationszeile), `tests/test_makefile.py` (installierter Text = Repository) |
| 114 | **`golang/freetype`: Alpe wählt die FreeType License** (Entscheid des Maintainers vom 25.11.2026; das Modul steht nach Wahl unter FTL oder GPL-2.0-or-later, eingebunden indirekt über `fogleman/gg` aus `go-qrcode/writer/standard` in `core/internal/qrcode/qrcode.go`, `core/internal/server/network/manager.go` und `qr_generator.go` – berichtigt nach der Prüfung zu 1.2, zuerst stand nur `core/internal/qrcode/`). `go mod vendor` übernimmt nur Paketordner, den Text `licenses/ftl.txt` nicht; die FTL verlangt ihn bei der Weitergabe des Quelltexts **unverändert**. Darum keine Kopie im Repository (das Original ist Latin-1 kodiert, eine Abschrift wäre nicht bytegleich), sondern: `make dist` legt die Originaldatei aus dem Modul nach `core/vendor/github.com/golang/freetype/licenses/ftl.txt` ins Quellarchiv, `make install` nach `/usr/share/licenses/alpe-shell/FTL.txt` (aus dem vendor-Baum des Archivs; beim Bau im Repository aus dem Modul-Cache über `go list -m`). `NOTICE`: Eintrag mit Fassung, Weg der Einbindung, Wahl der FTL und der verlangten Nennung des FreeType-Teams. Lizenzfeld: `FTL` (Arch) bzw. `FTL` statt `(FTL OR GPL-2.0-or-later)` (Fedora). Test: `tests/test_lizenzen.py`, `tests/test_makefile.py` (Archiv und Paket bytegleich mit dem Original, Installation aus dem Archiv ohne Modul-Cache) |
| 115 | **`yeqown/reedsolomon`: MIT, am Ursprung belegt** (Auftrag des Maintainers vom 25.11.2026: nachschlagen, bei belegter Lizenz Eintrag in `NOTICE` mit Fundstelle). v1.0.0 (2018, einziger Tag) hat keine Lizenzdatei; der Autor `yeqown` (einziger Autor aller Commits) hat am **08.03.2026** mit Commit `c5f4bc9af094852b52e593a5f964647c43028c51` auf `master` eine MIT-Lizenz («Copyright (c) 2026 yeqown») hinzugefügt; `compare v1.0.0...master` zeigt nur diese Datei, der Code ist also derselbe. Das einbindende Modul `go-qrcode/v2` (MIT) verlangt weiter v1.0.0. Eingebunden über `go-qrcode/v2` in `core/internal/qrcode/qrcode.go` und `core/internal/server/network/{manager,qr_generator}.go`. Kein Ersatz, nichts geparkt; das Lizenzfeld ändert sich nicht (MIT steht schon drin). Die Köpfe von `reedsolomon.go` und `binary/binary.go` nennen `skip2/go-qrcode` (MIT) als Vorlage – in `NOTICE` vermerkt. Abfrage über die GitHub-API, Beleg im lokalen Bericht. Test: `tests/test_lizenzen.py` |
| 116 | **Klänge: `desktop-login` entfernt, `NOTICE` auf die ausgelieferten Dateien berichtigt** (Entscheid des Maintainers vom 25.11.2026, damals mit der Begründung «Herkunft unbekannt»). **Inzwischen belegt** (Nachtlauf vom 26.11.2026, GitLab-API von `gitlab.freedesktop.org/xdg/xdg-sound-theme`): `desktop-login.oga` ist bytegleich mit `stereo/desktop-login.oga` des freedesktop-Klangthemas im Stand vor Commit `7c4e2f7739a08b145b87c4162b05c6c863b2034a` («remove desktop login/logout for now», 28.09.2009, Fassung 0.7); dieser Commit strich in `CREDITS` den Block «Copyright: Red Hat, Inc. – Created by: Mike Langlie – License: CC-BY-SA». Entfernt ist die Datei trotzdem, wie entschieden (Prüfer: Einordnung A); ob sie zurückkommt, ist eine Rückfrage an den Maintainer (lokaler Bericht). **Shell:** `AudioService.getSoundPath("desktop-login")` gibt ohne Klang aus dem Systemthema eine leere Quelle zurück (vorher wäre `message.wav` eingesprungen), `playSound` spielt bei leerer Quelle still nichts; Test `shell/tests/sound-paths.test.mjs`. **`NOTICE`** nennt jetzt genau die ausgelieferten Dateien: `audio-volume-change` (Lucas McCallister) unter CC-BY-SA **ohne Fassung** (am Ursprung nicht angegeben; Fedora und Arch führen CC-BY-SA-3.0), `message` (Ivica Bukvic, «Borealis») **widersprüchlich** (`CREDITS` CC-BY-SA; README 2009 erst «Creative Commons Share-Alike 3.0 Unported», ab Commit `bc4fe27` «Artistic License»), `message-new-instant` (seit dem ersten Stand 2008 im Thema, `CREDITS` nennt weder Urheber noch Lizenz – auch in keiner früheren Fassung von `CREDITS`), die `.wav` als PCM-gleiche ffmpeg-Umwandlung der `.oga`; dazu die zwei Harmony-2-Klänge. **Geparkt** (lokaler Bericht): Fassung der CC-BY-SA, Lizenz von `message` und von `message-new-instant`, Schalter «Anmeldeklang». **Folge für F1:** Wer unter 1.0 den Anmeldeklang eingeschaltet hat, hört ihn nach dem Umzug nur noch mit einem Systemklangthema, das `desktop-login` hat – gehört in die Hinweise zu 1.1. Test: `tests/test_lizenzen.py` (NOTICE = Dateien im Repository) |
| 117 | **Zeichen Dritter und drei Code-Teile in `NOTICE`, `discord.svg`/`reddit.svg` entfernt** (Entscheid des Maintainers vom 25.11.2026). `NOTICE`, Abschnitt «Zeichen Dritter (shell/assets/), nur zur Bezeichnung»: `hyprland.svg` (bytegleich mit der Datei der Dux Modular Shell; ~~eine Quelle bei hyprwm nicht gefunden~~, berichtigt unten), `package-sources/flatpak.svg` und `snap.svg` (Pfaddaten und Füllfarbe aus Simple Icons; ~~CC0 1.0~~ **berichtigt in der Nachbesserung:** Simple Icons ist CC0, die Zeichen darin nicht – Flatpak **CC BY 3.0** (flatpak.org/press; «© Flatpak Team» aus dem Seitenfuss derselben Seite), Snapcraft **CC BY-SA 3.0** nach den Daten von Simple Icons (design.ubuntu.com/resources)), `nix.svg` (bytegleich mit `logo/nix-snowflake-colours.svg` aus `NixOS/nixos-artwork`, Simon Frankau/Tim Cuthbertson, CC BY 4.0), `appimage.svg` (Herkunft nicht belegt); `hyprland.svg` **berichtigt:** hyprwm stellt seine Logodateien «ARR» bereit (`assets/logo/LICENSE`), Nutzung nach `hypr.land/trademark-usage/` (zur Bezeichnung erlaubt, aber mit der offiziellen Vorlage – die Datei von Alpe ist nicht die heutige Vorlage). Code: `fzf.js` (BSD-3-Clause, Ajit), `Hct.js` (Apache-2.0, Google LLC, Material Color Utilities), `MaterialShapeData.js` (Apache-2.0, Android Open Source Project) – je Lizenz aus dem Dateikopf, die Lizenz der Ursprungs-Repositories stimmt überein (`gh api`, Beleg im lokalen Bericht). **Geparkt** (lokaler Bericht): Umgang mit Flatpak/Snapcraft, Hyprland-Zeichen (offizielle Vorlage, neutral, Erlaubnis), Herkunft von `appimage.svg`. **Lizenzfeld:** `CC-BY-4.0` steht schon drin; **`CC-BY-3.0` und `CC-BY-SA-3.0` wären neu, das Hyprland-Zeichen (ARR) ist offen** – keine Vermutung ins Feld, Entscheid bei E2/E3. `tests/test_werte.py`: Untergrenze der Textdateien mit anderer Endung 52 → 50. Test: `tests/test_lizenzen.py` (NOTICE nennt genau die Zeichen unter `shell/assets/`, die drei Code-Teile mit Lizenz) |
| 118 | **PAM: eine eigene `dankshell` aus 1.0 wird nicht abgelöst** (Entscheid des Maintainers vom 25.11.2026, Option (b) der Prüfung zu E1 2.5). Findet `alpe-dienst auth sync` eine eigene, nicht verwaltete `/etc/pam.d/dankshell` und keine `/etc/pam.d/alpe`, schreibt es `alpe` nicht und meldet «Custom /etc/pam.d/dankshell from Alpe 1.0 found and no /etc/pam.d/alpe: … is not created, the lock screen keeps using …» – die Sperre nimmt dann weiter `dankshell` (`Pam.qml`: `alpe` vor `dankshell`). Eine verwaltete `dankshell` (Block von 1.0) wird wie bisher durch ein neues `alpe` abgelöst; gibt es `alpe` schon (verwaltet), wird es auch neben einer eigenen `dankshell` nachgeführt. `dankshell` selbst wird nie verändert. Der U2F-Dienst (`dankshell-u2f`/`alpe-u2f`) ist vom Entscheid nicht erfasst und unverändert (Frage im lokalen Bericht). Test: `core/internal/pam/pam_test.go` (`TestSyncLockscreenPamConfigWithDeps`) |
| 119 | **Richtlinie des Administrators aus 1.0 als Rückfall** (Entscheid des Maintainers vom 25.11.2026, Option (b) der Prüfung zu E1 2.5). `core/internal/clipolicy`: `EffectiveAdminPath` ist `/etc/alpe/cli-policy.json`, ausser diese fehlt und `/etc/dms/cli-policy.json` gibt es – dann gilt die alte, mit der Meldung «CLI policy: /etc/alpe/cli-policy.json is missing, using the policy of Alpe 1.0 from /etc/dms/cli-policy.json. Copy it to … to keep it; the old path is read only until the move from 1.0 is finished.» (bei jedem Laden: beim Start der Oberfläche über `ShellEnv` und beim Start des logind-Managers zweimal, also dreimal je Start; dazu bei Befehlen mit Sperrprüfung). Ist der alte Pfad da, aber nicht lesbar (etwa ohne Leserechte), gilt er trotzdem als Rückfall: Meldung, Lesefehler, alle Schalter ein – kein stiller Wegfall (Nachbesserung nach der Prüfung zu 1.7). Gilt für alle Leser: Schalter und `lock_settings` für die Oberfläche (`ShellEnv`), `LogindUnlockDisabled`, `LockSettings` (Dienst) und die Befehlssperre (`immutable_policy.go`). Die Richtlinie des Pakets von 1.0 (`/usr/share/dms`) wird nie gelesen. Der alte Pfad steht zwischen Marken `alpe-namen-ausnahme: umzug-ende` (Frist Umzug-Ende). Test: `clipolicy_test.go` (`TestLegacyAdminFallback`: nur alt, beide, keine, nur Paket von 1.0, alte fehlerhaft, Schalter in `ShellEnv`), `tests/test_pam_dienste.py` (statisch) |
| 120 | **`alpe.service` ohne `BusName=`** (Entscheid des Maintainers vom 25.11.2026, Option (a) der Prüfung zu E1 2.4). Zwei Units mit demselben Busnamen laden nicht nebeneinander (`dms.service` aus 1.0 trägt `BusName=org.freedesktop.Notifications`; Ladefehler, den `Conflicts=` nicht abwendet), und bei `Type=notify` ist der Busname nicht nötig – die Bereitschaft meldet `sd_notify`. Am PC gemessen, nur lesend: `systemd-analyze --user verify` mit der alten Unit meldet «dms.service: Two services allocated for the same bus name org.freedesktop.Notifications, refusing operation», mit der neuen nicht mehr (übrig bleibt nur «/usr/bin/alpe is not executable», weil das Paket am PC nicht installiert ist). `Conflicts=`/`After=dms.service` bleiben. 2.2 und 6.1 nachgeführt. **Die Messung mit beiden Paketen in der VM** (Umzug, Rückweg) steht auf der Liste des Installationstests (`offene-faelle.md`). Test: `tests/test_paketdateien.py` |
| 121 | **Material-Vorlage «alpe»: `softBurst` und `alpeLogo` gemeinsam auf der Mitte 0,453** (Entscheid des Maintainers vom 25.11.2026, Option (b) der Prüfung zum Befund 1.8 vom 25.11.2026). Mit 0,45 endeten zwei Täler zwischen den unteren Zacken von `softBurst` bei y/H ≈ 0,9986, knapp über dem Bildrand; der dunkle Grund schien als zwei Bogen durch (Haltbild Hyprland «offen» vom 25.11.: y = 719 bei x ≈ 931 und 1224). Nach `place()` ist die Höhe im Querformat proportional zu H; mit 0,453 liegen die Täler bei jedem Querformat unter dem Rand – gerechnet 1,15 px (1280 × 720) bis 3,8 px (3840 × 2160), am Mac (2560 × 1664) 2,7 px. Das Zeichen bleibt mittig auf der Form (beide 3/1000 der Höhe tiefer). `shell/Alpe/Common/MaterialWallpaper.js`, nur die Vorlage; gespeicherte eigene Anordnungen sind nicht betroffen, das Design speichert keine. Test: `shell/tests/material-alpe-edge.test.mjs` (rechnet die Täler über `place()` und `cubicsOf()` für zehn Querformate; mit 0,45 rot) |

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
| WirePlumber | `wireplumber/wireplumber.conf.d/51-dms-audio-aliases.conf` | `51-alpe-audio-aliases.conf` | **umbenennen in F1** (0.8 Nr. 73), nie beide gleichzeitig | Namen der Audiogeräte, von `AudioService` geschrieben; WirePlumber liest jede Datei im Ordner, zwei Fassungen würden sich überlagern. Bis F1 schreibt die Shell den alten Namen; F1 benennt um und stellt `AudioService.qml` im selben Schritt auf den neuen Namen, der Rückweg benennt zurück |
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
| `dms.service` | **`alpe.service`** (user unit, im Paket; `MALLOC_ARENA_MAX=2` fest drin; ~~`BusName=org.freedesktop.Notifications` bleibt~~ **ohne `BusName=`**, 0.8 Nr. 120) |
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
| PAM-Dienste `dankshell`, `dankshell-u2f`, Blockmarken «DMS LOCKSCREEN AUTH»; Richtlinien `/usr/share/dms`, `/etc/dms`; alle anderen paketierten Pfade | heute vom Paket `dux-shell`/`dms` belegt | **E1** (zwingend, 0.8 Nr. 16; alte Blöcke erkennen) – **umgesetzt am 25.11.2026:** PAM-Dienste `alpe`, `alpe-u2f` (unter der Richtlinie `alpe-fprint`), im Nutzerordner `alpe`; Blockmarken «ALPE LOCKSCREEN AUTH» / «ALPE LOCKSCREEN U2F AUTH»; Richtlinien `/usr/share/alpe/cli-policy.json`, `/etc/alpe/cli-policy.json`. Die Dienste und Blöcke von 1.0 werden erkannt (Meldung beim Abgleich; die Sperre nimmt sie als Rückfall, solange es die neuen nicht gibt) und nie geschrieben, umbenannt oder gelöscht; im Code stehen sie nur zwischen Marken mit Frist «Umzug-Ende». Die Einträge der Ausnahmeliste mit Frist E1 sind weg. Seit 0.8 Nr. 118 löst `auth sync` eine eigene `dankshell` nicht ab, seit Nr. 119 gilt `/etc/dms/cli-policy.json` als Rückfall (`/usr/share/dms` nie) |
| CUPS `requesting-user-name` `dms` | Besitzerkennung von Abonnements in cupsd (Befund in `offene-faelle.md`) | D7.7: Benutzername zur Laufzeit (`os/user`, Rückfall `alpe`); `dms` nur noch beim einmaligen Kündigen alter Abonnements (siehe unten), Frist wie Migration |
| Dateien fremder Plugins im Original, Herkunftsvermerke im README von `~/alpe-plugins` | Lizenz/Herkunft | dauerhaft |
| `Brand.heldPackages` (`dux-shell`, `dms`, `dms-cli`) | Paketnamen des Ursprungs | **E4** (0.8 Nr. 17) |
| Neovim: `nvim/colors/dms.lua`, Lualine-Thema `dms`, `_DMS_SUPPORT` | Anbindung an ein fremdes base46, das diese Namen erwartet (0.8 Nr. 60) | solange die Anbindung besteht |
| WirePlumber: `~/.config/wireplumber/wireplumber.conf.d/51-dms-audio-aliases.conf` (`AudioService.qml`) | Datei aus 1.0, liegt auf den Rechnern schon dort; WirePlumber liest jede Datei im Ordner, eine zweite unter neuem Namen würde sich mit ihr überlagern | **F1** (0.8 Nr. 73): Der Umzug benennt sie in `51-alpe-audio-aliases.conf` um, im selben Schritt stellt F1 `AudioService` auf den neuen Namen um; nie beide gleichzeitig |

**Alte CUPS-Abonnements (0.8 Nr. 22), gewählt: einmal kündigen.** Der Dienst legte Abonnements
mit Laufzeit 0 (Abfrageweg; bei cupsd bedeutet 0 «ohne Ende», sofern `MaxLeaseDuration` es
zulässt – `cupsd.conf` ist nur für root lesbar und liess sich nicht prüfen) bzw. 86400 s (D-Bus)
an. Auf ein Auslaufen ist also kein Verlass. Beim ersten Start fragt der Dienst darum einmal
`Get-Subscriptions` ab und kündigt nur Abonnements mit Besitzer `dms`, deren Ereignisliste und
Zustellweg (`ippget` bzw. `dbus://`) denen des Dienstes entsprechen; danach eine Marke in
`~/.local/state/alpe/` (0.8 Nr. 30; nicht unter `~/.config`). Befund am PC (22.11.2026, lesend über IPP): kein Abonnement mit Besitzer
`dms`, eines des angemeldeten Benutzers (`dbus://`, Auftragsereignisse, 3600 s – nicht vom Dienst). Test mit
einer IPP-Attrappe.

**Marken statt Zeileneinträge (0.8 Nr. 64).** Bereiche im Code, die zur Zeile «Lesen alter Namen
bei der Migration» gehören, stehen zwischen zwei Kommentarzeilen `alpe-namen-ausnahme: umzug-ende`.
Die Namensprüfung nimmt alles zwischen den Marken aus und meldet Marken ohne Gegenstück, mit
unbekannter Frist oder ohne Fundstelle dazwischen. `bash tools/namen-pruefen.sh --bereiche` listet
sie; mit «Umzug-Ende» fallen die Bereiche samt Marken weg.

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
| D7.8a | Vorstufe (0.8 Nr. 64–68): Fundstellen ausserhalb der Dateien von D7.8 einzeln eingeordnet; Marken `alpe-namen-ausnahme: umzug-ende` um die Bereiche, die beim Umzug alte Namen lesen; Übersetzungsschlüssel und Kopien der Testumgebungen umbenannt; toter Code der Aktualisierungsprüfung weg; User-Agent mit Version; Layer-Namensräume in einem Schema |
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
(`/usr/lib/qt6/bin/qmllint`) über `shell/` gegen die Grundlinie von 4902 Meldungen, neue Meldungen
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
Folgen für E3: `alpe-shell` liefert `alpe-open.desktop` selbst aus (`packaging/desktop/alpe-open.desktop`,
seit E1 über `make install` → `/usr/share/applications/`; Auswahl «jedes Mal fragen» der Standardprogramme, ruft
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
| Klänge «freedesktop» | `assets/sounds/freedesktop` | ~~CC-BY-SA / CC-BY 3.0 / GPLv2+ je Datei~~ **ausgeliefert nur `audio-volume-change`, `message` (CC-BY-SA ohne Fassung) und `message-new-instant` (Lizenz am Ursprung nicht angegeben)**, je `.oga`/`.wav`; `desktop-login` entfernt (0.8 Nr. 116) | `CREDITS` – bleibt unverändert dabei |
| Klänge «Harmony 2» (Plasma) | `assets/sounds/plasma` | CC-BY-SA 4.0 | LICENSE + README bleiben |
| suncalc.js | `Common/suncalc.js` | BSD-2-Clause | © Vladimir Agafonkin |
| chroma-Lexer (Syntaxhervorhebung) | `core/internal/highlight` | MIT | © 2017 Alec Thomas (`COPYING`) |
| IPP-Bibliothek | `core/pkg/ipp` | Apache 2.0 | LICENSE liegt bei |
| Wayland-Protokollbindungen | `core/internal/proto/*` | MIT-artig (Protokoll-Copyright im Kopf) | Chromium Authors, Simon Ser, Purism, Intel, Collabora … – Köpfe bleiben |
| matugen-VS-Code-Theme | `matugen/vsix-build` | MIT | © 2025 DankLinux |
| Quell-Farbwahl «ported from caelestia-cli» | `core/internal/matugen/sourcecolor.go` | **zu prüfen** – nur Gewichtungs-Konstanten (stammen ursprünglich aus Material Color Utilities, Apache 2.0). Kein übernommener Code erkennbar → Hinweis in NOTICE, Frage 15 |
| `github.com/pilebones/go-udev` v0.10.0 (im Dienst gelinkt) | `core/internal/server/brightness/udev_linux.go` | **GPL-3.0-only** – das Programm `alpe-dienst` als Ganzes wird unter den Bedingungen der GPL-3.0 weitergegeben, der Quelltext von Alpe bleibt MIT | `NOTICE`, Text `LICENSES/GPL-3.0-only.txt`; bleibt in Phase A, fällt mit der Ablösung des Go-Dienstes in Phase B weg (0.8 Nr. 113) |
| `github.com/golang/freetype` (über `fogleman/gg` aus `go-qrcode/writer/standard`) | `core/internal/qrcode/`, `core/internal/server/network/` (WLAN-QR) | **FTL** (gewählt; sonst GPL-2.0-or-later) | `NOTICE` mit Nennung des FreeType-Teams, `licenses/ftl.txt` unverändert in Archiv und Paket (0.8 Nr. 114) |
| `github.com/yeqown/reedsolomon` v1.0.0 (über `go-qrcode/v2`) | `core/internal/qrcode/`, `core/internal/server/network/` | MIT (Lizenzdatei erst seit 08.03.2026 am Ursprung, Code gleich v1.0.0) | `NOTICE` mit Fundstelle (0.8 Nr. 115) |
| Go-Abhängigkeiten (≈90 Module) | `go.mod` | MIT/BSD/Apache/ISC u. a. | Liste wird beim Umsetzen mit `go-licenses report` erzeugt und in `NOTICE` bzw. `packaging/LICENSES-go.txt` abgelegt; GPL-Module würden auffallen (bisher keines erkannt; **berichtigt in E1 2.8:** `go-udev`, Zeile oben) |
| Logos Dritter | `assets/` (niri, sway, mango, labwc, miracle, umbriel, hyprland, discord, reddit, matrix, flatpak, snap, nix, appimage) | Marken | fallen bis auf `hyprland.svg` und die Paketquellen-Symbole weg (Kandidaten-Liste 4); **seit 0.8 Nr. 117** `discord.svg`/`reddit.svg` entfernt, die übrigen fünf in `NOTICE` als Zeichen Dritter nur zur Bezeichnung (Flatpak CC BY 3.0, Snapcraft CC BY-SA 3.0, Nix CC BY 4.0, Hyprland ARR nach Markenrichtlinie, AppImage unbelegt) |
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
/usr/share/alpe/assets/fastfetch-logo.txt    Logo für tools/fastfetch.py (liest ../assets/)
/usr/share/plasma/shells/org.alpe.desktop/   KDE-Sperre, beim Bau mit der Ansicht aus shell/Modules/Lock/Alpe zusammengesetzt
                                             (HyprlockView.qml, layout.js, ganzer Ordner fonts; Version aus Brand.qml)
/usr/lib/systemd/user/alpe.service
/usr/share/applications/io.github.alpe_shell.Alpe{,.Notepad}.desktop
/usr/share/applications/alpe-open.desktop    Auswahl «jedes Mal fragen» (packaging/desktop/alpe-open.desktop, 0.8 Nr. 50, 59)
/usr/share/icons/hicolor/scalable/apps/io.github.alpe_shell.Alpe.svg   aus assets/logo/logo/alpe-zeichen.svg
/usr/share/bash-completion/completions/alpe-dienst
/usr/share/zsh/site-functions/_alpe-dienst
/usr/share/fish/vendor_completions.d/alpe-dienst.fish
/usr/share/licenses/alpe-shell/{LICENSE,NOTICE,GPL-3.0-only.txt,FTL.txt,…}   Lizenztexte (0.8 Nr. 113, 114)
```

**Makefile in der Wurzel (E1, 25.11.2026):** `make build` baut `alpe-dienst` ohne eingebettete Oberfläche (kein Tag
`withshell`, `-trimpath`, `CGO_ENABLED=0`, Version aus `Brand.qml` über ldflags wie in `core/Makefile`,
`SOURCE_DATE_EPOCH` wird beachtet); `make install DESTDIR=… PREFIX=…` legt den Baum an (Oberfläche und Plugins ohne
Tests – Liste `core/shell-test-excludes.txt` –, ohne `translations/*.py` und `scripts/qmllint-entrypoints.sh`;
**Werkzeuge nur aus der ausdrücklichen Liste `TOOLS`**: `alpe`, `activate-plugins.py`, `design.py`, `entfernen.sh`,
`fastfetch.py`, `hyprlock2qml.py`, `kde-sitzung.sh`, `kopfleiste.py`, `kuerzel.py`, `lockscreen.sh`, `maclock.sh`,
`titelleisten.py`; nicht ins Paket: `test.sh`, `test-commit.sh`, `node-tests.py`, `namen-*`, `werte-*`,
`neue-dateien-pruefen.sh`, `release-pruefen.sh`, `standbild.py`, `build-basemap.py`, `radar-probe.py`, `backend.sh` –
0.8 Nr. 109 (3)); `make test` = `tools/test.sh`; `make dist` = Quellarchiv aus `git archive HEAD` mit vendorten
Go-Modulen, reproduzierbar gepackt. Test: `tests/test_makefile.py`. **Seit 2.3/2.4 (25.11.2026)** installiert
`make install` auch das Sperrpaket (`make sperrpaket`, Teil von `build`), die Unit aus
`packaging/systemd/alpe.service`, die Desktop-Dateien aus `packaging/desktop/` (Pfade jeweils auf `PREFIX`
umgeschrieben), das Symbol und die Vervollständigungen (beim Bau mit `alpe-dienst completion bash|zsh|fish` erzeugt).
**Zu `.Open`:** Die Umbenennungstabelle (2.2) schlug `io.github.alpe_shell.Alpe.Open` als neuen Namen für
`dms-open.desktop` vor; entschieden ist `alpe-open.desktop` (0.8 Nr. 50, 59). Eine Datei `….Alpe.Open.desktop`
gibt es nicht – zwei Einträge für dieselben Link- und HTML-Typen erschienen doppelt in «Öffnen mit».
**Unit:** zusätzlich zu den Angaben unten `ALPE_SHELL_ARENA=1` (wie das Drop-in aus 1.0: die Shell gibt
`MALLOC_ARENA_MAX` nicht an Programme weiter, die man aus ihr startet, `SessionService.qml`) und die übrigen Zeilen
von `dms.service` (`ExecReload`, `LimitNOFILE`, `Restart…`, `Timeout…`, `Before=tray.target`). Test:
`tests/test_paketdateien.py`.
**Nachgebessert (Prüfung zu 2.2):** Zusätzlich `/usr/share/alpe/assets/fastfetch-logo.txt` – `tools/fastfetch.py`
liest `../assets/fastfetch-logo.txt` (der Baum spiegelt das Repo); sonst nichts aus `assets/`. `make install` baut
den Dienst nicht neu, wenn er schon gebaut ist (im Paketbau gingen sonst die `GOFLAGS` des Bauschritts verloren,
etwa `-buildmode=pie`); `EXTRA_LDFLAGS` für Zusätze wie eine Build-ID; `-buildvcs=false`, der Commit kommt nur aus
diesem Repository (nicht aus einem umschliessenden) oder aus der Datei `COMMIT` im Quellarchiv. `make dist` nimmt
Version und Commit aus `HEAD`, packt mit festen Modi (`--mode=u+rwX,go=rX`) und ist damit unabhängig von der umask
bytegleich (Test: zweiter Lauf mit umask 002); das Ergebnis hängt noch an der Go-Version, die vendort
(`vendor/modules.txt`).

`alpe.service` (aus `dms.service` abgeleitet):
`Description=Alpe`, `PartOf/After/Requisite=graphical-session.target`, `Type=notify`,
~~`BusName=org.freedesktop.Notifications`~~ (**seit 0.8 Nr. 120 kein `BusName=`**: zwei Units mit demselben
Busnamen laden nicht nebeneinander, `dms.service` aus 1.0 trägt ihn; bei `Type=notify` nicht nötig),
`Environment=QS_DISABLE_CRASH_HANDLER=1 MALLOC_ARENA_MAX=2`,
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

- `pkgname=alpe-shell`, `arch=(x86_64 aarch64)`, `license=(MIT CC-BY-4.0 CC0-1.0)` (Entscheid vom
  24.11.2026: MIT für Alpe und den Ursprung, CC-BY-4.0 für die Hintergrundmuster von Hero Patterns,
  CC0-1.0 für die Bilder des ausgelieferten Designs; Einzelheiten in `NOTICE`). ~~**Offen beim
  Maintainer:** ob das Feld bei diesen drei bleibt oder nach der Dateiliste von E1 vollständig wird~~
  **Entschieden am 25.11.2026:** Das Feld wird **vollständig aus der Dateiliste von `make install`**
  gebildet und am Ende von E1 festgelegt – Vorschlag aus der Tabelle Datei → Lizenz, Entscheid des
  Maintainers (`offene-faelle.md`, «Lizenzfeld der Pakete»); bis dahin stehen hier die drei.
  **Entschieden am 25.11.2026:** `GPL-3.0-only` gehört ins Feld (`go-udev` im Dienst, 0.8 Nr. 113), ebenso `FTL`
  (`golang/freetype`, Alpe wählt die FTL, Nr. 114).
- `depends=(quickshell>=0.3.2 qt6-base qt6-declarative qt6-multimedia qt6-svg accountsservice python matugen wtype wireplumber breeze-icons hicolor-icon-theme)`
  (`quickshell>=0.3.2`: so verlangt es die Systemprüfung des Ursprungs, und mit 0.3.2 ist an PC und
  Mac getestet; Untergrenze und Pragmas in 0.8 Nr. 97. `wireplumber`: liefert `wpexec` für den
  Codec-Wechsel bei Bluetooth, 0.8 Nr. 96 – `lua` wird nicht gebraucht. `breeze-icons`,
  `hicolor-icon-theme`: 0.8 Nr. 105)
- **Aufgabe (0.8 Nr. 91): `kora-icon-theme` in `depends`** (AUR, GPL-3.0, getrenntes Paket). Zu beachten
  beim Umsetzen: (a) `pacman` löst AUR-Abhängigkeiten nicht auf – der Weg «PKGBUILD aus dem Repo mit
  `makepkg -si`» braucht kora vorher (AUR-Helfer oder eigener Bau, siehe 6.4); (b) das AUR-Paket
  `kora-icon-theme` 2.0.6 führt `breeze-icons` und `hicolor-icon-theme` nur als `optdepends`, kora erbt
  aber von beiden (`Inherits=breeze,hicolor`) – Vorschlag: `breeze-icons` und `hicolor-icon-theme`
  ebenfalls in `depends` von `alpe-shell`.
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

- Chroots: **`fedora-45-aarch64` und `fedora-45-x86_64`** (der Mac läuft mit Fedora Asahi Remix 45,
  Mac-Test vom 23.11.2026), dazu die jeweils nächste Fassung, sobald Asahi Remix folgt
- **Entschieden am 25.11.2026:** `GPL-3.0-only` gehört auch in dieses Feld – das RPM liefert `alpe-dienst` mit
  `go-udev` aus (0.8 Nr. 113); die Spec liefert `LICENSES/GPL-3.0-only.txt` als `%license` mit. Ebenso `FTL`
  (`golang/freetype`, Nr. 114) – nur `FTL`, nicht `(FTL OR GPL-2.0-or-later)`, weil Alpe gewählt hat (gefolgert, an
  der Fedora-Richtlinie bei E3 nachschlagen); `%license` dazu `core/vendor/github.com/golang/freetype/licenses/ftl.txt`
  aus dem Archiv von `make dist` (nicht unter `LICENSES/`).
- `License: MIT AND CC-BY-4.0 AND CC0-1.0` (Entscheid vom 24.11.2026: das Lizenzfeld nennt MIT,
  CC-BY-4.0 und CC0-1.0, wie in 6.2; die Verknüpfung mit `AND` ist die SPDX-Schreibweise von Fedora
  für «alles davon ist enthalten» – der Entscheid nennt die drei Namen, die Schreibweise ist hier
  ergänzt und nicht an der Fedora-Richtlinie nachgeschlagen; bei E3 dort und mit `rpmlint`
  bestätigen). Unter `shell/` liegen nach `NOTICE` auch Teile unter anderen Lizenzen (Schriften
  OFL-1.1 und Apache-2.0, Klänge CC-BY-SA 4.0, CC-BY 3.0 und GPLv2+ – seit 0.8 Nr. 116 berichtigt: CC-BY-SA 4.0
  und CC-BY-SA ohne Fassung, `message` widersprüchlich, `message-new-instant` ungeklärt –, `suncalc.js` BSD-2-Clause,
  seit 0.8 Nr. 117 auch `fzf.js` BSD-3-Clause, `Hct.js` und `MaterialShapeData.js` Apache-2.0, Zeichen Dritter
  (CC BY 3.0, CC BY-SA 3.0, CC BY 4.0, Hyprland ARR),
  dazu die Go-Abhängigkeiten im Programm). **Entschieden am 25.11.2026 (`offene-faelle.md`,
  «Lizenzfeld der Pakete»):** Das Lizenzfeld wird vollständig aus der Dateiliste von `make install`
  gebildet, festgelegt am Ende von E1 – Vorschlag aus der Tabelle Datei → Lizenz, Entscheid des
  Maintainers; dasselbe gilt für 6.2.
- `Requires: quickshell >= 0.3.2, matugen, python3, accountsservice, qt6-qtmultimedia, wtype,
  wireplumber, kora-icon-theme, breeze-icon-theme` (`wireplumber` für `wpexec`, 0.8 Nr. 96 – vor dem
  Umsetzen am Mac mit `rpm -qf /usr/bin/wpexec` bestätigen; `quickshell`: 0.8 Nr. 97;
  `breeze-icon-theme`: 0.8 Nr. 105; kein `lua`);
- **kora und fremde COPRs (0.8 Nr. 99):** Das eigene COPR baut `kora-icon-theme` für fc45 auf beiden
  Architekturen. `alpe-shell` verlangt `kora-icon-theme` ohne Version und ohne Herkunft; liegt
  schon ein gleichnamiges Paket aus einem anderen COPR vor (am Mac: `hazel-bunny/ricing`), bleibt
  es bei gleicher Repo-Priorität bestehen, wenn sein Release höher zählt. Keine `Epoch`, kein
  `Obsoletes`, keine `priority` in der eigenen Repodatei.
  `Recommends: python3-h5py, ffmpeg-free, slurp, hyprlock, hypridle, kitty, fastfetch`
- **Aufgabe (0.8 Nr. 91): `kora-icon-theme` im eigenen COPR mitbauen** (eigene Spec, Lizenz GPL-3.0,
  Quelle `github.com/bikass/kora`), `alpe-shell` verlangt es mit `Requires: kora-icon-theme`. Dazu
  prüfen: das Ersatzthema breeze (`Inherits=breeze,hicolor`) – unter Fedora `breeze-icon-theme`, auf
  Fedora Asahi mit Hyprland nicht in der Grundinstallation; Vorschlag: ebenfalls `Requires`.
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
   **Aufgabe (0.8 Nr. 91): kora wird auf beiden Systemen mitinstalliert** – über die Abhängigkeit des
   Pakets (AUR-Helfer bzw. COPR); auf dem Weg ohne AUR-Helfer (`makepkg -si` aus dem Repo) baut
   `get.sh` zuerst `kora-icon-theme` aus dem AUR, **vor** `alpe-shell` – `pacman` löst
   AUR-Abhängigkeiten nicht auf (0.8 Nr. 105); `breeze-icons` kommt aus den Paketquellen. Probelauf `--check` prüft, dass
   `/usr/share/icons/kora/index.theme` danach vorhanden ist.
4. `alpe einrichten`, unter KDE `alpe kde ein --jetzt`, unter Hyprland
   `alpe-dienst systemd enable` (`hyprland-session.target` will `alpe.service`, 0.6 Nr. 1); eine
   vorhandene `exec-once`-Zeile mit `dms run`/`alpe start` wird mit Sicherung auskommentiert,
   sonst liefen zwei Shells.
5. Design einspielen (wie heute).
- Fallback ohne Paket für Entwicklung: `make build install PREFIX=$HOME/.local` + Unit nach
  `~/.config/systemd/user/` (Option `--aus-quelle`). `build` gehört dazu: `install` allein nimmt einen schon
  gebauten Dienst aus `build/`, der nach `git pull` veraltet sein kann (Makefile, Nachbesserung zu 2.2).
  `make install` im Repository braucht den Modul-Cache desselben Benutzers (Lizenztext von `golang/freetype`,
  0.8 Nr. 114) – also nicht `sudo make install` nach einem Bau als Benutzer.
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

**Vorgelegt am 22.11.2026, nicht entschieden: `docs/plan/sperrbildschirm-dateien.md`.** Berichtigung
zum Absatz oben: Bilder schreibt `lockscreen.sh` nicht ins Paket (das Layout nennt sie mit
absolutem Pfad); nutzerspezifisch ist dort allein `layout.js`, und nur mit einer eigenen
`~/.config/alpe/hyprlock.conf`. **Entschieden (22.11.2026):** Frage 4 – die Version in
`metadata.json` des Sperrpakets wird beim Paketbau aus derselben Quelle wie `Brand.version`
gesetzt, umgesetzt mit E1; Frage 3 – neutrale `layout.js` und Prüfung des ganzen Repos sind
erledigt (`56fcedd`, `016d986`). **Vollständig entschieden am 23.11.2026 (0.8 Nr. 86): Frage 1
Variante A** (Systempaket unverändert, Eigenes in `kscreenlockerrc`, nichts mehr unter
`~/.local/share/plasma/shells`); **Frage 2:** eine vorhandene eigene `hyprlock.conf` wird einmal
übernommen, Umsetzung in F1. Aufteilung: Zusammenbau des Pakets und Version in E1,
`lockscreen.sh`/`AlpeLockTab.qml`/`entfernen` in E4, Übernahme im Umzug in F1 (7.2 Nr. 5).

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
   **Angepasste Fassungen (0.8 Nr. 69):** Liegt ein fremdes Plugin schon unter
   `~/.config/alpe/plugins` (nach `docs/plugins-anpassen.md` angepasst), bleibt es, wie es ist –
   der Umzug kopiert nie eine unangepasste Fassung aus `~/.config/dms/plugins` darüber, auch nicht
   einzelne Dateien. **Meldung:** Für jedes Plugin unter `~/.config/dms/plugins`, das Alpe nicht
   selbst mitliefert und zu dem es unter `~/.config/alpe/plugins` keine Fassung gibt, und für jede
   Fassung dort, die noch alte Namen trägt (`Dank*`-Typen, `qs.DCommon`, `qs.Modules.DDash`,
   Aufruf von `dms`, `requires_dms`), nennt der Umzug am Ende ID, Ordner und Grund: «lädt unter
   1.1 nicht ohne Anpassung», mit Verweis auf die Anleitung. `plugin_settings.json` zieht mit den
   übrigen Dateien um; ein dort eingeschaltetes, aber nicht ladbares Plugin steht in der Meldung.
   Test in F1 mit beiden Fällen (angepasste Fassung bleibt bytegleich; unangepasstes wird gemeldet).
   `~/.local/state/dms/*` → `~/.local/state/alpe/`. Aus `~/.cache/dms` nur Zwischenablage und
   Mitteilungsverlauf. **Alte Ordner bleiben unangetastet** (Rückweg); weg mit
   `alpe umzug aufraeumen` oder `alpe entfernen --alles` (Frage 11).
   Schlüssel/Werte in `settings.json` benennt die Shell selbst beim ersten Start um
   (`SettingsData`-Migration, legt `settings.v<alt>.json` an) – eine Stelle, auch für Leute,
   die alte Sicherungen zurückspielen.
   **WirePlumber (0.8 Nr. 73):** `~/.config/wireplumber/wireplumber.conf.d/51-dms-audio-aliases.conf`
   wird in `51-alpe-audio-aliases.conf` **umbenannt** (nicht kopiert; Inhalt unverändert, Eintrag
   im Protokoll). Liegt der neue Name schon vor, bleibt er, und die alte Datei geht in die
   Sicherung und wird entfernt – **es liegen nie beide im Ordner**, weil WirePlumber jede Datei dort
   liest. Mit F1 schreibt und löscht `AudioService` nur noch den neuen Namen (bis dahin den alten,
   Ausnahmeliste 2.3.3); der Eintrag der Ausnahmeliste fällt im selben Commit weg. Test in F1:
   nur alte Datei, nur neue Datei, beide, keine; danach jeweils höchstens eine, und der Rückweg
   stellt den alten Namen wieder her. WirePlumber wird vom Umzug nicht neu gestartet (6.8).
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
   | Layer-Namensräume des Dienstes in `layerrule`/`layer_rule`: `dms-colorpicker`, `dms-screenshot` (D7.7h; Schema vereinheitlicht, 0.8 Nr. 68, 75) | `alpe:eyedropper`, `alpe:screenshot` |

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
- **WirePlumber (0.8 Nr. 73):** `51-alpe-audio-aliases.conf` → `51-dms-audio-aliases.conf`, im
  aktuellen Stand der Datei (Gerätenamen, die nach dem Umzug vergeben wurden, bleiben erhalten);
  auch hier nie beide Dateien gleichzeitig. Hat der Umzug eine alte Datei neben einer schon
  vorhandenen neuen entfernt, kommt die alte aus der Sicherung zurück und die neue geht weg.

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

### 7.8 Design-Export: Schlüssel der Session (0.8 Nr. 79)

`tools/design.py export` übernimmt aus `session.json` nur die Schlüssel der Liste `SESSION_GESTALTUNG`.
Alle 100 Schlüssel der Session (88 in `SessionSpec.js`, 12 in `SharedSessionSpec.js`) sind im Code
eingeordnet; `tests/test_design.py` verlangt die Einordnung für jeden Schlüssel und prüft, dass
`design/*/session.json` nur Gestaltung enthält. Ein Schlüssel, den die Spec nicht kennt, wird nicht
exportiert.

**Gestaltung (26, werden exportiert):**

| Gruppe | Schlüssel |
|---|---|
| Hell/Dunkel, Hintergrund | `isLightMode`, `wallpaperPath`, `wallpaperPathLight`, `wallpaperPathDark` (die beiden letzten nur mit `perModeWallpaper`), `perModeWallpaper`, `wallpaperTransition`, `includedTransitions` |
| Material-Vorlage und Formen | `materialWallpapers` (nur der Eintrag `""` für alle Bildschirme; Einträge je Bildschirm fallen weg, mit Hinweis), `materialWallpaperProfiles` |
| Zeitplan Hell/Dunkel | `themeModeAutoEnabled`, `themeModeAutoMode`, `themeModeStartHour`, `themeModeStartMinute`, `themeModeEndHour`, `themeModeEndMinute`, `themeModeShareGammaSettings` |
| Nachtlicht | `nightModeEnabled`, `nightModeTemperature`, `nightModeHighTemperature`, `nightModeAutoEnabled`, `nightModeAutoMode`, `nightModeStartHour`, `nightModeStartMinute`, `nightModeEndHour`, `nightModeEndMinute`, `nightModeTransitionMinutes` |

**Zustand (74, bleiben beim Nutzer):** Augenblickszustand (Nicht stören, Wachhalten, Hinweise des
Aktualisierers, `builtInPluginState`, `lastAppliedIconTheme`, `showConfigReloadToast`); Verläufe und
zuletzt Benutztes (`recentColors`, Starter- und Notizblock-Verläufe, VPN, Medienspieler,
`lastBrightnessDevice`); Programme des Nutzers (`dockPins`, `barPinnedApps`, `hiddenTrayIds`,
`trayItemOrder`, `hiddenApps`, `appOverrides`, `searchAppActions`, `terminalOverride`); Ort und Sprache
(`weatherLocation`, `weatherCoordinates`, `latitude`, `longitude`, `nightModeUseIPLocation`,
`nightModeLocationName`, `locale`, `timeLocale`); alles mit Bildschirmnamen oder -modellen als Schlüssel
(`perMonitorWallpaper`, `monitorWallpapers*`, `monitorWallpaperFillModes`, `monitorCyclingSettings`,
`desktopWidgetInstancePositions`, `lockScreenAutoPositions`, `desktopWidgetGridSettings`,
`lockScreenWidgetGridSettings`, `islandFreePositions`, `hyprlandOutputSettings`, `activeDisplayProfile*`,
`displayGamma`, `displayContrast`); Hintergrundwechsel aus einem eigenen Ordner (`wallpaperCycling*`);
Geräte (Helligkeit, Grafikkarten, WLAN, Bluetooth, Lautstärken, ausgeblendete Audiogeräte).

**Gegenüber der früheren Liste `SESSION_KEEP` geändert:** neu dabei `materialWallpapers`,
`materialWallpaperProfiles`; nicht mehr exportiert `dockPins`, `barPinnedApps`, `trayItemOrder`,
`recentColors` (Zustand), `desktopWidgetGridSettings`, `lockScreenWidgetGridSettings`,
`islandFreePositions` (Schlüssel sind Bildschirmnamen), `locale`, `timeLocale` (Sprache des Nutzers);
gestrichen `wallpaperFillMode` (kein Schlüssel der Session, steht in `settings.json`).
**Einspielen:** Eigene Formen des Nutzers (`materialWallpaperProfiles`) bleiben neben denen des Designs
bestehen. **Das Einspielen wendet dieselbe Liste an (0.8 Nr. 83):** Aus der Session eines Designs kommen
nur Schlüssel aus `SESSION_GESTALTUNG` in die Session des Nutzers; Zustand (etwa Anheftungen, Farbverlauf
oder Sprache aus einem älteren Export) und unbekannte Schlüssel werden weggelassen und beim Einspielen
genannt. Der frühere Filter «nur installierte Programme anheften» ist damit entfallen.

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
| E1 | **Erster Schritt: Standbild der Sperre ohne `ffmpeg`** (0.8 Nr. 106, angenommen am 24.11.2026) – fertige Datei `design/kde/bilder/jagged-peaks-wolkenzug.jpg` im Repository, Erzeugungsskript unter `tools/`, Test über die Prüfsumme der Quelle, Eintrag in `NOTICE`; die Shell nimmt das mitgelieferte Bild vor `ffmpeg`, `design.py` kopiert es mit. Danach: Makefile, systemd-Unit, Desktop-Dateien; **PAM-Dienste, Richtlinien und alle paketierten Pfade mit `alpe`-Namen** (0.8 Nr. 16). **Am Ende von E1** (Entscheid vom 25.11.2026): Lizenzfeld der Pakete vollständig aus der Dateiliste von `make install`. **Zu E1 gehört auch das Bild der KDE-Sperre** (0.8 Nr. 108, `halt-kwin-kdesperre.png`), **aber nicht in einem unbeaufsichtigten Lauf** | Standbild: Test der Prüfsumme und Node-Test der Auswahl; `make install DESTDIR` getestet in Temp-Wurzel; Dateiliste ohne Überschneidung mit dem Paket `dms`/`dux-shell` |
| E2 | PKGBUILD; **`depends` auf `kora-icon-theme`** (AUR; 0.8 Nr. 91, Einzelheiten 6.2 – der Entscheid nennt E3/E4, das PKGBUILD selbst entsteht hier); `depends` dazu `wireplumber` (`wpexec`, 0.8 Nr. 96), `breeze-icons`, `hicolor-icon-theme` (0.8 Nr. 105), `quickshell>=0.3.2` (0.8 Nr. 97); kein `lua`; `license=(MIT CC-BY-4.0 CC0-1.0)` (6.2; seit dem 25.11.2026 entschieden: das Feld wird vollständig aus der Dateiliste von `make install` gebildet, festgelegt am Ende von E1; `offene-faelle.md`, «Lizenzfeld der Pakete»; **`GPL-3.0-only` und `FTL` gehören dazu**, 0.8 Nr. 113, 114) | CI-Bau |
| E3 | RPM-Spec; `dsearch` (dux-search) wird **optionale** Abhängigkeit, keine harte, weil die Dateisuche ohne das Programm läuft: `optdepends` im PKGBUILD, `Recommends:` in der RPM-Spec (0.8 Nr. 26). **Aufgabe kora (0.8 Nr. 91):** `kora-icon-theme` im eigenen COPR mitbauen, `Requires: kora-icon-theme` in der Spec; Arch `depends` (6.2, 6.3). **Nach dem Mac-Test (0.8 Nr. 96, 97, 99, 105):** `Requires` dazu `wireplumber`, `breeze-icon-theme`, `quickshell >= 0.3.2`; Chroots fc45 auf aarch64 und x86_64; `kora-icon-theme` ohne Version und Herkunft, keine `Epoch`/`Obsoletes`/`priority` wegen fremder COPRs. **Lizenzfeld der Pakete (Entscheid vom 24.11.2026): MIT, CC-BY-4.0 und CC0-1.0; seit dem 25.11.2026 vollständig aus der Dateiliste von `make install`, festgelegt am Ende von E1** – bis dahin in der Spec `License: MIT AND CC-BY-4.0 AND CC0-1.0` (6.3), im PKGBUILD `license=(MIT CC-BY-4.0 CC0-1.0)` (6.2); **`GPL-3.0-only` und `FTL` gehören in beide Felder** (`go-udev` im Dienst, 0.8 Nr. 113; `golang/freetype` unter der FTL, Nr. 114; Texte als `%license`: `LICENSES/GPL-3.0-only.txt` und `core/vendor/github.com/golang/freetype/licenses/ftl.txt` aus dem Archiv); `NOTICE` nennt je CC-BY-Quelle Urheber, Lizenzverweis und ob die Datei verändert wurde | CI-Bau x86_64 |
| E4 | Werkzeuge: `alpe` CLI, einrichten.sh, entwicklung, doctor/update/entfernen/backup, kde-sitzung, lockscreen, kuerzel, titelleisten, design.py. **Aufgabe kora (0.8 Nr. 91):** Die Werkzeuge setzen kora als Abhängigkeit des Pakets voraus (kein eigenes Kopieren ins Home); Vorschlag dazu, noch nicht entschieden: `alpe doctor` meldet ein fehlendes Symbolthema des Designs (kora, Ersatzthema breeze), `design.py` nennt beim Einspielen ein Symbolthema, das nicht installiert ist. **Laufender Baum (0.8 Nr. 101):** `alpe update` und jede Aktualisierung schreiben erst vollständig, dann wird umgeschaltet oder neu gestartet – nie in Teilschritten in einen Baum, aus dem eine Shell läuft. `alpe start` hängt nur an `settings.json`, nicht am Ordner `~/.config/alpe` (0.8 Nr. 100). `alpe doctor` nennt die Herkunft von kora (0.8 Nr. 99). **Lizenzfeld der Pakete (Entscheid vom 24.11.2026, vom Maintainer für E3 und E4 genannt): MIT, CC-BY-4.0 und CC0-1.0; seit dem 25.11.2026 vollständig aus der Dateiliste von `make install`, festgelegt am Ende von E1; dazu gehören `GPL-3.0-only` und `FTL`, 0.8 Nr. 113, 114**; die Paketdateien selbst entstehen nach dieser Tabelle in E2 (PKGBUILD) und E3 (Spec) | bestehende Tests nachgeführt |
| F1 | Umzug: `tools/umzug.py`, `install.sh`-Übergang, Testdaten, Test; **nach F1 an der Shell-Sperre zu beurteilen** (aus der Mac-Liste verschoben, Entscheid vom 25.11.2026; `offene-faelle.md`, Punkte 4 und 5): Breite und Lesbarkeit des Passwortfelds am Bildschirm des MacBooks (2560 × 1664), Streifen im Himmel des Sperrbilds am Mac; **Standbild des Design-Videos** (0.8 Nr. 106 (iii)): das `.jpg` muss nach `<XDG_DATA_HOME>/alpe/design/bilder/` kommen, sonst gibt es ohne ffmpeg kein Standbild; Benutzerkopien ausgelieferter Plugins mit Rückweg zur Seite legen (0.8 Nr. 32). **Sicherungen der Mac-Tests auslassen:** Ordner mit `.vor-phase-a` oder `.vor-d7` im Namen (`~/.config/dms.vor-d7`, `~/.config/hypr.vor-d7`, `~/.config/alpe.vor-d7`, `~/.local/state/alpe.vor-d7` und die gleichnamigen mit `.vor-phase-a`) gelten als Sicherungen und werden weder umgezogen noch umgeschrieben noch gelöscht (wie 0.8 Nr. 57), mit Test. **Nach dem Mac-Test vom 23.11.2026:** (a) `~/.config/alpe` gibt es vor dem Umzug schon (`aus`, Marken, angepasste Plugins) – entschieden wird nur an `settings.json`, eigener Testfall (0.8 Nr. 100); (b) der laufende Baum von 1.0 (`~/dux-shell/quickshell`) wird nie in Teilschritten verändert: erst vollständig schreiben, dann umschalten oder neu starten (0.8 Nr. 101); (c) Kürzel aus `hypr/dms/binds.lua` (`dms ipc call …`, `dms screenshot …`) greifen bis zum Umzug nicht, 7.4 Schritt 6 schreibt sie um (im Mac-Test bestätigt) | |
| F2 | get.sh neu; **installiert kora auf beiden Systemen mit** (0.8 Nr. 91, 6.4) | Probelauf `--check` in Temp-`HOME` mit Attrappen |
| G1 | Doku, Brand 1.1, CHANGELOG, Namensprüfung + Ausnahmeliste; `Brand.version` auf 1.1 und **im selben Commit** `requires_alpe: >=1.1` für jedes Plugin, das Alpe ausliefert oder pflegt (`plugins/` im Repo, `~/alpe-plugins`; 0.8 Nr. 31). Bis dahin `>=1.0`, solange `Brand.version` noch 1.0 meldet. **CHANGELOG 1.1 enthält den Eintrag zur Behebung «Dienst hing bei stummem Systembus, Oberfläche verband sich nie»** (0.8 Nr. 85; `docs/plan/dienst-systembus.md`). **`docs/plugins-anpassen.md` auf `requires_alpe: ">=1.1"` umstellen** (alle `sed`-Zeilen und der erklärende Absatz; bis G1 steht dort `">=1.0"`, weil `Brand.version` bis G1 1.0 meldet), im selben Commit wie `Brand.version` | |

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
| Zwei Shells gleichzeitig (`BusName` Mitteilungen, Leisten doppelt; `alpe.service` seit 0.8 Nr. 120 ohne `BusName=`, der Name der Mitteilungen wird zur Laufzeit belegt) | Umzug stoppt `dms.service` vor dem Start von `alpe.service`; `alpe doctor` warnt |
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
