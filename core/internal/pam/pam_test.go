package pam

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func writeTestFile(t *testing.T, path string, content string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("failed to create parent dir for %s: %v", path, err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatalf("failed to write %s: %v", path, err)
	}
}

func (e *pamTestEnv) writePamFile(t *testing.T, name string, content string) {
	t.Helper()
	writeTestFile(t, filepath.Join(e.pamDir, name), content)
}

func (e *pamTestEnv) writeSettings(t *testing.T, content string) {
	t.Helper()
	writeTestFile(t, filepath.Join(e.homeDir, ".config", "alpe", "settings.json"), content)
}

func readFileString(t *testing.T, path string) string {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("failed to read %s: %v", path, err)
	}
	return string(data)
}

func TestHasManagedLockscreenPamFile(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name    string
		content string
		want    bool
	}{
		{
			name: "both markers present",
			content: "#%PAM-1.0\n" +
				LockscreenPamManagedBlockStart + "\n" +
				"auth sufficient pam_unix.so\n" +
				LockscreenPamManagedBlockEnd + "\n",
			want: true,
		},
		{
			name: "missing end marker is not managed",
			content: "#%PAM-1.0\n" +
				LockscreenPamManagedBlockStart + "\n" +
				"auth sufficient pam_unix.so\n",
			want: false,
		},
		{
			name:    "custom file is not managed",
			content: "#%PAM-1.0\nauth sufficient pam_unix.so\n",
			want:    false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			if got := hasManagedLockscreenPamFile(tt.content); got != tt.want {
				t.Fatalf("hasManagedLockscreenPamFile() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestBuildManagedLockscreenPamContent(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name            string
		files           map[string]string
		wantContains    []string
		wantNotContains []string
		wantCounts      map[string]int
		wantErr         string
	}{
		{
			name: "preserves custom modules and strips direct u2f and fprint directives",
			files: map[string]string{
				"login": "#%PAM-1.0\n" +
					"auth include system-auth\n" +
					"account include system-auth\n" +
					"session include system-auth\n",
				"system-auth": "auth requisite pam_nologin.so\n" +
					"auth sufficient pam_unix.so try_first_pass nullok\n" +
					"auth sufficient pam_u2f.so cue\n" +
					"auth sufficient pam_fprintd.so max-tries=1\n" +
					"auth required pam_radius_auth.so conf=/etc/raddb/server\n" +
					"account required pam_access.so\n" +
					"session optional pam_lastlog.so silent\n",
			},
			wantContains: []string{
				"#%PAM-1.0",
				LockscreenPamManagedBlockStart,
				LockscreenPamManagedBlockEnd,
				"auth requisite pam_nologin.so",
				"auth sufficient pam_unix.so try_first_pass nullok",
				"auth required pam_radius_auth.so conf=/etc/raddb/server",
				"account required pam_access.so",
				"session optional pam_lastlog.so silent",
			},
			wantNotContains: []string{
				"pam_u2f",
				"pam_fprintd",
			},
			wantCounts: map[string]int{
				"auth required pam_radius_auth.so conf=/etc/raddb/server": 1,
				"account required pam_access.so":                          1,
			},
		},
		{
			name: "resolves nested include substack and @include transitively",
			files: map[string]string{
				"login": "#%PAM-1.0\n" +
					"auth include system-auth\n" +
					"account include system-auth\n" +
					"password include system-auth\n" +
					"session include system-auth\n",
				"system-auth": "auth substack custom-auth\n" +
					"account include custom-auth\n" +
					"password include custom-auth\n" +
					"session @include common-session\n",
				"custom-auth": "auth required pam_custom.so one=two\n" +
					"account required pam_custom_account.so\n" +
					"password required pam_custom_password.so\n",
				"common-session": "session optional pam_fprintd.so max-tries=1\n" +
					"session optional pam_lastlog.so silent\n",
			},
			wantContains: []string{
				"auth required pam_custom.so one=two",
				"account required pam_custom_account.so",
				"password required pam_custom_password.so",
				"session optional pam_lastlog.so silent",
			},
			wantNotContains: []string{
				"pam_fprintd",
			},
			wantCounts: map[string]int{
				"auth required pam_custom.so one=two":      1,
				"account required pam_custom_account.so":   1,
				"password required pam_custom_password.so": 1,
				"session optional pam_lastlog.so silent":   1,
			},
		},
		{
			name: "falls back to system-auth when login is absent",
			files: map[string]string{
				"system-auth": "#%PAM-1.0\nauth sufficient pam_unix.so try_first_pass nullok\naccount required pam_unix.so\n",
			},
			wantContains: []string{
				"auth sufficient pam_unix.so try_first_pass nullok",
				"account required pam_unix.so",
			},
		},
		{
			name: "no usable service when none of the candidates exist",
			files: map[string]string{
				"other": "#%PAM-1.0\nauth required pam_deny.so\n",
			},
			wantErr: "no usable PAM auth service found",
		},
		{
			name: "existing login with bad include is authoritative and does not fall back",
			files: map[string]string{
				"login":       "#%PAM-1.0\nauth include missing-auth\n",
				"system-auth": "#%PAM-1.0\nauth sufficient pam_unix.so\naccount required pam_unix.so\n",
			},
			wantErr: "failed to read PAM file",
		},
		{
			name: "missing include fails",
			files: map[string]string{
				"login": "#%PAM-1.0\nauth include missing-auth\n",
			},
			wantErr: "failed to read PAM file",
		},
		{
			name: "cyclic include fails",
			files: map[string]string{
				"login":       "#%PAM-1.0\nauth include system-auth\n",
				"system-auth": "auth include login\n",
			},
			wantErr: "cyclic PAM include detected",
		},
		{
			name: "no auth directives remain after filtering fails",
			files: map[string]string{
				"login":       "#%PAM-1.0\nauth include system-auth\n",
				"system-auth": "auth sufficient pam_u2f.so cue\n",
			},
			wantErr: "no auth directives remained after filtering",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			env := newPamTestEnv(t)
			for name, content := range tt.files {
				env.writePamFile(t, name, content)
			}

			content, err := buildManagedLockscreenPamContent([]string{env.pamDir}, os.ReadFile)
			if tt.wantErr != "" {
				if err == nil {
					t.Fatalf("expected error containing %q, got nil", tt.wantErr)
				}
				if !strings.Contains(err.Error(), tt.wantErr) {
					t.Fatalf("error = %q, want substring %q", err.Error(), tt.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatalf("buildManagedLockscreenPamContent returned error: %v", err)
			}

			for _, want := range tt.wantContains {
				if !strings.Contains(content, want) {
					t.Errorf("missing expected string %q in output:\n%s", want, content)
				}
			}
			for _, notWant := range tt.wantNotContains {
				if strings.Contains(content, notWant) {
					t.Errorf("unexpected string %q found in output:\n%s", notWant, content)
				}
			}
			for want, wantCount := range tt.wantCounts {
				if gotCount := strings.Count(content, want); gotCount != wantCount {
					t.Errorf("count for %q = %d, want %d\noutput:\n%s", want, gotCount, wantCount, content)
				}
			}
		})
	}
}

// Real /etc/pam.d layouts of the non-Arch-shaped distros (#2789).
func TestBuildManagedLockscreenPamContent_DistroShapes(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name            string
		files           map[string]string
		wantContains    []string
		wantNotContains []string
	}{
		{
			// openSUSE: `include` (not @include), common-auth symlinked to
			// common-auth-pc (here just a plain file), bracketed securetty
			// control, keyring modules, pam_sss.
			name: "openSUSE include + common-auth + bracket control",
			files: map[string]string{
				"login": "#%PAM-1.0\n" +
					"auth     requisite      pam_nologin.so\n" +
					"auth     [user_unknown=ignore success=ok ignore=ignore auth_err=die default=bad] pam_securetty.so\n" +
					"auth     include        common-auth\n" +
					"account  include        common-account\n" +
					"session  required       pam_loginuid.so\n" +
					"session  include        common-session\n",
				"common-auth": "auth    required    pam_env.so\n" +
					"auth    optional    pam_gnome_keyring.so\n" +
					"auth    sufficient  pam_unix.so try_first_pass\n" +
					"auth    required    pam_sss.so use_first_pass\n",
				"common-account": "account required pam_unix.so try_first_pass\naccount sufficient pam_localuser.so\n",
				"common-session": "session optional pam_gnome_keyring.so auto_start\n",
			},
			wantContains: []string{
				"pam_securetty.so",
				"auth    sufficient  pam_unix.so try_first_pass",
				"auth    required    pam_sss.so use_first_pass",
				"account required pam_unix.so try_first_pass",
			},
		},
		{
			name: "openSUSE without login stitches common-auth and common-account",
			files: map[string]string{
				"common-auth": "auth    required    pam_env.so\n" +
					"auth    optional    pam_gnome_keyring.so\n" +
					"auth    sufficient  pam_unix.so try_first_pass\n" +
					"auth    required    pam_sss.so use_first_pass\n",
				"common-account": "account required pam_unix.so try_first_pass\n" +
					"account sufficient pam_localuser.so\n" +
					"account required pam_sss.so use_first_pass\n",
			},
			wantContains: []string{
				"auth    sufficient  pam_unix.so try_first_pass",
				"auth    required    pam_sss.so use_first_pass",
				"account required pam_unix.so try_first_pass",
				"account required pam_sss.so use_first_pass",
			},
		},
		{
			name: "openSUSE with only common-auth resolves auth-only",
			files: map[string]string{
				"common-auth": "auth sufficient pam_unix.so try_first_pass\nauth required pam_deny.so\n",
			},
			wantContains: []string{"auth sufficient pam_unix.so try_first_pass"},
			wantNotContains: []string{
				"account",
			},
		},
		{
			name: "Debian @include common-auth and common-account",
			files: map[string]string{
				"login": "#%PAM-1.0\n" +
					"auth       requisite  pam_nologin.so\n" +
					"@include common-auth\n" +
					"@include common-account\n" +
					"session    required   pam_loginuid.so\n" +
					"@include common-session\n",
				"common-auth": "auth\t[success=1 default=ignore]\tpam_unix.so nullok\n" +
					"auth\trequisite\t\t\tpam_deny.so\n" +
					"auth\trequired\t\t\tpam_permit.so\n",
				"common-account": "account\t[success=1 new_authtok_reqd=done default=ignore]\tpam_unix.so\naccount\trequisite\t\t\tpam_deny.so\n",
				"common-session": "session\t[default=1]\t\t\tpam_permit.so\n",
			},
			wantContains: []string{
				"auth\t[success=1 default=ignore]\tpam_unix.so nullok",
				"account\t[success=1 new_authtok_reqd=done default=ignore]\tpam_unix.so",
			},
		},
		{
			name: "NixOS flat login with absolute paths and dash directives",
			files: map[string]string{
				"login": "#%PAM-1.0\n" +
					"auth required /nix/store/abc-pam/lib/security/pam_unix.so likeauth nullok try_first_pass\n" +
					"auth sufficient /nix/store/abc-pam-u2f/lib/security/pam_u2f.so\n" +
					"-auth optional /nix/store/abc-kbd/lib/security/pam_gnome_keyring.so\n" +
					"account required /nix/store/abc-pam/lib/security/pam_unix.so\n" +
					"-session optional /nix/store/abc-sd/lib/security/pam_systemd.so\n",
			},
			wantContains: []string{
				"auth required /nix/store/abc-pam/lib/security/pam_unix.so likeauth nullok try_first_pass",
				"-auth optional /nix/store/abc-kbd/lib/security/pam_gnome_keyring.so",
				"account required /nix/store/abc-pam/lib/security/pam_unix.so",
			},
			wantNotContains: []string{"pam_u2f"},
		},
		{
			name: "Gentoo deep include chain login->system-local-login->system-login->system-auth",
			files: map[string]string{
				"login":              "#%PAM-1.0\nauth\tinclude\t\tsystem-local-login\naccount\tinclude\t\tsystem-local-login\n",
				"system-local-login": "auth\trequired\tpam_group.so\nauth\tinclude\t\tsystem-login\naccount\tinclude\t\tsystem-login\n",
				"system-login":       "auth\tinclude\t\tsystem-auth\naccount\tinclude\t\tsystem-auth\n",
				"system-auth":        "auth\trequired\tpam_env.so\nauth\tsufficient\tpam_unix.so try_first_pass likeauth nullok\nauth\trequired\tpam_deny.so\naccount\trequired\tpam_unix.so\n",
			},
			wantContains: []string{
				"auth\trequired\tpam_group.so",
				"auth\tsufficient\tpam_unix.so try_first_pass likeauth nullok",
				"account\trequired\tpam_unix.so",
			},
		},
		{
			name: "no login, entry falls through to system-auth",
			files: map[string]string{
				"system-auth": "#%PAM-1.0\n" +
					"auth        required      pam_env.so\n" +
					"auth        sufficient    pam_unix.so nullok\n" +
					"auth        sufficient    pam_sss.so forward_pass\n" +
					"auth        required      pam_deny.so\n" +
					"account     required      pam_unix.so\n" +
					"account     [default=bad success=ok user_unknown=ignore] pam_sss.so\n",
			},
			wantContains: []string{
				"auth        sufficient    pam_unix.so nullok",
				"auth        sufficient    pam_sss.so forward_pass",
				"account     required      pam_unix.so",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			env := newPamTestEnv(t)
			for name, content := range tt.files {
				env.writePamFile(t, name, content)
			}

			content, err := buildManagedLockscreenPamContent([]string{env.pamDir}, os.ReadFile)
			if err != nil {
				t.Fatalf("buildManagedLockscreenPamContent returned error: %v", err)
			}
			if !strings.Contains(content, "auth") {
				t.Fatalf("resolved content has no auth line:\n%s", content)
			}
			for _, want := range tt.wantContains {
				if !strings.Contains(content, want) {
					t.Errorf("missing expected string %q in output:\n%s", want, content)
				}
			}
			for _, notWant := range tt.wantNotContains {
				if strings.Contains(content, notWant) {
					t.Errorf("unexpected string %q found in output:\n%s", notWant, content)
				}
			}
		})
	}
}

func TestBuildManagedLockscreenPamContent_VendorDirFallback(t *testing.T) {
	t.Parallel()

	// Stateless/vendored-PAM systems (Clear Linux) ship the stack in
	// /usr/lib|share/pam.d with /etc/pam.d empty; includes resolve in that dir.
	etcDir := t.TempDir()
	vendorDir := t.TempDir()
	writeTestFile(t, filepath.Join(vendorDir, "login"), "#%PAM-1.0\nauth include system-auth\naccount include system-auth\n")
	writeTestFile(t, filepath.Join(vendorDir, "system-auth"), "auth sufficient pam_unix.so nullok\naccount required pam_unix.so\n")

	content, err := buildManagedLockscreenPamContent([]string{etcDir, vendorDir}, os.ReadFile)
	if err != nil {
		t.Fatalf("buildManagedLockscreenPamContent returned error: %v", err)
	}
	for _, want := range []string{"auth sufficient pam_unix.so nullok", "account required pam_unix.so"} {
		if !strings.Contains(content, want) {
			t.Errorf("missing %q in output:\n%s", want, content)
		}
	}
}

func TestSyncLockscreenPamConfigWithDeps(t *testing.T) {
	t.Parallel()

	t.Run("custom alpe file is skipped untouched", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		customContent := "#%PAM-1.0\nauth required pam_unix.so\n"
		env.writePamFile(t, "alpe", customContent)

		var logs []string
		err := syncLockscreenPamConfigWithDeps(func(msg string) {
			logs = append(logs, msg)
		}, "", env.deps(false))
		if err != nil {
			t.Fatalf("syncLockscreenPamConfigWithDeps returned error: %v", err)
		}

		if got := readFileString(t, env.alpePath); got != customContent {
			t.Fatalf("custom alpe content changed\ngot:\n%s\nwant:\n%s", got, customContent)
		}
		if len(logs) == 0 || !strings.Contains(logs[0], "Custom "+env.alpePath+" found") {
			t.Fatalf("expected custom-file skip log, got %v", logs)
		}
	})

	t.Run("managed alpe file is rewritten from resolved login stack", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.writePamFile(t, "login", "#%PAM-1.0\nauth include system-auth\naccount include system-auth\n")
		env.writePamFile(t, "system-auth", "auth sufficient pam_unix.so try_first_pass nullok\nauth sufficient pam_u2f.so cue\naccount required pam_access.so\n")
		env.writePamFile(t, "alpe", "#%PAM-1.0\n"+LockscreenPamManagedBlockStart+"\nauth required pam_env.so\n"+LockscreenPamManagedBlockEnd+"\n")

		var logs []string
		err := syncLockscreenPamConfigWithDeps(func(msg string) {
			logs = append(logs, msg)
		}, "", env.deps(false))
		if err != nil {
			t.Fatalf("syncLockscreenPamConfigWithDeps returned error: %v", err)
		}

		output := readFileString(t, env.alpePath)
		for _, want := range []string{
			LockscreenPamManagedBlockStart,
			"auth sufficient pam_unix.so try_first_pass nullok",
			"account required pam_access.so",
			LockscreenPamManagedBlockEnd,
		} {
			if !strings.Contains(output, want) {
				t.Errorf("missing expected string %q in rewritten alpe:\n%s", want, output)
			}
		}
		if strings.Contains(output, "pam_u2f") {
			t.Errorf("rewritten alpe still contains pam_u2f:\n%s", output)
		}
		if len(logs) == 0 || !strings.Contains(logs[len(logs)-1], "Created or updated "+env.alpePath+" ") {
			t.Fatalf("expected success log, got %v", logs)
		}
	})

	// Plan 0.8 Nr. 16: Der Dienst der Einrichtung von 1.0 wird erkannt und nicht verändert. Ist er verwaltet, wird
	// der neue Dienst daneben geschrieben und löst ihn ab; ist er eigen und fehlt alpe, entsteht kein alpe
	// (Entscheid vom 25.11.2026, Plan 0.8 Nr. 118).
	for _, legacyManaged := range []bool{true, false} {
		t.Run(fmt.Sprintf("legacy service from 1.0 is left unchanged (managed=%v)", legacyManaged), func(t *testing.T) {
			t.Parallel()

			env := newPamTestEnv(t)
			env.writePamFile(t, "login", "#%PAM-1.0\nauth include system-auth\naccount include system-auth\n")
			env.writePamFile(t, "system-auth", "auth sufficient pam_unix.so try_first_pass nullok\naccount required pam_access.so\n")
			legacy := "#%PAM-1.0\nauth required pam_unix.so\n"
			if legacyManaged {
				legacy = "#%PAM-1.0\n" + legacyLockscreenPamManagedBlockStart + "\nauth required pam_env.so\n" + legacyLockscreenPamManagedBlockEnd + "\n"
			}
			if err := os.WriteFile(env.legacyPath, []byte(legacy), 0o644); err != nil {
				t.Fatal(err)
			}

			var logs []string
			err := syncLockscreenPamConfigWithDeps(func(msg string) {
				logs = append(logs, msg)
			}, "", env.deps(false))
			if err != nil {
				t.Fatalf("syncLockscreenPamConfigWithDeps returned error: %v", err)
			}
			if got := readFileString(t, env.legacyPath); got != legacy {
				t.Fatalf("legacy service changed\ngot:\n%s\nwant:\n%s", got, legacy)
			}
			kind := "(custom)"
			if legacyManaged {
				kind = "(managed block"
			}
			if len(logs) == 0 || !strings.Contains(logs[0], env.legacyPath+" from Alpe 1.0 "+kind) {
				t.Fatalf("expected legacy recognition log %q, got %v", kind, logs)
			}
			if !legacyManaged {
				if _, err := os.Stat(env.alpePath); !os.IsNotExist(err) {
					t.Fatalf("a custom legacy service must not be replaced by a new alpe service, stat err = %v", err)
				}
				last := logs[len(logs)-1]
				if !strings.Contains(last, "Custom "+env.legacyPath+" from Alpe 1.0 found and no "+env.alpePath) || !strings.Contains(last, "is not created") {
					t.Fatalf("expected a message that alpe is not created, got %v", logs)
				}
				return
			}
			output := readFileString(t, env.alpePath)
			if !strings.Contains(output, LockscreenPamManagedBlockStart) || !strings.Contains(output, "auth sufficient pam_unix.so try_first_pass nullok") {
				t.Fatalf("expected the Alpe service to be written next to the legacy one:\n%s", output)
			}
		})
	}

	// Gibt es alpe schon (von Alpe verwaltet), wird es auch neben einem eigenen alten Dienst weiter nachgeführt: Die
	// Regel gilt nur, solange alpe fehlt.
	t.Run("custom legacy service with a managed alpe: alpe is still updated", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.writePamFile(t, "login", "#%PAM-1.0\nauth include system-auth\naccount include system-auth\n")
		env.writePamFile(t, "system-auth", "auth sufficient pam_unix.so try_first_pass nullok\naccount required pam_access.so\n")
		env.writePamFile(t, "alpe", "#%PAM-1.0\n"+LockscreenPamManagedBlockStart+"\nauth required pam_env.so\n"+LockscreenPamManagedBlockEnd+"\n")
		legacy := "#%PAM-1.0\nauth required pam_unix.so\n"
		if err := os.WriteFile(env.legacyPath, []byte(legacy), 0o644); err != nil {
			t.Fatal(err)
		}

		var logs []string
		if err := syncLockscreenPamConfigWithDeps(func(msg string) { logs = append(logs, msg) }, "", env.deps(false)); err != nil {
			t.Fatalf("syncLockscreenPamConfigWithDeps returned error: %v", err)
		}
		if got := readFileString(t, env.legacyPath); got != legacy {
			t.Fatalf("legacy service changed:\n%s", got)
		}
		if output := readFileString(t, env.alpePath); !strings.Contains(output, "auth sufficient pam_unix.so try_first_pass nullok") {
			t.Fatalf("expected the managed alpe service to be rewritten:\n%s", output)
		}
		if !strings.Contains(logs[len(logs)-1], "Created or updated "+env.alpePath+" ") {
			t.Fatalf("expected success log, got %v", logs)
		}
	})

	t.Run("mutable systems fail when login stack cannot be converted safely", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		err := syncLockscreenPamConfigWithDeps(func(string) {}, "", env.deps(false))
		if err == nil {
			t.Fatal("expected error when login PAM file is missing, got nil")
		}
		if !strings.Contains(err.Error(), "failed to build") {
			t.Fatalf("error = %q, want substring %q", err.Error(), "failed to build")
		}
	})

	t.Run("NixOS remains informational and does not write alpe", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		var logs []string

		err := syncLockscreenPamConfigWithDeps(func(msg string) {
			logs = append(logs, msg)
		}, "", env.deps(true))
		if err != nil {
			t.Fatalf("syncLockscreenPamConfigWithDeps returned error on NixOS path: %v", err)
		}
		if len(logs) == 0 || !strings.Contains(logs[0], "NixOS detected") || !strings.Contains(logs[0], "sanitized password-only service") {
			t.Fatalf("expected NixOS informational log describing the user-state fallback, got %v", logs)
		}
		if _, err := os.Stat(env.alpePath); !os.IsNotExist(err) {
			t.Fatalf("expected no alpe file to be written on NixOS path, stat err = %v", err)
		}
	})
}

func TestSyncLockscreenU2FPamConfigWithDeps(t *testing.T) {
	t.Parallel()

	t.Run("enabled creates managed file", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		var logs []string

		err := syncLockscreenU2FPamConfigWithDeps(func(msg string) {
			logs = append(logs, msg)
		}, "", true, env.deps(false))
		if err != nil {
			t.Fatalf("syncLockscreenU2FPamConfigWithDeps returned error: %v", err)
		}

		got := readFileString(t, env.alpeU2fPath)
		if got != buildManagedLockscreenU2FPamContent() {
			t.Fatalf("unexpected managed alpe-u2f content:\n%s", got)
		}
		if len(logs) == 0 || !strings.Contains(logs[len(logs)-1], "Created or updated "+env.alpeU2fPath) {
			t.Fatalf("expected create log, got %v", logs)
		}
	})

	t.Run("enabled rewrites existing managed file", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.writePamFile(t, "alpe-u2f", "#%PAM-1.0\n"+LockscreenU2FPamManagedBlockStart+"\nauth required pam_u2f.so old\n"+LockscreenU2FPamManagedBlockEnd+"\n")

		if err := syncLockscreenU2FPamConfigWithDeps(func(string) {}, "", true, env.deps(false)); err != nil {
			t.Fatalf("syncLockscreenU2FPamConfigWithDeps returned error: %v", err)
		}
		if got := readFileString(t, env.alpeU2fPath); got != buildManagedLockscreenU2FPamContent() {
			t.Fatalf("managed alpe-u2f was not rewritten:\n%s", got)
		}
	})

	t.Run("disabled removes managed file", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.writePamFile(t, "alpe-u2f", buildManagedLockscreenU2FPamContent())

		var logs []string
		err := syncLockscreenU2FPamConfigWithDeps(func(msg string) {
			logs = append(logs, msg)
		}, "", false, env.deps(false))
		if err != nil {
			t.Fatalf("syncLockscreenU2FPamConfigWithDeps returned error: %v", err)
		}
		if _, err := os.Stat(env.alpeU2fPath); !os.IsNotExist(err) {
			t.Fatalf("expected managed alpe-u2f to be removed, stat err = %v", err)
		}
		if len(logs) == 0 || !strings.Contains(logs[len(logs)-1], "Removed Alpe-managed "+env.alpeU2fPath) {
			t.Fatalf("expected removal log, got %v", logs)
		}
	})

	t.Run("disabled preserves custom file", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		customContent := "#%PAM-1.0\nauth required pam_u2f.so cue\n"
		env.writePamFile(t, "alpe-u2f", customContent)

		var logs []string
		err := syncLockscreenU2FPamConfigWithDeps(func(msg string) {
			logs = append(logs, msg)
		}, "", false, env.deps(false))
		if err != nil {
			t.Fatalf("syncLockscreenU2FPamConfigWithDeps returned error: %v", err)
		}
		if got := readFileString(t, env.alpeU2fPath); got != customContent {
			t.Fatalf("custom alpe-u2f content changed\ngot:\n%s\nwant:\n%s", got, customContent)
		}
		if len(logs) == 0 || !strings.Contains(logs[0], "Custom "+env.alpeU2fPath+" found") {
			t.Fatalf("expected custom-file log, got %v", logs)
		}
	})

	// Plan 0.8 Nr. 16: Der U2F-Dienst der Einrichtung von 1.0 wird erkannt und nie verändert – weder beim
	// Einschalten noch beim Abschalten (dann löschte die alte Logik einen verwalteten Dienst).
	for _, enabled := range []bool{true, false} {
		t.Run(fmt.Sprintf("legacy u2f service from 1.0 is left unchanged (enabled=%v)", enabled), func(t *testing.T) {
			t.Parallel()

			env := newPamTestEnv(t)
			legacy := "#%PAM-1.0\n" + legacyLockscreenU2FPamManagedBlockStart + "\nauth required pam_u2f.so cue\n" + legacyLockscreenU2FPamManagedBlockEnd + "\n"
			if err := os.WriteFile(env.legacyU2fPath, []byte(legacy), 0o644); err != nil {
				t.Fatal(err)
			}

			var logs []string
			err := syncLockscreenU2FPamConfigWithDeps(func(msg string) {
				logs = append(logs, msg)
			}, "", enabled, env.deps(false))
			if err != nil {
				t.Fatalf("syncLockscreenU2FPamConfigWithDeps returned error: %v", err)
			}
			if got := readFileString(t, env.legacyU2fPath); got != legacy {
				t.Fatalf("legacy u2f service changed\ngot:\n%s\nwant:\n%s", got, legacy)
			}
			if len(logs) == 0 || !strings.Contains(logs[0], env.legacyU2fPath+" from Alpe 1.0 (managed block") || !strings.Contains(logs[0], "left unchanged") {
				t.Fatalf("expected legacy recognition log, got %v", logs)
			}
			_, statErr := os.Stat(env.alpeU2fPath)
			if enabled && statErr != nil {
				t.Fatalf("expected %s to be written when enabled: %v", env.alpeU2fPath, statErr)
			}
			if !enabled && !os.IsNotExist(statErr) {
				t.Fatalf("expected no %s when disabled, stat err = %v", env.alpeU2fPath, statErr)
			}
		})
	}

	// Entscheid vom 26.11.2026 (dieselbe Regel wie für den Passwortdienst aus 1.0, Plan 0.8 Nr. 118, 135): Ein eigener,
	// nicht verwalteter U2F-Dienst aus 1.0 ohne alpe-u2f wird beim Einschalten nicht abgelöst, sondern gemeldet.
	t.Run("enabled with custom legacy u2f service and no alpe-u2f: nothing written, reported", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		custom := "#%PAM-1.0\nauth required pam_u2f.so cue authfile=/etc/u2f_mappings origin=pam://example\n"
		if err := os.WriteFile(env.legacyU2fPath, []byte(custom), 0o644); err != nil {
			t.Fatal(err)
		}

		var logs []string
		err := syncLockscreenU2FPamConfigWithDeps(func(msg string) {
			logs = append(logs, msg)
		}, "", true, env.deps(false))
		if err != nil {
			t.Fatalf("syncLockscreenU2FPamConfigWithDeps returned error: %v", err)
		}
		if _, statErr := os.Stat(env.alpeU2fPath); !os.IsNotExist(statErr) {
			t.Fatalf("expected no %s next to a custom %s, stat err = %v", env.alpeU2fPath, env.legacyU2fPath, statErr)
		}
		if got := readFileString(t, env.legacyU2fPath); got != custom {
			t.Fatalf("custom legacy u2f service changed\ngot:\n%s\nwant:\n%s", got, custom)
		}
		if len(logs) != 2 || !strings.Contains(logs[0], env.legacyU2fPath+" from Alpe 1.0 (custom) found") ||
			!strings.Contains(logs[1], "Custom "+env.legacyU2fPath+" from Alpe 1.0 found and no "+env.alpeU2fPath) ||
			!strings.Contains(logs[1], "is not created") {
			t.Fatalf("expected recognition and not-created logs, got %v", logs)
		}
	})

	t.Run("enabled with custom legacy u2f service and a managed alpe-u2f: alpe-u2f is updated", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		custom := "#%PAM-1.0\nauth required pam_u2f.so cue\n"
		if err := os.WriteFile(env.legacyU2fPath, []byte(custom), 0o644); err != nil {
			t.Fatal(err)
		}
		env.writePamFile(t, "alpe-u2f", "#%PAM-1.0\n"+LockscreenU2FPamManagedBlockStart+"\nauth required pam_u2f.so old\n"+LockscreenU2FPamManagedBlockEnd+"\n")

		if err := syncLockscreenU2FPamConfigWithDeps(func(string) {}, "", true, env.deps(false)); err != nil {
			t.Fatalf("syncLockscreenU2FPamConfigWithDeps returned error: %v", err)
		}
		if got := readFileString(t, env.alpeU2fPath); got != buildManagedLockscreenU2FPamContent() {
			t.Fatalf("managed alpe-u2f was not rewritten:\n%s", got)
		}
		if got := readFileString(t, env.legacyU2fPath); got != custom {
			t.Fatalf("custom legacy u2f service changed:\n%s", got)
		}
	})
}

func TestLegacyManagedBlocksAreRecognizedNotWritten(t *testing.T) {
	t.Parallel()

	legacy := "#%PAM-1.0\n" + legacyLockscreenPamManagedBlockStart + "\nauth required pam_unix.so\n" + legacyLockscreenPamManagedBlockEnd + "\n"
	if !HasLegacyManagedLockscreenPamFile(legacy) || hasManagedLockscreenPamFile(legacy) {
		t.Fatalf("legacy block must be recognized as legacy and not as the Alpe block")
	}
	if HasLegacyManagedLockscreenPamFile(buildManagedLockscreenU2FPamContent()) || !HasLegacyManagedLockscreenU2FPamFile("#%PAM-1.0\n"+legacyLockscreenU2FPamManagedBlockStart+"\n"+legacyLockscreenU2FPamManagedBlockEnd+"\n") {
		t.Fatalf("legacy u2f block recognition is wrong")
	}
	for _, written := range []string{buildManagedLockscreenU2FPamContent(), LockscreenPamManagedBlockStart, LockscreenPamManagedBlockEnd} {
		if strings.Contains(written, legacyLockscreenPamManagedBlockEnd) || !strings.Contains(written, "ALPE LOCKSCREEN") {
			t.Fatalf("written block markers must be the Alpe ones: %q", written)
		}
	}
	if AlpePamPath != "/etc/pam.d/alpe" || AlpeU2FPamPath != "/etc/pam.d/alpe-u2f" || UserLockscreenPamService != "alpe" {
		t.Fatalf("PAM service names must be alpe and alpe-u2f")
	}
}

func TestListLockscreenPamServices(t *testing.T) {
	t.Parallel()

	t.Run("dedupes by name with earlier base dir winning", func(t *testing.T) {
		t.Parallel()

		etcDir := t.TempDir()
		vendorDir := t.TempDir()
		// login exists in both dirs; system-auth only in the vendor dir.
		writeTestFile(t, filepath.Join(etcDir, "login"), "#%PAM-1.0\nauth required pam_unix.so\naccount required pam_unix.so\n")
		writeTestFile(t, filepath.Join(vendorDir, "login"), "#%PAM-1.0\nauth required pam_deny.so\n")
		writeTestFile(t, filepath.Join(vendorDir, "system-auth"), "#%PAM-1.0\nauth sufficient pam_unix.so\naccount required pam_unix.so\n")

		services := listLockscreenPamServices([]string{etcDir, vendorDir}, os.ReadFile)
		if len(services) != 2 {
			t.Fatalf("expected 2 services (login, system-auth), got %d: %+v", len(services), services)
		}
		byName := map[string]LockscreenPamServiceInfo{}
		for _, s := range services {
			byName[s.Name] = s
		}
		login, ok := byName["login"]
		if !ok {
			t.Fatalf("expected login service, got %+v", services)
		}
		if login.Dir != etcDir || login.Path != filepath.Join(etcDir, "login") {
			t.Fatalf("expected login to resolve in earlier dir %s, got dir=%s path=%s", etcDir, login.Dir, login.Path)
		}
		if !login.HasAuth {
			t.Fatalf("expected login to report hasAuth")
		}
		if byName["system-auth"].Dir != vendorDir {
			t.Fatalf("expected system-auth to resolve in vendor dir, got %s", byName["system-auth"].Dir)
		}
	})

	t.Run("include resolution sets hasAuth and detects inline fprintd/u2f", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.writePamFile(t, "login", "#%PAM-1.0\nauth include system-auth\naccount include system-auth\n")
		env.writePamFile(t, "system-auth", "auth sufficient pam_unix.so\nauth sufficient pam_fprintd.so\nauth sufficient pam_u2f.so cue\naccount required pam_unix.so\n")

		services := listLockscreenPamServices([]string{env.pamDir}, os.ReadFile)
		var login LockscreenPamServiceInfo
		for _, s := range services {
			if s.Name == "login" {
				login = s
			}
		}
		if !login.HasAuth {
			t.Fatalf("expected hasAuth via resolved include")
		}
		if !login.InlineFingerprint || !login.InlineU2f {
			t.Fatalf("expected inline fingerprint and u2f detection, got %+v", login)
		}
	})
}

func TestValidateLockscreenPam(t *testing.T) {
	t.Parallel()

	t.Run("valid service with resolved auth", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.availableModules["pam_unix.so"] = true
		env.writePamFile(t, "login", "#%PAM-1.0\nauth include system-auth\naccount include system-auth\n")
		env.writePamFile(t, "system-auth", "auth sufficient pam_unix.so\naccount required pam_unix.so\n")

		result := validateLockscreenPam("login", "", env.validateDeps())
		if !result.Valid {
			t.Fatalf("expected valid result, got %+v", result)
		}
		if !result.HasAuth {
			t.Fatalf("expected hasAuth true")
		}
		if len(result.Errors) != 0 {
			t.Fatalf("expected no errors, got %v", result.Errors)
		}
	})

	t.Run("path outside base dirs is read directly", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.availableModules["pam_unix.so"] = true
		outside := filepath.Join(t.TempDir(), "custom-pam")
		writeTestFile(t, outside, "#%PAM-1.0\nauth sufficient pam_unix.so\naccount required pam_unix.so\n")

		result := validateLockscreenPam("", outside, env.validateDeps())
		if !result.Valid || result.Path != outside {
			t.Fatalf("expected valid result for outside path, got %+v", result)
		}
	})

	t.Run("missing module produces warning and missingModules but stays valid", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.availableModules["pam_unix.so"] = true
		env.writePamFile(t, "system-auth", "#%PAM-1.0\nauth sufficient pam_unix.so\nauth required pam_absent.so\naccount required pam_unix.so\n")

		result := validateLockscreenPam("system-auth", "", env.validateDeps())
		if !result.Valid {
			t.Fatalf("expected valid despite missing module, got %+v", result)
		}
		if len(result.MissingModules) != 1 || result.MissingModules[0] != "pam_absent.so" {
			t.Fatalf("expected missing pam_absent.so, got %v", result.MissingModules)
		}
		if !containsSubstr(result.Warnings, "pam_absent.so") {
			t.Fatalf("expected warning about missing module, got %v", result.Warnings)
		}
	})

	t.Run("unknown directive is a warning not an error", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.availableModules["pam_unix.so"] = true
		env.availableModules["pam_foo.so"] = true
		env.writePamFile(t, "system-auth", "#%PAM-1.0\nauth sufficient pam_unix.so\nbadtype required pam_foo.so\naccount required pam_unix.so\n")

		result := validateLockscreenPam("system-auth", "", env.validateDeps())
		if !result.Valid {
			t.Fatalf("expected valid with unknown directive, got %+v", result)
		}
		if len(result.Errors) != 0 {
			t.Fatalf("expected no errors, got %v", result.Errors)
		}
		if !containsSubstr(result.Warnings, "unsupported PAM directive") {
			t.Fatalf("expected unsupported directive warning, got %v", result.Warnings)
		}
	})

	t.Run("cyclic include is an error", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.writePamFile(t, "login", "#%PAM-1.0\nauth include system-auth\n")
		env.writePamFile(t, "system-auth", "auth include login\n")

		result := validateLockscreenPam("login", "", env.validateDeps())
		if result.Valid {
			t.Fatalf("expected invalid on cyclic include, got %+v", result)
		}
		if !containsSubstr(result.Errors, "cyclic PAM include detected") {
			t.Fatalf("expected cyclic include error, got %v", result.Errors)
		}
	})

	t.Run("no auth directives is an error", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.availableModules["pam_unix.so"] = true
		env.writePamFile(t, "system-auth", "#%PAM-1.0\naccount required pam_unix.so\n")

		result := validateLockscreenPam("system-auth", "", env.validateDeps())
		if result.Valid {
			t.Fatalf("expected invalid when no auth directives, got %+v", result)
		}
		if !containsSubstr(result.Errors, "no auth directives") {
			t.Fatalf("expected no-auth error, got %v", result.Errors)
		}
	})

	t.Run("missing file is an error", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		result := validateLockscreenPam("", filepath.Join(env.pamDir, "does-not-exist"), env.validateDeps())
		if result.Valid || len(result.Errors) == 0 {
			t.Fatalf("expected invalid for missing file, got %+v", result)
		}
	})

	t.Run("inline fingerprint and u2f produce warnings", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.availableModules["pam_unix.so"] = true
		env.availableModules["pam_fprintd.so"] = true
		env.availableModules["pam_u2f.so"] = true
		env.writePamFile(t, "system-auth", "#%PAM-1.0\nauth sufficient pam_unix.so\nauth sufficient pam_fprintd.so\nauth sufficient pam_u2f.so cue\naccount required pam_unix.so\n")

		result := validateLockscreenPam("system-auth", "", env.validateDeps())
		if !result.Valid {
			t.Fatalf("expected valid, got %+v", result)
		}
		if !result.InlineFingerprint || !result.InlineU2f {
			t.Fatalf("expected inline flags set, got %+v", result)
		}
		if !containsSubstr(result.Warnings, "pam_fprintd") || !containsSubstr(result.Warnings, "pam_u2f") {
			t.Fatalf("expected double-prompt warnings, got %v", result.Warnings)
		}
	})
}

func TestValidateLockscreenU2fPam(t *testing.T) {
	t.Parallel()

	t.Run("accepts a dedicated U2F stack with custom options", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.availableModules["pam_u2f.so"] = true
		env.writePamFile(t, "alpe-u2f", "#%PAM-1.0\nauth required pam_u2f.so cue authfile=/etc/u2f-mappings\naccount required pam_permit.so\n")

		result := validateLockscreenU2fPam("alpe-u2f", "", env.validateDeps())
		if !result.Valid {
			t.Fatalf("expected valid dedicated U2F stack, got %+v", result)
		}
		if !result.InlineU2f {
			t.Fatalf("expected inline U2F detection, got %+v", result)
		}
		if containsSubstr(result.Warnings, "double-prompt") {
			t.Fatalf("dedicated U2F validation should not warn about its expected U2F module: %v", result.Warnings)
		}
	})

	t.Run("rejects a primary login stack that also prompts for a password", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.availableModules["pam_unix.so"] = true
		env.availableModules["pam_u2f.so"] = true
		env.writePamFile(t, "login", "#%PAM-1.0\nauth required pam_unix.so\nauth required pam_u2f.so cue\naccount required pam_unix.so\n")

		result := validateLockscreenU2fPam("login", "", env.validateDeps())
		if result.Valid {
			t.Fatalf("expected mixed password/U2F stack to be rejected, got %+v", result)
		}
		if !containsSubstr(result.Errors, "pam_unix.so") || !containsSubstr(result.Errors, "dedicated security-key") {
			t.Fatalf("expected actionable mixed-stack error, got %v", result.Errors)
		}
	})

	t.Run("rejects a stack without pam_u2f", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.availableModules["pam_unix.so"] = true
		env.writePamFile(t, "password-only", "#%PAM-1.0\nauth required pam_unix.so\n")

		result := validateLockscreenU2fPam("password-only", "", env.validateDeps())
		if result.Valid || !containsSubstr(result.Errors, "pam_u2f") {
			t.Fatalf("expected missing-U2F error, got %+v", result)
		}
	})

	t.Run("does not accept a similarly named module as pam_u2f", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.availableModules["pam_u2f_helper.so"] = true
		env.writePamFile(t, "not-u2f", "#%PAM-1.0\nauth required pam_u2f_helper.so\n")

		result := validateLockscreenU2fPam("not-u2f", "", env.validateDeps())
		if result.Valid || !containsSubstr(result.Errors, "no pam_u2f auth directive") {
			t.Fatalf("expected exact pam_u2f module validation, got %+v", result)
		}
	})

	t.Run("rejects a missing pam_u2f module", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.writePamFile(t, "alpe-u2f", "#%PAM-1.0\nauth required pam_u2f.so cue\n")

		result := validateLockscreenU2fPam("alpe-u2f", "", env.validateDeps())
		if result.Valid || !containsSubstr(result.Errors, "pam_u2f.so is not installed") {
			t.Fatalf("expected missing-module error, got %+v", result)
		}
	})
}

func containsSubstr(items []string, substr string) bool {
	for _, item := range items {
		if strings.Contains(item, substr) {
			return true
		}
	}
	return false
}

type pamTestEnv struct {
	pamDir           string
	alpePath         string
	alpeU2fPath      string
	legacyPath       string
	legacyU2fPath    string
	tmpDir           string
	homeDir          string
	availableModules map[string]bool
}

func newPamTestEnv(t *testing.T) *pamTestEnv {
	t.Helper()

	root := t.TempDir()
	pamDir := filepath.Join(root, "pam.d")
	tmpDir := filepath.Join(root, "tmp")
	homeDir := filepath.Join(root, "home")

	for _, dir := range []string{pamDir, tmpDir, homeDir} {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			t.Fatalf("failed to create %s: %v", dir, err)
		}
	}

	return &pamTestEnv{
		pamDir:      pamDir,
		alpePath:    filepath.Join(pamDir, "alpe"),
		alpeU2fPath: filepath.Join(pamDir, "alpe-u2f"),
		// alpe-namen-ausnahme: umzug-ende
		legacyPath:    filepath.Join(pamDir, "dankshell"),
		legacyU2fPath: filepath.Join(pamDir, "dankshell-u2f"),
		// alpe-namen-ausnahme: umzug-ende
		tmpDir:           tmpDir,
		homeDir:          homeDir,
		availableModules: map[string]bool{},
	}
}

func (e *pamTestEnv) deps(isNixOS bool) syncDeps {
	return syncDeps{
		pamDir:        e.pamDir,
		alpePath:      e.alpePath,
		alpeU2fPath:   e.alpeU2fPath,
		legacyPath:    e.legacyPath,
		legacyU2fPath: e.legacyU2fPath,
		isNixOS:       func() bool { return isNixOS },
		readFile:      os.ReadFile,
		stat:          os.Stat,
		createTemp: func(_ string, pattern string) (*os.File, error) {
			return os.CreateTemp(e.tmpDir, pattern)
		},
		removeFile: os.Remove,
		runSudoCmd: func(_ string, command string, args ...string) error {
			switch command {
			case "cp":
				if len(args) != 2 {
					return fmt.Errorf("unexpected cp args: %v", args)
				}
				data, err := os.ReadFile(args[0])
				if err != nil {
					return err
				}
				if err := os.MkdirAll(filepath.Dir(args[1]), 0o755); err != nil {
					return err
				}
				return os.WriteFile(args[1], data, 0o644)
			case "chmod":
				if len(args) != 2 {
					return fmt.Errorf("unexpected chmod args: %v", args)
				}
				return nil
			case "rm":
				if len(args) != 2 || args[0] != "-f" {
					return fmt.Errorf("unexpected rm args: %v", args)
				}
				if err := os.Remove(args[1]); err != nil && !os.IsNotExist(err) {
					return err
				}
				return nil
			default:
				return fmt.Errorf("unexpected sudo command: %s %v", command, args)
			}
		},
	}
}

func (e *pamTestEnv) validateDeps() lockscreenPamValidateDeps {
	return lockscreenPamValidateDeps{
		baseDirs:        []string{e.pamDir},
		readFile:        os.ReadFile,
		stat:            os.Stat,
		pamModuleExists: func(module string) bool { return e.availableModules[module] },
	}
}

func TestSyncAuthConfigWithDeps(t *testing.T) {
	t.Parallel()

	t.Run("creates lockscreen targets", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.writeSettings(t, `{"enableU2f":true}`)
		env.writePamFile(t, "login", "#%PAM-1.0\nauth include system-auth\naccount include system-auth\n")
		env.writePamFile(t, "system-auth", "auth sufficient pam_unix.so try_first_pass nullok\naccount required pam_access.so\n")

		err := syncAuthConfigWithDeps(func(string) {}, "", SyncAuthOptions{HomeDir: env.homeDir}, env.deps(false))
		if err != nil {
			t.Fatalf("syncAuthConfigWithDeps returned error: %v", err)
		}

		if _, err := os.Stat(env.alpePath); err != nil {
			t.Fatalf("expected alpe to be created: %v", err)
		}
		if got := readFileString(t, env.alpeU2fPath); got != buildManagedLockscreenU2FPamContent() {
			t.Fatalf("unexpected alpe-u2f content:\n%s", got)
		}
	})

	t.Run("removes alpe-u2f when disabled", func(t *testing.T) {
		t.Parallel()

		env := newPamTestEnv(t)
		env.writeSettings(t, `{"enableU2f":false}`)
		env.writePamFile(t, "login", "#%PAM-1.0\nauth include system-auth\naccount include system-auth\n")
		env.writePamFile(t, "system-auth", "auth sufficient pam_unix.so try_first_pass nullok\naccount required pam_access.so\n")
		env.writePamFile(t, "alpe-u2f", buildManagedLockscreenU2FPamContent())

		err := syncAuthConfigWithDeps(func(string) {}, "", SyncAuthOptions{HomeDir: env.homeDir}, env.deps(false))
		if err != nil {
			t.Fatalf("syncAuthConfigWithDeps returned error: %v", err)
		}

		if _, err := os.Stat(env.alpeU2fPath); !os.IsNotExist(err) {
			t.Fatalf("expected alpe-u2f to be removed, stat err = %v", err)
		}
	})
}

func writeLockscreenFixture(t *testing.T) *pamTestEnv {
	t.Helper()
	env := newPamTestEnv(t)
	env.writePamFile(t, "login", "#%PAM-1.0\nauth include system-auth\naccount include system-auth\n")
	env.writePamFile(t, "system-auth", "auth required pam_unix.so\naccount required pam_unix.so\n")
	return env
}

func TestWriteUserLockscreenPamConfigWritesOtherFallback(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	env := writeLockscreenFixture(t)

	path, err := writeUserLockscreenPamConfig(nil, []string{env.pamDir}, os.ReadFile)
	if err != nil {
		t.Fatalf("WriteUserLockscreenPamConfig: %v", err)
	}

	dir := UserLockscreenPamDir()
	if filepath.Dir(path) != dir {
		t.Fatalf("service written to %s, want a file in %s", path, dir)
	}

	fallback := filepath.Join(dir, UserLockscreenPamFallbackService)
	data, err := os.ReadFile(fallback)
	if err != nil {
		t.Fatalf("pam_start_confdir needs an %q service alongside %q: %v", UserLockscreenPamFallbackService, UserLockscreenPamService, err)
	}
	if string(data) != userLockscreenPamFallbackContent {
		t.Fatalf("fallback content:\n%s\nwant:\n%s", data, userLockscreenPamFallbackContent)
	}
	for _, phase := range []string{"auth", "account", "password", "session"} {
		if !strings.Contains(string(data), phase+" ") {
			t.Errorf("fallback is missing a %s rule, so PAM would fall through", phase)
		}
	}
}

func TestWriteUserLockscreenPamConfigIsIdempotent(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	env := writeLockscreenFixture(t)

	if _, err := writeUserLockscreenPamConfig(nil, []string{env.pamDir}, os.ReadFile); err != nil {
		t.Fatalf("first write: %v", err)
	}

	logged := 0
	if _, err := writeUserLockscreenPamConfig(func(string) { logged++ }, []string{env.pamDir}, os.ReadFile); err != nil {
		t.Fatalf("second write: %v", err)
	}
	if logged != 0 {
		t.Errorf("unchanged config logged %d times, want 0 (inotify churn)", logged)
	}
}
