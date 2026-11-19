import QtQuick
import Quickshell
import qs.Common
import qs.Services

// Alpe: Zugang der KWin-Seiten (Fensterregeln, Fenster & Effekte, Tastenkürzel) zu
// scripts/alpe-kwin.py. Lesen liefert JSON, Schreiben geht über kwriteconfig6 bzw. kglobalaccel.
Item {
    id: backend

    readonly property string script: Quickshell.shellDir + "/scripts/alpe-kwin.py"
    property var state: null
    property bool loading: false
    property int serial: 0

    function run(args, callback) {
        serial += 1;
        const id = args[0] === "state" || args[0] === "shortcuts" ? "alpe-kwin-" + args[0] : "alpe-kwin-" + args[0] + "-" + serial;
        Proc.runCommand(id, ["python3", "-I", script].concat(args), (output, exitCode) => {
            let parsed = null;
            try {
                parsed = JSON.parse(output);
            } catch (e) {
                parsed = null;
            }
            if (callback)
                callback(parsed, exitCode);
        }, 0, args[0] === "pick" ? 130000 : 20000);
    }

    function refresh() {
        loading = true;
        run(["state"], result => {
            loading = false;
            if (result)
                state = result;
        });
    }

    // Einträge [datei, gruppe, schlüssel, wert]; wert null löscht.
    function apply(entries, then) {
        run(["apply", JSON.stringify(entries)], () => {
            if (then)
                then();
            else
                refresh();
        });
    }

    // Den KWin-Zustand nur unter KWin lesen; andere Befehle (Dienste) gehen überall.
    Component.onCompleted: if (CompositorService.isKwin) refresh()
}
