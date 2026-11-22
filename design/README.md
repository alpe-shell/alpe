# Design

Das Aussehen, mit dem Alpe ausgeliefert wird. `get.sh` spielt es bei der Installation ein (bei
bestehenden Einstellungen nur auf Nachfrage), später jederzeit mit `alpe design apply`.

| Ordner | Aufgenommen auf | Inhalt |
|---|---|---|
| `kde/` | KDE-Plasma-PC | Einstellungen der Shell, KWin-Effekte und -Fensterregeln, Sperrbildschirm |
| `hyprland/` | MacBook mit Hyprland | Einstellungen der Shell, hyprlock.conf |

Jeder Ordner enthält `settings.json` (Farben, Schriften, Leiste, Dock, Dash), `session.json`
(nur Gestaltung: Hintergrund, Material-Vorlage, Hell/Dunkel, Nachtlicht – kein Zustand wie angeheftete
Programme, Verläufe, Ort oder Bildschirme; Liste `SESSION_GESTALTUNG` in `tools/design.py`), `plugins.json` (Alpe-Plugins), `programme/`
(Einstellungen von kitty und fastfetch; unter KDE wird kitty Standard-Terminal), bei KDE `kwin.json`,
eigene Bilder unter `bilder/` und ein `manifest.json` mit Stand, Schriften und Hinweisen.

## Aufnehmen

```sh
alpe design export          # fragt bei jedem Bild, ob es ein eigenes ist
git -C ~/alpe diff          # nachsehen, was drin ist
```

Weggelassen wird, was zu einer Person oder einem Gerät gehört: Wetterort (beim neuen Nutzer folgt
das Wetter dem Standort), Sport-Favoriten und Streaming-Links, Bildschirm- und Gerätenamen (Leiste
und Dock erscheinen auf allen Bildschirmen), eigene Befehle, Verläufe, Fensterregeln nach Fenstertitel
und jeder Pfad in den eigenen Ordner. Bilder kommen nur mit, wenn man sie beim Export als eigene
bestätigt; fremde Fotos gehören nicht in ein öffentliches Repository.

## Einspielen

`alpe design apply` sichert die bisherigen Dateien unter `~/.config/alpe/design-sicherung/` und
ersetzt nur, was das Design festlegt; eigene andere Einstellungen bleiben. Angeheftet werden nur
Programme, die installiert sind. Fehlende Schriften nennt es am Schluss.
