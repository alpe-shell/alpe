package systembus

import (
	"context"
	"errors"
	"fmt"
	"path/filepath"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/alpe-shell/alpe/core/internal/systembus/bustest"
	"github.com/godbus/dbus/v5"
)

// kurzerOrdner: Unix-Sockets dürfen höchstens 107 Zeichen lang sein; t.TempDir() ist oft länger.
func kurzerOrdner(t *testing.T) string { return bustest.KurzerOrdner(t) }

// Die Busse der Tests stehen in bustest: ein stummer (nie eine Antwort, oder Anmeldung ja und
// Hello nein) und ein echter dbus-daemon im Temp-Ordner.
func stummerBus(t *testing.T, anmelden bool) { bustest.Stumm(t, anmelden) }
func echterBus(t *testing.T)                 { bustest.Echt(t) }

func pruefeZeitgrenze(t *testing.T) {
	t.Helper()
	fertig := make(chan error, 1)
	beginn := time.Now()
	go func() {
		conn, err := Verbinden(context.Background(), 200*time.Millisecond)
		if conn != nil {
			conn.Close()
		}
		fertig <- err
	}()
	select {
	case err := <-fertig:
		if !errors.Is(err, ErrNichtVerfuegbar) {
			t.Fatalf("erwartet ErrNichtVerfuegbar, bekommen: %v", err)
		}
		if !strings.Contains(err.Error(), "no answer within") {
			t.Fatalf("Fehler nennt die Zeitgrenze nicht: %v", err)
		}
		if dauer := time.Since(beginn); dauer < 150*time.Millisecond {
			t.Fatalf("zu früh aufgegeben: %s", dauer)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("Verbinden hängt an einem Systembus, der nicht antwortet")
	}
}

func TestVerbindenBusAntwortetNie(t *testing.T) {
	stummerBus(t, false)
	pruefeZeitgrenze(t)
}

func TestVerbindenBusSchweigtNachAnmeldung(t *testing.T) {
	stummerBus(t, true)
	pruefeZeitgrenze(t)
}

func TestVerbindenOhneBus(t *testing.T) {
	t.Setenv("DBUS_SYSTEM_BUS_ADDRESS", "unix:path="+filepath.Join(kurzerOrdner(t), "gibtsnicht"))
	beginn := time.Now()
	_, err := Verbinden(context.Background(), 2*time.Second)
	if !errors.Is(err, ErrNichtVerfuegbar) || strings.Contains(err.Error(), "no answer within") {
		t.Fatalf("erwartet sofortigen Fehler ohne Zeitgrenze, bekommen: %v", err)
	}
	if time.Since(beginn) > time.Second {
		t.Fatal("fehlender Socket darf nicht bis zur Zeitgrenze warten")
	}
}

// Die Zeitgrenze gilt nur für den Aufbau: Nach ihrem Ablauf muss die Verbindung weiter stehen.
func TestVerbindungBleibtNachDerFrist(t *testing.T) {
	echterBus(t)
	conn, err := Verbinden(context.Background(), 300*time.Millisecond)
	if err != nil {
		t.Fatal(err)
	}
	defer conn.Close()
	time.Sleep(600 * time.Millisecond)
	if !conn.Connected() {
		t.Fatal("Verbindung wurde mit Ablauf der Aufbau-Frist geschlossen")
	}
	var namen []string
	if err := conn.BusObject().Call("org.freedesktop.DBus.ListNames", 0).Store(&namen); err != nil {
		t.Fatalf("Aufruf nach der Frist scheitert: %v", err)
	}
}

func TestVerbindungEndetMitContext(t *testing.T) {
	echterBus(t)
	ctx, abbrechen := context.WithCancel(context.Background())
	conn, err := Verbinden(ctx, time.Second)
	if err != nil {
		t.Fatal(err)
	}
	defer conn.Close()
	abbrechen()
	for range 50 {
		if !conn.Connected() {
			return
		}
		time.Sleep(20 * time.Millisecond)
	}
	t.Fatal("Verbindung überlebt das Ende ihres Contexts")
}

func testHalter(verbinden func(context.Context, time.Duration) (*dbus.Conn, error)) (*Halter, *[]string, *sync.Mutex) {
	var mu sync.Mutex
	meldungen := []string{}
	h := Neu()
	h.Grenze = 100 * time.Millisecond
	h.ErsterAbstand = 20 * time.Millisecond
	h.HoechstAbstand = 80 * time.Millisecond
	h.verbinden = verbinden
	notieren := func(art string) func(string, ...any) {
		return func(format string, v ...any) {
			mu.Lock()
			defer mu.Unlock()
			meldungen = append(meldungen, art+": "+fmt.Sprintf(format, v...))
		}
	}
	h.warnen = notieren("WARN")
	h.melden = notieren("INFO")
	return h, &meldungen, &mu
}

func TestHalterErneuteVersuche(t *testing.T) {
	echterBus(t)
	var versuche atomic.Int32
	var zeiten []time.Time
	h, meldungen, mu := testHalter(func(ctx context.Context, grenze time.Duration) (*dbus.Conn, error) {
		zeiten = append(zeiten, time.Now())
		if versuche.Add(1) < 4 {
			return nil, fmt.Errorf("%w: test", ErrNichtVerfuegbar)
		}
		return Verbinden(ctx, time.Second)
	})
	if _, ok := h.Conn(); ok {
		t.Fatal("Conn vor dem Start darf nichts liefern")
	}
	if _, err := h.Verlangen(); !errors.Is(err, ErrNichtVerfuegbar) {
		t.Fatalf("Verlangen vor dem Start: %v", err)
	}
	ctx, abbrechen := context.WithCancel(context.Background())
	defer abbrechen()
	h.Starten(ctx)
	h.Starten(ctx) // zweiter Aufruf ohne Wirkung

	conn, err := h.Warten(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if !conn.Connected() || versuche.Load() != 4 {
		t.Fatalf("erwartet Verbindung beim vierten Versuch, Versuche: %d", versuche.Load())
	}
	// Abstände 20, 40, 80 ms: wachsend (mit Spielraum für die Uhr).
	a, b, c := zeiten[1].Sub(zeiten[0]), zeiten[2].Sub(zeiten[1]), zeiten[3].Sub(zeiten[2])
	if a < 15*time.Millisecond || b < 35*time.Millisecond || c < 70*time.Millisecond {
		t.Fatalf("Abstände wachsen nicht: %s %s %s", a, b, c)
	}
	mu.Lock()
	defer mu.Unlock()
	if len(*meldungen) != 2 || !strings.HasPrefix((*meldungen)[0], "WARN: System bus unavailable") || (*meldungen)[1] != "INFO: System bus connected" {
		t.Fatalf("erwartet genau eine Meldung zum Ausfall und eine zur Verbindung: %q", *meldungen)
	}
}

// Erstversuch: im Normalfall die Verbindung, bei einem stummen Bus nach der Zeitgrenze nil.
func TestErstversuch(t *testing.T) {
	t.Run("stumm", func(t *testing.T) {
		stummerBus(t, false)
		h, _, _ := testHalter(Verbinden)
		ctx, abbrechen := context.WithCancel(context.Background())
		defer abbrechen()
		h.Starten(ctx)
		beginn := time.Now()
		if conn := h.Erstversuch(ctx); conn != nil {
			t.Fatal("stummer Bus liefert eine Verbindung")
		}
		if dauer := time.Since(beginn); dauer > time.Second {
			t.Fatalf("Erstversuch wartet über die Zeitgrenze hinaus: %s", dauer)
		}
	})
	t.Run("echt", func(t *testing.T) {
		echterBus(t)
		h, _, _ := testHalter(Verbinden)
		h.Grenze = time.Second
		ctx, abbrechen := context.WithCancel(context.Background())
		defer abbrechen()
		h.Starten(ctx)
		if conn := h.Erstversuch(ctx); conn == nil || !conn.Connected() {
			t.Fatal("Erstversuch liefert am antwortenden Bus keine Verbindung")
		}
	})
}

func TestHalterOhneAusfallMeldetNichts(t *testing.T) {
	echterBus(t)
	h, meldungen, mu := testHalter(Verbinden)
	h.Grenze = time.Second
	ctx, abbrechen := context.WithCancel(context.Background())
	defer abbrechen()
	h.Starten(ctx)
	if _, err := h.Warten(ctx); err != nil {
		t.Fatal(err)
	}
	mu.Lock()
	defer mu.Unlock()
	if len(*meldungen) != 0 {
		t.Fatalf("ohne Ausfall keine Meldung: %q", *meldungen)
	}
}

func TestHalterStummerBus(t *testing.T) {
	stummerBus(t, true)
	h, meldungen, mu := testHalter(Verbinden)
	ctx, abbrechen := context.WithCancel(context.Background())
	h.Starten(ctx)

	warten, ende := context.WithTimeout(context.Background(), 500*time.Millisecond)
	defer ende()
	if _, err := h.Warten(warten); !errors.Is(err, ErrNichtVerfuegbar) {
		t.Fatalf("Warten an einem stummen Bus: %v", err)
	}
	select {
	case <-h.Bereit():
		t.Fatal("Halter meldet bereit an einem stummen Bus")
	default:
	}
	abbrechen()
	mu.Lock()
	defer mu.Unlock()
	if len(*meldungen) != 1 || !strings.Contains((*meldungen)[0], "retrying in background") {
		t.Fatalf("erwartet genau eine Meldung trotz mehrerer Versuche: %q", *meldungen)
	}
}
