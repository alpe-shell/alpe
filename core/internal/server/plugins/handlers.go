package plugins

import (
	"fmt"

	"github.com/duxlabs-dev/dux-go/ipc"
)

// Alpe: Ohne Plugin-Register (Plan 0.4 Nr. 5) bleiben nur die lokalen Vorgänge.
func HandleRequest(conn *ipc.ConnWriter, req ipc.Request) {
	switch req.Method {
	case "plugins.listInstalled":
		HandleListInstalled(conn, req)
	case "plugins.uninstall":
		HandleUninstall(conn, req)
	default:
		conn.RespondError(req.ID, fmt.Sprintf("unknown method: %s", req.Method))
	}
}
