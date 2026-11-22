package providers

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/alpe-shell/alpe/core/internal/windowrules"
)

func findRulesFile(t *testing.T, dir string) string {
	t.Helper()
	found := ""
	_ = filepath.WalkDir(dir, func(path string, d os.DirEntry, err error) error {
		if err != nil || d.IsDir() {
			return nil
		}
		if data, readErr := os.ReadFile(path); readErr == nil && strings.Contains(string(data), "-RULE: id=") {
			found = path
		}
		return nil
	})
	if found == "" {
		t.Fatal("keine Regeldatei mit Marke gefunden")
	}
	return found
}

// Eine windowrules.lua aus 1.0 trägt "-- DMS-RULE:" und die alten IDs der eigenen Regeln. Beides
// wird gelesen; das nächste Schreiben setzt die neue Marke und die neuen IDs, ohne Doppel.
func TestRulesFromOldVersionAreReadAndRewritten(t *testing.T) {
	tmpDir := hyprLuaDir(t)
	provider := NewHyprlandWritableProvider(tmpDir)

	floating := newTestWindowRule("alpe-floating-windows", "Schwebende Fenster", "^(app1)$")
	floating.Actions.OpenFloating = new(true)
	own := newTestWindowRule("meine-regel", "Eigene", "^(app2)$")
	own.Actions.OpenFloating = new(true)
	if err := provider.SetRule(floating); err != nil {
		t.Fatalf("SetRule: %v", err)
	}
	if err := provider.SetRule(own); err != nil {
		t.Fatalf("SetRule: %v", err)
	}

	file := findRulesFile(t, tmpDir)
	data, err := os.ReadFile(file)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(data), "-- ALPE-RULE: id=alpe-floating-windows,") {
		t.Fatalf("neue Marke fehlt:\n%s", data)
	}

	// so sah die Datei unter 1.0 aus
	old := strings.ReplaceAll(string(data), "-- ALPE-RULE:", "-- DMS-RULE:")
	old = strings.ReplaceAll(old, "id=alpe-floating-windows,", "id=dms-floating-windows,")
	if err := os.WriteFile(file, []byte(old), 0o644); err != nil {
		t.Fatal(err)
	}

	rules, err := provider.LoadDMSRules()
	if err != nil {
		t.Fatalf("Laden: %v", err)
	}
	if len(rules) != 2 || rules[0].ID != "alpe-floating-windows" || rules[1].ID != "meine-regel" {
		t.Fatalf("alte Datei falsch gelesen: %+v", rules)
	}

	// die Shell setzt ihre Regel neu: kein zweiter Eintrag, neue Marke überall
	if err := provider.SetRule(floating); err != nil {
		t.Fatalf("SetRule: %v", err)
	}
	data, err = os.ReadFile(file)
	if err != nil {
		t.Fatal(err)
	}
	text := string(data)
	if strings.Contains(text, "DMS-RULE") || strings.Contains(text, "dms-floating-windows") {
		t.Errorf("alte Namen nach dem Schreiben noch da:\n%s", text)
	}
	if strings.Count(text, "-- ALPE-RULE:") != 2 {
		t.Errorf("erwartet 2 Regeln mit neuer Marke:\n%s", text)
	}
}

func TestCurrentRuleID(t *testing.T) {
	for old, want := range map[string]string{
		"dms-window-opaque":    windowrules.OpaqueRuleID,
		"dms-floating-windows": "alpe-floating-windows",
		"meine-regel":          "meine-regel",
		"dms_rule_3":           "dms_rule_3",
	} {
		if got := windowrules.CurrentRuleID(old); got != want {
			t.Errorf("CurrentRuleID(%q) = %q, want %q", old, got, want)
		}
	}
	if windowrules.OpaqueRuleID != "alpe-window-opaque" {
		t.Errorf("OpaqueRuleID = %q", windowrules.OpaqueRuleID)
	}
}
