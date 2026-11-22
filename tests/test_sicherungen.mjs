// Sicherungen aus 1.0 (gtk-theme.dms-backup, icon-theme.dms-backup) werden nie umbenannt, gelöscht
// oder verändert (Plan 0.8 Nr. 57). Der Test führt die Skripte aus, die die Shell ausführt
// (shell/Common/settings/Sicherungen.js), in einem Temp-Ordner und ohne gsettings/dconf.
//
//     node --test tests/test_sicherungen.mjs      nimmt shell/ im Repository (oder ALPE_SHELL_DIR)
import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, statSync, utimesSync, writeFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const shellDir = process.env.ALPE_SHELL_DIR || path.join(here, "..", "shell");
const { loadScript } = await import(pathToFileURL(path.join(shellDir, "tests", "qml-script.mjs")).href);
const S = loadScript(pathToFileURL(path.join(shellDir, "Common", "settings", "Sicherungen.js")));

// Ordner mit Leerzeichen und Apostroph: Die Skripte müssen richtig quoten.
function setup(t) {
    const root = mkdtempSync(path.join(os.tmpdir(), "alpe sicherung's-"));
    t.after(() => rmSync(root, { recursive: true, force: true }));
    const config = path.join(root, "config"), state = path.join(root, "state", "alpe");
    mkdirSync(path.join(config, "gtk-3.0"), { recursive: true });
    return { config, state, gtk: path.join(config, "gtk-3.0") };
}

// Alte Sicherung mit festem Zeitstempel anlegen; gibt eine Prüfung zurück, dass sie unverändert ist.
function legacy(dir, name, content) {
    const file = path.join(dir, name);
    writeFileSync(file, content);
    const stamp = new Date("2026-03-01T12:00:00Z");
    utimesSync(file, stamp, stamp);
    const before = statSync(file);
    return () => {
        assert.ok(existsSync(file), name + " ist noch da");
        assert.equal(readFileSync(file, "utf8"), content, name + " hat denselben Inhalt");
        const after = statSync(file);
        assert.equal(after.mtimeMs, before.mtimeMs, name + " wurde nicht neu geschrieben");
        assert.equal(after.ino, before.ino, name + " ist dieselbe Datei");
    };
}

const sh = script => execFileSync("sh", ["-c", script], { encoding: "utf8" });
const current = theme => `printf '%s' ${S.quote(theme)}`;

test("Symbolthema: Sicherung aus 1.0 kommt zurück, die alte Datei bleibt unverändert", t => {
    const d = setup(t);
    const unchanged = legacy(d.gtk, S.ICON_THEME_1_0, "Papirus\n");
    const out = sh(S.iconThemeRestoreScript(d.config, d.state, current("Alpe-Icons"), "Alpe-Icons"));
    assert.equal(out, "restore:Papirus");
    unchanged();
    assert.equal(existsSync(path.join(d.gtk, S.ICON_THEME)), false, "die Kopie ist verbraucht");
    assert.ok(existsSync(path.join(d.state, S.ICON_THEME_MARKER)), "Marke im Zustandsordner");
});

test("Symbolthema: die Sicherung aus 1.0 gilt nur einmal", t => {
    const d = setup(t);
    const unchanged = legacy(d.gtk, S.ICON_THEME_1_0, "Papirus\n");
    sh(S.iconThemeRestoreScript(d.config, d.state, current("Alpe-Icons"), "Alpe-Icons"));
    // Später stellt jemand ein anderes Thema ein und Alpe übernimmt wieder: neue Sicherung, nicht die alte.
    sh(S.iconThemeBackupScript(d.config, d.state, current("breeze"), "Alpe-Icons"));
    assert.equal(readFileSync(path.join(d.gtk, S.ICON_THEME), "utf8"), "breeze\n");
    assert.equal(sh(S.iconThemeRestoreScript(d.config, d.state, current("Alpe-Icons"), "Alpe-Icons")), "restore:breeze");
    assert.equal(sh(S.iconThemeRestoreScript(d.config, d.state, current("Alpe-Icons"), "Alpe-Icons")), "Alpe-Icons");
    unchanged();
});

test("Symbolthema: mit Sicherung aus 1.0 wird keine neue geschrieben", t => {
    const d = setup(t);
    const unchanged = legacy(d.gtk, S.ICON_THEME_1_0, "Papirus\n");
    sh(S.iconThemeBackupScript(d.config, d.state, current("breeze"), "Alpe-Icons"));
    assert.equal(readFileSync(path.join(d.gtk, S.ICON_THEME), "utf8"), "Papirus\n", "Kopie der alten Sicherung");
    unchanged();
});

test("Symbolthema: der neue Name gewinnt, die alte Sicherung bleibt trotzdem", t => {
    const d = setup(t);
    const unchanged = legacy(d.gtk, S.ICON_THEME_1_0, "Papirus\n");
    writeFileSync(path.join(d.gtk, S.ICON_THEME), "Tela\n");
    assert.equal(sh(S.iconThemeRestoreScript(d.config, d.state, current("Alpe-Icons"), "Alpe-Icons")), "restore:Tela");
    assert.equal(sh(S.iconThemeRestoreScript(d.config, d.state, current("Alpe-Icons"), "Alpe-Icons")), "Alpe-Icons", "die alte gilt danach nicht mehr");
    unchanged();
});

test("Symbolthema: ohne Sicherung aus 1.0 entsteht weder Kopie noch Marke", t => {
    const d = setup(t);
    assert.equal(sh(S.iconThemeRestoreScript(d.config, d.state, current("breeze"), "Alpe-Icons")), "breeze");
    assert.equal(existsSync(d.state), false);
    sh(S.iconThemeBackupScript(d.config, d.state, current("breeze"), "Alpe-Icons"));
    assert.equal(readFileSync(path.join(d.gtk, S.ICON_THEME), "utf8"), "breeze\n");
    assert.equal(existsSync(d.state), false);
});

test("GTK-Thema: Sicherung aus 1.0 gilt weiter und bleibt unverändert", t => {
    const d = setup(t);
    const unchanged = legacy(d.gtk, S.GTK_THEME_1_0, "Breeze\n");
    sh(`cur=Materia; ${S.gtkThemeBackupStep(d.config)}`);
    unchanged();
    assert.equal(existsSync(path.join(d.gtk, S.GTK_THEME)), false, "keine zweite Sicherung");
});

test("GTK-Thema: ohne Sicherung wird unter dem neuen Namen gesichert, einmal", t => {
    const d = setup(t);
    sh(`cur=Materia; ${S.gtkThemeBackupStep(d.config)}`);
    sh(`cur=Anderes; ${S.gtkThemeBackupStep(d.config)}`);
    assert.equal(readFileSync(path.join(d.gtk, S.GTK_THEME), "utf8"), "Materia\n");
    assert.equal(existsSync(path.join(d.gtk, S.GTK_THEME_1_0)), false);
});

test("die Shell benutzt diese Skripte und benennt keine Sicherung um", () => {
    const settings = readFileSync(path.join(shellDir, "Common", "SettingsData.qml"), "utf8");
    const theme = readFileSync(path.join(shellDir, "Common", "Theme.qml"), "utf8");
    assert.match(settings, /Sicherungen\.iconThemeRestoreScript\(/);
    assert.match(settings, /Sicherungen\.iconThemeBackupScript\(/);
    assert.match(theme, /Sicherungen\.gtkThemeBackupStep\(/);
    for (const [name, text] of [["SettingsData.qml", settings], ["Theme.qml", theme]])
        assert.doesNotMatch(text, /\.(dms|alpe)-backup/, name + ": Namen der Sicherungen stehen nur in Sicherungen.js");
    const helper = readFileSync(path.join(shellDir, "Common", "settings", "Sicherungen.js"), "utf8").replace(/^\s*\/\/.*$/gm, "");
    assert.doesNotMatch(helper, /\bmv\b/, "Sicherungen.js: kein mv");
});
