# Alpe – Technik

Wie Alpe aufgebaut ist und wie die einzelnen Teile arbeiten. Für Installation und Überblick siehe das
[README](../README.md).

## Befehl `alpe`

`install.sh` legt `~/.local/bin/alpe` an. Eigene Befehle: `alpe version [--short]`, `alpe doctor`, `alpe ram`,
`alpe fastfetch`, `alpe kopfleiste [schlank|weg|aus|status]`, `alpe titelleisten [status|aus|an]`, `alpe kde [status|ein|aus]`, `alpe design [status|export|apply]`, `alpe update [archiv]`, `alpe backup`, `alpe restore ARCHIV`, `alpe restart`, `alpe lock`, `alpe log`, `alpe test`. Alles andere geht unverändert an den
Hintergrunddienst (`alpe ipc call …`, `alpe run` …).

## Aufbau in drei Schichten

1. **KWin-Unterstützung** (`schichten/0000`): ein Patch, der der Dux Modular Shell die Zusammenarbeit
   mit KWin beibringt – KWin-Skript als Brücke (`Services/kwin/dms-bridge.js`), Arbeitsflächen,
   Fensterliste, Leiste und Dock. Unter anderen Fensterverwaltungen bleibt er untätig.
2. **Alpe im Shell-Code** (`schichten/0001`): alles, was Alpe an der Shell ändert. Jede Stelle ist
   klein gehalten und mit `Alpe:` kommentiert, damit sich neue Versionen des Ursprungsprojekts
   weiter übernehmen lassen. Nach Themen:
   - **Name und Zeichen:** `Common/Brand.qml` hält Name, Version, Codename und Adresse; `I18n.tr`
     ersetzt den Namen des Ursprungsprojekts in der Ausgabe, die Quelltexte bleiben unberührt.
   - **KDE Plasma:** Sperre über logind und den KDE-Sperrbildschirm (im Alpe-Design, Sperre beim
     Start über `LockOnStart`), Bildschirme aus mit `kscreen-doctor`, Helligkeit über Plasma
     (`scripts/alpe-brightness.py`), Tastenkürzel heissen in KDE «Alpe: …».
   - **Griffleisten:** Fenster ohne Titelleiste am oberen Rand ziehen, Einrasten am Bildschirmrand,
     Fenstermenü per Rechtsklick, Grösse an Ecken und Rändern ändern (siehe unten).
   - **Einstellungen:** nur, was der Rechner hat; unter KWin eigene Seiten für Fensterregeln,
     Fenster & Effekte, Tastenkürzel, Dienste (`scripts/alpe-kwin.py`), dazu Leistung,
     Geräte-Akkus, Wartung, Seitenauswahl, Sport und «Sperrbildschirm gestalten».
   - **Geräte:** Erkennung von Desktop und Laptop («Dieses Gerät»), Funk-Headsets
     (`scripts/alpe-headset.py`), Ladegrenze und Zuklappen (`scripts/alpe-root.sh`),
     Tastaturbeleuchtung.
   - **Hyprland:** Unschärfe einstellbar, hyprlock in den Einstellungen gestalten, Fenster anklicken
     für Fensterregeln.
   - **Wetter und Übersicht:** amtliche Regenmenge und Quelle in der Tagesprognose, Systemmonitor
     mit Auslastung statt Temperatur, Datum nach Landessprache.
   - **Dienst:** Teile des Hintergrunddienstes lassen sich vor dem Start abschalten
     (`~/.config/alpe/aus`, `core/internal/server/alpe_off.go`).
3. **Plugins**: `plugins/`, unabhängig vom Shell-Code.

`install.sh` baut den Zweig `alpe` in `~/dux-shell` immer als Ursprungsstand (`BASE`) plus alle
Schichten auf; weicht das Ergebnis vom vorhandenen Zweig ab, springt der Zweig darauf (mit Angabe
des Stands davor).

Ausserhalb des Shell-Codes liegen das Design des Sperrbildschirms (`lockscreen/`) und die
Werkzeuge in `tools/`.

## Sport

Plugin `alpeSport`: ein Tab «Sport» und eine Übersichtskarte «Sport heute» im Dashboard
(`alpe ipc call dash open plugin_alpeSport`). Aufbau wie FotMob:

- **Links** die Wettbewerbe, darüber «Alle Spiele», «Live» und «Favoriten». Die Zahl neben einem Eintrag
  zählt die laufenden Spiele.
- **Mitte** die Spiele des gewählten Tages, nach Wettbewerb (Datumsleiste, Pfeiltasten links/rechts), oder
  die Seite eines Wettbewerbs mit «Spiele» und «Tabelle».
- **Rechts** das Spieldetail mit Übersicht (Verlauf, Topspieler, Infos), Statistik und Aufstellung bzw.
  Boxscore. Unter etwa 1000 px Breite legt es sich über die Liste (Esc oder Pfeil schliesst).

Breite und Höhe des Tabs lassen sich im Bearbeiten-Modus des Dashboards ziehen; für alle drei Spalten
nebeneinander 8 Spalten breit. Welche Wettbewerbe erscheinen, steht in den Optionen des Tabs
(Einstellungen → Dashboard). Champions League, Europa League und Super League sind wählbar, aber aus.

Länderspiele der Schweiz: «Nati Fussball» kommt aus dem Spielplan des Teams bei ESPN (alle Wettbewerbe,
mit Spieldetail). «Nati Eishockey» liest die Resultate-Seite von sihf.ch, weil die Statistik-Schnittstelle
keine Länderspiele führt – dort gibt es Datum, Turnier, Ort und Resultat, aber keine Anspielzeit und kein
Detail.

Fehlersuche: `~/.config/dms/plugins/alpeSport/sport selftest --text` prüft jede Quelle mit Zeitmessung
(auch in `alpe doctor`); langsame und fehlgeschlagene Abrufe stehen in `~/.cache/alpe/sport/log.txt`.

Favoriten: Stern beim Team im Spieldetail oder Rechtsklick auf eine Tabellenzeile. Gespeichert in den
Plugin-Daten (`favorites`, z. B. `hockey:101144` für den EVZ).

Quellen, ohne Schlüssel und nicht offiziell dokumentiert: ESPN (`site.api.espn.com`) für Fussball und NBA,
die Statistik-Schnittstelle des Verbands (`data.sihf.ch`) für die National League. Das Hilfsprogramm
`plugins/alpeSport/sport` vereinheitlicht beide (`sport day [JJJJ-MM-TT]`, `sport league ID`,
`sport match ID SPIEL`, Ausgabe JSON) und braucht nur Python. Während ein Spiel läuft, lädt der Tab alle
30 s nach, sonst seltener und nur, solange er sichtbar ist. Antworten und Logos liegen in
`~/.cache/alpe/sport`; fällt eine Quelle aus, bleibt der letzte Stand stehen. Die Statistik-Schnittstelle der
National League liefert keine Logos; sie kommen von TheSportsDB (`HOCKEY_LOGOS` im Hilfsprogramm), fehlende
Vereine zeigen Kürzel in den Vereinsfarben (`HOCKEY_TEAMS`).

Vorschau ohne Shell: `python3 entwicklung/sportharness/make_fixtures.py`, dann
`python3 entwicklung/sportharness/shot.py entwicklung/sportharness/scenes/tab_wide.qml bild.png`.

## Sperrbildschirm gestalten

Stil «Eigenes Layout» (Vorgabe): Texte, Bilder und Passwortfeld frei angeordnet. Gestaltet wird in den
Einstellungen unter Sicherheit → **Sperrbildschirm gestalten**: Die Vorschau ist der echte
Sperrbildschirm; Elemente anklicken, ziehen, mit dem Mausrad vergrössern, Feinheiten in den Karten.

Eine Ansicht für alles: `quickshell/Modules/Lock/Alpe/HyprlockView.qml` (mit Vorlage `layout.js` und
Schriften) zeichnet die Vorschau, die Sperre der Shell (Hyprland) und – beim Einrichten ins KDE-Design
kopiert – den KDE-Sperrbildschirm. Gespeichert wird das Layout als JSON: unter KWin in `kscreenlockerrc`
(`[Greeter][LnF][General] Layout`), sonst in den Einstellungen der Shell (`alpeLockLayout`).

Ohne eigenes Layout gilt `~/.config/alpe/hyprlock.conf`, sonst die neutrale Vorlage `lockscreen/hyprlock.conf`, umgesetzt
von `tools/hyprlock2qml.py`. Bilder darin erwartet die Vorlage unter `~/Pictures/Hyprlock/`.

    bash ~/alpe/tools/lockscreen.sh hyprlock /pfad/hyprlock.conf   (KDE) hyprlock.conf als Layout übernehmen
    bash ~/alpe/tools/lockscreen.sh show                           (KDE) 15 s zur Ansicht
    bash ~/alpe/tools/maclock.sh [apply|undo]                      (Hyprland) hyprlock durch die Shell-Sperre ersetzen

**Am Mac (Hyprland) bleibt hyprlock die Sperre.** «Sperrbildschirm gestalten» liest und schreibt dort
`~/.config/hypr/hyprlock.conf` (`quickshell/scripts/alpe-hyprlock.py`): Alpe schreibt die Blöcke background,
label, image, shape und input-field neu; general, auth, animations und `$variablen` bleiben. Vor jedem Schreiben
liegt eine Sicherung in `~/.local/state/alpe/hyprlock/` (die erste zusätzlich als `hyprlock.conf.vor-alpe`).
Folgt der Hintergrund dem Desktop, trägt die Datei die Marke `# alpe: hintergrund = desktop`, und die Shell
tauscht das Bild bei jedem Wechsel des Desktop-Bilds (bei Video das Standbild). Die Sprache für Wochentag und
Monat steht als `LC_TIME=… date` im Text. Deckkraft von Bildern kennt hyprlock nicht; die Seite blendet sie aus.

Wahlweise sperrt stattdessen die Shell selbst (Einstellungen → Sicherheit → Sperrbildschirm):
`maclock.sh` ersetzt dafür in `~/.config/hypr` (`.conf` und `.lua`) Aufrufe von hyprlock durch
`dms ipc call lock lock`, stellt `lock_cmd` von hypridle um und ersetzt das Sperren beim Start durch die
Einstellung `lockAtStartup`. Ohne `apply` zeigt es nur; jede geänderte Datei bekommt eine Sicherung.

## Fensterregeln: Fenster anklicken

Wie im KDE-Dialog: In den Fensterregeln **Fenster anklicken** drücken, dann das gewünschte Fenster
anklicken. Alpe öffnet eine neue Regel mit Klasse und Titel.

- **KWin:** über `queryWindowInfo` von KWin (Fadenkreuz von KWin). Die neue Regel bekommt die Klasse
  und den Titel (genau); unter «Fenstertitel» lässt sich das auf «enthält», «Regulärer Ausdruck» oder
  «Titel egal» stellen (`title`/`titlematch` in der `kwinrulesrc`, wie im KDE-Dialog).
- **Hyprland:** über `slurp -p` und `hyprctl clients` (`quickshell/scripts/alpe-hypr-pick.py`). Bei
  überlappenden Fenstern gewinnt das oberste (Spezial-Arbeitsfläche, schwebend, zuletzt fokussiert).
  Der Titel wird als Regex maskiert (`^Downloads \(2\)$`). Esc bricht ab. Ohne `slurp` nimmt Alpe nach
  3 Sekunden das fokussierte Fenster.

## Hyprland: Unschärfe

Einstellungen → System → **Fenster & Effekte** zeigt unter Hyprland einen Modus für die Unschärfe: wie in
DMS eingestellt, mit Feineinstellungen (Körnung, Kontrast, Helligkeit, Sättigung, `ignore_opacity`,
`new_optimizations`, Popups, Spezial-Arbeitsflächen) oder ganz aus. Geschrieben wird über die
Lua-Konfiguration, die DMS ohnehin erzeugt (`HyprlandService.blurLines`), es gibt also keinen zweiten Ort.
«Robust einstellen» setzt die Werte, die am seltensten Darstellungsfehler zeigen; eine Karte zeigt live,
was Hyprland gerade verwendet (`hyprctl getoption`).

## MacBook: Dieses Gerät

- **Akku schonen:** Ladegrenze 50–100 % (`charge_control_end_threshold`, am MacBook `macsmc-battery`).
  Der Kernel vergisst sie beim Neustart; der Systemdienst `alpe-ladegrenze` setzt sie wieder.
- **Zuklappen:** Verhalten im Akkubetrieb, am Netzteil und mit externem Bildschirm
  (`/etc/systemd/logind.conf.d/60-alpe-deckel.conf`).
- **Tastaturbeleuchtung:** Helligkeit, aus nach einer Zeit ohne Eingabe und beim Sperren.

Was Root braucht, läuft über `pkexec` und `quickshell/scripts/alpe-root.sh`, das jede Eingabe prüft.

## Leistung

Einstellungen → System → **Leistung** zeigt Speicher (PSS) und CPU von Oberfläche und Dienst
(`scripts/alpe-perf.py`, nur solange die Seite offen ist). Teile des Dienstes, die ein Rechner nicht
braucht, stehen in `~/.config/alpe/aus` und starten dann gar nicht (`core/internal/server/alpe_off.go`):
`bluetooth`, `wellbeing`, `clipboard`, `location`, `trayrecovery`, `evdev`, `notifyactions`. Das wirkt nur mit
dem eigenen Dienst (siehe «Unterbau») und nach einem Neustart der Shell.

## Ein weiterer Rechner

Es gibt nur eine Ausgabe von Alpe. Was ein Rechner hat (Akku, WLAN, KWin oder Hyprland,
Tastaturbeleuchtung), erkennt die Shell zur Laufzeit; Einstellungen → System → «Dieses Gerät»
zeigt das Ergebnis. Am einfachsten richtet `get.sh` alles ein (siehe README); von Hand:

1. Den Ordner `alpe` auf den Rechner bringen (`git clone https://github.com/alpe-shell/alpe ~/alpe`
   oder ein Archiv der Releases nach `~` entpacken).
2. `bash ~/alpe/bootstrap.sh --check` – prüft und zeigt, was geschähe.
3. `bash ~/alpe/bootstrap.sh` – holt den Shell-Code im Stand aus `BASE`, legt alle Schichten
   darauf, kopiert die Plugins und stellt den Start der Shell um.

Der Start wird so umgestellt, dass nichts Bestehendes überschrieben wird:

- läuft die Shell als `dms.service`: Drop-in `~/.config/systemd/user/dms.service.d/alpe.conf`;
- startet Hyprland sie (`exec-once = dms run`): Datei `~/.config/hypr/alpe.conf` mit
  `env = DMS_SHELL_DIR,…` und ein Verweis darauf in der ersten Zeile von `hyprland.conf`
  (Sicherung: `hyprland.conf.vor-alpe`).

`bash ~/alpe/bootstrap.sh --undo` nimmt beides zurück.

Der Hintergrunddienst `dms` muss denselben Stand haben wie der Shell-Code (`BASE`). Weicht das
installierte Paket ab, baut `--build-backend` ihn mit `tools/backend.sh` aus dem geholten
Quellcode und stellt ihn ein (braucht `go` und `make`, siehe «Unterbau»).

Die Einstellungen eines Rechners (`~/.config/dms/settings.json`) wandern nicht mit; jeder
behält seine eigenen. Nur zwei Dinge setzt `install.sh` (über `tools/activate-plugins.py`), und
nur, wo sie fehlen: Die Plugins MeteoSchweiz und Radar werden eingeschaltet, und MeteoSchweiz
kommt an die erste Stelle der Wetteranbieter. Ein bewusst ausgeschaltetes Plugin bleibt aus.

## Unterbau

Der Hintergrunddienst und die Oberfläche müssen zusammenpassen. Zwei Wege:

**Dienst aus dem Paket** (`/usr/bin/dms` aus `dux-shell`). Damit ein Systemupdate ihn nicht an
der Oberfläche vorbei erneuert, ist das Paket von Updates ausgenommen:

    sudo sed -i -E 's/^#?[[:space:]]*IgnorePkg[[:space:]]*=[[:space:]]*(.*)$/IgnorePkg = \1 dux-shell/' /etc/pacman.conf

**Eigener Dienst** `alpe` (`tools/backend.sh`), gebaut aus demselben Quellbaum `~/dux-shell`
wie die Oberfläche. Er meldet sich als `2.1.2-alpe1.0` (Ursprungsstand und Alpe-Version) und passt per Bau immer; die Ausnahme in
`pacman.conf` ist dann unnötig.

    sudo pacman -S --needed go make        # Fedora: sudo dnf install golang make
    bash ~/alpe/tools/backend.sh build     # nach ~/.local/lib/alpe/alpe (alter Stand: alpe.prev)
    bash ~/alpe/tools/backend.sh use alpe  # dms.service startet ihn (Drop-in zz-alpe-backend.conf)
    bash ~/alpe/tools/backend.sh status
    bash ~/alpe/tools/backend.sh use system    # zurück zum Dienst aus dem Paket
    bash ~/alpe/tools/backend.sh rollback      # vorherigen eigenen Bau wieder einsetzen

Ohne `dms.service` (Hyprland mit `exec-once`) zeigt `~/.local/bin/dms` auf den eigenen Dienst
(Sicherung eines vorhandenen Eintrags: `dms.vor-alpe`). `go.mod` verlangt Go 1.27.3; ist die
installierte Version älter, lädt Go die passende selbst nach (`GOTOOLCHAIN=auto`).

## Neue Version des Ursprungsprojekts

`tools/upstream.sh` legt die Schichten auf einen neuen Stand und prüft, alles in einem eigenen
Arbeitsordner (`~/.cache/alpe/upstream/<stand>`); die laufende Shell bleibt bis zur Übernahme
unberührt.

    bash ~/alpe/tools/upstream.sh check            # neuere Versionen anzeigen
    bash ~/alpe/tools/upstream.sh try v2.2.0       # Schichten auflegen, Prüfungen laufen lassen
    bash ~/alpe/tools/upstream.sh resume v2.2.0    # nach einem von Hand gelösten Konflikt
    bash ~/alpe/tools/upstream.sh adopt v2.2.0     # übernehmen: Zweig alpe, schichten/*.patch, BASE
    bash ~/alpe/tools/upstream.sh back             # zurück auf den Stand vor der Übernahme
    bash ~/alpe/tools/upstream.sh abandon v2.2.0   # Versuch verwerfen

Geprüft werden das KWin-Skript, Headset- und Helligkeitsskript, alle von Alpe berührten
QML-Dateien auf Syntaxfehler (wenn `qmllint` da ist) und das Übersetzen des Dienstes (wenn `go`
da ist). Gelöste Konflikte merkt sich Git (`rerere`); `upstream.sh` legt die Lösungen in
`rerere/` ab, damit derselbe Konflikt beim nächsten Mal von selbst aufgeht. Mitgeliefert sind
die Lösungen für den Entwicklungsstand `master` vom November 2026 (fünf Schichten mit
Konflikten: KWin, Wartung, Einstellungen, Griffleisten, Geräteerkennung). Was so gelöst wurde,
meldet das Skript als «gelöst … bitte ansehen».

Ein Entwicklungsstand wie `master` lässt sich nur mit `adopt master --dev` übernehmen und nur
auf diesem Rechner; `shell/` und `BASE` bleiben dann beim veröffentlichten Stand, damit
`bootstrap.sh` auf anderen Rechnern weiter funktioniert.

## Griffleisten

Die Fensterregel «keine Titelleiste» nimmt den Fenstern ihren Griff. Ersatz: Auf dem oberen
Rand jedes solchen Fensters liegt ein unsichtbarer Streifen, der es verschiebt (Doppelklick:
maximieren). So greifen die Teile ineinander:

1. `Services/kwin/dms-bridge.js` (läuft in KWin) kennt Lage und Stapelfolge aller Fenster und
   meldet mit jedem Zustand, wo der obere Rand sichtbar ist (`grips`). Ausgelassen werden
   Vollbild, minimierte Fenster, Fenster mit KWin-Titelleiste, ausgenommene Programme und
   solche, die ihre Titelleiste selbst zeichnen (erkannt am eigenen Schatten:
   `bufferGeometry` grösser als `frameGeometry`).
2. `Modules/WindowGrips.qml` legt über jede gemeldete Stelle eine kleine Layer-Shell-Fläche.
   Solange ein Popout oder Dialog der Shell offen ist, ruhen die Flächen.
3. Ein Druck ruft über kglobalaccel das Tastenkürzel `alpe-grip-begin` auf. Das Skript sucht
   die Leiste unter dem Zeiger und führt das Fenster nach (`workspace.cursorPosChanged`), bis
   `alpe-grip-end` kommt, das Fenster verschwindet oder der Zeiger fünf Sekunden ruht.

Der Streifen sitzt rittlings auf dem Rand: `windowGripHeight` Pixel im Fenster (diese Klicks
erreichen das Programm nicht mehr, deshalb wenig) und `windowGripOutside` Pixel darüber, dort
aber nur, wo kein anderes Fenster liegt. Von Hand auslösen, etwa zur Fehlersuche:

    busctl --user call org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component invokeShortcut s alpe-grip-begin

Dazu:

- Über einem Streifen zeigt der Zeiger eine offene Hand, beim Ziehen eine geschlossene.
- Losgelassen am linken oder rechten Bildschirmrand füllt das Fenster die Hälfte, in einer Ecke
  ein Viertel, am oberen Rand wird es maximiert. Eine Fläche zeigt vorher, wohin es geht.
  Ränder, an die ein weiterer Bildschirm grenzt, sind Durchgänge und rasten nicht ein.
  Abschalten: Einstellungen → KWin & Plasma → «Am Bildschirmrand einrasten».
- Rechtsklick auf den Streifen: Minimieren, Maximieren, Im Vordergrund halten, Auf allen
  Arbeitsflächen, Schliessen.
- Auch die Fenster der Shell (Einstellungen, Systemmonitor) haben einen Streifen.
- In den beiden unteren Ecken liegt je eine Fläche von 18 px; der Zeiger wird zum
  Doppelpfeil, Ziehen ändert die Grösse (mindestens 160 × 100). Abschalten: «Grösse an den
  unteren Ecken ziehen» (`windowGripCorners`).

## Sperrbildschirm

Unter KWin sperrt KDEs `kscreenlocker`. Welches Design er zeigt, steht in
`~/.config/plasmashellrc` unter `[Shell] ShellPackage`. Fehlt das genannte Paket oder lädt es
nicht, fällt er auf ein Notdesign zurück (blau, «Lockscreen QML outdated»).

`lockscreen/org.alpe.desktop` ist ein eigenes Design im Alpe-Look: Hintergrund des Desktops,
weichgezeichnet und abgedunkelt. Stil «klar» (Vorgabe): Datum in Versalien, schlanke Uhr in
einer Zeile (Inter, sonst Noto Sans), Name mit Bild oder Initiale, Passwortfeld aus Milchglas
mit Pfeilknopf. Stil «slab»: Stunden und Minuten übereinander in Alfa Slab One
(`kscreenlockerrc [Greeter][LnF][General] Style=slab`, oder Schalter in den Einstellungen). Es
braucht nur QtQuick; fehlt Plasmas Tastaturmodul, entfällt nur der Hinweis zur Feststelltaste.

    bash ~/alpe/tools/lockscreen.sh status
    bash ~/alpe/tools/lockscreen.sh install   # kopieren, 5 s im Testmodus laden, dann einschalten
    bash ~/alpe/tools/lockscreen.sh use kde   # zurück zu KDEs Design
    bash ~/alpe/tools/lockscreen.sh repair    # nur einen ungültigen Eintrag entfernen

Eingeschaltet wird nur, was im Testmodus fehlerfrei lud. Ein Eintrag, der auf ein fehlendes
oder kaputtes Paket zeigt (etwa ein übrig gebliebenes `caelestia.desktop`), wird entfernt; das
Paket wandert nach `~/.local/share/alpe/alte-shells`. In den Einstellungen (Sperrbildschirm)
lassen sich Design, Unschärfe und Abdunkeln wählen; der Hintergrund folgt dem Desktop.

Notausgang, falls eine Sperre nicht aufgeht: Strg+Alt+F3, anmelden,
`loginctl unlock-sessions`, zurück mit Strg+Alt+F1 (oder F2).

## Headset-Akku

UPower meldet nur Geräte, die der Kernel als Akku kennt (die Logitech-Maus etwa). Funk-Headsets
mit eigenem Empfänger brauchen ein Werkzeug, das ihr HID-Protokoll spricht:

    paru -S headsetcontrol        # HyperX Cloud II Wireless (03f0:0696, 03f0:018b, 0951:1718) u. v. a.
    paru -S hyper-headset-bin     # HyperX, ausdrücklich auch Cloud II Core Wireless

Danach den Empfänger einmal aus- und einstecken (udev-Regel). Prüfen:

    lsusb | grep -i -e hyperx -e 03f0 -e 0951
    python3 ~/dux-shell/quickshell/scripts/alpe-headset.py

Die Antwort von `hyper_headset_cli --json` ist nicht dokumentiert; das Skript sucht darin nach
Bedeutung (Feldnamen mit `battery`, `charg`, `connect`). Stimmt etwas nicht, die Rohausgabe
ansehen und `parse_generic` anpassen.

## Tests

Alles auf einmal, genau wie auf GitHub:

    alpe test                       (oder: bash tools/test.sh)

Das sind:

    node tests/test_bridge.js       (KWin-Brücke in ~/dux-shell, braucht node)
    python3 tests/test_*.py         (Wetter, Radar mit h5py, Headset, Helligkeit, KWin-Helfer,
                                     hyprlock, Gerät, Fenster anklicken unter Hyprland …)
    bash -n install.sh … tools/alpe (Syntax der Skripte)
    entwicklung/pageharness/loadall.py
                                    (jede Alpe-Einstellungsseite muss laden; braucht PySide6,
                                     sonst übersprungen)
    go test ./internal/server -run TestReadAlpeOff   (in ~/dux-shell/core, braucht go)

### Prüfung auf persönliche Werte

`tests/test_werte.py` durchsucht über `tools/werte-pruefen.py` alle versionierten Textdateien nach
Pfaden in ein Home-Verzeichnis, Benutzer- und Rechnernamen, IP- und MAC-Adressen und
Gerätekennungen. Von Hand, auch gegen einen anderen Ordner:

    python3 tools/werte-pruefen.py [ORDNER] [--ausnahmen] [--ohne-ausnahmen]

- **Binärdateien** (Schriften, Bilder, Klänge, Video, PDF, Shader – was ein NUL-Byte enthält oder
  kein UTF-8 ist) werden roh nach denselben Werten durchsucht: als Bytefolge und noch einmal ohne
  NUL-Bytes (UTF-16 in Metadaten). Grenzen: Namen unter vier Zeichen werden dort nicht gesucht (in
  komprimierten Daten träfen sie zufällig), eine IP-Adresse zählt nur streng gültig, komprimierte
  Ströme werden nicht entpackt, Namen mit Zeichen ausserhalb von ASCII nicht gefunden.
- **Nicht durchsucht** werden Textdateien, deren Endung nicht auf der Liste `ENDUNGEN` steht (etwa
  `.svg`, `.frag`); der Lauf nennt ihre Zahl.
- **Ausnahmen** stehen in `tools/werte-ausnahmen.txt`: je Datei, Art und erwartetem Wert, mit Frist
  und Grund. Ein anderer Fund in derselben Datei schlägt an.
- **Die Ausnahmeliste selbst wird als ganze Datei nicht durchsucht** – bewusste Regel: Sie muss die
  ausgenommenen Werte nennen. Das gilt nur für die Liste, die der Lauf anwendet (die Datei neben dem
  Skript), nicht für eine gleichnamige Datei in einem anderen durchsuchten Ordner. Kommentare und
  Begründungen in der Liste prüft darum niemand; persönliche Werte gehören auch dort nicht hin.
- **Überholte Ausnahmen:** Eine Ausnahme ohne Treffer gilt als überholt und macht den Test rot – aber
  nur, wenn ihre Art in diesem Lauf gesucht wurde. Benutzer- und Rechnername kommen vom Rechner, auf
  dem der Test läuft (Namen aus einem Zeichen und Allerweltsnamen wie `runner` werden nicht
  gesucht; Namen unter vier Zeichen und solche, die auch eine Distribution oder ein Produkt
  bezeichnen, nur in eindeutigem Zusammenhang: `nutzer@name`, Hostname-Feld oder -Befehl, Pfad in
  ein Home, Rechnerfeld einer Journal-Zeile im Syslog-Format – `journalctl -o short`,
  `short-precise`, `short-iso`, `short-iso-precise`, `short-full`, `with-unit`, RFC 3164 und
  RFC 5424; **nicht** erkannt werden Ausgaben ohne Uhrzeit vor dem Rechnerfeld – `short-unix`,
  `short-monotonic`, `short-delta` – und Zeilen nach RFC 5424, deren PROCID weder «-» noch eine
  Zahl ist). Ausnahmen dieser beiden Arten werden nur beurteilt, wenn der Name des Rechners gesucht
  wurde und im Repository überhaupt vorkommt; in der CI und auf einem Rechner mit anderem Namen sagt
  der Lauf über sie nichts aus.
- **Dokumentationsbereiche sind kein Fund:** MAC-Adressen aus `00:00:5E:00:53:00/24` (RFC 7042) und
  IP-Adressen aus `192.0.2.0/24`, `198.51.100.0/24` und `203.0.113.0/24` (RFC 5737). Neue eigene
  Testdaten verwenden nur solche Werte und brauchen dann keine Ausnahme.

Quelle der Prognose- und Radardaten: MeteoSchweiz. Wetterdaten über Open-Meteo.com.
Kartengrundlage: Natural Earth. Musterdatei in `tests/data`: MeteoSchweiz Open Data.

