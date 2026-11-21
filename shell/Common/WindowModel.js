.pragma library

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

