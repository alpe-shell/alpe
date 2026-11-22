pragma Singleton

import Quickshell
import qs.Alpe.Common as Alpe

Singleton {
    readonly property int noTimeout: Alpe.Proc.noTimeout
    readonly property string dmsBin: Alpe.Proc.dmsBin
    // Plan 6.8: Den Neustart der Shell übernimmt die CLI «alpe restart» (startet alpe.service neu
    // bzw. die Instanz ohne systemd); alpe-dienst selbst startet nie eine Unit neu.
    readonly property var shellRestartCommand: ["alpe", "restart"]
    readonly property string shellUnit: "alpe.service"

    function runCommand(id, command, callback, debounceMs, timeoutMs, owner) {
        Alpe.Proc.runCommand(id, command, callback, debounceMs, timeoutMs, owner);
    }

    function release(id) {
        Alpe.Proc.release(id);
    }
}
