import assert from "node:assert/strict";
import test from "node:test";
import { loadScript } from "./qml-script.mjs";

// Nachtlauf vom 26.11.2026, Punkt 1.9 (Entscheid vom 25.11.2026): In der Material-Vorlage «alpe» liegen softBurst und
// alpeLogo gemeinsam auf der Mitte 0,453. Mit 0,45 endeten zwei Täler zwischen den unteren Zacken von softBurst
// knapp über dem unteren Bildrand (bei y/H ≈ 0,9986), und der dunkle Grund schien dort als zwei Bogen durch. Nach
// place() hängt die Höhe eines Punkts im Querformat nur von H ab; der Test rechnet trotzdem mehrere Formate nach.

const wallpaper = loadScript(new URL("../Alpe/Common/MaterialWallpaper.js", import.meta.url));

// Zeichenfläche, die nur die Abbildung von place() mitschreibt (translate, rotate, scale).
function recordingContext() {
    let m = [1, 0, 0, 1, 0, 0];
    return {
        translate(tx, ty) {
            m = [m[0], m[1], m[2], m[3], m[4] + m[0] * tx + m[2] * ty, m[5] + m[1] * tx + m[3] * ty];
        },
        scale(sx, sy) {
            m = [m[0] * sx, m[1] * sx, m[2] * sy, m[3] * sy, m[4], m[5]];
        },
        rotate(r) {
            const c = Math.cos(r), s = Math.sin(r);
            m = [m[0] * c + m[2] * s, m[1] * c + m[3] * s, m[2] * c - m[0] * s, m[3] * c - m[1] * s, m[4], m[5]];
        },
        map(u, v) {
            return [m[0] * u + m[2] * v + m[4], m[1] * u + m[3] * v + m[5]];
        }
    };
}

function outlinePoints(layer, width, height, steps = 200) {
    const ctx = recordingContext();
    wallpaper.place(ctx, layer, width, height);
    const points = [];
    for (const c of wallpaper.cubicsOf(layer)) {
        for (let i = 0; i < steps; i++) {
            const t = i / steps, s = 1 - t;
            const u = s ** 3 * c[0] + 3 * s * s * t * c[2] + 3 * s * t * t * c[4] + t ** 3 * c[6];
            const v = s ** 3 * c[1] + 3 * s * s * t * c[3] + 3 * s * t * t * c[5] + t ** 3 * c[7];
            points.push(ctx.map(u, v));
        }
    }
    return points;
}

// Täler am unteren Rand: lokale Minima von y (y wächst nach unten) im Bild, im untersten Zehntel.
function bottomValleys(points, width, height) {
    const valleys = [];
    for (let i = 0; i < points.length; i++) {
        const [x, y] = points[i];
        const prev = points[(i - 1 + points.length) % points.length][1];
        const next = points[(i + 1) % points.length][1];
        if (y <= prev && y <= next && y > 0.9 * height && x >= 0 && x < width)
            valleys.push([x, y]);
    }
    return valleys;
}

const layers = wallpaper.preset("alpe").layers;
const burst = layers.find(l => l.shape === "softBurst");
const logo = layers.find(l => l.shape === "alpeLogo");

test("softBurst and alpeLogo share the centre 0.453 in the alpe preset", () => {
    assert.ok(burst && logo);
    assert.equal(burst.y, 0.453);
    assert.equal(logo.y, burst.y);
    assert.equal(logo.x, burst.x);
});

const formats = [[1280, 720], [1366, 768], [1920, 1080], [2560, 1080], [2560, 1440], [2560, 1600], [2560, 1664], [3440, 1440], [3840, 2160], [1600, 1200]];

test("every bottom valley of softBurst lies below the screen edge in landscape formats", () => {
    for (const [width, height] of formats) {
        const valleys = bottomValleys(outlinePoints(burst, width, height), width, height);
        assert.ok(valleys.length >= 2, `${width}x${height}: valleys found`);
        for (const [x, y] of valleys)
            assert.ok(y > height, `${width}x${height}: valley at x=${x.toFixed(1)} y=${y.toFixed(2)} above the edge`);
    }
});
