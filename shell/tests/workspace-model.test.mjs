import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const model = vm.createContext({});
vm.runInContext(readFileSync(new URL("../Common/WorkspaceModel.js", import.meta.url), "utf8").replace(/^\.pragma.*$/m, ""), model);
const fixture = name => JSON.parse(readFileSync(new URL(`fixtures/workspaces/${name}.json`, import.meta.url), "utf8"));
const plain = value => JSON.parse(JSON.stringify(value));
const pick = (records, key) => Array.from(records, record => record[key]);

function hyprland(scenario) {
    const s = fixture("hyprland")[scenario];
    const monitors = s.monitors.map(monitor => ({ name: monitor.name, description: monitor.description ?? "" }));
    const monitor = name => monitors.find(m => m.name === name) ?? { name };
    const workspaces = s.workspaces.map(ws => ({ id: ws.id, name: ws.name, monitor: monitor(ws.monitor), lastIpcObject: { monitor: ws.ipcMonitor }, active: ws.active, urgent: ws.urgent }));
    const workspace = id => workspaces.find(ws => ws.id === id) ?? null;
    monitors.forEach((m, i) => m.activeWorkspace = workspace(s.monitors[i].activeWorkspaceId));
    const toplevels = s.toplevels.map(tl => ({ workspace: workspace(tl.workspace), wayland: tl.wayland ? { address: tl.address } : null }));
    return { workspaces, monitors, focusedWorkspace: workspace(s.focusedWorkspaceId), toplevels, windows: toplevels.filter(tl => tl.wayland).map(tl => tl.wayland), visibleSpecials: {} };
}


test("neighbor stepping stops at the ends", () => {
    const list = ["a", "b", "c"];
    assert.equal(model.neighbor(list, 0, 1), "b");
    assert.equal(model.neighbor(list, 2, 1), null);
});

test("hyprland lists skip special workspaces and fall back per monitor", () => {
    const raw = hyprland("twoScreens");
    const screen = model.hyprlandWorkspacesForScreen(raw, "HDMI-A-1", false, false);
    assert.deepEqual(pick(screen, "id"), [2, 4, -1337]);
    assert.deepEqual(pick(screen, "idx"), [2, 4, null]);
    assert.deepEqual(pick(screen, "name"), ["2", "4", "chat"]);
    assert.deepEqual(pick(screen, "urgent"), [true, false, false]);
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "HDMI-A-1", false, true), "id"), [2, 4]);
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "HDMI-A-1", true, false), "id"), [1, 2, 3, 4, -1337]);
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(hyprland("staleMonitor"), "DP-2", false, false), "id"), [5]);
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(hyprland("onlySpecial"), "DP-1", false, false), "name"), ["1"]);
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(hyprland("empty"), "DP-1", false, true), "id"), [1]);
    assert.equal(model.hyprlandCurrentId(raw, "HDMI-A-1", false), 2);
    assert.equal(model.hyprlandCurrentId(raw, "HDMI-A-1", true), 3);
    assert.equal(model.hyprlandCurrentId(hyprland("empty"), "DP-1", false), 1);
});

test("hyprland padding fills numbered ids up to the minimum, skipping ids owned by other monitors", () => {
    const raw = hyprland("twoScreens");
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "HDMI-A-1", false, false, 5), "id"), [2, 4, 5, -1337]);
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "HDMI-A-1", true, false, 6), "id"), [1, 2, 3, 4, 5, 6, -1337]);
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "HDMI-A-1", false, true, 4), "id"), [2, 4]);
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(hyprland("empty"), "DP-1", false, false, 3), "id"), [1, 2, 3]);
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "HDMI-A-1", false, false, 0), "id"), [2, 4, -1337]);
    const filled = model.hyprlandWorkspacesForScreen(raw, "HDMI-A-1", false, false, 5).find(ws => ws.id === 5);
    assert.deepEqual(plain(filled), { id: 5, idx: 5, address: "", name: "5", output: "HDMI-A-1", active: false, placeholder: false, urgent: false });
    raw.workspaces.push({ id: 5, name: "5", monitor: null, lastIpcObject: {} });
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "HDMI-A-1", false, false, 5), "id"), [2, 4, 5, -1337]);
});

test("hyprland padding honours workspace rules that bind ids to a monitor", () => {
    const raw = hyprland("twoScreens");
    raw.monitors.find(m => m.name === "HDMI-A-1").description = "Acme Ultra 27 0x1234";
    raw.workspaceRules = [
        { workspaceString: "r[1-5]", monitor: "DP-1" },
        { workspaceString: "6", monitor: "desc:Acme Ultra" },
        { workspaceString: "7 s[true]", monitor: "DP-1" },
        { workspaceString: "8", monitor: "DP-3" }
    ];
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "HDMI-A-1", false, false, 8), "id"), [2, 4, 6, 7, 8, -1337]);
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "DP-1", false, false, 8), "id"), [1, 3, 5, 7, 8]);
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "DP-1", true, false, 8), "id"), [1, 2, 3, 4, 5, 6, 7, 8, -1337]);
});

test("hyprland special workspaces are opt-in, listed last on their monitor and active while overlaid", () => {
    const raw = hyprland("twoScreens");
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "DP-1", false, false, 0, false), "id"), [1, 3]);
    const shown = model.hyprlandWorkspacesForScreen(raw, "DP-1", false, false, 0, true);
    assert.deepEqual(pick(shown, "name"), ["1", "3", "scratch", "special"]);
    assert.deepEqual(plain(shown[2]), { id: -98, idx: null, name: "scratch", output: "DP-1", active: false, placeholder: false, urgent: false, special: true });
    assert.deepEqual(plain(shown[3]), { id: null, idx: null, name: "special", output: "DP-1", active: false, placeholder: false, urgent: false, special: true });
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "HDMI-A-1", false, false, 0, true), "name"), ["2", "4", "chat", "special"]);
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "HDMI-A-1", true, false, 0, true), "name"), ["1", "2", "3", "4", "chat", "scratch", "special"]);
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "DP-1", false, true, 0, true), "name"), ["1", "3", "special"]);
    raw.visibleSpecials = { "DP-1": "special:scratch" };
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "DP-1", false, true, 0, true), "active"), [false, true, true, false]);
    raw.visibleSpecials = { "HDMI-A-1": "special:special" };
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "HDMI-A-1", false, false, 0, true), "active"), [true, false, false, true]);
    assert.equal(model.hyprlandWorkspacesForScreen(raw, "DP-1", true, false, 0, true).at(-1).active, true);
    assert.deepEqual(plain(model.hyprlandActiveWorkspace(raw, "HDMI-A-1")), { id: "special:special", idx: null, name: "special", output: "HDMI-A-1", active: true, placeholder: false, special: true });
    assert.deepEqual(pick([model.hyprlandActiveWorkspace(raw, "DP-1")], "id"), [3]);
    raw.visibleSpecials = { "DP-1": "special:scratch" };
    assert.deepEqual(plain(model.hyprlandActiveWorkspace(raw, "DP-1")), { id: -98, idx: null, name: "scratch", output: "DP-1", active: true, placeholder: false, special: true });
});

test("hyprland specials without ids match windows by name", () => {
    const raw = hyprland("twoScreens");
    const scratch = raw.workspaces.find(ws => ws.name === "special:scratch");
    scratch.id = 0;
    raw.workspaces.push({ id: 0, name: "special:special", monitor: raw.monitors[0], lastIpcObject: { monitor: "DP-1" }, active: false, urgent: false });
    const win = { address: "0xd" };
    raw.toplevels.push({ workspace: scratch, wayland: win });
    raw.windows.push(win);
    const shown = model.hyprlandWorkspacesForScreen(raw, "DP-1", false, true, 0, true);
    assert.deepEqual(pick(shown, "name"), ["1", "3", "scratch", "special"]);
    assert.equal(model.hyprlandWorkspaceOccupied(raw.toplevels, shown[2]), true);
    assert.equal(model.hyprlandWorkspaceOccupied(raw.toplevels, shown[3]), false);
    assert.deepEqual(pick(model.hyprlandWindowsOnWorkspace(raw.windows, shown[2], raw.toplevels), "address"), ["0xd"]);
    assert.deepEqual(model.hyprlandWindowsOnWorkspace(raw.windows, shown[3], raw.toplevels), []);
    raw.visibleSpecials = { "DP-1": "special:scratch" };
    assert.equal(model.hyprlandActiveWorkspace(raw, "DP-1").id, "special:scratch");
});

test("hyprland scroll targets use ipc monitors, numbered ids and ignore follow focus for current", () => {
    const raw = hyprland("twoScreens");
    assert.deepEqual(pick(model.hyprlandScrollWorkspaces(raw, "HDMI-A-1", false), "id"), [2, 4]);
    assert.deepEqual(pick(model.hyprlandScrollWorkspaces(raw, "HDMI-A-1", true), "id"), [1, 2, 3, 4]);
    assert.deepEqual(pick(model.hyprlandScrollWorkspaces(hyprland("staleMonitor"), "DP-2", false), "id"), [5]);
    assert.deepEqual(pick(model.hyprlandScrollWorkspaces(hyprland("empty"), "DP-1", false), "id"), [1]);
    assert.equal(model.hyprlandScrollCurrentId(raw, "HDMI-A-1"), 2);
    assert.equal(model.hyprlandScrollCurrentId(raw, ""), 1);
});

test("hyprland active workspace, windows and occupancy", () => {
    const raw = hyprland("twoScreens");
    assert.deepEqual(plain(model.hyprlandActiveWorkspace(raw, "HDMI-A-1")), { id: 2, idx: 2, name: "", output: "HDMI-A-1", active: true, placeholder: false });
    assert.equal(model.hyprlandActiveWorkspace(raw, "").id, 3);
    assert.equal(model.hyprlandActiveWorkspace(hyprland("specialActive"), "DP-1"), null);
    assert.deepEqual(plain(model.hyprlandActiveWorkspace(hyprland("namedActive"), "HDMI-A-1")), { id: -1337, idx: null, name: "chat", output: "HDMI-A-1", active: true, placeholder: false });
    assert.equal(model.hyprlandActiveWorkspace(hyprland("empty"), "DP-1"), null);
    assert.deepEqual(pick(model.hyprlandWindowsOnWorkspace(raw.windows, { id: 3 }, raw.toplevels), "address"), ["0xa"]);
    assert.deepEqual(plain(model.hyprlandWindowsOnWorkspace(raw.windows, { id: 1 }, raw.toplevels)), []);
    assert.equal(model.hyprlandWorkspaceOccupied(raw.toplevels, { id: 1 }), true);
    assert.equal(model.hyprlandWorkspaceOccupied(raw.toplevels, { id: 2 }), false);
});

test("hyprland main: named workspaces all report id -1, so identity and targets come from the address", () => {
    const monitor = { name: "DP-1" };
    const ws = (id, address, name) => ({ id, address, name, monitor, lastIpcObject: {} });
    const workspaces = [ws(1, "1", "1"), ws(-1, "music", "Tunes"), ws(-1, "chat", "chat"), ws(-1, "notes", "notes")];
    const [one, music, chat] = workspaces;
    monitor.activeWorkspace = chat;
    const win = { address: "0xa" };
    const toplevels = [{ workspace: one, wayland: null }, { workspace: music, wayland: win }];
    const raw = { workspaces, monitors: [monitor], focusedWorkspace: chat, toplevels, visibleSpecials: {} };
    assert.equal(model.hyprlandCurrentId(raw, "DP-1", false), "chat");
    assert.deepEqual(pick(model.hyprlandWorkspacesForScreen(raw, "DP-1", false, true), "name"), ["1", "chat", "Tunes"]);
    const chatRecord = model.hyprlandWorkspacesForScreen(raw, "DP-1", false, false).find(record => record.name === "chat");
    assert.equal(model.hyprlandWorkspaceOccupied(toplevels, chatRecord), false);
    assert.deepEqual(model.hyprlandWindowsOnWorkspace([win], chatRecord, toplevels), []);
    assert.deepEqual([one, music, { id: -1337, address: "-1337", name: "chat" }, { id: -1, address: "special:scratch", name: "special:scratch" }].map(model.hyprlandSelector), [1, "name:music", "name:chat", "special:scratch"]);
});

