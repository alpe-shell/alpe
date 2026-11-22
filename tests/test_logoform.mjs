// Alpe-Zeichen: eine Quelle für alle Pfaddaten (shell/Alpe/Widgets/LogoShape.js, Plan 0.8 Nr. 35).
// Prüft, dass Materialform, Material-Vorlage «Alpe», Logo-Modus "alpe" und die SVG-Dateien
// daraus stammen und nirgends eine Kopie der Koordinaten liegt.
//
//     node --test tests/test_logoform.mjs                         nimmt shell/ im Repository (oder ALPE_SHELL_DIR)
//     ALPE_LOGO_SCHREIBEN=1 node --test tests/test_logoform.mjs   schreibt die SVG-Dateien neu
import assert from "node:assert/strict";
import { readFileSync, readdirSync, writeFileSync } from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const shellDir = process.env.ALPE_SHELL_DIR || path.join(here, "..", "shell");
const { loadScript } = await import(pathToFileURL(path.join(shellDir, "tests", "qml-script.mjs")).href);
const load = (...parts) => loadScript(pathToFileURL(path.join(shellDir, ...parts)));
const logo = load("Alpe", "Widgets", "LogoShape.js");
const shapes = load("Alpe", "Widgets", "MaterialShapes.js");
const files = { "alpe-zeichen.svg": "#ffffff", "alpe-zeichen-akzent.svg": "#D0BCFF" };

test("die SVG-Dateien entsprechen LogoShape.svg()", () => {
    for (const [name, fill] of Object.entries(files)) {
        const file = path.join(shellDir, "assets", name);
        if (process.env.ALPE_LOGO_SCHREIBEN === "1")
            writeFileSync(file, logo.svg(fill));
        assert.equal(readFileSync(file, "utf8"), logo.svg(fill), name);
    }
});

test("die Materialform alpeLogo ist dasselbe Objekt wie LogoShape.cubics", () => {
    assert.equal(JSON.stringify(shapes.catalog.alpeLogo), JSON.stringify(logo.cubics));
    assert.equal("dankLogo" in shapes.catalog, false);
    const edges = logo.parts.reduce((sum, part) => sum + part.points.length, 0);
    assert.equal(logo.cubics.length, edges);
    for (const cubic of logo.cubics)
        for (const value of cubic)
            assert.ok(value >= 0 && value <= 1, "im Einheitsquadrat: " + value);
});

test("der Pfad der Form hat je Teil einen geschlossenen Teilpfad durch alle Ecken", () => {
    const d = shapes.buildPath("alpeLogo", logo.viewBox, logo.viewBox, false);
    assert.equal((d.match(/M /g) || []).length, logo.parts.length);
    assert.equal((d.match(/Z/g) || []).length, logo.parts.length);
    for (const part of logo.parts)
        for (const [x, y] of part.points)
            assert.ok(d.includes(x.toFixed(4) + " " + y.toFixed(4)), "Ecke " + x + " " + y);
});

test("die Material-Vorlage «Alpe» benutzt die Form alpeLogo", () => {
    const wallpaper = load("Alpe", "Common", "MaterialWallpaper.js");
    assert.equal(wallpaper.defaultPreset, "alpe");
    assert.equal(wallpaper.builtinIds[0], "alpe");
    assert.equal(wallpaper.builtinIds.includes("dank"), false);
    const layout = wallpaper.builtinLayout("alpe");
    assert.ok(layout.layers.some(layer => layer.shape === "alpeLogo"));
    assert.equal(wallpaper.builtinLayout("dank"), null);
});

test("der Logo-Modus \"alpe\" zeichnet die Form und lädt keine Datei", () => {
    const source = readFileSync(path.join(shellDir, "Widgets", "LauncherLogo.qml"), "utf8");
    assert.match(source, /case "alpe":/);
    assert.match(source, /shape: "alpeLogo"/);
    assert.equal(/alpe-zeichen|"dank"/.test(source), false);
});

test("die Koordinaten des Zeichens stehen nur in LogoShape.js und den erzeugten SVG-Dateien", () => {
    const marker = logo.partPath(logo.parts[0]).slice(0, 20);
    const numbers = "318, 62], [392, 196";
    const hits = [];
    const walk = dir => {
        for (const entry of readdirSync(dir, { withFileTypes: true })) {
            const file = path.join(dir, entry.name);
            if (entry.isDirectory()) {
                walk(file);
            } else if (/\.(qml|js|mjs|svg|json)$/.test(entry.name)) {
                const text = readFileSync(file, "utf8");
                if (text.includes(marker) || text.includes(numbers))
                    hits.push(path.relative(shellDir, file));
            }
        }
    };
    walk(shellDir);
    assert.deepEqual(hits.sort(), ["Alpe/Widgets/LogoShape.js", "assets/alpe-zeichen-akzent.svg", "assets/alpe-zeichen.svg"]);
});
