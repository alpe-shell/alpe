// Prüft die Migration der Einstellungen auf Version 43 (Namen des Ursprungs → eigene Namen) und
// 44 (gespeicherte Kennungen: Starter-Einträge alpe_*, Logo-Modus "alpe", matugen-Spec "alpe")
// mit einer settings.json aus Alpe 1.0 (Design «kde» vor D5 plus einige 1.0-Werte) und einer auf
// Version 43 (Design «kde» nach D5); dazu die Session auf Version 8 (Material-Vorlage «Alpe»).
//
//     node --test tests/test_einstellungen.mjs      nimmt shell/ im Repository (oder ALPE_SHELL_DIR)
import assert from "node:assert/strict";
import { existsSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const shellDir = process.env.ALPE_SHELL_DIR || path.join(here, "..", "shell");
const { loadScript } = await import(pathToFileURL(path.join(shellDir, "tests", "qml-script.mjs")).href);
const store = loadScript(pathToFileURL(path.join(shellDir, "Common", "settings", "SettingsStore.js")));
const spec = loadScript(pathToFileURL(path.join(shellDir, "Common", "settings", "SettingsSpec.js"))).SPEC;
const version = Number(readFileSync(path.join(shellDir, "Common", "SettingsData.qml"), "utf8").match(/settingsConfigVersion: (\d+)/)[1]);
const names = loadScript(pathToFileURL(path.join(shellDir, "Common", "settings", "Namen44.js")));
const sessionStore = loadScript(pathToFileURL(path.join(shellDir, "Common", "settings", "SessionStore.js")));
const sessionVersion = Number(readFileSync(path.join(shellDir, "Common", "SessionData.qml"), "utf8").match(/sessionConfigVersion: (\d+)/)[1]);
const v43 = JSON.parse(readFileSync(path.join(here, "data", "einstellungen-v43", "settings.json"), "utf8"));
const plain = value => JSON.parse(JSON.stringify(value));
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
        if (key in renamed || key === "configVersion" || key === "alpeLockStyle" || key === "alpeHyprBlurMode" || key === "builtInPluginSettings" || key === "settingsHiddenPages")
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

// ---------------------------------------------------------------- Version 44

test("die Shell kennt Version 44, die Testdateien sind 42 und 43", () => {
    assert.ok(version >= 44, "settingsConfigVersion " + version);
    assert.equal(old.configVersion, 42);
    assert.equal(v43.configVersion, 43);
});

for (const [label, file] of [["1.0", old], ["v43", v43]]) {
    test("Starter-Einträge heissen alpe_* (Datei " + label + ")", () => {
        const before = Object.keys(file.builtInPluginSettings);
        assert.ok(before.some(key => key.startsWith("dms_")), "Testdatei enthält dms_*");
        const migrated = plain(store.migrateToVersion(file, version));
        assert.equal(migrated.configVersion, version);
        assert.deepEqual(Object.keys(migrated.builtInPluginSettings).sort(), before.map(key => key.replace(/^dms_/, "alpe_")).sort());
        for (const key of before)
            assert.deepEqual(migrated.builtInPluginSettings[key.replace(/^dms_/, "alpe_")], file.builtInPluginSettings[key], key);
        assert.equal(/"dms_[a-z_]+"/.test(JSON.stringify(migrated)), false, "kein dms_* mehr");
    });

    test("alles andere bleibt (Datei " + label + ")", () => {
        const migrated = plain(store.migrateToVersion(file, version));
        const expected = plain(store.migrateToVersion(file, 43) ?? file);
        const rest = Object.assign({}, migrated);
        for (const key of ["builtInPluginSettings", "configVersion", "settingsHiddenPages"]) {
            delete expected[key];
            delete rest[key];
        }
        assert.deepEqual(rest, expected);
    });
}

test("Logo-Modus, Punkt-Symbol und matugen-Spec ziehen um, auch aus Version 43", () => {
    const file = {
        configVersion: 43,
        matugenSpec: "dms",
        barConfigs: [{ id: "a", leftWidgets: ["launcherButton", { id: "launcherButton", launcherLogoMode: "dank" }], islandFreeIconMode: "dank", centerWidgets: [{ id: "island", islandFreeIconMode: "dank" }] }],
        dockConfigs: [{ id: "d", launcherLogoMode: "dank", widgets: [{ id: "appsDock", launcherLogoMode: "os" }, { id: "x", launcherLogoMode: "dank" }] }],
        builtInPluginSettings: { dms_power: { enabled: false }, alpe_vpn: { enabled: true }, dms_vpn: { enabled: false }, fremd: { note: "dank" } },
        customThemeFile: "dank",
        launcherLogoCustomPath: "dms_settings.svg"
    };
    const migrated = plain(store.migrateToVersion(file, version));
    assert.equal(migrated.matugenSpec, "alpe");
    assert.equal(migrated.barConfigs[0].leftWidgets[1].launcherLogoMode, "alpe");
    assert.equal(migrated.barConfigs[0].islandFreeIconMode, "alpe");
    assert.equal(migrated.barConfigs[0].centerWidgets[0].islandFreeIconMode, "alpe");
    assert.equal(migrated.dockConfigs[0].launcherLogoMode, "alpe");
    assert.deepEqual(migrated.dockConfigs[0].widgets.map(widget => widget.launcherLogoMode), ["os", "alpe"]);
    assert.deepEqual(migrated.builtInPluginSettings, { alpe_vpn: { enabled: true }, fremd: { note: "dank" }, alpe_power: { enabled: false } }, "vorhandener neuer Schlüssel gewinnt");
    assert.equal(migrated.customThemeFile, "dank", "andere Werte «dank» bleiben");
    assert.equal(migrated.launcherLogoCustomPath, "dms_settings.svg", "nur ganze Kennungen");
    assert.equal(store.migrateToVersion({ configVersion: 43, matugenSpec: "2025" }, version).matugenSpec, "2025");
});

test("Session Version 8: Starter-Einträge in Pins, Material-Vorlage «Alpe», Form alpeLogo", () => {
    assert.ok(sessionVersion >= 8, "sessionConfigVersion " + sessionVersion);
    const session = {
        configVersion: 7,
        dockPins: { dock: ["kitty", "dms_settings", "dms_notepad"] },
        hiddenApps: ["dms_vpn"],
        builtInPluginState: { dankNotepadModule: { tabs: 2 } },
        materialWallpapers: { "": { shared: { preset: "dank", seed: "#d0bcff" }, dark: { preset: "bloom", seed: "#d0bcff" } } },
        materialWallpaperProfiles: { eigen: { name: "dank", layers: [{ shape: "dankLogo", x: 0.5 }, { shape: "circle", x: 0.1 }] } },
        launcherQueryHistory: ["dank", "dms"]
    };
    const migrated = plain(sessionStore.migrateToVersion(session, sessionVersion, null));
    assert.equal(migrated.configVersion, sessionVersion);
    assert.deepEqual(migrated.dockPins, { dock: ["kitty", "alpe_settings", "alpe_notepad"] });
    assert.deepEqual(migrated.hiddenApps, ["alpe_vpn"]);
    assert.deepEqual(migrated.builtInPluginState, session.builtInPluginState, "Altdaten des Notizblock-Plugins bleiben");
    assert.equal(migrated.materialWallpapers[""].shared.preset, "alpe");
    assert.equal(migrated.materialWallpapers[""].dark.preset, "bloom");
    assert.deepEqual(migrated.materialWallpaperProfiles.eigen, { name: "dank", layers: [{ shape: "alpeLogo", x: 0.5 }, { shape: "circle", x: 0.1 }] });
    assert.deepEqual(migrated.launcherQueryHistory, ["dank", "dms"]);
    assert.equal(sessionStore.migrateToVersion(migrated, sessionVersion, null), null, "nicht noch einmal");
});

test("ausgeblendete Seiten (settingsHiddenPages) tragen die neuen Seiten-IDs", () => {
    const tabs = readFileSync(path.join(shellDir, "Common", "SettingsTabs.qml"), "utf8");
    for (const [from, to] of Object.entries(names.PAGE_IDS)) {
        assert.ok(tabs.includes('"id": "' + to + '"'), "Seite " + to + " gibt es");
        assert.equal(tabs.includes('"' + from + '"'), false, from + " kennt die Shell nicht mehr");
    }
    assert.ok(Array.isArray(old.settingsHiddenPages) && old.settingsHiddenPages.includes("dank_dash"), "Testdatei aus 1.0 blendet dank_dash aus");
    const fromOld = plain(store.migrateToVersion(old, version));
    assert.deepEqual(fromOld.settingsHiddenPages, old.settingsHiddenPages.map(id => names.PAGE_IDS[id] ?? id));
    const file = { configVersion: 43, settingsHiddenPages: ["auto", "dankbar", "dankbar_settings", "dankbar_appearance", "dankbar_dot", "dankbar_widgets", "dank_dash", "dash", "printers"], launcherLastPage: "dank_dash", andere: ["dankbar"] };
    const migrated = plain(store.migrateToVersion(file, version));
    assert.deepEqual(migrated.settingsHiddenPages, ["auto", "bar", "bar_settings", "bar_appearance", "bar_dot", "bar_widgets", "dash", "printers"], "umbenannt, ohne Doppel, Reihenfolge bleibt");
    assert.equal(migrated.launcherLastPage, "dank_dash", "nur in der Seitenliste");
    assert.deepEqual(migrated.andere, ["dankbar"]);
    assert.equal(store.migrateToVersion(migrated, version), null, "nicht noch einmal");
    assert.deepEqual(plain(store.migrateToVersion({ configVersion: 43, settingsHiddenPages: "auto" }, version)).settingsHiddenPages, "auto", "kaputter Wert bleibt, wie er ist");
});

// ---------------------------------------------------------------- Session aus 1.0 als Datei

// Derselbe Ablauf wie SessionData.loadSettings()/_onWritableCheckComplete(): lesen, migrieren, die alte
// Datei als session.v<alt>.json sichern (SessionStore.backupFor), den migrierten Stand schreiben.
function loadSessionFile(dir) {
    const file = path.join(dir, "session.json");
    const obj = JSON.parse(readFileSync(file, "utf8"));
    const oldVersion = obj.configVersion ?? 0;
    const migrated = oldVersion < sessionVersion ? sessionStore.migrateToVersion(obj, sessionVersion, null) : null;
    if (!migrated)
        return false;
    const backup = sessionStore.backupFor(obj, oldVersion);
    if (backup)
        writeFileSync(path.join(dir, backup.name), backup.text);
    writeFileSync(file, JSON.stringify(migrated, null, 2));
    return true;
}

test("session.json aus 1.0: migriert, Sicherung session.v7.json, zweiter Lauf ändert nichts", () => {
    const source = path.join(here, "data", "einstellungen-1.0", "session.json");
    const original = readFileSync(source, "utf8");
    const before = JSON.parse(original);
    assert.equal(before.configVersion, 7, "Testdatei ist Session-Version 7 (Alpe 1.0)");
    const dir = mkdtempSync(path.join(os.tmpdir(), "alpe-session-"));
    try {
        writeFileSync(path.join(dir, "session.json"), original);
        assert.equal(loadSessionFile(dir), true, "erster Lauf migriert");
        assert.deepEqual(readdirSync(dir).sort(), ["session.json", "session.v7.json"]);
        assert.deepEqual(JSON.parse(readFileSync(path.join(dir, "session.v7.json"), "utf8")), before, "Sicherung = Datei aus 1.0");

        const after = JSON.parse(readFileSync(path.join(dir, "session.json"), "utf8"));
        assert.equal(after.configVersion, sessionVersion);
        assert.deepEqual(after.dockPins, { dock: ["org.kde.dolphin", "kitty", "alpe_settings", "alpe_notepad"] });
        assert.deepEqual(after.barPinnedApps, ["firefox", "alpe_sysmon"]);
        assert.deepEqual(after.hiddenApps, ["alpe_vpn", "org.kde.kwalletmanager"]);
        assert.deepEqual(after.appOverrides, { alpe_colorpicker: { name: "Pipette" } });
        assert.equal(after.materialWallpapers[""].shared.preset, "alpe");
        assert.equal(after.materialWallpapers[""].dark.preset, "bloom");
        assert.deepEqual(after.materialWallpaperProfiles.eigen.layers.map(layer => layer.shape), ["alpeLogo", "circle"]);
        assert.equal(after.materialWallpaperProfiles.eigen.name, "dank", "eigener Profilname bleibt");
        // alles andere bleibt Wort für Wort (Verläufe, Altdaten des Notizblock-Plugins, Geräte …)
        const touched = ["configVersion", "dockPins", "barPinnedApps", "hiddenApps", "appOverrides", "materialWallpapers", "materialWallpaperProfiles"];
        for (const key of Object.keys(before)) {
            if (!touched.includes(key))
                assert.deepEqual(after[key], before[key], key);
        }
        assert.deepEqual(Object.keys(after).sort(), Object.keys(before).sort(), "kein Schlüssel kommt dazu oder fällt weg");
        assert.equal(/"dms_[a-z_]+"|"dankLogo"/.test(JSON.stringify(after)), false, "keine alte Kennung mehr");

        const migratedText = readFileSync(path.join(dir, "session.json"), "utf8");
        const backupText = readFileSync(path.join(dir, "session.v7.json"), "utf8");
        assert.equal(loadSessionFile(dir), false, "zweiter Lauf migriert nicht");
        assert.deepEqual(readdirSync(dir).sort(), ["session.json", "session.v7.json"], "keine weitere Sicherung");
        assert.equal(readFileSync(path.join(dir, "session.json"), "utf8"), migratedText);
        assert.equal(readFileSync(path.join(dir, "session.v7.json"), "utf8"), backupText);
    } finally {
        rmSync(dir, { recursive: true, force: true });
    }
    assert.equal(sessionStore.backupFor({}, 7), null, "leere Datei: keine Sicherung");
});

test("SessionData.qml sichert über SessionStore.backupFor und schreibt den migrierten Stand", () => {
    const data = readFileSync(path.join(shellDir, "Common", "SessionData.qml"), "utf8");
    assert.match(data, /Store\.backupFor\(obj, oldVersion\)/);
    assert.match(data, /sessionBackup\.setText\(backup\.text\)/);
    assert.match(data, /else if \(_pendingMigration\)\s+settingsFile\.setText\(getCurrentSessionJson\(\)\)/);
});

test("die neuen Kennungen gibt es in der Shell, die alten nur noch in der Migration", () => {
    const search = readFileSync(path.join(shellDir, "Services", "AppSearchService.qml"), "utf8");
    for (const [from, to] of Object.entries(names.STARTER_IDS)) {
        assert.ok(search.includes('"' + to + '"'), to);
        assert.equal(search.includes(from), false, from);
    }
    const data = readFileSync(path.join(shellDir, "Common", "SettingsData.qml"), "utf8");
    assert.match(data, /spec === "alpe"/);
});
