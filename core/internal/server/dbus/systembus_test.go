package dbus

import (
	"context"
	"testing"
	"time"

	"github.com/alpe-shell/alpe/core/internal/systembus"
	"github.com/alpe-shell/alpe/core/internal/systembus/bustest"
	"github.com/godbus/dbus/v5"
)

// Die Brücke läuft bei einem stummen Systembus zuerst ohne ihn; er wird nachgereicht. Die
// geteilte Verbindung gehört dem Dienst und überlebt das Close der Brücke.
func TestSystembusNachgereicht(t *testing.T) {
	bustest.Echt(t)
	conn, err := systembus.Verbinden(context.Background(), 2*time.Second)
	if err != nil {
		t.Fatal(err)
	}
	defer conn.Close()

	m := &Manager{
		systemSignals:  make(chan *dbus.Signal, 256),
		sessionSignals: make(chan *dbus.Signal, 256),
	}
	go m.processSystemSignals()

	listNames := func() error {
		_, err := m.Call("system", "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "ListNames", nil)
		return err
	}
	if err := listNames(); err == nil {
		t.Fatal("Aufruf am Systembus vor dem Anbinden ohne Fehler")
	}
	m.SystembusAnbinden(nil)
	m.SystembusAnbinden(conn)
	m.SystembusAnbinden(conn)
	if err := listNames(); err != nil {
		t.Fatalf("Aufruf am Systembus nach dem Anbinden: %v", err)
	}

	m.Close()
	if !conn.Connected() {
		t.Fatal("Close der Brücke hat die geteilte Verbindung geschlossen")
	}
	m.SystembusAnbinden(conn) // nach Close ohne Wirkung
	if err := listNames(); err == nil {
		t.Fatal("Aufruf am Systembus nach Close ohne Fehler")
	}
}
