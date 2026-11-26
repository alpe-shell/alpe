import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import vm from "node:vm";

// Nachtlauf vom 26.11.2026, Punkt 1.4 (Entscheid vom 25.11.2026): desktop-login.oga/.wav sind entfernt. Der
// Anmeldeklang fällt ohne Klang aus dem Systemthema still weg – keine Ersatzdatei, kein Fehler.
// Nachtlauf vom 27.11.2026, Punkt 1.1 (Entscheid vom 26.11.2026): audio-volume-change, message und message-new-instant
// kommen aus dem installierten freedesktop-Klangthema ($XDG_DATA_DIRS/sounds/freedesktop/stereo), auch ohne
// Systemthema; fehlt die Datei, bleibt es still. Mitgeliefert sind nur noch die Klänge von Harmony 2; der Sonderfall
// «smooth» bleibt (Lautstärke nach dem Standard). Der Schalter «Anmeldeklang» erscheint nur, wenn das gewählte
// Systemthema den Klang hat.

const FILE = "../Services/AudioService.qml";
const source = readFileSync(new URL(FILE, import.meta.url), "utf8");
const FD = "/usr/share/sounds/freedesktop/stereo/";
const FREEDESKTOP = {
    "audio-volume-change": "file://" + FD + "audio-volume-change.oga",
    "message": "file://" + FD + "message.oga",
    "message-new-instant": "file://" + FD + "message-new-instant.oga"
};

function functionSource(name) {
    const found = source.match(new RegExp(`^    function ${name}\\([^)]*\\)(?:: \\w+)? \\{\\n[\\s\\S]*?^    \\}`, "m"));
    if (!found)
        throw new Error(`${name} not found in ${FILE}`);
    return found[0];
}

const EVENTS = JSON.parse(source.match(/readonly property var freedesktopSoundEvents: (\[[^\]]*\])/)[1]);

// runCommand: «run» führt den Befehl wirklich aus (sh), sonst wird er nur festgehalten
function service({ useSystemSoundTheme = false, soundFilePaths = {}, players = {}, theme = "freedesktop",
                   freedesktopSoundPaths = FREEDESKTOP, freedesktopSoundsResolved = true, soundThemeResolved = true,
                   env = {}, run = false } = {}) {
    const calls = { played: [], logged: [], commands: [] };
    const context = vm.createContext({
        SettingsData: { useSystemSoundTheme, soundsEnabled: true },
        currentSoundTheme: theme,
        soundFilePaths,
        freedesktopSoundEvents: EVENTS,
        freedesktopSoundPaths,
        freedesktopSoundsResolved,
        soundThemeResolved,
        pendingSoundPlayer: "",
        soundsAvailable: true,
        notificationsAudioMuted: false,
        shouldMuteForMedia: () => false,
        ensurePlayers: () => {},
        Quickshell: { env: name => env[name] },
        Proc: {
            runCommand(id, command, callback) {
                calls.commands.push({ id, command });
                if (!run)
                    return;
                const result = spawnSync(command[0], command.slice(1), { encoding: "utf8", env: { PATH: process.env.PATH } });
                callback(result.stdout, result.status);
            }
        },
        Qt: { resolvedUrl: path => "file:///shell/Services/" + path },
        log: { debug() {}, info() {}, warn: (...a) => calls.logged.push(a), error: (...a) => calls.logged.push(a) }
    });
    context.root = context;
    for (const [name, src] of Object.entries(players))
        context[name] = { source: src, play: () => calls.played.push(name) };
    for (const name of ["getSoundPath", "defaultSoundPath", "playSound", "soundsResolved", "playPendingSound",
                        "markSoundThemeResolved", "freedesktopSoundDirs", "fileUrl", "discoverFreedesktopSounds"])
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

test("the three freedesktop events come from the installed theme, also without a system theme", () => {
    assert.deepEqual(EVENTS, ["audio-volume-change", "message", "message-new-instant"]);
    const { context } = service();
    for (const event of EVENTS)
        assert.equal(context.getSoundPath(event), FREEDESKTOP[event]);
    assert.match(context.getSoundPath("power-plug"), /plasma\/power-plug\.wav$/);
    assert.match(context.getSoundPath("power-unplug"), /plasma\/power-unplug\.wav$/);
});

test("a missing freedesktop file stays silent: empty source, no bundled fallback, nothing played or logged", () => {
    const { context, calls } = service({ freedesktopSoundPaths: { message: FREEDESKTOP.message } });
    assert.equal(context.getSoundPath("audio-volume-change"), "");
    assert.equal(context.getSoundPath("message-new-instant"), "");
    assert.equal(context.getSoundPath("message"), FREEDESKTOP.message);
    assert.equal(context.getSoundPath("unknown-event"), "");
    context.volumeChangeSound = { source: context.getSoundPath("audio-volume-change"), play: () => calls.played.push("volumeChangeSound") };
    context.playSound("volumeChangeSound");
    assert.deepEqual(calls.played, []);
    assert.deepEqual(calls.logged, []);
});

test("a chosen system theme still wins where it has the sound", () => {
    const own = "file:///usr/share/sounds/ocean/stereo/message-new-email.oga";
    const { context } = service({ useSystemSoundTheme: true, theme: "ocean", soundFilePaths: { message: own } });
    assert.equal(context.getSoundPath("message"), own);
    assert.equal(context.getSoundPath("message-new-instant"), FREEDESKTOP["message-new-instant"]);
});

test("special case smooth: the volume sound follows the freedesktop default, not the theme", () => {
    const smooth = { "audio-volume-change": "file:///usr/share/sounds/Smooth/stereo/audio-volume-change.oga" };
    const { context } = service({ useSystemSoundTheme: true, theme: "Smooth", soundFilePaths: smooth });
    assert.equal(context.getSoundPath("audio-volume-change"), FREEDESKTOP["audio-volume-change"]);
    const ohne = service({ useSystemSoundTheme: true, theme: "smooth", soundFilePaths: smooth, freedesktopSoundPaths: {} });
    assert.equal(ohne.context.getSoundPath("audio-volume-change"), "");
});

test("playSound with an empty source plays nothing and logs nothing", () => {
    const { context, calls } = service({ players: { loginSound: "", normalNotificationSound: "file:///m.wav" } });
    context.playSound("loginSound");
    assert.deepEqual(calls.played, []);
    assert.deepEqual(calls.logged, []);
    context.playSound("normalNotificationSound");
    assert.deepEqual(calls.played, ["normalNotificationSound"]);
});

test("discovery: first file along XDG_DATA_DIRS, only sounds/freedesktop/stereo, URL-encoded, missing ones left out", () => {
    const tmp = mkdtempSync(join(tmpdir(), "alpe-sounds-"));
    try {
        const first = join(tmp, "eins #1"), second = join(tmp, "zwei");
        for (const dir of [first, second])
            mkdirSync(join(dir, "sounds", "freedesktop", "stereo"), { recursive: true });
        mkdirSync(join(tmp, "drei", "sounds", "freedesktop"), { recursive: true });
        writeFileSync(join(first, "sounds", "freedesktop", "stereo", "message.oga"), "");
        writeFileSync(join(second, "sounds", "freedesktop", "stereo", "message.oga"), "");
        writeFileSync(join(second, "sounds", "freedesktop", "stereo", "audio-volume-change.ogg"), "");
        // nicht unter stereo/ und nicht im Ordner eines anderen Themas: zählt nicht
        writeFileSync(join(tmp, "drei", "sounds", "freedesktop", "message-new-instant.oga"), "");
        const { context, calls } = service({ freedesktopSoundPaths: {}, freedesktopSoundsResolved: false, run: true,
                                             env: { XDG_DATA_DIRS: `${first}::${second}/:${join(tmp, "drei")}` } });
        context.discoverFreedesktopSounds();
        assert.equal(calls.commands.length, 1);
        assert.deepEqual(Array.from(calls.commands[0].command.slice(4)), [first, second, join(tmp, "drei")].map(d => d + "/sounds/freedesktop/stereo"));
        assert.equal(context.freedesktopSoundsResolved, true);
        assert.deepEqual(Object.keys(context.freedesktopSoundPaths).sort(), ["audio-volume-change", "message"]);
        assert.equal(context.freedesktopSoundPaths.message, "file://" + join(tmp, "eins%20%231", "sounds", "freedesktop", "stereo", "message.oga"));
        assert.equal(context.freedesktopSoundPaths["audio-volume-change"], "file://" + join(second, "sounds", "freedesktop", "stereo", "audio-volume-change.ogg"));
    } finally {
        rmSync(tmp, { recursive: true, force: true });
    }
});

test("discovery without XDG_DATA_DIRS: /usr/local/share, then /usr/share (XDG Base Directory)", () => {
    const { context, calls } = service({ freedesktopSoundsResolved: false });
    context.discoverFreedesktopSounds();
    // Arrays aus dem vm-Kontext haben einen fremden Prototyp: vor dem Vergleich kopieren
    assert.deepEqual(Array.from(calls.commands[0].command.slice(0, 2)), ["sh", "-c"]);
    assert.deepEqual(Array.from(calls.commands[0].command.slice(4)), ["/usr/local/share/sounds/freedesktop/stereo", "/usr/share/sounds/freedesktop/stereo"]);
});

test("a sound asked for before discovery waits and plays once the paths are known", () => {
    const { context, calls } = service({ freedesktopSoundPaths: {}, freedesktopSoundsResolved: false, run: true, env: { XDG_DATA_DIRS: "/nonexistent-alpe" },
                                         players: { normalNotificationSound: "file:///m.oga" } });
    context.playSound("normalNotificationSound");
    assert.deepEqual(calls.played, []);
    assert.equal(context.pendingSoundPlayer, "normalNotificationSound");
    context.discoverFreedesktopSounds();
    assert.deepEqual(calls.played, ["normalNotificationSound"]);
    // mit Systemthema wartet er auch auf dessen Pfade
    const both = service({ useSystemSoundTheme: true, soundThemeResolved: false, players: { normalNotificationSound: "file:///m.oga" } });
    both.context.playSound("normalNotificationSound");
    assert.deepEqual(both.calls.played, []);
    both.context.markSoundThemeResolved();
    assert.deepEqual(both.calls.played, ["normalNotificationSound"]);
});

test("startup always looks up the freedesktop sounds", () => {
    const completed = source.match(/^    Component\.onCompleted: \{\n([\s\S]*?)^    \}/m)[1];
    assert.match(completed, /^        discoverFreedesktopSounds\(\);$/m);
});

test("only Harmony 2 is bundled: no freedesktop copies, every named file exists, desktop-login is gone", () => {
    const named = [...source.matchAll(/"\.\.\/assets\/sounds\/([^"]+)"/g)].map(m => m[1]);
    assert.deepEqual(named.sort(), ["plasma/power-plug.wav", "plasma/power-unplug.wav"]);
    for (const path of named)
        assert.ok(existsSync(new URL("../assets/sounds/" + path, import.meta.url)), path);
    assert.ok(!existsSync(new URL("../assets/sounds/freedesktop", import.meta.url)));
});

test("the login switch shows only when the chosen system theme has the sound", () => {
    const tab = readFileSync(new URL("../Modules/Settings/SoundsTab.qml", import.meta.url), "utf8");
    const key = tab.indexOf('settingKey: "soundLogin"');
    assert.ok(key > 0);
    const row = tab.slice(tab.lastIndexOf("SettingsToggleRow {", key), tab.indexOf("\n            }", key));
    assert.match(row, /^\s+visible: SettingsData\.useSystemSoundTheme && !!AudioService\.soundFilePaths\["desktop-login"\]$/m);
});
