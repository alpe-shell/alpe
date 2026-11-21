package drives

import (
	"os"
	"os/exec"
	"path/filepath"

	"github.com/alpe-shell/alpe/core/internal/osinfo"
)

// Alpe: nur die Paketverwaltungen der unterstützten Systeme (Plan 0.5 Nr. 1).
var installCommands = map[osinfo.Family]string{
	osinfo.FamilyArch:   "sudo pacman -S smartmontools",
	osinfo.FamilyFedora: "sudo dnf install smartmontools",
}

// smartctlPath also checks sbin directories, which are often missing from a user's PATH.
func smartctlPath() string {
	if p, err := exec.LookPath("smartctl"); err == nil {
		if abs, err := filepath.Abs(p); err == nil {
			return abs
		}
	}
	for _, p := range []string{"/usr/sbin/smartctl", "/sbin/smartctl"} {
		if fi, err := os.Stat(p); err == nil && !fi.IsDir() && fi.Mode()&0o111 != 0 {
			return p
		}
	}
	return ""
}

func installCommand() string {
	info, err := osinfo.Get()
	if err != nil || info.Immutable {
		return ""
	}
	return installCommands[info.Family]
}
