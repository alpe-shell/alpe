package config

import _ "embed"

//go:embed embedded/hyprland.lua
var HyprlandLuaConfig string

//go:embed embedded/hypr-colors.lua
var ColorsLuaConfig string

//go:embed embedded/hypr-layout.lua
var LayoutLuaConfig string

//go:embed embedded/hypr-binds.lua
var BindsLuaConfig string

//go:embed embedded/hypr-outputs.lua
var OutputsLuaConfig string

//go:embed embedded/hypr-cursor.lua
var CursorLuaConfig string

//go:embed embedded/hypr-input.lua
var InputLuaConfig string

//go:embed embedded/hypr-windowrules.lua
var WindowRulesLuaConfig string

//go:embed embedded/hypr-binds-user.lua
var BindsUserLuaConfig string
