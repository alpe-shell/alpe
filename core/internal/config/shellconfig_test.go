package config

import (
	"os"
	"path/filepath"
	"testing"
)

// Plan 6.1, E1: doctor und die Version finden die Oberfläche im installierten Baum <Datenordner>/alpe/shell
// (Paket: /usr/share/alpe/shell); eine eigene Oberfläche unter ~/.config/quickshell/alpe geht vor.
func TestLocateShellConfigFindsInstalledTree(t *testing.T) {
	root := t.TempDir()
	home := filepath.Join(root, "home")
	share := filepath.Join(root, "usr", "share")
	t.Setenv("HOME", home)
	t.Setenv("XDG_CONFIG_HOME", filepath.Join(home, ".config"))
	t.Setenv("XDG_DATA_HOME", filepath.Join(home, ".local", "share"))
	t.Setenv("XDG_DATA_DIRS", share)
	t.Setenv("XDG_CONFIG_DIRS", filepath.Join(root, "etc", "xdg"))

	shell := func(dir string) string {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(dir, "shell.qml"), []byte("// Probe\n"), 0o644); err != nil {
			t.Fatal(err)
		}
		return dir
	}

	if _, err := LocateShellConfig(); err == nil {
		t.Fatal("expected an error without any shell.qml")
	}

	paket := shell(filepath.Join(share, "alpe", "shell"))
	if got, err := LocateShellConfig(); err != nil || got != paket {
		t.Fatalf("package tree: got %q, %v; want %q", got, err, paket)
	}

	// Ein alter Quickshell-Ordner im selben Datenordner ändert nichts: der installierte Baum geht vor.
	shell(filepath.Join(share, "quickshell", "alpe"))
	if got, _ := LocateShellConfig(); got != paket {
		t.Fatalf("installed tree must come before <data>/quickshell/alpe: got %q", got)
	}

	// Weg ohne Paket (PREFIX=$HOME/.local) vor dem Paket.
	lokal := shell(filepath.Join(home, ".local", "share", "alpe", "shell"))
	if got, _ := LocateShellConfig(); got != lokal {
		t.Fatalf("user data tree must come before the package tree: got %q, want %q", got, lokal)
	}

	// Eine eigene Oberfläche unter ~/.config/quickshell/alpe geht allem vor.
	eigen := shell(filepath.Join(home, ".config", "quickshell", "alpe"))
	if got, _ := LocateShellConfig(); got != eigen {
		t.Fatalf("own shell under the config dir must come first: got %q, want %q", got, eigen)
	}
}
