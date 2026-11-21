.pragma library

function placeholder() {
    return {
        id: null,
        idx: null,
        name: "",
        output: "",
        active: false,
        placeholder: true
    };
}

function neighbor(workspaces, index, direction) {
    const next = direction > 0 ? Math.min(index + 1, workspaces.length - 1) : Math.max(index - 1, 0);
    return next === index ? null : workspaces[next];
}

function reuse(cache, id, record) {
    const previous = cache[id];
    if (previous && Object.keys(record).every(key => previous[key] === record[key]))
        return previous;
    cache[id] = record;
    return record;
}

function hyprlandSpecialName(name) {
    return name === "special" || name.startsWith("special:");
}

function hyprlandSpecial(ws) {
    return !(ws.id > 0) && hyprlandSpecialName(ws.name ?? "");
}

// Hyprland 0.57 gives named workspaces no id (Quickshell reports -1 for all of them), so the address is their identity
function hyprlandKey(ws) {
    if (ws?.id > 0)
        return ws.id;
    return ws?.address || ws?.name || "";
}

// "name:" resolves against the address, which a rename leaves alone; pre-main Hyprland had no address (Quickshell then echoes the id)
function hyprlandSelector(ws) {
    if (ws?.id > 0)
        return ws.id;
    const address = String(ws?.address ?? "");
    const target = address && !/^-?\d+$/.test(address) ? address : String(ws?.name ?? "");
    return hyprlandSpecialName(target) ? target : "name:" + target;
}

function hyprlandOrder(a, b) {
    const keyA = a.id < 0 ? Number.MAX_SAFE_INTEGER : a.id;
    const keyB = b.id < 0 ? Number.MAX_SAFE_INTEGER : b.id;
    if (keyA !== keyB)
        return keyA - keyB;
    return (a.name ?? "").localeCompare(b.name ?? "");
}

function hyprlandRecord(ws) {
    return {
        id: ws.id,
        idx: ws.id > 0 ? ws.id : null,
        address: ws.address ?? "",
        name: ws.name ?? "",
        output: ws.monitor?.name ?? "",
        active: ws.active === true,
        placeholder: false,
        urgent: ws.urgent === true
    };
}

function hyprlandCurrentId(raw, screenName, followFocus) {
    const ws = !screenName || followFocus ? raw.focusedWorkspace : raw.monitors.find(m => m.name === screenName)?.activeWorkspace;
    return hyprlandKey(ws) || 1;
}

function hyprlandMonitorWorkspaces(raw, workspaces, screenName) {
    const monitorWorkspaces = workspaces.filter(ws => ws.monitor?.name === screenName);
    if (monitorWorkspaces.length > 0)
        return monitorWorkspaces.sort(hyprlandOrder);
    const active = raw.monitors.find(m => m.name === screenName)?.activeWorkspace;
    return active ? [active] : [];
}

function hyprlandListedWorkspaces(raw, screenName, followFocus, occupiedOnly) {
    const regular = raw.workspaces.filter(ws => !hyprlandSpecial(ws));
    if (regular.length === 0)
        return [hyprlandRecord({
                id: 1,
                name: "1"
            })];
    const workspaces = !screenName || followFocus ? regular.slice().sort(hyprlandOrder) : hyprlandMonitorWorkspaces(raw, regular, screenName);
    if (!occupiedOnly)
        return workspaces.map(hyprlandRecord);
    const currentKey = hyprlandCurrentId(raw, screenName, followFocus);
    return workspaces.filter(ws => hyprlandKey(ws) === currentKey || hyprlandWorkspaceOccupied(raw.toplevels, ws)).map(hyprlandRecord);
}

function hyprlandRuleIds(workspaceString) {
    const tokens = String(workspaceString ?? "").trim().split(/\s+/);
    if (tokens.includes("s[true]"))
        return [];
    const ids = [];
    for (const token of tokens) {
        if (/^\d+$/.test(token)) {
            ids.push(Number(token));
            continue;
        }
        const range = /^r\[(\d+)-(\d+)\]$/.exec(token);
        if (!range)
            continue;
        for (let id = Number(range[1]); id <= Number(range[2]); id++)
            ids.push(id);
    }
    return ids;
}

// `desc:` rules match a description prefix, like Hyprland's getMonitorFromDesc; a rule for an unplugged monitor binds nothing
function hyprlandRuleMonitor(raw, rule) {
    const target = String(rule.monitor ?? "");
    if (!target)
        return "";
    if (!target.startsWith("desc:"))
        return raw.monitors.some(m => m.name === target) ? target : "";
    const desc = target.slice(5).trim();
    return raw.monitors.find(m => (m.description ?? m.lastIpcObject?.description ?? "").startsWith(desc))?.name ?? "";
}

function hyprlandBoundMonitor(raw, id) {
    for (const rule of raw.workspaceRules ?? []) {
        if (!hyprlandRuleIds(rule.workspaceString).includes(id))
            continue;
        const monitor = hyprlandRuleMonitor(raw, rule);
        if (monitor)
            return monitor;
    }
    return "";
}

// Hyprland creates a numbered workspace on demand, so ids up to minCount are real switch targets even before they exist
function hyprlandPersistentWorkspaces(raw, records, screenName, followFocus, minCount) {
    if (!(minCount > 0))
        return records;
    const perMonitor = !!screenName && !followFocus;
    const taken = new Set(records.map(ws => ws.id));
    // a just-created workspace has no monitor until quickshell's j/workspaces refresh lands; claiming it for another monitor drops its slot for a frame
    if (perMonitor)
        raw.workspaces.forEach(ws => ws.id > 0 && ws.monitor && ws.monitor.name !== screenName && taken.add(ws.id));
    const filled = records.slice();
    for (let id = 1; id <= minCount; id++) {
        if (taken.has(id))
            continue;
        if (perMonitor) {
            const bound = hyprlandBoundMonitor(raw, id);
            if (bound && bound !== screenName)
                continue;
        }
        filled.push(hyprlandRecord({
            id,
            name: String(id),
            monitor: {
                name: perMonitor ? screenName : ""
            }
        }));
    }
    return filled.sort(hyprlandOrder);
}

function hyprlandSpecialDisplayName(name) {
    return name.startsWith("special:") ? name.slice(8) : name;
}

// Hyprland >= 0.56 reports every special workspace with a null id, so specials only match by name
function hyprlandWorkspaceMatches(ws, record) {
    if (record.special !== true)
        return !!ws && hyprlandKey(ws) === hyprlandKey(record);
    const name = ws?.name ?? "";
    return hyprlandSpecialName(name) && hyprlandSpecialDisplayName(name) === record.name;
}

// Hyprland overlays a special workspace on the monitor's regular one, so active comes from the tracked overlay, not ws.active
function hyprlandSpecialWorkspaces(raw, screenName, followFocus, occupiedOnly) {
    const perMonitor = !!screenName && !followFocus;
    const visible = raw.visibleSpecials ?? {};
    const toplevels = raw.toplevels;
    const isVisible = normalized => perMonitor ? visible[screenName] === normalized : Object.values(visible).includes(normalized);
    const specials = raw.workspaces.filter(ws => hyprlandSpecial(ws) && (!perMonitor || ws.monitor?.name === screenName)).map(ws => {
        const name = ws.name ?? "";
        return {
            id: ws.id,
            idx: null,
            name: hyprlandSpecialDisplayName(name),
            output: ws.monitor?.name ?? "",
            active: isVisible(name === "special" ? "special:special" : name),
            placeholder: false,
            urgent: ws.urgent === true,
            special: true
        };
    }).filter(ws => !occupiedOnly || ws.active || toplevels.some(tl => hyprlandWorkspaceMatches(tl.workspace, ws))).sort((a, b) => a.name.localeCompare(b.name));
    // the default scratchpad is always offered so it can be opened before Hyprland has created it
    if (!specials.some(ws => ws.name === "special"))
        specials.push({
            id: null,
            idx: null,
            name: "special",
            output: screenName ?? "",
            active: isVisible("special:special"),
            placeholder: false,
            urgent: false,
            special: true
        });
    return specials;
}

function hyprlandWorkspacesForScreen(raw, screenName, followFocus, occupiedOnly, minCount, showSpecial) {
    const regular = hyprlandPersistentWorkspaces(raw, hyprlandListedWorkspaces(raw, screenName, followFocus, occupiedOnly), screenName, followFocus, minCount);
    if (!showSpecial)
        return regular;
    return regular.concat(hyprlandSpecialWorkspaces(raw, screenName, followFocus, occupiedOnly));
}

function hyprlandScrollWorkspaces(raw, screenName, followFocus) {
    const onScreen = !screenName || followFocus ? raw.workspaces : raw.workspaces.filter(ws => ws.lastIpcObject?.monitor === screenName);
    const numbered = onScreen.filter(ws => ws.id > -1).sort((a, b) => a.id - b.id);
    return (numbered.length > 0 ? numbered : [
            {
                id: 1,
                name: "1"
            }
        ]).map(hyprlandRecord);
}

function hyprlandScrollCurrentId(raw, screenName) {
    return raw.monitors.find(m => m.name === screenName)?.activeWorkspace?.id ?? 1;
}

function hyprlandVisibleSpecial(raw, monitorName) {
    const tracked = raw.visibleSpecials?.[monitorName];
    if (!tracked)
        return null;
    // the overlay event can land before the workspace list refresh, so the tracked name is the OSD's key
    const ws = raw.workspaces.find(ws => hyprlandSpecial(ws) && (ws.name === "special" ? "special:special" : ws.name) === tracked);
    return {
        id: ws?.id || tracked,
        idx: null,
        name: hyprlandSpecialDisplayName(tracked),
        output: monitorName,
        active: true,
        placeholder: false,
        special: true
    };
}

function hyprlandActiveWorkspace(raw, screenName) {
    const monitor = raw.monitors.find(m => !screenName || m.name === screenName);
    const ws = monitor?.activeWorkspace;
    if (!ws)
        return null;
    const special = hyprlandVisibleSpecial(raw, monitor.name ?? screenName);
    if (special)
        return special;
    const name = ws.name ?? "";
    if (hyprlandSpecialName(name))
        return null;
    return {
        id: ws.id,
        idx: ws.id > 0 ? ws.id : null,
        name: name !== "" && name !== String(ws.id) ? name : "",
        output: monitor?.name ?? screenName,
        active: true,
        placeholder: false
    };
}

function hyprlandWindowsOnWorkspace(windows, workspace, toplevels) {
    const workspaces = new Map();
    for (const toplevel of toplevels) {
        if (!workspaces.has(toplevel.wayland))
            workspaces.set(toplevel.wayland, toplevel.workspace);
    }
    return windows.filter(win => win && hyprlandWorkspaceMatches(workspaces.get(win), workspace));
}

function hyprlandWorkspaceOccupied(toplevels, workspace) {
    return toplevels.some(tl => hyprlandWorkspaceMatches(tl.workspace, workspace));
}

