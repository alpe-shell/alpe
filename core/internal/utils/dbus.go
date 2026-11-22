package utils

import (
	"context"
	"slices"

	"github.com/alpe-shell/alpe/core/internal/systembus"
)

// Kurzlebige Abfragen (doctor): eigene Verbindung mit Zeitgrenze, danach geschlossen.

func IsDBusServiceAvailable(busName string) bool {
	conn, err := systembus.Verbinden(context.Background(), systembus.AufbauGrenze)
	if err != nil {
		return false
	}
	defer conn.Close()

	obj := conn.Object("org.freedesktop.DBus", "/org/freedesktop/DBus")
	var owned bool
	if err := obj.Call("org.freedesktop.DBus.NameHasOwner", 0, busName).Store(&owned); err != nil {
		return false
	}
	return owned
}

func IsDBusServiceActivatable(busName string) bool {
	conn, err := systembus.Verbinden(context.Background(), systembus.AufbauGrenze)
	if err != nil {
		return false
	}
	defer conn.Close()

	obj := conn.Object("org.freedesktop.DBus", "/org/freedesktop/DBus")
	var activatable []string
	if err := obj.Call("org.freedesktop.DBus.ListActivatableNames", 0).Store(&activatable); err != nil {
		return false
	}
	return slices.Contains(activatable, busName)
}
