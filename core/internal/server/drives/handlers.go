package drives

import (
	"fmt"

	"github.com/duxlabs-dev/dux-go/ipc"
	"github.com/godbus/dbus/v5"
)

func HandleRequest(conn *ipc.ConnWriter, req ipc.Request, systembus func() (*dbus.Conn, error)) {
	switch req.Method {
	case "drives.list":
		res, err := List(systembus)
		if err != nil {
			conn.RespondError(req.ID, err.Error())
			return
		}
		conn.Respond(req.ID, res)
	default:
		conn.RespondError(req.ID, fmt.Sprintf("unknown method: %s", req.Method))
	}
}
