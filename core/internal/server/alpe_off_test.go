package server

import (
	"os"
	"path/filepath"
	"testing"
)

func TestReadAlpeOff(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "aus")
	content := "# Kommentar\nBluetooth\n  wellbeing  # Statistik\n\nclipboard\n"
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	set := readAlpeOff(path)
	for _, name := range []string{"bluetooth", "wellbeing", "clipboard"} {
		if !set[name] {
			t.Errorf("%s fehlt", name)
		}
	}
	if len(set) != 3 {
		t.Errorf("erwartet 3 Einträge, bekommen %v", set)
	}
	if len(readAlpeOff(filepath.Join(dir, "gibt-es-nicht"))) != 0 {
		t.Error("fehlende Datei muss leer sein")
	}
}
