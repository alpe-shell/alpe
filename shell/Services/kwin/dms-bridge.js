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
            "windows": windows
        };
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
    var shortcuts = [
        ["dms-launcher", "DMS: Launcher", "Meta+Space"],
        ["dms-clipboard", "DMS: Clipboard history", "Meta+Shift+V"],
        ["dms-processlist", "DMS: System monitor", "Meta+Shift+M"],
        ["dms-settings", "DMS: Settings", "Meta+,"],
        ["dms-notifications", "DMS: Notification center", "Meta+N"],
        ["dms-control-center", "DMS: Control center", "Meta+Shift+C"],
        ["dms-dash", "DMS: Dashboard", "Meta+Shift+D"],
        ["dms-powermenu", "DMS: Power menu", "Meta+Shift+X"],
        ["dms-notepad", "DMS: Notepad", ""]
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

    send();
})();
