package main

import (
	"os"
	"path/filepath"
	"regexp"
)

// Alpe: Die Version der Oberfläche steht allein in Common/Brand.qml (Plan 0.5 Nr. 2).
var brandVersionRe = regexp.MustCompile(`(?m)^\s*readonly property string version:\s*"([^"]+)"`)

// brandVersion liest die Version aus <shellDir>/Common/Brand.qml, leer wenn nicht lesbar.
func brandVersion(shellDir string) string {
	data, err := os.ReadFile(filepath.Join(shellDir, "Common", "Brand.qml"))
	if err != nil {
		return ""
	}
	return parseBrandVersion(string(data))
}

func parseBrandVersion(qml string) string {
	if m := brandVersionRe.FindStringSubmatch(qml); m != nil {
		return m[1]
	}
	return ""
}
