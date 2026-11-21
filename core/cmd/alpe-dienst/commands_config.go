package main

import (
	"encoding/json"
	"fmt"
	"github.com/alpe-shell/alpe/core/internal/brand"
	"os"
	"path/filepath"
	"strings"

	"github.com/alpe-shell/alpe/core/internal/log"
	"github.com/alpe-shell/alpe/core/internal/luaconfig"
	"github.com/alpe-shell/alpe/core/internal/utils"
	"github.com/spf13/cobra"
)

var configCmd = &cobra.Command{
	Use:   "config",
	Short: "Configuration utilities",
}

var resolveIncludeCmd = &cobra.Command{
	Use:   "resolve-include <compositor> <filename>",
	Short: "Check if a file is included in compositor config",
	Long:  "Recursively check if a file is included/sourced in compositor configuration. Returns JSON with exists and included status.",
	Args:  cobra.ExactArgs(2),
	ValidArgsFunction: func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
		switch len(args) {
		case 0:
			return []string{"hyprland"}, cobra.ShellCompDirectiveNoFileComp
		case 1:
			return []string{
				"binds.lua",
				"binds-user.lua",
				"colors.lua",
				"layout.lua",
				"outputs.lua",
				"cursor.lua",
				"input.lua",
				"windowrules.lua",
			}, cobra.ShellCompDirectiveNoFileComp
		}
		return nil, cobra.ShellCompDirectiveNoFileComp
	},
	Run: runResolveInclude,
}

func init() {
	configCmd.AddCommand(resolveIncludeCmd)
}

type IncludeResult struct {
	Exists   bool `json:"exists"`
	Included bool `json:"included"`
}

func runResolveInclude(cmd *cobra.Command, args []string) {
	compositor := strings.ToLower(args[0])
	filename := args[1]

	var result IncludeResult
	var err error

	switch compositor {
	case "hyprland":
		result, err = checkHyprlandInclude(filename)
	default:
		log.Fatalf("Unknown compositor: %s", compositor)
	}

	if err != nil {
		log.Fatalf("Error checking include: %v", err)
	}

	output, _ := json.Marshal(result)
	fmt.Fprintln(os.Stdout, string(output))
}

func checkHyprlandInclude(filename string) (IncludeResult, error) {
	configDir := filepath.Join(utils.XDGConfigHome(), "hypr")

	targetPath := filepath.Join(configDir, brand.DirName, filename)
	result := IncludeResult{}

	if _, err := os.Stat(targetPath); err == nil {
		result.Exists = true
	}

	targetAbs, err := filepath.Abs(targetPath)
	if err != nil {
		return result, err
	}

	mainLua := filepath.Join(configDir, "hyprland.lua")
	if _, err := os.Stat(mainLua); err != nil {
		return result, nil
	}
	result.Included = luaconfig.RequiresTarget(mainLua, targetAbs, make(map[string]bool))
	return result, nil
}
