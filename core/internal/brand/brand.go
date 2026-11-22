// Package brand hält die Namen, unter denen Alpe nach aussen auftritt, an einer Stelle
// (Plan 2.2, D1–D3).
package brand

import "strings"

const (
	// ID benennt Laufzeitdateien: Socket $XDG_RUNTIME_DIR/alpe-<pid>.sock, alpe.path,
	// alpe-shell/ (ausgepackte Oberfläche), Sperrdateien.
	ID = "alpe"
	// Binary ist der Programmname des Dienstes (/usr/bin/alpe-dienst).
	Binary = "alpe-dienst"
	// EnvPrefix steht vor allen Umgebungsvariablen des Dienstes und der Oberfläche
	// (ALPE_SOCKET, ALPE_SHELL_DIR, ALPE_EXECUTABLE, ALPE_POLICY_* …).
	EnvPrefix = "ALPE"
	// DirName ist der Ordner unter ~/.config, ~/.local/state, ~/.cache (Plan 2.2, D2).
	DirName = "alpe"
	// SystemPluginDir enthält die mit dem Paket ausgelieferten Plugins (Plan 6.1).
	SystemPluginDir = "/usr/share/alpe/plugins"
	// AppID ist App-ID, Name der Desktop-Datei und Wayland-app_id der Shell (Plan 0.4 Nr. 2, D3);
	// davon abgeleitet die D-Bus-Namen.
	AppID = "io.github.alpe_shell.Alpe"
	// NMAgentID meldet den Dienst bei NetworkManager als Geheimnis-Agent an.
	NMAgentID = AppID + ".NMAgent"
	// Unit ist die systemd-Benutzereinheit; der Dienst startet sie nie selbst (Plan 6.8).
	Unit = "alpe.service"
)

// URL ist das öffentliche Repository (wie Brand.url in shell/Common/Brand.qml).
const URL = "https://github.com/alpe-shell/alpe"

// Version ist die Version von Alpe aus shell/Common/Brand.qml (Brand.version). Das Makefile setzt
// sie beim Bau (-X …/internal/brand.Version=…, dieselbe Quelle wie main.Version); ein Bau ohne
// Makefile trägt «dev».
var Version = "dev"

// UserAgent ist die Kennung für alle eigenen Abrufe des Dienstes im Netz, in der Form
// «Alpe/1.1.0 (+https://github.com/alpe-shell/alpe)» (Plan 0.8 Nr. 67). Die Nummer wird auf drei
// Stellen ergänzt («1.1» → «1.1.0»); alles, was keine Versionsnummer ist, steht unverändert da
// («Alpe/dev»).
func UserAgent() string {
	return "Alpe/" + threePartVersion(Version) + " (+" + URL + ")"
}

func threePartVersion(version string) string {
	version = strings.TrimPrefix(strings.TrimSpace(version), "v")
	if version == "" {
		return "dev"
	}
	parts := strings.Split(version, ".")
	for _, part := range parts {
		if part == "" || strings.Trim(part, "0123456789") != "" {
			return version
		}
	}
	for len(parts) < 3 {
		parts = append(parts, "0")
	}
	return strings.Join(parts, ".")
}

// Env gibt den Namen der Umgebungsvariable mit dem Alpe-Präfix zurück, z. B. Env("SOCKET").
func Env(name string) string { return EnvPrefix + "_" + name }
