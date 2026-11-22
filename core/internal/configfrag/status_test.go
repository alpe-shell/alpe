package configfrag

import "testing"

var hyprlandBinds = Messages{
	Missing:     "alpe/binds.lua (or legacy binds.conf) does not exist",
	NotIncluded: "alpe binds are not loaded from Hyprland config (require / source)",
	Overridden:  "Some Alpe binds may be overridden by config binds",
	Active:      "Alpe binds are active",
}

var mangoBinds = Messages{
	Missing:     "alpe/binds.conf does not exist",
	NotIncluded: "alpe/binds.conf is not sourced in config",
	Overridden:  "Some Alpe binds may be overridden by config binds",
	Active:      "Alpe binds are active",
}

var hyprlandRules = Messages{
	Missing:     "alpe window rules fragment (windowrules.lua / windowrules.conf) does not exist",
	NotIncluded: "alpe window rules are not loaded (missing require/source for alpe/windowrules)",
	Overridden:  "Some Alpe rules may be overridden by config rules",
	Active:      "Alpe window rules are active",
}

var allDomains = map[string]Messages{
	"hyprland binds": hyprlandBinds,
	"mango binds":    mangoBinds,
	"hyprland rules": hyprlandRules,
}

func TestMissingFragmentIsNotEffective(t *testing.T) {
	for domain, msgs := range allDomains {
		status := BuildStatus(NewScan(), false, 0, msgs)
		if status.Effective {
			t.Errorf("%s: a missing fragment must not be effective", domain)
		}
		if status.StatusMessage != msgs.Missing {
			t.Errorf("%s: message = %q, want %q", domain, status.StatusMessage, msgs.Missing)
		}
		if status.OverriddenBy != 0 {
			t.Errorf("%s: overriddenBy = %d, want 0", domain, status.OverriddenBy)
		}
	}
}

func TestExistingButNotIncludedIsNotEffective(t *testing.T) {
	for domain, msgs := range allDomains {
		scan := NewScan()
		scan.Count = 2
		status := BuildStatus(scan, true, 0, msgs)
		if status.Effective {
			t.Errorf("%s: an unincluded fragment must not be effective", domain)
		}
		if status.StatusMessage != msgs.NotIncluded {
			t.Errorf("%s: message = %q, want %q", domain, status.StatusMessage, msgs.NotIncluded)
		}
	}
}

func TestIncludedWithEntriesAfterReportsOverride(t *testing.T) {
	for domain, msgs := range allDomains {
		scan := IncludeScan{Count: 3, ShellPosition: 2, ShellSeen: true}
		status := BuildStatus(scan, true, 5, msgs)
		if !status.Effective {
			t.Errorf("%s: an overridden fragment is still effective", domain)
		}
		if status.OverriddenBy != 5 {
			t.Errorf("%s: overriddenBy = %d, want 5", domain, status.OverriddenBy)
		}
		if status.StatusMessage != msgs.Overridden {
			t.Errorf("%s: message = %q, want %q", domain, status.StatusMessage, msgs.Overridden)
		}
	}
}

func TestIncludedWithNothingAfterIsActive(t *testing.T) {
	for domain, msgs := range allDomains {
		scan := IncludeScan{Count: 1, ShellPosition: 1, ShellSeen: true}
		status := BuildStatus(scan, true, 0, msgs)
		if !status.Effective {
			t.Errorf("%s: an included fragment with nothing after it is effective", domain)
		}
		if status.OverriddenBy != 0 {
			t.Errorf("%s: overriddenBy = %d, want 0", domain, status.OverriddenBy)
		}
		if status.StatusMessage != msgs.Active {
			t.Errorf("%s: message = %q, want %q", domain, status.StatusMessage, msgs.Active)
		}
	}
}

func TestScanCarriesThrough(t *testing.T) {
	scan := IncludeScan{Count: 4, ShellPosition: 3, ShellSeen: true}
	status := BuildStatus(scan, true, 0, hyprlandRules)

	if status.TotalIncludes != 4 || status.IncludePosition != 3 {
		t.Errorf("includes = %d/%d, want 3/4", status.IncludePosition, status.TotalIncludes)
	}
	if !status.Included {
		t.Error("ShellSeen must land on Included")
	}
}
