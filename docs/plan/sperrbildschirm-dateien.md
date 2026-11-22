# Vorlage 6.7 – Sperrbildschirm unter KDE: wo nutzerspezifische Dateien liegen

Stand: 22.11.2026. **Zur Entscheidung vorgelegt, nicht freigegeben.** Vor E1 zu entscheiden
(Plan 0.8 Nr. 6); bis dahin wird nichts davon umgesetzt. Vier Fragen am Ende.

Betrifft nur den PC-Weg (KWin, `kscreenlocker_greet`). Unter Hyprland sperrt hyprlock mit
`~/.config/hypr/hyprlock.conf`; daran ändert die Vorlage nichts.

## 1. Bestand (gelesen auf `403b505`)

Der KDE-Sperrdienst nimmt seine Oberfläche aus dem Shell-Paket, das in `plasmashellrc`
(`[Shell] ShellPackage`) steht, und sucht es zuerst unter `~/.local/share/plasma/shells/`, dann
unter `/usr/share/plasma/shells/`. Eine Nutzerkopie verdeckt also ein gleichnamiges Systempaket.

`tools/lockscreen.sh install` baut heute bei jedem Aufruf eine Nutzerkopie
`~/.local/share/plasma/shells/org.alpe.desktop` aus drei Quellen:

| Inhalt | Quelle | nutzerspezifisch? |
|---|---|---|
| `metadata.json`, `LockScreen.qml`, `CapsLock.qml`, `config.xml`, Schrift Alfa Slab One | `lockscreen/org.alpe.desktop` | nein |
| `HyprlockView.qml`, Schriften JetBrains Mono | `shell/Modules/Lock/Alpe` | nein |
| `layout.js` (Vorlage, wenn kein eigenes Layout gestaltet ist) | erzeugt von `hyprlock2qml.py` aus `~/.config/alpe/hyprlock.conf`, wenn es die gibt, sonst aus `lockscreen/hyprlock.conf` | **nur mit eigener `hyprlock.conf`** |

Woher der Greeter sein Layout nimmt, in dieser Reihenfolge:

1. **`Layout` in `kscreenlockerrc`** (`[Greeter][LnF][General]`, JSON; Schema in `config.xml`).
   Geschrieben von der Seite «Sperrbildschirm gestalten», von `lockscreen.sh hyprlock DATEI` und
   von `alpe design apply`. Liegt schon heute beim Nutzer, nicht im Paket.
2. Ist `Layout` leer: die Vorlage **`layout.js` im Paket**.

Drei Berichtigungen gegenüber dem Plan (0.4, 6.7 alt):

- **Bilder schreibt `lockscreen.sh` nicht ins Paket.** Das Layout nennt Bilder mit absolutem
  Pfad; `images_check` prüft nur, ob sie da sind. Die Bilder eines eingespielten Designs legt
  `tools/design.py` unter `~/.local/share/alpe/design` ab. Nutzerspezifisch im Paket ist allein
  `layout.js`, und das nur, wenn `~/.config/alpe/hyprlock.conf` existiert.
- **`~/.config/alpe/hyprlock.conf` schreibt kein Werkzeug.** Sie ist von Hand angelegt; gelesen
  wird sie von `lockscreen.sh` (`conf_path`) und vom Design-Export (nur wenn `Layout` leer ist).
- Die Seite «Sperrbildschirm» (`AlpeLockTab.qml`, Abfrage `alpe=1`) sucht das Alpe-Design nur
  unter `~/.local/share/plasma/shells`; mit einem Systempaket meldete sie «nicht installiert».
  `alpe-lockcheck.sh` und `lockscreen.sh shell_dir` kennen beide Orte schon.

Ist-Zustand am PC (nur gelesen): `ShellPackage=org.alpe.desktop`, Nutzerkopie vorhanden,
`Layout` gesetzt (rund 3,9 kB), `Style=hyprlock`, `~/.config/alpe/hyprlock.conf` vorhanden (168
Zeilen) – sie wirkt heute nicht, weil `Layout` Vorrang hat. Daneben liegt ein fremdes Paket
`caelestia.desktop` (nennt `lockscreen.sh repair` schon als Hinweis).

## 2. Nebenbefund: persönliche Pfade in der eingecheckten Vorlage

`shell/Modules/Lock/Alpe/layout.js` ist nicht aus der neutralen `lockscreen/hyprlock.conf`
erzeugt, sondern aus einer persönlichen: sieben Pfade `/home/<Name>/Pictures/Hyprlock/…`
(Zeilen 10–152) und in Zeile 292 der Pfad der Quelle in einem zweiten Home-Verzeichnis. Die Datei
kam mit `bfc7243` («Alpe 1.0 im Quellbaum») herein; der Commit liegt laut lokalem Stand der
Remote-Zweige **auch auf `origin/phase-a`**. Sie verstösst gegen die Projektregel «keine
absoluten Pfade ins eigene Home-Verzeichnis»; `tests/test_werte.py` prüft darauf nur `design/`.

Folgen heute: Die Shell-Sperre (`AlpeLockSurface.qml`) zeigt ohne eigenes Layout diese Vorlage
und sucht auf jedem Rechner Bilder unter dem fremden Pfad. Die KDE-Sperre ist nicht betroffen,
solange `lockscreen.sh install` lief (es überschreibt `layout.js` in der Nutzerkopie). **Mit dem
Paket nach 6.1 würde genau diese Datei nach `/usr/share` ausgeliefert.**

**Behoben am 22.11.2026 (Auftrag des Maintainers):** `layout.js` ist in `56fcedd` aus
`lockscreen/hyprlock.conf` neu erzeugt (`alpe-hyprlock.py … --quelle lockscreen/hyprlock.conf`:
Name der Quelle statt absolutem Pfad, kein Datum), mit Test auf Gleichheit; `tests/test_werte.py`
durchsucht seit `016d986` das ganze Repo.

**Wo die Pfade in der Geschichte liegen (geprüft am 22.11.2026 am lokalen Stand):**

- `bfc7243` ist **nicht in `main` und nicht im Tag `v1.0`**; der Commit liegt nur auf `phase-a`
  und `origin/phase-a`.
- **Dieselben Pfade stehen trotzdem schon in `v1.0`, `main` und `origin/main`:** in
  `shell/0001-Alpe-1.0-Zugerberg.patch` (acht Stellen: sieben Bildpfade im eigenen
  Home-Verzeichnis und der Quellpfad) – die Schicht, aus der `bfc7243` den Quellbaum gemacht hat.
- Daneben in `v1.0`/`main` fünf Dateien mit Pfaden in ein Home-Verzeichnis einer Bauumgebung oder
  mit Platzhalternamen: `entwicklung/lint.sh`, `entwicklung/pageharness/td2.qml`, `th.qml`,
  `tl2.qml`, `entwicklung/sportharness/fixtures/match-nba-31.json`.

Ein Umschreiben nur von `phase-a` entfernte die Pfade also nicht aus dem Veröffentlichten. Über
die Geschichte entscheidet der Maintainer; hier ist nichts umgeschrieben.

## 3. Varianten

### A – Systempaket unverändert, Nutzerspezifisches nur in `kscreenlockerrc` (empfohlen)

Das Paket liefert `/usr/share/plasma/shells/org.alpe.desktop` fertig zusammengesetzt aus (wie 6.1),
mit einer `layout.js` aus der neutralen Vorlage. **Unter `~/.local/share/plasma/shells` liegt
nichts von Alpe.** Alles Eigene steht in `Layout` (und `Style`, `Blur`, `Dim`, `Locale`) in
`kscreenlockerrc`, Bilder wie heute unter ihrem absoluten Pfad.

Das ist die Variante «Greeter liest aus der Konfiguration» in der Form, die ohne Umbau des
Greeters geht: Aus `~/.config/alpe` kann die Greeter-Oberfläche nicht selbst lesen – Qt 6 sperrt
`XMLHttpRequest` auf lokale Dateien ohne `QML_XHR_ALLOW_FILE_READ=1` (nach Qt-Dokumentation,
hier nicht nachgemessen), und die Umgebung des Greeters gehört dem Sperrdienst. `kscreenlockerrc`
liest er dagegen schon.

- `lockscreen.sh install` wird zu «einschalten»: `repair`, Probe mit dem Systempaket,
  `ShellPackage` nur bei Erfolg; `build_layout` und das Kopieren entfallen.
- **Eigene `hyprlock.conf`:** einmalige Übernahme nach `Layout` über den bestehenden Weg
  (`lockscreen.sh hyprlock DATEI`), wenn `Layout` leer ist; danach ist `Layout` die einzige Quelle
  (Frage 2).
- **Umzug (7.2 Nr. 5):** Nutzerkopie in die Sicherung verschieben wie geplant; neu: bei leerem
  `Layout` und vorhandener `~/.config/alpe/hyprlock.conf` diese übernehmen und im Protokoll
  nennen. Rückweg: Nutzerkopie aus der Sicherung zurück, `kscreenlockerrc` aus der Sicherung.
- **`design export`:** `Layout` wie heute; der Zweig «eigene `hyprlock.conf`, wenn `Layout` leer»
  entfällt nach der Übernahme (bleibt für nicht umgezogene Stände harmlos).
  **`design apply`:** unverändert – es schreibt schon heute nur `kscreenlockerrc`.
- **`alpe entfernen`:** `use kde` und `kscreenlockerrc` aus der Sicherung wie heute; die Zeile,
  die `~/.local/share/plasma/shells/org.alpe.desktop` löscht, bleibt für Reste aus 1.0. Das
  Systempaket geht mit dem Paket.
- **Entwicklung am PC (6.5):** Ohne Paket gibt es kein Systempaket. `alpe entwicklung ein` legt
  dann bewusst eine Nutzerkopie aus dem Repo an (derselbe Zusammenbau wie im Paketbau, ein
  gemeinsames Skript), `alpe entwicklung aus` entfernt sie; `alpe doctor` nennt sie. Das ist die
  einzige Stelle, an der eine Nutzerkopie entsteht.

Für A spricht: Paket-Aktualisierungen wirken sofort; kein Verdecken; der Sperrbildschirm kann
nicht hinter der Shell zurückbleiben; `$HOME` wird vom Einrichten nur über `kwriteconfig6`
berührt. Dagegen: Wer seine `hyprlock.conf` von Hand pflegt, muss nach einer Änderung neu
übernehmen (ein Befehl) oder in den Einstellungen gestalten.

### B – bewusst erzeugte Nutzerkopie

`alpe einrichten` kopiert das Systempaket nach `~/.local/share/plasma/shells/org.alpe.desktop` und
schreibt `layout.js` hinein – der heutige Ablauf mit anderer Quelle.

- Verhalten wie 1.0; `~/.config/alpe/hyprlock.conf` bleibt die laufende Quelle der Vorlage.
- **Die Kopie verdeckt das Systempaket.** Nach `paru -Syu` ohne `alpe einrichten` läuft die alte
  Oberfläche gegen neue Einstellungen weiter; bricht eine Qt- oder Plasma-Aktualisierung die alte
  Fassung, erscheint das blaue Notdesign, obwohl das Paket schon berichtigt ist. Nötig wären ein
  Versionsvermerk in der Kopie, eine Prüfung in `alpe doctor` und ein Auffrischen bei jedem
  Start von `alpe start` – also doch ein Schreiben ins `$HOME` ausserhalb des Einrichtens.
- Umzug: Kopie neu erzeugen statt verschieben. `entfernen`: Kopie löschen (wie heute).
  `design apply/export`: unverändert.

### C – Mischform (Kopie nur, wenn eine eigene `hyprlock.conf` da ist)

Zwei Wege mit je eigenen Fehlerbildern, beide zu testen; nicht empfohlen.

## 4. Empfehlung

**Variante A**, mit einmaliger Übernahme einer eigenen `hyprlock.conf` und neutraler,
im Repo geprüfter Vorlage. Aufteilung: Zusammenbau des Pakets und neutrale `layout.js` in E1,
`lockscreen.sh`/`AlpeLockTab.qml`/`entfernen` in E4, Übernahme im Umzug in F1. Tests: Zusammenbau
in einen Temp-Ordner (alle Dateien da, `layout.js` gleich der Ausgabe des Umsetzers auf
`lockscreen/hyprlock.conf`), `lockscreen.sh` mit Attrappen für `kreadconfig6`/`kwriteconfig6`
und den Greeter im Temp-`HOME` (schreibt nichts unter `plasma/shells`), Umzug mit und ohne
eigene `hyprlock.conf`.

## 5. Fragen

**Stand 22.11.2026:** Frage 3 ist erledigt (siehe Abschnitt 2), Frage 4 entschieden: ja, beim
Paketbau aus derselben Quelle wie `Brand.version`, umgesetzt mit E1. Offen sind 1 und 2.

1. **Variante A oder B?** (Empfehlung: A.)
2. **Eigene `~/.config/alpe/hyprlock.conf` bei A:** (a) einmal übernehmen, wenn `Layout` leer ist,
   danach nicht mehr lesen und das in `docs/technik.md` sagen – empfohlen; oder (b) bei jedem
   `alpe einrichten` neu übernehmen, wenn die Datei jünger ist als die letzte Übernahme (dann
   überschreibt eine alte Datei unter Umständen ein in den Einstellungen gestaltetes Layout nicht,
   braucht aber einen Zeitvermerk). Am PC ist `Layout` gesetzt, dort ändert sich mit (a) nichts.
3. **Neutrale Vorlage:** `shell/Modules/Lock/Alpe/layout.js` aus `lockscreen/hyprlock.conf` neu
   erzeugen (ohne Quellpfad und Datum im Kopf), Test auf Gleichheit, `tests/test_werte.py` auf
   `shell/` und `lockscreen/` ausdehnen. Damit zeigt die Shell-Sperre ohne eigenes Layout die
   neutrale Vorlage statt der persönlichen. Einverstanden – und soll das **sofort als eigener
   Commit** geschehen, unabhängig von E1? Was mit der Geschichte auf `origin/phase-a` geschieht,
   entscheidest du.
4. **Version in `metadata.json`** des Sperrpakets steht auf 1.9.2 (aus der Zeit vor der
   Zählung «Zugerberg»). Beim Paketbau aus `Brand.qml` setzen und in `tests/test_version.py`
   prüfen?
