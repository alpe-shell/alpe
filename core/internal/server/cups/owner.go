package cups

import (
	"os/user"
)

// Besitzername der Abonnements bei cupsd (requesting-user-name). Bis Alpe 1.0 stand hier fest
// «dms»; jetzt ist es der Benutzer des laufenden Prozesses, mit Rückfall «alpe» (Plan 0.8 Nr. 22).
const fallbackUserName = "alpe"

// lookupUserName ist für Tests austauschbar.
var lookupUserName = func() (string, error) {
	u, err := user.Current()
	if err != nil {
		return "", err
	}
	return u.Username, nil
}

func requestingUserName() string {
	name, err := lookupUserName()
	if err != nil || name == "" {
		return fallbackUserName
	}
	return name
}

// notifyEvents: Ereignisse, die der Dienst abonniert (Abfrageweg und D-Bus gleich).
func notifyEvents() []string {
	return []string{
		"printer-state-changed",
		"printer-added",
		"printer-deleted",
		"job-created",
		"job-completed",
		"job-state-changed",
	}
}
