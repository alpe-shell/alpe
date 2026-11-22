package matugen

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Eigene Vorlagen aus 1.0 lesen {{dank16.…}} und {{dank16term.…}}: beide Namen liefern bis zum
// Umzug dieselben Werte wie palette16 und palette16term (Plan 0.8 Nr. 47).
func TestLegacyPaletteNamesCarryIdenticalValues(t *testing.T) {
	const pal = `{"color0":{"dark":{"hex":"#000000"}},"color1":{"dark":{"hex":"#111111"}}}`
	const term = `{"color0":{"dark":{"hex":"#222222"}}}`
	data := buildImportData(pal, "/w.png", "", []paletteInjection{{Namespace: "palette16term", JSON: term}, {Namespace: "wallust", JSON: term}})

	var fields map[string]json.RawMessage
	require.NoError(t, json.Unmarshal([]byte(withLegacyPaletteNames(data)), &fields))
	assert.JSONEq(t, pal, string(fields["palette16"]))
	assert.JSONEq(t, term, string(fields["palette16term"]))
	assert.Equal(t, string(fields["palette16"]), string(fields["dank16"]), "dank16 = palette16")
	assert.Equal(t, string(fields["palette16term"]), string(fields["dank16term"]), "dank16term = palette16term")
	assert.Contains(t, fields, "wallust")
	assert.Contains(t, fields, "image")
	assert.Len(t, fields, 6, "nur die beiden alten Namen kommen dazu")
}

func TestLegacyPaletteNamesLeaveUserPaletteAlone(t *testing.T) {
	const pal = `{"color0":"#000000"}`
	const own = `{"color0":"#abcdef"}`
	data := buildImportData(pal, "", "", []paletteInjection{{Namespace: "dank16", JSON: own}})

	var fields map[string]json.RawMessage
	require.NoError(t, json.Unmarshal([]byte(withLegacyPaletteNames(data)), &fields))
	assert.JSONEq(t, own, string(fields["dank16"]), "eine eigene Palette dieses Namens gewinnt")
	assert.NotContains(t, fields, "dank16term", "ohne palette16term kein dank16term")

	assert.Equal(t, "kein JSON", withLegacyPaletteNames("kein JSON"))
}

// Die Vorlage mit festen Farben (StockColors) geht denselben Weg.
func TestLegacyPaletteNamesOnStockImport(t *testing.T) {
	data := withLegacyPaletteNames(`{"colors": {}, "palette16": {"a":1}, "palette16term": {"a":2}}`)
	var fields map[string]json.RawMessage
	require.NoError(t, json.Unmarshal([]byte(data), &fields))
	assert.JSONEq(t, `{"a":1}`, string(fields["dank16"]))
	assert.JSONEq(t, `{"a":2}`, string(fields["dank16term"]))
}

func writeTestFile(t *testing.T, path, content string) {
	t.Helper()
	require.NoError(t, os.MkdirAll(filepath.Dir(path), 0o755))
	require.NoError(t, os.WriteFile(path, []byte(content), 0o644))
}

func legacyTestDirs(t *testing.T) (config, data, cache string, opts *Options) {
	t.Helper()
	root := t.TempDir()
	config, data, cache = filepath.Join(root, "config"), filepath.Join(root, "data"), filepath.Join(root, "cache")
	t.Setenv("XDG_CONFIG_HOME", config)
	t.Setenv("XDG_DATA_HOME", data)
	t.Setenv("XDG_CACHE_HOME", cache)
	t.Setenv("HOME", root)
	return config, data, cache, &Options{ConfigDir: config}
}

// Frisch eingerichteter Rechner: Es gibt keine alten Namen, also entstehen auch keine.
func TestLegacyOutputsUntouchedWithoutOldNames(t *testing.T) {
	config, data, _, opts := legacyTestDirs(t)
	writeTestFile(t, filepath.Join(config, "kitty", "alpe-theme.conf"), "neu\n")
	writeTestFile(t, filepath.Join(data, "color-schemes", "AlpeMatugen.colors"), "ColorScheme=AlpeMatugen\n")

	syncLegacyOutputs(opts)

	entries, err := os.ReadDir(filepath.Join(config, "kitty"))
	require.NoError(t, err)
	assert.Len(t, entries, 1)
	_, err = os.Lstat(filepath.Join(data, "color-schemes", "DankMatugen.colors"))
	assert.True(t, os.IsNotExist(err))
}

// Rechner mit Dateien aus 1.0: Die Einbindung über den alten Namen bekommt weiter die neuen Farben.
func TestLegacyOutputsSymlinkToNewFile(t *testing.T) {
	config, _, cache, opts := legacyTestDirs(t)
	writeTestFile(t, filepath.Join(config, "kitty", "dank-theme.conf"), "alt aus 1.0\n")
	writeTestFile(t, filepath.Join(config, "kitty", "alpe-theme.conf"), "foreground #ffffff\n")
	writeTestFile(t, filepath.Join(config, "gtk-4.0", "dank-colors.css"), "alt\n")
	writeTestFile(t, filepath.Join(config, "gtk-4.0", "alpe-colors.css"), "@define-color accent_color #fff;\n")
	writeTestFile(t, filepath.Join(cache, "wal", "dank-pywalfox.json"), "{}")
	writeTestFile(t, filepath.Join(cache, "wal", "alpe-pywalfox.json"), `{"neu":1}`)
	// alter Name da, neue Datei (Vorlage abgeschaltet) nicht: bleibt, wie er ist
	writeTestFile(t, filepath.Join(config, "foot", "dank-colors.ini"), "bleibt\n")

	syncLegacyOutputs(opts)

	for old, want := range map[string]string{
		filepath.Join(config, "kitty", "dank-theme.conf"):   "alpe-theme.conf",
		filepath.Join(config, "gtk-4.0", "dank-colors.css"): "alpe-colors.css",
		filepath.Join(cache, "wal", "dank-pywalfox.json"):   "alpe-pywalfox.json",
	} {
		target, err := os.Readlink(old)
		require.NoError(t, err, old)
		assert.Equal(t, want, target, "relativer Link im selben Ordner")
	}
	content, err := os.ReadFile(filepath.Join(config, "kitty", "dank-theme.conf"))
	require.NoError(t, err)
	assert.Equal(t, "foreground #ffffff\n", string(content))
	foot, err := os.ReadFile(filepath.Join(config, "foot", "dank-colors.ini"))
	require.NoError(t, err)
	assert.Equal(t, "bleibt\n", string(foot))

	// Die neue Datei ändert sich: Der Link trägt, ein zweiter Lauf fasst ihn nicht an.
	before, err := os.Lstat(filepath.Join(config, "kitty", "dank-theme.conf"))
	require.NoError(t, err)
	writeTestFile(t, filepath.Join(config, "kitty", "alpe-theme.conf"), "foreground #000000\n")
	syncLegacyOutputs(opts)
	after, err := os.Lstat(filepath.Join(config, "kitty", "dank-theme.conf"))
	require.NoError(t, err)
	assert.Equal(t, before.ModTime(), after.ModTime())
	content, _ = os.ReadFile(filepath.Join(config, "kitty", "dank-theme.conf"))
	assert.Equal(t, "foreground #000000\n", string(content))
	leftovers, _ := filepath.Glob(filepath.Join(config, "kitty", "*.alpe-neu"))
	assert.Empty(t, leftovers)
}

// Wo der Name im Inhalt steht, wird unter dem alten Namen eine zweite Fassung geschrieben.
func TestLegacyOutputsWrittenTwiceWithOldNames(t *testing.T) {
	config, data, _, opts := legacyTestDirs(t)
	schemes := filepath.Join(data, "color-schemes")
	writeTestFile(t, filepath.Join(schemes, "DankMatugenDark.colors"), "alt\n")
	writeTestFile(t, filepath.Join(schemes, "AlpeMatugenDark.colors"), "[General]\nColorScheme=AlpeMatugenDark\nName=Alpe (matugen) Dark\n[Colors:View]\nBackgroundNormal=1,2,3\n")
	writeTestFile(t, filepath.Join(config, "zed", "themes", "dank-zed-theme.json"), "{}")
	writeTestFile(t, filepath.Join(config, "zed", "themes", "alpe-zed-theme.json"), `{"name": "Dynamic Base16 Alpe", "themes": [{"name": "Alpe Dark"}, {"name": "Alpe Light Transparent"}]}`)
	writeTestFile(t, filepath.Join(data, "fcitx5", "themes", "dms", "theme.conf"), "alt\n")
	writeTestFile(t, filepath.Join(data, "fcitx5", "themes", "alpe", "theme.conf"), "[Metadata]\nName=Alpe\n")

	syncLegacyOutputs(opts)

	kde, err := os.ReadFile(filepath.Join(schemes, "DankMatugenDark.colors"))
	require.NoError(t, err)
	assert.Equal(t, "[General]\nColorScheme=DankMatugenDark\nName=Dank Shell (matugen) Dark\n[Colors:View]\nBackgroundNormal=1,2,3\n", string(kde))
	info, err := os.Lstat(filepath.Join(schemes, "DankMatugenDark.colors"))
	require.NoError(t, err)
	assert.True(t, info.Mode().IsRegular(), "eigene Datei, kein Link")
	_, err = os.Lstat(filepath.Join(schemes, "DankMatugen.colors"))
	assert.True(t, os.IsNotExist(err), "nur Namen, die es schon gab")

	zed, err := os.ReadFile(filepath.Join(config, "zed", "themes", "dank-zed-theme.json"))
	require.NoError(t, err)
	assert.Equal(t, `{"name": "Dynamic Base16 DankShell", "themes": [{"name": "DankShell Dark"}, {"name": "DankShell Light Transparent"}]}`, string(zed))

	fcitx, err := os.ReadFile(filepath.Join(data, "fcitx5", "themes", "dms", "theme.conf"))
	require.NoError(t, err)
	assert.Equal(t, "[Metadata]\nName=DMS\n", string(fcitx))
	dir, err := os.Lstat(filepath.Join(data, "fcitx5", "themes", "dms"))
	require.NoError(t, err)
	assert.True(t, dir.IsDir(), "der Ordner aus 1.0 bleibt ein Ordner")
}

// Die Erkennung «ist aktiv» gilt auch für Einbindungen aus 1.0, weil die alten Namen weiterleben.
func TestLegacyReferencesCountAsActive(t *testing.T) {
	config, _, _, _ := legacyTestDirs(t)
	writeTestFile(t, filepath.Join(config, "gtk-3.0", "gtk.css"), "@import url(\"dank-colors.css\");\n")
	assert.True(t, isDMSGTKActive(config))

	writeTestFile(t, filepath.Join(config, "kdeglobals"), "[General]\nColorScheme=DankMatugenDark\n")
	assert.Equal(t, "DankMatugen", activeKDESchemePrefix(config), "altes Schema bleibt das Schema des Nutzers")
	writeTestFile(t, filepath.Join(config, "kdeglobals"), "[General]\nColorScheme=AlpeMatugenLight\n")
	assert.Equal(t, "AlpeMatugen", activeKDESchemePrefix(config))
	writeTestFile(t, filepath.Join(config, "kdeglobals"), "[General]\nColorScheme=BreezeDark\n")
	assert.Equal(t, "", activeKDESchemePrefix(config))
}
