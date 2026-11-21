pragma Singleton

import Quickshell
import qs.DCommon.Common as DCommon

Singleton {
    readonly property int noTimeout: DCommon.Proc.noTimeout
    readonly property string dmsBin: DCommon.Proc.dmsBin
    // Plan 6.8: Den Neustart der Shell übernimmt die CLI «alpe restart» (startet alpe.service neu
    // bzw. die Instanz ohne systemd); alpe-dienst selbst startet nie eine Unit neu.
    readonly property var shellRestartCommand: ["alpe", "restart"]
    readonly property string shellUnit: "alpe.service"

    function runCommand(id, command, callback, debounceMs, timeoutMs, owner) {
        DCommon.Proc.runCommand(id, command, callback, debounceMs, timeoutMs, owner);
    }

    function release(id) {
        DCommon.Proc.release(id);
    }
}
