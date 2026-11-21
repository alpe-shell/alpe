package clipboard

import (
	"github.com/alpe-shell/alpe/core/internal/brand"
	"os"
	"path/filepath"
)

func GetDBPath() (string, error) {
	cacheDir, err := os.UserCacheDir()
	if err != nil {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return "", err
		}
		cacheDir = filepath.Join(homeDir, ".cache")
	}

	// Den Verlauf aus ~/.cache/dms/clipboard holt «alpe umzug» (Plan 7.2); hier wird nichts verschoben.
	newDir := filepath.Join(cacheDir, brand.DirName, "clipboard")
	newPath := filepath.Join(newDir, "db")

	if err := os.MkdirAll(newDir, 0o700); err != nil {
		return "", err
	}
	return newPath, nil
}
