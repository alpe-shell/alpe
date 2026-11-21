package plugins

import (
	"fmt"
	"path/filepath"
	"strings"

	"github.com/spf13/afero"
)

func (m *Manager) lockStore() *LockStore {
	lockPath := m.lockPath
	if lockPath == "" {
		lockPath = filepath.Join(filepath.Dir(m.pluginsDir), "plugins.lock.json")
	}
	return NewLockStore(m.fs, lockPath)
}

func (m *Manager) GetLockfilePath() string {
	return m.lockStore().Path()
}

func (m *Manager) EnsureLockfile() error {
	_, err := m.ensureLockfile()
	return err
}

func (m *Manager) ensureLockfile() (PluginLockfile, error) {
	store := m.lockStore()
	exists, err := store.Exists()
	if err != nil {
		return PluginLockfile{}, fmt.Errorf("failed to check plugin lockfile: %w", err)
	}
	if exists {
		return store.Load()
	}

	lock, _, err := m.SnapshotLockfile()
	if err != nil {
		return PluginLockfile{}, err
	}
	if err := store.Write(lock); err != nil {
		return PluginLockfile{}, err
	}
	return lock, nil
}

func (m *Manager) SnapshotLockfile() (PluginLockfile, []string, error) {
	lock := NewPluginLockfile()
	warnings := []string{}

	exists, err := afero.DirExists(m.fs, m.pluginsDir)
	if err != nil {
		return PluginLockfile{}, nil, fmt.Errorf("failed to check plugins directory: %w", err)
	}
	if !exists {
		return lock, warnings, nil
	}

	entries, err := afero.ReadDir(m.fs, m.pluginsDir)
	if err != nil {
		return PluginLockfile{}, nil, fmt.Errorf("failed to read plugins directory: %w", err)
	}

	for _, entry := range entries {
		name := entry.Name()
		if name == ".repos" || strings.HasSuffix(name, ".meta") {
			continue
		}

		pluginPath := filepath.Join(m.pluginsDir, name)
		manifest := m.getPluginManifest(pluginPath)
		if manifest == nil || manifest.ID == "" {
			continue
		}

		locked, repoPath, err := m.lockedPluginFromInstall(pluginPath)
		if err != nil {
			warnings = append(warnings, fmt.Sprintf("%s: %v", manifest.ID, err))
			continue
		}
		commit, err := m.gitClient.CurrentRevision(repoPath)
		if err != nil {
			warnings = append(warnings, fmt.Sprintf("%s: cannot read git revision: %v", manifest.ID, err))
			continue
		}
		locked.Commit = commit
		lock.SetRepositoryCommit(locked.Repo, commit)
		lock.Plugins[manifest.ID] = locked
	}

	if err := lock.Validate(); err != nil {
		return PluginLockfile{}, warnings, err
	}
	return lock, warnings, nil
}

func (m *Manager) lockedPluginFromInstall(pluginPath string) (LockedPlugin, string, error) {
	metaPath := pluginPath + ".meta"
	if metaExists, _ := afero.Exists(m.fs, metaPath); metaExists {
		data, err := afero.ReadFile(m.fs, metaPath)
		if err != nil {
			return LockedPlugin{}, "", fmt.Errorf("failed to read legacy metadata: %w", err)
		}
		metadata := parseLegacyPluginMetadata(string(data))
		repo := metadata["repo"]
		path := metadata["path"]
		repoDir := metadata["repodir"]
		if repo == "" || repoDir == "" {
			return LockedPlugin{}, "", fmt.Errorf("legacy metadata is incomplete")
		}
		if err := validatePluginRepo(repo); err != nil {
			return LockedPlugin{}, "", err
		}
		if !isSafePluginPathComponent(repoDir) {
			return LockedPlugin{}, "", fmt.Errorf("legacy repository directory is invalid")
		}
		if err := validatePluginRepoPath(path); err != nil {
			return LockedPlugin{}, "", err
		}
		return LockedPlugin{Repo: repo, Path: path}, filepath.Join(m.pluginsDir, ".repos", repoDir), nil
	}

	repo, err := m.gitClient.OriginURL(pluginPath)
	if err != nil {
		return LockedPlugin{}, "", fmt.Errorf("plugin is not a managed git checkout")
	}
	if err := validatePluginRepo(repo); err != nil {
		return LockedPlugin{}, "", err
	}
	return LockedPlugin{Repo: repo}, pluginPath, nil
}

func parseLegacyPluginMetadata(data string) map[string]string {
	metadata := make(map[string]string)
	for line := range strings.SplitSeq(data, "\n") {
		key, value, ok := strings.Cut(line, "=")
		if ok {
			metadata[strings.TrimSpace(key)] = strings.TrimSpace(value)
		}
	}
	return metadata
}

func (m *Manager) repositoryPath(pluginID string, plugin LockedPlugin) string {
	if plugin.Path != "" {
		return filepath.Join(m.pluginsDir, ".repos", m.getRepoName(plugin.Repo))
	}
	if installedPath, err := m.findInDir(m.pluginsDir, pluginID); err == nil && installedPath != "" {
		return installedPath
	}
	return filepath.Join(m.pluginsDir, pluginID)
}
