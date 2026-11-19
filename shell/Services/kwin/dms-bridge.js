// DMS <-> KWin bridge. Loaded into KWin by KwinService.qml through
// org.kde.kwin.Scripting. KWin exposes neither wlr-foreign-toplevel nor
// ext-workspace, so this script mirrors windows and virtual desktops to the
// shell: every change sends one full JSON snapshot as a D-Bus method call
// that the shell picks up with a bus monitor.
(function () {
    // Not org.kde.KWin: QtDBus short-circuits calls to the sender's own service, so they never reach the bus.
    var SERVICE = "org.freedesktop.systemd1";
    var PATH = "/DmsBridge";
    var IFACE = "dev.duxlabs.KwinBridge";

    var hooked = {};
    var hookedDesktops = {};
    var maximized = {};
    var seq = 0;

    // Alpe: Einstellungen, die KwinService dem Skript beim Laden voranstellt.
    var CONFIG = (typeof ALPE_CONFIG === "object" && ALPE_CONFIG) ? ALPE_CONFIG : {};
    var GRIP = {
        "enabled": !!CONFIG.gripEnabled,
        // Der Streifen sitzt rittlings auf dem oberen Rand: wenig im Fenster (dort liegen oft
        // Menüleisten), der grössere Teil darüber, wo nur der Hintergrund ist.
        "height": Math.max(2, Math.min(64, (CONFIG.gripHeight | 0) || 8)),
        "outside": Math.max(0, Math.min(64, CONFIG.gripOutside === undefined ? 12 : (CONFIG.gripOutside | 0))),
        "skipDecorated": CONFIG.gripSkipDecorated !== false,
        // An den Bildschirmrand ziehen: Hälfte, Viertel, oben maximieren.
        "snap": CONFIG.gripSnap !== false,
        // Untere Ecken eines Fensters ohne Rahmen: dort zieht man die Grösse. 0 schaltet ab.
        "corner": Math.max(0, Math.min(48, CONFIG.gripCorner === undefined ? 18 : (CONFIG.gripCorner | 0))),
        // Alpe: Ränder links, rechts und unten, ausserhalb des Fensters über dem Hintergrund,
        // wie der unsichtbare Rand einer Fensterdekoration. 0 schaltet ab.
        "edge": Math.max(0, Math.min(24, CONFIG.gripEdge === undefined ? 8 : (CONFIG.gripEdge | 0))),
        "shellPid": CONFIG.shellPid | 0,
        "excluded": {}
    };
    (function () {
        var list = CONFIG.gripExcluded || [];
        for (var i = 0; i < list.length; i++)
            GRIP.excluded[String(list[i]).toLowerCase()] = true;
    })();
    var clientDecorated = {};
    // Alpe: Wann ein Fenster zuletzt seine Titelleiste gewechselt hat (Fenstermenü «Ohne
    // Titelleiste und Rahmen», Regel). Bis das Programm seinen Puffer angepasst hat, ist dieser
    // kurz grösser als der Rahmen – das sah aus wie eine eigene Titelleiste mit Schatten und
    // nahm dem Fenster die Griffleiste für immer (kitty liess sich nicht mehr ziehen).
    var borderChanged = {};
    var SETTLE_MS = 2500;

    function idOf(w) {
        return String(w.internalId);
    }

    function wanted(w) {
        if (!w || w.deleted)
            return false;
        if (w.skipTaskbar || w.specialWindow)
            return false;
        return !!(w.normalWindow || w.dialog);
    }

    function guessMaximized(w) {
        try {
            var area = workspace.clientArea(KWin.MaximizeArea, w);
            var g = w.frameGeometry;
            return Math.abs(g.width - area.width) < 2 && Math.abs(g.height - area.height) < 2;
        } catch (e) {
            return false;
        }
    }

    function info(w) {
        var id = idOf(w);
        var desktops = [];
        try {
            var list = w.desktops || [];
            for (var i = 0; i < list.length; i++)
                desktops.push(String(list[i].id));
        } catch (e) {}
        if (maximized[id] === undefined)
            maximized[id] = guessMaximized(w);
        return {
            "id": id,
            "appId": String(w.desktopFileName || w.resourceClass || w.resourceName || ""),
            "title": String(w.caption || ""),
            "minimized": !!w.minimized,
            "fullscreen": !!w.fullScreen,
            "maximized": !!maximized[id],
            "urgent": !!w.demandsAttention,
            "pid": w.pid | 0,
            "output": w.output ? String(w.output.name) : "",
            "desktops": desktops,
            "allDesktops": !!w.onAllDesktops
        };
    }

    // ------------------------------------------------------------------
    // Alpe: Griffleisten. Fenster ohne Titelleiste lassen sich an ihrem oberen Rand ziehen.
    // Das Skript meldet, wo dieser Rand sichtbar ist; die Shell legt dort schmale, unsichtbare
    // Flächen ab. Ein Druck darauf löst «alpe-grip-begin» aus, und das Skript führt das Fenster
    // dem Mauszeiger nach, bis «alpe-grip-end» kommt.
    // ------------------------------------------------------------------

    function appIdOf(w) {
        return String(w.desktopFileName || w.resourceClass || w.resourceName || "");
    }

    function onCurrentDesktop(w) {
        try {
            if (w.onAllDesktops)
                return true;
            var list = w.desktops || [];
            if (list.length === 0)
                return true;
            var current = workspace.currentDesktop;
            for (var i = 0; i < list.length; i++) {
                if (list[i] === current || String(list[i].id) === String(current.id))
                    return true;
            }
        } catch (e) {}
        return false;
    }

    function shown(w) {
        try {
            if (!w || w.deleted || w.minimized)
                return false;
            if (w.hidden === true)
                return false;
            return onCurrentDesktop(w);
        } catch (e) {
            return false;
        }
    }

    function rectOf(w) {
        var g = w.frameGeometry;
        return {
            "x": g.x,
            "y": g.y,
            "w": g.width,
            "h": g.height
        };
    }

    // Programme, die ihre Titelleiste selbst zeichnen, zeichnen auch ihren Schatten selbst: ihr
    // Puffer ist grösser als das Fenster. Maximiert fehlt der Schatten, deshalb merkt sich das
    // Skript, was es einmal gesehen hat.
    function drawsOwnFrame(w, id) {
        if (clientDecorated[id])
            return true;
        if (borderChanged[id] && Date.now() - borderChanged[id] < SETTLE_MS)
            return false;
        try {
            var b = w.bufferGeometry;
            var f = w.frameGeometry;
            // Ein selbst gezeichneter Schatten liegt auf allen Seiten: Puffer breiter UND höher
            if (b && f && b.width > f.width + 1 && b.height > f.height + 1) {
                clientDecorated[id] = true;
                return true;
            }
        } catch (e) {}
        return false;
    }

    function gripTarget(w) {
        if (!wanted(w) || !shown(w) || w.fullScreen)
            return false;
        try {
            // Eigene Fenster der Shell (Einstellungen, Systemmonitor) bekommen eine Leiste wie
            // jedes andere; ihre Ebenenflächen (Leiste, Dock, Popouts) nicht.
            if (GRIP.shellPid && (w.pid | 0) === GRIP.shellPid && !w.normalWindow && !w.dialog)
                return false;
            if (w.noBorder === false)
                return false;
            if (w.moveable === false)
                return false;
        } catch (e) {}
        var app = appIdOf(w).toLowerCase();
        if (GRIP.excluded[app])
            return false;
        if (GRIP.skipDecorated && drawsOwnFrame(w, idOf(w)))
            return false;
        return true;
    }

    // Flächen, die nichts verdecken: die eigenen Griffleisten (sonst nähme sich jede Leiste
    // selbst den Platz weg und flackerte) und bildschirmfüllende Layer-Flächen, die durchsichtige
    // Träger sind. Die Shell blendet die Leisten ohnehin aus, solange ein Popout offen ist.
    // Erkannt werden die eigenen Leisten an Prozess und Höhe und, falls KWin den Prozess nicht
    // nennt, an ihrer Lage: Das Skript weiss, welche Rechtecke es zuletzt gemeldet hat.
    var issued = [];

    function rememberIssued(list) {
        var keys = {};
        for (var i = 0; i < list.length; i++)
            keys[list[i].gx + "," + list[i].gy + "," + list[i].w + "," + list[i].h] = true;
        issued.unshift(keys);
        if (issued.length > 6)
            issued.pop();
    }

    function wasIssued(r) {
        var key = Math.round(r.x) + "," + Math.round(r.y) + "," + Math.round(r.w) + "," + Math.round(r.h);
        for (var i = 0; i < issued.length; i++) {
            if (issued[i][key])
                return true;
        }
        return false;
    }

    function transparentSurface(w, r) {
        try {
            if (!(w.skipTaskbar || w.specialWindow))
                return false;
            // Alpe: Jede gemeldete Fläche ist eine eigene, egal welche Form. Bis 1.4.2 galt
            // das nur für Streifen in Leistenhöhe; die 18-px-Ecken verdeckten so beim Druck ihre
            // eigene Fensterecke, und der Griff ging ins Leere.
            if (wasIssued(r))
                return true;
            var near = function (a, b) {
                return b > 0 && Math.abs(a - b) < 1.5;
            };
            var ownShape = near(r.h, GRIP.height) || near(r.h, GRIP.outside) || near(r.w, GRIP.edge) || near(r.h, GRIP.edge) || (near(r.w, GRIP.corner) && near(r.h, GRIP.corner));
            if (ownShape && GRIP.shellPid && (w.pid | 0) === GRIP.shellPid)
                return true;
            var out = w.output ? w.output.geometry : null;
            return !!out && !w.fullScreen && r.w >= out.width * 0.9 && r.h >= out.height * 0.9;
        } catch (e) {
            return false;
        }
    }

    function subtract(spans, from, to) {
        var out = [];
        for (var i = 0; i < spans.length; i++) {
            var a = spans[i][0];
            var b = spans[i][1];
            if (to <= a || from >= b) {
                out.push(spans[i]);
                continue;
            }
            if (from > a)
                out.push([a, from]);
            if (to < b)
                out.push([to, b]);
        }
        return out;
    }

    function pushStrips(result, win, out, spans, top, height) {
        for (var k = 0; k < spans.length; k++) {
            var from = Math.ceil(spans[k][0]);
            var to = Math.floor(spans[k][1]);
            if (to - from < 32)
                continue;
            result.push({
                "id": idOf(win),
                "kind": "move",
                "output": String(win.output.name),
                "x": from - Math.round(out.x),
                "y": Math.round(top) - Math.round(out.y),
                "w": to - from,
                "h": height,
                "gx": from,
                "gy": Math.round(top)
            });
        }
    }

    function grips() {
        var result = [];
        if (!GRIP.enabled)
            return result;
        var stack;
        try {
            stack = workspace.stackingOrder;
        } catch (e) {
            return result;
        }
        var rects = [];
        for (var i = 0; i < stack.length; i++) {
            var entry = null;
            try {
                var w = stack[i];
                if (shown(w)) {
                    var r = rectOf(w);
                    if (r.w > 0 && r.h > 0 && !w.desktopWindow && !transparentSurface(w, r))
                        entry = {
                            "w": w,
                            "r": r
                        };
                }
            } catch (e) {}
            rects.push(entry);
        }
        for (var t = 0; t < rects.length; t++) {
            if (!rects[t])
                continue;
            var win = rects[t].w;
            var ok = false;
            try {
                ok = gripTarget(win);
            } catch (e) {}
            if (!ok)
                continue;
            var g = rects[t].r;
            var out = null;
            try {
                out = win.output ? win.output.geometry : null;
            } catch (e) {}
            if (!out)
                continue;
            var left = Math.max(g.x, out.x);
            var right = Math.min(g.x + g.w, out.x + out.width);
            // Im Fenster: verdeckt nur, was darüber gestapelt ist.
            var top = g.y;
            var bottom = g.y + GRIP.height;
            if (top >= out.y - 0.5 && bottom <= out.y + out.height) {
                var spans = [[left, right]];
                for (var o = t + 1; o < rects.length && spans.length > 0; o++) {
                    if (!rects[o])
                        continue;
                    var c = rects[o].r;
                    if (c.y >= bottom || c.y + c.h <= top)
                        continue;
                    spans = subtract(spans, c.x, c.x + c.w);
                }
                pushStrips(result, win, out, spans, top, GRIP.height);
            }
            // Über dem Fenster: nur wo dort gar kein anderes Fenster ist, also über dem Hintergrund.
            // Sonst nähme der Streifen einem fremden Fenster die Klicks weg.
            if (GRIP.outside > 0) {
                var above = g.y - GRIP.outside;
                var area = out;
                try {
                    // Nicht in den Bereich von Leiste und Dock hinein, wem auch immer er gehört.
                    area = workspace.clientArea(KWin.MaximizeArea, win);
                } catch (e) {}
                if (above >= area.y - 0.5 && g.y <= area.y + area.height) {
                    var free = [[left, right]];
                    for (var a = 0; a < rects.length && free.length > 0; a++) {
                        if (a === t || !rects[a])
                            continue;
                        var d = rects[a].r;
                        if (d.y >= g.y || d.y + d.h <= above)
                            continue;
                        free = subtract(free, d.x, d.x + d.w);
                    }
                    pushStrips(result, win, out, free, above, GRIP.outside);
                }
            }
            pushCorners(result, win, out, g, rects, t);
            pushEdges(result, win, out, g, rects, t);
        }
        return result;
    }

    // Alpe: Ränder ausserhalb des Fensters. Wie der Streifen über dem Fenster nur dort, wo
    // kein anderes Fenster liegt, und nicht in Leiste oder Dock hinein. Die Enden nahe den
    // unteren Ecken ziehen schräg.
    function pushEdges(result, win, out, g, rects, t) {
        var e = GRIP.edge;
        if (e <= 0)
            return;
        var flat = false;
        try {
            flat = isMaximized(win) || win.fullScreen || win.resizeable === false;
        } catch (ex) {}
        if (flat)
            return;
        var area = out;
        try {
            area = workspace.clientArea(KWin.MaximizeArea, win);
        } catch (ex) {}
        var ax0 = Math.max(area.x, out.x), ay0 = Math.max(area.y, out.y);
        var ax1 = Math.min(area.x + area.width, out.x + out.width), ay1 = Math.min(area.y + area.height, out.y + out.height);
        var gx0 = Math.round(g.x), gy0 = Math.round(g.y), gx1 = Math.round(g.x + g.w), gy1 = Math.round(g.y + g.h);
        var reach = 28;
        // [Seite, Rechteck, Achse der Spanne]
        var sides = [["l", gx0 - e, gy0, e, gy1 + e - gy0, "y"], ["r", gx1, gy0, e, gy1 + e - gy0, "y"], ["b", gx0, gy1, gx1 - gx0, e, "x"]];
        for (var s = 0; s < sides.length; s++) {
            var side = sides[s][0];
            var x = sides[s][1], y = sides[s][2], w = sides[s][3], h = sides[s][4];
            var alongX = sides[s][5] === "x";
            if (alongX ? (y < ay0 || y + h > ay1) : (x < ax0 || x + w > ax1))
                continue;
            var lo = alongX ? Math.max(x, ax0) : Math.max(y, ay0);
            var hi = alongX ? Math.min(x + w, ax1) : Math.min(y + h, ay1);
            var spans = hi > lo ? [[lo, hi]] : [];
            for (var a = 0; a < rects.length && spans.length > 0; a++) {
                if (a === t || !rects[a])
                    continue;
                var d = rects[a].r;
                if (alongX) {
                    if (d.y >= y + h || d.y + d.h <= y)
                        continue;
                    spans = subtract(spans, d.x, d.x + d.w);
                } else {
                    if (d.x >= x + w || d.x + d.w <= x)
                        continue;
                    spans = subtract(spans, d.y, d.y + d.h);
                }
            }
            for (var k = 0; k < spans.length; k++) {
                var from = Math.ceil(spans[k][0]), to = Math.floor(spans[k][1]);
                // Teilstücke: gerader Rand und schräges Ende an der unteren Ecke.
                var parts;
                if (side === "b")
                    parts = [[gx0, gx0 + reach, "resize-bl"], [gx0 + reach, gx1 - reach, "resize-b"], [gx1 - reach, gx1, "resize-br"]];
                else
                    parts = [[gy0, gy1 - reach, "resize-" + side], [gy1 - reach, gy1 + e, side === "l" ? "resize-bl" : "resize-br"]];
                for (var p = 0; p < parts.length; p++) {
                    var p0 = Math.max(from, parts[p][0]), p1 = Math.min(to, parts[p][1]);
                    if (p1 - p0 < 6)
                        continue;
                    var rx = alongX ? p0 : x, ry = alongX ? y : p0;
                    var rw = alongX ? p1 - p0 : w, rh = alongX ? h : p1 - p0;
                    result.push({
                        "id": idOf(win),
                        "kind": parts[p][2],
                        "output": String(win.output.name),
                        "x": rx - Math.round(out.x),
                        "y": ry - Math.round(out.y),
                        "w": rw,
                        "h": rh,
                        "gx": rx,
                        "gy": ry
                    });
                }
            }
        }
    }

    // Untere Ecken im Fenster, so gross wie GRIP.corner, nur wo kein Fenster darüber liegt.
    function pushCorners(result, win, out, g, rects, t) {
        var size = GRIP.corner;
        if (size <= 0 || g.w < 3 * size || g.h < 3 * size)
            return;
        var flat = false;
        try {
            flat = isMaximized(win) || win.fullScreen || win.resizeable === false;
        } catch (e) {}
        if (flat)
            return;
        var y = Math.round(g.y + g.h) - size;
        var corners = [["resize-bl", Math.round(g.x)], ["resize-br", Math.round(g.x + g.w) - size]];
        for (var k = 0; k < corners.length; k++) {
            var x = corners[k][1];
            if (x < out.x || x + size > out.x + out.width || y < out.y || y + size > out.y + out.height)
                continue;
            var covered = false;
            for (var o = t + 1; o < rects.length && !covered; o++) {
                var c = rects[o] && rects[o].r;
                if (c && c.x < x + size && c.x + c.w > x && c.y < y + size && c.y + c.h > y)
                    covered = true;
            }
            if (covered)
                continue;
            result.push({
                "id": idOf(win),
                "kind": corners[k][0],
                "output": String(win.output.name),
                "x": x - Math.round(out.x),
                "y": y - Math.round(out.y),
                "w": size,
                "h": size,
                "gx": x,
                "gy": y
            });
        }
    }

    var drag = null;
    // Grösse vor dem Einrasten, je Fenster: Zieht man es wieder weg, bekommt es sie zurück.
    var snapped = {};

    function screensList() {
        try {
            return workspace.screens || [];
        } catch (e) {
            return [];
        }
    }

    function outputAt(pos) {
        var list = screensList();
        for (var i = 0; i < list.length; i++) {
            var g = list[i].geometry;
            if (pos.x >= g.x && pos.x < g.x + g.width && pos.y >= g.y && pos.y < g.y + g.height)
                return list[i];
        }
        return null;
    }

    // Grenzt an dieser Kante ein anderer Bildschirm an, ist sie ein Durchgang, kein Rand.
    function neighbour(out, side) {
        var g = out.geometry;
        var list = screensList();
        for (var i = 0; i < list.length; i++) {
            if (list[i] === out || String(list[i].name) === String(out.name))
                continue;
            var o = list[i].geometry;
            var vertical = o.y < g.y + g.height && o.y + o.height > g.y;
            var horizontal = o.x < g.x + g.width && o.x + o.width > g.x;
            if (side === "left" && vertical && Math.abs(o.x + o.width - g.x) <= 1)
                return true;
            if (side === "right" && vertical && Math.abs(o.x - (g.x + g.width)) <= 1)
                return true;
            if (side === "top" && horizontal && Math.abs(o.y + o.height - g.y) <= 1)
                return true;
        }
        return false;
    }

    function areaOf(out, w) {
        try {
            return workspace.clientArea(KWin.MaximizeArea, out, workspace.currentDesktop);
        } catch (e) {
            return workspace.clientArea(KWin.MaximizeArea, w);
        }
    }

    function snapZone(w, pos) {
        if (!GRIP.snap)
            return null;
        var out = outputAt(pos);
        if (!out)
            return null;
        var g = out.geometry;
        var edge = 6;
        var left = pos.x <= g.x + edge && !neighbour(out, "left");
        var right = pos.x >= g.x + g.width - 1 - edge && !neighbour(out, "right");
        var top = pos.y <= g.y + edge && !neighbour(out, "top");
        if (!left && !right && !top)
            return null;
        var a = areaOf(out, w);
        var zone = {
            "output": String(out.name),
            "ox": g.x,
            "oy": g.y,
            "kind": "max",
            "x": a.x,
            "y": a.y,
            "w": a.width,
            "h": a.height
        };
        if (left || right) {
            var half = Math.round(a.width / 2);
            zone.x = left ? a.x : a.x + half;
            zone.w = left ? half : a.width - half;
            zone.kind = left ? "left" : "right";
            var rel = (pos.y - a.y) / Math.max(1, a.height);
            if (rel < 0.25 || rel > 0.75) {
                var halfH = Math.round(a.height / 2);
                zone.y = rel < 0.25 ? a.y : a.y + halfH;
                zone.h = rel < 0.25 ? halfH : a.height - halfH;
                zone.kind += rel < 0.25 ? "-top" : "-bottom";
            }
        }
        zone.x = Math.round(zone.x);
        zone.y = Math.round(zone.y);
        zone.w = Math.round(zone.w);
        zone.h = Math.round(zone.h);
        return zone;
    }

    function zoneKey(zone) {
        return zone ? zone.output + ":" + zone.kind : "";
    }
    var lastClick = {
        "id": "",
        "time": 0
    };
    var idleTimer = null;
    try {
        idleTimer = new QTimer();
        idleTimer.singleShot = true;
        idleTimer.interval = 5000;
        idleTimer.timeout.connect(function () {
            dragEnd();
        });
    } catch (e) {
        idleTimer = null;
    }

    function findWindow(id) {
        var all = workspace.windowList();
        for (var i = 0; i < all.length; i++) {
            if (idOf(all[i]) === id)
                return all[i];
        }
        return null;
    }

    function isMaximized(w) {
        var id = idOf(w);
        if (maximized[id] === undefined)
            maximized[id] = guessMaximized(w);
        return !!maximized[id];
    }

    // Der Aufruf kommt einige Millisekunden nach dem Druck an; der Zeiger kann die Leiste dann
    // schon verlassen haben. Deshalb zählt die nächstgelegene Leiste, nicht nur ein Volltreffer.
    function gripNear(pos) {
        var list = grips();
        var best = null;
        var bestDistance = 1e9;
        for (var i = 0; i < list.length; i++) {
            var g = list[i];
            var dx = pos.x < g.gx ? g.gx - pos.x : (pos.x > g.gx + g.w ? pos.x - (g.gx + g.w) : 0);
            var dy = pos.y < g.gy ? g.gy - pos.y : (pos.y > g.gy + g.h ? pos.y - (g.gy + g.h) : 0);
            var corner = g.kind && g.kind !== "move";
            // Ecken sind klein: nur bei Treffer oder knapp daneben (der Zeiger läuft beim Drücken weiter).
            if (corner ? (dx > 24 || dy > 24) : (dx > 160 || dy > 320))
                continue;
            // Bei gleichem Abstand gewinnt die Ecke.
            var distance = corner ? dx + dy - 0.5 : dx * 2 + dy;
            if (distance < bestDistance) {
                bestDistance = distance;
                best = g;
            }
        }
        return best;
    }

    function dragBegin() {
        dragEnd();
        if (!GRIP.enabled)
            return;
        var pos = workspace.cursorPos;
        var g = gripNear(pos);
        if (!g)
            return;
        var w = findWindow(g.id);
        if (!w)
            return;
        try {
            workspace.activeWindow = w;
        } catch (e) {}
        var now = Date.now();
        if (g.kind && g.kind !== "move") {
            resizeBegin(w, g, pos);
            return;
        }
        if (lastClick.id === g.id && now - lastClick.time < 450) {
            // Doppelklick wie auf einer Titelleiste: maximieren und zurück.
            lastClick.id = "";
            try {
                var max = isMaximized(w);
                w.setMaximize(!max, !max);
            } catch (e) {}
            return;
        }
        lastClick.id = g.id;
        lastClick.time = now;
        var f = w.frameGeometry;
        drag = {
            "w": w,
            "id": g.id,
            "fx": f.width > 0 ? Math.max(0, Math.min(1, (pos.x - f.x) / f.width)) : 0.5,
            "dy": Math.max(-GRIP.outside, Math.min(GRIP.height, pos.y - f.y)),
            "sx": pos.x,
            "sy": pos.y,
            "moved": false,
            "waitWidth": -1,
            "waitUntil": 0,
            "busy": false
        };
        try {
            workspace.cursorPosChanged.connect(dragMove);
            w.frameGeometryChanged.connect(dragMove);
        } catch (e) {}
        if (idleTimer)
            idleTimer.start();
        dragMove();
    }

    function resizeBegin(w, g, pos) {
        var f = w.frameGeometry;
        lastClick.id = "";
        delete snapped[g.id];
        drag = {
            "w": w,
            "id": g.id,
            "resize": g.kind,
            "f0": {
                "x": f.x,
                "y": f.y,
                "w": f.width,
                "h": f.height
            },
            "sx": pos.x,
            "sy": pos.y,
            "moved": false,
            "busy": false
        };
        try {
            workspace.cursorPosChanged.connect(dragMove);
        } catch (e) {}
        if (idleTimer)
            idleTimer.start();
    }

    function resizeMove(pos) {
        var w = drag.w;
        var f0 = drag.f0;
        var dx = pos.x - drag.sx;
        var dy = pos.y - drag.sy;
        if (!drag.moved && Math.abs(dx) + Math.abs(dy) < 3)
            return;
        drag.moved = true;
        var minW = 160, minH = 100;
        try {
            if (w.minSize && w.minSize.width > minW)
                minW = w.minSize.width;
            if (w.minSize && w.minSize.height > minH)
                minH = w.minSize.height;
        } catch (e) {}
        // resize-bl, -br, -b, -l, -r: l zieht den linken Rand, r den rechten, b den unteren.
        var edges = drag.resize.substring(7);
        var left = edges.indexOf("l") >= 0;
        var width = left ? f0.w - dx : (edges.indexOf("r") >= 0 ? f0.w + dx : f0.w);
        width = Math.round(Math.max(minW, width));
        var height = Math.round(Math.max(minH, edges.indexOf("b") >= 0 ? f0.h + dy : f0.h));
        var x = left ? Math.round(f0.x + f0.w - width) : Math.round(f0.x);
        if (idleTimer)
            idleTimer.start();
        drag.busy = true;
        try {
            w.frameGeometry = {
                "x": x,
                "y": Math.round(f0.y),
                "width": width,
                "height": height
            };
        } catch (e) {}
        drag.busy = false;
    }

    function dragMove() {
        if (!drag || drag.busy)
            return;
        if (drag.resize) {
            var alive = false;
            try {
                alive = drag.w && !drag.w.deleted;
            } catch (e) {}
            if (!alive) {
                dragEnd();
                return;
            }
            resizeMove(workspace.cursorPos);
            return;
        }
        var w = drag.w;
        var gone = true;
        try {
            gone = !w || w.deleted;
        } catch (e) {}
        if (gone) {
            dragEnd();
            return;
        }
        var pos = workspace.cursorPos;
        if (!drag.moved) {
            if (Math.abs(pos.x - drag.sx) + Math.abs(pos.y - drag.sy) < 5)
                return;
            drag.moved = true;
            lastClick.id = "";
            var before = snapped[drag.id];
            if (before && !isMaximized(w)) {
                // Eingerastet: beim Wegziehen zurück zur Grösse davor, der Griffpunkt bleibt.
                delete snapped[drag.id];
                drag.busy = true;
                try {
                    w.frameGeometry = {
                        "x": Math.round(pos.x - drag.fx * before.w),
                        "y": Math.round(pos.y - drag.dy),
                        "width": before.w,
                        "height": before.h
                    };
                } catch (e) {}
                drag.busy = false;
                return;
            }
            if (isMaximized(w)) {
                // Wie bei einer Titelleiste: Ziehen löst die Maximierung. Die neue Grösse kommt
                // erst, wenn das Programm sie bestätigt; so lange bleibt das Fenster stehen.
                drag.waitWidth = w.frameGeometry.width;
                drag.waitUntil = Date.now() + 500;
                try {
                    w.setMaximize(false, false);
                } catch (e) {}
            }
        }
        var f = w.frameGeometry;
        if (drag.waitWidth >= 0) {
            if (Math.abs(f.width - drag.waitWidth) < 2 && Date.now() < drag.waitUntil)
                return;
            drag.waitWidth = -1;
        }
        if (idleTimer)
            idleTimer.start();
        var zone = snapZone(w, pos);
        if (zoneKey(zone) !== zoneKey(drag.snap)) {
            drag.snap = zone;
            schedule();
        }
        var x = Math.round(pos.x - drag.fx * f.width);
        var y = Math.round(pos.y - drag.dy);
        try {
            // Der obere Rand bleibt erreichbar: nicht unter die Leiste der Shell und nicht aus dem
            // Bild. Auf einen anderen Bildschirm hinüber geht es trotzdem; dort gilt dessen Fläche.
            var screen = w.output.geometry;
            if (pos.x >= screen.x && pos.x < screen.x + screen.width && pos.y >= screen.y && pos.y < screen.y + screen.height) {
                var area = workspace.clientArea(KWin.MaximizeArea, w);
                y = Math.max(area.y, Math.min(y, area.y + area.height - GRIP.height));
                x = Math.max(area.x - f.width + 80, Math.min(x, area.x + area.width - 80));
            }
        } catch (e) {}
        if (x === Math.round(f.x) && y === Math.round(f.y))
            return;
        drag.busy = true;
        try {
            w.frameGeometry = {
                "x": x,
                "y": y,
                "width": f.width,
                "height": f.height
            };
        } catch (e) {}
        drag.busy = false;
    }

    // commit: die Maustaste wurde losgelassen (nicht: Fenster weg, Zeitablauf, neuer Griff).
    function dragEnd(commit) {
        if (!drag)
            return;
        var w = drag.w;
        var zone = commit === true && drag.moved ? drag.snap : null;
        var id = drag.id;
        drag = null;
        if (zone) {
            try {
                if (zone.kind === "max") {
                    w.setMaximize(true, true);
                } else {
                    var f = w.frameGeometry;
                    if (!snapped[id])
                        snapped[id] = {
                            "w": Math.round(f.width),
                            "h": Math.round(f.height)
                        };
                    w.frameGeometry = {
                        "x": zone.x,
                        "y": zone.y,
                        "width": zone.w,
                        "height": zone.h
                    };
                }
            } catch (e) {}
        }
        if (idleTimer)
            idleTimer.stop();
        try {
            workspace.cursorPosChanged.disconnect(dragMove);
        } catch (e) {}
        try {
            w.frameGeometryChanged.disconnect(dragMove);
        } catch (e) {}
        schedule();
    }

    function send() {
        var windows = [];
        var all = workspace.windowList();
        for (var i = 0; i < all.length; i++) {
            if (wanted(all[i]))
                windows.push(info(all[i]));
        }
        var desktops = [];
        var ds = workspace.desktops || [];
        for (var j = 0; j < ds.length; j++) {
            hookDesktop(ds[j]);
            desktops.push({
                "id": String(ds[j].id),
                "name": String(ds[j].name || ""),
                "number": ds[j].x11DesktopNumber | 0
            });
        }
        var active = workspace.activeWindow;
        var state = {
            "v": 1,
            "seq": ++seq,
            "current": workspace.currentDesktop ? String(workspace.currentDesktop.id) : "",
            "activeOutput": workspace.activeScreen ? String(workspace.activeScreen.name) : "",
            "active": active && wanted(active) ? idOf(active) : "",
            "desktops": desktops,
            "windows": windows,
            "grips": null,
            "snap": null
        };
        if (drag && drag.snap) {
            state.snap = {
                "output": drag.snap.output,
                "x": drag.snap.x - drag.snap.ox,
                "y": drag.snap.y - drag.snap.oy,
                "w": drag.snap.w,
                "h": drag.snap.h,
                "kind": drag.snap.kind
            };
        }
        if (!drag) {
            state.grips = grips();
            rememberIssued(state.grips);
        }
        callDBus(SERVICE, PATH, IFACE, "state", JSON.stringify(state));
    }

    var timer = null;
    try {
        timer = new QTimer();
        timer.singleShot = true;
        timer.interval = 25;
        timer.timeout.connect(send);
    } catch (e) {
        timer = null;
    }

    function schedule() {
        if (timer)
            timer.start();
        else
            send();
    }

    function connectSafe(obj, name, fn) {
        try {
            if (obj[name] && obj[name].connect)
                obj[name].connect(fn);
        } catch (e) {}
    }

    function hookDesktop(d) {
        var id = String(d.id);
        if (hookedDesktops[id])
            return;
        hookedDesktops[id] = true;
        connectSafe(d, "nameChanged", schedule);
    }

    function hook(w) {
        if (!w)
            return;
        var id = idOf(w);
        if (hooked[id])
            return;
        hooked[id] = true;
        var names = ["captionChanged", "minimizedChanged", "fullScreenChanged", "desktopsChanged", "outputChanged", "demandsAttentionChanged", "skipTaskbarChanged", "desktopFileNameChanged", "windowClassChanged"];
        for (var i = 0; i < names.length; i++)
            connectSafe(w, names[i], schedule);
        // Alpe: Für die Griffleisten zählen auch Lage und Stapelfolge, und zwar aller Fenster.
        if (GRIP.enabled) {
            connectSafe(w, "frameGeometryChanged", schedule);
            connectSafe(w, "stackingOrderChanged", schedule);
            connectSafe(w, "hiddenChanged", schedule);
        }
        // Alpe: KWin 6.8 meldet den Wechsel der Titelleiste als decorationPolicyChanged
        // (noBorder ist dort eine Ableitung der neuen Dekorations-Richtlinie); bis 6.7 noBorderChanged.
        var onBorder = function () {
            borderChanged[id] = Date.now();
            delete clientDecorated[id];
            schedule();
        };
        connectSafe(w, "noBorderChanged", onBorder);
        connectSafe(w, "decorationPolicyChanged", onBorder);
        connectSafe(w, "maximizedAboutToChange", function (mode) {
            maximized[id] = mode === 3;
            schedule();
        });
    }

    var existing = workspace.windowList();
    for (var i = 0; i < existing.length; i++)
        hook(existing[i]);

    connectSafe(workspace, "windowAdded", function (w) {
        hook(w);
        schedule();
    });
    connectSafe(workspace, "windowRemoved", function (w) {
        try {
            var id = idOf(w);
            delete hooked[id];
            delete maximized[id];
            delete clientDecorated[id];
            delete borderChanged[id];
            delete snapped[id];
            if (drag && drag.id === id)
                dragEnd();
        } catch (e) {}
        schedule();
    });
    connectSafe(workspace, "windowActivated", schedule);
    connectSafe(workspace, "currentDesktopChanged", schedule);
    connectSafe(workspace, "desktopsChanged", schedule);
    connectSafe(workspace, "screensChanged", schedule);

    // Global shortcuts. KWin owns them (kglobalaccel), so they show up under
    // System Settings > Shortcuts > KWin and can be rebound there. A default
    // key that is already taken elsewhere is left unassigned by KWin.
    // Alpe: Die Kennungen bleiben (an ihnen hängen die vergebenen Tasten), nur die Anzeigenamen
    // tragen den eigenen Namen.
    var shortcuts = [
        ["dms-launcher", "Alpe: Starter", "Meta+Space"],
        ["dms-clipboard", "Alpe: Zwischenablage", "Meta+Shift+V"],
        ["dms-processlist", "Alpe: Systemmonitor", "Meta+M"],
        ["dms-settings", "Alpe: Einstellungen", "Meta+,"],
        ["dms-notifications", "Alpe: Benachrichtigungen", "Meta+N"],
        ["dms-control-center", "Alpe: Kontrollzentrum", "Meta+Shift+C"],
        ["dms-dash", "Alpe: Dashboard", "Meta+Shift+D"],
        ["dms-powermenu", "Alpe: Energiemenü", "Meta+Shift+X"],
        ["dms-notepad", "Alpe: Notizblock", ""]
    ];

    function bindShortcut(entry) {
        try {
            registerShortcut(entry[0], entry[1], entry[2], function () {
                callDBus(SERVICE, PATH, IFACE, "shortcut", entry[0]);
            });
        } catch (e) {}
    }

    for (var s = 0; s < shortcuts.length; s++)
        bindShortcut(shortcuts[s]);

    // Alpe: Auslöser der Griffleisten. Die Shell ruft sie über kglobalaccel auf; eine Taste
    // brauchen sie nicht.
    if (GRIP.enabled) {
        try {
            registerShortcut("alpe-grip-begin", "Alpe: Fenster greifen (intern)", "", dragBegin);
            registerShortcut("alpe-grip-end", "Alpe: Fenster loslassen (intern)", "", function () {
                dragEnd(true);
            });
        } catch (e) {}
    }

    send();
})();
