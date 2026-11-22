package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/alpe-shell/alpe/core/internal/brand"
)

// LocateShellConfig sucht die Oberfläche (shell.qml) in den Quickshell-Ordnern unter dem Namen
// von Alpe. Die Ordner des Ursprungs gehören nicht dazu: Dort läge nicht Alpe.
func LocateShellConfig() (string, error) {
	var primaryPaths []string

	configHome, err := os.UserConfigDir()
	if err == nil && configHome != "" {
		primaryPaths = append(primaryPaths, filepath.Join(configHome, "quickshell", brand.ID))
	}

	// System data directories
	dataDirs := os.Getenv("XDG_DATA_DIRS")
	if dataDirs == "" {
		dataDirs = "/usr/local/share:/usr/share"
	}

	for dir := range strings.SplitSeq(dataDirs, ":") {
		if dir != "" {
			primaryPaths = append(primaryPaths, filepath.Join(dir, "quickshell", brand.ID))
		}
	}

	// System config directories (fallback)
	configDirs := os.Getenv("XDG_CONFIG_DIRS")
	if configDirs == "" {
		configDirs = "/etc/xdg"
	}

	for dir := range strings.SplitSeq(configDirs, ":") {
		if dir != "" {
			primaryPaths = append(primaryPaths, filepath.Join(dir, "quickshell", brand.ID))
		}
	}

	// Build search paths with secondary (monorepo) paths interleaved
	var searchPaths []string
	for _, path := range primaryPaths {
		searchPaths = append(searchPaths, path)
		searchPaths = append(searchPaths, filepath.Join(path, "quickshell"))
	}

	for _, path := range searchPaths {
		shellPath := filepath.Join(path, "shell.qml")
		if info, err := os.Stat(shellPath); err == nil && !info.IsDir() {
			return path, nil
		}
	}

	return "", fmt.Errorf("could not find the Alpe shell (shell.qml) in any valid config path")
}
