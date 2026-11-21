package plugins

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"github.com/alpe-shell/alpe/core/internal/brand"
	"os"
	"path/filepath"
	"strings"

	"github.com/alpe-shell/alpe/core/internal/log"
	"github.com/spf13/afero"
)

type Manager struct {
	fs         afero.Fs
	pluginsDir string
	lockPath   string
	gitClient  GitClient
}

func NewManager() (*Manager, error) {
	return NewManagerWithFs(afero.NewOsFs())
}

func NewManagerWithFs(fs afero.Fs) (*Manager, error) {
	pluginsDir := getPluginsDir()
	return &Manager{
		fs:         fs,
		pluginsDir: pluginsDir,
		lockPath:   getPluginLockPath(),
		gitClient:  &realGitClient{},
	}, nil
}

func getPluginsDir() string {
	configDir, err := os.UserConfigDir()
	if err != nil {
		log.Error("failed to get user config dir", "err", err)
		return ""
	}
	path := filepath.Join(configDir, brand.DirName, "plugins")
	if resolved, err := filepath.EvalSymlinks(path); err == nil {
		return resolved
	}
	if resolved, err := filepath.EvalSymlinks(filepath.Dir(path)); err == nil {
		return filepath.Join(resolved, "plugins")
	}
	return path
}

func getPluginLockPath() string {
	configDir, err := os.UserConfigDir()
	if err != nil {
		log.Error("failed to get user config dir", "err", err)
		return ""
	}
	return filepath.Join(configDir, brand.DirName, "plugins.lock.json")
}

func (m *Manager) findInstalledPath(pluginID string) (string, error) {
	// Check user plugins directory
	path, err := m.findInDir(m.pluginsDir, pluginID)
	if err != nil {
		return "", err
	}
	if path != "" {
		return path, nil
	}

	// Check system plugins directory
	systemDir := "/etc/xdg/quickshell/dms-plugins"
	return m.findInDir(systemDir, pluginID)
}

// isSafePluginPathComponent rejects ids that aren't a single path component,
// so filepath.Join can't resolve (and later RemoveAll) outside the plugins dir
func isSafePluginPathComponent(s string) bool {
	if s == "" || s == "." || s == ".." {
		return false
	}
	return !strings.ContainsAny(s, "/\\")
}

func (m *Manager) findInDir(dir, pluginID string) (string, error) {
	if !isSafePluginPathComponent(pluginID) {
		return "", fmt.Errorf("invalid plugin id: %q", pluginID)
	}

	// First, check if folder with exact ID name exists
	exactPath := filepath.Join(dir, pluginID)
	if exists, _ := afero.DirExists(m.fs, exactPath); exists {
		return exactPath, nil
	}

	// Scan all folders and check plugin.json for matching ID
	exists, err := afero.DirExists(m.fs, dir)
	if err != nil || !exists {
		return "", nil
	}

	entries, err := afero.ReadDir(m.fs, dir)
	if err != nil {
		return "", nil
	}

	for _, entry := range entries {
		name := entry.Name()
		if name == ".repos" || strings.HasSuffix(name, ".meta") {
			continue
		}

		fullPath := filepath.Join(dir, name)
		isPlugin := entry.IsDir() || entry.Mode()&os.ModeSymlink != 0
		if !isPlugin {
			if info, err := m.fs.Stat(fullPath); err == nil && info.IsDir() {
				isPlugin = true
			}
		}

		if isPlugin && m.getPluginID(fullPath) == pluginID {
			return fullPath, nil
		}
	}

	return "", nil
}

func (m *Manager) Uninstall(plugin Plugin) error {
	lock, err := m.ensureLockfile()
	if err != nil {
		return err
	}
	if locked, ok := lock.Plugins[plugin.ID]; ok {
		plugin.Repo = locked.Repo
		plugin.Path = locked.Path
	}

	pluginPath, err := m.findInstalledPath(plugin.ID)
	if err != nil {
		return fmt.Errorf("failed to find plugin: %w", err)
	}

	if pluginPath == "" {
		return fmt.Errorf("plugin not installed: %s", plugin.Name)
	}

	if strings.HasPrefix(pluginPath, "/etc/xdg/quickshell/dms-plugins") {
		return fmt.Errorf("cannot uninstall system plugin: %s", plugin.Name)
	}
	updatedLock := lock.Clone()
	delete(updatedLock.Plugins, plugin.ID)
	if err := m.lockStore().Write(updatedLock); err != nil {
		return err
	}
	rollbackLock := func(err error) error {
		if rollbackErr := m.lockStore().Write(lock); rollbackErr != nil {
			return fmt.Errorf("%w (also failed to restore plugin lockfile: %v)", err, rollbackErr)
		}
		return err
	}

	metaPath := pluginPath + ".meta"
	if plugin.Path != "" {
		reposDir := filepath.Join(m.pluginsDir, ".repos")
		repoName := m.getRepoName(plugin.Repo)
		repoPath := filepath.Join(reposDir, repoName)

		shouldCleanup, err := m.shouldCleanupRepo(plugin.Repo, plugin.ID)
		if err != nil {
			return rollbackLock(fmt.Errorf("failed to check repo cleanup: %w", err))
		}

		if err := m.fs.Remove(pluginPath); err != nil {
			return rollbackLock(fmt.Errorf("failed to remove symlink: %w", err))
		}

		if metaExists, _ := afero.Exists(m.fs, metaPath); metaExists {
			if err := m.fs.Remove(metaPath); err != nil {
				return rollbackLock(fmt.Errorf("failed to remove metadata: %w", err))
			}
		}

		if shouldCleanup {
			if err := m.fs.RemoveAll(repoPath); err != nil {
				return rollbackLock(fmt.Errorf("failed to cleanup repository: %w", err))
			}
		}
	} else {
		if err := m.fs.RemoveAll(pluginPath); err != nil {
			return rollbackLock(fmt.Errorf("failed to remove plugin: %w", err))
		}
	}

	return nil
}

func (m *Manager) shouldCleanupRepo(repoURL, excludePlugin string) (bool, error) {
	lock, err := m.ensureLockfile()
	if err != nil {
		return false, err
	}
	for id, plugin := range lock.Plugins {
		if id == excludePlugin {
			continue
		}
		if plugin.Repo == repoURL && plugin.Path != "" {
			return false, nil
		}
	}

	return true, nil
}

func (m *Manager) ListInstalled() ([]string, error) {
	installedMap := make(map[string]bool)

	exists, err := afero.DirExists(m.fs, m.pluginsDir)
	if err != nil {
		return nil, err
	}

	if exists {
		entries, err := afero.ReadDir(m.fs, m.pluginsDir)
		if err != nil {
			return nil, fmt.Errorf("failed to read plugins directory: %w", err)
		}

		for _, entry := range entries {
			name := entry.Name()
			if name == ".repos" || strings.HasSuffix(name, ".meta") {
				continue
			}

			fullPath := filepath.Join(m.pluginsDir, name)
			isPlugin := false

			if entry.IsDir() {
				isPlugin = true
			} else if entry.Mode()&os.ModeSymlink != 0 {
				isPlugin = true
			} else {
				info, err := m.fs.Stat(fullPath)
				if err == nil && info.IsDir() {
					isPlugin = true
				}
			}

			if isPlugin {
				// Read plugin.json to get the actual plugin ID
				pluginID := m.getPluginID(fullPath)
				if pluginID != "" {
					installedMap[pluginID] = true
				}
			}
		}
	}

	systemPluginsDir := "/etc/xdg/quickshell/dms-plugins"
	systemExists, err := afero.DirExists(m.fs, systemPluginsDir)
	if err == nil && systemExists {
		entries, err := afero.ReadDir(m.fs, systemPluginsDir)
		if err == nil {
			for _, entry := range entries {
				if entry.IsDir() {
					fullPath := filepath.Join(systemPluginsDir, entry.Name())
					// Read plugin.json to get the actual plugin ID
					pluginID := m.getPluginID(fullPath)
					if pluginID != "" {
						installedMap[pluginID] = true
					}
				}
			}
		}
	}

	var installed []string
	for name := range installedMap {
		installed = append(installed, name)
	}

	return installed, nil
}

// getPluginID reads the plugin.json file and returns the plugin ID
func (m *Manager) getPluginID(pluginPath string) string {
	manifest := m.getPluginManifest(pluginPath)
	if manifest == nil {
		return ""
	}
	return manifest.ID
}

func (m *Manager) getPluginManifest(pluginPath string) *pluginManifest {
	manifestPath := filepath.Join(pluginPath, "plugin.json")
	data, err := afero.ReadFile(m.fs, manifestPath)
	if err != nil {
		return nil
	}

	var manifest pluginManifest
	if err := json.Unmarshal(data, &manifest); err != nil {
		return nil
	}

	return &manifest
}

type pluginManifest struct {
	ID      string           `json:"id"`
	Name    string           `json:"name"`
	Lyrics  *LyricsProvider  `json:"lyrics"`
	Weather *WeatherProvider `json:"weather"`
}

func (m *Manager) GetPluginsDir() string {
	return m.pluginsDir
}

func (m *Manager) UninstallByIDOrName(idOrName string) error {
	pluginPath, err := m.findInstalledPathByIDOrName(idOrName)
	if err != nil {
		return err
	}
	if pluginPath == "" {
		return fmt.Errorf("plugin not found: %s", idOrName)
	}

	if strings.HasPrefix(pluginPath, "/etc/xdg/quickshell/dms-plugins") {
		return fmt.Errorf("cannot uninstall system plugin: %s", idOrName)
	}
	manifest := m.getPluginManifest(pluginPath)
	if manifest != nil {
		lock, err := m.ensureLockfile()
		if err != nil {
			return err
		}
		if locked, ok := lock.Plugins[manifest.ID]; ok {
			return m.Uninstall(Plugin{ID: manifest.ID, Name: manifest.Name, Repo: locked.Repo, Path: locked.Path})
		}
	}

	metaPath := pluginPath + ".meta"
	metaExists, _ := afero.Exists(m.fs, metaPath)

	if metaExists {
		if err := m.fs.Remove(pluginPath); err != nil {
			return fmt.Errorf("failed to remove symlink: %w", err)
		}
		if err := m.fs.Remove(metaPath); err != nil {
			return fmt.Errorf("failed to remove metadata: %w", err)
		}
	} else {
		if err := m.fs.RemoveAll(pluginPath); err != nil {
			return fmt.Errorf("failed to remove plugin: %w", err)
		}
	}

	return nil
}

func (m *Manager) findInstalledPathByIDOrName(idOrName string) (string, error) {
	path, err := m.findInDirByIDOrName(m.pluginsDir, idOrName)
	if err != nil {
		return "", err
	}
	if path != "" {
		return path, nil
	}

	systemDir := "/etc/xdg/quickshell/dms-plugins"
	return m.findInDirByIDOrName(systemDir, idOrName)
}

func (m *Manager) findInDirByIDOrName(dir, idOrName string) (string, error) {
	if !isSafePluginPathComponent(idOrName) {
		return "", fmt.Errorf("invalid plugin id/name: %q", idOrName)
	}

	// Check exact folder name match first
	exactPath := filepath.Join(dir, idOrName)
	if exists, _ := afero.DirExists(m.fs, exactPath); exists {
		return exactPath, nil
	}

	exists, err := afero.DirExists(m.fs, dir)
	if err != nil || !exists {
		return "", nil
	}

	entries, err := afero.ReadDir(m.fs, dir)
	if err != nil {
		return "", nil
	}

	for _, entry := range entries {
		name := entry.Name()
		if name == ".repos" || strings.HasSuffix(name, ".meta") {
			continue
		}

		fullPath := filepath.Join(dir, name)
		isPlugin := entry.IsDir() || entry.Mode()&os.ModeSymlink != 0
		if !isPlugin {
			if info, err := m.fs.Stat(fullPath); err == nil && info.IsDir() {
				isPlugin = true
			}
		}

		if !isPlugin {
			continue
		}

		manifest := m.getPluginManifest(fullPath)
		if manifest == nil {
			continue
		}

		if manifest.ID == idOrName || manifest.Name == idOrName {
			return fullPath, nil
		}
	}

	return "", nil
}

func (m *Manager) getRepoName(repoURL string) string {
	hash := sha256.Sum256([]byte(repoURL))
	return hex.EncodeToString(hash[:])[:16]
}
