# Alpe – Arbeitsregeln für Claude Code

Alpe ist eine Desktop-Shell für Linux, massgeschneidert für die Schweiz. Sie läuft auf zwei Rechnern
des Maintainers und muss auf beiden einwandfrei funktionieren:

| Rechner | System | Compositor | Architektur |
|---|---|---|---|
| PC | CachyOS (Arch) | KWin 6.8 (Plasma ohne plasmashell) | x86_64 |
| MacBook Air M2 | Fedora Asahi Remix | Hyprland | aarch64 |

Andere Compositors (niri, sway, mango, labwc …) werden nicht unterstützt.

## Sprache und Ton

- Alle Texte für Menschen (Oberfläche, Meldungen, Doku, Commit-Nachrichten, Kommentare) auf
  Hochdeutsch in **Schweizer Schreibweise**: nie «ß», immer «ss». Anrede in der Oberfläche: Du.
- Antworten an den Maintainer: Deutsch, Du-Form, sachlich, fachlich tief. Linux-Grundlagen nicht erklären.
- Code-Bezeichner dürfen englisch sein; bestehende deutsche Bezeichner nicht umbenennen.

## Befehle, die der Maintainer selbst ausführen soll

Die Shell des Maintainers ist **fish**. In Befehlen für ihn:
- keine Heredocs, kein `$(…)`, kein `&&`-Verketten langer Ketten – ein Befehl pro Zeile
- Pfade mit Leerzeichen in Anführungszeichen
- Paketentfernungen immer zuerst anzeigen: `pacman -Rs --print …` (nicht `-Rns --print`),
  danach erst `sudo pacman -Rns …`

## Git und GitHub

- **Nie pushen, nie Tags setzen oder verschieben, nie Releases anlegen.** Das macht der Maintainer selbst.
- Arbeiten auf einem eigenen Branch (für Phase A: `phase-a`), kleine, thematisch saubere Commits.
- Nicht `main` umschreiben. Kein `git push --force`, kein `git reset --hard` auf fremde Arbeit.
- Vor jedem Commit `git diff --cached --name-status` gegen die beabsichtigte Liste prüfen und nur
  mit ausdrücklich genannten Pfaden committen (`git commit -- PFAD…`), nie den ganzen Index
  (Plan 0.8 Nr. 72).
- Bei einem Merge (dort lässt git `commit -- PFAD…` nicht zu): `git merge --no-commit`, dann
  `git diff --cached --name-status` gegen die Liste der Gegenseite, dann `git commit -F`; Beleg
  `git show -m --first-parent --name-status` (Plan 0.8 Nr. 72, 147).
- `KONTEXT.md` ist lokal und gitignored – lesen ja, nie committen.
- Keine fremden oder urheberrechtlich geschützten Bilder ins Repository.

## Dateien ändern

- Dateien werden nur mit dem Edit-Werkzeug geändert (neue Dateien mit Write) – nicht mit
  `sed -i`, `perl -i`, einem Python- oder Shell-Skript, das per `replace` schreibt, oder einem Heredoc.
  Das gilt auch für eine einzelne Zeile, für mehrere gleichlautende Stellen und für «nur Doku»: Der
  Maintainer will jede Änderung im Klartext sehen, und ein `sed` oder `replace` kann unbemerkt ins
  Leere gehen oder zu viel treffen.
- **Wenn Edit bei einer Datei nicht geht: anhalten und den Grund nennen** (Datei, Aufruf, Fehlermeldung
  im Wortlaut). Nicht auf `sed` oder ein Skript ausweichen. Bequemlichkeit (lange Stelle, viele
  Stellen) ist kein Grund.
- Ausgenommen sind nur diese drei Arten erzeugter Dateien, und nur über ihr eingechecktes Werkzeug:
  Attrappen über `make -C core mocks` (Plan 0.8 Nr. 62, 66), gemessene Grundlinien über
  `--grundlinie` (`ladepruefung.py`, `qmllint-pruefung.py`; Plan 0.8 Nr. 63, 70, 76) und das Standbild der
  Sperre über `tools/standbild.py` (Plan 0.8 Nr. 106, 122). Suchindex und
  Massenumbenennungen (`umbenennen.py`, `texte-ersetzen.py`) sind offen und werden entschieden, wenn sie
  anstehen (Plan 0.8 Nr. 111); dann vorher fragen.
- Ausgaben von Programmen (Protokolle, Build- und Install-Ergebnisse in Temp-Ordnern) fallen nicht unter
  diese Regel; Belege gehören zu diesen Ausgaben, wo sie auch liegen. Von der Sitzung verfasster oder geänderter
  Inhalt bleibt unter der Regel, auch in Temp-Ordnern (etwa eine Temp-Kopie für eine Gegenprobe oder eine
  Hilfsdatei). Weitere versionierte Dateien, die eingecheckte Werkzeuge erzeugen, werden einzeln entschieden
  (Plan 0.8 Nr. 122, 138).

## Das laufende System

Der Maintainer arbeitet auf dem PC, auf dem du läufst, und Alpe ist seine aktive Oberfläche.
- Ohne Rückfrage **nicht**: `dms.service`/`alpe.service` neu starten oder stoppen, `install.sh`,
  `get.sh`, `bootstrap.sh`, `alpe design apply`, `alpe kde …`, `alpe entfernen` gegen das echte
  `$HOME` ausführen, KWin-Konfiguration schreiben, kglobalaccel ändern.
- Lesen von `~/.config/dms`, `~/.local/state/dms`, `~/.config/alpe`, `~/.config/kwinrulesrc`
  ist erlaubt (für Migrationstests: Kopie in ein Temp-`$HOME` ziehen und dort arbeiten).
- Tests laufen mit eigenem `HOME`/`XDG_*` in einem Temp-Verzeichnis, nie gegen das echte.
- **Go-Tests laufen nur über den abgeschotteten Weg** (eigenes `HOME`/`XDG_*` im Temp-Ordner), nie mit
  dem echten `HOME`. Wer von Hand startet, liest `GOMODCACHE` und `GOCACHE` (und `GOPATH`) mit
  `go env` aus, **bevor** `HOME` wechselt, und setzt sie als feste absolute Pfade – nach dem Wechsel
  zeigte `go env` schon in den Temp-Ordner. Sollen die Caches selbst im Temp-Ordner liegen, gehört
  `GOFLAGS=-modcacherw` dazu, damit kein schreibgeschützter Modul-Cache liegen bleibt
  (Plan 0.8 Nr. 40).
- Kein `pkill`, `killall` oder `pkill -f`, auch nicht mit Pfadmustern: Die echte Shell läuft unter
  denselben Programmnamen (`qs`/`quickshell`, `dms`/`alpe`). Prozesse der Ladeprüfung nur über ihren
  Scope beenden (`systemctl --user stop alpe-ladepruefung-<zeit>.scope`).
- Den echten Installationstest macht der Maintainer in der VM (CachyOS-VM mit Snapshot «frisch») und am Mac.

## Prüfen vor jedem Commit

```
bash tools/test.sh          # = alpe test, dieselben Prüfungen wie auf GitHub Actions
```

Alles muss grün sein – nach jedem Commit, und zwar auf dem Commit selbst in einem Temp-Worktree
(`git worktree add --detach`), nicht auf einem baumgleichen Vorgänger und nicht auf dem
Arbeitsbaum (Plan 0.8 Nr. 72). Dafür gibt es `bash tools/test-commit.sh HASH [HASH …]` (Temp-Worktree,
eigenes `HOME`/`XDG_*`, Go-Caches übernommen, Protokoll `test-<voller Hash>.log` unter
`$ALPE_TEST_PROTOKOLLE`). **Es nimmt nur volle Hashes (40 Hex-Zeichen); `HEAD`, Branch-Namen und
gekürzte Hashes lehnt es ab** – am 24.11.2026 prüfte ein Sammellauf mit `HEAD` den falschen Commit.
Ausgabe und Protokoll nennen den geprüften Hash.
**Die Haltprüfung startet nur, wenn für die Spitze ein grünes Protokoll von `tools/test.sh` mit vollem
Hash vorliegt:** `bash tools/test-commit.sh --gruen <voller Hash der Spitze>` muss 0 liefern, bevor die
erste Ladeprüfung, qmllint oder `go vet` des Halts läuft. Neue Funktion → neuer Test. Shell-Skripte: `bash -n`, QML-Seiten laden
in den Harnessen unter `entwicklung/`.

**Ausgaben von Tests und Prüfungen nie durch eine Pipe kürzen** (`tail`, `head`, `grep`), ohne
`pipefail` zu setzen – sonst gilt der Rückgabewert des letzten Befehls der Pipe, und ein roter Lauf
sieht grün aus (so blieb am 23.11.2026 ein roter Plan-Commit unbemerkt). Bevorzugt: die Ausgabe in eine Datei schreiben,
den Rückgabewert des Prüfbefehls selbst auswerten und erst danach den Schluss der Datei lesen.

Ladeprüfung (`entwicklung/ladepruefung/ladepruefung.py`) einmal pro Halt auf dem Endstand unter
KWin und Hyprland, **in zwei Varianten**: «gesperrt» (ohne Option; das Design sperrt beim Start)
und «offen» (`--offen`: ohne `lockAtStartup`, mit sichtbarer Material-Vorlage, **dazu als
Abdeckungs-Zusätze im Temp-HOME `workspaceSwitcher` und `launcherButton` im Logo-Modus `"alpe"`
eingeschaltet** – «offen» ist also nicht das ausgelieferte Design, das prüft «gesperrt»; Plan 0.8
Nr. 77), je gegen die eigene
Grundlinie (Plan 0.8 Nr. 70). Grundlinien können Meldungen als sporadisch kennzeichnen
(`SPORADISCH k/n: …`, beobachtete Häufigkeit); eine neue Meldung, die nicht in jedem Lauf auftritt,
wird vor dem Einordnen mehrfach gegen den Stand vor der Änderung gegengemessen (Plan 0.8 Nr. 76).
**Ladeprüfungen laufen nur in Ruhe:** nie neben Tests (`tools/test.sh`, `tools/test-commit.sh`,
`go test`, `go vet`, qmllint), Builds oder anderen Läufen (auch keiner zweiten Ladeprüfung, keinem
Klon oder Download) – erst starten, wenn alles andere beendet ist, und nichts anstossen, bis der Lauf
zu Ende ist. Anlass: Am 24.11.2026 erschienen unter Hyprland «offen» drei Meldungen je einmal in vier
Läufen unter Last und in 24 ruhigen Läufen nie (`docs/plan/offene-faelle.md`, «Ladeprüfung»).
**Wiederholungsregel für genau diese drei** – Notizblock «Tab file does not exist» (samt der
`FileView`-Zeile dazu), `DeferredAction.qml` «Cannot read property 'stop' of null», ShaderEffect
«'source' does not have a matching property»: Sind sie die einzigen fremden Meldungen eines Laufs,
wird er bis zu zweimal in Ruhe wiederholt. Die Prüfung gilt als bestanden, sobald ein Lauf ohne
fremde Meldung endet; die Zählung aller Läufe, auch der mit Meldung, kommt in den Bericht. Jede
andere fremde Meldung bleibt ein Fehler, und die drei stehen in keiner Grundlinie «offen».
Unter Hyprland `ALPE_LP_TMP=/tmp/claude-1000` (höchstens 19 Zeichen, sonst legt Hyprland seinen
Socket nicht an); ein Lauf ohne Hyprland-IPC gilt als gescheitert.
Unter beiden Compositors gilt ein Lauf nur, wenn die Oberfläche die Verbindung zum Dienst meldet
(`Connected (API v…)`); sonst ist er gescheitert und liefert nichts für die Grundlinie (Plan 0.8 Nr. 81).
Im Temp-HOME sind dabei alle Plugins unter `plugins/` eingeschaltet,
damit Plugins im Repo mitgeprüft werden (Plan 0.8 Nr. 33). Zum Halt gehört ein Bild der Variante
«offen» unter Hyprland (`--offen --bild DATEI`, aufgenommen mit `alpe-dienst screenshot full`;
grim wird nicht benutzt), das angesehen und dem Maintainer beschrieben wird (Plan 0.8 Nr. 71).
**Haltbilder heissen nach Compositor und Variante. Pflicht bei jedem Halt sind vier** (Plan 0.8 Nr. 71):
`halt-hyprland-offen.png` (`hyprland --offen --bild`), `halt-hyprland-gesperrt.png`
(`hyprland --bild-sperre`, die Sperre der Shell), `halt-kwin-offen.png` (`kwin --offen --bild`) und
`halt-kwin-gesperrt-schreibtisch.png` (`kwin --bild-schreibtisch`: der Schreibtisch im ausgelieferten
Design, Variante «gesperrt» ohne Abdeckungs-Zusätze – **nicht die Sperre**; unter KWin sperrt KDE,
`kwin --bild-sperre` bricht ab). Die zwei KWin-Bilder kommen über `kwinbild.py` und gelten, solange
dieser Weg A besteht (Plan 0.8 Nr. 103, befristet bis zum Entscheid über Weg B nach G1). Jedes der vier
wird angesehen und dem Maintainer beschrieben. Ein Bildlauf gilt zugleich als Lauf seiner Variante gegen die
Grundlinie (`kwin --bild-schreibtisch` also als KWin «gesperrt»).

Zur Haltprüfung gehört qmllint aus Qt 6 (`/usr/lib/qt6/bin/qmllint`) über `shell/` – nicht in
`tools/test.sh`: `python3 entwicklung/qmllint/qmllint-pruefung.py` vergleicht mit
`entwicklung/qmllint/grundlinie.txt` (4900 Meldungen seit dem 24.11.2026; vorher 4902, gezählt mit
diesem Skript auf `6305cb1` – die zwei Meldungen zu `Modules/Lock/Lock.qml` fehlten seit D7.8 in jedem
Lauf; eine andere Zahl aus früheren Notizen gilt nicht). Bei jedem Halt vergleichen und jede neue Meldung einzeln
einordnen (beheben oder mit Begründung in die Grundlinie; Plan 0.8 Nr. 63).

Dienst und Systembus (Plan 0.8 Nr. 82, 84, 85; `docs/plan/dienst-systembus.md`): Im Dienst ruft nichts
`dbus.SystemBus()` oder `dbus.ConnectSystemBus()` auf (`tests/test_werte.py` prüft das). Die eine
Verbindung baut `core/internal/systembus` mit Zeitgrenze auf; Manager bekommen sie hereingereicht und
schliessen sie nie. **Grundsatz: keine Sperre über einen Bus- oder Netzaufruf hinweg halten.**
Die Gegenprobe der Ladeprüfung mit stummem Ersatz-Systembus (`ALPE_LP_STUMMER_BUS=1`) **gehört zur
Haltprüfung: bei jedem Halt einmal, unter einem Compositor** (Variante «gesperrt» genügt). Der Go-Test
prüft nur die Bausteine; kehrt der Fehler in der Startreihenfolge des Dienstes zurück, zeigt ihn nur
dieser Lauf. Er besteht, wenn die Oberfläche `Connected` meldet und der Dienst den Ausfall genau einmal
meldet; mit der Grundlinie wird er nicht verglichen.

Ebenfalls am Halt: `go vet ./...` in `core/` ohne Meldung. Attrappen unter `core/internal/mocks`
nie von Hand ändern, sondern mit `make -C core mocks` neu erzeugen: genau **mockery v3.9.1**
(`MOCKERY_VERSION` im Makefile, das Ziel bricht bei einer anderen Version ab), Vorlage
`core/.mockery/testify.templ` (Plan 0.8 Nr. 62, 66).

## Projektregeln

- Version und Codename: Alle Fassungen heissen «Zugerberg», gezählt wird nur die Nummer
  (`Brand.qml`, `CHANGELOG.md`). Die nächste Fassung ist 1.1.
- Persönliches gehört nie ins Repo: kein Wetterort, keine Sport-Favoriten, keine absoluten
  Pfade ins eigene Home-Verzeichnis, keine Bildschirmnamen. `tools/design.py` schrubbt das beim Export.
- Neue eigene Testdaten verwenden MAC-Adressen aus `00:00:5E:00:53:00/24` (RFC 7042) und IP-Adressen
  aus `192.0.2.0/24`, `198.51.100.0/24` oder `203.0.113.0/24` (RFC 5737). Die Werteprüfung
  (`tools/werte-pruefen.py`) nimmt genau diese Bereiche aus; alles andere braucht eine Ausnahme mit
  Frist und Grund in `tools/werte-ausnahmen.txt`.
- Installationserlebnis zählt: `get.sh` muss auf einem frischen CachyOS (KDE) und einem frischen
  Fedora Asahi (Hyprland) ohne Handarbeit durchlaufen und genau das ausgelieferte Alpe-Design zeigen.
- Lizenz und Herkunft: Alpe ist ein Fork der Dux Modular Shell (DMS). Deren Lizenz und
  Copyright-Hinweise bleiben erhalten (LICENSE/NOTICE), auch wenn der Name sonst verschwindet.

## Grössere Aufgaben

Erst einen Plan als Markdown unter `docs/plan/` schreiben und dem Maintainer zur Freigabe vorlegen,
dann umsetzen. Offene Entscheidungen als Frage stellen statt raten.

## Arbeitsweise (Kontext sparen)

- Beim Einstieg aus `docs/plan/phase-a-plan.md` nur «Stand» und die Abschnitte zum aktuellen
  Schritt lesen, nicht den ganzen Plan; den Rest und `offene-faelle.md` nur bei einer konkreten Frage.
- Trefferlisten von `umbenennen.py` und `namen-pruefen.sh` in Dateien unter `/tmp/claude-1000/`
  schreiben. In den Kontext kommen nur Zählungen pro Name und auffällige Einzelfälle (Treffer in
  Strings, Übersetzungen, Kommentaren, Kollisionen).
- Von `tools/test.sh` bei grünem Lauf nur die Zusammenfassung lesen, bei rotem Lauf nur den
  Ausschnitt mit dem Fehler.
- Grosse Dateien gezielt mit Zeilenbereich oder `grep` lesen statt ganz.
