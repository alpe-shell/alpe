package matugen

import (
	"encoding/json"
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
