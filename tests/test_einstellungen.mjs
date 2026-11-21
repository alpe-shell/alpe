// Prüft die Migration der Einstellungen auf Version 43 (Namen des Ursprungs → eigene Namen)
// mit einer settings.json aus Alpe 1.0 (Design «kde» vor D5 plus einige 1.0-Werte).
//
//     node --test tests/test_einstellungen.mjs      nimmt shell/ im Repository (oder ALPE_SHELL_DIR)
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const shellDir = process.env.ALPE_SHELL_DIR || path.join(here, "..", "shell");
const { loadScript } = await import(pathToFileURL(path.join(shellDir, "tests", "qml-script.mjs")).href);
const store = loadScript(pathToFileURL(path.join(shellDir, "Common", "settings", "SettingsStore.js")));
const spec = loadScript(pathToFileURL(path.join(shellDir, "Common", "settings", "SettingsSpec.js"))).SPEC;
const version = Number(readFileSync(path.join(shellDir, "Common", "SettingsData.qml"), "utf8").match(/settingsConfigVersion: (\d+)/)[1]);
const old = JSON.parse(readFileSync(path.join(here, "data", "einstellungen-1.0", "settings.json"), "utf8"));
const renamed = {
    dankLauncherV2Size: "launcherSize",
    dankLauncherV2BorderEnabled: "launcherBorderEnabled",
    dankLauncherV2BorderThickness: "launcherBorderThickness",
    dankLauncherV2ShowFooter: "launcherShowFooter",
    runDmsMatugenTemplates: "runMatugenTemplates",
    dmsWindowsFloatingSeeded: "shellWindowsFloatingSeeded",
};

test("die Shell kennt Version 43", () => {
    assert.equal(old.configVersion, 42);
    assert.ok(version >= 43, "settingsConfigVersion " + version);
});

test("alte Schlüssel ziehen mit ihrem Wert um", () => {
    const migrated = store.migrateToVersion(old, version);
    assert.equal(migrated.configVersion, version);
    for (const [from, to] of Object.entries(renamed)) {
        assert.ok(from in old, "Testdatei enthält " + from);
        assert.equal(from in migrated, false, from + " ist weg");
        assert.equal(JSON.stringify(migrated[to]), JSON.stringify(old[from]), to + " trägt den alten Wert");
    }
});

test("Werte «dms» heissen «standard»", () => {
    const migrated = store.migrateToVersion(old, version);
    assert.equal(migrated.alpeLockStyle, "standard");
    assert.equal(migrated.alpeHyprBlurMode, "standard");
    const other = store.migrateToVersion({ configVersion: 42, alpeLockStyle: "hyprlock", alpeHyprBlurMode: "off" }, version);
    assert.equal(other.alpeLockStyle, "hyprlock");
    assert.equal(other.alpeHyprBlurMode, "off");
});

test("ein schon vorhandener neuer Schlüssel gewinnt", () => {
    const migrated = store.migrateToVersion({ configVersion: 42, dankLauncherV2Size: "micro", launcherSize: "large" }, version);
    assert.equal(migrated.launcherSize, "large");
    assert.equal("dankLauncherV2Size" in migrated, false);
});

test("übrige Einstellungen bleiben unverändert", () => {
    const migrated = store.migrateToVersion(old, version);
    for (const key of Object.keys(old)) {
        if (key in renamed || key === "configVersion" || key === "alpeLockStyle" || key === "alpeHyprBlurMode")
            continue;
        assert.equal(JSON.stringify(migrated[key]), JSON.stringify(old[key]), key);
    }
});

test("aktuelle Datei wird nicht noch einmal migriert", () => {
    const migrated = store.migrateToVersion(old, version);
    assert.equal(store.migrateToVersion(migrated, version), null);
});

test("kein Einstellungsschlüssel trägt mehr dank/dms im Namen", () => {
    const left = Object.keys(spec).filter(key => /dank|dms/i.test(key));
    assert.equal(left.join(" "), "");
    for (const to of Object.values(renamed))
        assert.ok(to in spec, to + " steht in SettingsSpec");
    assert.equal(spec.alpeHyprBlurMode.def, "standard");
});
