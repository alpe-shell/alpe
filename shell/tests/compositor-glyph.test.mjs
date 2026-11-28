import assert from "node:assert/strict";
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import vm from "node:vm";
import { loadScript } from "./qml-script.mjs";

// Nachtlauf vom 28.11.2026, Punkt 2.2 (Entscheid vom 28.11.2026, Plan 0.8 Nr. 143): Das Zeichen von Hyprland
// (shell/assets/hyprland.svg) ist entfernt. Prozessliste und Starter-Knopf zeigen dafür das neutrale Symbol
// «team_dashboard» aus der mitgelieferten Symbolschrift – auf Arch und Fedora gleich.

const GLYPH = "team_dashboard";
const shell = fileURLToPath(new URL("..", import.meta.url));
const read = path => readFileSync(join(shell, path), "utf8");
const FONT = "Alpe/assets/fonts/material-design-icons/variablefont/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf";

// ProcessIcons.js als Bibliothek, wie QML sie einbindet (const auf oberster Ebene liegt nicht auf dem Kontext)
function processIcons() {
    const context = loadScript(new URL("../Modules/ProcessList/ProcessIcons.js", import.meta.url));
    return { PROGRAM_ICONS: vm.runInContext("PROGRAM_ICONS", context) };
}

// Glyphennamen aus der Tabelle «post» (Format 2.0) einer TrueType-Schrift; Material Symbols benennt die Glyphe wie die
// Ligatur, die AlpeIcon über den Text auslöst.
function glyphNames(buffer) {
    const tables = buffer.readUInt16BE(4);
    let post = -1;
    for (let i = 0; i < tables; i++) {
        const record = 12 + i * 16;
        if (buffer.toString("latin1", record, record + 4) === "post")
            post = buffer.readUInt32BE(record + 8);
    }
    assert.ok(post >= 0, "Schrift ohne Tabelle post");
    assert.equal(buffer.readUInt32BE(post), 0x00020000, "post ist nicht Format 2.0");
    const count = buffer.readUInt16BE(post + 32);
    const indices = [];
    for (let i = 0; i < count; i++)
        indices.push(buffer.readUInt16BE(post + 34 + 2 * i));
    const extra = [];
    let at = post + 34 + 2 * count;
    while (extra.length < Math.max(0, ...indices) - 257) {
        const length = buffer[at];
        extra.push(buffer.toString("latin1", at + 1, at + 1 + length));
        at += 1 + length;
    }
    return new Set(indices.filter(i => i >= 258).map(i => extra[i - 258]));
}

test("the glyph is in the bundled symbol font, next to the AppImage glyph", () => {
    const names = glyphNames(readFileSync(join(shell, FONT)));
    assert.ok(names.has(GLYPH));
    assert.ok(names.has("deployed_code"));
    assert.ok(!names.has("team_dashboard_gibt_es_nicht"));
});

test("the glyph means nothing else in the shell: only the process list and the launcher logo use it", () => {
    const hits = [];
    const walk = dir => {
        for (const name of readdirSync(dir)) {
            const path = join(dir, name);
            if (statSync(path).isDirectory()) {
                if (!["fonts", "tests", "node_modules"].includes(name))
                    walk(path);
            } else if (/\.(qml|js|mjs|json)$/.test(name) && readFileSync(path, "utf8").includes(GLYPH)) {
                hits.push(path.slice(shell.length));
            }
        }
    };
    walk(shell);
    assert.deepEqual(hits.sort(), ["Modules/ProcessList/ProcessIcons.js", "Widgets/LauncherLogo.qml"]);
});

test("the Hyprland mark is gone: no file, no reference", () => {
    assert.ok(!existsSync(join(shell, "assets/hyprland.svg")));
    for (const path of ["Modules/ProcessList/ProcessIcons.js", "Widgets/LauncherLogo.qml", "Modules/ProcessList/ProcessListMetrics.qml"])
        assert.ok(!read(path).includes("hyprland.svg"), path);
});

test("process rows: Hyprland gets the glyph, no logo file; every remaining logo file exists", () => {
    const rows = processIcons().PROGRAM_ICONS;
    const row = rows.find(r => r.programs.includes("hyprland"));
    assert.ok(row.programs.includes("start-hyprland"));
    assert.equal(row.glyph, GLYPH);
    assert.equal(row.logo, undefined);
    for (const r of rows.filter(r => r.logo))
        assert.ok(existsSync(join(shell, "assets", r.logo)), r.logo);
});

// appGlyph und appIcon aus ProcessListMetrics.qml, mit Attrappen für das Übrige
function metrics(processes, icons, entries) {
    const source = read("Modules/ProcessList/ProcessListMetrics.qml");
    const wanted = ["programName", "programRow", "appGlyph", "appIcon"];
    const functions = [...source.matchAll(/^    function (\w+)\(([^)]*)\) \{\n([\s\S]*?)^    \}$/gm)]
        .filter(m => wanted.includes(m[1]))
        .map(m => `function ${m[1]}(${m[2]}) {\n${m[3]}}`);
    assert.equal(functions.length, wanted.length);
    const context = vm.createContext({
        ProcessIcons: processIcons(),
        _appMemo: { byPid: new Map(processes.map(p => [p.pid, p])) },
        indexProcesses() {},
        ownIcon: process => icons[process.pid] ?? "",
        appEntry: process => entries[process.pid] ?? null
    });
    vm.runInContext(functions.join("\n"), context);
    return context;
}

test("a Hyprland process shows its glyph, also by executable path, and does not take the icon of a parent app", () => {
    const session = { pid: 1, ppid: 0, command: "kitty" };
    const hypr = { pid: 2, ppid: 1, command: "Hyprland", executablePath: "/usr/bin/Hyprland" };
    const starter = { pid: 3, ppid: 1, command: "start-hyprland", fullCommand: "/usr/bin/start-hyprland --x" };
    const m = metrics([session, hypr, starter], { 1: "file:///kitty.svg" }, { 1: { id: "kitty" } });
    assert.equal(m.appGlyph(hypr), GLYPH);
    assert.equal(m.appGlyph(starter), GLYPH);
    assert.equal(m.appIcon(hypr, null), "");
    assert.equal(m.appIcon(starter, null), "");
});

test("other processes keep the old behaviour: own icon first, else the icon of the closest parent app", () => {
    const app = { pid: 1, ppid: 0, command: "kitty" };
    const child = { pid: 2, ppid: 1, command: "zsh" };
    const docker = { pid: 3, ppid: 1, command: "dockerd" };
    const m = metrics([app, child, docker], { 1: "file:///kitty.svg", 3: "file:///docker.svg" }, { 1: { id: "kitty" } });
    assert.equal(m.appGlyph(child), "");
    assert.equal(m.appIcon(child, null), "file:///kitty.svg");
    assert.equal(m.appIcon(docker, null), "file:///docker.svg");
    // Ein Symbol der Themen geht dem Glyph vor: hat Hyprland ein eigenes Symbol, zeigt die Zeile es
    const hypr = { pid: 4, ppid: 1, command: "Hyprland" };
    assert.equal(metrics([app, hypr], { 4: "file:///own.svg" }, {}).appIcon(hypr, null), "file:///own.svg");
});

test("the rows draw the glyph in place of the initial", () => {
    for (const path of ["Modules/ProcessList/ProcessRow.qml", "Modules/ProcessList/ProcessDetailStrip.qml"]) {
        const source = read(path);
        assert.match(source, /readonly property string glyph: ProcessListMetrics\.appGlyph\(root\.\w+\)/, path);
        assert.match(source, /id: initialBox\n/, path);
        assert.match(source, /AlpeIcon \{\n\s+anchors\.centerIn: parent\n\s+visible: initialBox\.glyph\.length > 0\n\s+name: initialBox\.glyph/, path);
        assert.match(source, /visible: initialBox\.glyph\.length === 0\n\s+text: root\.command\.charAt\(0\)\.toUpperCase\(\)/, path);
    }
});

test("the launcher logo in compositor mode shows the glyph under Hyprland, nothing under KWin", () => {
    const logo = read("Widgets/LauncherLogo.qml");
    const glyph = logo.match(/readonly property string compositorGlyph: \{\n([\s\S]*?)\n    \}/);
    assert.ok(glyph);
    assert.match(glyph[1], /case "hyprland":\n\s+return "team_dashboard";\n\s+default:\n\s+return "";/);
    assert.ok(!logo.includes("compositorSource"));
    const icon = logo.match(/^    AlpeIcon \{\n((?:        .*\n)+)^    \}/gm).find(block => block.includes("compositorGlyph"));
    assert.ok(icon);
    assert.match(icon, /visible: root\.resolvedMode === "compositor" && root\.compositorGlyph\.length > 0/);
    assert.match(icon, /name: root\.compositorGlyph/);
    assert.match(icon, /color: root\.colorize \? root\.resolvedColor : root\.appsIconColor/);
});
