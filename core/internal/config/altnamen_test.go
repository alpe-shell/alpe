package config

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Namen aus Alpe 1.0 in den Hyprland-Dateien (Plan 2.3.5 D7.7e, 0.8 Nr. 57).

func TestStartupBlockReadsLegacyMarkers(t *testing.T) {
	legacy := "-- kopf\n-- DMS_STARTUP_BEGIN\nhl.exec_cmd(\"alt\")\n-- DMS_STARTUP_END\n-- fuss\n"

	out := transformHyprlandLuaForNonSystemd(legacy, "kitty")

	assert.Contains(t, out, "-- ALPE_STARTUP_BEGIN\n")
	assert.Contains(t, out, "-- ALPE_STARTUP_END\n-- fuss\n")
	assert.NotContains(t, out, "DMS_STARTUP", "geschrieben werden nur die neuen Marken")
	assert.NotContains(t, out, `hl.exec_cmd("alt")`)
	assert.Contains(t, out, `hl.exec_cmd("alpe-dienst run")`)
	assert.True(t, strings.HasPrefix(out, "-- kopf\n"))
}

func TestStartupBlockPrefersCurrentMarkers(t *testing.T) {
	both := "-- DMS_STARTUP_BEGIN\nalt\n-- DMS_STARTUP_END\n-- ALPE_STARTUP_BEGIN\nneu\n-- ALPE_STARTUP_END\n"

	out := transformHyprlandLuaForNonSystemd(both, "kitty")

	assert.Contains(t, out, "-- DMS_STARTUP_BEGIN\nalt\n-- DMS_STARTUP_END\n", "der alte Block bleibt, wie er ist")
	assert.NotContains(t, out, "\nneu\n")
}

func TestStartupBlockWithoutMarkersIsUntouched(t *testing.T) {
	plain := "hl.config({})\n"
	assert.Equal(t, plain, transformHyprlandLuaForNonSystemd(plain, "kitty"))
}

func TestEmbeddedHyprlandConfigUsesCurrentNames(t *testing.T) {
	assert.Contains(t, HyprlandLuaConfig, hyprlandStartupBegin)
	assert.Contains(t, HyprlandLuaConfig, hyprlandStartupEnd)
	assert.Contains(t, HyprlandLuaConfig, `namespace = "^alpe:.*"`, "Layer-Namensraum der Shell (D7.7a2)")
	assert.Contains(t, BindsLuaConfig, `hl.dsp.event("alpe:geometry")`, "die Shell hört auf alpe:geometry")
	for name, content := range map[string]string{"hyprland.lua": HyprlandLuaConfig, "binds.lua": BindsLuaConfig, "binds-user.lua": BindsUserLuaConfig} {
		assert.NotContains(t, content, "dms ", name)
		assert.NotContains(t, content, "DMS", name)
	}
}

// Sicherungen aus 1.0 bleiben unverändert: Neue Sicherungen kommen nach .alpe-backups, der
// Ordner .dms-backups wird weder umbenannt noch beschrieben.
func TestLegacyBackupDirStaysUntouched(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	t.Setenv("XDG_CONFIG_HOME", filepath.Join(home, ".config"))
	stubAddWants(t, nil)

	hyprDir := filepath.Join(home, ".config", "hypr")
	legacyFile := filepath.Join(hyprDir, ".dms-backups", "2026-03-01_12-00-00", "hyprland.lua")
	legacyContent := "-- Sicherung aus 1.0\nhl.bind(\"SUPER + Y\", hl.dsp.exec_cmd(\"dms ipc call dankdash wallpaper\"))\n"
	require.NoError(t, os.MkdirAll(filepath.Dir(legacyFile), 0o755))
	require.NoError(t, os.WriteFile(legacyFile, []byte(legacyContent), 0o644))
	require.NoError(t, os.WriteFile(filepath.Join(hyprDir, "hyprland.lua"), []byte("hl.config({ eigen = true })\n"), 0o644))
	before, err := os.Stat(legacyFile)
	require.NoError(t, err)

	result, err := NewConfigDeployer(nil).deployHyprlandConfig("kitty", true)
	require.NoError(t, err)

	assert.Contains(t, result.BackupPath, filepath.Join(hyprDir, ".alpe-backups"))
	assert.FileExists(t, result.BackupPath)
	content, err := os.ReadFile(legacyFile)
	require.NoError(t, err)
	assert.Equal(t, legacyContent, string(content))
	after, err := os.Stat(legacyFile)
	require.NoError(t, err)
	assert.Equal(t, before.ModTime(), after.ModTime())
	entries, err := os.ReadDir(filepath.Join(hyprDir, ".dms-backups"))
	require.NoError(t, err)
	assert.Len(t, entries, 1, "in den alten Ordner kommt nichts dazu")
}
