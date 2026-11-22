# Phase A – Plan zur Umsetzung (Alpe 1.1 «Zugerberg»)

Stand: 21. November 2026, Branch `phase-a`. **Freigegeben am 21.11.2026** mit den Entscheiden in 0.4. Grundlage: `docs/plan/phase-a.md`, `CLAUDE.md`,
`KONTEXT.md`, Erkundung von `~/alpe` (Commit c988364) und `~/dux-shell` (Branch `alpe` =
v2.1.2 + 2 Schichten). Umgesetzt bis D6 (Halt), siehe «Stand»; Entscheide nach D3 in 0.7, nach D6 in 0.8 (D7 wieder
aufgenommen, Abschnitt 2.3); offene Einzelfälle in
`docs/plan/offene-faelle.md`.

---

## Stand (22.11.2026, nach D6)

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
| `8301a6a` | **D6** Dienst: Hilfe, Meldungen, Mitteilungs-Absender, Terminaltitel | Go wie bekannt (Tests angepasst) |
| `1bbf8da` | **D6** Alpe-Zeichen unter eigenem Dateinamen, `dank.svg` weg | dito |
| `b3db7fd` | **D6** Über-Seite: Beschreibung, Herkunft, Lizenz | dito |
| `d4c90f5`, `7e3c5a3` | **D6** übrige Oberflächentexte (Kürzelkategorie, `dms setup`-Hinweise, Plugin-Basisversion, Kopfzeilen, Testmitteilungen) | dito; Node-Tests config-include, plugin-reload, settings-search-cards neu in test.sh |
| `82ecea2` | Ladeprüfung auf dem Endstand: KWin 29/29, Hyprland 38/38, nur die 2 geänderten Meldungen; Grundlinien nachgeführt | – |

Go-Tests (`go test ./...`, abgeschottet): dieselben 3 Fehlschläge wie vor C1 (siehe offene
Fälle). Node-Tests des Ursprungs: 10 Fehlschläge, alle schon vor C1 rot. Jeder Commit nach D3
einzeln mit test.sh geprüft (Zwischenstände in einem Temp-Worktree).

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
- **0.8: D7 kommt wieder** (vollständige Umbenennung der internen Namen, Abschnitt 2.3).
  Vor dem Start: Freigabe von 2.3 und die Fragen in `offene-faelle.md`, «Vor D7». Halt nach D7.
- Danach: Vorlage 6.7 (Sperrbildschirm) vor E1, dann E1–E4, Halt nach E4.

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
| 6 | **Prüfregel ab D4:** `bash tools/test.sh` nach jedem Commit. Die Ladeprüfung läuft **einmal pro Halt** auf dem Endstand unter KWin und Hyprland; nur wenn sie neue Meldungen zeigt, werden die Commits dazwischen einzeln geprüft. Keine Überwachungen, die sich periodisch neu stellen. |
| 7 | Mac-Test nach D6 statt nach D3. |

### 0.8 Entscheide nach dem Halt D6 (22.11.2026)

| # | Entscheid |
|---|---|
| 1 | **Korrektur zu 0.7 Nr. 3: D7 bleibt.** Vollständige Umbenennung der internen Namen (`DankBar`, `DMSService`, `Dank*`-Widgets usw.). Kompatibilität mit dem DMS-Plugin-Store braucht Alpe nicht; ein eigener Store kommt allenfalls später. |
| 2 | **Keine `Dank*`-Weiterleitungen** (auch nicht `Modules/DankBar`, `Modules/DankDash`, `Common/Dank*`, `DankModal`). Die Plugin-Beschreibung bekommt eigene Namen (`requires_alpe` statt `requires_dms` …); `alpeSport`, `alpeMeteoSwiss`, `alpeRadar` im selben Zug. |
| 3 | **Fremde Plugins** hueManager, calculator (Mac) und sathiAi (PC) werden an die neuen Namen angepasst. Lizenz vorher prüfen: Erlaubt sie es, kommen sie als von Alpe gepflegte Plugins ins Repo, sonst Anleitung für die lokalen Kopien. Befund siehe 2.3.4. |
| 4 | **Kein `/usr/bin/dms`.** |
| 5 | **D7 nach D6 mit eigenem Halt**, skriptbasiert, ein Commit pro Bereich, Ladeprüfung auf dem Endstand unter KWin und Hyprland (Prüfregel 0.7 Nr. 6). Die Weiterleitungen fallen erst weg, wenn alle Plugins angepasst sind (letzter Commit von D7). |

Folgen: Die Fragen 1 und 3 zum Halt D6 (Kennungen `dms_*` der Starter-Plugins, Logo-Modus
`"dank"`) erledigt D7 (2.3.2, D7.5). Die Ausnahmeliste der Namensprüfung (9) schrumpft auf 2.2
«Begründete Ausnahmen» und 2.3.3.

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
| QML-Typen/Dateien `DMSService`, `DMSNetworkService`, `DMSShell*.qml`, `DankBar`, `DankDash`, `dankLauncherV2` … | `ShellBackend`, `BackendNetworkService`, `AlpeShell*.qml`, … (Tiefe: Frage 6) |
| Einstellungs-Schlüssel/-Werte mit dank/dms (`dankLauncherV2`, `alpeLockStyle: "dms"`, …) | umbenannt **mit Migration** in `SettingsData` (Versionssprung, alte Datei als `settings.v<N>.json`) |
| Texte «DMS», «Dux Modular Shell», «DankMaterialShell», Willkommens-/Changelog-Dialog | weg bzw. «Alpe»; `Brand.apply()`-Ersetzung entfällt; Über-Seite: «basiert ursprünglich auf der Dux Modular Shell (MIT)» |
| `Brand.heldPackages: ["dux-shell","dms","dms-cli"]` | entfällt (Alpe wird normal über die Paketverwaltung aktualisiert) |
| Prozessname über `~/.local/share/applications/dev.duxlabs.shell.desktop` | entfällt – das Paket liefert die eigene Desktop-Datei |

**Begründete Ausnahmen** (bleiben, werden in der Abnahme-Liste geführt):
- Go-Abhängigkeiten `github.com/duxlabs-dev/dux-go` und `dux-gop` (MIT, Avenge Media). Beide sind
  sauber parametrisiert (z. B. `shellapp.ID`), enthalten selbst keine sichtbaren Namen. Sie stehen
  in `go.mod`/`go.sum` und in Importzeilen. Alternative: Frage 9.
- Umzugscode und Tests dazu (`tools/umzug.py`, `tests/test_umzug.py`, Testdaten): müssen die
  alten Namen kennen.
- `NOTICE`, README-Abschnitt «Herkunft», `CHANGELOG.md`, `LICENSE`-Verweis.

### 2.3 D7: Umbenennung der internen Namen (0.8)

Ziel: Nach D7 trifft eine Suche nach `dms|dank|dux` (Gross/klein) in `shell/`, `core/`, `plugins/`
und `tools/` nur noch die Ausnahmen aus 2.2 und 2.3.3. Arbeitsweise wie in D1–D6: zuerst
gemessen (Stand `a48512d`), dann skriptbasiert, ein Commit pro Bereich, `bash tools/test.sh`
nach jedem Commit.

#### 2.3.1 Umfang (gemessen)

| Was | Menge |
|---|---|
| Dateien mit dms/dank im Namen (`shell/`, `core/`) | 105, davon **91 reine Weiterleitungen** (40 `Widgets/Dank*`, 33 `Modules/DankBar/Widgets/*`, 14 `Modules/DankDash/*`, 3 `Common/Dank*`, `Modals/Common/DankModal`) – die Shell selbst benutzt keine davon |
| echte Dateien | `DMSShell.qml`, `DMSShellIPC.qml`, `Services/DMSService.qml`, `Services/DMSNetworkService.qml`, `Services/CalendarDankBackend.qml`, `core/internal/dank16/`, `core/internal/config/dms.go`, matugen `dank.json`, `dank-zed.json`, `dank-emacs.el` |
| Bezeichner Oberfläche (QML/JS) | 311 verschiedene, ≈2000 Vorkommen (`DMSService` 472, `dmsBin` 73, `DMSNetworkService` 65, `DankBar` 35, `dankDashPopout` 32, `dankLauncherV2Modal` 31 …) |
| Bezeichner Dienst (Go) | 161 verschiedene, ≈1170 Vorkommen (`dmsDir`, `dmsPath`, `DMSStatus`, `dank16` …) |
| Gespeicherte Kennungen | Seiten-IDs `dankbar*`, `dank_dash` (z. B. in `settingsHiddenPages`), Starter-Plugins `dms_*`, Logo-Modus und Material-Vorlage `"dank"`, matugen-Spec `"dms"`, Kürzel-Quelle `"dms"`/`"dms-default"`, Regel-IDs `dms-floating-windows`/`dms-window-opaque`, Marke `-- DMS-RULE:` in `hypr/alpe/windowrules.lua` |
| Dateien bei Fremdprogrammen | Cache `dms-colors.json`, `dms-typography.json`; kitty `dank-theme.conf`/`dank-tabs.conf`; fcitx5-Thema `dms`; Lualine-Thema `dms` |
| IPC | Ziel `dankdash` (Doppel zu `dash`) |
| Plugin-Beschreibung | `requires_dms`, Fähigkeit `dankbar-widget` (alpeSport); `requires: ["dms"]` (calculator, nur Information) |

#### 2.3.2 Zuordnung (Vorschlag zur Freigabe)

Code-Bezeichner englisch (CLAUDE.md), sprechend nach Rolle statt nach Marke:

| Heute | Neu |
|---|---|
| `DMSService` | `ShellBackend` (Plan 2.2) |
| `DMSNetworkService` | `BackendNetworkService` |
| `DMSShell.qml`, `DMSShellIPC.qml` | `AlpeShell.qml`, `AlpeShellIPC.qml` |
| `Proc.dmsBin`, `dmsAvailable`, `checkDMSCapabilities` … | `backendBin`, `backendAvailable`, `checkBackendCapabilities` |
| `isDmsAction`, `dmsActions`, `DMS_ACTION_ARGS`, Aktionsart `"dms"` | `isShellAction`, `shellActions`, `SHELL_ACTION_ARGS`, `"shell"` |
| `DankBar…`, `dankBar…` (Rest-Bezeichner, Repeater, Tabs) | `Bar…`, `bar…` |
| `DankDash…`, `dankDashPopout(Loader)` | `Dash…`, `dashPopout(Loader)` |
| `DankIsland…`, `dankIsland…`, `DankDot` | `Island…`, `island…`, `Dot` |
| `dankLauncherV2Modal(Loader)` u. ä. | `launcherModal(Loader)` |
| `hyprDmsDir`, `dmsParsedArgs`, `dmsStatus` (QML wie Go/JSON) | `hyprAppDir`, `shellParsedArgs`, `includeStatus` |
| Go: `dmsDir`, `dmsPath`, `dmsState`, `DMSStatus`, `LoadDMSRules` … | `appDir`, `shellPath`, `appState`, `IncludeStatus`, `LoadShellRules` … |
| Go-Paket `internal/dank16`, Befehl `alpe-dienst dank16` | `internal/palette16`, Befehl `palette16` |
| Importname `danklog` (dux-go bleibt) | `duxlog` |
| Seiten-IDs `dankbar`, `dankbar_appearance`, `dankbar_dot`, `dankbar_settings`, `dankbar_widgets`, `dank_dash` | `bar`, `bar_appearance`, `bar_dot`, `bar_settings`, `bar_widgets`, `dash` (Kollisionsprüfung im Skript) |
| Starter-Plugins `dms_settings`, `dms_notepad`, … `dms_vpn` | `alpe_settings`, `alpe_notepad`, … |
| Logo-Modus `"dank"`, Material-Vorlage `"dank"` (Ebene `dankLogo`) | `"alpe"`; Form der Vorlage siehe Frage 2 zum Halt D6 |
| matugen-Spec `"dms"` (`SpecDMS`) | `"alpe"` |
| Kürzel-Quelle `"dms"`, `"dms-default"` | `"alpe"`, `"alpe-default"` |
| Regel-IDs `dms-floating-windows`, `dms-window-opaque`; Marke `-- DMS-RULE:` | `alpe-floating-windows`, `alpe-window-opaque`; `-- ALPE-RULE:` (die alte Marke wird gelesen, beim nächsten Schreiben ersetzt; sonst gingen bestehende Regeln verloren) |
| Cache `dms-colors.json`, `dms-typography.json` | `colors.json`, `typography.json` (im Ordner `~/.cache/alpe`, bauen sich neu) |
| matugen-Vorlagen `dank.json`, `dank-zed.json`, `dank-emacs.el`, kitty `dank-*.conf`, fcitx5/Lualine-Thema `dms` | `alpe*`; `include`-Zeilen und Themenwahl in den Fremdprogrammen schreibt der Umzug (F1) um |
| IPC-Ziel `dankdash` | entfällt (`dash` bleibt); Hyprland-Kürzel schreibt der Umzug um |
| `plugin.json`: `requires_dms`, Fähigkeit `dankbar-widget` | `requires_alpe` (gegen `Brand.version`), `bar-widget`; `requires_dms` wird nicht mehr gelesen |
| Plugin `dankNotepadModule` (Store-Plugin des Ursprungs, Sonderweg im Notizblock) | Anbindung entfällt (kein Store, 0.8 Nr. 1) |
| 91 Weiterleitungen, `Common/Deprecation.qml` | entfernt (D7.8) |

Gespeicherte Kennungen ziehen mit **Migration v44** um (`SettingsStore`, wie v43; Session-Daten
mit eigener Migration), `settings.v43.json` bleibt liegen. Das Skript liest die Tabelle aus
einer Datei, ersetzt nur ganze Bezeichner, bricht bei Kollisionen ab und gibt vor dem Schreiben
eine Liste aus.

#### 2.3.3 Was bleibt (Ausnahmeliste der Namensprüfung)

2.2 «Begründete Ausnahmen» (dux-go/dux-gop, Umzugscode und -tests, NOTICE, Herkunft, CHANGELOG,
LICENSE) und zusätzlich:
- `Brand.upstreamName`/`upstreamUrl`/`upstreamVersion` und die Herkunftszeile der Über-Seite;
- Migrationscode, der alte Namen lesen muss (`SettingsStore` v43/v44, alte Kopfzeile
  «DMS Include Configs», Marke `-- DMS-RULE:`), samt Tests;
- die fremde App «Dux Calendar» (`dev.duxlabs.calendar`, Socket `dankcal`); die Datei
  `CalendarDankBackend.qml` heisst künftig `CalendarDuxBackend.qml`;
- systemnahe Namen, solange Frage 6 zum Halt D6 offen ist (PAM `dankshell`, Hotspot-Verbindung,
  `/usr/share/dms`-Richtlinien, CUPS-Benutzer);
- Dateien fremder Plugins in ihrem Original (Lizenz-/Herkunftsvermerke).

`tools/namen-pruefen.sh` wird aus G1 nach D7 vorgezogen: ab D7.0 meldet es nur, ab D7.8 schlägt
es in `tools/test.sh` fehl, sobald etwas ausserhalb der Ausnahmeliste dazukommt.

#### 2.3.4 Plugins

Alpe-Plugins: keine `Dank*`-Typen, kein `requires_dms` (gemessen); alpeSport trägt die Fähigkeit
`dankbar-widget` → `bar-widget`. Alle drei bekommen `requires_alpe`.

Fremde Plugins (alle vier liegen inzwischen auch auf dem PC unter `~/.config/dms/plugins`):

| Plugin | Lizenz (Repo geprüft am 22.11.2026) | Was es vom Ursprung benutzt | Weg |
|---|---|---|---|
| calculator (rochacbruno/DankCalculator) | **AGPL-3.0** (Standardtext, kein eigener Copyright-Vermerk; Autor laut README Bruno Cesar Rocha) | `["dms","cl","copy"]`, `requires_dms` | Erlaubt Aufnahme; **Folge:** das Plugin bleibt AGPL in einem MIT-Repo, eigener Ordner mit LICENSE, Vermerk in NOTICE; Name «DankCalculator» im Repo-Pfad → neuer Ordnername `calculator` – Frage «Vor D7» Nr. 2 |
| hueManager (derethil/dms-hue-manager) | **keine Lizenz** (weder Datei noch Angabe; laut README nicht mehr gepflegt) | `DankIcon` (7), `DankSlider`, `DankListView`, `DankToggle`, `DankDropdown`, `DankButton` | nicht ins Repo → **Anleitung** für die lokalen Kopien |
| sathiAi (Shinda Singh) | README sagt «MIT» und verweist auf `LICENSE`, die Datei fehlt aber; Quell-Repo nicht auffindbar (Register des Ursprungs umgezogen) | `dms notify`, `dms ipc call settings …` (eigene `DankRectangle.qml`, kein Shell-Typ) | ohne belegte Lizenzdatei vorerst **Anleitung**; mit Repo-URL und LICENSE ins Repo – Frage «Vor D7» Nr. 3 |
| claudeCodeUsage (Nicolas Bellamy), in 0.8 nicht genannt | **MIT** (LICENSE mit Copyright) | `DankTextField`, `DankIcon`, `DankButton` | lädt nach D7.8 nicht mehr – Frage «Vor D7» Nr. 1 |

Anpassung (Repo oder Anleitung): `import qs.Widgets` → `qs.DCommon.Widgets`, `DankX` → `DX`
(`DankIcon` → `DIcon` …, Ziele aus den Weiterleitungen), `dms …` → `alpe-dienst …`,
`requires_dms` → `requires_alpe`, Ablage `~/.config/alpe/plugins`. Plugins im Repo behalten
ihre ID (damit `plugin_settings.json` passt) und werden wie `alpe*` ausgeliefert; der Umzug
kopiert ihre Nutzerkopien nicht (wie Plan 7.2 Schritt 4 für `alpe*`).

#### 2.3.5 Commits D7

| # | Bereich |
|---|---|
| D7.0 | Werkzeug: `entwicklung/umbenennen/` (Skript, Zuordnungstabelle, Probelauf, Kollisionsprüfung); `tools/namen-pruefen.sh` mit Ausnahmeliste, vorerst nur meldend |
| D7.1 | Plugin-Beschreibung: `requires_alpe`, `bar-widget`; `PluginService`, Einstellungsseiten, Alpe-Plugins; Test |
| D7.2 | Fremde Plugins: aufgenommene (nach Lizenz) unter `plugins/` angepasst, NOTICE; Anleitung für die übrigen in `docs/plugins-anpassen.md` |
| D7.3 | Schnittstelle Dienst ↔ Oberfläche: `DMSService`, `DMSNetworkService`, `dmsBin`, JSON-Felder und Gegenstücke im Go-Dienst |
| D7.4 | Oberfläche: Dateien `DMSShell*.qml`, Bezeichner `DankBar`/`DankDash`/`DankIsland`/`dankLauncherV2…`, Kürzel-Aktionen; `dankNotepadModule`-Anbindung weg |
| D7.5 | Gespeicherte Kennungen mit Migration v44 (Seiten-IDs, Starter-Plugins, Logo-Modus, Material-Vorlage, matugen-Spec, Kürzel-Quelle), IPC-Ziel `dankdash` weg; Test mit Einstellungen aus 1.0 und v43 |
| D7.6 | Erzeugte Dateien und Vorlagen für Fremdprogramme: Cache-Namen, matugen-Vorlagen, Regel-IDs, `-- ALPE-RULE:` |
| D7.7 | Dienst (Go) intern: Bezeichner, Paket `palette16`, Importname |
| D7.8 | Weiterleitungen und `Deprecation.qml` entfernt; Namensprüfung schlägt ab jetzt fehl |

Prüfung: je Commit `bash tools/test.sh`; Go-/Node-Tests wie bekannt; Ladeprüfung einmal auf
dem Endstand unter KWin und Hyprland (Grundlinien: Meldungen mit umbenannten Namen werden
nachgeführt, jede andere Abweichung einzeln erklärt). Halt nach D7 mit Mac-Test.

Folgen für F1 (Umzug), zusätzlich zu 7.2: kitty-`include`-Zeilen, fcitx5- und Lualine-Themenwahl,
Hyprland-Kürzel mit `dankdash`, Regel-IDs und `-- DMS-RULE:` in eigenen Hyprland-Dateien
(die Shell liest sie weiter, der Umzug darf sie umschreiben); Nutzerkopien der ins Repo
aufgenommenen Plugins nicht kopieren.

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
   verdecken). **Fremde Plugins und `.repos` bleiben unberührt** in `~/.config/dms/plugins`
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
   Eigene Programm-/Befehlskürzel (`net.local.*`) und Meta+Q/Meta+M sind nicht betroffen.
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
   Sicherung. kitty: `dank-theme.conf`/`dank-tabs.conf` → `alpe-*.conf`, `include`-Zeilen
   nachziehen. Erst jetzt, nach erfolgreichem Start und `alpe doctor` ohne Fehler:
   **`dux-shell` (und `dux-gop`) zum Entfernen anbieten** – `pacman -Rs --print dux-shell dux-gop`
   zeigen, dann `sudo pacman -Rns …`; Fedora: `dnf remove dms dms-cli dgop` zeigen. Hinweis auf
   die `IgnorePkg`-Zeile in `/etc/pacman.conf` (die fasse ich nicht an).
   `~/dux-shell` und `~/alpe` bleiben (PC: Entwicklung; Mac: Frage 12).
10. Marke `~/.config/alpe/umzug-1.1/fertig`.

**Rückweg** `alpe umzug --zurueck` (solange `dux-shell` noch installiert ist): `alpe.service`
aus, Sicherung zurückspielen, `dms.service` + Drop-ins an, Kürzel `dms-*` wieder setzen,
Hyprland-Zeilen zurück. Danach läuft 1.0 wie vorher.

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
- Kollision in `~/.config/alpe` → Alpe-Datei gewinnt, Protokolleintrag.

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
Meldungen die Commits dazwischen einzeln (0.7 Nr. 6).

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
| D7.0–D7.8 | Interne Namen, Plugin-Beschreibung, fremde Plugins, Weiterleitungen weg | **wieder aufgenommen** (0.8), Bereiche und Reihenfolge in 2.3.5; Halt nach D7 |
| E1 | Makefile, systemd-Unit, Desktop-Dateien | `make install DESTDIR` getestet in Temp-Wurzel |
| E2 | PKGBUILD | CI-Bau |
| E3 | RPM-Spec | CI-Bau x86_64 |
| E4 | Werkzeuge: `alpe` CLI, einrichten.sh, entwicklung, doctor/update/entfernen/backup, kde-sitzung, lockscreen, kuerzel, titelleisten, design.py | bestehende Tests nachgeführt |
| F1 | Umzug: `tools/umzug.py`, `install.sh`-Übergang, Testdaten, Test | |
| F2 | get.sh neu | Probelauf `--check` in Temp-`HOME` mit Attrappen |
| G1 | Doku, Brand 1.1, CHANGELOG, Namensprüfung + Ausnahmeliste | |

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
