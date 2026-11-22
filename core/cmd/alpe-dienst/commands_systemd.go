package main

import (
	"fmt"
	"github.com/alpe-shell/alpe/core/internal/brand"
	"github.com/alpe-shell/alpe/core/internal/utils"
	"strings"

	"github.com/alpe-shell/alpe/core/internal/config"
	"github.com/alpe-shell/alpe/core/internal/deps"
	"github.com/spf13/cobra"
)

var systemdCompositorFlag string

var systemdCmd = &cobra.Command{
	Use:   "systemd",
	Short: "Start Alpe as a systemd user service with the compositor session",
	Long: `Manage alpe.service for the compositor session.

enable makes the compositor's own session unit want alpe.service, so Alpe starts
with that compositor only: hyprland-session.target. The compositor is the running one, or --compositor.`,
}

var systemdEnableCmd = &cobra.Command{
	Use:   "enable",
	Short: "Start alpe.service with the compositor session",
	Args:  cobra.NoArgs,
	RunE: func(cmd *cobra.Command, args []string) error {
		wm, err := systemdCompositor()
		if err != nil {
			return err
		}
		unit, err := config.EnableSession(wm)
		if err != nil {
			return err
		}
		fmt.Printf("%s starts with %s\n", brand.Unit, unit)
		return nil
	},
}

var systemdDisableCmd = &cobra.Command{
	Use:   "disable",
	Short: "Stop starting alpe.service with any compositor session",
	Args:  cobra.NoArgs,
	RunE: func(cmd *cobra.Command, args []string) error {
		removed, err := config.DisableSession()
		if err != nil {
			return err
		}
		if len(removed) == 0 {
			fmt.Println("alpe.service was not wanted by any compositor session")
		} else {
			fmt.Printf("alpe.service no longer starts with %s\n", strings.Join(removed, ", "))
		}
		return nil
	},
}

var systemdStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show which compositor sessions start alpe.service",
	Args:  cobra.NoArgs,
	Run: func(cmd *cobra.Command, args []string) {
		state := getServiceState(brand.Unit, true)
		if !state.exists {
			fmt.Println("alpe.service: not installed")
			return
		}
		fmt.Printf("alpe.service: %s", state.enabled)
		if state.active != "" {
			fmt.Printf(", %s", state.active)
		}
		fmt.Println()
		wanted := config.SessionWanted()
		if len(wanted) == 0 {
			fmt.Println("Starts with: nothing (run 'alpe-dienst systemd enable')")
			return
		}
		fmt.Printf("Starts with: %s\n", strings.Join(wanted, ", "))
	},
}

func systemdCompositor() (deps.WindowManager, error) {
	if systemdCompositorFlag == "" {
		if wm, ok := config.RunningCompositor(); ok {
			return wm, nil
		}
		if !utils.CommandExists("Hyprland") {
			return 0, fmt.Errorf("no supported compositor found (Hyprland required)")
		}
		systemdCompositorFlag = "hyprland"
	}
	switch strings.ToLower(systemdCompositorFlag) {
	case "hyprland":
		return deps.WindowManagerHyprland, nil
	}
	return 0, fmt.Errorf("unknown compositor %q (hyprland)", systemdCompositorFlag)
}

func init() {
	systemdEnableCmd.Flags().StringVar(&systemdCompositorFlag, "compositor", "", "hyprland (default: the running one)")
	// Plan 6.8: kein --now und kein start/stop/restart; die Unit startet und stoppt «alpe».
	systemdCmd.AddCommand(systemdEnableCmd, systemdDisableCmd, systemdStatusCmd)
}
