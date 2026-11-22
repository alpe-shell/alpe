# Phase A – offene Fälle

Stand: 22. November 2026, Halt nach D6; D7 freigegeben (Plan 0.8, 2.3); Halt nach D3 abgenommen (Plan 0.7). Ergänzt mit den Entscheiden 0.5/0.6 und den Befunden aus C4/C5. Ergänzt `docs/plan/phase-a-plan.md`
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

**Anleitung für den Stand nach D6** (Plan 0.7 Nr. 7). Die Ladeprüfung braucht
`kwin_wayland --virtual` und wird am Mac übersprungen; getestet wird in der echten
Hyprland-Sitzung, `~/alpe` bleibt unberührt. Die Testshell schreibt nach `~/.config/alpe`,
`~/.local/state/alpe`, `~/.cache/alpe` und `~/.config/hypr/alpe/` (Plan 7.4).

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
make dev BUILD_DIR=/tmp/alpe-d6
/tmp/alpe-d6/alpe-dienst doctor
```

(Gibt es den Worktree noch nicht: `git -C ~/alpe worktree add ~/alpe-phase-a origin/phase-a`.)
Bei `doctor` muss unter «Compositor» Hyprland stehen; Überschriften und Meldungen nennen
«Alpe» bzw. `alpe-dienst`, nicht mehr «DMS».

Laufende Shell stoppen:

```
systemctl --user stop dms.service
```

Die Shell sucht ihre Einstellungen in `~/.config/alpe` (Umzug erst in F1). Damit der Test nicht
mit Werkseinstellungen läuft, die DMS-Dateien wie Umzug-Schritt 4 dazukopieren (`-n`: nichts
überschreiben; Sicherungen von oben):

```
cp -rn ~/.config/dms/. ~/.config/alpe/
mkdir -p ~/.local/state/alpe
cp -rn ~/.local/state/dms/. ~/.local/state/alpe/
mkdir -p ~/.config/hypr/alpe
cp -rn ~/.config/hypr/dms/. ~/.config/hypr/alpe/
```

(Die Kopie nach `hypr/alpe/` zeigt der Kürzel- und der Fensterregel-Seite die bestehenden
Einträge; Hyprland selbst liest weiter `hypr/dms/`.)

Testshell starten:

```
/tmp/alpe-d6/alpe-dienst -c ~/alpe-phase-a/shell run 2>&1 | tee /tmp/alpe-d6.log
```

Die Seiten Tastenkürzel, Fensterregeln und Anzeige melden, dass ihre Dateien nicht eingebunden
sind: **die Knöpfe «Einrichten»/«Einbinden» nicht drücken** – sie würden `require("alpe.…")` in
die echte `hyprland.lua` schreiben. Die Hyprland-Kürzel der 1.0-Einrichtung (`dms ipc call …`)
erreichen die Testshell nicht (anderer Socket); Aufrufe stattdessen im zweiten Terminal, z. B.
`/tmp/alpe-d6/alpe-dienst ipc call spotlight toggle`. «Neu starten» im Energiemenü nicht
auslösen: Das ruft `alpe restart`, und das 1.0-`alpe` startet `dms.service`.

Durchklicken wie beim letzten Mal (Arbeitsflächen, Launcher-Rechtsklick, Dock, Launcher,
Kontrollzentrum, Tastaturlayout, Einstellungen → Tastenkürzel, Fensterregeln, Anzeige, Maus &
Touchpad, Compositor-Layout; Energiemenü nur öffnen; im zweiten Terminal
`/tmp/alpe-d6/alpe-dienst screenshot window`; Mitteilung `notify-send test`;
`/tmp/alpe-d6/alpe-dienst restart` lädt nur die Testshell neu und ändert nichts an
`dms.service`; `hyprctl clients | grep class` zeigt `io.github.alpe_shell.Alpe`).

Neu seit D3 – bitte gezielt ansehen:

- **Einstellungen (D5):** In einem zweiten Terminal
  `ls ~/.config/alpe/settings.v42.json` (Sicherung vor der Migration muss da sein),
  `grep -c dankLauncherV2 ~/.config/alpe/settings.json` (muss 0 sein),
  `grep configVersion ~/.config/alpe/settings.json` (43). Starter: Grösse, Rahmen und Fusszeile
  wie vorher (die Werte sind umgezogen).
- **Fensterregeln (Fehler aus D2, `0515150`):** Eigene Regeln aus `hypr/alpe/windowrules.lua`
  stehen oben als bearbeitbare Regeln, nicht unter den fremden (nur lesbar).
- **Tastenkürzel:** Kategorie heisst «Alpe» statt «DMS» (Einstellungen und Kürzelübersicht).
- **Über-Seite:** eigene Beschreibung, «Herkunft: Basiert ursprünglich auf der Dux Modular
  Shell 2.1.2 (MIT-Lizenz)» mit Verweis; Lizenz-Verweis führt zu Alpe.
- **Sperrbildschirm / Effekte:** Sperr-Auswahl zeigt den bisherigen Stil; Unschärfe-Modus
  «Standard (Interface-Stil)».
- **Mitteilungen:** Bildschirmfoto-Mitteilung mit Absender «Alpe»; Einstellungen →
  Mitteilungen → Position testen zeigt drei deutsche Testmitteilungen.
- **Hilfe:** `/tmp/alpe-d6/alpe-dienst --help` und `/tmp/alpe-d6/alpe-dienst ipc` nennen
  `alpe-dienst`.

Beenden mit Strg+C, dann `systemctl --user start dms.service`. Auswerten:

```
grep -E "ReferenceError|TypeError|is not a type|is not defined|Cannot assign|Unable to assign|not installed" /tmp/alpe-d6.log
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

**Anleitung für den Stand nach D7 (Halt nach D7.8, 22.11.2026).** Ablauf wie oben für D6, mit
`/tmp/alpe-d7` statt `/tmp/alpe-d6` und diesen Änderungen. Seit D7.8 gibt es keine Hüllen mehr:
Ein fremdes Plugin lädt nur noch in der angepassten Fassung.

*Schritt 0, einmalig und bleibend – vor dem Sichern:* die angepassten Fassungen von hueManager
und calculator unter `~/.config/alpe/plugins` anlegen, genau nach `docs/plugins-anpassen.md`,
Abschnitt «Mac» (je `cp -r` aus `~/.config/dms/plugins`, dann die `sed`-Zeilen). Die Kopien unter
`~/.config/dms/plugins` bleiben unverändert, 1.0 läuft damit weiter. Weil das vor dem Sichern
geschieht, liegen die angepassten Fassungen auch in `~/.config/alpe.vor-phase-a` und überstehen
das Zurückholen am Ende. Prüfen (beide Befehle geben nichts aus):

```
grep -rn -E --include='*.qml' --include='plugin.json' '\bDank[A-Z]|qs\.DCommon|\["dms"|requires_dms' ~/.config/alpe/plugins/hueManager ~/.config/alpe/plugins/calculator
git -C ~/.config/dms/plugins/hueManager status --short
```

Danach sichern, bauen und die DMS-Dateien dazukopieren wie oben (`cp -rn` überschreibt die
angepassten Fassungen nicht), dann die alten Kopien von alpeSport und alpeRadar zur Seite legen
(Zusatz unten). Bauen und starten:

```
cd ~/alpe-phase-a/core
make dev BUILD_DIR=/tmp/alpe-d7
/tmp/alpe-d7/alpe-dienst --help
/tmp/alpe-d7/alpe-dienst dl --help
systemctl --user stop dms.service
/tmp/alpe-d7/alpe-dienst -c ~/alpe-phase-a/shell run 2>&1 | tee /tmp/alpe-d7.log
```

`--help` zeigt oben den Schriftzug «ALPE» (nicht mehr «DMS»), `dl --help` bei `--user-agent`
den Vorgabewert `Alpe/1.0.0 (+https://github.com/alpe-shell/alpe)`.

Neu seit D6 – bitte gezielt ansehen:

- **Fremde Plugins:** Einstellungen → Plugins: hueManager und calculator sind geladen (kein
  Fehlerhinweis beim Plugin). Rechner im Starter ausprobieren, Ergebnis kopieren (ruft
  `alpe-dienst cl copy`); Hue-Widget öffnen.
- **Alpe-Zeichen im Starter-Knopf:** Einstellungen → Leisten-Widgets → Starter-Knopf, Auswahl
  «Symbol» (im Code `launcherLogoMode`, Werte Apps, OS-Logo, Alpe, Compositor, Eigenes): «Alpe»
  wählen. In der Leiste steht dann das Alpe-Zeichen, nicht das Zeichen des Ursprungs und kein
  leerer Platz. War unter 1.0 das Logo des Ursprungs gewählt, ist nach dem Start schon «Alpe»
  gewählt (Migration v44).
- **Alpe-Zeichen als Material-Hintergrund:** Einstellungen → Hintergrund, Zeile «Material»
  (erscheint, wenn als Hintergrund das Material-Bild gewählt ist): Vorlage «Alpe». Auf dem
  Schreibtisch erscheint das Alpe-Zeichen als grosse Form (`alpeLogo`). Danach den bisherigen
  Hintergrund wieder wählen. So sah es in der Ladeprüfung am PC aus: siehe «Halt nach D7» im
  Plan, Abschnitt «Stand».
- **Punkt-Symbol:** Einstellungen → Seite «Punkt» (Leisten-Layout): Die Auswahl «Symbol» nennt
  den dritten Eintrag «Alpe» (bis D7.8a stand dort «Dux»).
- **Einstellungen und Session umgezogen** (zweites Terminal): `grep configVersion
  ~/.config/alpe/settings.json` zeigt 44; `grep -c -E 'dankLauncherV2|"dms_|dankLogo'
  ~/.config/alpe/settings.json ~/.local/state/alpe/session.json` zeigt zweimal 0;
  `ls ~/.local/state/alpe/session.v7.json` (Sicherung der Session vor dem Umzug auf Version 8).
- **Notizblock:** eine gespeicherte Notiz öffnen, neben dem Dateinamen den Knopf «Pfad kopieren»
  drücken und in einem Terminal einfügen – der Pfad der Datei muss kommen (der Knopf rief bis
  D7.8a noch `dms clipboard copy` und tat unter 1.1 nichts).
- **Bildschirmfoto und Pipette ohne Animation:** `/tmp/alpe-d7/alpe-dienst screenshot region`
  starten und während der Auswahl im zweiten Terminal `hyprctl layers | grep alpe:` – die Fläche
  heisst `alpe:screenshot` (Pipette: `alpe:eyedropper`, Plan 0.8 Nr. 75); sie soll ohne Einblenden erscheinen,
  wenn in der eigenen Hyprland-Datei eine Regel für `^alpe:.*` steht.
- **Einstellungssuche (Abschluss des Halts nach D7):** Die Registrierung der Zeilen und Karten
  für die Suche hängt neu als Eigenschaft an der Zeile. Einstellungen öffnen, im Suchfeld
  «Sperre» und danach «Schrift» suchen, je einen Treffer wählen: Die Seite wechselt, rollt zur
  Zeile und hebt sie kurz hervor. Danach zügig durch mehrere Seiten klicken (Abbau halb
  erzeugter Seiten). Im Protokoll darf `Cannot find member data` nicht stehen (dritter Befehl
  unten); die Meldung kam vorher sporadisch, ein sauberer Lauf allein beweist also nichts.
- **Pipette:** Farbwähler der Leiste öffnen und die Pipette starten; während der Auswahl zeigt
  `hyprctl layers | grep alpe:` die Fläche `alpe:eyedropper` (das Modal selbst heisst weiterhin
  `alpe:color-picker`). Eine eigene Regel für `dms-colorpicker` schreibt erst F1 um.
- **Dock ohne angeheftete Programme** (das ausgelieferte Design heftet nichts mehr an): Im Dock
  alle Anheftungen lösen (Rechtsklick → «Aus Dock loslösen») und offene Fenster schliessen. Ansehen und
  festhalten, am besten mit Bild: Breite und Form des Docks nur mit dem Papierkorb, Abstände,
  Trennstrich, ob es leer wirkt oder verrutscht. Danach wieder anheften – oder es bleiben
  lassen, das Zurückholen am Ende stellt die Session wieder her.
- **Papierkorb im Dock:** Er muss ein richtiges Symbol zeigen (leer `user-trash`, mit Inhalt
  `user-trash-full` aus dem Symbolthema), kein schwarzes Quadrat und keinen leeren Platz. Beides
  ansehen: Papierkorb leer, dann eine Datei hineinlegen. Welches Symbolthema eingestellt ist,
  dazuschreiben. Findet das Thema das Symbol nicht, zeichnet `DockTrashButton.qml` ersatzweise
  ein Schriftsymbol (`delete`) – auch das ist kein Quadrat. Am PC zeigt das Bild der Ladeprüfung
  (verschachteltes Hyprland, 22.11.2026) das richtige Symbol, aber auf einem schwarzen Quadrat,
  mit und ohne Anheftungen. Ursache ist das Symbol aus dem Ersatzthema Adwaita, das Qt mit
  schwarzem Grund rendert – siehe «Ladeprüfung» unten; am Mac ist Adwaita die Vorgabe von
  Fedora. Am Mac festhalten: Quadrat hinter dem Papierkorb ja/nein, eingestelltes Symbolthema,
  und wie das kleine Dock nur mit dem Papierkorb wirkt.
- **Tastenkürzel, Fensterregeln, Über-Seite, Mitteilungen:** wie in der Liste für D6.

Die Ladeprüfung in den Varianten «gesperrt» und «offen» (Plan 0.8 Nr. 70) läuft nur am PC.

Auswerten wie oben, mit `/tmp/alpe-d7.log`; zusätzlich darf der erste Befehl nichts finden. Der
zweite zeigt, was das Protokoll zu den beiden Plugins sagt (am PC meldet hueManager dort eine
Warnung aus eigenem Code, `Color.js … used before its declaration` – die gab es schon unter 1.0):

```
grep -E "is not a type|is not installed|is deprecated" /tmp/alpe-d7.log
grep -E "hueManager|calculator" /tmp/alpe-d7.log
grep -c "Cannot find member data" /tmp/alpe-d7.log
```

Beenden und zurückholen wie oben. Die angepassten Plugins bleiben dabei unter
`~/.config/alpe/plugins` (sie stecken in der Sicherung von Schritt 0 an).

**Zusatz zu den Repo-Plugins** (Plan 0.8 Nr. 32). Ab D7.2b importieren die Repo-Plugins
`qs.Alpe.*`; die alten Kopien von alpeSport und alpeRadar (aus 1.0, über `cp -rn` oben auch in
`~/.config/alpe/plugins`) laden damit nicht mehr und würden als Benutzerkopie die Repo-Fassung
verdecken. Für den Test zur Seite legen und die Repo-Fassung einsetzen, nach dem `cp -rn` und vor
dem Start der Testshell:

```
mkdir -p ~/.config/alpe/plugins.beiseite-d7
mv ~/.config/alpe/plugins/alpeSport ~/.config/alpe/plugins.beiseite-d7/
mv ~/.config/alpe/plugins/alpeRadar ~/.config/alpe/plugins.beiseite-d7/
cp -r ~/alpe-phase-a/plugins/alpeSport ~/.config/alpe/plugins/
cp -r ~/alpe-phase-a/plugins/alpeRadar ~/.config/alpe/plugins/
```

(Meldet `mv`, dass es eine Kopie nicht gibt, ist sie nicht da – dann nur die Repo-Fassung
kopieren.) `~/.config/dms/plugins` bleibt unberührt; dort liest 1.0 weiter seine Kopien.
Nach dem Test die alten Kopien zurückholen:

```
rm -r ~/.config/alpe/plugins/alpeSport ~/.config/alpe/plugins/alpeRadar
mv ~/.config/alpe/plugins.beiseite-d7/alpeSport ~/.config/alpe/plugins/
mv ~/.config/alpe/plugins.beiseite-d7/alpeRadar ~/.config/alpe/plugins/
rmdir ~/.config/alpe/plugins.beiseite-d7
```

## Nach C4: Liste für D

- ~~**Hinweise auf entfernte Befehle** (`dms setup`)~~ erledigt in D6: Oberfläche und Dienst
  sagen jetzt, dass zuerst `~/.config/hypr/hyprland.lua` anzulegen ist (evdev: nur die Gruppe
  `input`). Zeigt E4/F2 einen `alpe`-Befehl für die Einrichtung, die Texte dorthin ändern.
- **Deployer in `core/internal/config`** (`deployer.go`, `session_units.go`, eingebettete
  `hypr-*.lua`, Terminal-Vorlagen): hat seit dem Wegfall von `dms setup` keinen Aufrufer mehr,
  ist aber die einzige Stelle, die auf einem frischen Hyprland-System `hypr/dms/*.lua` anlegt
  (Plan 7.4). Bleibt vorerst stehen; in E4/F2 entscheiden, ob `alpe` bzw. `get.sh` ihn für eine
  frische Mac-Installation nutzt oder ob er wegkommt.
- ~~`core/internal/log/filelogger.go` (`duxinstall-*.log`)~~ ohne Aufrufer, entfernt in C6.
- Theme-Kategorie «registry»: Die Auswahl ist weg, `Theme.qml` kennt die Kategorie aber noch
  (wer ein Register-Theme aktiv hatte, behält es als eigene Datei). Mit D6/D7 bereinigen.

**Kürzel am Mac im D7-Stand (Plan 0.8 Nr. 44):** Kürzel mit alten Zielen greifen in der
Testshell erwartungsgemäss **nicht** – das ist kein Befund. Betroffen sind alle Hyprland-Zeilen
mit `dms ipc call …`, `dms screenshot …` (das Programm `dms` erreicht nur die Shell 1.0), das
IPC-Ziel `dankdash` (entfällt ohne Übergang; neu `dash toggle wallpaper`) und Seiten-IDs wie
`dank_dash` oder `dankbar_widgets` als Argument von `settings`. Erst der Umzug (F1, Plan 7.4
Schritt 6) schreibt sie um. Zum Prüfen im Terminal:

```
alpe-dienst ipc call dash toggle overview
alpe-dienst ipc call dash toggle wallpaper
alpe-dienst ipc call settings tabs
```

**Layer-Regeln am Mac im D7-Stand (Plan 0.8 Nr. 42, Tabelle):** Eigene Hyprland-Regeln mit
`dms:…` (`layerrule = blur, dms:bar`, `hl.layer_rule({ match = { namespace = "^dms:.*$" } … })`)
treffen die Testshell nicht mehr; ihre Flächen heissen `alpe:…` (`alpe:bar`, `alpe:island`,
`alpe:popout` …). Für den Test eine Zeile mit `alpe:` daneben setzen oder den Befund «kein Blur,
keine Animation-Ausnahme» als erwartet verbuchen; F1 schreibt die Regeln um. Nachsehen, was heute
vorkommt:

```
grep -rn "dms:" ~/.config/hypr
```

**Rückweg zu 1.0 nach dem Test (Plan 0.8 Nr. 41):** Die Testshell schreibt `session.json` schon
beim ersten Start auf Version 8. Wer die Session des Tests für 1.0 weiterverwenden will, nimmt
dafür nur die Sicherung `session.v7.json` – nie die migrierte `session.json`:

```
cp ~/.local/state/alpe/session.v7.json ~/.local/state/dms/session.json
```

(Im normalen Test ist das nicht nötig: 1.0 liest weiter `~/.local/state/dms/session.json`, die der
Test nicht anfasst.) Dasselbe gilt für `settings.v42.json` bzw. `settings.v43.json` unter
`~/.config/alpe/`.

## Nach D1: Folgen der neuen Namen

- **Kürzel in Hyprland-Dateien:** Die Kürzel-Aktionen heissen jetzt `alpe-dienst ipc call …` bzw.
  `alpe-dienst screenshot …`. Bestehende Zeilen mit `dms ipc call …` erkennt der Kürzel-Editor
  weiter (`KeybindActions.normalizeLegacyAction`), ausgeführt werden sie aber von Hyprland mit
  dem alten Programm `dms` – das spricht nur DMS-Sockets an, nie `alpe-<pid>.sock`. **Der Umzug
  (F1) muss in `hypr/alpe/*.lua` und eigenen Hyprland-Dateien `dms ipc`/`dms screenshot` auf
  `alpe-dienst` umschreiben.** Mac-Test bis dahin: Kürzel der Testshell über
  `alpe-dienst ipc call …` im Terminal prüfen; die eingebauten Hyprland-Kürzel erreichen sie
  nicht.
- `tools/maclock.sh` schreibt noch
  `dms ipc call lock lock` in `hypridle.conf` und die Hyprland-Kürzel (`tests/test_maclock.py`).
  Mit E4 auf `alpe-dienst` umstellen, der Umzug schreibt bestehende Zeilen um.
- `tools/alpe`, `tools/backend.sh`, `bootstrap.sh`, `get.sh` kennen noch `/usr/bin/dms` und
  `dms.service` (1.0-Weg, wird in E4/F2 ersetzt). `backend.sh` baut schon `bin/alpe-dienst`.
- ~~Hilfetexte des Dienstes und Oberflächentexte mit `dms`~~ erledigt in D6.
- `ALPE_SHELL_DIR` ist jetzt zugleich die Variable des Dienstes (vorher `DMS_SHELL_DIR`) und die
  der Werkzeuge/Tests – gleiche Bedeutung (Ordner mit `shell.qml`). Die Hyprland-Zeile
  `env = DMS_SHELL_DIR,…` aus `hypr/alpe.conf` wirkt auf `alpe-dienst` nicht mehr (Umzug 7.4
  entfernt sie ohnehin).
- Toter Code aus C4, erst jetzt gesehen: `internal/version` (`GetDMSVersionInfo`,
  `GetLatestDMSVersion`, Abfrage der DMS-Releases über `internal/netfetch/release.go`) hat
  ausser `CompareVersions` keinen Aufrufer mehr. Kandidat für einen Aufräum-Commit.
- `process.restartService` im Root-Helfer (Prozessliste → «Dienst neu starten») ruft
  `systemctl restart` für **System**-Dienste auf, auf ausdrückliche Handlung des Nutzers. Das
  ist nicht der eigene Dienst; Plan 6.8 bezieht sich auf `alpe.service`. Bleibt, falls du es
  nicht anders willst.

## Nach D2/D3: Folgen für Umzug und Werkzeuge

- **Umzug (F1) zusätzlich zu Plan 7:** Drop-ins der Autostart-Seite enthalten
  `After=dms.service` (`~/.config/systemd/user/<app>.service.d/`); die Shell schreibt ab D1
  `After=alpe.service`. Bestehende umschreiben. Ebenso die Hyprland-Fensterregel
  `dms-floating-windows` mit dem alten App-ID-Muster (die Shell aktualisiert sie beim Start
  selbst, sofern `hypr/alpe/windowrules.lua` eingebunden ist) und `kwinrc`
  `[Effect-better-blur-dx] WindowClasses` mit `dev.duxlabs.shell` (Plan 7.2 Schritt 6).
- **Werkzeuge (E4):** `tools/alpe` (Sicherungsliste mit `.config/dms`, `hypr/dms`,
  `dms.service.d`; Prüfung auf `dev.duxlabs.shell.desktop`), `tools/entfernen.sh`
  (`$CONFIG/dms` …), `tools/design.py` (stoppt/startet `dms.service` beim Einspielen),
  `install.sh` (Desktop-Datei `dev.duxlabs.shell`). Umgestellt sind in D2 nur die Werkzeuge,
  die Dateien der Shell schreiben oder lesen (`design.py`, `activate-plugins.py`, `maclock.sh`,
  `alpe sport`, Sport-Plugin).
- `doctor` sucht die Oberfläche noch unter `quickshell/dms` (`config.LocateDMSConfig`); mit E1
  (`/usr/share/alpe/shell`) anpassen.
- Bewusst gleich geblieben (D6/D7): Dateinamen `dms-colors.json`/`dms-typography.json` im
  Cache-Ordner, fcitx5-Theme-Name `dms` (in der fcitx5-Einstellung der Nutzer gewählt),
  Lualine-Theme `dms`, Kennung `source: "dms"` zwischen Kürzel-Parser und Oberfläche,
  Regelname `dms-floating-windows`, CUPS-Benutzername `dms`, Hotspot-Name
  «DankMaterialShell Hotspot», Kalender-Anbindung an `dev.duxlabs.calendar` (fremde App).
  Nach D6 weiter so; Hotspot siehe «Nach D4–D6: Fragen» Nr. 6.
- ~~Logos der Oberfläche~~ erledigt in D6 (`alpe-zeichen.svg`, `alpe-zeichen-akzent.svg`);
  App-Symbol und Desktop-Dateien liefert E1.
- ~~Abschnittsüberschrift «DMS Include Configs»~~ erledigt in D6: neue Kopfzeile
  «-- Alpe: eingebundene Dateien», die alte gilt beim Einbinden weiter als vorhanden. Der
  Umzug (F1) kann die alte Kopfzeile umschreiben, muss aber nicht.

## Nach D4–D6: Fragen zum Halt

1. ~~**Kennungen der eingebauten Starter-Plugins**~~ → D7.5 (Plan 0.8). **Kennungen der eingebauten Starter-Plugins** `dms_settings`, `dms_notepad`, `dms_sysmon`,
   `dms_colorpicker`, `dms_settings_search`, `dms_clipboard_search`, `dms_power`,
   `dms_qr_generator`, `dms_vpn` (≈50 Stellen; gespeichert in `builtInPluginSettings`,
   `launcherPluginVisibility`, `launcherPluginOrder`, Session `builtInPluginState`, Starter-
   Zwischenspeicher). Nicht sichtbar. In D5 bewusst nicht umbenannt. **Vorschlag:** auf die
   Ausnahmeliste (interne Kennung, wie 0.7 Nr. 3), Phase C. Alternative: Migration v44.
2. ~~**Material-Hintergrund «Dank»**~~ → entschieden (Plan 0.8 Nr. 13): Vorlage «Alpe», Form Alpe-Zeichen, Migration v44. **Material-Hintergrund «Dank»** (Vorgabe-Vorlage, `DCommon/Common/MaterialWallpaper.js`):
   heisst sichtbar «Dank» und zeichnet als Ebene `dankLogo` die **Logoform des Ursprungs**
   (`DCommon/Widgets/DLogoShape.js`). **Vorschlag:** Form durch das Alpe-Zeichen ersetzen
   (Kurven aus `alpe-zeichen.svg`), Bezeichnung «Alpe»; der gespeicherte Wert `"dank"` bleibt
   intern. Alternative: Vorlage entfernen (Vorgabe wird «bloom», Migration nötig).
3. ~~**Logo-Modus `"dank"`**~~ → D7.5 (Plan 0.8). **Logo-Modus `"dank"`** (Starter-Knopf, Apps-Dock, Dot: `launcherLogoMode`,
   `islandFreeIconMode`): zeigt seit 1.0 das Alpe-Zeichen, der Wert ist nicht sichtbar, liegt
   aber verschachtelt in Leisten-/Dock-Konfigurationen. **Vorschlag:** Ausnahmeliste, Phase C.
4. ~~**Webdienste des Ursprungs**~~ → entschieden (0.8 Nr. 14): Doku-Links und «Wallpaper creator» samt Code weg. **Webdienste des Ursprungs** (`Common/Site.qml`, `duxlabs.dev`): Doku-Link auf der
   Autostart-Seite, Doku-Links in `alpe-dienst doctor`, Knopf «Wallpaper creator»
   (Webdienst des Ursprungs; installiert über das Schema `dms://wallpaper/install/`, das
   `alpe-dienst open` und `DMSShell.qml` annehmen). **Vorschlag:** Doku-Links entfernen
   (Alpe hat keine eigene Doku-Seite), Wallpaper-Knopf ausblenden, `dms://` bleibt intern bis
   Phase C. Entscheid nötig, weil es eine Funktion wegnimmt.
5. ~~**Sie-Form**~~ → Prüfliste `docs/plan/sie-form.md`, Freigabe vor G1 (0.8 Nr. 15). **Sie-Form im deutschen Katalog des Ursprungs:** 103 von 3090 Übersetzungen siezen
   («Aktualisieren Sie …», «Ihr System …»); die Oberfläche soll duzen. Mechanisch nicht sicher
   umzustellen (Verbformen). **Vorschlag:** eigener Commit vor G1, Liste von Hand durchgehen.
6. ~~**Systemnahe Namen**~~ → keine dauerhafte Ausnahme (0.8 Nr. 16): paketierte Pfade und PAM in E1, Hotspot in D7, CUPS siehe unten. **Systemnahe Namen:** PAM-Dienste `/etc/pam.d/dankshell`, `dankshell-u2f` und deren
   Blockmarken «DMS LOCKSCREEN AUTH»; NetworkManager-Verbindung «DankMaterialShell Hotspot»
   (nur der Verbindungsname, die SSID wählt man selbst); Richtlinien
   `/usr/share/dms/cli-policy.json`, `/etc/dms/cli-policy.json`; CUPS-Benutzername `dms`.
   Umbenennen hiesse Systemdateien migrieren (sudo) bzw. alte Verbindungen doppelt führen.
   **Vorschlag:** Ausnahmeliste; die Richtlinien-Pfade mit E1 (Paket) neu entscheiden.
7. ~~**Gesperrte Pakete**~~ → mit E4 entfernen (0.8 Nr. 17). **Gesperrte Pakete** `Brand.heldPackages` (`dux-shell`, `dms`, `dms-cli`) und die
   Hold-Anzeige auf der Wartungsseite: gehören zur 1.0-Einrichtung; Plan 2.2 sagt «entfällt».
   **Vorschlag:** mit E4 entfernen (nach dem Umzug ist `dux-shell` weg).

Dazu, ohne Frage: Die deutschen Kataloge hatten «ß» (ersetzt), Importreihenfolge in 6 Go-Dateien
seit D3 (`bca3795`, Import von `internal/brand`) nicht gofmt-sauber (kosmetisch, vor G1), `Theme.qml` kennt die Kategorie «registry»
weiter (unverändert seit C4).

## Vor D7: Fragen (Plan 0.8, 2.3) – beantwortet am 22.11.2026

Antworten in Plan 0.8 Nr. 6–19: claudeCodeUsage ins Repo; calculator in eigenes Repo
`~/alpe-plugins`; sathiAi und hueManager per Anleitung; Namen freigegeben (`ShellBackend`,
`dash`, `alpe_*`, `palette16`); Material-Vorlage «Alpe» mit Alpe-Zeichen.

~~**Noch offen (vor D7.2):** Lesart der Widget-Bibliothek~~ → **Variante B** (Plan 0.8 Nr. 20);
Modulnamen fallen unter die Regel (0.8 Nr. 21, Zuordnung Plan 2.3.2: `qs.Alpe.*`,
`qs.Alpe.Dash`, `qs.Modules.Bar`, `qs.Modules.Island`, `qs.Modals.Launcher`). CUPS, «Phase C»
und Grössenprüfung: 0.8 Nr. 22–24.

## CUPS-Benutzer `dms` (Befund, Plan 0.8 Nr. 16)

Der Dienst setzt `requesting-user-name = "dms"` an fünf Stellen, alle beim **Abonnement von
Druckerereignissen** (`core/internal/server/cups/subscription.go`, `subscription_dbus.go`):
Anlegen (`Create-Printer-Subscriptions`), Abholen der Ereignisse und Kündigen. Druckaufträge,
Verwaltung oder Anmeldung benutzen ihn nicht. cupsd führt den Namen als Besitzer des
Abonnements; es ist kein Systemkonto, und es wird kein Recht damit verbunden (Ereignisse eines
Abonnements darf jeder abholen, Kündigen prüft den Besitzer). Abonnements laufen unbegrenzt
(Abfrageweg, `notify-lease-duration 0`) bzw. einen Tag (D-Bus-Weg) und werden beim Beenden
gekündigt. **Entschieden (Plan 0.8 Nr. 22, 2.3.3):** Benutzername zur Laufzeit (`os/user`, Rückfall
`alpe`); alte Abonnements des Besitzers `dms` kündigt der Dienst beim ersten Start einmal, weil
sich ihre Laufzeit (0 = ohne Ende, je nach `MaxLeaseDuration`) nicht belegen lässt. Am PC gab es
am 22.11.2026 keines.

## Mögliche eigene Funktion: Hintergrund-Gestalter (nach Phase A)

«Wallpaper creator» war ein Webdienst des Ursprungs (`wallpaper.duxlabs.dev`), der Bilder über
`dms://wallpaper/install/…` an die Shell übergab. Er entfällt in D7.5 samt Code (0.8 Nr. 14).
Denkbar später: eigener Gestalter in den Einstellungen (Material-Vorlagen gibt es schon) oder
ein eigenes Schema `alpe://` mit Handler im Paket.

## Mögliche eigene Funktion: Aktualisierungsprüfung im Dienst (allenfalls Phase B)

Der Dienst trug aus dem Ursprung eine Aktualisierungsprüfung ohne Aufrufer: installierte Version
aus dem Git-Stand der Oberfläche, neueste Version über die Release-Seite bzw. die GitHub-API
(`internal/version`, `internal/netfetch/release.go`). In D7.8a entfernt (Plan 0.8 Nr. 65);
`CompareVersions` bleibt für `doctor` und die Hyprland-Vorlagen. Aktualisierungen laufen in 1.1
über das Paket (`alpe update`, Wartungsseite). Eine eigene Prüfung gegen `alpe-shell/alpe`
(Hinweis in der Oberfläche, wenn eine neue Fassung erschienen ist) käme allenfalls in Phase B
mit dem neuen Dienst; dann gegen die Releases des eigenen Repos und mit dem User-Agent nach
0.8 Nr. 67.

## Aus D7.8a: zwei Fragen (22.11.2026) – beantwortet, Plan 0.8 Nr. 73 und 74

**Entschieden:** (1) F1 benennt die WirePlumber-Datei um, `AudioService` schreibt danach nur den
neuen Namen, der Rückweg benennt zurück, nie beide Dateien gleichzeitig. (2) Abgleich-Skripte
werden entfernt, das Skript zum Herausziehen der Texte wird angepasst und behalten. Der Text
unten ist der Stand der Frage.

1. **WirePlumber-Datei `51-dms-audio-aliases.conf`.** `AudioService.qml` schreibt die Namen der
   Audiogeräte nach `~/.config/wireplumber/wireplumber.conf.d/51-dms-audio-aliases.conf` – eine
   Ausgabedatei mit altem Namen, die in D7.7b2 (Tabelle 7.6) fehlt. Sie liegt auf Rechnern mit
   1.0 schon dort. Schreibt 1.1 unter einem neuen Namen, liest WirePlumber beide Dateien, und die
   alte gewinnt oder verdoppelt Einträge; umbenennen darf die Shell sie nicht still. In D7.8a
   **nicht umbenannt**, Ausnahmeliste mit Frist F1. Vorschlag: F1 benennt die Datei beim Umzug auf
   `51-alpe-audio-aliases.conf` um (Rückweg zurück), die Shell schreibt ab dann den neuen Namen;
   bis dahin bleibt der alte. Entscheid offen.
2. **Übersetzungsskripte des Ursprungs** (`shell/translations/extract_translations.py`,
   `check_term_freeze.py`, `check_term_variants.py`, `replace_qstr.py`): kein Aufrufer in
   `tools/test.sh`, Skripten oder CI. Sie kennen die Plugin-Repos des Ursprungs als
   Nachbarverzeichnisse (`dms-plugins`, `dms-plugins-external`) und ein fremdes
   Übersetzungsprojekt; `extract_translations.py` überspringt zudem den ganzen Ordner `Alpe/`
   (gedacht für die Widget-Bibliothek mit eigenem Katalog; seit D7.2a liegen dort auch Dash und
   Dateiverwaltung, `en.json` führt 185 Einträge mit erster Fundstelle unter `Alpe/`) – ein neuer
   Lauf würde solche Texte vermutlich aus `en.json` streichen (nicht ausprobiert). In D7.8a nichts daran geändert (Ausnahmeliste, Frist G1);
   `en.json`/`template.json` sind von Hand nachgeführt, `settings_search_index.json` mit
   `extract_settings_index.py` neu erzeugt (das Skript läuft richtig). Vorschlag für G1:
   `extract_translations.py` auf den heutigen Baum richten (ohne Plugin-Nachbarn, mit `Alpe/`)
   und als Prüfung in `tools/test.sh` aufnehmen, die beiden `check_term_*` entfernen. Entscheid offen.

   **Erledigt (Halt nach D7, 0.8 Nr. 74):** `check_term_freeze.py`, `replace_qstr.py` und
   `template.json` entfernt; `extract_translations.py` liest die ganze Oberfläche samt `Alpe/`,
   kennt `--pruefen` und schreibt `en.json` ohne Zeilennummern; `check_term_variants.py` bleibt
   als Prüfung der Quelltexte. Beides läuft über `tests/test_uebersetzung.py` in `tools/test.sh`.
   42 Texte ohne deutsche Übersetzung stehen in `tests/data/uebersetzung-bekannte-luecken.txt`.

## Notizblock: Markdown-Vorschau neu bauen (Frist: vor G1)

Die Vorschau im Notizblock wurde nur vom Store-Plugin `dankNotepadModule` gespeist und ist mit
dessen Anbindung in D7.5b entfallen (Plan 0.8 Nr. 37). Damit 1.1 gegenüber 1.0 keine Funktion
verliert, wird sie **vor G1** ohne Plugin neu gebaut: Anzeige des Notiztexts über
`Text.MarkdownText` (Umschalter Bearbeiten/Vorschau wie in 1.0), neuer Test. Die Altdaten des
Plugins behandelt weiterhin `SESSION_BACKED_PLUGIN_IDS` in `SettingsStore.js` (Ausnahmeliste,
Frist «Umzug-Ende»).

## Plugin-Seite: Hinweis bei veralteter Benutzerkopie (ohne Frist in Phase A)

Liegt ein Plugin mit derselben ID im Benutzerordner und im Systemordner, gewinnt die
Benutzerkopie (Plan 0.8 Nr. 32). Ist die Benutzerkopie älter als die mitgelieferte Fassung
(Vergleich der `version` aus beiden `plugin.json`), soll die Plugin-Seite einen Hinweis zeigen
(Plan 0.8 Nr. 39). Nicht in Phase A terminiert.

## Vencord: lädt das Thema beim Wechsel über den Link neu? (ohne Frist)

Bis «Umzug-Ende» zeigt `themes/dank-discord.css` als Link auf `alpe-discord.css` (Plan 0.8
Nr. 48, 59). Ungeklärt ist, ob Vencord (und Vesktop, Equibop) eine Änderung der Zieldatei
bemerkt, wenn das gewählte Thema der Link ist, oder ob das Thema dann erst nach einem Neuladen
des Clients (Strg+R) die neuen Farben zeigt. Nicht geprüft, auch nicht am Quelltext der Clients. Zu prüfen
an einem Rechner mit laufendem Client: Farbwechsel in Alpe auslösen, einmal mit dem alten Namen
(Link) und einmal mit `alpe-discord.css` als gewähltem Thema. Lädt der Client über den Link
nicht neu, genügt bis zum Umzug ein Hinweis im CHANGELOG; nach F1 steht die Auswahl ohnehin auf
dem neuen Namen (Plan 7.6).

## Hyprland: `hyprctl descriptions` (nach Phase A)

Unter Hyprland 0.57.2 meldet `HyprlandService.qml:257` `hyprctl descriptions parse failed:
SyntaxError: JSON.parse`. Gibt es schon in 1.0 (Journal vom 20.11.2026, vor Phase A), also
nicht durch Phase A verursacht. Folge: `hyprOptionNames` bleibt leer; die Layout-/Eingabe-
Erzeugung läuft trotzdem weiter. Vermutung: Hyprland 0.57 liefert für `hyprctl -j descriptions`
kein gültiges JSON (oder Text vor dem JSON). Nicht in Phase A beheben (Plan 0.6 Nr. 3).

## Plugin-Kompatibilität (0.7 Nr. 3, **ersetzt durch Plan 0.8**: keine Weiterleitungen, D7)

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

**Nach Halt D6 verworfen (Plan 0.8):** Weiterleitungen und `requires_dms` entfallen in D7, fremde Plugins werden angepasst (Plan 2.3.4). Kein `/usr/bin/dms` bleibt. Früherer Vorschlag, nur noch zur Nachvollziehbarkeit:

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

- Go: ~~`internal/matugen` `TestTerminalPaletteOnlyReachesTerminalTemplates`; `internal/qmlchecks`
  `TestLockScreenPasswordFieldBypassesTextInputIME`, `TestLockScreenFprintProfileMatchesPamQml`~~
  **behoben vor D7.7b** (Plan 0.8 Nr. 49): Alle drei lasen die Oberfläche am Ursprungspfad
  `../../../quickshell/…`; sie lesen jetzt `shell/…` und sind grün. Der Katalogtest
  `TestHyprlandKeybindCatalogMapsToLua` übersprang sich aus demselben Grund still und läuft jetzt mit.
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
- Hyprland: Die Meldung zur Fensterregel der Shell nennt seit D6 «the shell window rule» und
  verweist auf das Anlegen von `hyprland.lua` statt auf `dms setup` (Grundlinie nachgeführt).
- **KWin: leere Bildschirmliste** – `[WlrOutputService] Received empty outputs list`. Unter
  KWin kommen die Bildschirme über kscreen, nicht wlr-output-management; zu klären, ob die
  Anzeige-Seite unter KWin trotzdem Bildschirme zeigt oder ob nur die Meldung stört.
- Hyprland: `[KeybindsService] Failed to parse binds: SyntaxError: JSON.parse` und
  `Load process failed with code: 1` (Kürzel-Auslesen scheitert im Testprofil).
- Hyprland: `[CompositorService] failed to update the shell window rule dms-floating-windows …
  hyprland.lua not found …` (im Testprofil gibt es keine `hyprland.lua`; Text seit D6 ohne
  `dms setup`).

- **Offen, gefunden beim Abschluss des Halts nach D7 (22.11.2026): Unter dem verschachtelten
  Hyprland verbindet sich die Oberfläche nie mit dem Dienst.** Im Protokoll des Dienstes ist
  `Attempting to initialize Wayland gamma control...` die letzte Zeile der Initialisierung; danach
  kommt bis zum Ende des Laufs nichts mehr (unter KWin folgt `Failed to initialize wayland manager:
  … compositor does not support gamma control`, und es geht weiter). Die Oberfläche meldet nie
  `Connected (API v…)`; `ShellBackend.isConnected` bleibt falsch. Folgen im Lauf: Widgets, die
  `DgopService.dgopAvailable` brauchen (`cpuUsage`, `cpuTemp`, `gpuTemp`, `memUsage`), bleiben
  unsichtbar – darum ist die linke Leistenseite im Bild leer –, `[ProcessListModal] dgop is not
  available` und `Theme worker: Server unavailable, running synchronously` stehen seit jeher in
  der Hyprland-Grundlinie und nur dort. Gleich auf `ba4ddbc` und auf dem Endstand, also **kein
  Fehler aus D7**; aber die Ladeprüfung unter Hyprland hat alles, was den Dienst braucht
  (Netzwerk, Systemmonitor, Plugins-Verwaltung, Farbschema über den Dienst), nie geprüft.
  **Berichtigt (22.11.2026): Die Ursache ist nicht Gamma und nicht der Compositor, sondern der
  Systembus.** Der Ersatz-Systembus der Ladeprüfung erlaubte keine Antworten; der Dienst wartet
  ohne Zeitgrenze auf die Antwort zu `Hello`. Belegt durch die Goroutinen-Stapel
  (`ALPE_LP_STAPEL=1`): Der Loginctl-Manager steht in `Hello` und hält dabei `systemBusLck`, die
  paketweite Sperre von godbus in `dbus.SystemBus()`; der Hauptablauf wartet in
  `wayland.NewManager` → `setupDBusMonitor` (Ruhezustands-Überwachung von Gamma) auf genau diese
  Sperre und erreicht `s.ipc.Serve` nie. Die Zeile zu Gamma ist nur die letzte Meldung davor.
  Unter KWin scheitert Gamma schon vorher am Compositor, darum hingen dort nur Netzwerk-,
  Loginctl- und Freedesktop-Manager still im Hintergrund. **Zwei Teile:** (1) Prüfumgebung
  behoben in `439de4f` (Richtlinie erlaubt Antworten; ein Lauf ohne `Connected` gilt als
  gescheitert, Plan 0.8 Nr. 81); Probelauf unter Hyprland meldet `Connected`. (2) Der Dienst
  selbst – **ein Fehler aus der Zeit vor Phase A**, am Mac bei einem hängenden Systembus ebenso
  denkbar – hat eine Zeitgrenze für alle Verbindungen zum Systembus bekommen: Plan
  `docs/plan/dienst-systembus.md` (freigegeben, 0.8 Nr. 84), **behoben am 22.11.2026**: Paket
  `core/internal/systembus`, eine Verbindung für alle Manager, erneute Versuche im Hintergrund,
  Ruhezustands-Überwachung von Gamma nebenher. Gegenprobe mit stummem Ersatz-Systembus
  (`ALPE_LP_STUMMER_BUS=1`) unter Hyprland und KWin bestanden; sie läuft seither bei jedem Halt
  einmal mit, unter einem Compositor (0.8 Nr. 85). Die Grundlinien sind danach neu gemessen
  (`9685ebe`, 0.8 Nr. 80). **Für G1:** Changelog-Eintrag 1.1 zur Behebung «Dienst hing bei stummem
  Systembus, Oberfläche verband sich nie».
- **Sporadische Meldungen unter Hyprland aus der Neumessung (22.11.2026), nicht behoben –
  Herkunft offen, Frist: vor G1:** je in
  1 von 3 Läufen (a) `NotepadStorageService`: «Tab file does not exist …/untitled-<ID>.txt» samt
  der zugehörigen `FileView`-Meldung (Variante «gesperrt»; der erste Reiter wird gelesen, bevor
  seine Datei angelegt ist), (b) `DeferredAction.qml`: «Property 'flush' of object … is not a
  function» (Variante «offen»; vermutlich feuert der Timer, während das Objekt abgebaut wird).
  Beide Dateien sind seit `ba4ddbc` unverändert; in den sechs Gegenläufen auf `ba4ddbc` unter
  Hyprland trat keine auf, unter KWin in zwölf Läufen keine. Sechs Gegenläufe schliessen bei
  dieser Häufigkeit weder aus, dass die Meldungen schon vorher auftraten, noch belegen sie es.
  **Herkunft offen** (Entscheid des Maintainers nach dem Halt D7; die frühere Einordnung, sie
  stammten nicht aus Phase A, ist zurückgenommen): Dass die beiden Dateien unverändert sind, sagt
  nichts über ihre Aufrufer, und D7 hat Aufrufer umbenannt. In den Grundlinien als
  `SPORADISCH 1/3` geführt. Ursache der beiden Wettläufe nicht untersucht.
  **Vor G1 zu klären:** (a) Notizblock: Reihenfolge von Anlegen und Lesen des ersten Reiters,
  gegen den Stand vor Phase A. (b) `DeferredAction`: alle Aufrufer prüfen, die `flush` erwarten
  (Objekte, die als `DeferredAction` angelegt sind oder waren, samt den in D7 umbenannten
  Typen, Kennungen und Importen), ob `flush` dort noch auf ein `DeferredAction` trifft; dazu der
  eigene Zeitgeber der Datei (`onTriggered: root.flush()`) beim Abbau. Vorabblick ohne Befund,
  ersetzt die Prüfung nicht: 16 QML-Dateien nennen `DeferredAction`, `.flush()` ruft von aussen
  nur `Modules/SurfaceWidgets/ApplicationStrip.qml` (`modelUpdate.flush()`), dazu zweimal
  `socket.flush()` (anderer Typ). Danach je beheben oder mit Begründung einordnen.
  **Am Mac prüfen (zur Anleitung für den Stand nach D7):** Nachtlicht ein- und ausschalten und über
  die Zeitsteuerung laufen lassen; Deckel zu und wieder auf – die Farbtemperatur muss nach dem
  Aufwachen stimmen (die Überwachung des Ruhezustands hängt jetzt erst Augenblicke nach dem Start
  am Bus); WLAN-Liste, Bluetooth, Helligkeitstasten, Sperren beim Zuklappen.
- **Offen (22.11.2026, Frist: vor E1 – Entscheid des Maintainers, weil es das Erste ist, was ein
  neuer Nutzer sieht): Dock ohne angeheftete Programme.** Im Bild der Variante «offen» unter dem
  verschachtelten Hyprland (`1d91c2b`) steht unten in der Mitte nur der Papierkorb auf einem
  schwarzen, scharfkantigen Quadrat von etwa 68 px. **Gegenprobe (22.11.2026, Stand `016d986`,
  im Temp-HOME vier Programme angeheftet, sonst gleich; Lauf gültig, 39 gleich, nichts neu):** Mit
  Anheftungen zeichnet das Dock eine gerundete, dunkle Fläche um alle Symbole; der Papierkorb
  sitzt darin weiterhin auf seinem schwarzen Quadrat. Die Gegenprobe lief unter Hyprland in der
  Variante «offen» gegen `grundlinie-hyprland-offen.txt` (40 Einträge, davon einer `SPORADISCH`;
  «39 gleich» sind die 39 festen – die Zahl gleicht nur zufällig den 39 Einträgen von KWin
  «gesperrt»).
  **Untersucht am 23.11.2026:**
  (1) **Schwarzes Quadrat – Ursache gefunden, liegt nicht im Code von Alpe.** Es ist das Symbol
  selbst: `user-trash.svg` aus `adwaita-icon-theme` 51.0 (128 px, mit `<mask>`, `<filter>` und
  `<clipPath>`), das Qt 6.12 mit deckend schwarzem Grund rendert. Nachgemessen ausserhalb der
  Shell (Qt-Bildleser, offscreen, 72 px): alle vier Ecken (0, 0, 0) mit Alpha 255; dieselbe Probe
  mit `user-trash` aus breeze-dark, Papirus, char-white und AdwaitaLegacy und mit 16 anderen
  Adwaita-Symbolen: Ecken durchsichtig. Im Bild sind die Ecken des Quadrats ebenfalls (0, 0, 0).
  **Warum Adwaita:** Das Design setzt `iconThemeDark: "kora"`; kora liefert niemand mit (nur im
  Home des Maintainers installiert, kein Paket, keine Abhängigkeit, nichts in `get.sh`). Fehlt das
  Thema, sucht `IconThemeService` nur noch in hicolor und übergibt an `Quickshell.iconPath`, also
  an das Ersatzthema von Qt – in der Ladeprüfung Adwaita. **1.0 verhält sich gleich:**
  `DockTrashButton.qml` unterscheidet sich vom Stand 1.0 (`~/dux-shell`, Zweig `alpe`) nur in
  den Namen `DIcon`/`qs.DCommon.Widgets`; am PC des Maintainers ist das Quadrat nie zu sehen,
  weil dort kora installiert ist. **Nicht behoben, weil die Behebung eine Wahl ist:** (a) kora aus
  dem Design nehmen (dann gilt das Thema des Systems, unter KDE breeze) oder kora als
  Abhängigkeit ausliefern – behebt die Ursache, dass ein neuer Nutzer überhaupt beim Ersatzthema
  landet, und betrifft alle Symbole, nicht nur den Papierkorb; (b) für den Papierkorb ein eigenes
  Symbol (Schriftsymbol `delete` wie im heutigen Rückfall, oder ein eigenes SVG) – unabhängig vom
  Thema, aber nicht mehr im Stil des Themas; (c) nichts tun und auf Qt/Adwaita warten – am Mac
  (Fedora, Adwaita als Vorgabe) dann voraussichtlich sichtbar. Vorschlag: (a) ohne kora im Design,
  dazu der Mac-Test als Gegenprobe.
  (2) **Dock-Fläche ohne Anheftungen – Berichtigung: Sie fehlt nicht.** Die Vergrösserung des
  Bildes ohne Anheftungen zeigt um den Papierkorb eine gerundete Fläche von rund 100 × 100 px
  (kaum heller als der Hintergrund daneben, also auf der dunklen Material-Vorlage fast
  unsichtbar; das Design zeichnet keinen Rand, `borderEnabled: false`, Deckkraft 0,8). Die
  Angabe vom 22.11.2026, die Fläche fehle ganz, war falsch gelesen; `hasApps`
  (`widgetStrip.preferredLength > 0`) ist mit dem Papierkorb allein wahr. Ein neuer Nutzer sieht
  also ein kleines, quadratisches Dock nur mit dem Papierkorb (der Starter im Dock ist im Design
  aus, `launcherEnabled: false`). **Möglichkeiten, nicht umgesetzt:** (i) so lassen – richtig
  gezeichnet, wirkt aber wie ein vergessener Rest, bis der Nutzer etwas anheftet oder ein Fenster
  öffnet (laufende Programme erscheinen im Dock); (ii) Dock ohne Anheftungen und ohne laufende
  Programme verbergen – ruhiger Schreibtisch, aber der Papierkorb ist dann nur da, wenn
  Programme laufen, und das Dock «springt» beim ersten Fenster herein; braucht neuen Code in
  `DockBody.qml` und eine Regel für die reservierte Fläche; (iii) im Design den Starter im Dock
  einschalten (`launcherEnabled`) – kein neuer Code, das Dock hat dann zwei Einträge und einen
  erkennbaren Zweck, verdoppelt aber den Starter-Knopf der Leiste, sobald der sichtbar ist;
  (iv) Vorgabe-Anheftungen, die es auf jedem Rechner gibt – unter KDE etwa Dolphin, Konsole,
  Systemeinstellungen; unter Hyprland am Mac gibt es keine gemeinsame Auswahl, und das Einspielen
  übernimmt Anheftungen seit 0.8 Nr. 83 bewusst nicht aus einem Design (bräuchte eine Ausnahme
  für den ersten Start); (v) Rand oder höhere Deckkraft für das Dock im Design, damit die Fläche
  erkennbar ist – ändert das Aussehen auch mit Anheftungen.
  Unter KWin: Bild in der Haltprüfung vom 23.11.2026 (Plan, «Stand»). Gegenprobe am Mac steht in
  der Anleitung für den Stand nach D7.
- **Offen (23.11.2026): kein Bild unter KWin.** `alpe-dienst screenshot full` meldet im virtuellen
  `kwin_wayland` der Ladeprüfung `compositor does not support wlr-screencopy-unstable-v1`; das
  Bild zum Halt (Plan 0.8 Nr. 71) gibt es darum nur unter Hyprland. Der Lauf selbst bleibt
  gültig und ohne neue Meldung. Zu klären: ob das Bildschirmfoto des Dienstes unter KWin
  überhaupt geht (auch auf dem echten Schreibtisch) oder ob die Ladeprüfung dort einen anderen
  Weg braucht (KWin-Schnittstelle `org.kde.KWin.ScreenShot2`, verlangt eine Freigabe über die
  Desktop-Datei). Ebenso: `--bild` gibt es nur in der Variante «offen»; ein Bild des
  Sperrbildschirms brauchte am 23.11.2026 einen Temp-Worktree mit aufgehobener Sperre.
- **Hinweisbalken von Hyprland in der Ladeprüfung: erledigt (`1d91c2b`).** Die Testkonfiguration
  setzt `misc.disable_watchdog_warning`; das Bild danach zeigt keinen Balken mehr, der Lauf
  gegen die Grundlinie «offen» 39 gleich, nichts neu.
- **Offen, nicht belegt (22.11.2026): Kann der Wayland-Teil von Gamma bei einem stummen
  Compositor hängen?** `wayland.NewManager` läuft synchron im Start des Dienstes, vor
  `s.ipc.Serve` (Registry, Ausgaben, Gamma-Steuerung über die geteilte Wayland-Verbindung). Ob
  dort ein Aufruf ohne Zeitgrenze auf den Compositor wartet, ist nicht untersucht; ein Hänger an
  dieser Stelle ist nie beobachtet worden (der beobachtete lag am Systembus, siehe oben). Kein
  Umbau jetzt (0.8 Nr. 82).
- **Offen aus dem Plan zum Systembus (22.11.2026), je ohne Umbau jetzt:** (a) Der Session-Bus hat
  dieselbe Bauart (`dbus.SessionBus()` mit `sessionBusLck`, 10 Stellen im Dienst), aber keinen
  Befund. (b) `gonetworkmanager` ruft selbst `dbus.SystemBus()` auf und nimmt keine Verbindung
  entgegen (Frage 1 im Plan). (c) Nach einem Abriss der Systembus-Verbindung im Betrieb werden
  die Manager nicht neu aufgebaut (heute auch nicht). (d) Der Freedesktop-Manager wartet bei einem
  stummen Systembus als Ganzes, auch mit seinem Session-Bus-Teil (Bildschirmschoner-Sperre,
  Farbschema-Einstellung). (e) Startet der Dienst mit stummem Bus, bleibt die Ortung bei der
  IP-Adresse, auch wenn der Bus später antwortet. (f) Läufe der Ladeprüfung mit stummem Bus dauern
  etwa doppelt so lang (319 s und 263 s gegen 149 s); vermutet, nicht belegt: Zeitüberschreitungen der
  Oberfläche selbst (Qt/Quickshell) am Systembus. Einzelheiten in `dienst-systembus.md`, 5a.
- **Ausgeliefertes Design nennt ein fremdes Plugin:** `design/kde/settings.json` führt links in
  der Leiste `sathiAi` (wird nicht mitgeliefert; auf einem frischen Rechner bleibt die Stelle
  leer) und bei `gpuTemp` die Gerätekennung einer Grafikkarte (`pciId`). `tests/test_werte.py` prüft die
  Widget-Kennungen des Designs gegen die registrierten Widgets und führt `sathiAi` als bekannte
  Ausnahme. Ob beides ins Design gehört, ist offen.
  **Erledigt (22.11.2026, Entscheid des Maintainers):** `sathiAi` und `pciId` sind aus
  `design/kde/settings.json` entfernt (die Shell trägt die Kennung der Grafikkarte auf jedem
  Rechner selbst ein); `tools/design.py` lässt `pciId` beim Export weg (`NESTED_DROP`, Test in
  `tests/test_design.py`). `tests/test_werte.py` kennt keine Ausnahme mehr und prüft alle
  Textdateien unter `design/` auf persönliche Werte (Pfade in ein Home-Verzeichnis, IP-, MAC-
  und E-Mail-Adressen, PCI-/USB-Kennungen, Bildschirmnamen, Koordinaten, Schlüssel wie
  `weatherLocation`, `hostname`, `ssid` mit Wert). **Nicht entfernt, dem Maintainer gemeldet:**
  angeheftete Programme im Dock (`session.json`, `dockPins`: 14 Programmkennungen), die
  Reihenfolge der Ligen in `plugins.json` (`alpeSport.order`), Fensterregeln und
  `windowGripExcluded` für einzelne Programme (`kwin.json`, `settings.json`), Exportdatum im
  `manifest.json`. Ein fremdes Plugin im Bar-Layout fängt beim Export nur der Test ab,
  `design.py` filtert es nicht.
  **Entschieden und umgesetzt (22.11.2026):** `dockPins` ist aus `design/kde/session.json`
  entfernt – das ausgelieferte Design heftet keine Programme an (der Schlüssel fehlt, statt leer
  zu sein: Ein leeres Dock im Design würde beim Einspielen die Anheftungen des Nutzers
  überschreiben). Aus `kwin.json` sind die Fensterregeln «WingDrive» und «dev.zed.Zed» und die
  Programmliste `WindowClasses` des Unschärfe-Effekts (Zen, Nautilus, WingDrive, Zed) entfernt,
  die Hinweise im `manifest.json` dazu ebenfalls. `alpeSport.order` bleibt (National League
  zuerst ist die Vorgabe für Alpe). `tools/design.py` nimmt beim Export Widgets fremder Plugins
  aus dem Bar-Layout (bekannt sind die Widgets aus `WidgetModel.js` und die mitgelieferten
  Plugins), Test in `tests/test_design.py`; der Test in `tests/test_werte.py` bleibt als zweite
  Sicherung. **`windowGripExcluded: ["app.zen_browser.zen"]` entfernt:** Der Eintrag nimmt Zen
  von den Griffleisten aus (`docs/technik.md`, «Griffleisten»: der Streifen am oberen
  Fensterrand fängt Klicks ab; Zen hat dort seine Reiter). Im Repository steht dazu nichts –
  kein Kommentar, kein Eintrag in Doku oder CHANGELOG, keine Sonderbehandlung in
  `alpe-bridge.js`; es ist eine Ausnahme aus den Einstellungen des exportierenden Rechners. Als
  Umgehung eines allgemeinen Problems wäre sie in der Liste ohnehin am falschen Ort, weil
  dasselbe jedes Programm mit Reitern am oberen Rand träfe (Firefox, Chromium …), die nicht in
  der Liste stehen. **Offen:** prüfen, ob die Erkennung selbst gezeichneter Titelleisten
  (`bufferGeometry` grösser als `frameGeometry`) solche Programme unter der Regel «ohne
  Titelleiste» verfehlt; wenn ja, gehört die Lösung in die Brücke, nicht ins Design.
- ~~Sporadisch: `SettingsSearchRegistration.qml: TypeError: Cannot read property 'parent' of null`~~
  Behoben (Commit «Einstellungssuche: abgebaute Karten»): Bindung und `sync()` prüfen `target`
  auf null; `unregisterCard` ohne Karte entfernt nur einen Eintrag, dessen Karte schon weg ist,
  nie den einer neueren Karte mit demselben Schlüssel (vorher möglich). Test
  `shell/tests/settings-search-cards.test.mjs`. Die begleitende Meldung `SettingsRow.qml[139:5]:
  Cannot find member data` stammt vermutlich aus derselben abgebrochenen Erzeugung (Qt hängt die
  Registrierung an `data` einer schon abgebauten Zeile) und lässt sich im QML nicht abfangen; da
  der Fehler sporadisch ist, beweist ein sauberer Lauf das Verschwinden nicht. Bei erneutem
  Auftreten hier nachtragen.
  **Wieder aufgetreten** (allein, ohne den TypeError): KWin-Lauf zu `d3343e9` (Commit ändert
  nur zwei unbenutzte SVG-Dateien im Dienst), 1 von 30 Läufen seit der Behebung. Bleibt eine
  sporadische Meldung beim Abbau der Einstellungsseiten; nicht in der Grundlinie. Möglicher
  nächster Schritt: Registrierung als Eigenschaft statt als Kind in `data` anhängen und über
  viele Läufe vergleichen.
  **Erledigt – Halt nach D7 (22.11.2026):** In der Variante «offen» unter Hyprland erschien die Meldung auf
  dem Endstand in 1 von 3 Läufen, auf `ba4ddbc` in 0 von 3. Sie ist kein Fehler aus D7: Der Fund
  oben auf `d3343e9` liegt 29 Commits vor `ba4ddbc`. Ein `git bisect` zwischen `ba4ddbc` und dem
  Endstand hätte darum keinen verlässlich «guten» Anfang und wurde nicht gefahren (ein Lauf dauert
  gut 5 Minuten; bei einer Rate um ein Drittel bräuchte jeder Schritt viele Läufe und bliebe
  unsicher). Behoben an der Ursache: `SettingsRow`, `SettingsCard` und `IslandHomeLayoutEditor`
  halten die Registrierung als Eigenschaft (`readonly property SettingsSearchRegistration …`),
  Qt hängt sie nicht mehr über `data` an. Belegt ist die Behebung durch den Strukturtest in
  `tests/test_werte.py` (keine Registrierung mehr als Kind); die Messläufe danach stützen sie nur,
  weil bei einer Rate um ein Drittel wenige Läufe allein nichts beweisen (Plan 0.8 Nr. 76).
- Seit D3 (`bca3795`) meldet Qt beim Anmelden am Portal `App info not found for
  'io.github.alpe_shell.Alpe'` statt `Connection already associated with an application ID`: Zur
  neuen App-ID gibt es noch keine Desktop-Datei. In beiden Fällen scheitert die Anmeldung, wie
  bisher in der Testumgebung. Die Grundlinien sind entsprechend nachgeführt; mit der
  Desktop-Datei aus dem Paket (E1) sollte die Zeile verschwinden – dann prüfen, ob Portale
  (Dateiauswahl, Bildschirmfreigabe) die Shell richtig zuordnen.
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
  ~~`CompositorService.toggleOverview`, `workspaceSecondaryAction`~~ samt
  `overviewActiveForScreen` erledigt in C6. Der Rechtsklick aufs Dock-Launcher-Symbol tut
  weiterhin nichts (öffnete die niri-Übersicht); Vorschlag nach Phase A: Hyprland-Übersicht wie
  beim Rechtsklick auf den Arbeitsflächen-Umschalter.
- **Noch offen (nicht C6):** `CompositorService.overviewActiveOnScreen` ist ebenfalls konstant
  `false`; daran hängen die Einstellungen `openOnOverview` (Leiste, Dock) und
  `frameShowOnOverview`, die damit nichts bewirken. Entfernen hiesse sichtbare Optionen
  streichen (mit D5/D6 und Migration) oder an die Hyprland-Übersicht hängen – Entscheid des
  Maintainers.
- ~~`DBarBody.fullscreenAutoHide`-Kette~~ erledigt in C6.
- ~~`KeybindsService._bindsStale`~~ erledigt in C6 (die Zählung `addRef`/`removeRef` bleibt, wird aber nicht ausgewertet).
- Allgemein genutzte Helfer mit niri im Namen umbenennen (Phase D):
  `OutputModel.niriIdentifier`, `formatNiriMode`; Bedingungsschlüssel
  `isHyprlandOrNiri`/`isNiriOrMango`, Eintrag `hyprlandNiriOnly`.

## Werkzeuge

- ~~`extract_settings_index.py` bricht ab~~ erledigt in D6 (`eab4f12`): Alpe-Seiten werden
  ausdrücklich übersprungen (sie kommen zur Laufzeit dazu), Index neu erzeugt.
- ~~`entwicklung/lint.sh`~~ und die Hand-Harnesse `pageharness/th.qml`, `td2.qml`, `tl2.qml`
  (tote Pfade in ein fremdes Home-Verzeichnis) entfernt in C6. ~~Übrig:
  `shell/Modules/Lock/Alpe/layout.js` nennt als Herkunft einen solchen Pfad~~ erledigt in
  `56fcedd`: aus `lockscreen/hyprlock.conf` neu erzeugt, ohne Pfad und Datum; seither prüft
  `tests/test_werte.py` das ganze Repo auf persönliche Werte.
- `entwicklung/pageharness/qs/` enthält veraltete Kopien (`SettingsTabs.qml`,
  `CompositorService.qml`-Attrappe mit `isNiri`).
- ~~Übersetzungen mit Texten entfernter Seiten~~ bereinigt in D6 (`f2a34f7`).
- Assets `discord.svg`, `reddit.svg`, `matrix-logo-white.svg` sind unbenutzt bzw. nur noch
  für den Discord-Link des Ursprungs da (Entfernen laut 4.3 in C4).
