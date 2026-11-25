import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import vm from "node:vm";

// Nachtlauf E1 2.7 (offene-faelle.md, «pkill -x wireplumber»): Ohne das Programm systemctl
// (SessionService.systemctlCommandAvailable) startet die Oberfläche WirePlumber nicht neu, beendet keinen Prozess
// über seinen Namen und zeigt stattdessen einen Hinweis.

const FILE = "../Services/AudioService.qml";
const source = readFileSync(new URL(FILE, import.meta.url), "utf8");

function functionSource(name) {
    const found = source.match(new RegExp(`^    function ${name}\\([^)]*\\)(?:: \\w+)? \\{\\n[\\s\\S]*?^    \\}`, "m"));
    if (!found)
        throw new Error(`${name} not found in ${FILE}`);
    return found[0];
}

function service(systemctlAvailable) {
    const calls = { run: [], detached: [], info: [], error: [], started: 0, completed: [] };
    const context = vm.createContext({
        freebsdAudio: false,
        wireplumberReloading: false,
        SessionService: { systemctlCommandAvailable: systemctlAvailable },
        Proc: { runCommand: (id, command, callback) => calls.run.push({ id, command, callback }) },
        Quickshell: { execDetached: command => calls.detached.push(command) },
        ToastService: { showInfo: (...args) => calls.info.push(args), showError: (...args) => calls.error.push(args) },
        I18n: { tr: text => text },
        log: { error() {} },
        wireplumberReloadStarted: () => calls.started++,
        wireplumberReloadCompleted: success => calls.completed.push(success)
    });
    for (const name of ["wireplumberRestartCommand", "reloadWireplumberConfig"])
        vm.runInContext(functionSource(name), context);
    return { context, calls };
}

test("without systemctl: no restart, no process ended by name, a hint instead", () => {
    const { context, calls } = service(false);
    context.reloadWireplumberConfig();
    assert.deepEqual(calls.run, []);
    assert.deepEqual(calls.detached, []);
    assert.equal(calls.info.length, 1);
    assert.equal(calls.info[0][0], "Device names saved");
    assert.match(calls.info[0][1], /not restarted/);
    assert.deepEqual(calls.error, []);
    assert.deepEqual(calls.completed, [false]);
    assert.equal(calls.started, 0);
    assert.equal(context.wireplumberReloading, false);
});

test("with systemctl: restart through the user manager only", () => {
    const { context, calls } = service(true);
    context.reloadWireplumberConfig();
    assert.equal(calls.run.length, 1);
    assert.deepEqual([...calls.run[0].command], ["systemctl", "--user", "restart", "wireplumber"]);
    assert.equal(context.wireplumberReloading, true);
    calls.run[0].callback("", 0);
    assert.equal(context.wireplumberReloading, false);
    assert.deepEqual(calls.completed, [true]);
    assert.deepEqual(calls.detached, []);
});

test("with systemctl but no running user manager: restart fails with an error, still no pkill", () => {
    const { context, calls } = service(true);
    context.reloadWireplumberConfig();
    calls.run[0].callback("Failed to connect to bus", 1);
    assert.equal(calls.error.length, 1);
    assert.deepEqual(calls.completed, [false]);
    assert.deepEqual(calls.detached, []);
});

test("AudioService.qml no longer ends processes by name", () => {
    assert.doesNotMatch(source, /\bpkill\b|\bkillall\b/);
    assert.doesNotMatch(functionSource("reloadWireplumberConfig"), /execDetached|"sh", "-c"/);
});
