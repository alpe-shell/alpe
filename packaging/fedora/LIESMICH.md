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
| `alpe-shell.spec` | `alpe-shell` (Dienst, Oberfläche, Werkzeuge, Design, KDE-Sperre, Benutzer-Unit) | vorhanden, in mock gebaut (`fedora-45-aarch64`) |
| `kora-icon-theme.spec` | `kora-icon-theme` (Symbolthema des ausgelieferten Designs) | vorhanden, in mock gebaut |
| `quickshell.spec` | `quickshell` 0.3.2 (Fedora 45 liefert 0.2.1; alpe-shell verlangt ≥ 0.3.2), abgeleitet von der Fedora-Spec aus dist-git `rpms/quickshell`, Zweig `f45` | vorhanden, in mock gebaut |
| `matugen.spec` | `matugen` 4.2.0 (Fedora 45 liefert nur 3.1.0 – Binärpaket `matugen` aus dem Quellpaket `rust-matugen` –; das ausgelieferte Design braucht `--prefer`, das es ab 4.1 gibt) | vorhanden, in mock ohne Netz gebaut; braucht das Crate-Archiv als `Source1` (siehe unten) |
| `matugen-vendor.sh` | – (erzeugt das Crate-Archiv von matugen) | vorhanden |
| `<Paket>.rpmlintrc` | – (begründete Ausnahmen für rpmlint, je Paket eine: `alpe-shell`, `kora-icon-theme`, `quickshell`, `matugen`) | vorhanden |

`rpmlint` immer mit `-r` und der rpmlintrc des Pakets, etwa
`rpmlint -r packaging/fedora/matugen.rpmlintrc packaging/fedora/matugen.spec <SRPM> <RPM>` (liegt mehr als eine
`*.rpmlintrc` im Ordner, lädt rpmlint ohne `-r` keine; die Ausnahmen eines Pakets gelten nicht für ein anderes).
Erwartet beim gemeinsamen Lauf auf Spec, SRPM und RPM: 0 Fehler; als Warnung bleibt nur `no-manual-page-for-binary`.
Wird die Spec allein geprüft, meldet rpmlint `E: unused-rpmlintrc-filter` für Filter, die nur das RPM betreffen.

## Quellarchiv von alpe-shell

Name und Ordner des Archivs stehen in `alpe-shell.spec` an genau einer Stelle (`%global quelle`). Das Archiv ist das
von `make dist` (Go-Module vendort); gebaut wird ohne Netz (`GOFLAGS=-mod=vendor`, `GOPROXY=off`).

## Crate-Archiv von matugen

`matugen.spec` baut ohne Netz: `Source0` ist das Archiv des Tags, `Source1` (`matugen-<Version>-vendor.tar.gz`) der
Ordner `vendor/` mit allen Crates aus `Cargo.lock`. Beide prüft `%prep` gegen ihre sha256 (`quelle_sha256`,
`vendor_sha256` in der Spec). Das Crate-Archiv liegt nicht im Repository; es wird mit `matugen-vendor.sh` erzeugt und
mit dem SRPM hochgeladen. So entsteht es im mock-Chroot von Fedora 45; der Chroot selbst hat nur im Schritt mit
`--enable-network` Netz (`--init` und `--install` laden Pakete wie bei jedem Bau). Die Befehle laufen in der Wurzel
des Repositorys; `spectool` (Paket `rpmdevtools`) lädt `Source0` dorthin (`*.tar.gz` ist in `.gitignore`):

```
spectool -g packaging/fedora/matugen.spec
sha256sum matugen-4.2.0.tar.gz
mock -r fedora-45-aarch64 --init
mock -r fedora-45-aarch64 --install cargo rust tar gzip findutils coreutils
mock -r fedora-45-aarch64 --copyin packaging/fedora/matugen-vendor.sh matugen-4.2.0.tar.gz /builddir/
mock -r fedora-45-aarch64 --unpriv --chroot "mkdir -p /builddir/aus"
mock -r fedora-45-aarch64 --enable-network --unpriv --chroot "bash /builddir/matugen-vendor.sh /builddir/matugen-4.2.0.tar.gz /builddir/aus"
mock -r fedora-45-aarch64 --copyout /builddir/aus/matugen-4.2.0-vendor.tar.gz .
sha256sum matugen-4.2.0-vendor.tar.gz
```

Beide Prüfsummen mit `quelle_sha256` und `vendor_sha256` in `matugen.spec` vergleichen (das Skript prüft die Quelle
zusätzlich selbst).

Das Skript prüft die Quelle, holt die Crates mit `cargo vendor --locked --versioned-dirs` und packt reproduzierbar
(Namen sortiert, Zeit von `Cargo.lock`, Besitzer 0/0, `gzip -n`); am Ende stehen Grösse und sha256. Im Nachtlauf vom
29.11.2026 mit cargo 1.100.0, tar 1.35 und gzip 1.14 aus Fedora 45 zweimal erzeugt, bytegleich: 62 633 851 Byte, sha256
`5c5ffd861dbb9f31a3f2c08e79439f5abaaf40175b1813fb514b6bdaaf0d55d4` (= `vendor_sha256`). Mit einer anderen Fassung
von cargo kann die Summe abweichen; dann das neue Archiv nehmen und `vendor_sha256` nachführen. Bei einer neuen
Fassung von matugen: `version` und `quelle_sha256` im Skript und in der Spec gemeinsam ändern, das Archiv neu
erzeugen, Lizenzfeld neu ermitteln (der Lizenzabgleich in `%check` bricht sonst den Bau).

Bekannt und noch nicht entschieden: `cargo vendor` holt die Crates aller Plattformen, das Archiv enthält darum
vorgebaute Windows-Bibliotheken (`winapi-*-windows-gnu`, `windows_*`). Gelinkt wird davon nichts. Fedoras
Packaging Guidelines verlangen, vorgebaute Programme und Bibliotheken in `%prep` vor dem Bau zu entfernen («Remove all
pre-built program binaries and program libraries in %prep»); für ein COPR ist das nicht bindend. Bei vendorten Crates
bräche ein Löschen in `%prep` die Prüfsummen in `.cargo-checksum.json`.

## Baureihenfolge im COPR

1. `quickshell`, `kora-icon-theme` und `matugen` – voneinander unabhängig, in beliebiger Reihenfolge
2. `alpe-shell` – erst, wenn alle drei in beiden Chroots erfolgreich gebaut sind

`alpe-shell` verlangt die drei mit `Requires`; in einem COPR ohne sie lässt es sich bauen, aber nicht installieren.
COPR kann die Reihenfolge der Bauten festlegen («Build batches»: `copr build … --after-build-id <Nr.>` bzw.
`--with-build-id <Nr.>`, auch im Web-Formular des Baus), wartet dabei aber nur, bis der vorige Bau **beendet** ist –
auch ein gescheiterter gilt als beendet. Ob die drei erfolgreich waren, vor dem Bau von `alpe-shell` selbst
nachsehen.

**Pflicht: `quickshell` nach jeder Aktualisierung von Qt in Fedora neu bauen** (Entscheid P15). Quickshell nutzt
private Schnittstellen von Qt (`BUILD.md` des Ursprungs: «MUST be rebuilt against each Qt release»); das RPM verlangt
die Minor-Fassung von Qt, gegen die es gebaut ist (`libQt6*.so.6(Qt_6.<Minor>_PRIVATE_API)`); bei einer neuen
Patch-Fassung greift diese Abhängigkeit nicht (gefolgert). Darum nach jeder neuen Fassung von `qt6-qtbase` oder
`qt6-qtdeclarative` (private Schnittstellen von QtQuick, `cmake(Qt6QuickPrivate)`) in Fedora 45 das Release von
`quickshell` erhöhen, das SRPM neu bauen und hochladen.

**Pflicht: vor jedem Hochladen das Release fremder Pakete gleichen Namens prüfen** (Entscheid P18). dnf wählt bei
gleicher Priorität die höhere EVR; bei gleicher Fassung samt Release entschiede nicht das eigene COPR. Das eigene
Release muss darum **strikt über** dem höchsten bekannten fremden liegen. Gemessen am 28.11.2026 in einem fremden COPR:
`quickshell-0.3.2-4.fc45` und `matugen-4.2.0-1.fc45`; die eigenen Releases sind 5 und 2. Prüfen etwa mit
`dnf repoquery --qf '%{name}-%{epoch}:%{version}-%{release} %{repoid}\n' quickshell matugen` auf einem Rechner mit
den betreffenden Quellen (dazu die Paketsuche der COPR-Weboberfläche nach `quickshell` und `matugen`), Vergleich mit
`rpmdev-vercmp` (Paket `rpmdevtools`). Liegt ein fremdes Release gleich hoch oder höher, das eigene Release vor dem
Hochladen erhöhen.

## Chroots

- `fedora-45-aarch64` (MacBook mit Fedora Asahi Remix 45: 16-KB-Seiten; jemalloc aus Fedora ist für Seiten bis 64 KiB
  gebaut, Quickshell braucht dafür keinen eigenen Schalter)
- `fedora-45-x86_64`

Die jeweils nächste Fassung kommt dazu, sobald Fedora Asahi Remix folgt.

## Im COPR von Hand einzustellen

- Projekt `alpe` unter dem Konto `alpe-shell` anlegen, Chroots wie oben.
- **Keine Priorität setzen** und keine Abhängigkeit auf ein anderes COPR eintragen (Plan 0.8 Nr. 99). Pakete gleichen
  Namens aus fremden COPRs mit höherer Fassung bleiben bei gleicher Priorität installiert; das ist hingenommen.
- **Netz im Builder: aus**, in den Projekteinstellungen und je Bau («Enable internet access during builds» nicht
  ankreuzen). Kein Paket braucht Netz im Bau: `alpe-shell` baut aus dem Archiv von `make dist`, `matugen` aus dem
  Crate-Archiv, `quickshell` und `kora-icon-theme` aus ihren Quellarchiven.
- **SRPM von Hand hochladen** (bis G1): SRPM lokal bauen (`rpmbuild -bs` mit den Quellen nach `Source0`, bei `matugen`
  dazu `Source1`), dann im Projekt «New Build» → «Upload» und die `.src.rpm` wählen (oder
  `copr build alpe-shell/alpe <Datei>.src.rpm`). Je Paket ein Bau, Chroots wie oben. Das SRPM immer aus dem Stand
  bauen, der hochgeladen werden soll (ein SRPM aus einem früheren Probebau enthält dessen Spec).
- Beschreibung und Installationshinweis des Projekts: die zwei Befehle oben, dazu die Lizenzen der Pakete (COPR-Doku,
  «What I can build in Copr?»: «It would be nice if you stated the license of your packages in the Description or
  Install instructions»).

## Lizenzen

COPR nimmt nur Material unter Lizenzen aus Fedoras Liste (COPR-Doku, «What I can build in Copr?», Punkt b). Seit den
Entscheiden vom 28.11.2026 erfüllt: Logo und Symbol von Alpe stehen unter CC-BY-SA-4.0 (das Lizenzfeld von
`alpe-shell.spec` nennt nur Kennungen aus Fedoras Liste), und unter `shell/assets/` liegt kein Hyprland-Zeichen mehr
(neutrales Symbol). `matugen` legt die Lizenz jedes gelinkten Crates in `LICENSE.dependencies` ab; `%check` bricht den
Bau, wenn das Lizenzfeld nicht mehr zu den Crates passt.

Das Paket aktiviert und startet keine Unit; eingeschaltet wird Alpe pro Benutzer mit `alpe einrichten`.
