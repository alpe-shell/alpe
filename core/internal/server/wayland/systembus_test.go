package wayland

import (
	"context"
	"sync"
	"testing"
	"time"

	"github.com/alpe-shell/alpe/core/internal/systembus"
	"github.com/alpe-shell/alpe/core/internal/systembus/bustest"
	"github.com/godbus/dbus/v5"
)

func verbinde(t *testing.T) *dbus.Conn {
	t.Helper()
	conn, err := systembus.Verbinden(context.Background(), 2*time.Second)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { conn.Close() })
	return conn
}

// Die Überwachung des Ruhezustands kommt nach dem Start dazu: Signale erreichen den Manager
// erst nach SystembusAnbinden, und nach dem Abbinden bleibt die geteilte Verbindung offen.
func TestSystembusAnbinden(t *testing.T) {
	bustest.Echt(t)
	conn := verbinde(t)
	sender := verbinde(t)

	m := &Manager{dbusSignal: make(chan *dbus.Signal, 16)}
	if err := m.SystembusAnbinden(nil); err == nil {
		t.Fatal("ohne Verbindung muss SystembusAnbinden einen Fehler melden")
	}
	if err := m.SystembusAnbinden(conn); err != nil {
		t.Fatal(err)
	}
	if err := m.SystembusAnbinden(conn); err != nil {
		t.Fatalf("zweites Anbinden: %v", err)
	}

	if err := sender.Emit("/org/freedesktop/login1", "org.freedesktop.login1.Manager.PrepareForSleep", true); err != nil {
		t.Fatal(err)
	}
	select {
	case sig := <-m.dbusSignal:
		if sig.Name != "org.freedesktop.login1.Manager.PrepareForSleep" {
			t.Fatalf("unerwartetes Signal: %s", sig.Name)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("PrepareForSleep kommt nach dem Anbinden nicht an")
	}

	m.systembusAbbinden()
	if !conn.Connected() {
		t.Fatal("Abbinden hat die geteilte Verbindung geschlossen")
	}
	if err := sender.Emit("/org/freedesktop/login1", "org.freedesktop.login1.Manager.PrepareForSleep", false); err != nil {
		t.Fatal(err)
	}
	select {
	case sig := <-m.dbusSignal:
		t.Fatalf("Signal nach dem Abbinden: %v", sig)
	case <-time.After(200 * time.Millisecond):
	}
}

// Anbinden und Schliessen dürfen sich überholen, ohne Hänger und ohne Wettlauf (go test -race);
// nach dem Schliessen bleibt ein Anbinden ohne Wirkung.
func TestSystembusAnbindenUndSchliessenGleichzeitig(t *testing.T) {
	bustest.Echt(t)
	conn := verbinde(t)

	for range 20 {
		m := &Manager{dbusSignal: make(chan *dbus.Signal, 16)}
		var wg sync.WaitGroup
		wg.Add(2)
		go func() {
			defer wg.Done()
			m.SystembusAnbinden(conn)
		}()
		go func() {
			defer wg.Done()
			m.systembusAbbinden()
		}()
		fertig := make(chan struct{})
		go func() {
			wg.Wait()
			close(fertig)
		}()
		select {
		case <-fertig:
		case <-time.After(3 * time.Second):
			t.Fatal("Anbinden und Schliessen blockieren sich")
		}

		m.systembusAbbinden()
		if err := m.SystembusAnbinden(conn); err != nil {
			t.Fatal(err)
		}
		m.dbusMu.Lock()
		angebunden := m.dbusConn != nil
		m.dbusMu.Unlock()
		if angebunden {
			t.Fatal("Anbinden nach dem Schliessen darf nichts mehr setzen")
		}
	}
}

// Ein Systembus, der nie antwortet, hält das Anbinden nicht auf: Es findet gar nicht statt, weil
// der Dienst die Verbindung nie bekommt.
func TestStummerSystembusLiefertKeineVerbindung(t *testing.T) {
	bustest.Stumm(t, true)
	h := systembus.Neu()
	h.Grenze = 150 * time.Millisecond
	ctx, ende := context.WithCancel(context.Background())
	defer ende()
	h.Starten(ctx)
	beginn := time.Now()
	if conn := h.Erstversuch(ctx); conn != nil {
		t.Fatal("stummer Bus liefert eine Verbindung")
	}
	if time.Since(beginn) > 2*time.Second {
		t.Fatal("Erstversuch wartet länger als die Zeitgrenze")
	}
}
