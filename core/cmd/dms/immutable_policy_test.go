package main

import (
	"encoding/json"
	"testing"

	"github.com/alpe-shell/alpe/core/internal/clipolicy"
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
	if len(blocked) != 0 {
		t.Fatalf("embedded CLI policy must block nothing, got %v", blocked)
	}
}
