package main

import (
	"fmt"
	"github.com/alpe-shell/alpe/core/internal/brand"

	"github.com/alpe-shell/alpe/core/internal/log"
	"github.com/alpe-shell/alpe/core/internal/plugins"
	"github.com/alpe-shell/alpe/core/internal/server"
	"github.com/alpe-shell/alpe/core/internal/site"
	"github.com/spf13/cobra"
)

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Show version information",
	Run:   runVersion,
}

var ipcCmd = &cobra.Command{
	Use:   "ipc",
	Short: "Send IPC commands to running Alpe shell",
	Long: `Send IPC commands to the running Alpe shell.

  alpe-dienst ipc call <target> <function> [args...]   invoke a command
  alpe-dienst ipc list                                 list all targets and functions

Full reference: ` + site.Docs + "/dms/keybinds-ipc",
	ValidArgsFunction: func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
		return getShellIPCCompletions(args, toComplete), cobra.ShellCompDirectiveNoFileComp
	},
	Run: func(cmd *cobra.Command, args []string) {
		runShellIPCCommand(args)
	},
}

var ipcListCmd = &cobra.Command{
	Use:   "list",
	Short: "List all IPC targets and functions",
	Run: func(cmd *cobra.Command, args []string) {
		printIPCHelp()
	},
}

func init() {
	ipcCmd.AddCommand(ipcListCmd)
	ipcCmd.SetHelpFunc(func(cmd *cobra.Command, args []string) {
		printIPCHelp()
	})
}

var debugSrvCmd = &cobra.Command{
	Use:   "debug-srv",
	Short: "Start the debug server",
	Long:  "Start the Unix socket debug server for Alpe",
	Run: func(cmd *cobra.Command, args []string) {
		if err := startDebugServer(); err != nil {
			log.Fatalf("Error starting debug server: %v", err)
		}
	},
}

var pluginsCmd = &cobra.Command{
	Use:   "plugins",
	Short: "Manage Alpe plugins",
	Long:  "List and remove locally installed Alpe plugins",
}

var pluginsListCmd = &cobra.Command{
	Use:   "list",
	Short: "List installed plugins",
	Long:  "List all installed Alpe plugins",
	Run: func(cmd *cobra.Command, args []string) {
		if err := listInstalledPlugins(); err != nil {
			log.Fatalf("Error listing plugins: %v", err)
		}
	},
}

var pluginsUninstallCmd = &cobra.Command{
	Use:   "uninstall <plugin-id>",
	Short: "Uninstall a plugin by ID",
	Long:  "Uninstall an Alpe plugin using its ID (e.g., 'myPlugin'). Plugin names with spaces are also supported for backward compatibility.",
	Args:  cobra.ExactArgs(1),
	ValidArgsFunction: func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
		if len(args) != 0 {
			return nil, cobra.ShellCompDirectiveNoFileComp
		}
		return getInstalledPluginIDs(), cobra.ShellCompDirectiveNoFileComp
	},
	Run: func(cmd *cobra.Command, args []string) {
		if err := uninstallPluginCLI(args[0]); err != nil {
			log.Fatalf("Error uninstalling plugin: %v", err)
		}
	},
}

func runVersion(cmd *cobra.Command, args []string) {
	fmt.Printf("%s\n", formatVersion(Version))
}

// Alpe: Die Version setzt das Makefile beim Bau aus shell/Common/Brand.qml (Plan 0.5 Nr. 2).
func formatVersion(version string) string {
	return brand.Binary + " " + version
}

func startDebugServer() error {
	server.CLIVersion = Version
	return server.Start(true)
}

func listInstalledPlugins() error {
	manager, err := plugins.NewManager()
	if err != nil {
		return fmt.Errorf("failed to create manager: %w", err)
	}

	installedIDs, err := manager.ListInstalled()
	if err != nil {
		return fmt.Errorf("failed to list installed plugins: %w", err)
	}

	if len(installedIDs) == 0 {
		fmt.Println("No plugins installed.")
		return nil
	}

	fmt.Printf("\nInstalled Plugins (%d):\n\n", len(installedIDs))
	for _, id := range installedIDs {
		fmt.Printf("  %s\n", id)
	}
	return nil
}

func uninstallPluginCLI(idOrName string) error {
	manager, err := plugins.NewManager()
	if err != nil {
		return fmt.Errorf("failed to create manager: %w", err)
	}

	fmt.Printf("Uninstalling plugin: %s\n", idOrName)
	if err := manager.UninstallByIDOrName(idOrName); err != nil {
		return err
	}
	fmt.Printf("Plugin uninstalled successfully: %s\n", idOrName)
	return nil
}

func getInstalledPluginIDs() []string {
	manager, err := plugins.NewManager()
	if err != nil {
		return nil
	}

	installed, err := manager.ListInstalled()
	if err != nil {
		return nil
	}

	return installed
}

func getCommonCommands() []*cobra.Command {
	commands := shellApp.Commands()
	return append(commands, []*cobra.Command{
		versionCmd,
		ipcCmd,
		debugSrvCmd,
		sysmonHelperCmd,
		pluginsCmd,
		dank16Cmd,
		brightnessCmd,
		iccCmd,
		dpmsCmd,
		keybindsCmd,
		colorCmd,
		qrCmd,
		screenshotCmd,
		notifyActionCmd,
		notifyCmd,
		genericNotifyActionCmd,
		matugenCmd,
		clipboardCmd,
		chromaCmd,
		doctorCmd,
		configCmd,
		dlCmd,
		randrCmd,
		blurCmd,
		trashCmd,
		systemCmd,
		systemdCmd,
		switchUserCmd,
		dmenuCmd,
	}...)
}
