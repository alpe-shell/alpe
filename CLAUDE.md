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
- `KONTEXT.md` ist lokal und gitignored – lesen ja, nie committen.
- Keine fremden oder urheberrechtlich geschützten Bilder ins Repository.

## Das laufende System

Der Maintainer arbeitet auf dem PC, auf dem du läufst, und Alpe ist seine aktive Oberfläche.
- Ohne Rückfrage **nicht**: `dms.service`/`alpe.service` neu starten oder stoppen, `install.sh`,
  `get.sh`, `bootstrap.sh`, `alpe design apply`, `alpe kde …`, `alpe entfernen` gegen das echte
  `$HOME` ausführen, KWin-Konfiguration schreiben, kglobalaccel ändern.
- Lesen von `~/.config/dms`, `~/.local/state/dms`, `~/.config/alpe`, `~/.config/kwinrulesrc`
  ist erlaubt (für Migrationstests: Kopie in ein Temp-`$HOME` ziehen und dort arbeiten).
- Tests laufen mit eigenem `HOME`/`XDG_*` in einem Temp-Verzeichnis, nie gegen das echte.
- Kein `pkill`, `killall` oder `pkill -f`, auch nicht mit Pfadmustern: Die echte Shell läuft unter
  denselben Programmnamen (`qs`/`quickshell`, `dms`/`alpe`). Prozesse der Ladeprüfung nur über ihren
  Scope beenden (`systemctl --user stop alpe-ladepruefung-<zeit>.scope`).
- Den echten Installationstest macht der Maintainer in der VM (CachyOS-VM mit Snapshot «frisch») und am Mac.

## Prüfen vor jedem Commit

```
bash tools/test.sh          # = alpe test, dieselben Prüfungen wie auf GitHub Actions
```

Alles muss grün sein. Neue Funktion → neuer Test. Shell-Skripte: `bash -n`, QML-Seiten laden
in den Harnessen unter `entwicklung/`.

## Projektregeln

- Version und Codename: Alle Fassungen heissen «Zugerberg», gezählt wird nur die Nummer
  (`Brand.qml`, `CHANGELOG.md`). Die nächste Fassung ist 1.1.
- Persönliches gehört nie ins Repo: kein Wetterort, keine Sport-Favoriten, keine absoluten
  Pfade ins eigene Home-Verzeichnis, keine Bildschirmnamen. `tools/design.py` schrubbt das beim Export.
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
