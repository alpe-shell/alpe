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
//
// Reihenfolge (Plan 6.1, E1): (1) eine eigene Oberfläche unter <XDG_CONFIG_HOME>/quickshell/alpe (Entwicklung);
// (2) der installierte Baum <Datenordner>/alpe/shell – das Paket legt ihn nach /usr/share/alpe/shell, der Weg ohne
// Paket (make install PREFIX=$HOME/.local, 6.4) nach <XDG_DATA_HOME>/alpe/shell; (3) wie bisher
// <Datenordner>/quickshell/alpe und <XDG_CONFIG_DIRS>/quickshell/alpe.
func LocateShellConfig() (string, error) {
	var userPaths, installedPaths, primaryPaths []string

	configHome, err := os.UserConfigDir()
	if err == nil && configHome != "" {
		userPaths = append(userPaths, filepath.Join(configHome, "quickshell", brand.ID))
	}

	// System data directories
	dataDirs := os.Getenv("XDG_DATA_DIRS")
	if dataDirs == "" {
		dataDirs = "/usr/local/share:/usr/share"
	}

	dataHome := os.Getenv("XDG_DATA_HOME")
	if dataHome == "" {
		if home, err := os.UserHomeDir(); err == nil && home != "" {
			dataHome = filepath.Join(home, ".local", "share")
		}
	}
	if dataHome != "" {
		installedPaths = append(installedPaths, filepath.Join(dataHome, brand.DirName, "shell"))
	}

	for dir := range strings.SplitSeq(dataDirs, ":") {
		if dir != "" {
			installedPaths = append(installedPaths, filepath.Join(dir, brand.DirName, "shell"))
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

	// Build search paths with secondary (monorepo) paths interleaved; der installierte Baum hat keinen solchen
	// Unterordner und steht zwischen der eigenen Oberfläche und den übrigen Quickshell-Ordnern.
	var searchPaths []string
	for _, path := range userPaths {
		searchPaths = append(searchPaths, path, filepath.Join(path, "quickshell"))
	}
	searchPaths = append(searchPaths, installedPaths...)
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
