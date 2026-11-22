import QtCore
import QtQuick
import qs.Common
import qs.Services
import "../../../Common/ConfigIncludeResolve.js" as ConfigIncludeResolve

QtObject {
    id: root

    required property string includeKind
    property string procTag: includeKind + "-include"
    property bool autoCheck: true
    property string warningCategory: "hyprland-migration"
    property var status: defaultStatus()
    property bool checking: false
    property bool fixing: false

    readonly property bool compositorSupported: ConfigIncludeResolve.includeSpec(includeKind, CompositorService.compositor) !== null
    readonly property bool included: status.included === true
    readonly property bool readOnly: CompositorService.isHyprland && !HyprlandService.luaConfigActive
    readonly property string fragmentLabel: "alpe/" + includeKind

    signal fixed

    function defaultStatus() {
        return {
            "exists": false,
            "included": false
        };
    }

    function applyStatus(fragmentStatus) {
        if (!fragmentStatus)
            return;
        status = {
            "exists": fragmentStatus.exists,
            "included": fragmentStatus.included
        };
    }

    function configDir() {
        return Paths.strip(StandardPaths.writableLocation(StandardPaths.ConfigLocation));
    }

    function check() {
        const args = ConfigIncludeResolve.resolveIncludeArgs(includeKind, CompositorService.compositor);
        if (!args) {
            status = defaultStatus();
            return;
        }
        checking = true;
        Proc.runCommand("check-" + procTag, [Proc.backendBin, "config", "resolve-include", ...args], (output, exitCode) => {
            checking = false;
            if (exitCode !== 0) {
                status = defaultStatus();
                return;
            }
            try {
                status = JSON.parse(output.trim());
            } catch (e) {
                status = defaultStatus();
            }
        });
    }

    function showReadOnlyWarning() {
        ToastService.showWarning(I18n.tr("%1 not found").arg("hyprland.lua"), I18n.tr("Alpe writes these settings into the Lua configuration of Hyprland. Create %1 first, then open this page again.", "hyprland.lua missing warning, %1 is the path of hyprland.lua").arg("~/.config/hypr/hyprland.lua"), "", warningCategory);
    }

    function fix() {
        if (readOnly) {
            showReadOnlyWarning();
            return;
        }
        const compositor = CompositorService.compositor;
        const dir = configDir();
        const configName = "";
        const paths = ConfigIncludeResolve.includePaths(includeKind, compositor, dir, configName);
        if (!paths)
            return;
        const unixTime = Math.floor(Date.now() / 1000);
        const script = ConfigIncludeResolve.repairScriptFor(includeKind, compositor, dir, paths.configFile + ".backup" + unixTime, configName, Proc.backendBin);
        fixing = true;
        Proc.runCommand("fix-" + procTag, ["sh", "-c", script], (output, exitCode) => {
            fixing = false;
            if (exitCode !== 0)
                return;
            if (autoCheck)
                check();
            fixed();
        });
    }

    Component.onCompleted: {
        if (autoCheck && compositorSupported)
            check();
    }
}
