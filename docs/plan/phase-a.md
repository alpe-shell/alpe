# Phase A – Harte Abspaltung von DMS (Ziel: Alpe 1.1 «Zugerberg»)

## Ziel in einem Satz

Alpe wird ein eigenständiges Projekt: kein Patch-Stapel mehr auf der Dux Modular Shell (DMS),
kein Paket `dux-shell`, kein `dms.service`, kein «Dux»/«DMS»/«Dank» in Oberfläche, Pfaden,
Diensten und Befehlen – die Shell bleibt technisch QML/Quickshell mit dem Go-Hintergrunddienst.
Rust kommt erst in Phase B. **In Phase A wird nichts neu geschrieben, nur einverleibt, umbenannt,
entschlackt und eigenständig paketiert.**

## Ausgangslage (Stand 1.0, Mitte November 2026)

### Verzeichnisse auf diesem PC

| Pfad | Inhalt |
|---|---|
| `~/alpe` | Repository Alpe (ein Commit «Alpe 1.0 «Zugerberg»», Tag `v1.0`). `git remote -v` zeigt das GitHub-Repo. |
| `~/dux-shell` | Arbeitsbaum der Shell: Git-Klon von DMS mit Branch `alpe` = Tag aus `~/alpe/BASE` (v2.1.2) + die zwei Patches. Enthält `quickshell/` (QML) und `core/` (Go-Dienst). |
| `~/.local/lib/alpe/alpe` | selbst gebauter Go-Dienst (aus `~/dux-shell/core`, `tools/backend.sh`) |
| `~/.local/bin/alpe` | Link auf `~/alpe/tools/alpe` (CLI) |
| `~/.config/dms/` | `settings.json`, `plugin_settings.json`, `plugins/alpe*` (kopierte Alpe-Plugins) |
| `~/.local/state/dms/session.json` | Hintergrund, Hell/Dunkel, angeheftete Programme |
| `~/.config/alpe/` | Alpe-eigenes: `design-sicherung/`, `pakete`, ggf. `hyprlock.conf` |
| `~/.config/systemd/user/dms.service.d/` | Drop-ins von Alpe: `alpe.conf` (ExecStart → `/usr/bin/dms -c ~/dux-shell/quickshell run`), `zz-alpe-name.conf`, `zz-alpe-backend.conf` |
| `~/.local/share/plasma/shells/org.alpe.desktop` | Sperrbildschirm-Paket für kscreenlocker (QML) |

### Wie 1.0 gebaut und gestartet wird

- `install.sh` baut in einem Worktree aus `BASE` per `git am shell/*.patch` den Baum und setzt
  `~/dux-shell` (Branch `alpe`) darauf, wenn er abweicht. Schichten:
  `shell/0000-KWin-Unterst-tzung-Patch-v4.patch`, `shell/0001-Alpe-1.0-Zugerberg.patch` (≈1 MB).
- `bootstrap.sh` lenkt `dms.service` (aus dem Arch-Paket `dux-shell`) per Drop-in auf den
  Alpe-Code um, richtet unter Hyprland die Umgebung ein und baut bei Bedarf den eigenen Go-Dienst.
- `get.sh` (Einzeiler `curl … | bash`) installiert Pakete (Arch: `dux-shell`, matugen,
  qt6-multimedia, wtype, kitty, fastfetch, KWin-Effekte aus dem AUR; Fedora: DMS-Installer),
  ruft `bootstrap.sh`, unter KDE `tools/kde-sitzung.sh ein` (maskiert `plasma-plasmashell.service`,
  schaltet `dms.service` ein) und `tools/design.py apply`.
- KWin-Anbindung: KWin-Skript `quickshell/Services/kwin/dms-bridge.js`, Rückkanal per D-Bus,
  gelesen mit `busctl monitor` (`Services/KwinService.qml`), Hilfsprogramm
  `quickshell/scripts/alpe-kwin.py` (Regeln, Effekte, kglobalaccel; KWin-6.8-Format mit `Order`).
- Werkzeuge in `tools/`: `alpe` (CLI), `design.py`, `kde-sitzung.sh`, `lockscreen.sh`,
  `kuerzel.py`, `entfernen.sh`, `titelleisten.py`, `kopfleiste.py`, `fastfetch.py`, `backend.sh`,
  `test.sh`. Plugins in `plugins/` (u. a. `alpeSport`, Wetter/Radar). Tests in `tests/`,
  Harnesse in `entwicklung/`. CI in `.github/workflows/`.
- `KONTEXT.md` (lokal) enthält weitere Hintergründe – zuerst lesen.

## Umfang

### 1. Quellcode einverleiben

- DMS v2.1.2 plus beide Patches wird zum eigenen Quellbaum im Repo `~/alpe` (z. B. `shell/` für
  QML und `core/` für Go – Aufteilung vorschlagen). Danach gibt es keine Patch-Schichten, kein
  `BASE`, keinen Rebuild-Mechanismus in `install.sh` und keinen separaten Baum `~/dux-shell` mehr.
- Herkunft dokumentieren: `NOTICE` (oder Abschnitt in `LICENSE`) mit Projekt, Version, Lizenz und
  Copyright der DMS-Autoren. Vorher die Lizenz von DMS **und** aller mitgebrachten Teile
  (Schriften, Icons, Bibliotheken unter `quickshell/`, `core/`) prüfen und auflisten.
- Die Git-Geschichte von DMS wird nicht übernommen; im Alpe-Repo genügt ein Commit
  «DMS 2.1.2 einverleibt» als Ausgangspunkt, danach die Umbauten als einzelne Commits.

### 2. Umbenennen

| Heute | Neu (Vorschlag – in deinem Plan bestätigen oder begründet ändern) |
|---|---|
| `dms.service` | `alpe.service` (user unit, im eigenen Paket) |
| `/usr/bin/dms`, `dms ipc …` | Dienst-Binary z. B. `alpe-dienst`; IPC über `alpe ipc …` |
| `~/.config/dms/` | `~/.config/alpe/` (Konflikte mit dem bestehenden Inhalt dort sauber lösen) |
| `~/.local/state/dms/`, `~/.cache/dms/` | `~/.local/state/alpe/`, `~/.cache/alpe/` |
| D-Bus-Namen, IPC-Ziele, Prozessname, Desktop-Datei `dev.duxlabs.shell.desktop` | alles auf `alpe` bzw. eine eigene Reverse-Domain (Vorschlag machen) |
| KWin-Skript `dms-bridge.js`, Aktionen `dms-*` in kglobalaccel | `alpe-*`; vorhandene Kürzel beim Umzug übernehmen |
| Sichtbare Texte «DMS», «Dux», «Dank», Willkommens-/Changelog-Dialog von DMS | entfernen bzw. Alpe |

**Achtung Namenskonflikt:** `alpe` ist schon die CLI (`~/.local/bin/alpe`). Das Dienst-Binary darf
nicht ebenfalls `alpe` heissen, oder CLI und Dienst werden bewusst zu einem Programm
zusammengeführt – entscheiden und begründen.

### 3. Entschlacken

- Code für nicht unterstützte Compositors entfernen (niri, sway, mango, labwc, river, Miracle …),
  ebenso die dazugehörigen Einstellungsseiten, Installer-Pfade und Tests.
- Was danach ungenutzt ist (Module, Übersetzungen, Assets), entfernen. Vorher eine Liste der
  Kandidaten vorlegen; Grenzfälle den Maintainer fragen.
- `CompositorService` & Co. auf genau zwei Wege reduzieren: Hyprland und KWin.

### 4. Eigene Pakete und Installation

- **Arch/CachyOS:** `PKGBUILD` für `alpe-shell` (AUR-tauglich, x86_64 und aarch64), Abhängigkeiten
  sauber (quickshell, qt6-*, matugen, …), Konflikt/Ersatz für `dux-shell`.
- **Fedora/Asahi:** RPM-Spec für COPR (aarch64 und x86_64). Prüfen, woher Quickshell und
  matugen unter Fedora kommen, und dokumentieren.
- `get.sh` installiert das Alpe-Paket statt DMS; kein Aufruf des DMS-Installers mehr.
  Fallback ohne Paket (aus dem Repo bauen) für Entwicklung beibehalten.
- `bootstrap.sh`/`install.sh` werden entsprechend einfacher; `tools/backend.sh` entfällt oder
  baut nur noch für Entwicklung.
- `alpe doctor`, `alpe update`, `alpe entfernen` (inkl. `--alles`) an die neuen Namen anpassen.

### 5. Umzug bestehender Installationen

PC und Mac des Maintainers laufen mit 1.0. Ein Update auf 1.1 muss automatisch und umkehrbar umziehen:
- Einstellungen, Session, Plugin-Einstellungen von `dms` nach `alpe` übernehmen (Sicherung behalten).
- `dms.service` und seine Drop-ins abschalten/entfernen, `alpe.service` einschalten;
  unter KDE bleibt `plasma-plasmashell.service` maskiert.
- kglobalaccel-Kürzel (`dms-*` → `alpe-*`), KWin-Regeln, Sperrbildschirm-Paket,
  Hyprland-Konfiguration (`exec-once`, `source`-Zeilen) mitnehmen.
- Paket `dux-shell` am Ende zum Entfernen anbieten (mit `--print` zuerst).
- Ein Test, der den Umzug in einem Temp-`$HOME` mit einer echten 1.0-Struktur prüft
  (Vorlage: echte Dateien lesend kopieren und anonymisieren).

### 6. Doku und Version

- `README.md`, `docs/technik.md`, `design/README.md`, `CHANGELOG.md` (Eintrag 1.1),
  `Brand.qml` (`version: "1.1"`). DMS als Herkunft im README nennen («basiert ursprünglich auf …»).
- Aus 1.0 bekannte Baustelle: Der CI-Lauf auf GitHub zum Commit von 1.0 war rot – zuerst
  Ursache finden (`gh run list`, `gh run view --log-failed`), Korrektur gehört in Phase A.

## Abnahmekriterien

1. `grep -ri` nach `dms`, `dux`, `dank` im Repo trifft nur noch Herkunftshinweise (NOTICE,
   README-Abschnitt, CHANGELOG) – Liste der verbleibenden Treffer mit Begründung.
2. `bash tools/test.sh` grün, CI auf dem Branch grün (der Maintainer pusht den Branch dafür).
3. Frische VM CachyOS/KDE: `get.sh` → nach Ab-/Anmelden genau das ausgelieferte Design, eine einzige
   Sperre beim Start, Meta+Q/Meta+M, Unschärfe und Ecken, kitty/fastfetch – ohne DMS-Paket.
4. Fedora Asahi (Mac): Update von 1.0 auf 1.1 per `alpe update` ohne Handarbeit.
5. PC: Update von 1.0 auf 1.1 ohne Verlust von Einstellungen, Regeln, Kürzeln.
6. `alpe entfernen --alles` hinterlässt in der VM keinen Alpe-Rest.
7. Speicher und Startzeit nicht schlechter als 1.0 (vorher und nachher mit `alpe doctor` messen).

## Vorgehen

1. `CLAUDE.md` und `KONTEXT.md` lesen, beide Bäume (`~/alpe`, `~/dux-shell`) erkunden.
2. Plan schreiben: `docs/plan/phase-a-plan.md` mit Zielstruktur des Repos, Namensentscheiden,
   Liste der zu entfernenden Teile, Paketierung, Umzugslogik, Reihenfolge der Commits, Risiken
   und offenen Fragen. **Dann anhalten und auf die Freigabe des Maintainers warten.**
3. Nach Freigabe auf Branch `phase-a` in kleinen Schritten umsetzen; nach jedem Schritt Tests.
4. Am Ende: Zusammenfassung, Anleitung für die Tests des Maintainers (VM, PC, Mac) als fish-taugliche
   Befehle, verbleibende Punkte. Nicht pushen.
