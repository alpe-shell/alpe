// Package version vergleicht Versionsnummern (doctor, Hyprland-Vorlagen). Die
// Aktualisierungsprüfung des Ursprungs, die hier lag, hatte keinen Aufrufer und ist entfernt
// (Plan 0.8 Nr. 65).
package version

import (
	"fmt"
	"strings"
)

func CompareVersions(v1, v2 string) int {
	v1 = strings.TrimPrefix(v1, "v")
	v2 = strings.TrimPrefix(v2, "v")

	parts1 := strings.Split(v1, ".")
	parts2 := strings.Split(v2, ".")

	maxLen := max(len(parts2), len(parts1))

	for i := range maxLen {
		var p1, p2 int
		if i < len(parts1) {
			fmt.Sscanf(parts1[i], "%d", &p1) //nolint:errcheck
		}
		if i < len(parts2) {
			fmt.Sscanf(parts2[i], "%d", &p2) //nolint:errcheck
		}

		if p1 < p2 {
			return -1
		}
		if p1 > p2 {
			return 1
		}
	}

	return 0
}
