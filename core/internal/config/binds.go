package config

import "github.com/duxlabs-dev/dux-shell/core/internal/deps"

// BindsConfigType is the replaceConfigs key choosing stock DMS binds over the user's.
const BindsConfigType = "Keybinds"

// SetReplaceBinds picks the DMS stock binds over existing ones; existing binds are kept by default.
func (cd *ConfigDeployer) SetReplaceBinds(replace bool) {
	cd.replaceBinds = replace
}

// ExistingBinds returns where the user's keybinds for wm live, if any. Hyprland
// has none to keep: its binds.lua is DMS-owned and user binds sit in binds-user.lua.
func ExistingBinds(wm deps.WindowManager) (string, bool) {
	return "", false
}
