package server

import (
	"errors"
	"testing"
	"time"

	"github.com/alpe-shell/alpe/core/internal/server/cups"
	"github.com/godbus/dbus/v5"
)

func TestCupsRueckzugPausenUndRuecksetzen(t *testing.T) {
	zeit := time.Unix(1000, 0)
	r := cupsRueckzug{jetzt: func() time.Time { return zeit }}

	if !r.darf() {
		t.Fatal("ohne Fehlschlag muss der erste Versuch durchgehen")
	}
	erwartet := []time.Duration{5 * time.Second, 10 * time.Second, 20 * time.Second, 40 * time.Second, time.Minute, time.Minute}
	for i, pause := range erwartet {
		erster, bekommen := r.gescheitert()
		if erster != (i == 0) {
			t.Fatalf("Fehlschlag %d: erster=%v", i+1, erster)
		}
		if bekommen != pause {
			t.Fatalf("Fehlschlag %d: Pause %s, erwartet %s", i+1, bekommen, pause)
		}
		if r.darf() {
			t.Fatalf("Fehlschlag %d: direkt danach darf kein Versuch durchgehen", i+1)
		}
		zeit = zeit.Add(pause - time.Millisecond)
		if r.darf() {
			t.Fatalf("Fehlschlag %d: kurz vor Ende der Pause darf kein Versuch durchgehen", i+1)
		}
		zeit = zeit.Add(time.Millisecond)
		if !r.darf() {
			t.Fatalf("Fehlschlag %d: nach der Pause muss ein Versuch durchgehen", i+1)
		}
	}
	if !r.gelungen() {
		t.Fatal("Erfolg nach Fehlschlägen muss als Rückkehr gemeldet werden")
	}
	if r.gelungen() {
		t.Fatal("Erfolg ohne vorherigen Fehlschlag ist keine Rückkehr")
	}
	if erster, pause := r.gescheitert(); !erster || pause != 5*time.Second {
		t.Fatalf("nach einem Erfolg beginnt der Rückzug neu: erster=%v, Pause %s", erster, pause)
	}
}

// Ohne laufendes CUPS: Nur der erste Versuch und die Versuche nach Ablauf der Pause erreichen CUPS;
// alles dazwischen kehrt sofort mit errCupsRueckzug zurück (und schreibt damit auch nichts).
func TestCupsManagerOhneCupsNurEinVersuchJePause(t *testing.T) {
	cupsMu.Lock()
	alterManager, alteVersuche, alteFabrik, alteVerfuegbar := cupsManager, cupsVersuche, cupsNeuerManager, cupsEverAvailable
	cupsMu.Unlock()
	t.Cleanup(func() {
		cupsMu.Lock()
		cupsManager, cupsVersuche, cupsNeuerManager, cupsEverAvailable = alterManager, alteVersuche, alteFabrik, alteVerfuegbar
		cupsMu.Unlock()
	})

	zeit := time.Unix(2000, 0)
	versuche := 0
	abgelehnt := errors.New("dial tcp 127.0.0.1:631: connect: connection refused")
	cupsMu.Lock()
	cupsManager = nil
	cupsEverAvailable = false
	cupsVersuche = cupsRueckzug{jetzt: func() time.Time { return zeit }}
	cupsNeuerManager = func(func() (*dbus.Conn, error)) (*cups.Manager, error) {
		versuche++
		return nil, abgelehnt
	}
	cupsMu.Unlock()

	if _, err := ensureCupsManager(); !errors.Is(err, abgelehnt) || versuche != 1 {
		t.Fatalf("erster Versuch: err=%v, Versuche=%d", err, versuche)
	}
	for i := 0; i < 20; i++ {
		if _, err := ensureCupsManager(); !errors.Is(err, errCupsRueckzug) {
			t.Fatalf("Versuch in der Pause: err=%v", err)
		}
	}
	if versuche != 1 {
		t.Fatalf("in der Pause wurde CUPS %d-mal angesprochen, erwartet 1", versuche)
	}
	zeit = zeit.Add(5 * time.Second)
	if _, err := ensureCupsManager(); !errors.Is(err, abgelehnt) || versuche != 2 {
		t.Fatalf("nach der Pause: err=%v, Versuche=%d", err, versuche)
	}
	if cupsAvailable() {
		t.Fatal("ohne CUPS darf die Fähigkeit cups nicht gemeldet werden")
	}
}
