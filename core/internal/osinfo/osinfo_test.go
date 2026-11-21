package osinfo

import (
	"testing"

	"github.com/spf13/afero"
)

func osRelease(t *testing.T, content string, extra ...string) afero.Fs {
	t.Helper()
	fs := afero.NewMemMapFs()
	if err := afero.WriteFile(fs, "/etc/os-release", []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	for _, path := range extra {
		if err := afero.WriteFile(fs, path, nil, 0o644); err != nil {
			t.Fatal(err)
		}
	}
	return fs
}

func TestGetSupportedSystems(t *testing.T) {
	tests := []struct {
		name, content string
		family        Family
		pretty        string
	}{
		{"CachyOS", "NAME=\"CachyOS Linux\"\nPRETTY_NAME=\"CachyOS\"\nID=cachyos\nID_LIKE=arch\nBUILD_ID=rolling\n", FamilyArch, "CachyOS"},
		{"Arch", "PRETTY_NAME=\"Arch Linux\"\nID=arch\n", FamilyArch, "Arch Linux"},
		{"Fedora Asahi Remix", "PRETTY_NAME=\"Fedora Linux Asahi Remix 44\"\nID=fedora-asahi-remix\nID_LIKE=fedora\nVERSION_ID=44\n", FamilyFedora, "Fedora Linux Asahi Remix 44"},
		{"Debian bleibt unbekannt", "PRETTY_NAME=\"Debian GNU/Linux 13\"\nID=debian\n", FamilyUnknown, "Debian GNU/Linux 13"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			info, err := get(osRelease(t, tt.content), "arm64")
			if err != nil {
				t.Fatal(err)
			}
			if info.Family != tt.family || info.PrettyName != tt.pretty || info.Architecture != "arm64" {
				t.Fatalf("got %+v", info)
			}
			if info.Immutable {
				t.Fatalf("%s gilt fälschlich als image-basiert: %s", tt.name, info.ImmutableReason)
			}
		})
	}
}

func TestBuildIDStandsInForVersion(t *testing.T) {
	info, err := get(osRelease(t, "ID=cachyos\nID_LIKE=arch\nBUILD_ID=rolling\n"), "amd64")
	if err != nil || info.VersionID != "rolling" {
		t.Fatalf("VersionID = %q, err %v", info.VersionID, err)
	}
}

func TestMissingOSReleaseIsAnError(t *testing.T) {
	if _, err := get(afero.NewMemMapFs(), "amd64"); err == nil {
		t.Fatal("ohne /etc/os-release muss get scheitern")
	}
}

func TestDetectImmutable(t *testing.T) {
	tests := []struct {
		name, content string
		files         []string
		want          bool
	}{
		{"ostree-Marke", "ID=fedora\n", []string{"/run/ostree-booted"}, true},
		{"Kinoite", "ID=fedora\nVARIANT_ID=kinoite\n", nil, true},
		{"Bazzite", "ID=bazzite\nID_LIKE=fedora\n", nil, true},
		{"Fedora Workstation", "ID=fedora\nVARIANT_ID=workstation\n", nil, false},
		{"CachyOS", "ID=cachyos\nID_LIKE=arch\n", nil, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			fs := osRelease(t, tt.content, tt.files...)
			got, reason := detectImmutable(fs, readOSRelease(fs))
			if got != tt.want {
				t.Fatalf("detectImmutable = %v (%s), want %v", got, reason, tt.want)
			}
		})
	}
}
