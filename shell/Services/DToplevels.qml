pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Services

// Window source for the shell: wlr-foreign-toplevel-management where the
// compositor has it, the KWin bridge otherwise. Mirrors the two members of
// Quickshell's ToplevelManager that the shell reads.
Singleton {
    id: root

    readonly property var toplevels: CompositorService.isKwin ? KwinService.toplevelList : ToplevelManager.toplevels
    readonly property var activeToplevel: CompositorService.isKwin ? KwinService.activeToplevel : ToplevelManager.activeToplevel
}
