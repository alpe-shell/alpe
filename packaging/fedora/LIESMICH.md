# Fedora und Fedora Asahi Remix: Pakete im COPR `alpe-shell/alpe`

Alpe wird unter Fedora als RPM aus einem eigenen COPR verteilt (Plan 6.3). Nutzer binden nur dieses eine COPR ein:

```
sudo dnf copr enable alpe-shell/alpe
sudo dnf install alpe-shell
```

Alpe hängt von keinem fremden COPR ab. Was Fedora nicht oder zu alt liefert, baut das eigene COPR mit.

## Dateien

| Datei | Paket | Stand |
|---|---|---|
| `alpe-shell.spec` | `alpe-shell` (Dienst, Oberfläche, Werkzeuge, Design, KDE-Sperre, Benutzer-Unit) | vorhanden |
| `alpe-shell.rpmlintrc` | – (rpmlint: deutsche Texte werden gegen en_US geprüft, `spelling-error` gefiltert) | vorhanden |
| `kora-icon-theme.spec` | `kora-icon-theme` (Symbolthema des ausgelieferten Designs) | vorhanden |
| – | `quickshell` ≥ 0.3.2 (Fedora 45 liefert 0.2.1) | offen: Lizenzfeld zu entscheiden; Grundlage ist die Fedora-Spec aus dist-git `rpms/quickshell`, Zweig `f45` |
| – | `matugen` ≥ 4.1 (Fedora 45 liefert 3.1.0; das Design braucht `--prefer`) | offen: Bau ohne Netz braucht ein vendortes Crate-Archiv |

`rpmlint` für alle Specs: `rpmlint -r packaging/fedora/alpe-shell.rpmlintrc <Spec> <SRPM> <RPM>`.

## Quellarchiv von alpe-shell

Name und Ordner des Archivs stehen in `alpe-shell.spec` an genau einer Stelle (`%global quelle`). Das Archiv ist das
von `make dist` (Go-Module vendort); gebaut wird ohne Netz (`GOFLAGS=-mod=vendor`, `GOPROXY=off`).

## Baureihenfolge im COPR

Jeder Schritt erst, wenn der vorige in beiden Chroots erfolgreich ist:

1. `quickshell`
2. `kora-icon-theme`
3. `matugen`
4. `alpe-shell`

`alpe-shell` verlangt die drei ersten mit `Requires`; in einem COPR ohne sie lässt es sich bauen, aber nicht
installieren.

## Chroots

- `fedora-45-aarch64` (MacBook mit Fedora Asahi Remix 45: 16-KB-Seiten; jemalloc aus Fedora ist für Seiten bis 64 KiB
  gebaut, Quickshell braucht dafür keinen eigenen Schalter)
- `fedora-45-x86_64`

Die jeweils nächste Fassung kommt dazu, sobald Fedora Asahi Remix folgt.

## Im COPR von Hand einzustellen

- Projekt `alpe` unter dem Konto `alpe-shell` anlegen, Chroots wie oben.
- **Keine Priorität setzen** und keine Abhängigkeit auf ein anderes COPR eintragen (Plan 0.8 Nr. 99). Pakete gleichen
  Namens aus fremden COPRs mit höherer Fassung bleiben bei gleicher Priorität installiert; das ist hingenommen.
- Netz im Builder: aus. `alpe-shell` und `kora-icon-theme` bauen ohne Netz; für `matugen` ist der Weg offen (siehe
  oben).
- Beschreibung und Installationshinweis des Projekts: die zwei Befehle oben, dazu die Lizenzen der Pakete (COPR bittet
  darum).
- Wie das SRPM ins COPR kommt (hochladen oder aus dem Repository mit `.copr/Makefile`), ist noch nicht entschieden.

## Vor dem ersten Bau von alpe-shell zu klären

COPR nimmt nur Material unter Lizenzen aus Fedoras Liste. Zwei Teile des Pakets erfüllen das heute nicht:

- Logo und Symbol von Alpe (`LicenseRef-Alpe-Logo`, Bedingungen in `NOTICE`): keine Lizenz aus Fedoras Liste.
- Das Hyprland-Zeichen unter `shell/assets/`: Die Logodateien von Hyprland sind «all rights reserved», und die
  Markenrichtlinie verlangt die offizielle Vorlage.

Das Paket aktiviert und startet keine Unit; eingeschaltet wird Alpe pro Benutzer mit `alpe einrichten`.
