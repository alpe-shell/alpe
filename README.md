<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo/alpe-logo-dunkel.svg">
    <img src="assets/logo/alpe-logo-hell.svg" alt="Alpe «Zugerberg»" width="520">
  </picture>
</p>

# Alpe «Zugerberg»

[![Tests](https://github.com/alpemessi/alpe/actions/workflows/tests.yml/badge.svg)](https://github.com/alpemessi/alpe/actions/workflows/tests.yml)
[![Version](https://img.shields.io/github/v/release/alpemessi/alpe?label=Version)](https://github.com/alpemessi/alpe/releases)
[![Lizenz: MIT](https://img.shields.io/badge/Lizenz-MIT-blue.svg)](LICENSE)

**Eine Desktop-Shell für Linux, massgeschneidert für die Schweiz.** Wetter von MeteoSchweiz mit
Niederschlagsradar, National League und Nati im Sport-Tab, Schweizer Schreibweise überall – auf
einem KDE-Plasma-PC genauso wie auf einem MacBook mit Asahi Linux.

https://github.com/user-attachments/assets/fdb085bb-e699-43d1-967c-eb4ee050b9e3

> **English:** Alpe is a Linux desktop shell tailored to Switzerland: MeteoSwiss forecasts and
> precipitation radar, Swiss ice hockey and football next to the NBA and Europe's top leagues,
> Swiss German conventions throughout. It runs on KDE Plasma (replacing plasmashell, keeping KWin)
> and on Hyprland, and was built for a CachyOS desktop and an Apple Silicon MacBook running Fedora
> Asahi Remix. Install with one command (below); the interface is in German.

## Installation

```sh
curl -fsSL https://raw.githubusercontent.com/alpemessi/alpe/main/get.sh | bash
```

Der Installer fragt bei jedem Schritt nach und verändert nichts ohne Zustimmung:

1. prüft Rechner und Sitzung (KDE Plasma oder Hyprland, Arch/CachyOS oder Fedora/Asahi),
2. installiert bei Bedarf die [Dux Modular Shell](https://github.com/duxlabs-dev/dux-shell), auf der Alpe aufbaut – unter Arch/CachyOS als Paket `dux-shell` aus den offiziellen Quellen (ohne zusätzlichen Compositor), unter Fedora über den DMS-Installer,
3. installiert auf Wunsch kitty und fastfetch (beide im Alpe-Design) und unter KDE die KWin-Effekte für Unschärfe und runde Ecken (Better Blur DX, KDE-Rounded-Corners; aus dem AUR mit paru oder yay),
4. holt Alpe nach `~/alpe` und richtet es ein; passt der installierte Dienst nicht zum Shell-Code, baut Alpe den passenden selbst,
5. ersetzt unter KDE Plasmas Leiste und Desktop durch Alpe (KWin, Systemeinstellungen und alle KDE-Programme bleiben),
6. spielt das Alpe-Design ein: Leiste, Dock, Dash, Farben, Effekte, Sperrbildschirm, kitty und fastfetch wie auf den Bildern.

Danach einmal ab- und wieder anmelden. Nur schauen, was geschehen würde:
`curl -fsSL https://raw.githubusercontent.com/alpemessi/alpe/main/get.sh | bash -s -- --check`

| | KDE-PC | MacBook (Apple Silicon) |
|---|---|---|
| System | CachyOS oder Arch Linux | Fedora Asahi Remix |
| Sitzung | KDE Plasma 6.8 (Wayland), Alpe anstelle von plasmashell | Hyprland |
| Fenster | ohne Titelleisten, an einer Griffleiste ziehen, Ecken und Ränder zum Grössenändern, Einrasten | wie von Hyprland gewohnt |
| Sperrbildschirm | KDE-Sperre im Alpe-Design | Sperre der Shell oder hyprlock, beide in Alpe gestaltet |
| Gerät | Headset-Akku (HyperX, HeadsetControl) | Ladegrenze, Deckel, Tastaturbeleuchtung |

Andere Distributionen mit KDE Plasma oder Hyprland gehen meist auch; die Pakete installiert man dort selbst.

## Was Alpe kann

| Bereich | |
|---|---|
| **Wetter** | Prognose von MeteoSchweiz (amtliche Tagesprognose, Stundenwerte aus ICON-CH), Niederschlagsradar der Schweiz als Film mit eigener Hochrechnung der nächsten Stunde |
| **Sport** | Spiele, Live-Resultate, Tabellen, Bestenlisten und Spieldetails: National League, Super League, Länderspiele der Schweiz im Eishockey und Fussball, Top-5-Ligen mit ihren Cups, Champions und Europa League, NBA. Favoriten mit Mitteilung bei Toren, laufendes Spiel in der Leiste, Streamingdienst je Wettbewerb |
| **Dash** | Übersicht mit Uhr, Kalender, Wetter, Sport und Systemlast; Tabs für Wetter, Radar und Sport; wächst mit, wenn man ein Spiel öffnet |
| **KDE Plasma** | Leiste, Dock, Arbeitsflächen und Fensterliste unter KWin; Fensterregeln, Effekte (runde Ecken, Unschärfe), Tastenkürzel und Dienste direkt in den Einstellungen der Shell |
| **Sperrbildschirm** | frei gestaltbar mit Live-Vorschau (Texte, Bilder, Passwortfeld, Hintergrund); nach der automatischen Anmeldung unter KDE gesperrt, bevor der Desktop erscheint |
| **Einstellungen** | nur, was der Rechner hat; Seiten für Leistung (Speicher von Oberfläche und Dienst), Geräte-Akkus, Wartung |
| **Befehl `alpe`** | `alpe doctor` prüft die Einrichtung, `alpe update` holt die neue Fassung, `alpe design`, `alpe backup`, `alpe ram`, `alpe fastfetch` … – `alpe help` zeigt alle |

## Nach der Installation

```sh
alpe doctor          # ist alles da und richtig eingerichtet?
alpe update          # neue Fassung holen und einspielen
alpe design apply    # das Alpe-Design (wieder) einspielen, mit Sicherung der eigenen Einstellungen
alpe kde aus         # KDE: zurück zu Plasmas eigener Oberfläche (alpe kde ein: wieder Alpe)
alpe entfernen       # Alpe entfernen, KDE bzw. Hyprland wie vorher (--alles: auch Einstellungen und Pakete)
```

Unter KDE haben Fenster keine Titelleiste. Gezogen wird am oberen Fensterrand (Griffleiste), die
Grösse an den Rändern und unteren Ecken; Rechtsklick auf den oberen Rand öffnet das Fenstermenü.

| Kürzel (KDE) | |
|---|---|
| Meta+Q oder Alt+F4 | Fenster schliessen |
| Meta+M | Systemmonitor |
| Meta+Space | Starter |
| Meta+N | Benachrichtigungen |
| Meta+, | Einstellungen |
| Meta+Ziehen | Fenster verschieben (wie in KDE) |

Ändern lassen sich alle in den Einstellungen der Shell (Tastenkürzel).

Das Wetter folgt dem Standort; einen festen Ort und die Sport-Favoriten stellt man in den Einstellungen
ein (Zeit & Wetter, Sport).

`alpe entfernen` stellt Plasmas Oberfläche, Titelleisten und Sperrbildschirm wieder her, spielt die
Einstellungen von vor dem Design zurück und löscht den Shell-Code; DMS und seine Einstellungen bleiben.
`alpe entfernen --alles` nimmt dazu die Einstellungen von DMS, kitty und fastfetch (soweit sie erst
mit Alpe kamen), `~/alpe` und die Pakete, die der Installer selbst installiert hat – die Liste zeigt es
vorher an. Mit `--check` nur schauen.

## Das Design

`design/` enthält das Aussehen, mit dem Alpe ausgeliefert wird – je eines für KDE und für Hyprland.
Wer sein eigenes Aussehen weitergeben will, nimmt es mit `alpe design export` auf: Übernommen wird,
was man sieht; Wetterort, Favoriten, Bildschirmnamen, eigene Befehle und Pfade bleiben draussen, und
Bilder kommen nur mit, wenn man sie als eigene bestätigt. Einzelheiten in [design/README.md](design/README.md).

## Aufbau

Alpe ist ein loser Fork der Dux Modular Shell (Quickshell/QML und ein Go-Dienst). Das Repository enthält
nur, was Alpe unterscheidet:

- `shell/` – Änderungen am Shell-Code als Patch-Schichten auf einen festen Stand des Ursprungsprojekts
  (`BASE`), darunter die KWin-Unterstützung,
- `plugins/` – Wetter (MeteoSchweiz), Radar und Sport,
- `lockscreen/` – das Design für KDEs Sperrbildschirm,
- `tools/`, `get.sh`, `bootstrap.sh`, `install.sh` – Einrichtung und der Befehl `alpe`,
- `tests/`, `entwicklung/` – Prüfungen (auch auf GitHub bei jedem Push) und Testumgebungen.

Wie die Teile arbeiten, steht in [docs/technik.md](docs/technik.md).

## Fehler melden, mitmachen

Fehler und Wünsche bitte als [Issue](https://github.com/alpemessi/alpe/issues), am besten mit der
Ausgabe von `alpe doctor`. Vor einem Pull Request `alpe test` laufen lassen.

## Datenquellen

- **MeteoSchweiz** (Bundesamt für Meteorologie und Klimatologie): Prognosen und Radar aus Open Government
  Data. Quelle: MeteoSchweiz. Ortsangaben über data.geo.admin.ch (swisstopo).
- **Open-Meteo** (CC BY 4.0): Stundenwerte des Modells ICON-CH.
- **ESPN**: Spiele, Tabellen und Statistiken über die öffentlich erreichbare, aber nicht dokumentierte
  Schnittstelle der ESPN-Webseiten. Alpe hat keine Verbindung zu ESPN; die Schnittstelle kann sich
  jederzeit ändern.
- **Swiss Ice Hockey Federation**: National League und Nati. **TheSportsDB**: Logos der National League.

Die Daten gehören ihren Anbietern und sind für den persönlichen Gebrauch auf dem eigenen Desktop gedacht.

## Dank und Lizenz

Alpe baut auf der [Dux Modular Shell](https://github.com/duxlabs-dev/dux-shell) (MIT, © 2025 Avenge
Media LLC) und [Quickshell](https://quickshell.org) auf. Die Schriften des Sperrbildschirms (Alfa Slab One,
JetBrains Mono) stehen unter der SIL Open Font License.

Alpe selbst steht unter der [MIT-Lizenz](LICENSE). Gemacht in der Schweiz.
