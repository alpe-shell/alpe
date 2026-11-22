package brightness

import (
	"fmt"

	"github.com/alpe-shell/alpe/core/internal/log"
	"github.com/godbus/dbus/v5"
)

type DBusConn interface {
	Object(dest string, path dbus.ObjectPath) dbus.BusObject
}

type LogindBackend struct {
	conn DBusConn
}

// NewLogindBackend arbeitet auf conn (im Dienst die geteilte Systembus-Verbindung); conn wird hier
// nie geschlossen.
func NewLogindBackend(conn *dbus.Conn) (*LogindBackend, error) {
	if conn == nil {
		return nil, fmt.Errorf("connect to system bus: not connected")
	}

	obj := conn.Object("org.freedesktop.login1", "/org/freedesktop/login1/session/auto")
	call := obj.Call("org.freedesktop.DBus.Peer.Ping", 0)
	if call.Err != nil {
		return nil, fmt.Errorf("logind not available: %w", call.Err)
	}

	return &LogindBackend{conn: conn}, nil
}

func NewLogindBackendWithConn(conn DBusConn) *LogindBackend {
	return &LogindBackend{
		conn: conn,
	}
}

func (b *LogindBackend) SetBrightness(subsystem, name string, brightness uint32) error {
	if b.conn == nil {
		return fmt.Errorf("connect to system bus: not connected")
	}

	obj := b.conn.Object("org.freedesktop.login1", "/org/freedesktop/login1/session/auto")
	call := obj.Call("org.freedesktop.login1.Session.SetBrightness", 0, subsystem, name, brightness)
	if call.Err != nil {
		return fmt.Errorf("dbus call failed: %w", call.Err)
	}

	log.Debugf("logind: set %s/%s to %d", subsystem, name, brightness)
	return nil
}

func (b *LogindBackend) Close() {}
