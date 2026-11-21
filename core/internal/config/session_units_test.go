package config

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestDisableSessionRemovesEveryWantsLink(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	for _, unit := range []string{HyprlandSessionTarget} {
		link := WantsLink(unit)
		require.NoError(t, os.MkdirAll(filepath.Dir(link), 0o755))
		require.NoError(t, os.Symlink("/dev/null", link))
	}
	var reloads int
	prev := systemctlUser
	systemctlUser = func(args ...string) error {
		if args[0] == "daemon-reload" {
			reloads++
		}
		return nil
	}
	t.Cleanup(func() { systemctlUser = prev })

	assert.Equal(t, []string{HyprlandSessionTarget}, SessionWanted())
	removed, err := DisableSession()
	require.NoError(t, err)
	assert.Equal(t, []string{HyprlandSessionTarget}, removed)
	assert.Empty(t, SessionWanted())
	assert.Equal(t, 1, reloads)

	removed, err = DisableSession()
	require.NoError(t, err)
	assert.Nil(t, removed)
	assert.Equal(t, 1, reloads)
}
