import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { loadScript } from "./qml-script.mjs";

// Standbild eines Video-Hintergrunds (Plan 0.8 Nr. 106): Videos des eingespielten Designs bringen ein gleichnamiges
// .jpg mit, das vor ffmpeg genommen wird – nur im Ordner des Designs, nie für eigene Videos der Nutzer.
const poster = loadScript(new URL("../Common/VideoPoster.js", import.meta.url));
const DESIGN = poster.designDir("/home/u/.local/share/alpe");

test("designDir: Ordner des eingespielten Designs mit Schrägstrich am Ende", () => {
    assert.equal(DESIGN, "/home/u/.local/share/alpe/design/");
    assert.equal(poster.designDir("/home/u/.local/share/alpe/"), "/home/u/.local/share/alpe/design/");
});

test("bundledPoster: Video im Ordner des Designs bekommt das gleichnamige .jpg", () => {
    assert.equal(poster.bundledPoster(DESIGN + "bilder/jagged-peaks-wolkenzug.mp4", DESIGN), DESIGN + "bilder/jagged-peaks-wolkenzug.jpg");
    assert.equal(poster.bundledPoster("file://" + DESIGN + "bilder/berg.webm", DESIGN), DESIGN + "bilder/berg.jpg");
});

test("bundledPoster: eigene Videos der Nutzer bekommen nichts", () => {
    assert.equal(poster.bundledPoster("/home/u/Videos/berg.mp4", DESIGN), "");
    assert.equal(poster.bundledPoster("/home/u/.local/share/alpe/designs/berg.mp4", DESIGN), "");
    assert.equal(poster.bundledPoster("/home/u/.local/share/alpe/design-alt/berg.mp4", DESIGN), "");
});

test("bundledPoster: kein Ausweg aus dem Ordner, keine leeren Angaben", () => {
    assert.equal(poster.bundledPoster(DESIGN + "../../Videos/berg.mp4", DESIGN), "");
    assert.equal(poster.bundledPoster(DESIGN + "bilder/ohne-endung", DESIGN), "");
    assert.equal(poster.bundledPoster("", DESIGN), "");
    assert.equal(poster.bundledPoster(DESIGN + "bilder/berg.mp4", ""), "");
    assert.equal(poster.bundledPoster("/design/berg.mp4", poster.designDir("")), "");
});

// Das Skript selbst mit sh, ohne ffmpeg im PATH: Mit mitgeliefertem Standbild endet es mit BUNDLED_EXIT, sonst mit
// 127 (ffmpeg fehlt) – das mitgelieferte Bild wird also vor ffmpeg genommen.
function skript(args) {
    return spawnSync("/bin/sh", ["-c", poster.script(), "sh", ...args], { env: { PATH: "/nonexistent" } }).status;
}

test("script: mitgeliefertes Standbild ohne ffmpeg, sonst 127", () => {
    const dir = mkdtempSync(join(tmpdir(), "alpe-poster-"));
    try {
        mkdirSync(join(dir, "bilder"));
        writeFileSync(join(dir, "bilder", "berg.mp4"), "VIDEO");
        writeFileSync(join(dir, "bilder", "berg.jpg"), "BILD");
        const cache = join(dir, "cache", "x.jpg");
        assert.equal(skript([cache, join(dir, "bilder", "berg.mp4"), join(dir, "bilder", "berg.jpg")]), poster.BUNDLED_EXIT);
        assert.equal(skript([cache, join(dir, "bilder", "berg.mp4"), ""]), 127, "eigenes Video: ohne ffmpeg kein Standbild");
        assert.equal(skript([cache, join(dir, "bilder", "berg.mp4"), join(dir, "bilder", "fehlt.jpg")]), 127, "Standbild fehlt: weiter zu ffmpeg");
    } finally {
        rmSync(dir, { recursive: true, force: true });
    }
});

test("outcome: Rückgabewert des Skripts", () => {
    assert.equal(poster.outcome(poster.BUNDLED_EXIT, "/d/berg.jpg"), "bundled");
    assert.equal(poster.outcome(poster.BUNDLED_EXIT, ""), "failed", "10 ohne mitgeliefertes Bild gilt nicht als Standbild");
    assert.equal(poster.outcome(127, "/d/berg.jpg"), "missing");
    assert.equal(poster.outcome(127, ""), "missing");
    assert.equal(poster.outcome(0, ""), "generated");
    assert.equal(poster.outcome(1, ""), "failed");
});

// Ablauf des Dienstes ohne ffmpeg, mit den reinen Funktionen und dem echten Skript (wie _next() in
// VideoWallpaperService.qml): Nach dem einen Lauf wartet framePending() nicht mehr, und request() stellt nicht
// erneut ein.
function ablauf(video, bundled) {
    const state = { ffmpegMissing: false, queued: false, failed: false, poster: "" };
    let aufrufe = 0;
    for (let runde = 0; runde < 5 && poster.mayRequest(bundled, state); runde++) {
        aufrufe++;
        const code = skript([join(tmpdir(), "alpe-poster-cache-nie", "x.jpg"), video, bundled]);
        const result = poster.outcome(code, bundled);
        if (result === "bundled")
            state.poster = bundled;
        else if (result === "missing") {
            state.failed = true;
            state.ffmpegMissing = true;
        } else if (result === "failed")
            state.failed = true;
    }
    return { aufrufe, pending: poster.pending(true, bundled, state), state };
}

test("Dienst ohne ffmpeg: Video des Designs ohne .jpg – ein Lauf, danach kein Warten", () => {
    const dir = mkdtempSync(join(tmpdir(), "alpe-poster-"));
    try {
        writeFileSync(join(dir, "berg.mp4"), "VIDEO");
        const r = ablauf(join(dir, "berg.mp4"), join(dir, "berg.jpg"));
        assert.equal(r.aufrufe, 1);
        assert.equal(r.pending, false, "framePending() wird falsch – Rückfall auf die Samenfarbe wie vorher");
        assert.equal(r.state.ffmpegMissing, true);
    } finally {
        rmSync(dir, { recursive: true, force: true });
    }
});

test("Dienst ohne ffmpeg: Video des Designs mit .jpg – mitgeliefertes Bild", () => {
    const dir = mkdtempSync(join(tmpdir(), "alpe-poster-"));
    try {
        writeFileSync(join(dir, "berg.mp4"), "VIDEO");
        writeFileSync(join(dir, "berg.jpg"), "BILD");
        const r = ablauf(join(dir, "berg.mp4"), join(dir, "berg.jpg"));
        assert.equal(r.aufrufe, 1);
        assert.equal(r.state.poster, join(dir, "berg.jpg"));
        assert.equal(r.pending, false);
    } finally {
        rmSync(dir, { recursive: true, force: true });
    }
});

test("Dienst ohne ffmpeg: eigenes Video – wie bisher kein Standbild, kein Warten", () => {
    const r = ablauf("/home/u/Videos/berg.mp4", "");
    assert.equal(r.aufrufe, 1);
    assert.equal(r.pending, false);
    assert.equal(poster.pending(true, "", { ffmpegMissing: true }), false, "ffmpeg fehlt: ein eigenes Video wartet nicht");
});

test("script: derselbe ffmpeg-Aufruf wie zuvor in VideoWallpaperService (Filter, Qualität)", () => {
    const s = poster.script();
    assert.ok(s.includes(`-vf "${poster.FILTER}" -frames:v 1 -q:v ${poster.QUALITY} `));
    assert.equal(poster.FILTER, "thumbnail=60,scale='min(3840,iw)':-2");
    assert.equal(poster.QUALITY, "2");
});
