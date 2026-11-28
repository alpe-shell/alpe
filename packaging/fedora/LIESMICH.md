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
| `quickshell.spec` | `quickshell` 0.3.2 (Fedora 45 liefert 0.2.1; alpe-shell verlangt ≥ 0.3.2), abgeleitet von der Fedora-Spec aus dist-git `rpms/quickshell`, Zweig `f45` | vorhanden, in mock gebaut (`fedora-45-aarch64`) |
| `matugen.spec` | `matugen` 4.2.0 (Fedora 45 liefert nur 3.1.0 als `rust-matugen`; das ausgelieferte Design braucht `--prefer`, das es ab 4.1 gibt) | vorhanden; Bau braucht Netz (Crates von crates.io nach `Cargo.lock`); Bau in mock noch nicht abgeschlossen |

`rpmlint` für alle Specs: `rpmlint -r packaging/fedora/alpe-shell.rpmlintrc <Spec> <SRPM> <RPM>` (immer mit `-r`: liegt
mehr als eine `*.rpmlintrc` im Ordner, lädt rpmlint ohne `-r` keine).

## Quellarchiv von alpe-shell

Name und Ordner des Archivs stehen in `alpe-shell.spec` an genau einer Stelle (`%global quelle`). Das Archiv ist das
von `make dist` (Go-Module vendort); gebaut wird ohne Netz (`GOFLAGS=-mod=vendor`, `GOPROXY=off`).

## Baureihenfolge im COPR

Jeder Schritt erst, wenn der vorige in beiden Chroots erfolgreich ist:

1. `quickshell`
2. `kora-icon-theme`
3. `matugen` (mit Netz im Bau, siehe unten)
4. `alpe-shell`

`alpe-shell` verlangt die drei ersten mit `Requires`; in einem COPR ohne sie lässt es sich bauen, aber nicht
installieren. Die drei ersten hängen nicht voneinander ab, ihre Reihenfolge ist frei. COPR kann die Reihenfolge selbst einhalten («Build
batches»: `copr build … --after-build-id <Nr.>` bzw. `--with-build-id <Nr.>`, auch im Web-Formular des Baus).

Quickshell nutzt private Schnittstellen von Qt und muss nach jeder Aktualisierung von Qt in Fedora neu gebaut werden
(`BUILD.md` des Ursprungs); das RPM verlangt die Minor-Fassung von Qt, gegen die es gebaut ist
(`libQt6*.so.6(Qt_6.<Minor>_PRIVATE_API)`).

Das Release der Pakete `quickshell` und `matugen` liegt über dem gleichnamiger Pakete fremder COPRs (am 28.11.2026:
`quickshell-0.3.2-4.fc45`, `matugen-4.2.0-1.fc45`), sonst entschiede bei gleicher Fassung nicht das eigene COPR.

## Chroots

- `fedora-45-aarch64` (MacBook mit Fedora Asahi Remix 45: 16-KB-Seiten; jemalloc aus Fedora ist für Seiten bis 64 KiB
  gebaut, Quickshell braucht dafür keinen eigenen Schalter)
- `fedora-45-x86_64`

Die jeweils nächste Fassung kommt dazu, sobald Fedora Asahi Remix folgt.

## Im COPR von Hand einzustellen

- Projekt `alpe` unter dem Konto `alpe-shell` anlegen, Chroots wie oben.
- **Keine Priorität setzen** und keine Abhängigkeit auf ein anderes COPR eintragen (Plan 0.8 Nr. 99). Pakete gleichen
  Namens aus fremden COPRs mit höherer Fassung bleiben bei gleicher Priorität installiert; das ist hingenommen.
- **Netz im Builder:** in den Projekteinstellungen aus lassen («Enable internet access during builds» nicht angekreuzt).
  Nur der Bau von `matugen` braucht Netz: im Formular des neuen Baus «Enable internet access during this build»
  ankreuzen (mit `copr-cli build` die Option `--enable-net`); der Schalter je Bau übersteuert die Projekteinstellung.
  `quickshell`, `kora-icon-theme` und `alpe-shell` bauen ohne Netz.
- **SRPM von Hand hochladen** (bis G1): SRPM lokal bauen (`rpmbuild -bs` mit den Quellen nach `Source0`), dann im
  Projekt «New Build» → «Upload» und die `.src.rpm` wählen (oder `copr build alpe-shell/alpe <Datei>.src.rpm`). Je
  Paket ein Bau, Chroots wie oben.
- Beschreibung und Installationshinweis des Projekts: die zwei Befehle oben, dazu die Lizenzen der Pakete (COPR-Doku,
  «What I can build in Copr?»: «It would be nice if you stated the license of your packages in the Description or
  Install instructions»).

## Lizenzfragen vor dem ersten Bau von alpe-shell

COPR nimmt nur Material unter Lizenzen aus Fedoras Liste. Entschieden am 28.11.2026, umgesetzt am PC:

- Logo und Symbol von Alpe stehen unter CC-BY-SA-4.0; `LicenseRef-Alpe-Logo` entfällt aus dem Lizenzfeld.
- Das Hyprland-Zeichen unter `shell/assets/` wird durch ein neutrales Symbol ersetzt.

Das Paket aktiviert und startet keine Unit; eingeschaltet wird Alpe pro Benutzer mit `alpe einrichten`.
