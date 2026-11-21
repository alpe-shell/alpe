package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// Plan 6.8: «alpe-dienst restart» darf nie systemctl start/stop/restart aufrufen, ob eine Instanz
// als alpe.service läuft oder nicht. Eine systemctl-Attrappe vorne im PATH protokolliert jeden
// Aufruf; der Haken darf gar keinen erzeugen.
func stubSystemctl(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	logPath := filepath.Join(dir, "calls.log")
	script := "#!/bin/sh\necho \"$*\" >> '" + logPath + "'\n"
	if err := os.WriteFile(filepath.Join(dir, "systemctl"), []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))
	return logPath
}

func TestRefuseUnitRestart(t *testing.T) {
	tests := []struct {
		name        string
		cgroups     map[int]string
		wantHandled bool
		wantNotice  bool
	}{
		{"instance in alpe.service", map[int]string{4711: "0::/user.slice/user-1000.slice/user@1000.service/app.slice/alpe.service\n"}, true, true},
		{"hand-started instance", map[int]string{4711: "0::/user.slice/user-1000.slice/user@1000.service/app.slice/app-org.kde.konsole@1.service\n"}, false, false},
		{"old dms.service is not ours", map[int]string{4711: "0::/user.slice/user@1000.service/app.slice/dms.service\n"}, false, false},
		{"no instance", map[int]string{}, false, false},
	}

	origInstances, origCgroup, origNotice := runningInstances, readCgroup, restartNotice
	t.Cleanup(func() { runningInstances, readCgroup, restartNotice = origInstances, origCgroup, origNotice })

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			calls := stubSystemctl(t)
			runningInstances = func() []int {
				var pids []int
				for pid := range tt.cgroups {
					pids = append(pids, pid)
				}
				return pids
			}
			readCgroup = func(pid int) string { return tt.cgroups[pid] }
			var notice bytes.Buffer
			restartNotice = &notice

			handled, err := refuseUnitRestart()
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if handled != tt.wantHandled {
				t.Fatalf("handled = %v, want %v", handled, tt.wantHandled)
			}
			if got := strings.Contains(notice.String(), "alpe restart"); got != tt.wantNotice {
				t.Fatalf("notice %q, want notice %v", notice.String(), tt.wantNotice)
			}
			if data, _ := os.ReadFile(calls); len(data) != 0 {
				t.Fatalf("systemctl called: %q", data)
			}
		})
	}
}

func TestInUnit(t *testing.T) {
	for cgroup, want := range map[string]bool{
		"0::/user.slice/user@1000.service/app.slice/alpe.service\n":                      true,
		"12:pids:/user.slice/x\n0::/user.slice/user@1000.service/app.slice/alpe.service": true,
		"0::/user.slice/user@1000.service/app.slice/xalpe.service":                       false,
		"0::/user.slice/user@1000.service/app.slice/alpe.service/sub":                    false,
		"": false,
	} {
		if got := inUnit(cgroup); got != want {
			t.Errorf("inUnit(%q) = %v, want %v", cgroup, got, want)
		}
	}
}

// Die Unterbefehle von «alpe-dienst systemd» starten, stoppen und starten nichts neu.
func TestSystemdCommandHasNoLifecycle(t *testing.T) {
	for _, sub := range systemdCmd.Commands() {
		switch sub.Name() {
		case "start", "stop", "restart":
			t.Errorf("systemd %s must not exist (Plan 6.8)", sub.Name())
		}
		if sub.Flags().Lookup("now") != nil {
			t.Errorf("systemd %s --now must not exist (Plan 6.8)", sub.Name())
		}
	}
}
