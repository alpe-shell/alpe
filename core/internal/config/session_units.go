package config

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/alpe-shell/alpe/core/internal/deps"
)

// dms.service is wanted by the compositor's own session unit rather than enabled
// for graphical-session.target, so it never starts under GNOME or KDE on the same user.
const HyprlandSessionTarget = "hyprland-session.target"

var sessionUnits = []string{HyprlandSessionTarget}

var systemctlUser = func(args ...string) error {
	output, err := exec.Command("systemctl", append([]string{"--user"}, args...)...).CombinedOutput()
	if err == nil {
		return nil
	}
	if detail := strings.TrimSpace(string(output)); detail != "" {
		return fmt.Errorf("%s: %w", detail, err)
	}
	return err
}

// SessionUnitName is the unit dms.service is wanted by under wm, with no side effects.
func SessionUnitName(wm deps.WindowManager) string {
	switch wm {
	case deps.WindowManagerHyprland:
		return HyprlandSessionTarget
	}
	return ""
}

// SessionUnit returns the unit dms.service should be wanted by under wm, making sure it
// exists. Hyprland before 0.57 gets our target written.
func SessionUnit(wm deps.WindowManager) (string, error) {
	switch wm {
	case deps.WindowManagerHyprland:
		if _, err := EnsureHyprlandSessionTarget(); err != nil {
			return "", fmt.Errorf("write %s: %w", HyprlandSessionTarget, err)
		}
		return HyprlandSessionTarget, nil
	}
	return "", fmt.Errorf("unsupported compositor %v", wm)
}

// WantsLink is the add-wants symlink that starts dms.service with unit.
func WantsLink(unit string) string {
	return filepath.Join(os.Getenv("HOME"), ".config", "systemd", "user", unit+".wants", "dms.service")
}

// SessionWanted lists the compositor units that currently pull dms.service in.
func SessionWanted() []string {
	var wanted []string
	for _, unit := range sessionUnits {
		if _, err := os.Lstat(WantsLink(unit)); err == nil {
			wanted = append(wanted, unit)
		}
	}
	return wanted
}

// EnableSession makes wm's session unit want dms.service and returns that unit.
func EnableSession(wm deps.WindowManager) (string, error) {
	unit, err := SessionUnit(wm)
	if err != nil {
		return "", err
	}
	if err := systemctlUser("add-wants", unit, "dms"); err != nil {
		return unit, fmt.Errorf("add-wants %s dms: %w", unit, err)
	}
	return unit, nil
}

// DisableSession drops dms.service from every compositor session unit and returns the ones it was wanted by.
func DisableSession() ([]string, error) {
	var removed []string
	for _, unit := range sessionUnits {
		if err := os.Remove(WantsLink(unit)); err != nil {
			if os.IsNotExist(err) {
				continue
			}
			return removed, err
		}
		removed = append(removed, unit)
	}
	if len(removed) == 0 {
		return nil, nil
	}
	return removed, systemctlUser("daemon-reload")
}

// RunningCompositor identifies the compositor of the current session from its environment.
func RunningCompositor() (deps.WindowManager, bool) {
	switch {
	case os.Getenv("HYPRLAND_INSTANCE_SIGNATURE") != "":
		return deps.WindowManagerHyprland, true
	}
	return 0, false
}

// systemdAutostart makes the compositor session start dms.service and returns false when
// that is not possible, so the deployed config keeps starting DMS itself.
func (cd *ConfigDeployer) systemdAutostart(wm deps.WindowManager, useSystemd bool) bool {
	name := SessionUnitName(wm)
	if !useSystemd {
		if err := os.Remove(WantsLink(name)); err == nil {
			cd.log("Removed dms.service from " + name)
		}
		return false
	}
	unit, err := EnableSession(wm)
	if err != nil {
		cd.log(fmt.Sprintf("Warning: %v; starting DMS from the compositor config instead", err))
		if unit == "" {
			if err := os.Remove(WantsLink(name)); err == nil {
				cd.log("Removed dms.service from " + name)
			}
		}
		return false
	}
	cd.log("DMS starts as dms.service with " + unit)
	return true
}

// An already active session unit ignores a new wants link until next login, so a deploy
// from inside that session starts dms.service itself.
func (cd *ConfigDeployer) startInLiveSession(wm deps.WindowManager) {
	if running, ok := RunningCompositor(); !ok || running != wm {
		return
	}
	if systemctlUser("is-active", "--quiet", SessionUnitName(wm)) != nil {
		return
	}
	if err := systemctlUser("start", "--no-block", "dms.service"); err != nil {
		cd.log(fmt.Sprintf("Warning: failed to start dms.service: %v", err))
		return
	}
	cd.log("Started dms.service in the running session")
}
