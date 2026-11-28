package clipolicy

import (
	"encoding/json"
	"fmt"
	"os"
	"slices"
	"strings"
	"sync"

	"github.com/alpe-shell/alpe/core/internal/log"
	"github.com/spf13/afero"
)

// Richtlinien des Pakets und des Administrators (Plan 0.8 Nr. 16): eigene Pfade, keine des Pakets des Ursprungs.
const (
	PackagedPath = "/usr/share/alpe/cli-policy.json"
	AdminPath    = "/etc/alpe/cli-policy.json"
)

// Rückfall (Entscheid vom 25.11.2026, Plan 0.8 Nr. 119): Solange AdminPath fehlt, gilt die Richtlinie des
// Administrators aus 1.0, mit einer Meldung – sonst fielen ihre Schalter für die Sperre ohne Meldung weg. Nur der
// Pfad des Administrators; die Richtlinie des Pakets von 1.0 unter /usr/share wird nie gelesen.
// alpe-namen-ausnahme: umzug-ende
const LegacyAdminPath = "/etc/dms/cli-policy.json"

// warnLegacyAdmin meldet den Rückfall; Tests ersetzen die Funktion, um die Meldung zu sehen.
var warnLegacyAdmin = func(format string, v ...any) { log.Warnf(format, v...) }

// legacyWarnOnce: Die Meldung kommt einmal je Prozess, nicht bei jedem Laden (Plan 0.8 Nr. 139 (1); vorher bis zu
// dreimal je Start). Tests setzen ein neues sync.Once.
var legacyWarnOnce = &sync.Once{}

// LegacyAdminInUse sagt, ob der Rückfall gilt: AdminPath fehlt und LegacyAdminPath gibt es (oder lässt sich nicht
// prüfen). Ohne Meldung – für «alpe-dienst doctor».
func LegacyAdminInUse(fs afero.Fs) bool {
	if _, err := fs.Stat(AdminPath); err == nil || !os.IsNotExist(err) {
		return false
	}
	// Nur «fehlt» heisst: kein Rückfall. Ein anderer Fehler (etwa keine Leserechte) gilt als Rückfall, damit
	// LoadFile den Lesefehler meldet und die Schalter sicher eingeschaltet werden, statt dass die Richtlinie still
	// wegfällt.
	if _, err := fs.Stat(LegacyAdminPath); os.IsNotExist(err) {
		return false
	}
	return true
}

// EffectiveAdminPath ist AdminPath, ausser AdminPath fehlt und LegacyAdminPath gibt es: dann LegacyAdminPath, mit
// einer Meldung (einmal je Prozess). Fehlen beide, AdminPath.
func EffectiveAdminPath(fs afero.Fs) string {
	if !LegacyAdminInUse(fs) {
		return AdminPath
	}
	legacyWarnOnce.Do(func() {
		warnLegacyAdmin("CLI policy: %s is missing, using the policy of Alpe 1.0 from %s. Copy it to %s to keep it; the old path is read only until the move from 1.0 is finished.",
			AdminPath, LegacyAdminPath, AdminPath)
	})
	return LegacyAdminPath
}

// alpe-namen-ausnahme: umzug-ende

type File struct {
	PolicyVersion         int       `json:"policy_version"`
	ImmutableSystem       *bool     `json:"immutable_system"`
	BlockedCommands       *[]string `json:"blocked_commands"`
	Message               *string   `json:"message"`
	DisableLockIPCUnlock  *bool     `json:"disable_lock_ipc_unlock"`
	DisableLogindUnlock   *bool     `json:"disable_logind_unlock"`
	DisableCustomLockPAM  *bool     `json:"disable_custom_lock_pam"`
	DisableUserPlugins    *bool     `json:"disable_user_plugins"`
	DisableSettingsIPCSet *bool     `json:"disable_settings_ipc_set"`

	LockSettings map[string]json.RawMessage `json:"lock_settings"`
}

// shellSwitches reach the shell as ALPE_POLICY_<KEY> in its launch environment.
var shellSwitches = []struct {
	key   string
	value func(*File) *bool
}{
	{"disable_lock_ipc_unlock", func(p *File) *bool { return p.DisableLockIPCUnlock }},
	{"disable_logind_unlock", func(p *File) *bool { return p.DisableLogindUnlock }},
	{"disable_custom_lock_pam", func(p *File) *bool { return p.DisableCustomLockPAM }},
	{"disable_user_plugins", func(p *File) *bool { return p.DisableUserPlugins }},
	{"disable_settings_ipc_set", func(p *File) *bool { return p.DisableSettingsIPCSet }},
}

// lockSettingKeys are the shell settings lock_settings may manage.
var lockSettingKeys = []string{
	"customPowerActionLock",
	"lockBeforeSuspend",
	"loginctlLockIntegration",
	"lockAtStartup",
	"acLockTimeout",
	"batteryLockTimeout",
	"fadeToLockEnabled",
	"fadeToLockGracePeriod",
	"enableFprint",
	"maxFprintTries",
	"enableU2f",
	"u2fMode",
}

// LoadFile returns nil without an error when the file does not exist.
func LoadFile(fs afero.Fs, path string) (*File, error) {
	data, err := afero.ReadFile(fs, path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to read %s: %w", path, err)
	}

	var policy File
	if err := json.Unmarshal(data, &policy); err != nil {
		return nil, fmt.Errorf("failed to parse %s: %w", path, err)
	}

	return &policy, nil
}

// load returns the policy files that exist, PackagedPath first, then the admin policy (EffectiveAdminPath).
func load(fs afero.Fs) ([]*File, error) {
	var policies []*File
	for _, path := range []string{PackagedPath, EffectiveAdminPath(fs)} {
		policy, err := LoadFile(fs, path)
		if err != nil {
			return nil, err
		}
		if policy != nil {
			policies = append(policies, policy)
		}
	}
	return policies, nil
}

// flag reports a boolean key, false unless set. An explicit value in AdminPath
// overrides PackagedPath.
func flag(policies []*File, value func(*File) *bool) bool {
	set := false
	for _, policy := range policies {
		if v := value(policy); v != nil {
			set = *v
		}
	}
	return set
}

// LogindUnlockDisabled reports whether a logind Unlock must leave a lock in
// place. An explicit value in AdminPath overrides PackagedPath.
func LogindUnlockDisabled(fs afero.Fs) (bool, error) {
	policies, err := load(fs)
	if err != nil {
		return false, err
	}
	return flag(policies, func(p *File) *bool { return p.DisableLogindUnlock }), nil
}

// lockSettings merges lock_settings per key, AdminPath over PackagedPath,
// without null values and keys outside lockSettingKeys.
func lockSettings(policies []*File) map[string]json.RawMessage {
	settings := make(map[string]json.RawMessage)
	for _, policy := range policies {
		for key, value := range policy.LockSettings {
			if !slices.Contains(lockSettingKeys, key) {
				log.Warnf("CLI policy: ignoring lock_settings key %q, which is not a managed lock setting", key)
				continue
			}
			if string(value) == "null" {
				continue
			}
			settings[key] = value
		}
	}
	return settings
}

// LockSettings returns the managed lock settings as raw JSON by key. A policy
// file that fails to load manages none, and its error is returned.
func LockSettings(fs afero.Fs) (map[string]json.RawMessage, error) {
	policies, err := load(fs)
	return lockSettings(policies), err
}

// LockSettingBool returns a managed boolean lock setting, or nil when it is
// not managed or not a boolean, which the shell ignores too.
func LockSettingBool(settings map[string]json.RawMessage, key string) *bool {
	var value *bool
	if err := json.Unmarshal(settings[key], &value); err != nil {
		return nil
	}
	return value
}

// ShellEnv returns every shell switch as ALPE_POLICY_<KEY>=1 or 0 and the
// managed lock settings as ALPE_POLICY_LOCK_SETTINGS=<JSON object>, so a value
// inherited by the shell never counts. A policy file that fails to load turns
// every switch on and manages no lock setting, and its error is returned with
// them.
func ShellEnv(fs afero.Fs) ([]string, error) {
	policies, err := load(fs)
	env := make([]string, 0, len(shellSwitches)+1)
	for _, s := range shellSwitches {
		value := "0"
		if err != nil || flag(policies, s.value) {
			value = "1"
		}
		env = append(env, "ALPE_POLICY_"+strings.ToUpper(s.key)+"="+value)
	}
	// The values come from json.Unmarshal, so they marshal.
	settings, _ := json.Marshal(lockSettings(policies))
	env = append(env, "ALPE_POLICY_LOCK_SETTINGS="+string(settings))
	return env, err
}
