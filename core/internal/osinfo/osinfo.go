// Package osinfo liest, auf welchem System der Dienst läuft. Alpe: ersetzt den Installer für
// zehn Distributionen (internal/distros, Plan 0.5 Nr. 1); unterstützt sind CachyOS/Arch und
// Fedora (Asahi Remix), alles andere wird nur angezeigt.
package osinfo

import (
	"bufio"
	"fmt"
	"runtime"
	"slices"
	"strings"

	"github.com/spf13/afero"
)

// Family ist die Paketfamilie, soweit Alpe sie kennt.
type Family string

const (
	FamilyArch    Family = "arch"
	FamilyFedora  Family = "fedora"
	FamilyUnknown Family = ""
)

type Info struct {
	ID              string
	IDLike          []string
	VersionID       string
	PrettyName      string
	Architecture    string
	Family          Family
	Immutable       bool
	ImmutableReason string
}

// Get liest /etc/os-release.
func Get() (*Info, error) {
	return get(afero.NewOsFs(), runtime.GOARCH)
}

func get(fs afero.Fs, arch string) (*Info, error) {
	values := readOSRelease(fs)
	if len(values) == 0 {
		return nil, fmt.Errorf("cannot read /etc/os-release")
	}
	info := &Info{
		ID:           values["ID"],
		IDLike:       strings.Fields(values["ID_LIKE"]),
		VersionID:    values["VERSION_ID"],
		PrettyName:   values["PRETTY_NAME"],
		Architecture: arch,
	}
	if info.VersionID == "" {
		info.VersionID = values["BUILD_ID"]
	}
	info.Family = familyOf(info.ID, info.IDLike)
	info.Immutable, info.ImmutableReason = detectImmutable(fs, values)
	return info, nil
}

func familyOf(id string, idLike []string) Family {
	ids := append([]string{id}, idLike...)
	switch {
	case slices.Contains(ids, "arch"):
		return FamilyArch
	case slices.Contains(ids, "fedora"):
		return FamilyFedora
	default:
		return FamilyUnknown
	}
}

// DetectImmutable meldet, ob das System image-basiert ist (ostree, transactional-update, …).
func DetectImmutable() (bool, string) {
	fs := afero.NewOsFs()
	return detectImmutable(fs, readOSRelease(fs))
}

// Markers only reached when /run/ostree-booted is absent, such as a chroot.
var immutableIDs = map[string]bool{
	"bluefin":          true,
	"bazzite":          true,
	"aurora":           true,
	"secureblue":       true,
	"zirconium":        true,
	"fedora-iot":       true,
	"fedora-coreos":    true,
	"opensuse-microos": true,
	"opensuse-aeon":    true,
	"steamos":          true,
	"org.gnome.os":     true,
	"blendos":          true,
	"arkane":           true,
}

var immutableVariantMarkers = []string{"silverblue", "kinoite", "sericea", "onyx", "atomic", "coreos", "iot"}

var immutableMarkerFiles = []struct {
	path   string
	reason string
}{
	{"/run/ostree-booted", "ostree-based system"},
	{"/usr/sbin/transactional-update", "transactional-update system"},
	{"/usr/bin/abroot", "ABRoot system"},
}

func detectImmutable(fs afero.Fs, osRelease map[string]string) (bool, string) {
	for _, marker := range immutableMarkerFiles {
		if exists, _ := afero.Exists(fs, marker.path); exists {
			return true, fmt.Sprintf("%s (%s)", marker.reason, marker.path)
		}
	}

	id := strings.ToLower(osRelease["ID"])
	if immutableIDs[id] {
		return true, "os-release ID=" + id
	}

	variantID := strings.ToLower(osRelease["VARIANT_ID"])
	for _, marker := range immutableVariantMarkers {
		if strings.Contains(variantID, marker) {
			return true, "os-release VARIANT_ID=" + variantID
		}
	}

	for _, like := range strings.Fields(strings.ToLower(osRelease["ID_LIKE"])) {
		if like == "microos" || like == "ostree" {
			return true, "os-release ID_LIKE=" + like
		}
	}

	return false, ""
}

func readOSRelease(fs afero.Fs) map[string]string {
	values := make(map[string]string)
	file, err := fs.Open("/etc/os-release")
	if err != nil {
		return values
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		parts := strings.SplitN(scanner.Text(), "=", 2)
		if len(parts) != 2 {
			continue
		}
		values[strings.TrimSpace(parts[0])] = strings.Trim(strings.TrimSpace(parts[1]), "\"'")
	}
	return values
}
