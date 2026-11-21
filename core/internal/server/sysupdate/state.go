package sysupdate

import (
	"encoding/json"
	"github.com/alpe-shell/alpe/core/internal/brand"
	"os"
	"path/filepath"

	"github.com/alpe-shell/alpe/core/internal/log"
	"github.com/alpe-shell/alpe/core/internal/utils"
)

func cacheDir() string {
	return filepath.Join(utils.XDGCacheHome(), brand.DirName)
}

func writeFileAtomic(path string, data []byte) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

// Packages ride along so a restart doesn't show an empty list until the next daily check.
type persistedState struct {
	LastCheckUnix   int64     `json:"lastCheckUnix"`
	LastSuccessUnix int64     `json:"lastSuccessUnix"`
	Packages        []Package `json:"packages,omitempty"`
	// Survives shell restarts, not the reboot itself.
	RebootBootID   string   `json:"rebootBootId,omitempty"`
	RebootPackages []string `json:"rebootPackages,omitempty"`
}

func statePath() string {
	return filepath.Join(cacheDir(), "sysupdate.json")
}

func loadPersisted() persistedState {
	var s persistedState
	data, err := os.ReadFile(statePath())
	if err != nil {
		return s
	}
	if err := json.Unmarshal(data, &s); err != nil {
		return persistedState{}
	}
	return s
}

func savePersisted(s persistedState) {
	data, err := json.Marshal(s)
	if err != nil {
		return
	}
	if err := writeFileAtomic(statePath(), data); err != nil {
		log.Debugf("[sysupdate] persist state: %v", err)
	}
}
