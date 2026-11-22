package matugen

import (
	"bytes"
	"os"
	"path/filepath"

	"github.com/alpe-shell/alpe/core/internal/log"
	"github.com/alpe-shell/alpe/core/internal/utils"
)

// Übergang von Alpe 1.0 (Plan 0.8 Nr. 48, Frist F1). Bis 1.0 trugen die Ausgabedateien für
// Fremdprogramme Namen des Ursprungs, und die Programme binden sie unter diesen Namen ein
// (kitty-include, gtk.css-Import, KDE-Farbschema …). Solange es eine Datei unter dem alten Namen
// gibt, hält Alpe sie aktuell: als Symlink auf die neue Datei, oder – wo der Name auch im Inhalt
// steht oder ein Ordner gemeint ist – als zweite Fassung. Auf einem frisch eingerichteten Rechner
// gibt es die alten Namen nicht, dort geschieht hier nichts. Der Umzug (F1) schreibt die
// Einbindungen um und räumt die alten Namen weg; dann fällt diese Datei.

const (
	legacyColorsCSS = "dank-colors.css"
	legacyKDEScheme = "DankMatugen"
)

type legacyBase int

const (
	baseConfig legacyBase = iota
	baseData
	baseCache
	baseEmacs
)

// legacyOutput: old und new relativ zum Basisordner. Ohne rewrite genügt ein Symlink; mit rewrite
// wird die neue Datei gelesen, jedes Paar (neu, alt) ersetzt und das Ergebnis unter dem alten
// Namen geschrieben.
type legacyOutput struct {
	base    legacyBase
	old     string
	new     string
	copy    bool
	rewrite []string
}

var legacyOutputs = []legacyOutput{
	{base: baseConfig, old: "gtk-3.0/dank-colors.css", new: "gtk-3.0/alpe-colors.css"},
	{base: baseConfig, old: "gtk-4.0/dank-colors.css", new: "gtk-4.0/alpe-colors.css"},
	{base: baseConfig, old: "kitty/dank-theme.conf", new: "kitty/alpe-theme.conf"},
	{base: baseConfig, old: "kitty/dank-tabs.conf", new: "kitty/alpe-tabs.conf"},
	{base: baseConfig, old: "alacritty/dank-theme.toml", new: "alacritty/alpe-theme.toml"},
	{base: baseConfig, old: "wezterm/colors/dank-theme.toml", new: "wezterm/colors/alpe-theme.toml"},
	{base: baseConfig, old: "ghostty/themes/dankcolors", new: "ghostty/themes/alpecolors"},
	{base: baseConfig, old: "foot/dank-colors.ini", new: "foot/alpe-colors.ini"},
	{base: baseConfig, old: "equibop/themes/dank-discord.css", new: "equibop/themes/alpe-discord.css"},
	{base: baseConfig, old: "vesktop/themes/dank-discord.css", new: "vesktop/themes/alpe-discord.css"},
	{base: baseConfig, old: "Vencord/themes/dank-discord.css", new: "Vencord/themes/alpe-discord.css"},
	{base: baseCache, old: "wal/dank-pywalfox.json", new: "wal/alpe-pywalfox.json"},
	// Ordner aus 1.0 bleibt ein Ordner (kein Link an seiner Stelle), darum Kopien.
	{base: baseData, old: "fcitx5/themes/dms/theme.conf", new: "fcitx5/themes/alpe/theme.conf", copy: true, rewrite: []string{"Name=Alpe", "Name=DMS"}},
	{base: baseData, old: "fcitx5/themes/dms/panel.svg", new: "fcitx5/themes/alpe/panel.svg", copy: true},
	{base: baseData, old: "fcitx5/themes/dms/highlight.svg", new: "fcitx5/themes/alpe/highlight.svg", copy: true},
	// Der Name steht im Inhalt: KDE-Farbschema, Zed-Themen, Emacs-Thema.
	{base: baseData, old: "color-schemes/DankMatugen.colors", new: "color-schemes/AlpeMatugen.colors", copy: true, rewrite: []string{"AlpeMatugen", "DankMatugen", "Name=Alpe (matugen)", "Name=Dank Shell (matugen)"}},
	{base: baseData, old: "color-schemes/DankMatugenLight.colors", new: "color-schemes/AlpeMatugenLight.colors", copy: true, rewrite: []string{"AlpeMatugen", "DankMatugen", "Name=Alpe (matugen)", "Name=Dank Shell (matugen)"}},
	{base: baseData, old: "color-schemes/DankMatugenDark.colors", new: "color-schemes/AlpeMatugenDark.colors", copy: true, rewrite: []string{"AlpeMatugen", "DankMatugen", "Name=Alpe (matugen)", "Name=Dank Shell (matugen)"}},
	{base: baseConfig, old: "zed/themes/dank-zed-theme.json", new: "zed/themes/alpe-zed-theme.json", copy: true, rewrite: []string{"Dynamic Base16 Alpe", "Dynamic Base16 DankShell", `"name": "Alpe `, `"name": "DankShell `}},
	{base: baseEmacs, old: "themes/dank-emacs-theme.el", new: "themes/alpe-emacs-theme.el", copy: true, rewrite: []string{"alpe-emacs", "dank-emacs"}},
}

func legacyBaseDir(base legacyBase, opts *Options) string {
	switch base {
	case baseConfig:
		return opts.ConfigDir
	case baseData:
		return utils.XDGDataHome()
	case baseCache:
		return utils.XDGCacheHome()
	case baseEmacs:
		return utils.EmacsConfigDir()
	}
	return ""
}

func syncLegacyOutputs(opts *Options) {
	for _, out := range legacyOutputs {
		dir := legacyBaseDir(out.base, opts)
		if dir == "" {
			continue
		}
		if err := syncLegacyOutput(filepath.Join(dir, out.old), filepath.Join(dir, out.new), out); err != nil {
			log.Warnf("Alter Dateiname %s: %v", out.old, err)
		}
	}
}

// syncLegacyOutput tut nur etwas, wenn es den alten Namen schon gibt (Datei aus 1.0 oder unser
// Link) und die neue Datei geschrieben wurde.
func syncLegacyOutput(oldPath, newPath string, out legacyOutput) error {
	if _, err := os.Lstat(oldPath); err != nil {
		return nil
	}
	data, err := os.ReadFile(newPath)
	if err != nil {
		return nil
	}
	if out.copy {
		for i := 0; i+1 < len(out.rewrite); i += 2 {
			data = bytes.ReplaceAll(data, []byte(out.rewrite[i]), []byte(out.rewrite[i+1]))
		}
		if current, err := os.ReadFile(oldPath); err == nil && bytes.Equal(current, data) {
			return nil
		}
		return writeFileAtomic(oldPath, data)
	}
	// Alter und neuer Name liegen im selben Ordner: relativer Link.
	target := filepath.Base(newPath)
	if current, err := os.Readlink(oldPath); err == nil && current == target {
		return nil
	}
	tmp := oldPath + ".alpe-neu"
	_ = os.Remove(tmp)
	if err := os.Symlink(target, tmp); err != nil {
		return err
	}
	return os.Rename(tmp, oldPath)
}

func writeFileAtomic(path string, data []byte) error {
	tmp := path + ".alpe-neu"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}
