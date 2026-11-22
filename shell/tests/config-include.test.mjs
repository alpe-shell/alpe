import assert from "node:assert/strict";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { loadScript } from "./qml-script.mjs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import vm from "node:vm";
import test from "node:test";

const resolve = vm.createContext({});
vm.runInContext(readFileSync(new URL("../Common/ConfigIncludeResolve.js", import.meta.url), "utf8").replace(/^\.pragma.*$/m, ""), resolve);
const plain = value => JSON.parse(JSON.stringify(value));

test("includePaths joins the compositor directory, with hypr for hyprland", () => {
    const hyprland = resolve.includePaths("layout", "hyprland", "/home/u/.config");
    assert.equal(hyprland.configFile, "/home/u/.config/hypr/hyprland.lua");
    assert.deepEqual(plain(hyprland.fragmentFiles), ["/home/u/.config/hypr/alpe/layout.lua"]);
    assert.equal(resolve.includePaths("colors", "kwin", "/home/u/.config"), null, "no spec, no paths");
});

test("resolveIncludeArgs names the compositor and the fragment", () => {
    assert.deepEqual(plain(resolve.resolveIncludeArgs("windowrules", "hyprland")), ["hyprland", "windowrules.lua"]);
    assert.equal(resolve.resolveIncludeArgs("colors", "kwin"), null, "no spec, no args");
});

test("repair preserves config and fragments, backs up, and adds live includes only once", t => {
    const directory = mkdtempSync(join(tmpdir(), "dms-includes-"));
    t.after(() => rmSync(directory, { recursive: true, force: true }));
    for (const [compositor, kind, prefix] of [["hyprland", "binds", "--"]]) {
        const configDir = join(directory, compositor + " space's");
        const paths = resolve.includePaths(kind, compositor, configDir);
        mkdirSync(dirname(paths.configFile), { recursive: true });
        const original = prefix + " user config\n" + paths.includes.map(entry => prefix + " " + entry.includeLine + "\n").join("");
        writeFileSync(paths.configFile, original);
        const fragment = paths.fragmentFiles[0];
        mkdirSync(dirname(fragment), { recursive: true });
        writeFileSync(fragment, "existing fragment\n");
        const backup = paths.configFile + ".backup";
        execFileSync("sh", ["-c", resolve.repairScriptFor(kind, compositor, configDir, backup)]);
        assert.equal(readFileSync(backup, "utf8"), original);
        assert.equal(readFileSync(fragment, "utf8"), "existing fragment\n");
        for (const file of paths.fragmentFiles)
            assert.ok(existsSync(file));
        const repaired = readFileSync(paths.configFile, "utf8");
        assert.ok(repaired.startsWith(original));
        const live = repaired.split("\n").filter(line => !line.trimStart().startsWith(prefix));
        for (const { includeLine } of paths.includes)
            assert.equal(live.filter(line => line === includeLine).length, 1);
        if (compositor === "hyprland")
            assert.ok(live.indexOf(paths.includes[0].includeLine) < live.indexOf(paths.includes[1].includeLine));
        execFileSync("sh", ["-c", resolve.repairScriptFor(kind, compositor, configDir, "")]);
        assert.equal(readFileSync(paths.configFile, "utf8"), repaired);
    }
});


// Alpe: Ein Abschnitt mit der Kopfzeile aus DMS bzw. Alpe 1.0 bekommt keine zweite Kopfzeile.
test("repair appends below a legacy DMS section header instead of adding a new one", t => {
    const directory = mkdtempSync(join(tmpdir(), "alpe-includes-"));
    t.after(() => rmSync(directory, { recursive: true, force: true }));
    const paths = resolve.includePaths("layout", "hyprland", directory);
    mkdirSync(dirname(paths.configFile), { recursive: true });
    writeFileSync(paths.configFile, "-- user config\n\n-- DMS Include Configs\nrequire(\"dms.colors\")\n");
    execFileSync("sh", ["-c", resolve.repairScriptFor("layout", "hyprland", directory, "")]);
    const repaired = readFileSync(paths.configFile, "utf8");
    assert.equal(repaired.includes("Alpe: eingebundene Dateien"), false);
    assert.ok(repaired.includes("-- DMS Include Configs\nrequire(\"dms.colors\")\n" + paths.includes[0].includeLine));
});

test("a fresh config gets the Alpe section header", t => {
    const directory = mkdtempSync(join(tmpdir(), "alpe-includes-"));
    t.after(() => rmSync(directory, { recursive: true, force: true }));
    const paths = resolve.includePaths("layout", "hyprland", directory);
    mkdirSync(dirname(paths.configFile), { recursive: true });
    writeFileSync(paths.configFile, "-- user config\n");
    execFileSync("sh", ["-c", resolve.repairScriptFor("layout", "hyprland", directory, "")]);
    assert.ok(readFileSync(paths.configFile, "utf8").includes("\n-- Alpe: eingebundene Dateien\n" + paths.includes[0].includeLine));
});
