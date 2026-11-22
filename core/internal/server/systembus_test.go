package server

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/alpe-shell/alpe/core/internal/geolocation"
	"github.com/alpe-shell/alpe/core/internal/server/brightness"
	"github.com/alpe-shell/alpe/core/internal/server/drives"
	"github.com/alpe-shell/alpe/core/internal/server/loginctl"
	"github.com/alpe-shell/alpe/core/internal/systembus"
	"github.com/alpe-shell/alpe/core/internal/systembus/bustest"
)

// innerhalb bricht ab, wenn f länger als grenze braucht – so sieht ein Hänger am Bus aus.
func innerhalb(t *testing.T, grenze time.Duration, was string, f func()) {
	t.Helper()
	fertig := make(chan struct{})
	go func() {
		defer close(fertig)
		f()
	}()
	select {
	case <-fertig:
	case <-time.After(grenze):
		t.Fatalf("%s hängt an einem Systembus, der nicht antwortet", was)
	}
}

// Der Fall der Ladeprüfung: Der Systembus nimmt die Anmeldung an und antwortet nie auf Hello.
// Früher hing daran der ganze Start (dbus.SystemBus() hält eine paketweite Sperre). Jetzt gilt:
// Was die Verbindung braucht, bekommt sofort einen Fehler oder nil und kehrt zurück; nur wer
// ausdrücklich wartet (eigene Goroutine eines Managers), wartet.
func TestStummerSystembusHaeltDenDienstNichtAuf(t *testing.T) {
	bustest.Stumm(t, true)

	alt, altCtx := systemBus, systemBusCtx
	t.Cleanup(func() { systemBus, systemBusCtx = alt, altCtx })
	ctx, ende := context.WithCancel(context.Background())
	defer ende()
	systemBus = systembus.Neu()
	systemBus.Grenze = 150 * time.Millisecond
	systemBus.ErsterAbstand = 50 * time.Millisecond
	systemBus.HoechstAbstand = 100 * time.Millisecond
	systemBusCtx = ctx
	systemBus.Starten(ctx)

	innerhalb(t, time.Second, "systemBusJetzt", func() {
		if _, err := systemBusJetzt(); !errors.Is(err, systembus.ErrNichtVerfuegbar) {
			t.Errorf("systemBusJetzt: %v", err)
		}
	})
	innerhalb(t, 2*time.Second, "Erstversuch", func() {
		if conn := systemBus.Erstversuch(ctx); conn != nil {
			t.Error("Erstversuch liefert an einem stummen Bus eine Verbindung")
		}
	})

	// Anfragen der Oberfläche: sofort ein Fehler, kein Warten.
	innerhalb(t, time.Second, "drives.List", func() {
		if _, err := drives.List(systemBusJetzt); !errors.Is(err, systembus.ErrNichtVerfuegbar) {
			t.Errorf("drives.List: %v", err)
		}
	})

	// Manager ohne Verbindung: Fehler statt Hänger, und keiner baut selbst eine auf.
	innerhalb(t, time.Second, "Manager ohne Verbindung", func() {
		if _, err := loginctl.NewManager(nil, false, loginctl.LockPolicy{}); err == nil {
			t.Error("loginctl.NewManager(nil) ohne Fehler")
		}
		if err := InitializeFreedeskManager(nil); err == nil {
			t.Error("InitializeFreedeskManager(nil) ohne Fehler")
		}
		if err := InitializeBluezManager(nil); err == nil {
			t.Error("InitializeBluezManager(nil) ohne Fehler")
		}
		if _, err := brightness.NewLogindBackend(nil); err == nil {
			t.Error("brightness.NewLogindBackend(nil) ohne Fehler")
		}
		if client := geolocation.NewClient(nil); client == nil {
			t.Error("Ortung ohne Systembus muss auf die IP-Adresse ausweichen")
		}
	})
	if loginctlManager != nil || freedesktopManager != nil || bluezManager != nil {
		t.Fatal("ohne Systembus darf kein Manager am Bus eingerichtet sein")
	}
	for _, faehigkeit := range getCapabilities().Capabilities {
		switch faehigkeit {
		case "loginctl", "freedesktop", "bluetooth", "network":
			t.Fatalf("Fähigkeit %q trotz stummem Systembus", faehigkeit)
		}
	}

	// Wer wartet, wartet – bis sein Context endet, nicht ewig und ohne andere zu blockieren.
	kurz, kurzEnde := context.WithTimeout(ctx, 200*time.Millisecond)
	defer kurzEnde()
	innerhalb(t, 2*time.Second, "Warten mit Context", func() {
		if _, err := systemBus.Warten(kurz); !errors.Is(err, systembus.ErrNichtVerfuegbar) {
			t.Errorf("Warten: %v", err)
		}
	})
}
