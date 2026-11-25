import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import test from "node:test";
import vm from "node:vm";

// Nachtlauf vom 26.11.2026, Punkt 1.4 (Entscheid vom 25.11.2026): desktop-login.oga/.wav sind entfernt. Der
// Anmeldeklang fällt ohne Klang aus dem Systemthema still weg – keine Ersatzdatei, kein Fehler. Alle anderen
// Ereignisse behalten ihre mitgelieferte Datei, und jede genannte Datei liegt im Repository.

const FILE = "../Services/AudioService.qml";
const source = readFileSync(new URL(FILE, import.meta.url), "utf8");

function functionSource(name) {
    const found = source.match(new RegExp(`^    function ${name}\\([^)]*\\)(?:: \\w+)? \\{\\n[\\s\\S]*?^    \\}`, "m"));
    if (!found)
        throw new Error(`${name} not found in ${FILE}`);
    return found[0];
}

function service({ useSystemSoundTheme = false, soundFilePaths = {}, players = {} } = {}) {
    const calls = { played: [], logged: [] };
    const context = vm.createContext({
        SettingsData: { useSystemSoundTheme, soundsEnabled: true },
        currentSoundTheme: "freedesktop",
        soundFilePaths,
        soundThemeResolved: true,
        pendingSoundPlayer: "",
        soundsAvailable: true,
        notificationsAudioMuted: false,
        shouldMuteForMedia: () => false,
        ensurePlayers: () => {},
        Qt: { resolvedUrl: path => "file:///shell/Services/" + path },
        log: { debug() {}, info() {}, warn: (...a) => calls.logged.push(a), error: (...a) => calls.logged.push(a) }
    });
    context.root = context;
    for (const [name, src] of Object.entries(players))
        context[name] = { source: src, play: () => calls.played.push(name) };
    for (const name of ["getSoundPath", "playSound"])
        vm.runInContext(functionSource(name), context);
    return { context, calls };
}

test("desktop-login has no bundled file: empty source, not the message fallback", () => {
    const { context } = service();
    assert.equal(context.getSoundPath("desktop-login"), "");
});

test("desktop-login from the system sound theme still plays when the theme has it", () => {
    const { context } = service({ useSystemSoundTheme: true, soundFilePaths: { "desktop-login": "file:///usr/share/sounds/x/desktop-login.oga" } });
    assert.equal(context.getSoundPath("desktop-login"), "file:///usr/share/sounds/x/desktop-login.oga");
});

test("system theme switched on but without desktop-login: still empty", () => {
    const { context } = service({ useSystemSoundTheme: true, soundFilePaths: { message: "file:///m.oga" } });
    assert.equal(context.getSoundPath("desktop-login"), "");
});

test("the other events keep their bundled files", () => {
    const { context } = service();
    assert.match(context.getSoundPath("message"), /freedesktop\/message\.wav$/);
    assert.match(context.getSoundPath("message-new-instant"), /freedesktop\/message-new-instant\.wav$/);
    assert.match(context.getSoundPath("audio-volume-change"), /freedesktop\/audio-volume-change\.wav$/);
    assert.match(context.getSoundPath("power-plug"), /plasma\/power-plug\.wav$/);
});

test("playSound with an empty source plays nothing and logs nothing", () => {
    const { context, calls } = service({ players: { loginSound: "", normalNotificationSound: "file:///m.wav" } });
    context.playSound("loginSound");
    assert.deepEqual(calls.played, []);
    assert.deepEqual(calls.logged, []);
    context.playSound("normalNotificationSound");
    assert.deepEqual(calls.played, ["normalNotificationSound"]);
});

test("every bundled file named in AudioService.qml exists, desktop-login is gone", () => {
    const named = [...source.matchAll(/"\.\.\/assets\/sounds\/([^"]+)"/g)].map(m => m[1]);
    assert.ok(named.length >= 6);
    for (const path of named)
        assert.ok(existsSync(new URL("../assets/sounds/" + path, import.meta.url)), path);
    assert.ok(!named.some(path => path.includes("desktop-login")));
    for (const ext of ["oga", "wav"])
        assert.ok(!existsSync(new URL(`../assets/sounds/freedesktop/desktop-login.${ext}`, import.meta.url)));
});
