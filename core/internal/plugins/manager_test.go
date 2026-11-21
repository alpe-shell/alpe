package plugins

import (
	"path/filepath"
	"testing"

	"github.com/spf13/afero"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func setupTestManager(t *testing.T) (*Manager, afero.Fs, string) {
	t.Helper()
	fs := afero.NewMemMapFs()
	pluginsDir := "/test-plugins"
	manager := &Manager{
		fs:         fs,
		pluginsDir: pluginsDir,
		lockPath:   "/config/plugins.lock.json",
		gitClient:  &mockGitClient{},
	}
	return manager, fs, pluginsDir
}

func TestGetPluginsDir(t *testing.T) {
	t.Run("uses XDG_CONFIG_HOME when set", func(t *testing.T) {
		configHome := t.TempDir()
		t.Setenv("XDG_CONFIG_HOME", configHome)

		assert.Equal(t, filepath.Join(configHome, "alpe", "plugins"), getPluginsDir())
	})

	t.Run("falls back to home directory", func(t *testing.T) {
		home := t.TempDir()
		t.Setenv("XDG_CONFIG_HOME", "")
		t.Setenv("HOME", home)

		assert.Equal(t, filepath.Join(home, ".config", "alpe", "plugins"), getPluginsDir())
	})
}

func TestUninstall(t *testing.T) {
	t.Run("uninstalls plugin successfully", func(t *testing.T) {
		manager, fs, pluginsDir := setupTestManager(t)

		plugin := Plugin{ID: "test-plugin", Name: "TestPlugin"}
		pluginPath := filepath.Join(pluginsDir, plugin.ID)
		err := fs.MkdirAll(pluginPath, 0o755)
		require.NoError(t, err)

		err = manager.Uninstall(plugin)
		assert.NoError(t, err)

		exists, _ := afero.DirExists(fs, pluginPath)
		assert.False(t, exists)
	})

	t.Run("returns error when plugin not installed", func(t *testing.T) {
		manager, _, _ := setupTestManager(t)

		plugin := Plugin{ID: "non-existent", Name: "NonExistent"}
		err := manager.Uninstall(plugin)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "not installed")
	})
}

func TestListInstalled(t *testing.T) {
	t.Run("returns empty list when no plugins installed", func(t *testing.T) {
		manager, _, _ := setupTestManager(t)

		installed, err := manager.ListInstalled()
		assert.NoError(t, err)
		assert.Empty(t, installed)
	})

	t.Run("ignores files and .repos directory", func(t *testing.T) {
		manager, fs, pluginsDir := setupTestManager(t)

		err := fs.MkdirAll(pluginsDir, 0o755)
		require.NoError(t, err)
		err = fs.MkdirAll(filepath.Join(pluginsDir, "Plugin1"), 0o755)
		require.NoError(t, err)
		err = afero.WriteFile(fs, filepath.Join(pluginsDir, "Plugin1", "plugin.json"), []byte(`{"id":"Plugin1"}`), 0o644)
		require.NoError(t, err)
		err = fs.MkdirAll(filepath.Join(pluginsDir, ".repos"), 0o755)
		require.NoError(t, err)
		err = afero.WriteFile(fs, filepath.Join(pluginsDir, "README.md"), []byte("test"), 0o644)
		require.NoError(t, err)

		installed, err := manager.ListInstalled()
		assert.NoError(t, err)
		assert.Len(t, installed, 1)
		assert.Equal(t, "Plugin1", installed[0])
	})
}

func TestUninstallRemovesLockedPlugin(t *testing.T) {
	manager, fs, pluginsDir := setupTestManager(t)
	plugin := Plugin{ID: "test-plugin", Name: "Test Plugin", Repo: "https://github.com/test/plugin.git"}
	pluginPath := filepath.Join(pluginsDir, plugin.ID)
	require.NoError(t, fs.MkdirAll(pluginPath, 0o755))
	require.NoError(t, afero.WriteFile(fs, filepath.Join(pluginPath, "plugin.json"), []byte(`{"id":"test-plugin"}`), 0o644))
	require.NoError(t, manager.lockStore().Write(PluginLockfile{
		LockfileVersion: 1,
		Plugins: map[string]LockedPlugin{
			plugin.ID: {Repo: plugin.Repo, Commit: testCommit},
		},
	}))

	require.NoError(t, manager.Uninstall(plugin))
	lock, err := manager.lockStore().Load()
	require.NoError(t, err)
	assert.NotContains(t, lock.Plugins, plugin.ID)
}

func TestSnapshotLockfileMigratesLegacyMonorepoMetadata(t *testing.T) {
	manager, fs, pluginsDir := setupTestManager(t)
	pluginPath := filepath.Join(pluginsDir, "legacy")
	repoPath := filepath.Join(pluginsDir, ".repos", "legacy-repo")
	require.NoError(t, fs.MkdirAll(pluginPath, 0o755))
	require.NoError(t, fs.MkdirAll(repoPath, 0o755))
	require.NoError(t, afero.WriteFile(fs, filepath.Join(pluginPath, "plugin.json"), []byte(`{"id":"legacy"}`), 0o644))
	require.NoError(t, afero.WriteFile(fs, pluginPath+".meta", []byte("repo=https://github.com/test/suite.git\npath=plugins/legacy\nrepodir=legacy-repo"), 0o644))
	manager.gitClient = &mockGitClient{
		revisionFunc: func(path string) (string, error) {
			assert.Equal(t, repoPath, path)
			return testCommit, nil
		},
	}

	lock, warnings, err := manager.SnapshotLockfile()
	require.NoError(t, err)
	assert.Empty(t, warnings)
	assert.Equal(t, LockedPlugin{
		Repo:   "https://github.com/test/suite.git",
		Path:   "plugins/legacy",
		Commit: testCommit,
	}, lock.Plugins["legacy"])
}

type mockGitClient struct {
	originFunc   func(path string) (string, error)
	revisionFunc func(path string) (string, error)
}

func (m *mockGitClient) OriginURL(path string) (string, error) {
	if m.originFunc != nil {
		return m.originFunc(path)
	}
	return "", nil
}

func (m *mockGitClient) CurrentRevision(path string) (string, error) {
	if m.revisionFunc != nil {
		return m.revisionFunc(path)
	}
	return testCommit, nil
}
