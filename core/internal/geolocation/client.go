package geolocation

import (
	"github.com/alpe-shell/alpe/core/internal/log"
	"github.com/godbus/dbus/v5"
)

// NewClient nimmt GeoClue über sysConn (die geteilte Systembus-Verbindung des Dienstes, wird hier
// nie geschlossen); ohne Verbindung oder ohne GeoClue bleibt die Ortung über die IP-Adresse.
func NewClient(sysConn *dbus.Conn) Client {
	if sysConn == nil {
		// Die eine Meldung zum fehlenden Systembus kommt vom Dienst.
		return newIpClient()
	}
	geoclueClient, err := newGeoClueClient(sysConn)
	if err != nil {
		log.Warnf("GeoClue2 unavailable: %v", err)
		return newIpClient()
	}
	return geoclueClient
}
