package luaconfig

import (
	"os"
	"path/filepath"
	"testing"
)

func TestModuleToRelPath(t *testing.T) {
	tests := map[string]string{
		"alpe.binds":      filepath.Join("alpe", "binds.lua"),
		"alpe/binds-user": filepath.Join("alpe", "binds-user.lua"),
		" awesome.binds ": filepath.Join("awesome", "binds.lua"),
	}

	for input, want := range tests {
		if got := ModuleToRelPath(input); got != want {
			t.Fatalf("ModuleToRelPath(%q) = %q, want %q", input, got, want)
		}
	}
}

func TestRequiresSkipsComments(t *testing.T) {
	if modules := Requires(`-- require("alpe.binds")`); len(modules) != 0 {
		t.Fatalf("expected commented require to be ignored, got %#v", modules)
	}

	modules := Requires(`print("-- not a comment") require("alpe.binds") -- require("ignored")`)
	if len(modules) != 1 || modules[0] != "alpe.binds" {
		t.Fatalf("unexpected modules: %#v", modules)
	}
}

func TestRequiresTargetRecurses(t *testing.T) {
	tmpDir := t.TempDir()
	appDir := filepath.Join(tmpDir, "alpe")
	if err := os.MkdirAll(appDir, 0o755); err != nil {
		t.Fatal(err)
	}
	target := filepath.Join(appDir, "windowrules.lua")
	if err := os.WriteFile(filepath.Join(tmpDir, "hyprland.lua"), []byte(`require("alpe.extra")`), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(appDir, "extra.lua"), []byte(`require("alpe.windowrules")`), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(target, []byte(`-- rules`), 0o644); err != nil {
		t.Fatal(err)
	}

	if !RequiresTarget(filepath.Join(tmpDir, "hyprland.lua"), target, make(map[string]bool)) {
		t.Fatal("expected recursive require lookup to find target")
	}
}
