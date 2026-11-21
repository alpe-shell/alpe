package plugins

import (
	"fmt"

	"github.com/alpe-shell/alpe/core/internal/plugins"
	"github.com/duxlabs-dev/dux-go/ipc"
)

// HandleListInstalled meldet die Plugins im Benutzer- und im Systemordner. Name, Version und
// Anforderungen liest die Oberfläche selbst aus plugin.json.
func HandleListInstalled(conn *ipc.ConnWriter, req ipc.Request) {
	manager, err := plugins.NewManager()
	if err != nil {
		conn.RespondError(req.ID, fmt.Sprintf("failed to create manager: %v", err))
		return
	}

	installedIDs, err := manager.ListInstalled()
	if err != nil {
		conn.RespondError(req.ID, fmt.Sprintf("failed to list installed plugins: %v", err))
		return
	}

	result := make([]PluginInfo, 0, len(installedIDs))
	for _, id := range installedIDs {
		result = append(result, PluginInfo{ID: id, Name: id})
	}
	conn.Respond(req.ID, result)
}
