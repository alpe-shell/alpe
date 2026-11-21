package plugins

import (
	"fmt"

	"github.com/alpe-shell/alpe/core/internal/plugins"
	"github.com/duxlabs-dev/dux-go/ipc"
)

func HandleUninstall(conn *ipc.ConnWriter, req ipc.Request) {
	name, ok := req.Get[string]("name")
	if !ok {
		conn.RespondError(req.ID, "missing or invalid 'name' parameter")
		return
	}

	manager, err := plugins.NewManager()
	if err != nil {
		conn.RespondError(req.ID, fmt.Sprintf("failed to create manager: %v", err))
		return
	}

	if err := manager.UninstallByIDOrName(name); err != nil {
		conn.RespondError(req.ID, fmt.Sprintf("failed to uninstall plugin: %v", err))
		return
	}

	conn.Respond(req.ID, SuccessResult{
		Success: true,
		Message: fmt.Sprintf("plugin uninstalled: %s", name),
	})
}
