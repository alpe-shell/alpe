import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import test from "node:test";

// Nachtlauf vom 27.11.2026, Punkt 1.2 (Entscheid vom 26.11.2026): Das Herkunftsabzeichen für AppImage zeigt kein
// fremdes Zeichen mehr (appimage.svg, Herkunft unbelegt, ist entfernt), sondern das Symbol «deployed_code» aus der
// mitgelieferten Symbolschrift. Flatpak, Snap und Nix behalten ihre Zeichen (mit Nennung in NOTICE).

const badge = readFileSync(new URL("../Modals/Launcher/SourceBadge.qml", import.meta.url), "utf8");

function map(name) {
    const found = badge.match(new RegExp(`readonly property var ${name}: \\(\\{([\\s\\S]*?)\\}\\)`));
    assert.ok(found, name);
    return Object.fromEntries([...found[1].matchAll(/"([\w-]+)": "([^"]+)"/g)].map(m => [m[1], m[2]]));
}

test("AppImage gets the neutral glyph from the bundled symbol font, no file", () => {
    assert.deepEqual(map("sourceGlyph"), { appimage: "deployed_code" });
    assert.ok(!("appimage" in map("sourceAsset")));
    assert.ok(!badge.includes("appimage.svg"));
    assert.ok(!existsSync(new URL("../assets/package-sources/appimage.svg", import.meta.url)));
});

test("the other sources keep their files, and every named file exists", () => {
    const assets = map("sourceAsset");
    assert.deepEqual(Object.keys(assets).sort(), ["flatpak", "nix", "snap"]);
    for (const path of Object.values(assets))
        assert.ok(existsSync(new URL("../Modals/Launcher/" + path, import.meta.url)), path);
});

test("the badge shows for a glyph as for a file, through AlpeIcon", () => {
    assert.match(badge, /^import qs\.Alpe\.Widgets$/m);
    assert.match(badge, /^    visible: badgeVisible && SettingsData\.launcherShowSourceBadges && \(assetPath\.length > 0 \|\| glyphName\.length > 0\)$/m);
    const icon = badge.match(/^    AlpeIcon \{\n([\s\S]*?)^    \}/m);
    assert.ok(icon);
    assert.match(icon[1], /name: root\.glyphName/);
    assert.match(icon[1], /visible: root\.glyphName\.length > 0/);
    const image = badge.match(/^    IconImage \{\n([\s\S]*?)^    \}/m);
    assert.match(image[1], /visible: root\.assetPath\.length > 0/);
});

test("deployed_code is a glyph the shell already uses from the same font", () => {
    const tabs = readFileSync(new URL("../Common/SettingsTabs.qml", import.meta.url), "utf8");
    assert.match(tabs, /"icon": "deployed_code"/);
});
