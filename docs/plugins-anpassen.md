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

Alle Befehle unten sind für fish geschrieben, ein Befehl pro Zeile. Gibt es den Zielordner schon
(etwa von einem früheren Versuch), zuerst ansehen und selbst entscheiden – `cp -r` würde sonst
eine zweite Kopie *in* den vorhandenen Ordner legen:

```
ls ~/.config/alpe/plugins
```

## Was sich ändert

| Bisher | Alpe 1.1 |
|---|---|
| `import qs.DCommon.Widgets` | `import qs.Alpe.Widgets` |
| `DButton`, `DTextField`, `DActionButton` … (aus `qs.DCommon.Widgets`) | `AlpeButton`, `AlpeTextField`, `AlpeActionButton` … |
| `DankIcon`, `DankSlider`, `DankButton` … (aus `qs.Widgets`) | `AlpeIcon`, `AlpeSlider`, `AlpeButton` … aus `qs.Alpe.Widgets` |
| `DModal`, `DPopout`, `DTooltip` … (aus `qs.Modals.Common`, `qs.Widgets`) | `AlpeModal`, `AlpePopout`, `AlpeTooltip` … (Modul bleibt) |
| `import qs.Modules.DDash` | `import qs.Alpe.Dash` |
| Programm `dms` (`dms notify`, `dms ipc call …`, `dms cl copy`) | `alpe-dienst` (gleiche Unterbefehle) |
| `plugin.json`: `requires_dms` | `requires_alpe` (bezieht sich auf die Version von Alpe, z. B. `">=1.0"`) |
| `plugin.json`: Fähigkeit `dankbar-widget` | `bar-widget` |
| Ablage `~/.config/DankMaterialShell/plugins/` bzw. `~/.config/dms/plugins/` | `~/.config/alpe/plugins/` |

Unverändert bleiben `qs.Common`, `qs.Services`, `qs.Modules.Plugins`, `qs.Modals.Common` (als
Modul) und die Plugin-ID. Die Einstellungen der Plugins (`plugin_settings.json`) überträgt der
Umzug.

`import qs.Widgets` bleibt nur stehen, wenn die Datei ausser den `Dank*`-Typen noch andere Typen
daraus benutzt. Steht beides da, gewinnt bei gleichen Namen der zuletzt importierte Typ.

## PC: hueManager und sathiAi

### hueManager (derethil/dms-hue-manager)

Benutzt `DankIcon`, `DankSlider`, `DankListView`, `DankToggle`, `DankDropdown`, `DankButton`
aus `qs.Widgets` in `src/HueSettings.qml` und `src/Widgets/*.qml`. Kein Aufruf von `dms` im
Plugin selbst (nur in `devenv.nix`, für die Entwicklung).

```
mkdir -p ~/.config/alpe/plugins
cp -r ~/.config/dms/plugins/hueManager ~/.config/alpe/plugins/hueManager
cd ~/.config/alpe/plugins/hueManager
sed -i -E 's/\bDank(Icon|Slider|ListView|Toggle|Dropdown|Button)\b/Alpe\1/g' src/**.qml
sed -i -E 's/^import qs\.Widgets$/import qs.Widgets\nimport qs.Alpe.Widgets/' src/**.qml
```

In `plugin.json` die Beschreibung «from DMS» nach Wunsch anpassen.

### sathiAi (Shinda Singh)

Benutzt `qs.DCommon.Widgets` mit `DActionButton`, `DTextField`, `DDropdown`, `DButton`,
`DToggle`, `DSpinner`, ausserdem `ConfirmModal` aus `qs.Modals.Common` (bleibt) und ruft
`dms notify` sowie `dms ipc call settings openWith plugins` auf. `ui/DankRectangle.qml` ist eine
eigene Datei des Plugins und darf so heissen; umbenennen ist freiwillig. Eigene Änderungen an der
alten Kopie (etwa ein anderes Symbol in `Sathi.qml`) kommen mit der Kopie mit.

```
mkdir -p ~/.config/alpe/plugins
cp -r ~/.config/dms/plugins/sathiAi ~/.config/alpe/plugins/sathiAi
cd ~/.config/alpe/plugins/sathiAi
sed -i -E 's/^(\s*)import qs\.DCommon\.Widgets/\1import qs.Alpe.Widgets/' **.qml
sed -i -E 's/\bD(ActionButton|TextField|Dropdown|Button|Toggle|Spinner)\b/Alpe\1/g' **.qml
sed -i -E 's/\["dms", /["alpe-dienst", /' **.qml
```

`Sathi.qml` fängt einen Fehlschlag von `notify` ab und zeigt dann eine Meldung über
`ToastService`; das funktioniert unverändert.

## Mac: hueManager und calculator

### hueManager

Dieselben fünf Befehle wie am PC (Abschnitt oben).

### calculator (rochacbruno/DankCalculator, AGPL-3.0)

Benutzt keine `Dank*`-Typen. Zu ändern sind der Aufruf der Zwischenablage (`dms cl copy`) und
zwei Einträge in `plugin.json`.

```
mkdir -p ~/.config/alpe/plugins
cp -r ~/.config/dms/plugins/calculator ~/.config/alpe/plugins/calculator
cd ~/.config/alpe/plugins/calculator
sed -i -E 's/\["dms", "cl", "copy"/["alpe-dienst", "cl", "copy"/' CalculatorLauncher.qml
sed -i -E 's/"requires_dms": "[^"]*"/"requires_alpe": ">=1.0"/' plugin.json
sed -i -E 's/"requires": \["dms"\]/"requires": ["alpe-dienst"]/' plugin.json
```

Die AGPL verlangt, Änderungen kenntlich zu machen, wenn du die Fassung weitergibst: dann oben in
`CalculatorLauncher.qml` einen Kommentar mit Datum und Änderung ergänzen und eine `CHANGES.md`
dazulegen.

## Prüfen

Vor dem Wechsel auf 1.1 – in der Kopie darf keine alte Stelle mehr stehen. Der Befehl gibt nichts
aus, wenn alles angepasst ist (bei sathiAi bleibt die eigene Datei `ui/DankRectangle.qml` und ihre
Verwendung als Treffer stehen; das ist in Ordnung):

```
cd ~/.config/alpe/plugins
grep -rn -E --include='*.qml' --include='plugin.json' '\bDank[A-Z]|qs\.DCommon|qs\.Modules\.DDash|\["dms"|requires_dms' hueManager
```

Für `sathiAi` bzw. `calculator` den Ordnernamen am Ende ersetzen. Die Kopie unter
`~/.config/dms/plugins/` muss unverändert sein:

```
git -C ~/.config/dms/plugins/hueManager status --short
```

Unter 1.1: Plugin in den Einstellungen unter «Plugins» einschalten. Lädt es nicht, steht der Grund
auf derselben Seite beim Plugin und im Protokoll (`journalctl --user -u alpe.service -b`); eine
übersehene alte Stelle zeigt sich als «… is not a type» mit Datei und Zeile.
