package main

import (
	"os"
	"path/filepath"
	"runtime"
	"testing"
)

func TestParseBrandVersion(t *testing.T) {
	qml := "Singleton {\n    readonly property string name: \"Alpe\"\n    readonly property string version: \"1.1\"\n    readonly property string upstreamVersion: \"2.1.2\"\n}\n"
	if got := parseBrandVersion(qml); got != "1.1" {
		t.Fatalf("parseBrandVersion = %q, want 1.1", got)
	}
	if got := parseBrandVersion("kein QML"); got != "" {
		t.Fatalf("parseBrandVersion ohne Version = %q, want leer", got)
	}
}

// Die Oberfläche im Repository muss eine Version tragen, die der Dienst lesen kann.
func TestBrandVersionOfRepositoryShell(t *testing.T) {
	_, file, _, _ := runtime.Caller(0)
	shellDir := filepath.Join(filepath.Dir(file), "..", "..", "..", "shell")
	if _, err := os.Stat(filepath.Join(shellDir, "Common", "Brand.qml")); err != nil {
		t.Skip("shell/ nicht vorhanden")
	}
	if brandVersion(shellDir) == "" {
		t.Fatal("keine Version in shell/Common/Brand.qml gefunden")
	}
}
