package main

import (
	"github.com/alpe-shell/alpe/core/internal/brand"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   brand.Binary,
	Short: "dms CLI",
	Long:  "dms is the Dux Modular Shell management CLI and backend server.",
}

func init() {
	rootCmd.PersistentFlags().StringVarP(shellApp.CustomConfigVar(), "config", "c", "", "Path to a UI config dir (containing shell.qml) to use instead of the embedded UI (env: ALPE_SHELL_DIR)")
}
