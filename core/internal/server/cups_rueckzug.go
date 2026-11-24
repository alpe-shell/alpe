package server

import (
	"errors"
	"time"
)

// Alpe: Läuft kein CUPS (so am Mac), scheitert jeder Aufbau des CUPS-Managers an «connection refused».
// Die Oberfläche versucht es bei jedem Abonnement und jeder cups.*-Anfrage neu; früher schrieb jeder
// Versuch eine Warnung. Der Rückzug meldet den Ausfall einmal und lässt weitere Versuche erst nach einer
// wachsenden Pause wieder bis zu CUPS durch. Ein gelungener Aufbau setzt alles zurück.
const (
	cupsRueckzugAnfang = 5 * time.Second
	cupsRueckzugGrenze = time.Minute
)

// errCupsRueckzug: Der Versuch fiel in die Pause; CUPS wurde nicht angesprochen.
var errCupsRueckzug = errors.New("cups: letzter Versuch gescheitert, nächster Versuch nach der Pause")

type cupsRueckzug struct {
	fehlschlaege int
	naechster    time.Time
	jetzt        func() time.Time
}

func (r *cupsRueckzug) uhr() time.Time {
	if r.jetzt != nil {
		return r.jetzt()
	}
	return time.Now()
}

// darf meldet, ob jetzt ein Versuch bis zu CUPS gehen soll.
func (r *cupsRueckzug) darf() bool {
	return r.fehlschlaege == 0 || !r.uhr().Before(r.naechster)
}

// gescheitert verbucht einen Fehlschlag und meldet, ob es der erste seit dem letzten Erfolg ist
// (nur der wird als Warnung geschrieben). Die Pause verdoppelt sich bis zur Grenze.
func (r *cupsRueckzug) gescheitert() (erster bool, pause time.Duration) {
	r.fehlschlaege++
	pause = cupsRueckzugAnfang
	for i := 1; i < r.fehlschlaege && pause < cupsRueckzugGrenze; i++ {
		pause *= 2
	}
	if pause > cupsRueckzugGrenze {
		pause = cupsRueckzugGrenze
	}
	r.naechster = r.uhr().Add(pause)
	return r.fehlschlaege == 1, pause
}

// gelungen setzt den Rückzug zurück und meldet, ob davor Fehlschläge lagen.
func (r *cupsRueckzug) gelungen() (nachAusfall bool) {
	nachAusfall = r.fehlschlaege > 0
	r.fehlschlaege = 0
	r.naechster = time.Time{}
	return nachAusfall
}
