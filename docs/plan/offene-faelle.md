# Phase A – offene Fälle

Stand: 21. November 2026, nach C5 und Mac-Test. Ergänzt mit den Entscheiden 0.5/0.6 und den Befunden aus C4/C5. Ergänzt `docs/plan/phase-a-plan.md`
(Abschnitt «Stand»). Erledigte Fälle werden gestrichen, nicht gelöscht.

## Entscheide des Maintainers

~~Die Punkte 1–4 (distros, VERSION/CODENAME, Bildschirmfreigabe-Symbol, abgeschaltete
Zweige) stehen mit Vorschlägen im Plan unter «Stand → Entscheide nach C3». Noch offen.~~
Entschieden am 21.11.2026, siehe Plan 0.5.

## Bildschirmfreigabe-Symbol (nach 1.1)

Das Symbol im Kontrollzentrum und auf dem Sperrbildschirm zeigte nur unter niri etwas und ist
seit C2 immer aus. Bleibt in Phase A unverändert (Plan 0.5 Nr. 3). Vorschlag für nach 1.1: an
`PrivacyService.screensharingActive` hängen.

## Mac-Test

**Stand nach C5 (`2271063`) getestet am 21.11.2026** (Plan 0.6): Hyprland 0.57.2, Fedora Asahi
45, Quickshell 0.3.2 (COPR `avengemedia/quickshell`); Shell startet, Plugins geladen, keine
QML-Fehler; `doctor` erkennt Hyprland. Befunde 1–4 siehe Plan 0.6 und die Fälle unten.

Anleitung für den nächsten Stand (nach D3). Die Ladeprüfung braucht `kwin_wayland --virtual`
und wird am Mac übersprungen; getestet wird in der echten Hyprland-Sitzung, `~/alpe` bleibt
unberührt. **Ab D2 schreibt die Testshell nach `~/.config/alpe`, `~/.local/state/alpe`,
`~/.cache/alpe` und `~/.config/hypr/alpe/`** (Plan 7.4); vorher entstehende Dateien in
`~/.config/hypr/dms/` (z. B. `layout.lua`) schreibt die Shell beim Start selbst.

Am PC (Maintainer):

```
git -C ~/alpe-phase-a push origin phase-a
```

Am Mac – sichern (Hypr-Ordner mit, weil die Shell darin schreibt):

```
cp -r ~/.config/dms ~/.config/dms.vor-phase-a
cp -r ~/.config/hypr ~/.config/hypr.vor-phase-a
cp -r ~/.config/alpe ~/.config/alpe.vor-phase-a
cp -r ~/.local/state/alpe ~/.local/state/alpe.vor-phase-a
git -C ~/alpe fetch origin phase-a
git -C ~/alpe-phase-a checkout --detach origin/phase-a
bash ~/alpe-phase-a/tools/test.sh
cd ~/alpe-phase-a/core
make dev BUILD_DIR=/tmp/alpe-d3
/tmp/alpe-d3/alpe-dienst doctor
```

(Beim ersten Mal statt `checkout` noch `git -C ~/alpe worktree add ~/alpe-phase-a origin/phase-a`.)
Ab D1 heisst das Programm `alpe-dienst`. Bei `doctor` muss unter «Compositor» Hyprland stehen.

Laufende Shell stoppen:

```
systemctl --user stop dms.service
```

Ab D2 sucht die Shell ihre Einstellungen in `~/.config/alpe` (Umzug erst in F1). Damit der Test
nicht mit Werkseinstellungen läuft, die DMS-Dateien wie Umzug-Schritt 4 dazukopieren (`-n`:
nichts überschreiben; Sicherungen von oben):

```
cp -rn ~/.config/dms/. ~/.config/alpe/
mkdir -p ~/.local/state/alpe
cp -rn ~/.local/state/dms/. ~/.local/state/alpe/
```

Testshell starten:

```
/tmp/alpe-d3/alpe-dienst -c ~/alpe-phase-a/shell run 2>&1 | tee /tmp/alpe-d3.log
```

Durchklicken wie beim letzten Mal (Arbeitsflächen, Launcher-Rechtsklick, Dock, Launcher,
Kontrollzentrum, Tastaturlayout, Einstellungen → Tastenkürzel, Fensterregeln, Anzeige, Maus &
Touchpad, Compositor-Layout, Über-Seite; Energiemenü nur öffnen; im zweiten Terminal
`/tmp/alpe-d3/alpe-dienst screenshot window`). Zusätzlich: Starter-Einträge aus «Zuletzt»
(App-ID), Mitteilung senden (`notify-send test`).

Beenden mit Strg+C, dann `systemctl --user start dms.service`. Auswerten:

```
grep -E "ReferenceError|TypeError|is not a type|is not defined|Cannot assign|Unable to assign|not installed" /tmp/alpe-d3.log
ls ~/.config/hypr/alpe
```

Danach den Stand vor dem Test zurückholen. Wichtig für den späteren Umzug: Ein
`~/.config/alpe/settings.json` aus dem Test würde das Sicherheitsnetz von `alpe start`
(Plan 6.6) abschalten.

```
rm -rf ~/.config/alpe ~/.local/state/alpe ~/.config/hypr/alpe
mv ~/.config/alpe.vor-phase-a ~/.config/alpe
mv ~/.local/state/alpe.vor-phase-a ~/.local/state/alpe
```

(Gab es `~/.local/state/alpe` vor dem Test nicht, meldet das erste `cp` bzw. das letzte `mv`
nur «nicht gefunden».)

## Nach C4: Liste für D

- **Hinweise auf entfernte Befehle** (sichtbare Texte, D6): Die Oberfläche empfiehlt weiterhin
  `dms setup`, wenn `hyprland.lua` fehlt (`KeybindsTab.qml`, `Widgets/ConfigInclude.qml`,
  `Widgets/IncludeSetupBanner.qml`, `KeybindsService.qml`), ebenso der Dienst
  (`keybinds/providers/hyprland.go`, `windowrules/providers/hyprland_parser.go`,
  `server/evdev/manager.go`). Aufgerufen wird `setup` nirgends, darum ist es nach Plan 0.5
  Nr. 1 weg. Die Texte sollen auf den Reparatur-Knopf der Oberfläche bzw. den künftigen
  `alpe`-Befehl zeigen.
- **Deployer in `core/internal/config`** (`deployer.go`, `session_units.go`, eingebettete
  `hypr-*.lua`, Terminal-Vorlagen): hat seit dem Wegfall von `dms setup` keinen Aufrufer mehr,
  ist aber die einzige Stelle, die auf einem frischen Hyprland-System `hypr/dms/*.lua` anlegt
  (Plan 7.4). Bleibt vorerst stehen; in E4/F2 entscheiden, ob `alpe` bzw. `get.sh` ihn für eine
  frische Mac-Installation nutzt oder ob er wegkommt.
- `core/internal/log/filelogger.go` schreibt noch `duxinstall-*.log` (`DUXINSTALL_LOG_DIR`),
  vermutlich tot seit C1; prüfen und entfernen.
- Theme-Kategorie «registry»: Die Auswahl ist weg, `Theme.qml` kennt die Kategorie aber noch
  (wer ein Register-Theme aktiv hatte, behält es als eigene Datei). Mit D6/D7 bereinigen.

## Hyprland: `hyprctl descriptions` (nach Phase A)

Unter Hyprland 0.57.2 meldet `HyprlandService.qml:257` `hyprctl descriptions parse failed:
SyntaxError: JSON.parse`. Gibt es schon in 1.0 (Journal vom 20.11.2026, vor Phase A), also
nicht durch Phase A verursacht. Folge: `hyprOptionNames` bleibt leer; die Layout-/Eingabe-
Erzeugung läuft trotzdem weiter. Vermutung: Hyprland 0.57 liefert für `hyprctl -j descriptions`
kein gültiges JSON (oder Text vor dem JSON). Nicht in Phase A beheben (Plan 0.6 Nr. 3).

## Plugin-Kompatibilität (Entscheid vor D7)

Fremde Plugins: am Mac hueManager, calculator; am PC sathiAi, claudeCodeUsage (am PC am
21.11. dazugekommen). Was sie vom Ursprung benutzen (am PC gelesen):

| Schnittstelle | Beispiel | betrifft | Was Phase A daran ändert |
|---|---|---|---|
| Module `qs.Common`, `qs.Services`, `qs.Widgets`, `qs.Modules.Plugins`, `qs.DCommon.Widgets`, `qs.Modals.Common` | `import qs.Common` | alle | nichts (neutral) |
| Basistypen `PluginComponent`, `PluginSettings`, `PopoutComponent` | | alle | nichts (neutral) |
| Singletons `Theme`, `PluginService`, `ToastService`, `SessionData` | `Theme.primary` | alle | nichts – D7 benennt nur `DMS*`/`Dank*`-Namen |
| **`Dank*`-Widgets** (`DankIcon`, `DankButton`, `DankTextField` …) aus `qs.Widgets` | `DankIcon { name: "close" }` | claudeCodeUsage; laut Maintainer auch hueManager, calculator | 40 Dateien `shell/Widgets/Dank*.qml`. Schon im Ursprung **reine Weiterleitungen** auf `DCommon.D*` mit Veraltet-Meldung (`Deprecation.type`); die Shell selbst benutzt sie nicht mehr |
| Programm `dms` | `dms ipc call …`, `dms notify` | sathiAi | heisst ab D1 `alpe-dienst` |
| `plugin.json` `requires_dms` | | Register-Plugins | wird geprüft gegen `Brand.upstreamVersion` |
| Plugin-Ordner `~/.config/dms/plugins` | | alle | ab D2 `~/.config/alpe/plugins`; fremde Plugins zieht der Umzug nicht mit (0.4) |

(`DankRectangle` in sathiAi ist eine eigene Datei des Plugins, kein Shell-Typ.)

**Vorschlag:** Kompatibilität gezielt behalten, wo sie nichts kostet, sonst bewusst brechen.

1. **`Dank*`-Widgets behalten** (40 kleine Weiterleitungen, kein eigener Code). Sie stehen als
   «Plugin-Schnittstelle» auf der Ausnahmeliste der Namensprüfung; D7 fasst sie nicht an.
   Ohne sie laden claudeCodeUsage, hueManager und calculator nicht mehr («DankIcon is not a
   type»). Entfernen erst, wenn Alpe eine eigene Plugin-Schnittstelle beschreibt (Phase B).
2. **`requires_dms` weiter lesen**, zusätzlich `requires_alpe` (gegen `Brand.version`) für
   eigene Plugins. Kostet ein paar Zeilen in `PluginService`.
3. **Programm `dms` bewusst brechen.** Ein `/usr/bin/dms` im Paket würde mit `dux-shell`
   kollidieren, das beim Umzug als Rückweg installiert bleibt (Plan 6.2). Folge: In sathiAi
   scheitern «Einstellungen öffnen» (`dms ipc call settings …`) und die Systemmitteilung
   (`dms notify`, das Plugin hat einen Ersatzweg über `ToastService`). `alpe doctor` nennt
   fremde Plugins, die `"dms"` aufrufen. (Alternative ohne Kollision: Weiterleitung
   `/usr/share/alpe/compat/bin/dms` und dieser Ordner vorne im `PATH` von `alpe.service` –
   nicht empfohlen, verdeckt ein echtes `dms` und ist schwer zu erklären.)
4. **Plugin-Ordner:** wie entschieden; fremde Plugins holt man selbst nach
   `~/.config/alpe/plugins`, `alpe doctor` sagt welche.

Bewusst brechen in allen Punkten hiesse: 40 Dateien weniger und eine saubere Namensprüfung,
aber jedes fremde Plugin mit `Dank*`-Widgets lädt nicht mehr – bei den vier bekannten wären es
mindestens drei.

## Bekannte Fehlschläge (schon vor C1, unverändert)

- Go: `internal/matugen` `TestTerminalPaletteOnlyReachesTerminalTemplates`;
  `internal/qmlchecks` `TestLockScreenPasswordFieldBypassesTextInputIME`,
  `TestLockScreenFprintProfileMatchesPamQml`.
- Node (`shell/tests`, nicht in `tools/test.sh`): 10 Fälle, u. a. Hyprland-Layout-Tests,
  Singleton-Zyklen mit `KwinService`, `shell-embed` (sucht `scripts/shell-test-excludes.txt`
  am Ursprungspfad), Systemaktualisierung (flatpak, portage).
- `go vet` meldet Signaturwarnungen in `internal/mocks` (vom Ursprung generiert).
- Referenzprüfung: `SettingsData.barPosition` (DLauncherV2ModalHost) und
  `SessionService.lock` (SwitchUserModal) sind nicht definiert.

Gehören in Abschnitt 9 (Node-Tests in `tools/test.sh` aufnehmen) bzw. in einen eigenen Commit.

## Ladeprüfung

Meldungen der Shell in den Grundlinien (`entwicklung/ladepruefung/grundlinie-*.txt`), die auf
echte Fehler im QML hindeuten (Umgebungsmeldungen wie fehlendes D-Bus, PipeWire, `dsearch`
oder noch nicht vorhandene Cache-Dateien sind nicht aufgeführt). Ursache je Fall noch offen:

- beide: `AlpeDeviceTab.qml: Unable to assign [undefined] to bool`,
  `DBarTab.qml: Unable to assign [undefined] to QString`.
- beide: `[Proc] runCommand callback error … TypeError: Cannot read property 'lid' of null`
  (Ladegrenze/Deckel-Abfrage; im Test fehlt logind, die Auswertung fängt das nicht ab).
- beide: `SportDaemon … Created graphical object was not placed in the graphics scene`.
- KWin: `Error: Cannot assign to non-existent property "requestedSearchQuery"` (ohne Datei).
- **KWin: leere Bildschirmliste** – `[WlrOutputService] Received empty outputs list`. Unter
  KWin kommen die Bildschirme über kscreen, nicht wlr-output-management; zu klären, ob die
  Anzeige-Seite unter KWin trotzdem Bildschirme zeigt oder ob nur die Meldung stört.
- Hyprland: `[KeybindsService] Failed to parse binds: SyntaxError: JSON.parse` und
  `Load process failed with code: 1` (Kürzel-Auslesen scheitert im Testprofil).
- Hyprland: `[CompositorService] failed to update DMS window rule dms-floating-windows …
  hyprland.lua not found …; run dms setup …`; verweist auf `dms setup` (Befehl fällt mit C4 weg).

- Sporadisch: `SettingsSearchRegistration.qml: TypeError: Cannot read property 'parent' of null`
  und `SettingsRow.qml: Cannot find member data`. Gesehen einmal unter Hyprland (vor C4) und
  einmal unter KWin während C4 (Plugin-Register-Commit); der Wiederholungslauf mit demselben Code
  war sauber. Nicht in die Grundlinie aufgenommen. Vermutete Ursache: Beim Abbau einer
  `SettingsRow` setzt Qt die `Item`-Eigenschaft `target` von `SettingsSearchRegistration` auf
  `null`, die Bindung `flickable: QmlUtils.findParentFlickable(target.parent)` wird danach noch
  einmal ausgewertet. Vorschlag (eigener Commit): `target?.parent`, `sync()` und
  `Component.onDestruction` gegen `target === null` absichern; prüfen, ob `unregisterCard`
  dann trotzdem greift.
- Die Ladeprüfung läuft nur, wo `kwin_wayland` installiert ist (auch für Hyprland).

## Aufräumen (Entscheid 4, C5)

- ~~`WindowRuleEditorDialog.qml`: `isNiri`/`niriConfigNext`/`isMango` konstant `false`,
  die zugehörigen Felder und Zweige entfernen.~~ Erledigt in C5 (`ae2a925`).
- ~~`KeybindEditorDialog.qml`: Zweige für Provider `"niri"` und `"mangowc"`.~~ Erledigt in C5
  (`8cb116f`). Übrig: `compositorFlagOptions()` kennt noch niri-Aktionsnamen
  (`move-column-to-workspace*`, `screenshot-window`); unter Hyprland/KWin nie erreicht, aber
  nur über die Aktionsdaten nachweisbar, darum nicht angefasst.
- ~~`WorkspaceSwitcher.qml`: Zieh-Pfad zum Umsortieren (`workspaceReorderSupported`),
  Übersichts-Pille (`workspacesHiddenByOverview`).~~ Erledigt in C5. Übrig:
  `CompositorService.toggleOverview` (leer, noch vom Dock-Launcher aufgerufen) und
  `workspaceSecondaryAction` (leer, noch von Arbeitsflächen-Umschalter, Modell und Insel
  aufgerufen) – nicht Teil von Entscheid 4.
- `DBarBody.fullscreenAutoHide` ist konstant `false`; die Kette über DBar und IPC kann weg.
- `KeybindsService._bindsStale` wird nie mehr gesetzt.
- Allgemein genutzte Helfer mit niri im Namen umbenennen (Phase D):
  `OutputModel.niriIdentifier`, `formatNiriMode`; Bedingungsschlüssel
  `isHyprlandOrNiri`/`isNiriOrMango`, Eintrag `hyprlandNiriOnly`.

## Werkzeuge

- `shell/translations/extract_settings_index.py` bricht ab, weil die Alpe-Seiten in
  `TAB_INDEX_MAP` fehlen; der Suchindex wurde in C2/C3 von Hand bereinigt (Einträge zu
  entfernten Einstellungen). Vor D6 nachrüsten.
- `entwicklung/lint.sh` zeigt auf alte Pfade (`/home/claude/...`, `quickshell/`); erneuern
  oder entfernen.
- `entwicklung/pageharness/qs/` enthält veraltete Kopien (`SettingsTabs.qml`,
  `CompositorService.qml`-Attrappe mit `isNiri`).
- Übersetzungen (`shell/translations/*.json`, `poexports`) enthalten noch Texte entfernter
  Seiten; bereinigen mit D6.
- Assets `discord.svg`, `reddit.svg`, `matrix-logo-white.svg` sind unbenutzt bzw. nur noch
  für den Discord-Link des Ursprungs da (Entfernen laut 4.3 in C4).
