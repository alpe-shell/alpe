# Fremde Plugins an Alpe 1.1 anpassen

Mit Alpe 1.1 heissen die internen Namen anders (Plan 2.3). Plugins, die für die Dux Modular
Shell geschrieben wurden, laden bis D7.8 noch über Übergangs-Hüllen weiter. Danach fallen
diese Hüllen weg, und die Plugins brauchen die neuen Namen. Diese Anleitung gilt für Plugins,
die nicht im Alpe-Repository liegen und deren Lizenz eine Weitergabe nicht erlaubt oder unklar
ist: **hueManager** und **sathiAi**. Du passt deine lokale Kopie selbst an.

## Was sich ändert

| Bisher | Alpe 1.1 |
|---|---|
| `import qs.DCommon.Widgets` | `import qs.Alpe.Widgets` |
| `DButton`, `DTextField`, `DActionButton` … (aus `qs.DCommon.Widgets`) | `AlpeButton`, `AlpeTextField`, `AlpeActionButton` … |
| `DankIcon`, `DankSlider`, `DankButton` … (aus `qs.Widgets`) | `AlpeIcon`, `AlpeSlider`, `AlpeButton` … aus `qs.Alpe.Widgets` |
| `DModal`, `DPopout`, `DTooltip` … (aus `qs.Modals.Common`, `qs.Widgets`) | `AlpeModal`, `AlpePopout`, `AlpeTooltip` … (Modul bleibt) |
| `import qs.Modules.DDash` | `import qs.Alpe.Dash` |
| Programm `dms` (`dms notify`, `dms ipc call …`, `dms cl copy`) | `alpe-dienst` (gleiche Unterbefehle) |
| `plugin.json`: `requires_dms` | `requires_alpe` (z. B. `">=1.1"`) |
| `plugin.json`: Fähigkeit `dankbar-widget` | `bar-widget` |
| Ablage `~/.config/DankMaterialShell/plugins/` bzw. `~/.config/dms/plugins/` | `~/.config/alpe/plugins/` |

Unverändert bleiben `qs.Common`, `qs.Services`, `qs.Modules.Plugins`, `qs.Modals.Common` (als
Modul) und die Plugin-ID; `plugin_settings.json` passt weiter.

`import qs.Widgets` bleibt nur stehen, wenn die Datei ausser den `Dank*`-Typen noch andere Typen
daraus benutzt. Steht beides da, gewinnt bei gleichen Namen der zuletzt importierte Typ.

## hueManager (derethil/dms-hue-manager)

Benutzt `DankIcon`, `DankSlider`, `DankListView`, `DankToggle`, `DankDropdown`, `DankButton`
aus `qs.Widgets` in `src/HueSettings.qml` und `src/Widgets/*.qml`. Kein Aufruf von `dms` im
Plugin selbst (nur in `devenv.nix`, für die Entwicklung).

Im Ordner des Plugins, ein Befehl pro Zeile (fish):

```
cd ~/.config/alpe/plugins/hueManager
sed -i -E 's/\bDank(Icon|Slider|ListView|Toggle|Dropdown|Button)\b/Alpe\1/g' src/**.qml
sed -i -E 's/^import qs\.Widgets$/import qs.Widgets\nimport qs.Alpe.Widgets/' src/**.qml
```

Danach prüfen, ob `import qs.Widgets` noch gebraucht wird (`grep -n -E 'Styled|Dank' src/**.qml`),
und in `plugin.json` die Beschreibung «from DMS» nach Wunsch anpassen.

## sathiAi (Shinda Singh)

Benutzt `qs.DCommon.Widgets` mit `DActionButton`, `DTextField`, `DDropdown`, `DButton`,
`DToggle`, `DSpinner`, ausserdem `ConfirmModal` aus `qs.Modals.Common` (bleibt) und ruft
`dms notify` sowie `dms ipc call settings openWith plugins` auf. `ui/DankRectangle.qml` ist eine
eigene Datei des Plugins und darf so heissen; umbenennen ist freiwillig.

```
cd ~/.config/alpe/plugins/sathiAi
sed -i -E 's/^(\s*)import qs\.DCommon\.Widgets/\1import qs.Alpe.Widgets/' **.qml
sed -i -E 's/\bD(ActionButton|TextField|Dropdown|Button|Toggle|Spinner)\b/Alpe\1/g' **.qml
sed -i -E 's/\["dms", /["alpe-dienst", /' **.qml
```

`Sathi.qml` fängt einen Fehlschlag von `notify` ab und zeigt dann eine Meldung über
`ToastService`; das funktioniert unverändert.

## Prüfen

Nach dem Anpassen die Shell neu laden (`alpe restart`) und im Protokoll nach Hinweisen suchen:
Solange die Übergangs-Hüllen noch da sind (bis D7.8), meldet jede noch alte Stelle beim Laden
«… is deprecated …» mit dem neuen Namen. Ein angepasstes Plugin erzeugt keine solche Meldung mehr.
