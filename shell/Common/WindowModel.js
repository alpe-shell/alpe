.pragma library

function touchesEdge(position, positions, x, y, width, height, thickness, screenWidth, screenHeight) {
    switch (position) {
    case positions.top:
        return y < thickness;
    case positions.bottom:
        return y + height > screenHeight - thickness;
    case positions.left:
        return x < thickness;
    case positions.right:
        return x + width > screenWidth - thickness;
    default:
        return false;
    }
}

function sortedWindowFor(sortedToplevels, toplevel) {
    const exact = sortedToplevels.find(window => window === toplevel || window.wayland === toplevel || window.sourceToplevel === toplevel);
    if (exact)
        return exact;
    const titleMatches = sortedToplevels.filter(window => window.appId === toplevel.appId && window.title === toplevel.title);
    return titleMatches.length === 1 ? titleMatches[0] : null;
}

function hyprlandToplevelFor(hyprToplevels, toplevel) {
    for (const hyprToplevel of hyprToplevels) {
        if (hyprToplevel.wayland === toplevel)
            return hyprToplevel;
    }
    return null;
}

function hyprlandWindowPid(hyprToplevels, toplevel) {
    return hyprToplevels.find(t => t.wayland === toplevel)?.lastIpcObject?.pid || 0;
}

// Same identity as WorkspaceModel.hyprlandKey: Quickshell reports -1 for every named workspace on Hyprland 0.57
function hyprlandWorkspaceKey(ws) {
    return ws.id > 0 ? ws.id : ws.address || ws.name;
}

function hyprlandWindowOnActiveWorkspace(hyprToplevels, focusedWorkspace, toplevel) {
    if (!focusedWorkspace)
        return false;
    const hyprToplevel = hyprToplevels.find(t => t?.wayland === toplevel);
    if (!hyprToplevel || !hyprToplevel.workspace)
        return false;
    return hyprlandWorkspaceKey(hyprToplevel.workspace) === hyprlandWorkspaceKey(focusedWorkspace);
}

function hyprlandSpecialWorkspaceName(hyprToplevels, toplevel) {
    const hyprToplevel = hyprlandToplevelFor(hyprToplevels, toplevel);
    if (!hyprToplevel)
        return "";
    const wsName = String(hyprToplevel.lastIpcObject?.workspace?.name || hyprToplevel.workspace?.name || "");
    if (!wsName.startsWith("special:"))
        return "";
    return wsName.slice("special:".length);
}

function mangoWindowPid(windows, sortedWindow) {
    if (sortedWindow?.mangoWindowId === undefined)
        return 0;
    return windows.find(w => w.id === sortedWindow.mangoWindowId)?.pid || 0;
}

function mangoVisibleWindows(windows, output, screenName) {
    const active = new Set(output?.activeTags || []);
    return windows.filter(win => {
        if (!win || win.monitor !== screenName || win.is_minimized)
            return false;
        if (typeof win.is_visible === "boolean")
            return win.is_visible;
        return active.size === 0 || (win.tags || []).some(t => active.has(t));
    });
}

function mangoEdgeOverlap(windows, output, screenName, position, thickness, screenWidth, screenHeight, positions) {
    const monX = output?.x ?? 0;
    const monY = output?.y ?? 0;
    return mangoVisibleWindows(windows, output, screenName).some(win => touchesEdge(position, positions, (win.x ?? 0) - monX, (win.y ?? 0) - monY, win.width ?? 0, win.height ?? 0, thickness, screenWidth, screenHeight));
}

function mangoMaximizedOnScreen(windows, output, screenName) {
    return mangoVisibleWindows(windows, output, screenName).some(win => win.is_maximized || win.is_fullscreen);
}
