# Dienst: Zeitgrenze für alle Verbindungen zum Systembus (Plan 0.8 Nr. 82)

Stand: **Freigegeben am 22.11.2026 wie vorgeschlagen** (Plan 0.8 Nr. 84; Antworten in Abschnitt 6).

## 1. Befund

Antwortet der Systembus nicht auf `Hello`, startet `alpe-dienst` nie fertig: Die Schnittstelle nimmt
keine Verbindungen an, die Oberfläche meldet nie `Connected`. Gefunden in der Ladeprüfung unter dem
verschachtelten Hyprland (Ersatz-Systembus ohne Antwort-Regeln; in `439de4f` berichtigt). Der Fehler
stammt aus der Zeit vor Phase A.

Belegt durch die Goroutinen-Stapel des hängenden Dienstes (`ALPE_LP_STAPEL=1`, `76f42f0`) und den Code
von godbus v5.2.4:

| Goroutine | Zustand | Ort |
|---|---|---|
| `InitializeLoginctlManager` (nebenher) | wartet in `(*Conn).Hello` | `dbus.SystemBus()` → `ConnectSystemBus()` – **hält dabei `systemBusLck`** |
| `InitializeNetworkManager` (nebenher) | wartet in `(*Conn).Hello` | eigenes `dbus.ConnectSystemBus()` in `network.DetectNetworkStack` |
| `InitializeFreedeskManager` (nebenher) | `sync.Mutex.Lock` | `dbus.SystemBus()` |
| **Hauptablauf**, `InitializeWaylandManager` → `wayland.NewManager` → `setupDBusMonitor` | `sync.Mutex.Lock` | `dbus.SystemBus()` |

**Antwort auf die Frage zur Sperre: Ja.** Gamma wartet nicht auf den Compositor und nicht auf eine eigene
Sperre, sondern auf `systemBusLck`, die paketweite Sperre in `dbus.SystemBus()` (`conn.go`, Zeile 120 ff.).
godbus hält sie über den ganzen Verbindungsaufbau samt `Hello`, und `Hello` hat keine Zeitgrenze. Ein
einziger hängender Aufrufer blockiert damit jeden weiteren Aufruf von `dbus.SystemBus()` im Prozess.

Warum nur unter Hyprland sichtbar: Unter KWin scheitert `wayland.NewManager` schon vorher («compositor
does not support gamma control») und erreicht `setupDBusMonitor` nie; die drei Manager hängen dort still
im Hintergrund. Unter Hyprland steht der Hauptablauf, und `s.ipc.Serve` kommt erst ganz am Ende von
`Start()` (`server.go`, nach allen synchronen Initialisierungen).

Zweiter Befund: `Start()` nimmt Verbindungen erst an, wenn alle synchronen Manager fertig sind. Jeder
synchrone Schritt, der hängt, hält also die ganze Schnittstelle auf.

## 2. Vorschlag (die kleinere Variante, geprüft)

### 2.1 Eine Systembus-Verbindung, vom Dienst aufgebaut, mit Zeitgrenze

Neues Paket `core/internal/systembus`:

- `Verbinden(ctx, grenze) (*dbus.Conn, error)` baut die Verbindung mit
  `dbus.ConnectSystemBus(dbus.WithContext(c))` auf.
- **Achtung, Eigenheit von godbus:** Der Context aus `WithContext` begrenzt nicht nur den Aufbau, er ist
  die Lebensdauer der Verbindung (`newConn` startet `<-ctx.Done(); conn.Close()`). Ein
  `context.WithTimeout` schlösse die Verbindung also auch nach erfolgreichem Aufbau, sobald die Frist
  abläuft. Darum: `context.WithCancel` plus `time.AfterFunc(grenze, cancel)`; nach erfolgreichem Aufbau
  wird der Timer gestoppt, der Context lebt bis zum Ende des Dienstes. Läuft die Frist ab, schliesst
  godbus die Verbindung, und `Auth`/`Hello` kehren mit Fehler zurück. Das wird im Test geprüft (3).
- Zeitgrenze für den Aufbau: **3 s** (Vorschlag; am echten Bus dauert er Millisekunden).
- `Halter`: hält die Verbindung, gibt sie über `Conn() (*dbus.Conn, bool)` heraus und meldet über
  einen Kanal `Bereit()`, wenn sie steht. Reisst die Verbindung später ab (`conn.Context().Done()`),
  gilt der Bus wieder als nicht verfügbar; ein Neuaufbau der Manager nach einem Abriss im Betrieb gehört
  **nicht** zu diesem Schritt (heute gibt es das auch nicht) und wird als offener Fall notiert.
- Die Verbindung gehört dem Halter. **Kein Manager schliesst sie**; Manager melden nur ihre eigenen
  Signale und Match-Regeln ab (so macht es Gamma heute schon). Die `Close()`-Wege von `loginctl`,
  `bluez`, `network` (iwd) werden darauf geprüft.

Alle Manager bekommen die Verbindung als Argument; **in `core/` ruft nichts mehr `dbus.SystemBus()`
auf.** Die vier Stellen mit eigenem `dbus.ConnectSystemBus()` im Dienst (`network/detect.go`,
`backend_networkmanager_wifi.go`, `backend_networkmanager_cellular.go`, `priority.go`) nehmen ebenfalls
die geteilte Verbindung, soweit sie im laufenden Dienst liegen.

**Eine Ausnahme, die sich nicht wegplanen lässt:** `github.com/Wifx/gonetworkmanager/v2` (31 Aufrufe
`gonetworkmanager.New…`, davon 23 `NewSettings`) ruft in seinem `utils.go` selbst `dbus.SystemBus()` auf
und nimmt keine Verbindung entgegen. Vorschlag: Das NetworkManager-Backend wird erst eingerichtet, wenn
der Halter «bereit» meldet (der Bus hat also eben geantwortet). Bleibender Rest: Verstummt der Bus genau
danach, kann der erste Aufruf der Bibliothek hängen – aber nur noch in der Netzwerk-Goroutine, weil
sonst niemand mehr an `systemBusLck` wartet. Die Bibliothek zu ersetzen oder zu patchen (Fork mit
`replace` in `go.mod`) wäre die vollständige Lösung; das schlage ich **nicht** für diesen Schritt vor
und führe es als offenen Fall. *Entscheid nötig (Frage 1).*

Ausserhalb des laufenden Dienstes (kurzlebige Befehle): `internal/utils/dbus.go`
(`IsDBusServiceAvailable`, `IsDBusServiceActivatable`, genutzt von `doctor`) und
`internal/geolocation/client_geoclue.go` bekommen dieselbe Zeitgrenze über `systembus.Verbinden`, ohne
Halter.

### 2.2 Scheitern: nicht verfügbar, eine Meldung, erneute Versuche

- Scheitert der erste Aufbau, gelten alle Manager am Systembus als nicht verfügbar: Netzwerk, Loginctl,
  Freedesktop (Systembus-Teil), BlueZ, Helligkeit über logind, CUPS (pkhelper und Abonnement), Laufwerke
  (UDisks), D-Bus-Brücke (Systembus-Teil), GeoClue, Ruhezustands-Überwachung von Gamma. Ihre Fähigkeiten
  fehlen in `capabilities`, wie heute bei einem fehlenden Dienst.
- **Eine** Meldung: `System bus unavailable (…); dependent managers disabled, retrying in background`.
  Die Manager melden in diesem Fall nichts Eigenes.
- Erneute Versuche im Hintergrund mit wachsendem Abstand: 2 s, 4 s, 8 s … bis höchstens 60 s, ohne
  Ende, ohne weitere Meldung pro Versuch (nur `Debug`). Gelingt einer, kommt eine Meldung
  `System bus connected`, die wartenden Manager werden eingerichtet, und `notifyCapabilityChange()`
  meldet der Oberfläche die neuen Fähigkeiten (der Weg besteht schon für Netzwerk und BlueZ).
- Die bestehenden eigenen Wiederholschleifen (Netzwerk: 10 × 30 s; BlueZ: Warten auf den Adapter)
  bleiben, laufen aber erst nach «bereit».

### 2.3 Gamma: Wayland-Teil synchron, Ruhezustand nebenher

- `wayland.NewManager` bleibt synchron wie heute (Registry, Ausgaben, Gamma-Steuerung) und läuft auf der
  geteilten Wayland-Verbindung in derselben Reihenfolge wie bisher. Damit gibt es keine zweite Goroutine
  auf der geteilten Wayland-Verbindung – das Problem entfällt.
- Aus `NewManager` verschwindet nur `setupDBusMonitor()`. Neu: `(*Manager).SystembusAnbinden(conn)`
  setzt `dbusConn`, legt die Match-Regel für `PrepareForSleep` an und startet `dbusMonitor()`. Der
  Dienst ruft das auf, **nachdem die Schnittstelle Verbindungen annimmt**, sobald der Halter «bereit»
  meldet. `Close()` meldet die Regel wie heute ab, wenn eine Verbindung gesetzt ist.
- Zu klären bei der Umsetzung (nur lesen, kein Umbau): Zugriffe auf `m.dbusConn` laufen heute ohne
  Sperre, weil das Feld vor dem Start der Goroutinen gesetzt wird. Mit dem späteren Setzen braucht es
  eine kleine eigene Sperre oder ein `atomic.Pointer` – nur um das Feld, nie über den Busaufruf hinweg.

### 2.4 Schnittstelle vor den Managern am Bus

`s.ipc.Serve` startet heute am Ende von `Start()`. Mit 2.1–2.3 hängt kein synchroner Schritt mehr am
Systembus; die Reihenfolge der synchronen Manager bleibt darum unverändert. Der Halter wird früh in
`Start()` in einer eigenen Goroutine gestartet, die Manager am Bus warten auf «bereit». **Nicht**
vorgeschlagen ist, `Serve` vor die synchronen Manager zu ziehen: Das änderte, was die Oberfläche beim
ersten `Connected` an Fähigkeiten sieht, und ist für die Behebung nicht nötig.

### 2.5 Grundsatz

Keine Sperre wird über einen Bus- oder Netzaufruf hinweg gehalten. Im Zuge der Umsetzung werden die
berührten Pakete darauf durchgesehen (`loginctl`, `freedesktop`, `bluez`, `network`, `cups`, `drives`,
`brightness`, `dbus`, `wayland`); Funde ausserhalb des Verbindungsaufbaus werden **gemeldet und als
offener Fall geführt, nicht nebenbei umgebaut**. Der Grundsatz kommt als Satz in `CLAUDE.md`.

### 2.6 Nicht Teil dieses Schritts

- Session-Bus (`dbus.SessionBus()`, 10 Stellen): gleiche Bauart (`sessionBusLck`), aber kein Befund; der
  Session-Bus der Sitzung ist der, über den die Oberfläche selbst läuft. Offener Fall, kein Umbau.
- Ob der Wayland-Teil von Gamma bei einem stummen Compositor hängen kann, ist nicht belegt: offener Fall
  in `offene-faelle.md`, kein Umbau.
- Zeitgrenzen für einzelne Aufrufe auf einer stehenden Verbindung (`Call` ohne Context).

## 3. Betroffene Dateien

| Datei | Änderung |
|---|---|
| `core/internal/systembus/` (neu: `systembus.go`, `systembus_test.go`) | `Verbinden`, `Halter`, erneute Versuche |
| `core/internal/server/server.go` | Halter starten; `Initialize{Network,Loginctl,Freedesk,Bluez,Brightness,Dbus}Manager`, CUPS, Laufwerke und Ortung nach «bereit»; Gamma anbinden |
| `core/internal/server/wayland/manager.go`, `types.go` | `setupDBusMonitor` aus `NewManager` heraus, `SystembusAnbinden` |
| `core/internal/server/loginctl/manager.go`, `freedesktop/manager.go`, `dbus/manager.go`, `drives/udisks.go` | Verbindung als Argument |
| `core/internal/server/bluez/manager.go`, `watcher.go`, `agent.go` | dito |
| `core/internal/server/brightness/logind.go` | dito (zwei Stellen) |
| `core/internal/server/cups/pkhelper.go`, `subscription_dbus.go` | dito |
| `core/internal/server/network/detect.go`, `backend_iwd.go`, `backend_networkd.go`, `backend_networkmanager_signals.go`, `backend_networkmanager_wifi.go`, `backend_networkmanager_cellular.go`, `agent_networkmanager.go`, `priority.go` | dito; NetworkManager-Backend erst nach «bereit» |
| `core/internal/geolocation/client_geoclue.go`, `core/internal/utils/dbus.go` | `systembus.Verbinden` mit Zeitgrenze |
| `core/internal/mocks/…` | nur falls sich eine Schnittstelle mit Attrappe ändert: `make -C core mocks` (mockery v3.9.1), nie von Hand |
| `tests/test_werte.py` (oder eigener Test) | Strukturtest: kein `dbus.SystemBus()` unter `core/` |
| `docs/plan/offene-faelle.md`, `docs/plan/phase-a-plan.md`, `CLAUDE.md`, `CHANGELOG.md` | Eintrag, Stand, Grundsatz, Hinweis |

Commits: (1) Paket `systembus` mit Tests; (2) Manager auf die geteilte Verbindung, Gamma nebenher,
Strukturtest – ein Commit, weil die Zwischenstände sonst zwei Verbindungswege mischen; (3) Plan, offene
Fälle, Mac-Anleitung. Jeder mit `tools/test.sh` auf dem Commit im Temp-Worktree, dazu `go vet ./...` und
`go test ./...` abgeschottet.

## 4. Tests

Alle Go-Tests abgeschottet (Temp-HOME, `GOMODCACHE`/`GOCACHE`/`GOPATH` aus `go env`), ohne den echten
Systembus: Die Adresse kommt über `DBUS_SYSTEM_BUS_ADDRESS` aus dem Test.

1. **Systembus, der nie antwortet** (`systembus_test.go`): ein Unix-Socket im Temp-Ordner, der
   Verbindungen annimmt und nichts sendet. `Verbinden` mit 200 ms Grenze kehrt innerhalb 1 s mit Fehler
   zurück; danach läuft keine Goroutine des Tests mehr im Verbindungsaufbau.
2. **Stummer Bus nach der Anmeldung:** der Socket beantwortet `AUTH` und schweigt auf `Hello` – genau
   der Fall der Ladeprüfung. Gleiche Erwartung.
3. **Erfolg bleibt bestehen:** gegen einen echten `dbus-daemon` im Temp-Ordner (übersprungen, wenn er
   fehlt; beendet sich über `timeout` selbst): Die Verbindung ist nach Ablauf der Aufbau-Grenze noch
   `Connected()` – prüft die Eigenheit aus 2.1.
4. **Erneute Versuche:** Halter gegen einen Socket, der erst beim dritten Versuch antwortet; Abstände
   wachsen, «bereit» kommt, genau eine Meldung zum Ausfall, eine zur Verbindung.
5. **Start mit stummem Bus** (`server`-Paket): Der Dienst nimmt innerhalb der Frist Verbindungen an,
   `capabilities` enthält weder `network` noch `loginctl`, und Gamma ist – mit einer Attrappe für den
   Wayland-Teil – eingerichtet, ohne Ruhezustands-Überwachung.
6. **Gamma:** `SystembusAnbinden` nach dem Start legt die Match-Regel an; `Close()` vorher und nachher
   ohne Hänger und ohne Wettlauf (`go test -race` für `wayland` und `systembus`).
7. **Strukturtest:** kein `dbus.SystemBus()` und kein `dbus.ConnectSystemBus(` unter `core/` ausserhalb
   von `internal/systembus`.
8. **Ladeprüfung** (nach beiden Commits, 0.8 Nr. 80): beide Varianten unter KWin und Hyprland mit
   antwortendem Ersatz-Systembus, `Connected` in jedem Lauf; dazu **ein Lauf mit der alten, stummen
   Richtlinie** als Gegenprobe (Schalter nur für diesen Zweck, etwa `ALPE_LP_STUMMER_BUS=1`): Die
   Oberfläche meldet trotzdem `Connected`, im Protokoll steht die eine Meldung zum Systembus.

## 5. Was sich am Mac ändert (Fedora Asahi, Hyprland)

Im Normalfall nichts Sichtbares: Der Systembus antwortet in Millisekunden, die Manager sind wie bisher
da. Unterschiede:

- **Nachtlicht/Gamma:** Der Wayland-Teil ist unverändert. Die Überwachung des Ruhezustands hängt erst
  Augenblicke nach dem Start am Bus statt davor. Ein `PrepareForSleep` in diesem Fenster (Zuklappen
  innerhalb der ersten Sekunde nach dem Start des Dienstes) würde verpasst; heute ist es das auch, weil
  der Dienst dann noch gar nicht läuft.
- **Reihenfolge der Fähigkeiten:** Netzwerk, Loginctl usw. erscheinen wie heute nebenher; neu warten
  sie gemeinsam auf eine Verbindung statt jeder auf seine.
- **Bei einem hängenden Systembus** (bisher: Dienst startet nie, Leiste ohne Dienst): Die Oberfläche
  verbindet sich, WLAN, Bluetooth, Akku-/Sitzungsfunktionen und Helligkeit über logind fehlen, bis der
  Bus antwortet, und kommen dann von selbst.
- **Mac-Anleitung** (wird in `offene-faelle.md` ergänzt): Nachtlicht ein- und ausschalten und über die
  Zeitsteuerung prüfen; Deckel zu und auf – die Farbtemperatur muss nach dem Aufwachen wieder stimmen;
  WLAN-Liste, Bluetooth, Helligkeitstasten, Sperren beim Zuklappen.

## 5a. Umsetzung (22.11.2026) und Abweichungen vom Vorschlag

Umgesetzt in zwei Commits: Paket `core/internal/systembus` (`0dbeb27`), danach die Manager, Gamma und
die Gegenprobe. Kein Aufruf von `dbus.SystemBus()`/`dbus.ConnectSystemBus()` mehr ausserhalb von
`internal/systembus` (Strukturtest in `tests/test_werte.py`); `gonetworkmanager` ruft es weiterhin selbst
auf, das NetworkManager-Backend entsteht aber erst mit stehender Verbindung.

Wie die Verbindung zu den Managern kommt:

| Manager | Übergabe | Bei stummem Bus |
|---|---|---|
| Loginctl, Freedesktop, BlueZ | `*dbus.Conn` als Argument, nach `Warten` | wartet still, kommt nach, sobald der Bus antwortet |
| Netzwerk | `*dbus.Conn` als Argument, nach `Erstversuch` | wpa_supplicant über `wpa_ctrl`, falls vorhanden; sonst wartet es und kommt nach |
| Gamma | `SystembusAnbinden(conn)` nebenher nach dem synchronen Wayland-Teil | Nachtlicht läuft, Ruhezustands-Überwachung kommt nach |
| D-Bus-Brücke | `*dbus.Conn` oder nil, dann `SystembusAnbinden` | Session-Bus sofort, Systembus kommt nach |
| Helligkeit | Funktion, die wartet (eigene Goroutine für logind) | sysfs und DDC sofort, logind kommt nach |
| CUPS, Laufwerke | Funktion, die nicht wartet | pkhelper/Liste melden «nicht verfügbar» |
| Ortung | `*dbus.Conn` oder nil nach `Erstversuch` | Ortung über die IP-Adresse |

Abweichungen:

1. **Freedesktop wartet als Ganzes** auf den Systembus, nicht nur sein Systembus-Teil (Accounts): Die
   Felder dafür werden an einem Dutzend Stellen ohne Sperre gelesen; ein nachträgliches Anbinden hätte
   einen Umbau des Pakets verlangt. Folge nur bei stummem Bus: Bildschirmschoner-Sperre und
   Farbschema-Einstellung über den Session-Bus fehlen, bis der Systembus antwortet. Offener Fall.
2. **Ortung:** Startet der Dienst mit stummem Bus, bleibt es bei der Ortung über die IP-Adresse, auch wenn
   der Bus später antwortet (kein Wechsel auf GeoClue im Betrieb). Offener Fall.
3. **Test 5 («Start mit stummem Bus» im `server`-Paket) ist kleiner als geplant:** `Serve()` lässt sich
   in einem Go-Test nicht gefahrlos ganz starten (es richtet Zwischenablage, Tray, Aktualisierungen und
   weitere Manager ein, die sich nicht alle abschalten lassen). Der Go-Test prüft darum die Bausteine am
   stummen Bus (sofortiger Fehler für Anfragen, `Erstversuch` innerhalb der Frist, kein Manager und keine
   Fähigkeit am Bus, `Warten` endet mit dem Context). Den ganzen Start prüft die Gegenprobe der
   Ladeprüfung – unter beiden Compositors bestanden (Hyprland 319 s, KWin 263 s; die Oberfläche meldet
   `Connected`, der Dienst den Ausfall genau einmal).
4. **Kein Eintrag in `CHANGELOG.md`:** Dort gibt es noch keinen Abschnitt 1.1; der Hinweis kommt mit G1.
5. **Zusätzlich:** `Halter.Erstversuch` (Ergebnis des ersten Versuchs abwarten, höchstens 3 s) für
   Manager, die auch ohne Systembus etwas leisten; Test-Helfer `internal/systembus/bustest` (eigener
   stummer oder echter Bus im Temp-Ordner, nie der Systembus des Rechners).

Beobachtung, nicht eingeordnet: Die Läufe mit stummem Bus dauern etwa doppelt so lang wie mit antwortendem
(319 s und 263 s gegen 149 s). Vermutet, nicht belegt: Die Oberfläche selbst (Qt/Quickshell: UPower,
BlueZ, polkit) wartet je auf ihre eigene Zeitüberschreitung am Systembus.

## 6. Fragen an den Maintainer

**Beantwortet am 22.11.2026:** (1) NetworkManager-Backend erst einrichten, wenn die Verbindung steht;
kein Patch der Bibliothek. (2) 3 s für den Aufbau, erneute Versuche ab 2 s verdoppelnd bis 60 s, ohne
Ende. (3) Gegenprobe mit Schalter für einen stummen Bus in der Ladeprüfung: einmal nach der Behebung
unter beiden Compositors, danach nur bei Bedarf, nicht bei jedem Halt. (4) Abriss der Verbindung im
Betrieb bleibt draussen und ist offener Fall.

1. **gonetworkmanager:** Reicht «NetworkManager-Backend erst nach bereit» mit dem beschriebenen Rest
   (Vorschlag), oder soll die Bibliothek in diesem Schritt gepatcht/ersetzt werden, damit wörtlich kein
   `dbus.SystemBus()` mehr im Prozess läuft?
2. **Zeitgrenze und Abstände:** 3 s für den Aufbau, erneute Versuche 2 s verdoppelnd bis 60 s, ohne
   Ende – einverstanden?
3. **Gegenprobe in der Ladeprüfung** (Schalter für den stummen Bus, Test 8): gewünscht, oder genügen
   die Go-Tests 1, 2 und 5?
4. **Abriss im Betrieb:** Neuaufbau der Manager nach einem späteren Verlust der Verbindung bleibt
   draussen und wird offener Fall – einverstanden?
