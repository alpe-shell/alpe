# Phase A – offene Fälle

Stand: 21. November 2026, nach C3 (`2c92ce4`), ergänzt mit den Entscheiden 0.5. Ergänzt `docs/plan/phase-a-plan.md`
(Abschnitt «Stand»). Erledigte Fälle werden gestrichen, nicht gelöscht.

## Entscheide des Maintainers

~~Die Punkte 1–4 (distros, VERSION/CODENAME, Bildschirmfreigabe-Symbol, abgeschaltete
Zweige) stehen mit Vorschlägen im Plan unter «Stand → Entscheide nach C3». Noch offen.~~
Entschieden am 21.11.2026, siehe Plan 0.5.

## Bildschirmfreigabe-Symbol (nach 1.1)

Das Symbol im Kontrollzentrum und auf dem Sperrbildschirm zeigte nur unter niri etwas und ist
seit C2 immer aus. Bleibt in Phase A unverändert (Plan 0.5 Nr. 3). Vorschlag für nach 1.1: an
`PrivacyService.screensharingActive` hängen.

## Mac-Test (ausstehend)

Die Ladeprüfung braucht `kwin_wayland --virtual` und wird am Mac ohne KWin übersprungen;
getestet wird in der echten Hyprland-Sitzung, `~/alpe` bleibt unberührt.

Am PC (Maintainer):

```
git -C ~/alpe-phase-a push origin phase-a
```

Am Mac:

```
cp -r ~/.config/dms ~/.config/dms.vor-phase-a
git -C ~/alpe fetch origin phase-a
git -C ~/alpe worktree add ~/alpe-phase-a origin/phase-a
bash ~/alpe-phase-a/tools/test.sh
cd ~/alpe-phase-a/core
env CGO_ENABLED=0 go build -o /tmp/alpe-dienst-c3 ./cmd/dms
/tmp/alpe-dienst-c3 doctor
```

(`go` fehlt: `sudo dnf install golang`.) Bei `doctor` muss unter «Compositor» Hyprland
stehen.

Laufende Shell stoppen – zuerst `systemctl --user is-active dms.service`; bei `active`:

```
systemctl --user stop dms.service
```

sonst `dms kill`. Testshell starten:

```
/tmp/alpe-dienst-c3 -c ~/alpe-phase-a/shell run 2>&1 | tee /tmp/alpe-c3.log
```

Durchklicken: Arbeitsflächen wechseln (auch Mausrad), Rechtsklick aufs Launcher-Logo
(Hyprland-Übersicht), Dock, Launcher, Kontrollzentrum, Tastaturlayout; Einstellungen →
Tastenkürzel (bearbeiten, abbrechen), Fensterregeln (neue Regel, abbrechen), Anzeige,
Maus & Touchpad, Compositor-Layout, Über-Seite; Energiemenü nur öffnen; im zweiten
Terminal `/tmp/alpe-dienst-c3 screenshot window`.

Beenden mit Strg+C, dann `systemctl --user start dms.service` (oder neu anmelden).
Auswertung:

```
grep -E "ReferenceError|TypeError|is not a type|is not defined|Cannot assign|Unable to assign|not installed" /tmp/alpe-c3.log
```

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

- Einmal flüchtig unter Hyprland (Code identisch mit der Grundlinie), danach nicht wieder:
  `SettingsSearchRegistration.qml: TypeError: Cannot read property 'parent' of null` und
  `SettingsRow.qml: Cannot find member data`. Nicht in die Grundlinie aufgenommen;
  taucht es wieder auf, Ursache suchen statt aufnehmen.
- Die Ladeprüfung läuft nur, wo `kwin_wayland` installiert ist (auch für Hyprland).

## Aufräumen (nach Entscheid 4)

- `WindowRuleEditorDialog.qml`: `isNiri`/`niriConfigNext`/`isMango` konstant `false`,
  die zugehörigen Felder und Zweige entfernen.
- `KeybindEditorDialog.qml`: Zweige für Provider `"niri"` und `"mangowc"`.
- `WorkspaceSwitcher.qml`: Zieh-Pfad zum Umsortieren (`workspaceReorderSupported`),
  Übersichts-Pille (`workspacesHiddenByOverview`); `CompositorService.toggleOverview`
  und `workspaceSecondaryAction` sind leer.
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
