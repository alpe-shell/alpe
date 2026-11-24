# Fremde Plugins an Alpe 1.1 anpassen

Mit Alpe 1.1 heissen die internen Namen anders (Plan 2.3). Die Übergangs-Hüllen für Plugins, die
für die Dux Modular Shell geschrieben wurden, gibt es seit D7.8 nicht mehr: Ein unangepasstes
Plugin lädt unter 1.1 nicht («DankIcon is not a type», «module "qs.DCommon.Widgets" is not
installed»). Diese Anleitung gilt für Plugins, die nicht im Alpe-Repository liegen, weil ihre
Lizenz eine Weitergabe nicht erlaubt, unklar oder eine andere ist: **hueManager**, **sathiAi**
und **calculator**. Du passt eine eigene Kopie an.

## Grundsatz: zwei Ordner, die alte Kopie bleibt

| Ordner | Wer liest ihn | Was dort liegt |
|---|---|---|
| `~/.config/dms/plugins/` | Alpe 1.0 | die Plugins wie bisher – **nicht anfassen**, solange auf dem Rechner noch 1.0 läuft |
| `~/.config/alpe/plugins/` | Alpe 1.1 | die angepasste Fassung |

Du kopierst das Plugin aus dem alten Ordner in den neuen und änderst nur die Kopie. So läuft 1.0
unverändert weiter, und 1.1 findet beim ersten Start schon die passende Fassung. Der Umzug
(`alpe umzug`, Plan 7.2) überschreibt eine Fassung, die unter `~/.config/alpe/plugins/` schon
liegt, nicht.

Alle Befehle unten sind für fish geschrieben, ein Befehl pro Zeile.

**Drei Regeln, damit kein Befehl am falschen Ort läuft** (Zwischenfall vom 23.11.2026,
`docs/plan/offene-faelle.md`, «Mac-Test»):

1. **Jeder Block gilt nur auf dem Rechner, der darüber steht**, und nur, wenn der Prüfbefehl am
   Anfang des Blocks den Ordner des Plugins nennt. Meldet `ls` «nicht gefunden», liegt das Plugin
   auf diesem Rechner nicht: den ganzen Block auslassen.
2. **Kein `cd`, keine relativen Muster.** Jeder `sed`-Befehl nennt den vollen Pfad unter
   `~/.config/alpe/plugins/<Plugin>/`. Einen Befehl nie auf ein Muster wie `**.qml` ohne Pfad
   davor kürzen – er träfe alle QML-Dateien unter dem Ordner, in dem das Terminal gerade steht.
3. **`cp -r` nur in einen Zielordner, den es noch nicht gibt.** Gibt es ihn schon (etwa von einem
   früheren Versuch), legt `cp -r` eine verschachtelte Kopie *in* den vorhandenen Ordner
   (`…/hueManager/hueManager`). Darum vor einem zweiten Versuch nicht erneut kopieren, sondern die
   Kopie zuerst ganz löschen – mit festem Pfad und `rm -rf`, weil die Git-Packdateien in der Kopie
   schreibgeschützt sind und `rm -r` bei jeder nachfragt:

```
ls ~/.config/alpe/plugins
rm -rf ~/.config/alpe/plugins/hueManager
```

(Die zweite Zeile nur für das Plugin, das neu kopiert werden soll, und nur unter
`~/.config/alpe/plugins/` – nie unter `~/.config/dms/plugins/`.)

## Was sich ändert

| Bisher | Alpe 1.1 |
|---|---|
| `import qs.DCommon.Widgets` | `import qs.Alpe.Widgets` |
| `DButton`, `DTextField`, `DActionButton` … (aus `qs.DCommon.Widgets`) | `AlpeButton`, `AlpeTextField`, `AlpeActionButton` … |
| `DankIcon`, `DankSlider`, `DankButton` … (aus `qs.Widgets`) | `AlpeIcon`, `AlpeSlider`, `AlpeButton` … aus `qs.Alpe.Widgets` |
| `DModal`, `DPopout`, `DTooltip` … und `DankModal`, `DankPopout`, `DankTooltip`, `DankOSD`, `DankSeekbar`, `DankSlideout`, `DankBackdrop`, `DankFloatingWindow`, `DankFocusGrab`, `DankAnimatedAlbumArt` (aus `qs.Modals.Common`, `qs.Widgets`) | `AlpeModal`, `AlpePopout`, `AlpeTooltip` … – **das Modul bleibt** (`qs.Modals.Common` bzw. `qs.Widgets`), kein Import von `qs.Alpe.Widgets` nötig |
| `DankAnim`, `DankColorAnim`, `DankSocket` (aus `qs.Common`) | `AlpeAnim`, `AlpeColorAnim`, `AlpeSocket` aus `qs.Alpe.Common` |
| `import qs.Modules.DDash` | `import qs.Alpe.Dash` |
| Programm `dms` (`dms notify`, `dms ipc call …`, `dms cl copy`) | `alpe-dienst` (gleiche Unterbefehle) |
| `plugin.json`: `requires_dms` | `requires_alpe` (bezieht sich auf die Version von Alpe, siehe unten) |
| `plugin.json`: Fähigkeit `dankbar-widget` | `bar-widget` |
| `plugin.json`: `"requires": ["dms"]` | `"requires": ["alpe-dienst"]` |
| Ablage `~/.config/DankMaterialShell/plugins/` bzw. `~/.config/dms/plugins/` | `~/.config/alpe/plugins/` |

Unverändert bleiben `qs.Common`, `qs.Services`, `qs.Modules.Plugins`, `qs.Modals.Common` (als
Modul) und die Plugin-ID. Die Einstellungen der Plugins (`plugin_settings.json`) überträgt der
Umzug. Die Seite der Einstellungen heisst weiterhin `plugins`
(`alpe-dienst ipc call settings openWith plugins`).

**Ein alter Typ, zwei alte Namen, ein neuer.** `DButton` und `DankButton`, `DDropdown` und
`DankDropdown`, `DToggle` und `DankToggle` (und alle anderen Paare) werden zu demselben Typ
`AlpeButton`, `AlpeDropdown`, `AlpeToggle`. Das ist kein Zusammenlegen zweier Bauteile: Die
`Dank*`-Namen waren schon in der Dux Modular Shell reine Weiterleitungen auf die `D*`-Typen, und
D7 hat nur umbenannt. Eigenschaften, Signale und Funktionen sind dieselben wie vorher (geprüft
gegen den Stand des Ursprungs für `Button`, `Dropdown`, `Toggle`, `ListView`, `Spinner`, `Icon`,
`Slider`, `ActionButton`, `TextField`); `AlpeListView` und `AlpeSpinner` gibt es.

**`requires_alpe`.** Die Angabe wird mit der Version von Alpe verglichen (`Brand.version`); passt
sie nicht, zeigt die Plugin-Seite einen Hinweis, geladen wird das Plugin trotzdem. In dieser
Anleitung steht `">=1.0"`. **Das gilt nur für den Test vor 1.1:** Bis zum Abschluss von 1.1 meldet
der Entwicklungsstand noch die Version 1.0, und `">=1.1"` ergäbe bei jedem Start den Hinweis. Mit
dem Erscheinen von 1.1 gehört `">=1.1"` hinein (die Anleitung wird dann umgestellt).

`import qs.Widgets` bleibt nur stehen, wenn die Datei ausser den `Dank*`-Typen noch andere Typen
daraus benutzt. Steht beides da, gewinnt bei gleichen Namen der zuletzt importierte Typ.

## PC: hueManager und sathiAi

### hueManager (derethil/dms-hue-manager)

Benutzt `DankIcon`, `DankSlider`, `DankListView`, `DankToggle`, `DankDropdown`, `DankButton`
aus `qs.Widgets` in `src/HueSettings.qml` und `src/Widgets/*.qml`. Kein Aufruf von `dms` im
Plugin selbst (nur in `devenv.nix`, für die Entwicklung).

**Gilt am PC und am Mac.** Zuerst prüfen, ob das Plugin auf diesem Rechner liegt und ob es die
Kopie noch nicht gibt – die erste Zeile muss den Ordner nennen, die zweite «nicht gefunden» melden:

```
ls -d ~/.config/dms/plugins/hueManager
ls -d ~/.config/alpe/plugins/hueManager
```

Nur dann:

```
mkdir -p ~/.config/alpe/plugins
cp -r ~/.config/dms/plugins/hueManager ~/.config/alpe/plugins/hueManager
sed -i -E 's/\bDank(Icon|Slider|ListView|Toggle|Dropdown|Button)\b/Alpe\1/g' ~/.config/alpe/plugins/hueManager/src/**.qml
sed -i -E 's/^import qs\.Widgets$/import qs.Widgets\nimport qs.Alpe.Widgets/' ~/.config/alpe/plugins/hueManager/src/**.qml
```

**Die letzte Zeile (Import) darf nur einmal laufen.** Sie hängt hinter jedes `import qs.Widgets`
eine Zeile `import qs.Alpe.Widgets`; ein zweiter Lauf hängt sie noch einmal an, und der Import
steht doppelt. Das schadet beim Laden nicht, ist aber unsauber. Nachsehen (gibt nichts aus, wenn
keine Datei den Import mehr als einmal hat):

```
grep -rc --include='*.qml' '^import qs.Alpe.Widgets' ~/.config/alpe/plugins/hueManager | grep -v ':[01]$'
```

`plugin.json`: **keine Änderung nötig.** Die Datei von hueManager 0.5.0 enthält weder
`requires_dms` noch eine Fähigkeit `dankbar-widget` noch `"requires"` (nur `id`, `name`,
`description`, `version`, `author`, `icon`, `type`, `component`, `settings`, `permissions`).
Freiwillig: die Beschreibung «from DMS» anpassen und `"requires_alpe": ">=1.0"` ergänzen. Hat eine
neuere Fassung des Plugins einen der drei Einträge, gelten die Zeilen aus dem Abschnitt zu
calculator.

### sathiAi (Shinda Singh)

Benutzt `qs.DCommon.Widgets` mit `DActionButton`, `DTextField`, `DDropdown`, `DButton`,
`DToggle`, `DSpinner`, ausserdem `ConfirmModal` aus `qs.Modals.Common` (bleibt) und ruft
`dms notify` sowie `dms ipc call settings openWith plugins` auf. `ui/DankRectangle.qml` ist eine
eigene Datei des Plugins und darf so heissen; umbenennen ist freiwillig. Eigene Änderungen an der
alten Kopie (etwa ein anderes Symbol in `Sathi.qml`) kommen mit der Kopie mit.

**Gilt nur am PC – am Mac gibt es sathiAi nicht; dort den ganzen Block auslassen.** Zuerst prüfen:
Die erste Zeile muss den Ordner nennen, die zweite «nicht gefunden» melden.

```
ls -d ~/.config/dms/plugins/sathiAi
ls -d ~/.config/alpe/plugins/sathiAi
```

Nur dann:

```
mkdir -p ~/.config/alpe/plugins
cp -r ~/.config/dms/plugins/sathiAi ~/.config/alpe/plugins/sathiAi
sed -i -E 's/^(\s*)import qs\.DCommon\.Widgets/\1import qs.Alpe.Widgets/' ~/.config/alpe/plugins/sathiAi/**.qml
sed -i -E 's/\bD(ActionButton|TextField|Dropdown|Button|Toggle|Spinner)\b/Alpe\1/g' ~/.config/alpe/plugins/sathiAi/**.qml
sed -i -E 's/\["dms", /["alpe-dienst", /' ~/.config/alpe/plugins/sathiAi/**.qml
```

`Sathi.qml` fängt einen Fehlschlag von `notify` ab und zeigt dann eine Meldung über
`ToastService`; das funktioniert unverändert. Die dritte Zeile trifft die drei Aufrufe im Plugin
(`["dms", "notify", …` in `Sathi.qml`, `["dms", "ipc", "call", "settings", "openWith", "plugins"]`
in `ui/ChatBottomBar.qml` und `ui/EmptyChatState.qml`); die Seite `plugins` heisst in 1.1 gleich.
Die erste Zeile ersetzt den Import und kann darum gefahrlos zweimal laufen.

`plugin.json`: **keine Änderung nötig.** Die Datei von sathiAi 1.26.46 enthält weder
`requires_dms` noch eine Fähigkeit `dankbar-widget` noch `"requires"` (zusätzlich zu den üblichen
Feldern nur `"dependencies": []`). Freiwillig: `"requires_alpe": ">=1.0"` ergänzen. Der Eintrag
`dms ipc call plugins reload …` in `.vscode/settings.json` gehört zur Entwicklungsumgebung des
Autors und wird von Alpe nicht gelesen.

## Mac: hueManager und calculator

### hueManager

Der Block «hueManager» oben gilt unverändert auch am Mac: die beiden Prüfbefehle, dann die vier
Befehle, dann die Nachschau zum doppelten Import. **Den Block «sathiAi» am Mac nicht ausführen.**

### calculator (rochacbruno/DankCalculator, AGPL-3.0)

Benutzt keine `Dank*`-Typen. Zu ändern sind der Aufruf der Zwischenablage (`dms cl copy`) und
zwei Einträge in `plugin.json`.

**Gilt am Mac** (am PC liegt die für Alpe angepasste Fassung schon fertig in `~/alpe-plugins`; dort
diesen Block nicht ausführen, sondern den Ordner von dort kopieren). Zuerst prüfen: Die erste Zeile muss den Ordner nennen, die zweite
«nicht gefunden» melden.

```
ls -d ~/.config/dms/plugins/calculator
ls -d ~/.config/alpe/plugins/calculator
```

Nur dann:

```
mkdir -p ~/.config/alpe/plugins
cp -r ~/.config/dms/plugins/calculator ~/.config/alpe/plugins/calculator
sed -i -E 's/\["dms", "cl", "copy"/["alpe-dienst", "cl", "copy"/' ~/.config/alpe/plugins/calculator/CalculatorLauncher.qml
sed -i -E 's/"requires_dms": "[^"]*"/"requires_alpe": ">=1.0"/' ~/.config/alpe/plugins/calculator/plugin.json
sed -i -E 's/"requires": \["dms"\]/"requires": ["alpe-dienst"]/' ~/.config/alpe/plugins/calculator/plugin.json
```

**Hinweis zum Verlauf:** Das Protokoll meldet beim ersten Start «Read of
~/.config/alpe/plugins/calculator_history.json failed». Das Plugin legt seinen Verlauf im
Sammelordner der Plugins ab statt im eigenen Ordner (`pluginDirectory`); gibt es die Datei noch
nicht, meldet Quickshell das Lesen als gescheitert, und das Plugin beginnt mit leerem Verlauf.
Unter 1.0 ist es gleich (beim Mac-Test am 23.11.2026 beobachtet) – kein Fehler von Alpe, nichts
anzupassen.

Die AGPL verlangt, Änderungen kenntlich zu machen, wenn du die Fassung weitergibst: dann oben in
`CalculatorLauncher.qml` einen Kommentar mit Datum und Änderung ergänzen und eine `CHANGES.md`
dazulegen; die Datei `LICENSE` bleibt unverändert.

**Dasselbe gilt für das lokale Repository `~/alpe-plugins`**, in dem die für Alpe angepasste
Fassung des calculator liegt: Sobald es eine Remote bekommt und gepusht wird, ist das eine
Weitergabe. Dann müssen dort vorliegen: ein Änderungsvermerk mit Datum im Kopf jeder geänderten
Quelldatei, eine `CHANGES.md`, die **jede** geänderte Datei nennt (auch `README.md` und
`plugin.json`), und die unveränderte `LICENSE` des Originals. Jede spätere Änderung – etwa
`requires_alpe` auf `">=1.1"` – bekommt einen eigenen Eintrag mit Datum.

## Prüfen

Vor dem Wechsel auf 1.1 – in der Kopie darf keine alte Stelle mehr stehen.

**1. Bekannte alte Stellen.** Jeder Befehl gibt nichts aus, wenn alles angepasst ist. Bei sathiAi
bleiben die eigene Datei `ui/DankRectangle.qml` und ihre Verwendung als Treffer stehen; das ist
in Ordnung.

```
grep -rn -E --include='*.qml' --include='plugin.json' '\bDank[A-Z]|qs\.DCommon|qs\.Modules\.DDash|\["dms"|requires_dms|dankbar-widget' ~/.config/alpe/plugins/hueManager
grep -rn -E --include='*.qml' --include='plugin.json' '\bDank[A-Z]|qs\.DCommon|qs\.Modules\.DDash|\["dms"|requires_dms|dankbar-widget' ~/.config/alpe/plugins/sathiAi
grep -rn -E --include='*.qml' --include='plugin.json' '\bDank[A-Z]|qs\.DCommon|qs\.Modules\.DDash|\["dms"|requires_dms|dankbar-widget' ~/.config/alpe/plugins/calculator
```

**2. Breite Suche nach `dms`, von Hand durchsehen.** Das Muster oben findet `["dms"` nur, wenn es
so auf einer Zeile steht. Ein Aufruf in einem mehrzeiligen Array, in einem `sh -c`-Text oder in
einer zusammengesetzten Zeichenkette fällt durch. Darum zusätzlich jede Stelle mit dem Wort `dms`
ansehen (Gross- und Kleinschreibung egal) und einzeln entscheiden. Unbedenklich sind Texte und
Kommentare (Beschreibung «from DMS», README, `CHANGES.md`), Dateien der Entwicklungsumgebung
(`devenv.nix`, `.vscode/`) und beim calculator der Vermerk im Kopf von `CalculatorLauncher.qml`;
anzupassen ist jeder Aufruf des Programms `dms`.

```
grep -rn -i -w --exclude-dir=.git 'dms' ~/.config/alpe/plugins/hueManager
grep -rn -i -w --exclude-dir=.git 'dms' ~/.config/alpe/plugins/sathiAi
grep -rn -i -w --exclude-dir=.git 'dms' ~/.config/alpe/plugins/calculator
```

**3. Typen ohne Import.** Zwei kurze Befehle je Plugin, ohne Pipe (lange Zeilen mit Pipe brechen
beim Einfügen um). Der erste nennt die Dateien, die einen `Alpe…`-Typ benutzen, der zweite die
Dateien, denen `import qs.Alpe.Widgets` fehlt. **Keine Datei aus der ersten Liste darf in der
zweiten stehen.** Eine Datei in beiden Listen ist nur dann in Ordnung, wenn sie ausschliesslich
Typen benutzt, deren Modul geblieben ist (`AlpeModal` aus `qs.Modals.Common`; `AlpePopout`,
`AlpeTooltip` und die anderen aus der Tabelle oben aus `qs.Widgets`). Beim calculator bleibt die
erste Liste leer (er benutzt keine solchen Typen), die zweite nennt dann alle seine QML-Dateien.

```
grep -rlE --include='*.qml' '\bAlpe[A-Z]' ~/.config/alpe/plugins/hueManager
grep -rL --include='*.qml' 'import qs.Alpe.Widgets' ~/.config/alpe/plugins/hueManager
```

```
grep -rlE --include='*.qml' '\bAlpe[A-Z]' ~/.config/alpe/plugins/sathiAi
grep -rL --include='*.qml' 'import qs.Alpe.Widgets' ~/.config/alpe/plugins/sathiAi
```

```
grep -rlE --include='*.qml' '\bAlpe[A-Z]' ~/.config/alpe/plugins/calculator
grep -rL --include='*.qml' 'import qs.Alpe.Widgets' ~/.config/alpe/plugins/calculator
```

**4. Die alte Kopie ist unverändert.** Ist die alte Kopie ein Git-Klon, zeigt `git status` es
direkt. Der erste Befehl sagt, ob sie einer ist (`true`); der zweite gibt dann nichts aus:

```
git -C ~/.config/dms/plugins/hueManager rev-parse --is-inside-work-tree
git -C ~/.config/dms/plugins/hueManager status --short
git -C ~/.config/dms/plugins/sathiAi rev-parse --is-inside-work-tree
git -C ~/.config/dms/plugins/sathiAi status --short
git -C ~/.config/dms/plugins/calculator rev-parse --is-inside-work-tree
git -C ~/.config/dms/plugins/calculator status --short
```

Bei sathiAi zeigt `git status` auch eigene Änderungen, die es schon vor der Anpassung gab; sie
sind kein Fehler. Meldet der erste Befehl einen Fehler («kein Git-Repository»), als Ausweg die
alte mit der neuen Kopie vergleichen. **Unterscheiden dürfen sich nur die Dateien, die die
`sed`-Zeilen oben angepasst haben** (bei hueManager QML-Dateien unter `src/`, bei sathiAi
QML-Dateien, beim calculator `CalculatorLauncher.qml` und `plugin.json`); jede andere Zeile der
Ausgabe heisst, dass an einer der beiden Kopien noch etwas geändert wurde:

```
diff -rq ~/.config/dms/plugins/hueManager ~/.config/alpe/plugins/hueManager
diff -rq ~/.config/dms/plugins/sathiAi ~/.config/alpe/plugins/sathiAi
diff -rq ~/.config/dms/plugins/calculator ~/.config/alpe/plugins/calculator
```

Unter 1.1: Plugin in den Einstellungen unter «Plugins» einschalten. Lädt es nicht, steht der Grund
auf derselben Seite beim Plugin und im Protokoll (`journalctl --user -u alpe.service -b`); eine
übersehene alte Stelle zeigt sich als «… is not a type» mit Datei und Zeile.
