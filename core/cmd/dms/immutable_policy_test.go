package main

import (
	"encoding/json"
	"testing"

	"github.com/duxlabs-dev/dux-shell/core/internal/clipolicy"
)

func TestDefaultImmutablePolicyBlocksNothing(t *testing.T) {
	var policyFile clipolicy.File
	if err := json.Unmarshal(defaultCLIPolicyJSON, &policyFile); err != nil {
		t.Fatalf("failed to parse embedded CLI policy: %v", err)
	}
	if policyFile.BlockedCommands == nil {
		t.Fatal("embedded CLI policy has no blocked_commands")
	}

	blocked := normalizeBlockedCommands(*policyFile.BlockedCommands)
	if commandBlockedByPolicy("setup", blocked) {
		t.Fatal("setup only writes to the home directory and must stay available on image-based systems")
	}
}
