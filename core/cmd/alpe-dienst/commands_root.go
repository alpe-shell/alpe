package main

import (
	"github.com/alpe-shell/alpe/core/internal/brand"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   brand.Binary,
	Short: "Alpe service and CLI",
	Long:  brand.Binary + " is the background service of Alpe and its command line interface.",
}

func init() {
	rootCmd.PersistentFlags().StringVarP(shellApp.CustomConfigVar(), "config", "c", "", "Path to a UI config dir (containing shell.qml) to use instead of the embedded UI (env: ALPE_SHELL_DIR)")
}
