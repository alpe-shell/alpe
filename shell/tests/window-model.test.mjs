import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const here = new URL("./", import.meta.url);
const source = path => readFileSync(new URL(path, here), "utf8");
const fixture = name => JSON.parse(readFileSync(new URL(`fixtures/windows/${name}.json`, here), "utf8"));
const Position = { Top: 0, Bottom: 1, Left: 2, Right: 3 };
const positions = ["Top", "Bottom", "Left", "Right"];

function lift(text, name, context) {
    const match = text.match(new RegExp(`^    function ${name}\\([^\\n]*\\) \\{\\n[\\s\\S]*?^    \\}`, "m"));
    assert.ok(match, `function ${name} not found`);
    vm.runInContext(match[0], context);
}

const compositorService = source("../Services/CompositorService.qml");
const model = vm.createContext({});
vm.runInContext(source("../Common/WindowModel.js").replace(/^\.pragma.*$/m, ""), model);

function filterCurrentDisplay(list, name) {
    return list.filter(t => !t.screens || t.screens.includes(name));
}

function facade(compositor, globals) {
    const context = vm.createContext({
        compositor,
        WindowModel: model,
        _edgePositions: { top: Position.Top, bottom: Position.Bottom, left: Position.Left, right: Position.Right },
        sortedToplevels: [],
        ToplevelManager: { activeToplevel: null, toplevels: { values: [] } },
        Hyprland: {},
        filterCurrentDisplay,
        ...globals
    });
    for (const name of ["_windowAlive", "_retainedWindow", "activeWindowForScreen", "windowPid", "windowOnActiveWorkspace", "windowsHideBar", "windowsOverlapDock", "maximizedWindowOnScreen", "specialWorkspaceName"])
        lift(compositorService, name, context);
    return context;
}

function presentable(toplevel) {
    return !!toplevel && !!(toplevel.title || toplevel.appId);
}

function hyprlandState() {
    const s = fixture("hyprland");
    const waylands = {};
    const wayland = id => id === null ? null : (waylands[id] ??= { id, appId: id, title: id });
    return { focusedWorkspace: s.focusedWorkspace, toplevels: s.toplevels.map(t => ({ ...t, wayland: wayland(t.wayland) })), wayland: id => wayland(id) };
}

function focusedAppHyprland(state, activeWindow, focusedWorkspace) {
    const context = facade("hyprland", { Hyprland: { toplevels: { values: state.toplevels }, focusedWorkspace } });
    return { onActiveWorkspace: presentable(activeWindow) && context.windowOnActiveWorkspace("DP-1", activeWindow, false), pid: context.windowPid(activeWindow) };
}

function specialWorkspaceName(state, waylandToplevel) {
    return facade("hyprland", { Hyprland: { toplevels: { values: state.toplevels } } }).specialWorkspaceName(waylandToplevel);
}

test("hyprland: workspace membership against the focused workspace, pid from the ipc object, special workspace names", () => {
    const hypr = hyprlandState();
    assert.deepEqual(focusedAppHyprland(hypr, hypr.wayland("w1"), hypr.focusedWorkspace), { onActiveWorkspace: true, pid: 501 });
    assert.deepEqual(focusedAppHyprland(hypr, hypr.wayland("w3"), hypr.focusedWorkspace), { onActiveWorkspace: false, pid: 503 });
    assert.deepEqual(focusedAppHyprland(hypr, hypr.wayland("w4"), hypr.focusedWorkspace), { onActiveWorkspace: false, pid: 0 });
    assert.deepEqual(focusedAppHyprland(hypr, hypr.wayland("w5"), hypr.focusedWorkspace), { onActiveWorkspace: false, pid: 0 });
    assert.deepEqual(focusedAppHyprland(hypr, hypr.wayland("w1"), null), { onActiveWorkspace: false, pid: 501 });
    assert.deepEqual(["w1", "w2", "w4", "w5"].map(id => specialWorkspaceName(hypr, hypr.wayland(id))), ["", "scratch", "notes", ""]);
    assert.equal(specialWorkspaceName(hypr, null), "");
});

test("hyprland main: named workspaces all report id -1, so active-workspace membership compares addresses", () => {
    const music = { id: -1, address: "music", name: "music" };
    const chat = { id: -1, address: "chat", name: "chat" };
    const win = { id: "w", appId: "w", title: "w" };
    const state = { toplevels: [{ wayland: win, workspace: music, lastIpcObject: { pid: 7 } }] };
    assert.deepEqual([chat, music].map(focused => focusedAppHyprland(state, win, focused).onActiveWorkspace), [false, true]);
});

