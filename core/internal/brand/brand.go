// Package brand hält die Namen, unter denen Alpe nach aussen auftritt, an einer Stelle
// (Plan 2.2, D1). Pfade folgen in D2, App-ID und D-Bus-Namen in D3.
package brand

const (
	// ID benennt Laufzeitdateien: Socket $XDG_RUNTIME_DIR/alpe-<pid>.sock, alpe.path,
	// alpe-shell/ (ausgepackte Oberfläche), Sperrdateien.
	ID = "alpe"
	// Binary ist der Programmname des Dienstes (/usr/bin/alpe-dienst).
	Binary = "alpe-dienst"
	// EnvPrefix steht vor allen Umgebungsvariablen des Dienstes und der Oberfläche
	// (ALPE_SOCKET, ALPE_SHELL_DIR, ALPE_EXECUTABLE, ALPE_POLICY_* …).
	EnvPrefix = "ALPE"
	// Unit ist die systemd-Benutzereinheit; der Dienst startet sie nie selbst (Plan 6.8).
	Unit = "alpe.service"
)

// Env gibt den Namen der Umgebungsvariable mit dem Alpe-Präfix zurück, z. B. Env("SOCKET").
func Env(name string) string { return EnvPrefix + "_" + name }
