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

**Anleitung für den Stand nach D7 (Halt nach D7.8, 22.11.2026; überarbeitet am 23.11.2026 und nach dem Test am 24.11.2026).**
Eigenständiger Ablauf – die Befehle der Anleitung für D6 werden hier nicht mehr vorausgesetzt.
Getestet wird in der echten Hyprland-Sitzung; `~/alpe` bleibt unberührt. Seit D7.8 gibt es keine
Hüllen mehr: Ein fremdes Plugin lädt nur noch in der angepassten Fassung.

**Nicht auslösen: die Sperre.** Mit der Testshell wird am Mac nicht gesperrt – kein Sperr-Kürzel,
kein Eintrag «Sperren» im Energiemenü, den Deckel während des Tests nicht schliessen. Die Sperre
ist durch die Ladeprüfung am PC abgedeckt (Variante «gesperrt»); schlägt sie in der echten
Hyprland-Sitzung fehl, bleibt nur der Notbildschirm von Hyprland. Ebenso wie bei D6: die Knöpfe
«Einrichten»/«Einbinden» nicht drücken, «Neu starten» im Energiemenü nicht auslösen.

*Ergebnis (eingetragen am 24.11.2026 nach den Angaben des Maintainers):*

| | |
|---|---|
| Getesteter Commit | `b04b1bf` |
| Datum | 23.11.2026 |
| Hyprland, Fedora, Quickshell | Hyprland 0.57.2, Fedora Asahi Remix 45, Quickshell 0.3.2 (COPR `avengemedia/quickshell`) |
| Ergebnis | **In Ordnung.** Verbindung zum Dienst (`Connected`), WLAN-Liste, Bluetooth, Helligkeitsregler, Systemmonitor-Widgets, hueManager und calculator (angepasste Fassungen, Rechner samt Kopieren), Alpe-Zeichen (Starter-Knopf, Material «Alpe», Punkt), Über-Seite, Kürzel-Kategorie «Alpe», Fensterregeln, Notizblock «Pfad kopieren», Einstellungssuche (0 × «Cannot find member data»), Bildschirmfoto über `alpe-dienst screenshot region` samt Zwischenablage, Layer `alpe:screenshot`, IPC `spotlight`/`processlist`/`dash`/`settings`, Migration `settings` v42→44 und `session` v7→8 mit den Sicherungen `settings.v42.json` und `session.v7.json`. Keine Meldungen «is not a type», «not installed», «deprecated», keine `TypeError`/`ReferenceError`. |
| Kürzel aus `hypr/dms/binds.lua` | `dms ipc call …` und `dms screenshot …` greifen erwartungsgemäss nicht; das schreibt F1 um. |
| Papierkorb Durchgang 1 (ohne kora) | **entfällt:** kora ist am Mac als Systempaket installiert (`kora-icon-theme-2.0.6-1.20260824git7a75842.fc43`, fremdes COPR `hazel-bunny/ricing`). Der Befund zu Adwaita ist durch die Ladeprüfung am PC belegt. |
| Papierkorb Durchgang 2 (kora 2.0.6) | Thema «kora»: **kein Quadrat**, leer und voll. |
| Dock-Fläche auf dem Hintergrund des Macs | nicht gesondert beurteilt; das Dock nur mit Papierkorb wirkt gut. Der Entscheid «so lassen» bleibt. |
| Nachtlicht | **keine sichtbare Wirkung** am internen Bildschirm, obwohl der Dienst «Wayland gamma control initialized successfully» meldet; unter 1.0 gleich. Plattform-Fall, siehe unten. |
| `dnf info breeze-icon-theme` | `breeze-icon-theme` 6.32.0-1.fc45 ist verfügbar, am Mac nicht installiert. Der Paketname für E4 ist damit bestätigt. |
| kora nach dem Test | unverändert (Systempaket, nichts im Home angelegt) |

**Plattform-Fall ohne Frist: Nachtlicht am internen Bildschirm des MacBooks.** Der Dienst bindet
`wlr-gamma-control` erfolgreich («Wayland gamma control initialized successfully»), das Einschalten
des Nachtlichts ändert das Bild aber nicht – unter 1.0 genauso, also kein Fehler aus Phase A.
Vermutung (nicht belegt): Der Bildschirmtreiber von Asahi setzt die Gamma-Tabelle nicht um.
Hyprland nimmt die Tabelle an, darum meldet der Dienst keinen Fehler und kann den Fall nicht
erkennen. Nichts zu tun in Phase A; neu ansehen, wenn sich am Treiber etwas ändert.

**Zwischenfall beim Mac-Test (23.11.2026, behoben; Ursache: die Anleitung).** Beim Anpassen der
Plugins lief am Mac der Block für sathiAi aus `docs/plugins-anpassen.md`, obwohl es sathiAi dort
nicht gibt. `cp` und `cd` scheiterten; die drei folgenden `sed -i`-Zeilen mit dem relativen Muster
`**.qml` liefen darum im Home-Verzeichnis und schrieben alle `.qml`-Dateien in nicht versteckten
Ordnern neu – darunter `~/dux-shell` (der laufende Baum von 1.0) und `~/alpe`. Quickshell lud den
laufenden Baum sofort neu und scheiterte («Config reload failed»). Alles ist über `git restore`
zurückgeholt und mit `git status` und `grep` geprüft; 1.0 läuft wieder ohne Ladefehler.
Lehren, umgesetzt am 24.11.2026:

- `docs/plugins-anpassen.md` kennt kein `cd` und keine relativen Muster mehr; jeder `sed`-Befehl
  nennt den absoluten Pfad, über jedem Block steht der Rechner und ein Prüfbefehl, ob das Plugin
  überhaupt da ist.
- Ein laufender Baum wird von Quickshell bei jeder Dateiänderung neu geladen. Umzug (F1) und
  Aktualisierung (E4) dürfen ihn darum nie in Teilschritten verändern (Plan 10, F1 und E4).
- Die Mac-Test-Anleitung unten ist nach den Erfahrungen dieser Runde überarbeitet (Stand holen
  auf einen festen Hash, `lockAtStartup`, hypridle/hyprsunset, Rückbau mit Prüfungen).

**Für den nächsten Mac-Test zusätzlich zu prüfen (Auftrag des Maintainers vom 24.11.2026).** Diese
Punkte kommen zur Anleitung unten hinzu; sie betreffen Änderungen der Runde nach dem Mac-Test
(`899fefc`, `19a16c4`, `09021df`) und zwei Beobachtungen am Bild der Sperre.

1. **hyprlock ohne `eDP-1`:** `lockscreen/hyprlock.conf` nennt seit `899fefc` in keiner
   `monitor`-Zeile mehr einen Bildschirm (vorher dreimal `eDP-1`). **Geprüft werden muss genau diese
   Datei aus dem ausgecheckten Stand** – nicht die Dateien, die am Mac schon liegen: Das Programm
   hyprlock liest sonst `~/.config/hypr/hyprlock.conf`, und nichts kopiert die Vorlage von selbst
   dorthin (nur die Einstellungsseite schreibt die Datei, auf Benutzeraktion). Die Shell-Sperre
   liest gar keine `hyprlock.conf`: Sie nimmt das in den Einstellungen gespeicherte Layout
   (`alpeLockLayout`), sonst das mitgelieferte `layout.js`; den Vorrang einer eigenen
   `~/.config/alpe/hyprlock.conf` gibt es nur in `tools/lockscreen.sh` (KDE-Sperre) und beim
   Design-Export. Ein Test ohne ausdrückliche Angabe der Datei prüfte den alten Stand mit
   `eDP-1` und wäre immer grün. Zu prüfen: Mit der Vorlage aus dem Repo zeigt hyprlock Hintergrund,
   Uhr, Datum und Passwortfeld am internen Bildschirm und – falls angeschlossen – an einem zweiten;
   die Ausgabe von hyprlock (im Terminal, nicht im Journal) nennt keinen Fehler zu `monitor`.
   ~~**Offen beim Maintainer:** der Aufruf (wie hyprlock die Repo-Datei übergeben bekommt; die Option
   dafür ist hier nicht nachgeschlagen) und der Rückweg, falls die Sperre hängt.~~ **Entschieden am
   25.11.2026 (Maintainer):** hyprlock wird **in der echten Sitzung** mit `hyprlock --config` und der
   Datei aus dem ausgecheckten Stand gestartet. **Vorher** eine zweite Anmeldung als Rückweg öffnen
   (TTY oder SSH) und mit `hyprlock --help` prüfen, dass die installierte Fassung die Option `--config`
   kennt (an der Quelle belegt: `-c`/`--config` spätestens seit hyprlock v0.4.0, `src/main.cpp`). Am Mac, ein
   Befehl pro Zeile:

   ```
   hyprlock --help
   hyprlock --config ~/alpe-phase-a/lockscreen/hyprlock.conf
   ```

   **Rückweg, wenn die Sperre hängt (berichtigt am 25.11.2026):** Wird hyprlock beendet, **bleibt die
   Sitzung gesperrt** – Hyprland hält sie nach dem Protokoll ext-session-lock fest und zeigt einen roten
   Bildschirm, der die Befehle zur Wiederherstellung nennt. Von der zweiten Anmeldung aus genau diese
   Befehle ausführen. Wortlaut als Beispiel für die Hyprlang-Konfiguration (aus der Hyprland-Diskussion
   #14395; nicht am Mac gesehen):

   ```
   hyprctl --instance 0 'keyword misc:allow_session_lock_restore 1'
   hyprctl --instance 0 dispatch exec -- hyprlock
   ```

   Unter der Lua-Konfiguration (Hyprland ab 0.55 – aus einem Forenbeitrag, nicht an der Quelle gelesen)
   lauten sie anders; massgeblich ist, was der rote
   Bildschirm nennt. Welche Hyprland-Fassung und welche Konfigurationsart am Mac laufen, ist hier nicht
   nachgeschlagen. Muss hyprlock selbst beendet werden, dann nur über seine PID, nie über den Namen.
   **Erwartet** (aus dem Quelltext gefolgert, nicht gemessen): `hyprlock.conf` setzt `general { grace = 1 }`;
   ab hyprlock v0.9.0 gibt es diese Option nicht mehr, eine neuere Fassung meldet darum «Config has
   errors … Proceeding ignoring faulty entries» zu `grace` – das ist kein Fehler zu `monitor`. Der Block
   `background` hat kein `path` (nur Farbe), und `AlfaSlabOne` liegt nur unter
   `shell/Modules/Lock/Alpe/fonts`; ohne systemweite Installation nimmt hyprlock eine Ersatzschrift. Das
   Bild sieht also anders aus als die Shell-Sperre; für die Prüfung von `monitor` ist das unerheblich.
   (Ergänzung, vorsichtige Lesart:) Nennt `hyprlock --help` die Option nicht, wird der Punkt nicht
   geprüft und notiert. Ob am Mac je hyprlock mit dieser Vorlage lief, ist nicht belegt. **Hinweis für F1:** Wer das Programm
   hyprlock mit einer eigenen `~/.config/hypr/hyprlock.conf` benutzt, behält dort `eDP-1`; die
   Änderung aus `899fefc` erreicht diese Datei nicht von selbst. Für die Punkte 4 und 5 gilt
   entsprechend: Ein am Mac gespeichertes `alpeLockLayout` hätte Vorrang vor `layout.js` – ob dort
   eines gesetzt ist, ist nicht belegt.
2. **matugen-Vorlagen aus:** Das ausgelieferte Design schaltet seit `19a16c4` die Vorlagen für
   Firefox, Neovim, Zen und Zed aus (Plan 0.8 Nr. 104). **Im Ablauf der Anleitung
   unten am Mac nicht prüfbar:** Sie kopiert die bestehenden Einstellungen (Schritt 3), ein frisch
   eingespieltes Design kommt dort nicht vor, und bestehende Einstellungen bleiben, wie sie sind.
   Prüfbar ist der Punkt erst mit einem frischen Stand – mit E4 bzw. dem Installationstest (VM am
   PC, frisches Fedora Asahi) oder in einem Temp-`HOME`: Dann stehen die vier Schalter in den
   Einstellungen auf «aus». Am Mac bis dahin nur festhalten, dass sich an den vorhandenen
   Schaltern nichts geändert hat.
3. **CUPS-Rückzug:** Der Dienst meldet einen Ausfall von CUPS seit `09021df` einmal und versucht
   es dann in wachsenden Abständen (5 s bis 1 min) wieder. Am Mac läuft kein CUPS; der
   Punkt zeigt sich dort beim gewöhnlichen Start der Testshell. Zu prüfen im Protokoll der
   Testshell (die Anleitung schreibt es nach `/tmp/alpe-d7.log`, nicht ins Journal): Die Warnung
   `Failed to initialize cups manager: … (further attempts are not reported; retrying quietly with
   back-off)` steht nach einigen Minuten genau einmal –
   `grep -c "Failed to initialize cups manager" /tmp/alpe-d7.log` ergibt 1; vor `09021df`
   schrieb jeder Versuch eine Warnung. Ergibt der Befehl 0, war CUPS erreichbar (etwa über
   `cups.socket`) – das ist kein Fehlschlag, der Punkt ist dann nur nicht geprüft. **Nicht Teil der Prüfung, weil nicht belegt:** dass sich
   der Dienst nach einem späteren Start von CUPS von selbst wieder verbindet. Der Rückzug ist
   passiv – einen neuen Versuch gibt es erst, wenn die Oberfläche wieder eine Anfrage oder ein
   Abonnement schickt und die Pause abgelaufen ist; ob sie das von selbst tut, hat niemand
   gemessen, ebenso wenig, ob unter Fedora ein gestoppter `cups.service` bei aktivem `cups.socket`
   genügt.
4. **Passwortfeld im Bild der Sperre:** Im Haltbild der Test-Instanz (1280 × 720) ist das Feld
   nur rund 85 Pixel breit und gut 20 hoch, der Platzhalter kaum lesbar, und der Mauszeiger liegt
   in beiden Haltbildern vom 24.11.2026 genau darauf. Ursache ist der Massstab (`size = 200, 50` auf dem Bezugsbildschirm
   2560 × 1664). Zu prüfen am Bildschirm des MacBooks (2560 × 1664): Breite und Lesbarkeit des
   Felds und des Platzhalters. **Entschieden am 25.11.2026: erst nach F1 an der Shell-Sperre zu
   beurteilen**, nicht in diesem Mac-Test.
5. **Streifen im Bild der Sperre:** Im oberen Viertel des Haltbilds stehen feine waagrechte
   Farbstufen im Himmel (Unschärfe, Helligkeit und Kontrast aus `hyprlock.conf` auf 8 Bit je
   Kanal). Zu prüfen am Mac: ob die Streifen auf echter Hardware sichtbar sind. **Entschieden am
   25.11.2026: erst nach F1 an der Shell-Sperre zu beurteilen**, nicht in diesem Mac-Test.
6. **Die drei sporadischen Meldungen** (Plan 0.8 Nr. 107; am PC nur unter Last beobachtet): Nach dem
   Start der Testshell ihr Protokoll durchsehen – die Anleitung unten schreibt es nach
   `/tmp/alpe-d7.log`; läuft die Shell später als Dienst (`alpe.service`, erst mit dem Paket), steht es
   im Journal (`journalctl --user -u alpe.service -b`), und dieselbe Suche gilt dort. Gesucht: Notizblock «Tab file does not exist» (samt der
   `FileView`-Zeile dazu), `DeferredAction.qml` «Cannot read property 'stop' of null», ShaderEffect
   «'source' does not have a matching property». Die `FileView`-Zeile lautet «Read of
   …untitled-<ID>.txt failed: File does not exist.» (`grundlinie-hyprland.txt`). Die erste Zeile zählt,
   die zweite zeigt die Zeilen mit Nummer; jede Zahl über 0 mit den Zeilen selbst notieren:

   ```
   grep -c -e "Tab file does not exist" -e "Cannot read property 'stop' of null" -e "'source' does not have a matching property" -e "txt failed: File does not exist" /tmp/alpe-d7.log
   grep -n -e "Tab file does not exist" -e "Cannot read property 'stop' of null" -e "'source' does not have a matching property" -e "txt failed: File does not exist" /tmp/alpe-d7.log
   ```
7. **Keine Zeile «Unrecognized pragma»** (Plan 0.8 Nr. 97: die Pragmas `RenderControl` und
   `DiskCache` sind aus `shell/shell.qml` entfernt). Erwartet: 0.

   ```
   grep -c "Unrecognized pragma" /tmp/alpe-d7.log
   ```
8. **Werteprüfung und ein kurzer Benutzername:** Ist der Benutzername am Mac kürzer als vier
   Zeichen, sucht die Werteprüfung (`tools/werte-pruefen.py`, `tests/test_werte.py`) ihn nur im
   Zusammenhang (`nutzer@…`, Pfad in ein Home, Hostname-Feld …) und in Binärdateien roh gar nicht
   (`docs/technik.md`, Absatz «Binärdateien» der Werteprüfung; Kopf und `roh_funde` von
   `tools/werte-pruefen.py`). Namen unter zwei Zeichen und Allerweltsnamen (`user`, `nutzer`, `root` …)
   werden gar nicht gesucht. Ein grüner Abschnitt `test_werte` sagt über einen solchen Namen also
   weniger als über einen längeren – beim Lesen des Ergebnisses beachten. **Den Abschnitt `test_werte`
   aus Schritt 2 festhalten** (Ausgabe von `tools/test.sh` dort, die Zeilen unter `== tests/test_werte.py`;
   Entscheid vom 25.11.2026).
9. **Priorität der COPR-Repos** (Plan 0.8 Nr. 99): Ausgabe von `dnf repolist -v` festhalten, vor
   allem die Angabe zur `priority` der COPR-Repos (`hazel-bunny/ricing` und weitere). **Berichtigt am
   25.11.2026 (an der Quelle nachgeschlagen):** dnf5 – unter Fedora seit 41 das `dnf` (nicht an der Quelle gelesen) – kennt keine
   globale Option `-v` (Handbuch `dnf5(8)`: nur `-q`), und `repo list` kennt nur `--all`, `--enabled`,
   `--disabled`, `--json` (`dnf5-repo(8)`); `repolist` ist ein Alias für `repo list`, `repoinfo` einer für
   `repo info` (`aliases.d/compatibility.conf`). Die Priorität zeigt `repo info` (Zeilen «Priority» und
   «Cost», `libdnf5-cli/output/repo_info.cpp`). Dass am Mac dnf5 läuft, ist gefolgert, nicht dort
   gesehen. Darum zwei Zeilen: die vorgegebene (deren Ausgabe zeigt zugleich, welches dnf läuft; ein
   Argumentfehler ist dann zu erwarten) und `dnf repoinfo` für Priorität und Kosten:

   ```
   dnf repolist -v
   dnf repoinfo
   ```
10. **Sperre der Shell mit dem Bergbild, ohne Videocache** (Entscheid vom 25.11.2026; Plan 0.8 Nr. 106, Standbild
    `design/kde/bilder/jagged-peaks-wolkenzug.jpg`): Die Sperre der Shell zeigt das Bergbild, und im Ordner
    `~/.cache/alpe/video-wallpaper` **entsteht nichts Neues** (das Standbild kommt aus dem Design, `ffmpeg` wird nicht
    gebraucht). Am PC ist die Sperre mit dem Standbild in der Haltprüfung abgedeckt (Hyprland «gesperrt» im
    Temp-HOME); am Mac geht es um die **echte, umgezogene Sitzung** (dort gibt es `ffmpeg-free`). Die Testshell darf in
    diesem Test nicht sperren (Regel oben in der Anleitung, «Nicht auslösen: die Sperre») – darum **nach F1 an der
    Shell-Sperre**. **Vorbedingungen** (sonst gilt der Punkt als nicht prüfbar, mit Verweis auf Plan 0.8 Nr. 106
    (iii)): Der Hintergrund ist das Video des Designs (`wallpaperPath` in `~/.config/alpe/settings.json`), und neben
    dem Video liegt im Ordner des Designs das `.jpg` (das Standbild greift nur für Videos unter
    `~/.local/share/alpe/design/` mit `.jpg` daneben; wer aus 1.0 kommt, hat dort nur das `.mp4`, bis das Design neu
    eingespielt ist). Den Cache **vor F1** festhalten, weil ihn frühere Tests am Mac schon angelegt haben können (der
    Rückbau räumt `~/.cache/alpe` nicht ab):

    ```
    grep -o '"wallpaperPath": *"[^"]*"' ~/.config/alpe/settings.json
    ls -l ~/.local/share/alpe/design/kde/bilder/ ~/.local/share/alpe/design/hyprland/bilder/
    ls -l --time-style=full-iso ~/.cache/alpe/video-wallpaper
    ```

    Nach F1 und einer Sperre dieselbe letzte Zeile noch einmal. Erwartet: keine Datei, die nach F1 entstanden ist
    (oder weiterhin «Datei oder Verzeichnis nicht gefunden»). Ob der Ordner vorher gelöscht wird, entscheidet der
    Maintainer.
11. **PAM-Dienste nach F1** (Entscheid vom 25.11.2026; Plan 0.8 Nr. 118): **Vorher** eine zweite Anmeldung als
    Rückweg öffnen (TTY oder SSH). Dann die Dienste ansehen und die Sperre der Shell mit dem Passwort entsperren (mit
    U2F, falls eingerichtet):

    ```
    ls -l /etc/pam.d/dankshell /etc/pam.d/dankshell-u2f /etc/pam.d/alpe /etc/pam.d/alpe-u2f
    grep -c "LOCKSCREEN AUTH" /etc/pam.d/dankshell /etc/pam.d/alpe
    ```

    Die zweite Zeile zeigt, ob ein Dienst verwaltet ist (2 = Block vorhanden) oder eigen (0). Gibt es eine **eigene**
    `dankshell` (ohne den Block «DMS LOCKSCREEN AUTH») und keine `alpe`, meldet
    `alpe-dienst auth sync` «Custom /etc/pam.d/dankshell from Alpe 1.0 found and no /etc/pam.d/alpe …», legt `alpe`
    nicht an, und die Sperre entsperrt weiter über `dankshell` (Hinweis der Prüfung zu 1.6 im Nachtlauf vom
    26.11.2026). Die Meldung steht in der Ausgabe von `alpe-dienst auth sync` (eigener Aufruf oder Ausgabe des
    Umzugs). **Risiko bei F1:** Gehört `dankshell` dem Paket von 1.0 und nimmt die Paketentfernung sie weg, gibt es
    danach weder `dankshell` noch `alpe` – dann bleibt nur der Rückweg über die zweite Anmeldung. Darum vorher Punkt 13
    (`rpm -qf` auf die PAM-Dienste).
12. **`alpe-dienst doctor --verbose` nach F1 ohne laufende Shell** (Entscheid vom 25.11.2026; Plan 2.6 von E1):
    erwartet «Alpe Configuration» = `/usr/share/alpe/shell`; dabei `XDG_DATA_DIRS` der Hyprland-Sitzung festhalten.
    Die Erwartung gilt nur, wenn es weder `~/.config/quickshell/alpe` noch `~/.local/share/alpe/shell` gibt (beide gehen
    vor, `core/internal/config/shellconfig.go`). «Ohne laufende Shell»: vorher `systemctl --user stop alpe.service`,
    danach wieder `start` (führt der Maintainer aus).

    ```
    ls -d ~/.config/quickshell/alpe ~/.local/share/alpe/shell
    alpe-dienst doctor --verbose
    echo $XDG_DATA_DIRS
    ```
13. **Weitere Punkte aus dem Nachtlauf vom 26.11.2026** (Hinweise der Prüfungen zu 1.4, 1.7 und 1.8):
    `rpm -q sound-theme-freedesktop` (~~könnte die Shell die freedesktop-Klänge aus dem Paket nehmen?~~ seit Plan
    0.8 Nr. 128 nimmt sie sie daraus – Paketname und `ls /usr/share/sounds/freedesktop/stereo/` am Mac bestätigen);
    `ls -l /etc/dms /usr/share/dms` und, falls vorhanden, `rpm -qf /etc/dms/cli-policy.json` (Rückfall der
    Richtlinie, Plan 0.8 Nr. 119 – gehört die Datei einem Paket von 1.0, vor dessen Entfernung bei F1 nach
    `/etc/alpe` kopieren; ob sie dort `%config(noreplace)` ist, zeigt `rpm -qc <Paket>`); `systemctl --user cat
    dms.service` (trägt die Unit des Pakets von 1.0 am Mac `BusName=`? Siehe «Installationstest in der VM (Liste)»,
    Punkt 1; ob neben `alpe.service` ein anderer Mitteilungsdienst läuft – mako, swaync, dunst –, siehe dort Punkt 2);
    `rpm -qf /etc/pam.d/dankshell /etc/pam.d/dankshell-u2f` (gehören die PAM-Dienste von 1.0 einem Paket? Siehe
    Punkt 11, Risiko bei F1).

Zu 1: Dieser Punkt braucht die Sperre durch das Programm hyprlock in der echten Sitzung (siehe 1).
Die Anleitung unten verbietet, mit der **Testshell** zu sperren («Nicht auslösen: die Sperre») – das
gilt weiter. Die Punkte 4 und 5 (Passwortfeld, Streifen) entfallen in diesem Mac-Test; sie werden
nach F1 an der Shell-Sperre beurteilt, ebenso die Punkte 10 bis 12 (Nachtlauf vom 26.11.2026). Punkt 13 geht schon
jetzt (nur lesend). Nichts davon ändert `layout.js` oder `hyprlock.conf`.

*Am PC (Maintainer):*

```
git -C ~/alpe-phase-a push origin phase-a
```

*Vor allem anderen – Stand holen und auschecken,* damit `docs/plugins-anpassen.md` und diese
Anleitung im neuen Stand gelesen werden. Ausgecheckt wird der **konkrete Hash**, den der PC nach
dem Push nennt (`git -C ~/alpe-phase-a rev-parse --short HEAD` am PC), nicht `origin/phase-a`: Ist
`~/alpe` nur für `main` geklont, aktualisiert `fetch origin phase-a` nur `FETCH_HEAD`, und
`origin/phase-a` bliebe auf dem alten Stand stehen. In der zweiten Zeile `HASH` ersetzen; die
dritte muss denselben Hash zeigen:

```
git -C ~/alpe fetch origin phase-a
git -C ~/alpe-phase-a checkout --detach HASH
git -C ~/alpe-phase-a rev-parse --short HEAD
```

(Gibt es den Worktree noch nicht: `git -C ~/alpe worktree add --detach ~/alpe-phase-a HASH`.)

*Schritt 0, einmalig und bleibend – vor dem Sichern:* die angepassten Fassungen von hueManager
und calculator unter `~/.config/alpe/plugins` anlegen, genau nach `docs/plugins-anpassen.md`
**im eben ausgecheckten Stand**: die Blöcke «hueManager» und «calculator», je mit den beiden
Prüfbefehlen vorweg; **den Block «sathiAi» am Mac nicht ausführen** (Zwischenfall vom 23.11.2026).
Liegen die angepassten Fassungen von der letzten Runde schon dort, entfällt der Schritt bis auf
das Prüfen. Die Kopien unter `~/.config/dms/plugins` bleiben unverändert, 1.0 läuft damit weiter.
Weil das vor dem Sichern geschieht, liegen die angepassten Fassungen auch in
`~/.config/alpe.vor-d7` und überstehen das Zurückholen am Ende. Prüfen wie in
`docs/plugins-anpassen.md`, «Prüfen». Die ersten beiden Befehle geben nichts aus; die Treffer des
dritten und vierten sieht man von Hand durch (Texte und Kommentare sind unbedenklich, ein Aufruf
des Programms `dms` nicht):

```
grep -rn -E --include='*.qml' --include='plugin.json' '\bDank[A-Z]|qs\.DCommon|qs\.Modules\.DDash|\["dms"|requires_dms|dankbar-widget' ~/.config/alpe/plugins/hueManager
grep -rn -E --include='*.qml' --include='plugin.json' '\bDank[A-Z]|qs\.DCommon|qs\.Modules\.DDash|\["dms"|requires_dms|dankbar-widget' ~/.config/alpe/plugins/calculator
grep -rn -i -w --exclude-dir=.git 'dms' ~/.config/alpe/plugins/hueManager
grep -rn -i -w --exclude-dir=.git 'dms' ~/.config/alpe/plugins/calculator
```

Typen ohne Import, zwei kurze Befehle ohne Pipe: Der erste nennt die Dateien von hueManager mit
einem `Alpe…`-Typ, der zweite die Dateien ohne `import qs.Alpe.Widgets`. **Keine Datei aus der
ersten Liste darf in der zweiten stehen.** (Der calculator benutzt keine solchen Typen.)

```
grep -rlE --include='*.qml' '\bAlpe[A-Z]' ~/.config/alpe/plugins/hueManager
grep -rL --include='*.qml' 'import qs.Alpe.Widgets' ~/.config/alpe/plugins/hueManager
```

Die alten Kopien sind unverändert (ist eine davon kein Git-Klon, der Ausweg mit `diff -rq` aus
`docs/plugins-anpassen.md`):

```
git -C ~/.config/dms/plugins/hueManager status --short
git -C ~/.config/dms/plugins/calculator status --short
```

*Schritt 1 – alte Sicherungen.* Die Sicherungen dieser Runde heissen `.vor-d7`. Zuerst nachsehen,
ob von der Runde D6 noch Sicherungen liegen oder ob es die neuen Namen schon gibt:

```
ls -d ~/.config/dms.vor-phase-a ~/.config/hypr.vor-phase-a ~/.config/alpe.vor-phase-a ~/.local/state/alpe.vor-phase-a
ls -d ~/.config/dms.vor-d7 ~/.config/hypr.vor-d7 ~/.config/alpe.vor-d7 ~/.local/state/alpe.vor-d7
```

Meldet `ls` für alle «nicht gefunden», ist nichts da. Liegt eine alte Sicherung noch dort: selbst
ansehen, ob sie noch gebraucht wird, und sie wegräumen oder umbenennen, **bevor** neu gesichert
wird. `cp -r` in einen vorhandenen Ordner legt die neue Kopie sonst *in* den alten Ordner, und
beim Zurückholen käme der alte Stand zurück. Ordner mit `.vor-d7` aus einem abgebrochenen Versuch
ebenso zuerst wegräumen.

*Schritt 2 – sichern, prüfen, bauen* (Hypr-Ordner mit, weil die Shell darin schreibt; geholt und
ausgecheckt ist schon, siehe oben; kein `cd`, gebaut wird mit `make -C`):

```
cp -r ~/.config/dms ~/.config/dms.vor-d7
cp -r ~/.config/hypr ~/.config/hypr.vor-d7
cp -r ~/.config/alpe ~/.config/alpe.vor-d7
cp -r ~/.local/state/alpe ~/.local/state/alpe.vor-d7
git -C ~/alpe-phase-a rev-parse --short HEAD
bash ~/alpe-phase-a/tools/test.sh
make -C ~/alpe-phase-a/core dev BUILD_DIR=/tmp/alpe-d7
/tmp/alpe-d7/alpe-dienst doctor
/tmp/alpe-d7/alpe-dienst --help
/tmp/alpe-d7/alpe-dienst dl --help
```

(Gibt es `~/.local/state/alpe` noch nicht, meldet das vierte `cp` nur «nicht gefunden».) Den
Hash aus der fünften Zeile oben in die Tabelle eintragen. Bei `tools/test.sh` meldet am Mac
`shell/tests/bluez-codec.test.mjs` zwei Tests als übersprungen, wenn `lua` nicht installiert ist;
das ist kein Fehlschlag. Bei `doctor` steht unter «Compositor»
Hyprland. `--help` zeigt oben den Schriftzug «ALPE» (nicht mehr «DMS»), `dl --help` bei
`--user-agent` den Vorgabewert `Alpe/1.0.0 (+https://github.com/alpe-shell/alpe)`.

*Schritt 3 – Dateien von 1.0 dazukopieren* (`-n`: nichts überschreiben, also auch nicht die
angepassten Fassungen aus Schritt 0):

```
systemctl --user stop dms.service
cp -rn ~/.config/dms/. ~/.config/alpe/
mkdir -p ~/.local/state/alpe
cp -rn ~/.local/state/dms/. ~/.local/state/alpe/
mkdir -p ~/.config/hypr/alpe
cp -rn ~/.config/hypr/dms/. ~/.config/hypr/alpe/
```

Sperrt 1.0 am Mac beim Start (`lockAtStartup`), täte es die Testshell auch. Der Vorgabewert ist
`false` (`shell/Common/settings/SettingsSpec.js`); die Shell schreibt den Schlüssel nur, wenn er
je umgestellt wurde. Nachsehen, **nur in der Kopie**:

```
grep -c lockAtStartup ~/.config/alpe/settings.json
grep lockAtStartup ~/.config/alpe/settings.json
```

- Zählt der erste Befehl 0, **fehlt der Schlüssel** (so am 23.11.2026): Es gilt die Vorgabe
  `false`, die Testshell sperrt nicht, nichts zu tun – das `sed` unten griffe ins Leere.
- Zeigt der zweite `"lockAtStartup": false`: nichts zu tun.
- Zeigt er `"lockAtStartup": true`: in der Kopie ausschalten und nachsehen, dass danach `false`
  dasteht:

```
sed -i -E 's/"lockAtStartup": *true/"lockAtStartup": false/' ~/.config/alpe/settings.json
grep lockAtStartup ~/.config/alpe/settings.json
```

*Schritt 4 – Plugins aus dem Repo statt der alten Kopien* (Plan 0.8 Nr. 32). Das Repo liefert
vier Plugins: `alpeMeteoSwiss`, `alpeRadar`, `alpeSport`, `claudeCodeUsage`. Alte Kopien davon
aus 1.0 laden unter 1.1 nicht mehr und würden als Benutzerkopie die Repo-Fassung verdecken.
Welche am Mac als alte Kopie liegen (für die fehlenden meldet `ls` «nicht gefunden»):

```
ls -d ~/.config/dms/plugins/alpeMeteoSwiss ~/.config/dms/plugins/alpeRadar ~/.config/dms/plugins/alpeSport ~/.config/dms/plugins/claudeCodeUsage
```

Jede davon ist mit Schritt 3 auch nach `~/.config/alpe/plugins` gekommen. Dort zur Seite legen und
die Repo-Fassung einsetzen – alle vier Zeilen ausführen; für ein Plugin, das am Mac nicht liegt,
meldet `mv` nur «nicht gefunden»:

```
mkdir -p ~/.config/alpe/plugins.beiseite-d7
mv ~/.config/alpe/plugins/alpeMeteoSwiss ~/.config/alpe/plugins.beiseite-d7/
mv ~/.config/alpe/plugins/alpeRadar ~/.config/alpe/plugins.beiseite-d7/
mv ~/.config/alpe/plugins/alpeSport ~/.config/alpe/plugins.beiseite-d7/
mv ~/.config/alpe/plugins/claudeCodeUsage ~/.config/alpe/plugins.beiseite-d7/
cp -r ~/alpe-phase-a/plugins/alpeMeteoSwiss ~/.config/alpe/plugins/
cp -r ~/alpe-phase-a/plugins/alpeRadar ~/.config/alpe/plugins/
cp -r ~/alpe-phase-a/plugins/alpeSport ~/.config/alpe/plugins/
cp -r ~/alpe-phase-a/plugins/claudeCodeUsage ~/.config/alpe/plugins/
```

`~/.config/dms/plugins` bleibt unberührt; dort liest 1.0 weiter seine Kopien. Zurückgeholt wird
nichts einzeln: Der Rückbau am Ende entfernt `~/.config/alpe` ganz und setzt die Sicherung ein.

*Schritt 4a – hypridle und hyprsunset.* Beide belegen Dinge, die auch der Dienst anfasst
(`org.freedesktop.ScreenSaver`, Gamma). Nachsehen, ob und wie sie laufen:

```
systemctl --user is-active hypridle.service
systemctl --user is-active hyprsunset.service
pgrep -a hypridle
pgrep -a hyprsunset
```

- **Als Dienst laufend** (`active`): für den Test stoppen und im Rückbau (Schritt 7) wieder
  starten – in die Tabelle schreiben, welche es waren:

```
systemctl --user stop hypridle.service
systemctl --user stop hyprsunset.service
```

- **Über `exec-once` laufend** (`pgrep` nennt einen Prozess, `is-active` meldet `inactive`): laufen
  lassen. Der Dienst meldet dann nur als Hinweis, dass `org.freedesktop.ScreenSaver` schon einem
  anderen Prozess gehört («already owned by another process (e.g. hypridle/swayidle)»); so war es
  am 23.11.2026.
- Läuft keines: nichts zu tun.

*Schritt 5 – Testshell starten:*

```
/tmp/alpe-d7/alpe-dienst -c ~/alpe-phase-a/shell run 2>&1 | tee /tmp/alpe-d7.log
```

**Direkt nach dem Start** im zweiten Terminal – die Zahl muss 1 oder grösser sein, sonst hat sich
die Oberfläche nicht mit dem Dienst verbunden, und der Test sagt nichts aus (abbrechen, Protokoll
aufheben):

```
grep -c "Connected (API" /tmp/alpe-d7.log
```

Die Hyprland-Kürzel der 1.0-Einrichtung (`dms ipc call …`) erreichen die Testshell nicht; Aufrufe
im zweiten Terminal **immer mit vollem Pfad** – ein `alpe-dienst` ohne Pfad gibt es am Mac vor dem
Umzug nicht:

```
/tmp/alpe-d7/alpe-dienst ipc call spotlight toggle
/tmp/alpe-d7/alpe-dienst ipc call processlist focusOrToggle
/tmp/alpe-d7/alpe-dienst ipc call dash toggle overview
/tmp/alpe-d7/alpe-dienst ipc call dash toggle wallpaper
/tmp/alpe-d7/alpe-dienst ipc call settings focusOrToggle
/tmp/alpe-d7/alpe-dienst ipc call settings tabs
```

(`processlist focusOrToggle` öffnet den Systemmonitor.)
`/tmp/alpe-d7/alpe-dienst restart` lädt nur die Testshell neu und ändert nichts an `dms.service`.
Durchklicken wie bei D6 (Arbeitsflächen, Starter, Dock, Kontrollzentrum, Tastaturlayout,
Einstellungen → Tastenkürzel, Fensterregeln, Anzeige, Maus & Touchpad; Energiemenü nur öffnen;
`/tmp/alpe-d7/alpe-dienst screenshot window`; `notify-send test`).

Geräte und Dienst – am Mac zu prüfen, weil die Ladeprüfung am PC sie nicht abdeckt:

- **WLAN-Liste:** Kontrollzentrum → WLAN: Netze erscheinen, das verbundene ist markiert.
- **Bluetooth:** Kontrollzentrum → Bluetooth: gekoppelte Geräte erscheinen; bei einem verbundenen
  Kopfhörer die **Codec-Auswahl** öffnen (Liste der Codecs erscheint, Wechsel wirkt).
- **Helligkeitsregler:** Regler im Kontrollzentrum und die Helligkeitstasten ändern die
  Helligkeit des internen Bildschirms.
- **Systemmonitor-Widgets:** CPU-, Speicher- und Temperaturanzeigen der Leiste zeigen Werte (keine
  Striche); `/tmp/alpe-d7/alpe-dienst ipc call processlist focusOrToggle` öffnet die Prozessliste.

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
- **Bildschirmfoto und Pipette ohne Animation:** Start und Layer-Prüfung als **eine Zeile**:

  ```
  /tmp/alpe-d7/alpe-dienst screenshot region & sleep 2; hyprctl layers | grep alpe:
  ```

  Die Fläche heisst `alpe:screenshot` (Pipette: `alpe:eyedropper`, Plan 0.8 Nr. 75); sie soll ohne
  Einblenden erscheinen, wenn in der eigenen Hyprland-Datei eine Regel für `^alpe:.*` steht.
  Danach die Auswahl abschliessen und prüfen, dass das Bild in der Zwischenablage liegt.
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
- **Nachtlicht (eigener Prüfpunkt; seit der Behebung am Systembus hängt die Überwachung des
  Ruhezustands erst Augenblicke nach dem Start am Bus):** Das Nachtlicht einschalten (in der
  Oberfläche «Nachtmodus»: Kachel im Kontrollzentrum oder in den Einstellungen bei der Anzeige,
  Stichwort «Nachtmodus, Gamma, Kontrast»). Festhalten: Wird
  der **interne Bildschirm des MacBooks** sichtbar wärmer, sofort oder mit Übergang, und bleibt
  es dabei? Dann wieder ausschalten und festhalten, ob die Farbe zurückkommt. Danach das Protokoll
  auf Meldungen zu Gamma ansehen (zweites Terminal) und die Zeilen in die Tabelle übernehmen:

  ```
  grep -i -E "gamma|night|nachtlicht" /tmp/alpe-d7.log
  ```

  Erwartet ist keine Zeile mit «failed», «not available» oder «appears dead»; war das Nachtlicht
  schon beim Start an, meldet der Dienst «Gamma control enabled at startup». Den Deckel dafür
  nicht schliessen (siehe oben).
- **Papierkorb und Symbolthema, zwei Durchgänge** (Plan 0.8 Nr. 91–93; ersetzt die früheren
  Fassungen dieses Punkts). Der Papierkorb im Dock zeigt leer `user-trash`, mit Inhalt
  `user-trash-full` aus dem Symbolthema; findet die Shell keines, zeichnet `DockTrashButton.qml`
  ein Schriftsymbol. Für beide Durchgänge das Dock ohne Anheftungen ansehen: alle Anheftungen
  lösen (Rechtsklick → «Aus Dock loslösen»), offene Fenster schliessen; das Zurückholen am Ende
  stellt die Session wieder her.
  **Ist kora schon installiert, entfällt Durchgang 1** (so am 23.11.2026: Systempaket
  `kora-icon-theme` aus einem fremden COPR); der Befund zu Adwaita ist durch die Ladeprüfung am PC
  belegt. Dann auch nichts ins Home klonen, sondern in Durchgang 2 nur das Thema «kora» wählen.
  Nachsehen:

  ```
  rpm -q kora-icon-theme
  ls -d /usr/share/icons/kora ~/.local/share/icons/kora
  ```

  *Durchgang 1 – ohne kora (nur wenn keiner der Befehle oben kora findet).* Eingestelltes Symbolthema festhalten
  (Einstellungen → «Theme & Farben», Auswahl des Symbolthemas). Mit Adwaita – der Vorgabe von Fedora – ist ein
  **deckend schwarzes Quadrat hinter dem Papierkorb erwartet und kein neuer Befund**: QtSvg 6.12
  zeichnet in `user-trash.svg` von Adwaita die `<clipPath>`-Elemente, die ausserhalb von `<defs>`
  stehen, als schwarze Fläche («Ladeprüfung» unten, Fall zu Adwaita). Festhalten: Quadrat
  ja/nein, leer und nach dem Hineinlegen einer Datei.
  *Durchgang 2 – mit kora 2.0.6 aus dem Ursprung im Home.* Den Tag `v2.0.6` gibt es im Ursprung
  (geprüft am 23.11.2026); der Ordner `kora` liegt dort direkt in der Wurzel. Gibt es
  `~/.local/share/icons/kora` schon, zuerst ansehen und nicht überschreiben:

  ```
  ls -d ~/.local/share/icons/kora
  git clone --depth 1 --branch v2.0.6 https://github.com/bikass/kora.git /tmp/kora-2.0.6
  mkdir -p ~/.local/share/icons
  cp -a /tmp/kora-2.0.6/kora ~/.local/share/icons/
  dnf info breeze-icon-theme
  /tmp/alpe-d7/alpe-dienst restart
  ```

  `dnf info` liefert den Paketnamen und die Version des Ersatzthemas für E4 (kora erbt von breeze;
  ist das Paket am Mac nicht installiert, das ebenfalls festhalten). Nach dem Neuladen in den
  Einstellungen als Symbolthema «kora» wählen. **Achtung:** Die Shell schreibt das gewählte
  Symbolthema auch für GTK- und Qt-Programme (ausserhalb der gesicherten Ordner); darum **vor dem
  Rückbau das vorherige Symbolthema wieder wählen**. Erwartet: der Papierkorb aus kora, **kein
  Quadrat**, leer ein grauer Eimer, mit Inhalt derselbe mit Papier darin. Festhalten: Quadrat
  ja/nein.
  *Dock-Fläche:* In beiden Durchgängen beurteilen, ob die kleine gerundete Dock-Fläche um den
  Papierkorb **auf dem Hintergrund des Macs** erkennbar ist (am PC war sie auf der dunklen
  Material-Vorlage fast unsichtbar); das Dock ohne Anheftungen bleibt für 1.1, wie es ist.
  *Nach dem Test:* kora entweder im Home liegen lassen (dann findet es auch 1.0, und der Umzug
  trifft später auf ein vorhandenes Thema im Home neben dem aus dem Paket) oder entfernen – was
  davon, in die Tabelle:

  ```
  rm -r ~/.local/share/icons/kora
  rm -rf /tmp/kora-2.0.6
  ```
- **Tastenkürzel, Fensterregeln, Über-Seite, Mitteilungen:** wie in der Liste für D6.

Die Ladeprüfung in den Varianten «gesperrt» und «offen» (Plan 0.8 Nr. 70) läuft nur am PC.

*Schritt 6 – beenden und auswerten.* Testshell mit Strg+C beenden. Der erste Befehl darf nichts
finden. Der zweite zeigt, was das Protokoll zu den beiden fremden Plugins sagt (am PC meldet
hueManager dort eine Warnung aus eigenem Code, `Color.js … used before its declaration` – die gab
es schon unter 1.0); der dritte zählt die frühere sporadische Meldung der Einstellungssuche:

```
grep -E "is not a type|is not installed|is deprecated" /tmp/alpe-d7.log
grep -E "hueManager|calculator" /tmp/alpe-d7.log
grep -c "Cannot find member data" /tmp/alpe-d7.log
grep -E "ReferenceError|TypeError|is not defined|Cannot assign|Unable to assign" /tmp/alpe-d7.log
ls ~/.config/hypr/alpe
```

*Schritt 7 – Rückbau.* Vorher das Symbolthema zurückstellen (Durchgang 2). Dann den Stand vor dem
Test zurückholen und 1.0 wieder starten. Wichtig für den späteren Umzug: Ein
`~/.config/alpe/settings.json` aus dem Test würde das Sicherheitsnetz von `alpe start` (Plan 6.6)
abschalten.

**Zuerst sicherstellen, dass die Testshell wirklich beendet ist.** Am 23.11.2026 lief sie beim
Löschen noch und schrieb `~/.config/hypr/alpe` gleich wieder neu. Der Befehl darf nichts ausgeben;
nennt er einen Prozess, die Testshell im ersten Terminal mit Strg+C beenden und noch einmal
nachsehen (einen einzelnen übrig gebliebenen Prozess über seine Nummer beenden: `kill NUMMER`):

```
pgrep -a alpe-dienst
```

Erst dann löschen und zurückholen:

```
rm -rf ~/.config/alpe ~/.local/state/alpe ~/.config/hypr/alpe
mv ~/.config/alpe.vor-d7 ~/.config/alpe
mv ~/.local/state/alpe.vor-d7 ~/.local/state/alpe
```

(Gab es `~/.local/state/alpe` vor dem Test nicht, meldet das zweite `mv` nur «nicht gefunden».)
Jetzt vergleichen, ob die Ordner von 1.0 noch so sind wie vor dem Test. **Beide Befehle müssen
ohne Ausgabe enden;** jede Zeile nennt eine Datei, die sich während des Tests geändert hat – dann
1.0 noch nicht starten, sondern die Datei ansehen und aus der Sicherung zurückholen:

```
diff -rq ~/.config/dms.vor-d7 ~/.config/dms
diff -rq ~/.config/hypr.vor-d7 ~/.config/hypr
```

Erst bei leerer Ausgabe 1.0 starten, gestoppte Dienste aus Schritt 4a wieder starten (nur die,
die vorher `active` waren) und das Journal auf Ladefehler prüfen – der letzte Befehl darf nichts
finden:

```
systemctl --user start dms.service
systemctl --user start hypridle.service
systemctl --user start hyprsunset.service
journalctl --user -u dms.service --since "-2min" --no-pager -g "Config reload failed|is not a type|is not installed|ReferenceError|TypeError"
```

Die angepassten Plugins aus Schritt 0 liegen danach wieder unter `~/.config/alpe/plugins`, weil
sie in der Sicherung stecken; die zur Seite gelegten alten Kopien der Repo-Plugins sind mit
`~/.config/alpe` entfernt (ihre Originale liegen unverändert unter `~/.config/dms/plugins`).
`~/.config/dms.vor-d7` und `~/.config/hypr.vor-d7` bleiben als Sicherung liegen, bis geprüft ist,
dass 1.0 wie vorher läuft; dann selbst wegräumen. Der Umzug (F1) lässt Ordner mit `.vor-phase-a`
und `.vor-d7` im Namen aus (Plan 10, F1).

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
Schritt 6) schreibt sie um. Zum Prüfen im Terminal, mit vollem Pfad der Testshell (ein
`alpe-dienst` ohne Pfad gibt es am Mac vor dem Umzug nicht):

```
/tmp/alpe-d7/alpe-dienst ipc call dash toggle overview
/tmp/alpe-d7/alpe-dienst ipc call dash toggle wallpaper
/tmp/alpe-d7/alpe-dienst ipc call settings tabs
/tmp/alpe-d7/alpe-dienst ipc call processlist focusOrToggle
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

~~**Rückweg zu 1.0 nach dem Test (Plan 0.8 Nr. 41):** `session.v7.json` aus
`~/.local/state/alpe` nach `~/.local/state/dms/session.json` kopieren, ebenso
`settings.v42.json` bzw. `settings.v43.json`.~~ **Gestrichen am 23.11.2026 – der Abschnitt hat
keinen Zweck:** 1.0 liest `~/.local/state/dms/session.json` und `~/.config/dms/settings.json`,
und die fasst der Test nicht an. `session.v7.json` ist nur die Kopie dieser Datei vom Beginn des
Tests (über `cp -rn` nach `~/.local/state/alpe` gekommen und dort vor der Migration gesichert);
sie zurückzukopieren brächte nichts Neues und würde höchstens Änderungen überschreiben, die 1.0
seither gemacht hat. Ausserdem löscht der Rückbau `~/.local/state/alpe` samt dieser Datei. Was
bleibt: **nie die migrierte `session.json` (Version 8) oder `settings.json` (Version 44) aus
`~/.local/state/alpe` bzw. `~/.config/alpe` nach `dms/` kopieren** – 1.0 kann sie nicht lesen.

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
- **Werkzeuge und Oberfläche im Paket (E4; gefunden bei der Prüfung des Makefiles am 25.11.2026):** Einige
  Stellen erwarten weiter den Klon `~/alpe` statt des installierten Baums `/usr/share/alpe`:
  `shell/Modules/Settings/AlpeLockDesignTab.qml` ruft für «hyprlock.conf übernehmen» fest
  `~/alpe/tools/hyprlock2qml.py` auf (im Paket liegt es unter `/usr/share/alpe/tools`); Hinweistexte nennen
  `~/alpe/install.sh` und `backend.sh` (`AlpePerformanceTab.qml`, `AlpeLockTab.qml`, `AlpeMaintenanceTab.qml`);
  `tools/alpe` verweist in `doctor` auf `backend.sh` und `install.sh` und ruft für `alpe update` `install.sh` auf;
  `alpe test` braucht `tools/test.sh`, das nicht ins Paket kommt (geparkt im Nachtlauf vom 25.11.2026; **entschieden
  am 25.11.2026, Plan 0.8 Nr. 125 (2):** im Paket meldet `alpe test` «nur im Repository» mit Rückgabewert ungleich 0, E4).
  `design.py export` schreibt nach `<ALPE_DIR>/design`, im Paket also nach `/usr/share/alpe/design` (nicht
  beschreibbar) – Export ist ein Werkzeug für das Repository, das ist bei E4 festzuhalten. `make -C core build`
  bettet die Oberfläche weiter ein (Tag `withshell`), das Makefile in der Wurzel nicht – Kandidat zum Aufräumen.
- **Zwei Units mit demselben Busnamen (E2/F1; aus der Prüfung zu 2.4 am 25.11.2026):** `alpe.service` und
  `dms.service` (Paket `dux-shell`) tragen beide `BusName=org.freedesktop.Notifications`. Sind beide installiert –
  so sieht es 6.2 vor (kein `conflicts`, `dux-shell` bleibt als Rückweg) –, lädt eine der beiden nicht:
  `systemd-analyze --user verify` am PC meldete «dms.service: Two services allocated for the same bus name
  org.freedesktop.Notifications, refusing operation»; nach dem Quelltext von systemd (`src/core/service.c`,
  `service_setup_bus_name()` beim Laden, nachgeschlagen von der Gegenprüfung) ist das ein Ladefehler, den
  `Conflicts=` nicht abwendet (es wirkt erst beim Start). Welche Unit es trifft, hängt von der Ladereihenfolge ab;
  `Conflicts=`/`After=dms.service` in `alpe.service` laden `dms.service` immer mit. Gefolgert, nicht gemessen:
  betroffen sind Umzug (7.2 Nr. 7) und `alpe umzug --zurueck`. **In der VM messen** (beide Pakete installiert,
  Umzug, Rückweg). Entscheid des Maintainers offen: `BusName=` streichen (bei `Type=notify` nur empfohlen),
  `conflicts=dux-shell` (Rückweg fällt weg) oder Ladereihenfolge im Umzug regeln. **Entschieden am 25.11.2026,
  umgesetzt im Nachtlauf vom 26.11.2026 (Plan 0.8 Nr. 120):** `BusName=` gestrichen; `systemd-analyze --user verify`
  meldet den Konflikt mit der neuen Unit nicht mehr. Die Messung mit beiden Paketen steht unter «Installationstest in
  der VM (Liste)».
- **Desktop-Datei `io.github.alpe_shell.Alpe.desktop` (E4):** `Exec=alpe-dienst run -c /usr/share/alpe/shell`
  gilt nur für den Übergang, solange es `alpe start` nicht gibt; nach 6.6 ist `ExecStart` von `alpe.service` der
  einzige Startweg, und wer die Datei startet, umginge das Sicherheitsnetz `alpe umzug --nur-dateien`. Bei E4
  anpassen (Vorschlag der Gegenprüfung: `Exec=alpe start` – **entschieden am 25.11.2026, Plan 0.8 Nr. 125 (1)**,
  zusammen mit einer gemeinsamen Pfadauflösung für `alpe start` und `doctor`); `tests/test_paketdateien.py` legt den heutigen Wert fest
  und wird dann rot – gewollt. Dazu `alpe doctor`: prüft weiter `dev.duxlabs.shell.desktop` im Home und empfiehlt
  `install.sh` (nach dem Umzug eine falsche Warnung). Die Unit landet mit `PREFIX=$HOME/.local` unter
  `~/.local/lib/systemd/user`, das nicht im Suchpfad der Benutzer-Units liegt; 6.4 kopiert sie selbst nach
  `~/.config/systemd/user/`.
- **Sperrpaket (E4; aus der Prüfung zu 2.3 am 25.11.2026):** (a) `make install` legt `lockscreen/` weiter ganz
  nach `/usr/share/alpe/lockscreen/`; dort liegt ein zweites `org.alpe.desktop/metadata.json` mit der alten Version
  «1.9.2». Zur Laufzeit braucht davon nur `lockscreen.sh` etwas (`SOURCE`, `hyprlock.conf`); nach Variante A
  (6.7) entfällt das Kopieren – bei E4 entscheiden, ob nur `hyprlock.conf` installiert wird oder der Doppelgänger
  bewusst bleibt. (b) Das Paket setzen heute zwei Stellen zusammen: `make sperrpaket` und `lockscreen.sh install`.
  Variante A verlangt «derselbe Zusammenbau wie im Paketbau, ein gemeinsames Skript» – bei E4 rufen
  `alpe entwicklung ein` bzw. `lockscreen.sh` `make sperrpaket` auf.
- ~~`doctor` sucht die Oberfläche noch unter `quickshell/dms` (`config.LocateDMSConfig`); mit E1
  (`/usr/share/alpe/shell`) anpassen.~~ **Erledigt am 25.11.2026 (E1):** `config.LocateShellConfig` (von
  `alpe-dienst doctor` und der Versionsanzeige benutzt) sucht nach einer eigenen Oberfläche unter
  `~/.config/quickshell/alpe` zuerst im installierten Baum `<Datenordner>/alpe/shell` – `$XDG_DATA_HOME/alpe/shell`
  (Weg ohne Paket), dann je Ordner aus `XDG_DATA_DIRS`, also `/usr/share/alpe/shell` –, danach wie bisher unter
  `quickshell/alpe`. Go-Test `internal/config/shellconfig_test.go` (läuft mit `go test ./...` am Halt; `tools/test.sh`
  führt im Dienst nur `TestReadAlpeOff` aus).
  - **Wann die Suche greift:** `doctor` und die Versionsanzeige fragen zuerst `shellApp.ResolveConfig` (dux-go
    `shellapp`): `-c`, `ALPE_SHELL_DIR`, dann der Pfad der laufenden Instanz aus `<Runtime>/alpe.path` (geschrieben
    beim Start, `supervise.go`), dann die eingebettete Oberfläche. `LocateShellConfig` greift also nur ohne laufende
    Shell und bei einem Dienst ohne eingebettete Oberfläche (so baut ihn das Makefile in der Wurzel; mit
    `make -C core build`, Tag `withshell`, nie).
  - **Für E4 (Prüfer zu 2.6):** «Install Type» in `checkShellInstallation` stuft `~/.local/share/alpe/shell` (Weg
    ohne Paket, 6.4) als «System package» ein – erst seit 2.6 erreichbar, Bezeichnung falsch. ~~Ebenfalls offen
    (Maintainer): ob `doctor` ohne laufende Shell dieselbe Auflösung nimmt wie `alpe start` (Nachtlauf, «Geparkt»).~~
    **Entschieden am 25.11.2026 (Plan 0.8 Nr. 125 (1)):** gemeinsame Pfadauflösung für `alpe start` und `doctor`, bei E4.
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
   **Erledigt am 25.11.2026 (E1):** PAM-Dienste `alpe`/`alpe-u2f`, Blockmarke «ALPE LOCKSCREEN AUTH», Richtlinien
   `/usr/share/alpe/cli-policy.json` und `/etc/alpe/cli-policy.json` (Plan 2.3.3). Die alten Dienste werden erkannt
   und nicht verändert. Für F1 und den Mac (nur dort sperrt die Shell mit `Pam.qml`; unter KWin sperrt KDE): Ein
   Nutzer von 1.0 hat `/etc/pam.d/dankshell`; die Sperre nimmt ihn, bis `alpe-dienst auth sync` `/etc/pam.d/alpe`
   geschrieben hat – **seit Plan 0.8 Nr. 118 nur noch für eine verwaltete `dankshell`**; eine eigene bleibt, solange
   `alpe` fehlt, und `auth sync` meldet das. Geprüft ist das im QML-Test `tst_Pam.qml` mit Attrappen – mit Richtlinie und ohne (Weg am Mac:
   `alpe` vor `dankshell`, dann Dienst im Nutzerordner, dann die mitgelieferten Stapel) –, nicht an einer echten
   Sperre. Nebenbefund: `shell/tests/run-qml.py` zeigt noch auf den alten Ordner `quickshell/` und läuft so nicht;
   `tests/test_pam_dienste.py` ruft `qmltestrunner` für `tst_Pam.qml` direkt auf. Die Attrappen kennen das
   Singleton `Proc` nicht (Warnung «Proc is not defined» in den Fällen ohne Richtlinie, ohne Folgen für das Ergebnis).
   **Offen beim Maintainer (Nachtlauf vom 25.11.2026, Prüfung zu 2.5):** (1) Eine **eigene** `/etc/pam.d/dankshell`
   aus 1.0 wird abgelöst, sobald `auth sync` läuft (etwa beim Einschalten von U2F): Es schreibt `/etc/pam.d/alpe` aus
   dem login-Stapel, und die Sperre nimmt `alpe` vor `dankshell` – unter 1.0 hiess es an dieser Stelle «Custom …
   Skipping». **Entschieden am 25.11.2026, umgesetzt im Nachtlauf vom 26.11.2026 (Plan 0.8 Nr. 118):** Findet
   `auth sync` eine eigene, nicht verwaltete `dankshell` und keine `alpe`, schreibt es `alpe` nicht und meldet das;
   eine verwaltete `dankshell` wird wie bisher abgelöst. (2) Die Richtlinie des Administrators aus 1.0 (`/etc/dms/cli-policy.json`) wird nicht mehr gelesen;
   sicherheitsrelevante Schalter (`disable_custom_lock_pam`, `disable_lock_ipc_unlock`, `disable_logind_unlock`,
   `lock_settings`) fielen damit ohne Meldung weg. Am PC gibt es weder `/etc/dms` noch `/usr/share/dms`; am Mac ist
   es nicht nachgesehen. Optionen und Empfehlungen im lokalen Bericht des Nachtlaufs; für F1 zu entscheiden.
   **Zu (2) entschieden am 25.11.2026, umgesetzt im Nachtlauf vom 26.11.2026 (Plan 0.8 Nr. 119):**
   `/etc/dms/cli-policy.json` gilt als Rückfall, solange `/etc/alpe/cli-policy.json` fehlt, mit Meldung, Frist
   Umzug-Ende; `/usr/share/dms` nie. Für F1: der Umzug sollte die Datei nach `/etc/alpe` kopieren (braucht root) oder
   den Befehl nennen.
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

## Aufgabe für E: `pkill -x wireplumber` in `AudioService.qml` (Entscheid vom 24.11.2026)

`shell/Services/AudioService.qml`, Funktion `reloadWireplumberConfig()`: Nach dem Schreiben der
Alias-Datei startet die Shell WirePlumber neu. Mit systemd über `systemctl --user restart
wireplumber`; **ohne systemd** (`!SessionService.systemctlCommandAvailable`) über
`sh -c "pkill -x wireplumber; sleep 1"` und danach `wireplumber` als losgelösten Prozess.

- Der Zweig greift nur ohne systemd – auf beiden Zielrechnern also nie; er ist ausgelieferter Code
  aus dem Ursprung und in Phase A bisher nicht berührt. **Genaue Bedingung:**
  `systemctlCommandAvailable` (`shell/Services/SessionService.qml`) heisst nur «das Programm
  `systemctl` ist im Pfad», nicht «systemd läuft»; den laufenden Benutzer-Manager führt dort
  `userManagerAvailable` getrennt, und `AudioService` wertet ihn nicht aus. Mit `systemctl`, aber
  ohne Benutzer-Manager, scheitert der Neustart also mit Fehlermeldung, ohne `pkill`.
- Er widerspricht dem Grundsatz «kein `pkill`» (`CLAUDE.md`): `pkill -x wireplumber` beendet jeden
  Prozess dieses Namens des Benutzers, nicht nur den der Sitzung.
- **Aufgabe für E** (Paketierung; `wireplumber` bleibt harte Abhängigkeit, Plan 0.8 Nr. 96):
  entscheiden und umsetzen, was ohne systemd geschieht – den Zweig entfernen (ohne systemd kein
  Neustart, Hinweis an die Nutzerin oder den Nutzer) oder gezielt nur den eigenen Prozess beenden.
  Mit Test. Am 24.11.2026 nicht geändert.
- **Erledigt am 25.11.2026 (E1, Nachtlauf 2.7):** Zweig entfernt. Die Bedingung bleibt
  `SessionService.systemctlCommandAvailable` (Programm `systemctl` im Pfad). Ohne es startet die Oberfläche
  WirePlumber nicht neu und beendet keinen Prozess, sondern zeigt den Hinweis «Gerätenamen gespeichert – Das
  Audiosystem wurde nicht neu gestartet …» (`wireplumberReloadCompleted(false)`). Mit `systemctl`, aber ohne
  laufenden Benutzer-Manager, scheitert `systemctl --user restart wireplumber` wie bisher mit Fehlermeldung.
  Die Entscheidung über den Befehl steckt in der reinen Funktion `wireplumberRestartCommand`; Test
  `shell/tests/wireplumber-restart.test.mjs` (über `tools/node-tests.py` in `tools/test.sh`). In `shell/` steht
  danach kein `pkill` und kein `killall` mehr. Der Zweig war auch auf PC und Mac erreichbar:
  `systemctlCommandAvailable` steht anfangs auf `false`, bis die Abfrage beim Start (`SessionService.qml`) den Wert
  setzt – wer in diesem kurzen Fenster einen Gerätenamen änderte, löste `pkill -x wireplumber` aus; jetzt
  schlimmstenfalls einen unnötigen Hinweis (Prüfer zu 2.7).

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
- **Nachtrag vom Halt am 24.11.2026 (Hyprland, Variante «offen», Endstand `54bb5c0`; nicht
  eingeordnet, Grundlinie unverändert):** In vier Läufen auf dem Endstand traten drei Meldungen
  auf, die in `grundlinie-hyprland-offen.txt` nicht stehen, jede in einem der vier Läufe:
  (1) das Notizblock-Paar «Tab file does not exist …/untitled-<ID>.txt» samt `FileView`-Meldung –
  bisher nur in «gesperrt» als sporadisch 1/3 geführt; (2) `@Common/DeferredAction.qml`:
  «TypeError: Cannot read property 'stop' of null» – dieselbe Datei wie die geführte
  `flush`-Meldung, anderer Wortlaut; (3) «ShaderEffect: 'source' does not have a matching
  property». Gegenmessung nach 0.8 Nr. 76 auf `b04b1bf` (Stand vor dieser Runde): 3 Läufe, 39/39,
  keine der drei. Das reicht bei dieser Häufigkeit weder für «neu durch diese Runde» noch für
  «schon vorher»: Von den Commits der Runde berühren nur `899fefc` (`layout.js` der Sperre, drei
  leere `monitor`-Werte) und `19a16c4` (vier matugen-Vorlagen im Design aus) überhaupt, was die
  Shell im Lauf lädt; `DeferredAction.qml`, `NotepadStorageService.qml` und die Shader sind
  unverändert. **Herkunft offen, Frist wie unten vor G1;** vor einer Aufnahme als `SPORADISCH`
  in die Grundlinie mehr Läufe auf beiden Ständen (Entscheid des Maintainers).
  *(Seither gemessen und entschieden: siehe den nächsten Eintrag und Plan 0.8 Nr. 107.)*
- **Sporadische Meldungen unter Hyprland «offen» – Entscheid des Maintainers vom 24.11.2026: nicht
  in die Grundlinie, hier geführt. Vermerk: nur unter Last beobachtet, Herkunft offen.**
  Die drei Meldungen (normalisiert, wie die Ladeprüfung sie vergleicht):
  (1) Notizblock-Paar – `WARN qml: [NotepadStorageService:<Z>] Tab file does not exist:
  <TMP>/h/.local/state/alpe/notepad-files/untitled-<ID>.txt` samt der Zeile `QML FileView at
  @Services/NotepadStorageService.qml[<Z>]: Read of … failed: File does not exist.`;
  (2) `@Common/DeferredAction.qml`: «TypeError: Cannot read property 'stop' of null»;
  (3) «ShaderEffect: 'source' does not have a matching property».
  **Zählungen:**

  | Läufe | Stand | Bedingungen | Notizblock | `stop` of null | ShaderEffect |
  |---|---|---|---|---|---|
  | 12 (24.11.2026, 19:48–20:48, abwechselnd mit der Zeile darunter) | `b04b1bf` | in Ruhe | 0 | 0 | 0 |
  | 12 (dieselbe Messung) | `54bb5c0` | in Ruhe | 0 | 0 | 0 |
  | 1 (24.11.2026, ab 18:59, Haltprüfung) | `54bb5c0` | daneben lief `go vet ./...` über `core/` (belegt) | 1 | 0 | 0 |
  | 3 (24.11.2026, 19:07–19:14) | `54bb5c0` | daneben nur leichte Lesezugriffe der Sitzung (Bilder ansehen, `grep`) und das `rm -rf` eines Temp-Ordners; eine Last ist für diese drei Läufe **nicht** belegt | 0 | 1 | 1 |

  Also 0 von 12 auf `b04b1bf` und 0 von 12 auf `54bb5c0` in Ruhe, je einmal in 4 Läufen unter Last.
  **«Unter Last» ist dabei die Einordnung des Maintainers, kein Messbefund:** Gemessen ist ein
  paralleles `go vet` nur beim Lauf mit dem Notizblock-Paar; bei den Läufen mit «stop of null» und
  ShaderEffect liefen nur die genannten Lesezugriffe. Auch während der 24 Läufe ohne Fund hat die
  Sitzung daneben gelesen (Dateien, `grep`, Bildwerte, zwei Web-Abfragen), und auch die drei Läufe
  von 19:07–19:14 liefen nacheinander. Belegt unterscheiden sich diese drei von den 24 nur darin,
  dass sie in einem Aufruf mit drei Läufen liefen statt je einzeln, und im `rm -rf` eines
  Temp-Ordners. Ein Unterschied in der Last ist für sie also nicht belegt.
  **Die drei Meldungen trafen drei verschiedene Läufe** (gefolgert aus den Zählungen der vier
  Läufe: 39 + Notizblock-Paar im ersten, dann 39, 40, 40 Meldungen): Von den vier Läufen war also
  nur einer ohne fremde Meldung, von den 24 ruhigen alle 24.
  Auch die schon geführte Meldung `DeferredAction` «Property 'flush' of object … is not a function»
  (`SPORADISCH 1/3` in `grundlinie-hyprland-offen.txt`) kam in den 24 ruhigen Läufen nie vor.
  Drei frühere Läufe auf `b04b1bf` vom selben Abend (19:14–19:22, nicht in Ruhe gemessen) zeigten
  ebenfalls keine der drei. **Das Notizblock-Paar steht auf `b04b1bf` schon in der Grundlinie der
  Variante «gesperrt»** (`grundlinie-hyprland.txt`, `SPORADISCH 1/3`), wurde also vor der Runde nach
  dem Mac-Test beobachtet, nur in der anderen Variante. In `grundlinie-hyprland-offen.txt` steht
  keine der drei; tritt eine auf, meldet die Ladeprüfung sie weiter als neu. Dafür gilt die
  Wiederholungsregel in `CLAUDE.md` («Ladeprüfungen laufen nur in Ruhe»): bis zu zwei
  Wiederholungen in Ruhe, Zählung aller Läufe in den Bericht. Mögliche Ursache für (2), aus dem
  Quelltext gefolgert und nicht durch einen Lauf belegt: `deferTimer` in `DeferredAction.qml` ist
  ein Objekt in einer Eigenschaft; läuft `cancel()` beim Abbau oder vor der Zuweisung, ist es noch
  oder schon `null`. ~~**Offen beim Maintainer:** ob `SPORADISCH`-Einträge von Hand in eine
  Grundlinie dürfen.~~ **Entschieden am 25.11.2026 (Plan 0.8 Nr. 109 (6)):** nie von Hand, Grundlinien
  werden nur gemessen. Frist für die Herkunft: vor G1.
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
  **Am Mac prüfen (zur Anleitung für den Stand nach D7):** Nachtlicht – eigener Prüfpunkt in der
  Anleitung («Mac-Test»); WLAN-Liste, Bluetooth, Helligkeitstasten. ~~Deckel zu und wieder auf,
  Sperren beim Zuklappen~~ **nicht mit der Testshell** (überarbeitet am 23.11.2026): Die Sperre
  wird am Mac mit der Testshell nicht ausgelöst; ob die Farbtemperatur nach dem Aufwachen stimmt,
  zeigt sich erst nach dem Umzug mit der eingerichteten 1.1.
- ~~**Offen (22.11.2026, Frist: vor E1 – Entscheid des Maintainers, weil es das Erste ist, was ein
  neuer Nutzer sieht): Dock ohne angeheftete Programme.**~~ **Geschlossen am 23.11.2026 (Plan 0.8
  Nr. 91–93):** kora wird als Abhängigkeit mitgeliefert, der Papierkorb kommt damit aus kora (kein
  eigenes Symbol); das Dock ohne Anheftungen bleibt für 1.1, wie es ist – die Sichtbarkeit der
  Fläche wird beim Mac-Test auf anderem Hintergrund neu beurteilt. Beleg mit der Systemfassung von
  kora (leerer und voller Papierkorb) im Plan, «Stand»; der Befund zu Adwaita steht als eigener
  Fall weiter unten. Der Text darunter ist der Stand der Untersuchung. Im Bild der Variante «offen» unter dem
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
- **Offen (23.11.2026, Herkunft offen): `AlpeTextField.qml: TypeError: Property 'snapTo' of object
  SpringMotion… is not a function`** – KWin, Variante «offen», in 1 von 4 Läufen auf `016b2d4`, in
  0 von 3 auf dem Stand davor (`53c5121`). Vermutlich dieselbe Art Wettlauf wie bei
  `DeferredAction` (Aufruf, während das Objekt auf- oder abgebaut wird; `AlpeTextField` ruft
  `snapTo` auf drei eigenen `SpringMotion`-Objekten), nicht untersucht. Die sieben Läufe belegen
  weder, dass die Meldung neu ist, noch dass sie alt ist (Plan 0.8 Nr. 76). Nicht in der
  Grundlinie; bis zu einem Entscheid kann der Lauf KWin «offen» damit gelegentlich rot sein.
  Zusammen mit den beiden sporadischen Meldungen unter Hyprland klären (Frist dort: vor G1).
- ~~**Bilder des Designs ohne Lizenzangabe (23.11.2026):** `design/kde/bilder/` enthält
  `jagged-peaks-wolkenzug.mp4`, `wallpaper.jpg` und `wall.png`; `NOTICE` nennt sie nicht, die
  Dateien tragen keine Urheberangabe. Das Bergbild der Sperre ist ein Standbild aus dem Video.
  Herkunft und Lizenz bestätigt der Maintainer; danach Eintrag in `NOTICE`.~~ **Erledigt
  (Plan 0.8 Nr. 95):** vom Maintainer, teils mit KI-Werkzeugen erstellt, CC0 1.0; in `NOTICE`.
- **Lizenzfeld der Pakete – entschieden am 25.11.2026 (Maintainer): Option (b).** Das Lizenzfeld wird
  **vollständig aus der Dateiliste von `make install`** gebildet und **am Ende von E1 festgelegt**
  (Auftrag des Maintainers vom 25.11.2026: Tabelle Datei oder Ordner → Lizenz nach `NOTICE`, daraus der Vorschlag für 6.2
  und 6.3). Bis dahin bleibt der Plan bei den drei; der Text darunter ist der Stand vom 24.11.2026.
  - **Umgesetzt in E2 (Nachtlauf vom 26.11.2026, Plan 0.8 Nr. 126):** Das Feld im PKGBUILD steht in Plan 6.2 («Umgesetzt
    in E2») mit Beleg je Kennung und der Liste dessen, was ungeklärt und darum nicht im Feld ist. Der Vorschlag unten
    ist damit überholt (Stand 25.11.2026).
  - **Vorschlag aus der Dateiliste (25.11.2026, Nachtlauf E1 2.8; Tabelle Datei/Ordner → Lizenz in der Nachtdatei
    und in den Belegen; Entscheid beim Maintainer):**
    Arch `license=(MIT GPL-3.0-only Apache-2.0 BSD-2-Clause BSD-3-Clause OFL-1.1 CC-BY-4.0 CC-BY-SA-4.0 CC0-1.0 FTL
    LicenseRef-Alpe-Logo)`; Fedora `License: MIT AND GPL-3.0-only AND Apache-2.0 AND BSD-2-Clause AND BSD-3-Clause AND
    OFL-1.1 AND CC-BY-4.0 AND CC-BY-SA-4.0 AND CC0-1.0 AND (FTL OR GPL-2.0-or-later) AND LicenseRef-Alpe-Logo`
    (seit Plan 0.8 Nr. 114 bei Fedora nur `FTL`, weil Alpe die FTL gewählt hat)
    – vorbehaltlich der offenen Punkte (dazu vermutlich `CC-BY-SA-3.0` für die Klänge; Schriften ohne Reserved
    Font Name, etwa Fira Code, als `OFL-1.1-no-RFN`; `gopkg.in/yaml.v3` MIT und Apache-2.0 – Schreibweisen bei E2/E3
    mit `namcap`/`rpmlint` prüfen):
    - **`alpe-dienst` linkt `github.com/pilebones/go-udev` (GPL-3.0, README «GNU GPL v3» ohne «or later»)**,
      benutzt in `core/internal/server/brightness/udev_linux.go`; aus dem Ursprung übernommen. Das Programm als
      Ganzes fällt damit unter die Bedingungen der GPL-3.0. **Entschieden am 25.11.2026 (Plan 0.8 Nr. 113):**
      `go-udev` bleibt, `GPL-3.0-only` ins Feld, eigener Eintrag in `NOTICE`, Lizenztext im Paket; kein Ersatz in
      Phase A, Phase B löst den Go-Dienst ab.
    - `github.com/yeqown/reedsolomon` (indirekt über `go-qrcode`): im Modul keine Lizenzdatei, die README nennt
      keine Lizenz – Lizenz ungeklärt. **Geklärt am 25.11.2026 (Nachtlauf vom 26.11.2026, Plan 0.8 Nr. 115):** MIT; der Autor hat die Datei
      `LICENSE` am 08.03.2026 in sein Repository gelegt (Code unverändert gegenüber v1.0.0); Eintrag in `NOTICE`.
    - `github.com/golang/freetype`: FreeType License oder GPL-2.0-or-later nach Wahl; die FTL verlangt eine Nennung
      in der Dokumentation. **Entschieden am 25.11.2026 (Plan 0.8 Nr. 114):** Alpe wählt die FTL; Text unverändert
      ins Quellarchiv und ins Paket, Nennung in `NOTICE`.
    - **Klänge** (`shell/assets/sounds/freedesktop/`, ausgeliefert ~~nur vier~~ seit Plan 0.8 Nr. 116 nur drei, je
      `.oga` und `.wav`):
      `audio-volume-change`, `message` und `message-new-instant` sind bytegleich mit `sound-theme-freedesktop` 0.8
      (`sha256sum` der `.oga` gegen das Arch-Paket 0.8-6 am PC, nur gelesen, 25.11.2026). `audio-volume-change` und
      `message`: CC-BY-SA, nach Debian CC-BY-SA-3.0. **`message-new-instant`: Herkunft belegt (Klangthema),
      Lizenz ungeklärt** – `CREDITS` gibt ihm keinen eigenen Eintrag, Debian fasst das Thema als «CC-BY-3.0 and
      CC-BY-SA-3.0 and GPL-2 and GPL-2+» zusammen; ob GPL-2.0-only oder -or-later, ist nicht belegt (früher hier
      «vermutlich GPLv2+» aus der Stellung in `CREDITS` – das trägt nicht). **`desktop-login` gehört nicht zum
      Klangthema:** nicht im Paket am PC, nicht in Debians `copyright`, und die Prüfsumme gleicht weder
      `service-login` noch `service-logout`; über DMS übernommen, **Herkunft und Lizenz unbekannt**. Die
      CC-BY-3.0-Klänge aus `NOTICE` werden nicht ausgeliefert. Nachschlagen am Ursprung und Entfernen von
      `desktop-login`: Entscheid des Maintainers vom 25.11.2026 (Nachtlauf 26.11.2026, Punkt 1.4; lokaler Bericht).
      **Nachtrag (Nachtlauf vom 26.11.2026, Plan 0.8 Nr. 116):** Der Satz «`desktop-login` gehört nicht zum
      Klangthema» ist **überholt** – die Datei gehörte bis 0.6 dazu (bytegleich mit dem Stand vor Commit `7c4e2f7`
      von 2009, `CREDITS` damals: Red Hat, Inc., Mike Langlie, CC-BY-SA); im heutigen Paket fehlt sie, weil der
      Ursprung sie in 0.7 entfernt hat. Entfernt ist sie wie entschieden. `message-new-instant`: auch in keiner
      früheren Fassung von `CREDITS` ein Eintrag – Lizenz am Ursprung nicht angegeben. Die Fassung der CC-BY-SA nennt
      der Ursprung nirgends (CC-BY-SA-3.0 ist die Einordnung von Debian, Fedora und Arch). Beides geparkt.
      **`message` (Borealis) ist am Ursprung widersprüchlich:** `CREDITS` (ab 14.09.2009) nennt CC-BY-SA, das README
      nannte vorher «Creative Commons Share-Alike 3.0 Unported» und ab Commit `bc4fe27` (01.09.2009, «Borealis is
      actually artistic, not gpl») «Artistic License»; eine dritte Seite (Miranda NG) beschreibt Borealis als
      Artistic License mit Zusätzen. Lizenz von `message` damit ungeklärt, geparkt; im Lizenzfeld (E2) keine
      Vermutung.
      **Erledigt durch den Entscheid vom 26.11.2026 (Nachtlauf vom 27.11.2026, Plan 0.8 Nr. 128):** Alpe liefert die
      drei Klänge und `CREDITS` nicht mehr mit; die Shell nimmt sie aus dem installierten Paket
      `sound-theme-freedesktop` (Abhängigkeit in 6.2 und 6.3), fehlt eine Datei, bleibt es still. Die offenen Fragen
      zu Fassung und Lizenz betreffen damit nicht mehr das Paket von Alpe.
    - **Nicht in `NOTICE`:** `shell/Alpe/Common/fzf.js` (BSD-3-Clause, Ajit), `shell/Alpe/Common/Hct.js`
      (Apache-2.0, Google, aus Material Color Utilities), `shell/Alpe/Widgets/MaterialShapeData.js` (Apache-2.0,
      Android Open Source Project; `MaterialShapes.NOTICE` und `Apache-2.0.txt` daneben); Zeichen Dritter unter
      `shell/assets/`: `hyprland.svg`, `package-sources/{flatpak,snap,appimage,nix}.svg` (benutzt),
      `discord.svg`, `reddit.svg` (nirgends benutzt). **Erledigt im Nachtlauf vom 26.11.2026 (Plan 0.8 Nr. 117):**
      alle drei Code-Teile und die fünf Zeichen in `NOTICE`, `discord.svg`/`reddit.svg` entfernt. **Für das
      Lizenzfeld neu (nicht vermuten, bei E2/E3 entscheiden):** Flatpak-Zeichen CC-BY-3.0, Snapcraft-Zeichen
      CC-BY-SA-3.0 (beide nach Simple Icons, das selbst CC0 ist), Hyprland-Zeichen ARR nach der Markenrichtlinie
      von hyprwm (die Datei ist nicht die offizielle Vorlage); Herkunft von `appimage.svg` unbelegt. Geparkt.
    - `LicenseRef-Alpe-Logo`: Symbol und Zeichen von Alpe (Rechte beim Maintainer, `NOTICE`); die mit
      `alpe-dienst completion` erzeugten Vervollständigungen stammen aus Vorlagen von cobra (Apache-2.0).
- ~~**Lizenzfeld der Pakete (offen beim Maintainer, 24.11.2026):**~~ Entschieden ist, dass das
  Lizenzfeld MIT, CC-BY-4.0 und CC0-1.0 nennt (Plan 6.2, 6.3, Abschnitt 10). Unter `shell/` liegen
  nach `NOTICE` und Plan Abschnitt 3 aber auch Teile unter anderen Lizenzen: Schriften (OFL-1.1,
  Apache-2.0), Klänge (CC-BY-SA 4.0, CC-BY 3.0, GPLv2+), `suncalc.js` (BSD-2-Clause), dazu die
  Go-Abhängigkeiten im Programm. Die Radar-Musterdatei (CC BY 4.0) liegt unter `tests/` und kommt
  vermutlich nicht ins Paket; CC-BY-4.0 stünde dann nur wegen der Hintergrundmuster im Feld.
  Optionen: (a) bei den drei bleiben, `NOTICE` trägt den Rest; (b) vollständige Aufzählung aus
  der tatsächlichen Dateiliste von `make install` (E1), in beiden Paketen; (c) drei im PKGBUILD,
  vollständig nur in der Spec. Empfehlung der Gegenprüfung: (b), festgelegt nach E1 und vor
  E2/E3. Bis zum Entscheid bleibt der Plan bei den drei.
- **Hero Patterns, Vergleich mit den Download-Dateien (24.11.2026, Nachtlauf):** Die sieben Muster
  sind mit `https://heropatterns.com/svg/<name>.zip` verglichen: `graph-paper.svg` byte-gleich,
  die sechs anderen gleich bis auf genau einen zusätzlichen Zeilenumbruch am Dateiende. Die
  Füllfarbe Schwarz ist die des Originals. So steht es in `NOTICE`.
- **Nachtrag 24.11.2026 zur Liste unten (Auftrag des Maintainers, `NOTICE`):** eingetragen sind
  jetzt (1) die sieben Muster unter `shell/Alpe/Widgets/wallpaper-patterns/` – **Hero Patterns von
  Steve Schoger, CC BY 4.0** (Lizenzvermerk auf `heropatterns.com`; die Pfaddaten aller sieben
  stehen in der Musterliste der Seite, `js/app.js`: fünf zeichengleich im Anfang, `bubbles` und
  `bank-note` dort in gekürzter relativer Schreibweise mit denselben Koordinaten); (2) die
  Radar-Musterdatei – MeteoSchweiz Open Data, Produkt PRECIP/RZC im Format ODIM HDF5, CC BY 4.0,
  verlangte Angabe «Quelle: MeteoSchweiz» (`opendatadocs.meteoswiss.ch`, Nutzungsbedingungen und
  Seite zu den Radarprodukten); (3) die Karten des Radar-Tabs – Natural Earth, gemeinfrei, Nennung
  nicht verlangt; (4) die Logos – Rechte am Logo und am Namen beim Maintainer, Nutzung zur
  Bezeichnung von Alpe erlaubt, nicht CC0. Die Drucker-Testseite ist neu erzeugt
  (`entwicklung/testseite/erzeugen.py`). **Weiterhin ohne Eintrag:** die Zeichen Dritter unter
  `shell/assets/` und die Teile des fcitx5-Themas.
- **Medien ohne Herkunftsangabe in `NOTICE` (Bestand vom 23.11.2026; nichts wird ohne Angabe des
  Maintainers eingetragen).** Geprüft: alle versionierten Bilder, Videos und Klänge (43 Dateien in
  neun Ordnern) sowie zwei weitere Binärdateien; in `lockscreen/`, `docs/` und im README liegen
  keine Bilder. Genannt sind in `NOTICE` die Klänge (`shell/assets/sounds/`), die Schriften und
  jetzt `design/kde/bilder/`. **Ohne Eintrag:**
  - *Seit Alpe 1.0 (`c988364`), nicht aus dem Ursprung:* `assets/logo/logo/` – `alpe-avatar.png`,
    `alpe-avatar.svg`, `alpe-logo-dunkel.svg`, `alpe-logo-hell.svg`, `alpe-social.png`,
    `alpe-social.svg`, `alpe-zeichen.png`, `alpe-zeichen.svg` (Logos von Alpe; Urheber und Lizenz
    nirgends genannt). `plugins/alpeRadar/map-lines.png`, `map-water.png` (Kartengrundlage; laut
    `tools/build-basemap.py` und `docs/technik.md` aus Natural Earth, gemeinfrei – steht nicht in
    `NOTICE`). `tests/data/rzc263201930vl.001.h5` (Radar-Musterdatei; laut `docs/technik.md`
    MeteoSchweiz Open Data – `NOTICE` nennt nur allgemein «Wetterdaten und Radarbilder»).
  - *Aus dem Ursprung (`a21d715`), dort ohne eigene Angabe und in `NOTICE` nur über den
    allgemeinen Abschnitt zur Dux Modular Shell erfasst:*
    `shell/Alpe/Widgets/wallpaper-patterns/` – `bank-note.svg`, `bubbles.svg`,
    `endless-clouds.svg`, `graph-paper.svg`, `plus.svg`, `topography.svg`, `wiggle.svg` (die
    Dateien tragen keinen Vermerk; die Namen gleichen denen einer verbreiteten freien
    Mustersammlung – Herkunft nicht belegt, zu klären). `shell/assets/discord.svg`, `reddit.svg`
    (Markenzeichen Dritter; unbenutzt bzw. Rest, siehe «Werkzeuge»). `shell/assets/hyprland.svg`
    (Zeichen von Hyprland). `shell/assets/package-sources/appimage.svg`, `flatpak.svg`, `nix.svg`,
    `snap.svg` (Zeichen der Paketformate). `shell/matugen/templates/fcitx5/highlight.svg`,
    `panel.svg` (Teile des fcitx5-Themas). `core/internal/config/embedded/testpage.pdf`
    (Drucker-Testseite; **der PDF-Titel lautet noch «DankMaterialShell Test Page»** – die
    Namensprüfung sieht in die Binärdatei nicht hinein).
  - *Aus eigenem Code erzeugt, darum wohl ohne Eintrag richtig:* `shell/assets/alpe-zeichen.svg`,
    `alpe-zeichen-akzent.svg` (aus `LogoShape.js`, vom Test geprüft).
- **Verweise im ausgelieferten Design, die nur auf dem exportierenden Rechner aufgehen (geprüft am
  23.11.2026; Massstab: vom Paket `alpe-shell` oder seinen Abhängigkeiten geliefert oder in der
  Grundinstallation von CachyOS mit KDE und Fedora Asahi mit Hyprland vorhanden).** Es gibt ein
  Design, `design/kde`. **In Ordnung:** Symbolthema kora (Abhängigkeit, Plan 0.8 Nr. 91; ein
  eigenes Thema für die helle Darstellung setzt das Design nicht – `iconThemeLight` und
  `iconThemePerMode` fehlen, hell und dunkel benutzen kora); Schriften der Sperre «AlfaSlabOne»
  und «JetBrains Mono Nerd Font Mono» (liegen unter `shell/Modules/Lock/Alpe/fonts`, die Sperre
  ordnet den Namen ohne «Nerd Font» zu); Schrift der Shell und Festbreitenschrift (nicht im
  Design, Vorgaben «Google Sans Flex» und «Fira Code» liegen unter `shell/Alpe/assets/fonts`);
  Bilder (`bilder/`, kommen mit dem Design); Cursorthema und Klangthema (nicht im Design, es gilt
  das System); fastfetch-Logo (`alpe-logo.txt` legt `tools/fastfetch.py` an); Symbole in der
  fastfetch-Vorlage (kitty bringt «Symbols Nerd Font Mono» selbst mit). **Behoben (eindeutig):**
  Das abgeschaltete Uhr-Widget auf dem Schreibtisch nannte «CaskaydiaCove Nerd Font Propo» (am PC
  aus `ttf-cascadia-code-nerd`, ausdrücklich installiert; unter Fedora nicht paketiert) – aus dem
  Design entfernt, es gilt die Schrift der Shell. **Unklar, nur aufgelistet:** (1) KWin-Effekte
  `better_blur_dx` und `Round-Corners` in `kwin.json` – Pakete aus AUR bzw. fremden COPR, heute
  `optdepends` (Plan 6.2) und von `get.sh` nachinstalliert; fehlen sie, hat das Design weder
  Unschärfe noch runde Ecken und der eingebaute Unschärfe-Effekt ist abgeschaltet
  (`blurEnabled=false`). Gehört das zum «ausgelieferten Design», müssten sie Abhängigkeiten sein.
  (2) Video-Hintergrund `jagged-peaks-wolkenzug.mp4`: braucht `qt6-multimedia` (in `depends`) und
  für das Standbild der Sperre und die Farben `ffmpeg` (heute `optdepends`/`Recommends`); ohne
  `ffmpeg` zeigt die Sperre eine Farbe statt des Bildes. (3) `manifest.json` führt Schriften nur aus
  Schlüsseln der obersten Ebene, der Sperre und der Programme; die Schrift im Uhr-Widget stand
  darum nicht darin – `tools/design.py` sammelt verschachtelte `fontFamily` nicht ein und meldet
  sie beim Einspielen nicht als fehlend. (4) Eingeschaltete matugen-Vorlagen für Firefox, Neovim,
  Zen und Zed spiegeln die Programme des exportierenden Rechners; ob sie ins Design gehören, ist
  offen. (5) `lockscreen/hyprlock.conf` und daraus `layout.js` nennen an mehreren Stellen den
  Bildschirm `eDP-1` (eingebauter Bildschirm eines Notebooks; die Shell-Sperre beachtet die Angabe
  laut Kopf der Vorlage nicht); kein persönlicher Name, aber eine Bildschirmangabe im Repository. **Vorschlag für einen Test (nicht umgesetzt):** in
  `tests/test_werte.py` für jedes Design alle Verweise einsammeln – `iconThemeDark`/`iconThemeLight`,
  `cursorSettings.theme`, jede `fontFamily`/`font.family` in beliebiger Tiefe von `settings.json`
  und im Layout der Sperre, `font_family` in den Programmdateien, Bild- und Videopfade, die
  eingeschalteten KWin-Effekte – und gegen eine erlaubte Liste prüfen, die neben dem Test steht
  und je Eintrag sagt, woher er kommt: Abhängigkeit (`kora`), mitgelieferte Schrift (der Test
  prüft die Datei unter `shell/…/fonts`), Datei im Design (`@DESIGN@/bilder/…` muss existieren),
  generischer Name (`Sans`, `monospace`, «System Default»). Alles andere ist ein Fund. Sobald es
  PKGBUILD und Spec gibt (E2/E3), vergleicht derselbe Test die Liste mit deren `depends`/`Requires`,
  damit Liste und Pakete nicht auseinanderlaufen. Dazu `design.py`: verschachtelte Schriften ins
  `manifest.json`.
- **Offen (23.11.2026, ohne Frist; vor G1 neu beurteilen): Adwaita 51 unter Qt 6.12 – Symbole mit
  deckend schwarzem Grund.** Betrifft nur Nutzer, die das Symbolthema selbst auf Adwaita umstellen
  (oder bei denen kora und breeze fehlen, sodass Qt bei Adwaita landet); das ausgelieferte Design
  nennt kora, das als Abhängigkeit mitkommt (Plan 0.8 Nr. 91, 92). Im Dock sichtbar am Papierkorb
  (`user-trash`, `user-trash-full`). **Ursache eingegrenzt (QtSvg 6.12.0, Bildleser von Qt,
  offscreen, 72 px):** nicht `<mask>` und nicht `<filter>` – die Datei rendert auch ohne beide
  schwarz –, sondern **`<clipPath>`-Elemente, die direkt unter `<svg>` stehen statt in `<defs>`**:
  QtSvg zeichnet ihren Inhalt wie gewöhnliche Formen. `user-trash.svg` enthält acht solche
  Elemente, zwei davon `<clipPath><rect width="192" height="152"/></clipPath>`; dieses Rechteck
  ohne Füllangabe wird als deckend schwarze Fläche über das ganze Bild gemalt. Gegenproben: ohne
  die beiden Rechteck-Clip-Pfade sind die Ecken durchsichtig; mit denselben Elementen in `<defs>`
  ebenfalls; eine Datei aus vier Zeilen (ein `<clipPath>` mit `<rect>` direkt unter `<svg>`, ein
  Kreis) zeigt denselben Fehler, mit `<defs>` nicht. **Umfang (alle 767 Dateien von
  `adwaita-icon-theme` 51.0 gerendert):** 16 Symbole mit vier schwarzen Ecken – neben den beiden
  Papierkörben `audio-headphones`, `audio-headset`, `ebook-reader`, `input-tablet`, `microphone`,
  `printer`, `printer-network`, `scanner`, `video-display` (Geräte) und `package-x-generic`,
  `x-office-addressbook`, `x-office-spreadsheet`, `x-office-spreadsheet-template`,
  `x-package-repository` (Dateitypen). kora 2.0.6 (9819 Dateien), breeze 6.32 (7859) und hicolor
  (239) im selben Lauf: keines. Die Angabe vom 23.11.2026, 16 andere Adwaita-Symbole seien
  unauffällig, war eine Stichprobe und bleibt richtig, aber der Papierkorb ist nicht das einzige
  betroffene Symbol. Mögliche Wege, nichts davon umgesetzt: auf Qt oder Adwaita warten; in
  `IconThemeService` für Adwaita die Symbole aus `AdwaitaLegacy` bzw. die symbolischen vorziehen;
  betroffene SVG vor dem Laden umschreiben (nicht empfohlen).
- **Offen (23.11.2026): kein Bild unter KWin.** `alpe-dienst screenshot full` meldet im virtuellen
  `kwin_wayland` der Ladeprüfung `compositor does not support wlr-screencopy-unstable-v1`; das
  Bild zum Halt (Plan 0.8 Nr. 71) gibt es darum nur unter Hyprland. Der Lauf selbst bleibt
  gültig und ohne neue Meldung. Zu klären: ob das Bildschirmfoto des Dienstes unter KWin
  überhaupt geht (auch auf dem echten Schreibtisch) oder ob die Ladeprüfung dort einen anderen
  Weg braucht (KWin-Schnittstelle `org.kde.KWin.ScreenShot2`, verlangt eine Freigabe über die
  Desktop-Datei). Ebenso: `--bild` gibt es nur in der Variante «offen»; ein Bild des
  Sperrbildschirms brauchte am 23.11.2026 einen Temp-Worktree mit aufgehobener Sperre.
  **Weg A umgesetzt am 24.11.2026 (Plan 0.8 Nr. 103), befristet und nur für KWin, bis Weg B nach
  G1 entschieden ist:** `entwicklung/ladepruefung/kwinbild.py`, aufgerufen von `--bild` und neu
  `--bild-sperre` unter KWin. Das Skript ermittelt die Busadresse im Lauf und bricht ohne Aufnahme
  ab, wenn sie fehlt, keine eindeutige Unix-Adresse ist, der Adresse der Sitzung des Maintainers
  (beim Start der Ladeprüfung aus `DBUS_SESSION_BUS_ADDRESS` gelesen) oder `/run/user/<uid>/bus`
  gleicht, oder wenn der Prozess hinter `org.kde.KWin` an diesem Bus nicht im Scope des Laufs
  läuft; die Ladeprüfung wertet einen solchen Abbruch als ungültigen Lauf. Test in
  `tests/test_ladepruefung.py`; Probelauf «offen» unter KWin am 24.11.2026 mit Bild 1920 × 1080.
  **Kein Bild der Sperre unter KWin (24.11.2026, offen):** `--bild-sperre` liefert unter KWin den
  Schreibtisch (Bergbild, Leiste, Dock), nicht die Sperre. Unter KWin sperrt nicht die Shell,
  sondern der Sperrbildschirm von KDE mit dem Paket `org.alpe.desktop`; die Ladeprüfung startet
  `kwin_wayland` mit `--no-lockscreen`, und `loginctl` ist eine Attrappe. Die Variante «gesperrt»
  prüft unter KWin also nur, dass die Shell mit `lockAtStartup` lädt. Ein Bild der KDE-Sperre
  brauchte einen eigenen Weg (Sperre in der Test-Instanz zulassen; ob ScreenShot2 sie dann
  aufnimmt, ist nicht geprüft) – Entscheid des Maintainers. Unter Hyprland zeigt `--bild-sperre`
  die Sperre der Shell.
  **Seit dem Nachtlauf vom 24.11.2026 bricht `kwin --bild-sperre` mit einer Meldung ab** (Rückgabewert
  2, kein Bau, kein Lauf, kein Bild) und liefert nicht mehr den Schreibtisch; Test in
  `tests/test_ladepruefung.py`. Ein Bild der KDE-Sperre ist damit nicht gebaut.
  **Nachtrag vom 25.11.2026 (Plan 0.8 Nr. 71, 112):** `kwinbild.py` wird heute von `kwin --offen --bild`
  und neu von `kwin --bild-schreibtisch` aufgerufen – nicht mehr von `--bild-sperre` (der Satz oben «aufgerufen von `--bild`
  und neu `--bild-sperre`» gilt seit `73ab9c5` nicht mehr). `--bild-schreibtisch` nimmt in der Variante
  «gesperrt» den Schreibtisch im ausgelieferten Design auf (ohne Abdeckungs-Zusätze), Haltbild
  `halt-kwin-gesperrt-schreibtisch.png`; es ist Pflicht bei jedem Halt, solange Weg A besteht. Die Aussage
  «Die Variante «gesperrt» prüft unter KWin also nur, dass die Shell mit `lockAtStartup` lädt» bleibt für
  die Sperre richtig; zu sehen ist unter KWin jetzt zusätzlich der Schreibtisch (in der Test-Instanz
  erscheint keine Sperre). Die KDE-Sperre
  selbst zeigt weiter kein Haltbild (Nr. 108).
  **Berichtigt am 24.11.2026 (Nachtlauf): Die Aussage unten, KWin 6.8.3 prüfe an ScreenShot2 keine
  Berechtigung, ist am Quelltext belegt** (vorher «unbelegt»; Einzelheiten in Plan 0.8 Nr. 103).
  Bis 6.7 prüfte das Screenshot-Plugin die Desktop-Datei des Aufrufers und antwortete sonst mit
  `org.kde.KWin.ScreenShot2.Error.NoAuthorized`; der KWin-Commit
  `0ea31ae72eb052cb9c9cc508318fc3f0f329ed53` («plugins/screenshot: Drop
  X-KDE-DBUS-Restricted-Interfaces») entfernt die Prüfung, enthalten ab `v6.7.90`/`v6.8.0`. Im Tag
  `v6.8.0` nimmt `CaptureWorkspace` (`src/plugins/screenshot/screenshotdbusinterface2.cpp`, ab
  Zeile 415) jeden Aufrufer an; die PID dient nur noch `pidToHide`.
  `KWIN_SCREENSHOT_NO_PERMISSION_CHECKS` gibt es dort nicht mehr; die Ladeprüfung setzt die
  Variable nicht (auf 6.8 wirkungslos). **Damit sind die Abbruchbedingungen von `kwinbild.py` die
  einzige Schranke zwischen Test und echter Sitzung**; jede hat einen Test durch `main()`
  (`tests/test_ladepruefung.py`), und meldet ein älteres KWin `NoAuthorized`, bricht `kwinbild.py`
  mit klarer Meldung ab, statt die Prüfung zu umgehen. Die Nummer des Merge-Requests ist nicht
  nachgeschlagen. Der folgende Befund an den Binärdateien bleibt als Verlauf stehen.
  Ergänzende Suche am 24.11.2026 in `/usr/lib/libkwin.so.6.8.3` (Paket `kwin`
  6.8.3-1.1), im Plugin `screenshot.so` und in `kwin_wayland`, je als ASCII, UTF-16 LE/BE und in den
  exportierten Symbolen: kein `X-KDE-DBUS-Restricted-Interfaces`, kein `X-KDE-Wayland-Interfaces`,
  kein `KWIN_SCREENSHOT…`, kein `…PERMISSION_CHECK…`, kein `NotAuthorized`/`NoAuthorized`, kein
  Symbol mit `fetchRestricted…` oder `…RestrictedInterfaces…`; `libkwin.so` enthält `desktopFile…`
  nur für Fenster und Fensterregeln. Das stützt die Probe, beweist aber nichts: Zeichenketten
  können zusammengesetzt, die Prüfung in einer anderen Bibliothek oder per Richtlinie des Busses
  gelöst sein.
  **Einschätzung vom 23.11.2026:**
  *Berechtigungsprüfung am installierten KWin 6.8.3:* Die Annahme «verlangt eine Freigabe über die
  Desktop-Datei» trifft auf dieser Version nicht zu. Belege: (1) Im Plugin
  `/usr/lib/qt6/plugins/kwin/plugins/screenshot.so` (Paket `kwin` 6.8.3) gibt es die Fehlernamen
  `org.kde.KWin.ScreenShot2.Error.Cancelled`, `.FileDescriptor`, `.InvalidArea`, `.InvalidScreen`,
  `.InvalidWindow`, `.NoActiveWindow` – **keinen** für eine verweigerte Berechtigung; weder das
  Plugin noch `libkwin.so.6` noch `kwin_wayland` enthalten den Schlüssel
  `X-KDE-DBUS-Restricted-Interfaces` oder eine Umgebungsvariable mit `NO_PERMISSION_CHECKS` (als
  ASCII und UTF-16 gesucht). (2) Probe in einer eigenen Test-Instanz (`kwin_wayland --virtual`,
  eigener Scope, eigenes HOME, eigener Session-Bus, keine `KWIN_*`-Variable gesetzt): `busctl
  --user call org.kde.KWin /org/kde/KWin/ScreenShot2 org.kde.KWin.ScreenShot2 CaptureWorkspace
  'a{sv}h' 0 3` – ein Aufrufer ohne Desktop-Datei – liefert ohne Fehler `format 16` (RGBX8888),
  1280 × 720, `stride 5120`, `type raw` und 3 686 400 Bytes Bilddaten; die Schnittstelle meldet
  `Version 5`. **Eine Umgebungsvariable zum Abschalten gibt es in dieser Version also nicht, und es
  braucht keine.** Der Quelltext von 6.8.3 liegt auf dem Rechner nicht vor (kein Quell- oder
  Debug-Paket, keine Header zum Plugin); belegt ist das Verhalten der installierten Binärdateien,
  nicht der Quelltext. Dass ältere KWin-Fassungen die Desktop-Datei prüfen und einen Schalter
  kennen, ist hier nicht nachprüfbar; die drei Desktop-Dateien mit dem Schlüssel (plasmashell,
  Portal, Spectacle) liegen weiterhin vor. Die echte Sitzung wurde nicht angesprochen.
  *Was es braucht:* Die Schnittstelle nimmt einen Dateideskriptor (Pipe), schreibt Rohdaten und
  antwortet mit Breite, Höhe, Zeilenlänge und `QImage`-Format. **Weg A – nur in der Ladeprüfung**
  (`ladepruefung.py`, `--bild` unter KWin über `busctl` und ein paar Zeilen Umwandlung nach PNG,
  dazu ein Test): rund 40 Zeilen, ein bis zwei Stunden; trifft von der Bauart her nur die
  Test-Instanz (eigener Session-Bus), der Dienst bleibt unverändert. Weicht von «fester Weg
  `alpe-dienst screenshot full`» (0.8 Nr. 71) ab, darum Entscheid nötig. **Weg B – im Dienst**
  (`core/internal/screenshot`: zweites Backend über den Session-Bus mit godbus, Pipe lesen,
  Formate RGBX8888/ARGB32 nach PNG, `full` über `CaptureWorkspace`, später `CaptureScreen`,
  `CaptureArea`, `CaptureActiveWindow`; Go-Test gegen eine Attrappe der Schnittstelle auf einem
  privaten Bus): für `screenshot full` ein halber bis ein Tag, mit Bereichs- und Fensterauswahl
  mehr. Das wäre eine neue Funktion für alle KWin-Nutzer (heute meldet der Dienst unter KWin nur
  den Fehler oben) und liesse sich nur künstlich auf die Test-Instanz beschränken (eigener
  Schalter im Dienst) – davon rate ich ab. **Vorschlag:** Weg A **vor E1** (klein, und ab E1
  ändern sich Pfade und Paketdateien, bei denen ein Bild unter KWin am Halt nützt); Weg B nicht
  in Phase A, als eigene Funktion nach G1 entscheiden.
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

## Installationstest in der VM (Liste)

Der echte Installationstest macht der Maintainer in der CachyOS-VM (Snapshot «frisch») und am Mac (`CLAUDE.md`).
Punkte, die nur dort messbar sind:

1. **`alpe.service` und `dms.service` nebeneinander** (Plan 0.8 Nr. 120, seit dem Nachtlauf vom 26.11.2026 ohne
   `BusName=`): beide Pakete installiert (`alpe-shell` und `dux-shell`), `systemctl --user daemon-reload`, dann
   `systemctl --user status alpe.service dms.service` – beide geladen; der Ladefehler «Two services allocated for the
   same bus name» stünde nicht sicher in `status`, darum zusätzlich `systemd-analyze --user verify
   /usr/lib/systemd/user/alpe.service` und `journalctl --user -b -g "same bus name"` (beide ohne Treffer); Umzug (7.2
   Nr. 7) und `alpe umzug --zurueck` durchspielen, danach jeweils nur eine Shell aktiv und Mitteilungen kommen an
   (`notify-send test`). **Am Mac** dasselbe mit dem Paket von 1.0 dort (`dms-shell`; ob dessen Unit `BusName=` trägt,
   ist nicht nachgesehen – `systemctl --user cat dms.service`).
2. **Nebenwirkung von Plan 0.8 Nr. 120 (gefolgert):** Ohne `BusName=` lädt `alpe.service` auch neben Units anderer
   Mitteilungsdienste (dunst, mako, swaync), die den Namen tragen. Besitzt beim Start ein anderer Prozess den Namen,
   setzt der Dienst den sd_notify-Status «notifications handled by external process» (`core/internal/systemd/notify.go`)
   – zu sehen als «Status:» in `systemctl --user status alpe.service`. In der VM bzw. am Mac mit einem installierten
   Mitteilungsdienst ansehen.

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

- **Lücke der Namensprüfung: Binärdateien (24.11.2026, offen).** `tools/namen-pruefen.py` überspringt
  jede Datei mit einem Nullbyte in den ersten 8192 Bytes; Metadaten und Inhalte von PDF, PNG, JPEG,
  MP4, Schriften, Klängen, `.qsb` und HDF5 sieht sie nicht (61 versionierte Dateien). So blieb die
  Drucker-Testseite des Ursprungs unbemerkt (Titel, Metadaten und Seitentext nannten ihn). Einmalige
  Suche am 24.11.2026 über alle 61 Dateien nach den ausgeschriebenen Namen des Ursprungs (roh, als
  UTF-16 und in entpackten PDF-Strömen): Fund nur in der Testseite; die drei Bilder des Designs
  zeigen bloss zufällige Drei-Buchstaben-Folgen in komprimierten Daten. Die Testseite ist jetzt
  unkomprimierter Text und wird von der Namensprüfung gelesen, dazu prüft `tests/test_werte.py` sie.
  Für die übrigen Binärdateien gibt es keine laufende Prüfung; ein Suchen nach den kurzen Mustern
  (`dms`, `dank`, `dux`) wäre dort voller Scheintreffer – sinnvoll wäre höchstens eine Prüfung der
  Metadatenfelder je Dateityp (PNG-Textblöcke, EXIF, Namenstabellen der Schriften).

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
  für den Discord-Link des Ursprungs da (Entfernen laut 4.3 in C4). **`discord.svg` und `reddit.svg` entfernt am
  25.11.2026 (Nachtlauf vom 26.11.2026, Plan 0.8 Nr. 117).**
- **Offen (23.11.2026, Frist: G1): `docs/technik.md` beschreibt noch `tools/upstream.sh` und
  `schichten/*.patch`** (Abschnitte «Aufbau in drei Schichten» und «Neue Version des
  Ursprungsprojekts»). Beides gibt es seit B3 nicht mehr (`4a9a1c2` «Schichten aufgelöst»). Im
  selben Zug prüfen: Der Abschnitt «Tests» nennt noch `~/dux-shell` als Ort der KWin-Brücke und
  des Dienstes, «Unterbau» den Dienst `dms` und `tools/backend.sh` mit dem Quellbaum des
  Ursprungs. Mit der Doku in G1 (Plan 8.) neu schreiben.
