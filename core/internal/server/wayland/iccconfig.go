package wayland

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/alpe-shell/alpe/core/internal/brand"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	"github.com/alpe-shell/alpe/core/internal/log"
	"github.com/alpe-shell/alpe/core/internal/utils"
)

type iccConfig struct {
	ICCProfiles      map[string]string `json:"iccProfiles,omitempty"`
	OutputTemps      map[string]int    `json:"outputTemps,omitempty"`
	OutputBrightness map[string]int    `json:"outputBrightness,omitempty"`
}

func dmsConfigDir() string {
	return filepath.Join(utils.XDGConfigHome(), brand.DirName)
}

func iccConfigPath() string {
	return filepath.Join(dmsConfigDir(), "icc.json")
}

func ICCProfilesDir() string {
	return filepath.Join(dmsConfigDir(), "icc")
}

func resolveICCProfile(name string) string {
	if filepath.IsAbs(name) {
		return name
	}
	return filepath.Join(ICCProfilesDir(), name)
}

// Only the ICC fields persist, the shell pushes the night light state.
func LoadConfig() Config {

	cfg := DefaultConfig()
	data, err := os.ReadFile(iccConfigPath())
	if err != nil {
		return cfg
	}
	var stored iccConfig
	if err := json.Unmarshal(data, &stored); err != nil {
		log.Warnf("icc: ignoring %s: %v", iccConfigPath(), err)
		return cfg
	}
	cfg.ICCProfiles = stored.ICCProfiles
	cfg.OutputTemps = stored.OutputTemps
	cfg.OutputBrightness = stored.OutputBrightness
	return cfg
}

func SaveICCConfig(cfg Config) error {
	path := iccConfigPath()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	data, err := json.MarshalIndent(iccConfig{ICCProfiles: cfg.ICCProfiles, OutputTemps: cfg.OutputTemps, OutputBrightness: cfg.OutputBrightness}, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, data, 0o644)
}

func stageICCProfile(dir, src string) (string, error) {
	if filepath.Dir(filepath.Clean(src)) == filepath.Clean(dir) {
		return filepath.Base(src), nil
	}
	data, err := os.ReadFile(src)
	if err != nil {
		return "", err
	}
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return "", err
	}

	base := filepath.Base(src)
	ext := filepath.Ext(base)
	stem := strings.TrimSuffix(base, ext)
	for n := 0; ; n++ {
		name := base
		if n > 0 {
			name = fmt.Sprintf("%s-%d%s", stem, n, ext)
		}
		dest := filepath.Join(dir, name)
		existing, err := os.ReadFile(dest)
		switch {
		case errors.Is(err, fs.ErrNotExist):
			if err := os.WriteFile(dest, data, 0o644); err != nil {
				return "", err
			}
			return name, nil
		case err != nil:
			return "", err
		case bytes.Equal(existing, data):
			return name, nil
		}
	}
}

