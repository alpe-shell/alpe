# Phase A – Plan zur Umsetzung (Alpe 1.1 «Zugerberg»)

Stand: 21. November 2026, Branch `phase-a`. **Freigegeben am 21.11.2026** mit den Entscheiden in 0.4. Grundlage: `docs/plan/phase-a.md`, `CLAUDE.md`,
`KONTEXT.md`, Erkundung von `~/alpe` (Commit c988364) und `~/dux-shell` (Branch `alpe` =
v2.1.2 + 2 Schichten). **Noch nichts umgesetzt.** Dieser Plan wartet auf Freigabe; die offenen
Fragen stehen gesammelt in Abschnitt 12.

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
| 5 | Greeter weg; Aktualisierung/Changelog/Willkommen des Ursprungs weg; Plugin- und Theme-Browser **inklusive `internal/registries` ganz entfernen** (eigener Commit, lokales Laden von Plugins bleibt); vsix weg; **Tailscale: noch offen** (Rückfrage vor C4) |
| 6 | D7 als letzte Etappe mit eigenem Halt, nur bei grüner Ladeprüfung der ganzen Shell; bei Problemen D7 verwerfen und interne Namen auf die Ausnahmeliste |
| 7 | Eigenes COPR `alpe-shell/alpe` mit selbst gebautem Quickshell (Vorlage: errornointernet), bei Bedarf matugen. Mac-Ausgaben inkl. `getconf PAGESIZE` folgen |
| 8 | Hyprland startet über `exec-once = alpe start` |
| 9 | dux-go/dux-gop bleiben, Ausnahme in der Namensprüfung |
| 10 | AUR-Veröffentlichung zum Release von 1.1 durch den Maintainer; bis dahin baut `get.sh` aus dem PKGBUILD im Repo |
| 11 | Alte Ordner bleiben bis `alpe umzug aufraeumen`; `alpe doctor` erinnert daran |
| 12 | `~/alpe` am Mac bleibt |
| 13 | Archiv aus c988364 bauen, `gh release upload`-Befehl dem Maintainer geben |
| 14 | **offen** (Bestätigung der Bilder) |
| 15 | Herkunftsvermerk in NOTICE genügt |
| 16 | **offen** – ohne eindeutigen MIT-Beleg Halt vor B2 |
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
- **Halte:** nach A1, nach B3 (Baumvergleich), nach C4, nach D6, nach E4, nach F2, dann D7
  separat, zuletzt G1 – jeweils mit Zusammenfassung und Diffstat.

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
4. `alpe einrichten`, unter KDE `alpe kde ein --jetzt`, unter Hyprland Startzeile (7.4).
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
  Entwicklungsmodus der Repo-Baum. Wird von `alpe.service` und von Hyprland (`exec-once`) benutzt.
- `alpe doctor` erinnert an `alpe umzug aufraeumen`, solange die alten DMS-Ordner liegen.

### 6.7 Sperrbildschirm: nutzerspezifische Dateien (wird vor E1 vorgelegt)

Heute kopiert `lockscreen.sh` das Design nach `~/.local/share/plasma/shells/org.alpe.desktop` und
schreibt dort das erzeugte `layout.js` und die Bilder hinein. Ein Paket unter
`/usr/share/plasma/shells/` ist schreibgeschützt. Entscheidungsvorlage (Varianten: Greeter liest
aus `~/.config/alpe`, oder bewusst erzeugte Nutzerkopie) mit Folgen für Umzug,
`design apply/export` und `alpe entfernen` folgt vor E1.

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
   `MALLOC_ARENA_MAX` steckt im Paket. `alpe.service` enable. Unter KDE bleibt
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

Heute (laut bootstrap.sh): `exec-once = dms run` in der eigenen Hyprland-Konfiguration,
`source = ~/.config/hypr/alpe.conf` (Datei mit `env = DMS_SHELL_DIR,…`) ganz oben, und – vom
DMS-Setup – Includes aus `~/.config/hypr/dms/*.lua` (binds, colors, layout, outputs, cursor,
windowrules, binds-user).
Umzug:
1. `hypr/alpe.conf` und ihre `source`-Zeile entfernen (die Umlenkung ist überflüssig; ausserdem
   ist `hypr/alpe` künftig ein Ordner).
2. `hypr/dms/` → `hypr/alpe/` (kopieren, alte bleibt bis zum Aufräumen), alle Verweise in
   `hyprland.conf`/`hyprland.lua` und Unterdateien umschreiben (Sicherung `*.vor-alpe-1.1`).
3. Startzeile `exec-once = dms run …` → `exec-once = alpe start` (gleiches Startmodell wie
   heute, Entscheid 8).
4. Wirksam nach Ab-/Anmelden; `--jetzt` startet die neue Shell sofort und beendet die alte.

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

---

## 10. Reihenfolge der Commits (Branch `phase-a`)

Jeder Commit: `bash tools/test.sh` grün (ab C3 zusätzlich Ladeprüfung, ab C8 Umzugstest).

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
| D1 | Go: Modulpfad, Binary `alpe-dienst`, Socket, Umgebungsvariablen | zentrale Konstanten in `core/internal/brand` |
| D2 | Go/QML: Pfade `~/.config|state|cache/alpe`, System-Plugins, hypr-Ordner | zentrale Stellen `Paths.qml`/`brand` statt verstreuter Literale |
| D3 | App-ID, Desktop-Dateien, D-Bus-Namen, Icon | |
| D4 | KWin-Brücke `alpe-bridge`, Aktionen `alpe-*` | Test test_bridge.js angepasst |
| D5 | Einstellungen: Schlüssel/Werte + Migration | Test mit alter settings.json |
| D6 | Sichtbare Texte, Über-Seite, Brand.apply weg, Übersetzungen | |
| D7 | Interne Bezeichner (DMSService, DankBar …) | skriptbasiert, ein Commit je Bereich (Tiefe: Frage 6) |
| E1 | Makefile, systemd-Unit, Desktop-Dateien | `make install DESTDIR` getestet in Temp-Wurzel |
| E2 | PKGBUILD | CI-Bau |
| E3 | RPM-Spec | CI-Bau x86_64 |
| E4 | Werkzeuge: `alpe` CLI, einrichten.sh, entwicklung, doctor/update/entfernen/backup, kde-sitzung, lockscreen, kuerzel, titelleisten, design.py | bestehende Tests nachgeführt |
| F1 | Umzug: `tools/umzug.py`, `install.sh`-Übergang, Testdaten, Test | |
| F2 | get.sh neu | Probelauf `--check` in Temp-`HOME` mit Attrappen |
| G1 | Doku, Brand 1.1, CHANGELOG, Namensprüfung + Ausnahmeliste | |

**Halte** (Zusammenfassung + Diffstat, dann Freigabe abwarten): nach A1, nach B3
(Baumvergleich), nach C4, nach D6, nach E4, nach F2, D7 separat, zuletzt G1. Vor B2 zusätzlich,
falls die Herkunft des KWin-Patches nicht als MIT belegt ist; vor C4 wegen Tailscale; vor E1 mit
der Vorlage 6.7.

Danach Zusammenfassung mit fish-tauglichen Testanleitungen (VM «frisch», PC-Umzug, Mac-Umzug,
Messung Speicher/Startzeit vorher/nachher mit `alpe doctor`). Kein Push, kein Tag.

Grössenordnung: B1 ≈ 2800 Dateien (inkl. Schriften, Übersetzungen), D7 berührt mehrere hundert
Dateien. Ich arbeite skriptbasiert (Umbenennungsskript liegt unter `entwicklung/`, damit es
nachvollziehbar ist) und prüfe nach jedem Schritt mit der Ladeprüfung.

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
   Empfehlung: ja, skriptbasiert in D7, weil es danach nie billiger wird.
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
   Empfehlung für 1.1: `exec-once`, keine zweite Baustelle.
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
