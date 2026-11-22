package config

import (
	"fmt"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/alpe-shell/alpe/core/internal/utils"
)

const (
	hyprlandStartupBegin = "-- ALPE_STARTUP_BEGIN"
	hyprlandStartupEnd   = "-- ALPE_STARTUP_END"

	// Marken bis Alpe 1.0: Sie werden gelesen, geschrieben werden nur die neuen. Fällt weg,
	// sobald der Umzug von 1.0 nicht mehr unterstützt wird.
	legacyHyprlandStartupBegin = "-- DMS_STARTUP_BEGIN"
	legacyHyprlandStartupEnd   = "-- DMS_STARTUP_END"
)

// startupBlock findet den Startblock zwischen den Marken; end zeigt hinter die Endmarke.
func startupBlock(config string) (start, end int, ok bool) {
	for _, marks := range [][2]string{
		{hyprlandStartupBegin, hyprlandStartupEnd},
		{legacyHyprlandStartupBegin, legacyHyprlandStartupEnd},
	} {
		start = strings.Index(config, marks[0])
		endMark := strings.Index(config, marks[1])
		if start != -1 && endMark > start {
			return start, endMark + len(marks[1]), true
		}
	}
	return 0, 0, false
}

func transformHyprlandLuaForNonSystemd(config, terminalCommand string) string {
	start, endClose, ok := startupBlock(config)
	if !ok {
		return config
	}
	replacement := hyprlandStartupBegin + "\n" +
		`hl.env("QT_QPA_PLATFORM", "wayland;xcb")` + "\n" +
		`hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")` + "\n" +
		`hl.env("QT_QPA_PLATFORMTHEME", "gtk3")` + "\n" +
		`hl.env("QT_QPA_PLATFORMTHEME_QT6", "gtk3")` + "\n" +
		fmt.Sprintf(`hl.env("TERMINAL", %s)`, strconv.Quote(terminalCommand)) + "\n\n" +
		`hl.on("hyprland.start", function()` + "\n" +
		`	hl.exec_cmd("alpe-dienst run")` + "\n" +
		`end)` + "\n" +
		hyprlandStartupEnd
	return config[:start] + replacement + config[endClose:]
}

func HyprlandConfigDir() string {
	return filepath.Join(utils.XDGConfigHome(), "hypr")
}
