package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/alpe-shell/alpe/core/internal/brand"
	"github.com/alpe-shell/alpe/core/internal/clipolicy"
	"github.com/alpe-shell/alpe/core/internal/gpu"
	"github.com/alpe-shell/alpe/core/internal/log"
	"github.com/alpe-shell/alpe/core/internal/server"
	"github.com/alpe-shell/alpe/core/internal/shellembed"
	"github.com/alpe-shell/alpe/core/internal/utils"
	"github.com/duxlabs-dev/dux-go/shellapp"
	"github.com/spf13/afero"
)

var shellApp = shellapp.New(shellapp.Config{
	ID:                     brand.ID,
	EnvPrefix:              brand.EnvPrefix,
	QSAppID:                brand.AppID,
	Version:                Version,
	Embedded:               embeddedShell{},
	Boot:                   bootBackend,
	PreLaunch:              preLaunch,
	ExtraEnv:               shellExtraEnv,
	OnUIExit:               logStartupFailure,
	SessionRestartExitCode: sessionRestartExitCode,
	TryManagedRestart:      refuseUnitRestart,
})

type embeddedShell struct{}

func (embeddedShell) Available() bool { return shellembed.Available() }

func (embeddedShell) Extract(baseDir string) (string, error) { return shellembed.Extract(baseDir) }

func (embeddedShell) Prune(baseDir, keep string) { shellembed.Prune(baseDir, keep) }

type serverBackend struct {
	srv    *server.Server
	done   chan error
	cancel context.CancelFunc
}

func (b *serverBackend) SocketPath() string { return b.srv.SocketPath() }

func (b *serverBackend) Close() {
	b.cancel()
	b.srv.Close()
}

func (b *serverBackend) Done() <-chan error { return b.done }

func bootBackend(ctx context.Context) (shellapp.Backend, error) {
	server.CLIVersion = Version
	noteUnmanaged()

	srv := server.New()
	if err := srv.Listen(); err != nil {
		return nil, err
	}

	ctx, cancel := context.WithCancel(ctx)
	backend := &serverBackend{srv: srv, done: make(chan error, 1), cancel: cancel}
	go srv.WaitReady(ctx)
	go func() {
		defer cancel()
		defer func() {
			if r := recover(); r != nil {
				backend.done <- fmt.Errorf("server panic: %v", r)
			}
		}()
		backend.done <- srv.Serve(false)
	}()

	return backend, nil
}

func preLaunch() {
	go printASCII()
	ensureFontCache()
}

// The elapsed-timer driver keeps the scrolling wallpaper spring in step above 60 Hz,
// but it makes every other animation jump after a dropped frame (#3837).
func scrollingWallpaperConfigured() bool {
	configDir, err := os.UserConfigDir()
	if err != nil {
		return false
	}
	data, err := os.ReadFile(filepath.Join(configDir, brand.DirName, "settings.json"))
	if err != nil {
		return false
	}
	return wantsSimpleAnimationDriver(data)
}

func wantsSimpleAnimationDriver(settings []byte) bool {
	var parsed struct {
		WallpaperFillMode string `json:"wallpaperFillMode"`
	}
	if json.Unmarshal(settings, &parsed) != nil {
		return false
	}
	return parsed.WallpaperFillMode == "Scrolling"
}

// Qt < 6.10 reserves a JS stack slot per object of the shell's whole type tree while
// creating it, which overflows the 4 MiB default and breaks early handlers (#4175).
const qmlJSStackSize = 16 << 20

func shellExtraEnv(string) []string {
	var env []string
	if selfPath, err := os.Executable(); err == nil {
		env = append(env, brand.Env("EXECUTABLE")+"="+selfPath)
	}
	if os.Getenv("QSG_USE_SIMPLE_ANIMATION_DRIVER") == "" && scrollingWallpaperConfigured() {
		env = append(env, "QSG_USE_SIMPLE_ANIMATION_DRIVER=1")
	}
	if _, set := os.LookupEnv("MALLOC_CONF"); !set {
		env = append(env, "MALLOC_CONF=thp:never,narenas:4,dirty_decay_ms:3000")
	}
	if os.Getenv("QV4_JS_MAX_STACK_SIZE") == "" {
		env = append(env, "QV4_JS_MAX_STACK_SIZE="+strconv.Itoa(qmlJSStackSize))
	}
	env = append(env, gpu.ShellEnv()...)
	policyEnv, err := clipolicy.ShellEnv(afero.NewOsFs())
	if err != nil {
		log.Errorf("CLI policy unreadable, enforcing every shell switch and ignoring its lock settings: %v", err)
	}
	env = append(env, policyEnv...)
	// systemd user services miss the login shell PATH, so tools in ~/.local/bin
	// (herdr, pip/cargo installs) would be invisible to the shell and its children.
	for _, entry := range utils.EnvWithUserBinPath(nil) {
		if strings.HasPrefix(entry, "PATH=") {
			env = append(env, entry)
		}
	}
	return env
}
