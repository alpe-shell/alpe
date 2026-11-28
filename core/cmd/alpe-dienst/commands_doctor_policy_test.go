package main

import (
	"strings"
	"testing"

	"github.com/alpe-shell/alpe/core/internal/clipolicy"
	"github.com/spf13/afero"
)

// Plan 0.8 Nr. 139 (1): «alpe-dienst doctor» nennt den Rückfall auf die Richtlinie des Administrators aus 1.0 bei jedem
// Aufruf (die Warnung im Protokoll kommt nur einmal je Prozess).
func TestCheckCLIPolicy(t *testing.T) {
	tests := []struct {
		name         string
		admin        bool
		legacy       bool
		wantStatus   status
		wantContains []string
	}{
		{name: "no policy", wantStatus: statusInfo, wantContains: []string{"Not present"}},
		{name: "admin policy", admin: true, wantStatus: statusOK, wantContains: []string{"Present"}},
		{name: "only the policy of 1.0", legacy: true, wantStatus: statusWarn,
			wantContains: []string{"Alpe 1.0", clipolicy.LegacyAdminPath, clipolicy.AdminPath}},
		{name: "admin policy wins over 1.0", admin: true, legacy: true, wantStatus: statusOK, wantContains: []string{"Present"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fs := afero.NewMemMapFs()
			if tt.admin {
				if err := afero.WriteFile(fs, clipolicy.AdminPath, []byte("{}"), 0o644); err != nil {
					t.Fatal(err)
				}
			}
			if tt.legacy {
				if err := afero.WriteFile(fs, clipolicy.LegacyAdminPath, []byte("{}"), 0o644); err != nil {
					t.Fatal(err)
				}
			}
			results := checkCLIPolicy(fs)
			if len(results) != 1 {
				t.Fatalf("want exactly one result, got %d", len(results))
			}
			r := results[0]
			if r.category != catConfigFiles || r.name != "cli-policy.json" || r.status != tt.wantStatus {
				t.Errorf("got %v/%q/%q, want Config Files/cli-policy.json/%q", r.category, r.name, r.status, tt.wantStatus)
			}
			for _, want := range tt.wantContains {
				if !strings.Contains(r.message, want) {
					t.Errorf("message %q does not contain %q", r.message, want)
				}
			}
			if r.details != clipolicy.AdminPath {
				t.Errorf("details %q, want %q", r.details, clipolicy.AdminPath)
			}
		})
	}
}
