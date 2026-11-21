// Prüft das KWin-Skript (Griffleisten, Tastenkürzel) in einer Attrappe der KWin-Skriptumgebung.
//
//     node tests/test_bridge.js                 nimmt shell/ im Repository
//     node tests/test_bridge.js /pfad/dms-bridge.js
const fs = require("fs");
const path = require("path");
const shellDir = process.env.ALPE_SHELL_DIR || path.join(__dirname, "..", "shell");
const src = fs.readFileSync(process.argv[2] || path.join(shellDir, "Services", "kwin", "dms-bridge.js"), "utf8");
function Signal() { const fns = []; return { connect: f => fns.push(f), disconnect: f => { const i = fns.indexOf(f); if (i < 0) throw new Error("not connected"); fns.splice(i, 1); }, emit: (...a) => fns.slice().forEach(f => f(...a)), count: () => fns.length }; }
let nextId = 1;
const desk = { id: "d1", name: "Eins", x11DesktopNumber: 1, nameChanged: Signal() };
const desk2 = { id: "d2", name: "Zwei", x11DesktopNumber: 2, nameChanged: Signal() };
const output = { name: "DP-2", geometry: { x: 0, y: 0, width: 3127, height: 1309 } };
function Win(o) {
    const w = Object.assign({
        internalId: "{w" + (nextId++) + "}", deleted: false, skipTaskbar: false, specialWindow: false, normalWindow: true, dialog: false,
        desktopFileName: "", resourceClass: "app", resourceName: "app", caption: "", minimized: false, fullScreen: false, demandsAttention: false,
        pid: 1000, output, desktops: [desk], onAllDesktops: false, noBorder: true, moveable: true, hidden: false, desktopWindow: false,
    }, o);
    let geo = o.geo; w._buffer = o.buffer || null;
    for (const n of ["captionChanged", "minimizedChanged", "fullScreenChanged", "desktopsChanged", "outputChanged", "demandsAttentionChanged", "skipTaskbarChanged", "desktopFileNameChanged", "windowClassChanged", "maximizedAboutToChange", "frameGeometryChanged", "stackingOrderChanged", "hiddenChanged", "noBorderChanged", "decorationPolicyChanged"]) w[n] = Signal();
    Object.defineProperty(w, "frameGeometry", { get: () => Object.assign({}, geo), set: g => { const ch = g.x !== geo.x || g.y !== geo.y || g.width !== geo.width || g.height !== geo.height; geo = { x: g.x, y: g.y, width: g.width, height: g.height }; w.moves = (w.moves || 0) + 1; if (ch) w.frameGeometryChanged.emit(); } });
    Object.defineProperty(w, "bufferGeometry", { get: () => w._buffer || Object.assign({}, geo) });
    w.setMaximize = (v, h) => { w.maxCalls = (w.maxCalls || []).concat([[v, h]]); w.maximizedAboutToChange.emit(v && h ? 3 : 0); if (w.onUnmax && !v) w.onUnmax(); };
    w._setGeo = g => { geo = g; w.frameGeometryChanged.emit(); };
    return w;
}
const timers = [];
global.QTimer = function () { this.timeout = Signal(); this.start = () => { this.active = true; }; this.stop = () => { this.active = false; }; timers.push(this); };
const calls = [];
global.callDBus = (s, p, i, m, payload) => calls.push([m, payload]);
const shortcuts = {};
global.registerShortcut = (name, text, key, fn) => { shortcuts[name] = { text, key, fn }; };
global.KWin = { MaximizeArea: 2 };
global.print = (...a) => console.log("print:", ...a);
const ws = global.workspace = {
    stackingOrder: [], windowList() { return this.stackingOrder.slice(); }, desktops: [desk, desk2], currentDesktop: desk, activeScreen: output, activeWindow: null,
    cursorPos: { x: 0, y: 0 }, cursorPosChanged: Signal(), windowAdded: Signal(), windowRemoved: Signal(), windowActivated: Signal(), currentDesktopChanged: Signal(), desktopsChanged: Signal(), screensChanged: Signal(),
    clientArea: (kind, o) => (o && o.geometry && o !== output ? Object.assign({}, o.geometry) : { x: 0, y: 44, width: 3127, height: 1265 }),
    screens: [output],
};
const flush = () => { for (const t of timers) if (t.active && t.interval === 25) { t.active = false; t.timeout.emit(); } };
const lastRaw = () => JSON.parse(calls[calls.length - 1][1]);
// Die Leisten-Prüfungen sehen nur die Streifen; die Ecken prüft ein eigener Abschnitt.
const last = () => { const st = lastRaw(); if (Array.isArray(st.grips)) st.grips = st.grips.filter(x => (x.kind || "move") === "move"); return st; };
const show = g => (g || []).map(x => `${x.id}@${x.gx},${x.gy} ${x.w}x${x.h}`).join(" | ") || "(keine)";
function load(config) { global.ALPE_CONFIG = config; calls.length = 0; timers.length = 0; for (const k in shortcuts) delete shortcuts[k]; (0, eval)(src); }
const assert = (c, m) => { if (!c) { console.log("FEHLER:", m); process.exitCode = 1; } else console.log("ok   ", m); };

// --- Aufbau: Leiste der Shell, drei Fenster, eins mit eigenem Schatten, eins fremder Arbeitsfläche
const bar = Win({ geo: { x: 0, y: 0, width: 3127, height: 44 }, pid: 77, normalWindow: false, specialWindow: true, resourceClass: "quickshell" });
const wallpaper = Win({ geo: { x: 0, y: 0, width: 3127, height: 1309 }, pid: 77, desktopWindow: true, normalWindow: false, specialWindow: true });
const kitty = Win({ geo: { x: 100, y: 100, width: 900, height: 600 }, resourceClass: "kitty" });
const spotify = Win({ geo: { x: 600, y: 300, width: 1200, height: 700 }, resourceClass: "Spotify" });
const nautilus = Win({ geo: { x: 2000, y: 200, width: 900, height: 600 }, resourceClass: "org.gnome.Nautilus", buffer: { x: 1975, y: 175, width: 950, height: 650 } });
const other = Win({ geo: { x: 50, y: 60, width: 500, height: 400 }, desktops: [desk2], resourceClass: "elsewhere" });
const settings = Win({ geo: { x: 1000, y: 150, width: 900, height: 700 }, pid: 77, resourceClass: "quickshell" });
ws.stackingOrder = [wallpaper, kitty, other, nautilus, spotify, settings, bar];

load({ gripEnabled: false });
flush(); 
assert(Array.isArray(last().grips) && last().grips.length === 0, "abgeschaltet: keine Leisten, Kürzel alpe-grip-* fehlen: " + !shortcuts["alpe-grip-begin"]);
assert(Object.keys(shortcuts).length === 9 && shortcuts["dms-launcher"].text === "Alpe: Starter", "neun Tastenkürzel mit Alpe-Namen");

load({ gripEnabled: true, gripHeight: 20, gripOutside: 0, shellPid: 77, gripExcluded: [] });
let g = last().grips;
console.log("     Leisten:", show(g));
assert(g.length === 3 && !!g.find(x => x.id === settings.internalId), "drei Leisten: kitty, Spotify und das Einstellungsfenster der Shell (Nautilus zeichnet selbst, andere Arbeitsfläche zählt nicht)");
assert(g.find(x => x.id === kitty.internalId).w === 900 && g.find(x => x.id === spotify.internalId).gx === 600 && g.find(x => x.id === spotify.internalId).w === 400, "Spotify-Leiste endet, wo das Einstellungsfenster der Shell darüberliegt (600..1000)");

// Menü (Popup) über der kitty-Leiste
const menu = Win({ geo: { x: 300, y: 90, width: 200, height: 300 }, normalWindow: false, specialWindow: true, resourceClass: "kitty" });
ws.stackingOrder = [wallpaper, kitty, other, nautilus, spotify, settings, menu, bar]; ws.windowAdded.emit(menu); flush();
g = last().grips; console.log("     mit Menü:", show(g));
assert(g.filter(x => x.id === kitty.internalId).length === 2 && g.filter(x => x.id === kitty.internalId).map(x => x.w).join(",") === "200,500", "Menü teilt die kitty-Leiste in 100..300 und 500..1000");
ws.stackingOrder = [wallpaper, kitty, other, nautilus, spotify, settings, bar]; ws.windowRemoved.emit(menu); flush();

// Eigene Griffflächen und bildschirmfüllende Shell-Flächen verdecken nichts
const strip = Win({ geo: { x: 100, y: 100, width: 900, height: 20 }, pid: 77, normalWindow: false, specialWindow: true });
const veil = Win({ geo: { x: 0, y: 0, width: 3127, height: 1309 }, pid: 77, normalWindow: false, specialWindow: true });
ws.stackingOrder = [wallpaper, kitty, other, nautilus, spotify, settings, strip, veil, bar]; ws.windowAdded.emit(strip); flush();
assert(last().grips.find(x => x.id === kitty.internalId).w === 900, "eigene Grifffläche und durchsichtiger Vollbildträger der Shell verdecken nichts");
// Dasselbe, wenn KWin den Prozess der Flächen nicht nennt: erkannt an der gemeldeten Lage
load({ gripEnabled: true, gripHeight: 20, gripOutside: 0, shellPid: 0 });
strip.pid = 0; veil.pid = 0;
// Das neu geladene Skript kennt die alte Fläche noch nicht: Die Shell räumt sie ab und setzt sie neu.
ws.stackingOrder = ws.stackingOrder.filter(w => w !== strip); ws.windowRemoved.emit(strip); flush();
ws.stackingOrder.push(strip); ws.windowAdded.emit(strip); flush(); ws.windowActivated.emit(kitty); flush(); ws.windowActivated.emit(kitty); flush();
assert(last().grips.find(x => x.id === kitty.internalId).w === 900, "ohne Prozessangabe: eigene Leiste an ihrer Lage erkannt, kein Flackern über mehrere Meldungen");
const stray = Win({ geo: { x: 300, y: 95, width: 200, height: 20 }, pid: 0, normalWindow: false, specialWindow: true });
ws.stackingOrder.push(stray); ws.windowAdded.emit(stray); flush();
assert(last().grips.filter(x => x.id === kitty.internalId).length === 2, "fremde Fläche gleicher Höhe an anderer Stelle verdeckt weiterhin");
ws.stackingOrder = ws.stackingOrder.filter(w => w !== stray); ws.windowRemoved.emit(stray); strip.pid = 77; veil.pid = 77;
load({ gripEnabled: true, gripHeight: 20, gripOutside: 0, shellPid: 77 });
// Popout der Shell (nicht bildschirmfüllend) verdeckt sehr wohl
const popout = Win({ geo: { x: 0, y: 44, width: 800, height: 500 }, pid: 77, normalWindow: false, specialWindow: true });
ws.stackingOrder.push(popout); ws.windowAdded.emit(popout); flush();
assert(last().grips.find(x => x.id === kitty.internalId).gx === 800, "Popout der Shell schneidet die Leiste darunter weg");
ws.stackingOrder = [wallpaper, kitty, other, nautilus, spotify, settings, bar]; ws.windowRemoved.emit(popout); flush();

// Vollbild und minimiert
spotify.fullScreen = true; spotify._setGeo({ x: 0, y: 0, width: 3127, height: 1309 }); spotify.fullScreenChanged.emit(); flush();
assert(last().grips.length === 1 && last().grips[0].id === settings.internalId, "Vollbildfenster: selbst ohne Leiste, verdeckt alle darunter (nur das Fenster darüber behält seine)");
spotify.fullScreen = false; spotify._setGeo({ x: 600, y: 300, width: 1200, height: 700 }); spotify.minimized = true; spotify.minimizedChanged.emit(); flush();
assert(last().grips.find(x => x.id === kitty.internalId).w === 900, "minimiertes Fenster verdeckt nichts");
spotify.minimized = false; spotify.minimizedChanged.emit(); flush();

// Ausnahme und Titelleiste von KWin
load({ gripEnabled: true, gripHeight: 20, gripOutside: 0, shellPid: 77, gripExcluded: ["spotify"] });
assert(!last().grips.find(x => x.id === spotify.internalId), "ausgenommenes Programm ohne Leiste (Gross-/Kleinschreibung egal)");
load({ gripEnabled: true, gripHeight: 20, gripOutside: 0, shellPid: 77, gripSkipDecorated: false });
assert(!!last().grips.find(x => x.id === nautilus.internalId), "Erkennung abgeschaltet: auch Nautilus bekommt eine Leiste");
load({ gripEnabled: true, gripHeight: 20, gripOutside: 0, shellPid: 77 });
kitty.noBorder = false; ws.windowActivated.emit(kitty); flush();
assert(!last().grips.find(x => x.id === kitty.internalId), "Fenster mit KWin-Titelleiste ohne Leiste");
kitty.noBorder = true;
// Titelleiste im Fenstermenü abgeschaltet. Bis kitty seinen Puffer anpasst, ist er grösser als
// der Rahmen – das darf die Leiste nicht für immer nehmen.
load({ gripEnabled: true, gripHeight: 20, gripOutside: 0, shellPid: 77 });
kitty._buffer = { x: 100, y: 70, width: 900, height: 630 }; kitty._setGeo({ x: 100, y: 100, width: 900, height: 600 }); flush();
assert(!!last().grips.find(x => x.id === kitty.internalId), "nur höherer Puffer (alte Titelleiste) gilt nicht als eigene Titelleiste");
kitty._buffer = { x: 95, y: 70, width: 910, height: 630 }; kitty.noBorderChanged.emit(); flush();
assert(!!last().grips.find(x => x.id === kitty.internalId), "direkt nach dem Wechsel der Titelleiste: Leiste bleibt");
kitty._buffer = null; ws.windowActivated.emit(kitty); flush();
assert(!!last().grips.find(x => x.id === kitty.internalId), "nach dem Wechsel: kitty behält die Leiste");
assert(!last().grips.find(x => x.id === nautilus.internalId), "Nautilus (Schatten rundum) weiterhin ohne Leiste");
// KWin 6.8 meldet denselben Wechsel als decorationPolicyChanged
load({ gripEnabled: true, gripHeight: 20, gripOutside: 0, shellPid: 77 });
kitty._buffer = { x: 95, y: 70, width: 910, height: 630 }; kitty.decorationPolicyChanged.emit(); flush();
assert(!!last().grips.find(x => x.id === kitty.internalId), "KWin 6.8: direkt nach decorationPolicyChanged bleibt die Leiste");
kitty._buffer = null; ws.windowActivated.emit(kitty); flush();

// --- Streifen über dem Fenster (rittlings auf dem Rand)
load({ gripEnabled: true, shellPid: 77 });
g = last().grips; console.log("     rittlings:", show(g));
const of = (w, h) => g.filter(x => x.id === w.internalId && x.h === h);
assert(of(kitty, 8).length === 1 && of(kitty, 8)[0].gy === 100 && of(kitty, 12).length === 1 && of(kitty, 12)[0].gy === 88 && of(kitty, 12)[0].w === 900, "Vorgabe: 8 px im Fenster, 12 px darüber (kitty: frei über dem Hintergrund)");
assert(of(spotify, 12).length === 0 && of(spotify, 8).length === 1, "über Spotify liegen kitty und ein Shell-Fenster: dort kein Streifen ausserhalb, der im Fenster bleibt");
kitty._setGeo({ x: 100, y: 50, width: 900, height: 600 }); flush(); g = last().grips;
assert(of(kitty, 12).length === 0 && of(kitty, 8).length === 1, "Fenster dicht unter der Leiste: kein Streifen in den Bereich der Leiste hinein, der im Fenster bleibt");
kitty._setGeo({ x: 100, y: 100, width: 900, height: 600 }); flush();
ws.cursorPos = { x: 400, y: 92 }; shortcuts["alpe-grip-begin"].fn(); ws.cursorPos = { x: 450, y: 142 }; ws.cursorPosChanged.emit();
assert(kitty.frameGeometry.x === 150 && kitty.frameGeometry.y === 150, "Griff im Streifen über dem Fenster: der Rand bleibt 8 px unter dem Zeiger (" + kitty.frameGeometry.x + "," + kitty.frameGeometry.y + ")");
shortcuts["alpe-grip-end"].fn(); kitty._setGeo({ x: 100, y: 100, width: 900, height: 600 }); flush();
load({ gripEnabled: true, gripHeight: 20, gripOutside: 0, shellPid: 77 });

// --- Ziehen
const begin = shortcuts["alpe-grip-begin"].fn, end = shortcuts["alpe-grip-end"].fn;
const moveTo = (x, y) => { ws.cursorPos = { x, y }; ws.cursorPosChanged.emit(); };
const hooksBefore = kitty.frameGeometryChanged.count();
ws.cursorPos = { x: 400, y: 108 }; begin();
assert(ws.activeWindow === kitty && ws.cursorPosChanged.count() === 1, "Griff auf kitty: Fenster aktiviert, Zeiger wird verfolgt");
ws.windowActivated.emit(kitty); flush();
assert(last().grips === null, "während des Ziehens meldet das Skript keine Leisten (die Shell behält die alten)");
moveTo(402, 109); assert(kitty.frameGeometry.x === 100, "unter 5 px Weg: noch kein Verschieben (Klick bleibt Klick)");
moveTo(500, 208); assert(kitty.frameGeometry.x === 200 && kitty.frameGeometry.y === 200, "Fenster folgt dem Zeiger: " + JSON.stringify(kitty.frameGeometry));
moveTo(500, 10); assert(kitty.frameGeometry.y === 44, "oben gestoppt an der Arbeitsfläche unter der Leiste (y=44)");
moveTo(3120, 400); assert(kitty.frameGeometry.x === 2820, "am rechten Rand bleibt der gegriffene Punkt unter dem Zeiger");
moveTo(500, 1305); assert(kitty.frameGeometry.y === 44 + 1265 - 20, "unten bleibt die Griffleiste im Bild");
moveTo(700, 500); end();
assert(ws.cursorPosChanged.count() === 0 && kitty.frameGeometryChanged.count() === hooksBefore, "Loslassen: Verfolgung beendet, Verbindungen gelöst");
const before = JSON.stringify(kitty.frameGeometry); moveTo(900, 900);
assert(JSON.stringify(kitty.frameGeometry) === before, "nach dem Loslassen bewegt sich nichts mehr");
flush(); assert(Array.isArray(last().grips), "danach kommen wieder Leisten");

// verspäteter Aufruf: Zeiger hat die Leiste schon verlassen
kitty._setGeo({ x: 100, y: 100, width: 900, height: 600 }); flush();
ws.cursorPos = { x: 420, y: 170 }; begin(); moveTo(430, 180);
assert(kitty.frameGeometry.y === 160 && kitty.frameGeometry.x === 110, "verspäteter Griff: Fenster holt den Zeiger ein (" + kitty.frameGeometry.x + "," + kitty.frameGeometry.y + ")");
end();
// daneben: kein Griff
ws.cursorPos = { x: 1500, y: 1200 }; begin(); assert(ws.cursorPosChanged.count() === 0, "weit weg von jeder Leiste: kein Griff");

// Doppelklick maximiert
kitty._setGeo({ x: 100, y: 100, width: 900, height: 600 }); flush();
ws.cursorPos = { x: 400, y: 105 }; begin(); end(); begin();
assert(JSON.stringify(kitty.maxCalls) === "[[true,true]]" && ws.cursorPosChanged.count() === 0, "Doppelklick maximiert, ohne zu ziehen");
// Ziehen eines maximierten Fensters: erst lösen, dann folgen
kitty._setGeo({ x: 0, y: 44, width: 3127, height: 1265 }); flush();
kitty.onUnmax = () => setTimeout(() => kitty._setGeo({ x: 0, y: 44, width: 900, height: 600 }), 30);
setTimeout(() => {
    ws.cursorPos = { x: 1563, y: 50 }; begin(); moveTo(1563, 80);
    assert(kitty.maxCalls.length === 2 && kitty.frameGeometry.width === 3127, "maximiertes Fenster: Maximierung gelöst, Fenster wartet auf die neue Grösse");
    setTimeout(() => {
        const f = kitty.frameGeometry;
        assert(f.width === 900 && Math.abs((f.x + 450) - 1563) <= 1 && f.y === 74, "nach der Bestätigung sitzt das Fenster mittig unter dem Zeiger: " + JSON.stringify(f));
        // Fenster verschwindet mitten im Ziehen
        ws.stackingOrder = ws.stackingOrder.filter(w => w !== kitty); kitty.deleted = true; ws.windowRemoved.emit(kitty);
        assert(ws.cursorPosChanged.count() === 0, "Fenster geschlossen: Griff endet von selbst");
        // Leerlauf beendet den Griff
        ws.cursorPos = { x: 700, y: 305 }; begin(); const idle = timers.find(t => t.interval === 5000); idle.timeout.emit();
        assert(ws.cursorPosChanged.count() === 0, "5 s ohne Bewegung: Griff endet (verlorenes Loslassen bleibt folgenlos)");
        // --- Einrasten am Bildschirmrand
        const term = Win({ geo: { x: 800, y: 400, width: 900, height: 600 }, resourceClass: "kitty" });
        ws.stackingOrder.push(term); ws.windowAdded.emit(term); flush();
        const grab = (x, y) => { ws.cursorPos = { x, y }; begin(); };
        grab(1000, 405); moveTo(400, 600); moveTo(2, 600); flush();
        assert(last().snap && last().snap.kind === "left" && last().snap.w === 1564 && last().snap.y === 44, "am linken Rand: Vorschau linke Hälfte " + JSON.stringify(last().snap));
        shortcuts["alpe-grip-end"].fn(); flush();
        let tf = term.frameGeometry;
        assert(tf.x === 0 && tf.y === 44 && tf.width === 1564 && tf.height === 1265 && last().snap === null, "losgelassen: Fenster füllt die linke Hälfte, Vorschau weg");
        grab(700, 47); moveTo(720, 300);
        tf = term.frameGeometry;
        assert(tf.width === 900 && f.height === 600 && Math.abs(tf.x + 900 * (700 / 1564) - 720) < 2, "wieder weggezogen: alte Grösse, Griffpunkt bleibt unter dem Zeiger " + JSON.stringify(tf));
        moveTo(3126, 100); flush();
        assert(last().snap.kind === "right-top" && last().snap.x === 1564 && last().snap.h === 633, "rechts oben: Viertel " + JSON.stringify(last().snap));
        moveTo(1500, 0); flush();
        assert(last().snap.kind === "max", "oben: maximieren");
        moveTo(1500, 500); flush();
        assert(last().snap === null, "zurück in die Mitte: keine Vorschau");
        moveTo(1500, 1); shortcuts["alpe-grip-end"].fn();
        assert(JSON.stringify(term.maxCalls) === "[[true,true]]", "oben losgelassen: maximiert");
        // Zeitablauf rastet nicht ein
        term.maxCalls = []; term.maximizedAboutToChange.emit(0); term._setGeo({ x: 800, y: 400, width: 900, height: 600 }); flush();
        grab(1000, 405); moveTo(400, 600); moveTo(1, 700); timers.find(t => t.interval === 5000).timeout.emit();
        assert(term.frameGeometry.width === 900 && term.maxCalls.length === 0, "Griff durch Zeitablauf beendet: kein Einrasten " + JSON.stringify(term.frameGeometry) + JSON.stringify(term.maxCalls));
        // zweiter Bildschirm rechts: rechter Rand des ersten ist ein Durchgang
        const out2 = { name: "HDMI-A-1", geometry: { x: 3127, y: 0, width: 1920, height: 1080 } };
        ws.screens = [output, out2];
        term._setGeo({ x: 800, y: 400, width: 900, height: 600 }); flush();
        grab(1000, 405); moveTo(3120, 600); flush();
        assert(last().snap === null, "Rand zum zweiten Bildschirm: kein Einrasten");
        moveTo(3127 + 1918, 600); flush();
        assert(last().snap && last().snap.output === "HDMI-A-1" && last().snap.kind === "right" && last().snap.x === 960 && last().snap.y === 0 && last().snap.w === 960, "äusserer Rand des zweiten Bildschirms: rastet ein, Lage relativ zum Bildschirm " + JSON.stringify(last().snap));
        shortcuts["alpe-grip-end"].fn(); ws.screens = [output];
        // Ecken: Grösse ziehen
        flush();
        const corners = lastRaw().grips.filter(x => x.id === settings.internalId && x.kind !== "move" && x.w === 18 && x.h === 18);
        assert(corners.length === 2 && corners.every(c => c.w === 18 && c.h === 18), "Ecken unten links und rechts, 18 px: " + JSON.stringify(corners.map(c => c.kind + "@" + c.gx + "," + c.gy)));
        const coveredKitty = lastRaw().grips.filter(x => x.id === kitty.internalId && x.kind !== "move").map(c => c.kind).join();
        const sg = settings.frameGeometry;
        const br = corners.find(c => c.kind === "resize-br");
        grab(br.gx + 9, br.gy + 9); moveTo(br.gx + 109, br.gy + 59);
        assert(settings.frameGeometry.width === sg.width + 100 && settings.frameGeometry.height === sg.height + 50 && settings.frameGeometry.x === sg.x && settings.frameGeometry.y === sg.y, "rechte Ecke: breiter und höher, Lage bleibt " + JSON.stringify(settings.frameGeometry));
        shortcuts["alpe-grip-end"].fn(); flush();
        const bl = lastRaw().grips.find(x => x.id === settings.internalId && x.kind === "resize-bl");
        const g2 = settings.frameGeometry;
        grab(bl.gx + 5, bl.gy + 5); moveTo(bl.gx - 95, bl.gy + 5);
        assert(settings.frameGeometry.x === g2.x - 100 && settings.frameGeometry.width === g2.width + 100 && settings.frameGeometry.y === g2.y, "linke Ecke: rechter Rand bleibt stehen " + JSON.stringify(settings.frameGeometry));
        moveTo(bl.gx + 5000, bl.gy - 5000);
        assert(settings.frameGeometry.width === 160 && settings.frameGeometry.height === 100 && settings.frameGeometry.x + 160 === g2.x + g2.width, "Mindestgrösse 160×100 " + JSON.stringify(settings.frameGeometry));
        shortcuts["alpe-grip-end"].fn();
        assert(JSON.stringify(settings.maxCalls || []) === "[]" && last().snap === undefined || last().snap === null, "Grösse ziehen rastet nicht ein");
        settings._setGeo(sg); flush();
        console.log("     Ecken von kitty (teils verdeckt):", coveredKitty || "keine");
        // Alpe: Die Eckfläche liegt in echt selbst im Stapel (Ebenenfläche der Shell).
        // Bis 1.4.2 verdeckte sie ihre eigene Fensterecke, der Druck ging ins Leere.
        const own = Win({ geo: { x: br.gx, y: br.gy, width: 18, height: 18 }, pid: 77, normalWindow: false, specialWindow: true, skipTaskbar: true });
        ws.stackingOrder.push(own); ws.windowAdded.emit(own); flush();
        assert(lastRaw().grips.some(x => x.id === settings.internalId && x.kind === "resize-br" && x.w === 18), "eigene Eckfläche im Stapel verdeckt die Ecke nicht");
        grab(br.gx + 9, br.gy + 9); moveTo(br.gx + 59, br.gy + 29);
        assert(settings.frameGeometry.width === sg.width + 50 && settings.frameGeometry.height === sg.height + 20, "Druck auf die echte Eckfläche zieht die Grösse " + JSON.stringify(settings.frameGeometry));
        shortcuts["alpe-grip-end"].fn();
        ws.stackingOrder = ws.stackingOrder.filter(w => w !== own); ws.windowRemoved.emit(own);
        settings._setGeo(sg); flush();
        // Ränder ausserhalb: frei stehendes Fenster bekommt links, rechts und unten einen Rand
        const free = Win({ geo: { x: 400, y: 1000, width: 600, height: 200 }, resourceClass: "Spotify" });
        const keep = ws.stackingOrder.slice();
        ws.stackingOrder = [wallpaper, free, bar]; ws.windowAdded.emit(free); flush();
        const edges = lastRaw().grips.filter(x => x.id === free.internalId && x.kind !== "move" && !(x.w === 18 && x.h === 18));
        const kinds = edges.map(x => x.kind).sort().join();
        assert(kinds === "resize-b,resize-bl,resize-bl,resize-br,resize-br,resize-l,resize-r", "Ränder links, rechts, unten mit schrägen Enden: " + kinds);
        const rEdge = edges.find(x => x.kind === "resize-r");
        assert(rEdge.gx === 1000 && rEdge.w === 8 && rEdge.gy === 1000, "rechter Rand liegt ausserhalb, 8 px " + JSON.stringify(rEdge));
        const own2 = Win({ geo: { x: rEdge.gx, y: rEdge.gy, width: rEdge.w, height: rEdge.h }, pid: 77, normalWindow: false, specialWindow: true, skipTaskbar: true });
        ws.stackingOrder = [wallpaper, free, own2, bar]; ws.windowAdded.emit(own2); flush();
        grab(1004, 1100); moveTo(1104, 1150);
        let ff = free.frameGeometry;
        assert(ff.width === 700 && ff.height === 200 && ff.x === 400, "rechter Rand: nur breiter " + JSON.stringify(ff));
        shortcuts["alpe-grip-end"].fn(); flush();
        const lEdge = lastRaw().grips.find(x => x.id === free.internalId && x.kind === "resize-l");
        grab(lEdge.gx + 4, lEdge.gy + 20); moveTo(lEdge.gx + 104, lEdge.gy + 80);
        ff = free.frameGeometry;
        assert(ff.x === 500 && ff.width === 600 && ff.height === 200, "linker Rand: rechter Rand bleibt, Höhe bleibt " + JSON.stringify(ff));
        shortcuts["alpe-grip-end"].fn();
        // Unten reicht der Rand nicht unter die Leiste/den Bildschirmrand: Fenster bis 1300 hoch -> kein unterer Rand
        free._setGeo({ x: 400, y: 1000, width: 600, height: 305 }); flush();
        assert(!lastRaw().grips.some(x => x.id === free.internalId && x.kind === "resize-b"), "kein unterer Rand, wo der Bildschirm endet");
        // Daneben liegendes Fenster: Rand wird ausgespart
        free._setGeo({ x: 400, y: 1000, width: 600, height: 200 });
        const nb = Win({ geo: { x: 1004, y: 900, width: 300, height: 400 }, resourceClass: "nb" });
        ws.stackingOrder = [wallpaper, nb, free, bar]; ws.windowAdded.emit(nb); flush();
        assert(!lastRaw().grips.some(x => x.id === free.internalId && x.kind === "resize-r"), "rechter Rand fehlt, wo ein anderes Fenster anliegt");
        ws.stackingOrder = keep; ws.windowRemoved.emit(nb); ws.windowRemoved.emit(free); flush();
        console.log(process.exitCode ? "\nFEHLER vorhanden" : "\nalle Prüfungen bestanden");
    }, 80);
}, 500);
