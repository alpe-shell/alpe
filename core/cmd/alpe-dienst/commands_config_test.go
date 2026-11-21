package main

import (
	"os"
	"path/filepath"
	"testing"
)

func writeConfigFile(t *testing.T, path, content string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

func TestCheckHyprlandIncludeIgnoresLegacyConf(t *testing.T) {
	xdg := t.TempDir()
	t.Setenv("XDG_CONFIG_HOME", xdg)
	writeConfigFile(t, filepath.Join(xdg, "hypr", "hyprland.conf"), "source = ./dms/colors.conf\n")
	writeConfigFile(t, filepath.Join(xdg, "hypr", "dms", "colors.conf"), "")

	got, err := checkHyprlandInclude("colors.conf")
	if err != nil {
		t.Fatal(err)
	}
	if got.Included {
		t.Fatalf("got %+v; a hyprland.conf source must not count once Hyprland reads only Lua", got)
	}
}
