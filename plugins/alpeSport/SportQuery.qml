import QtQuick
import Quickshell.Io

// Ruft das Hilfsprogramm «sport» auf. Jede Anfrage bekommt einen eigenen Prozess; kommt eine neue,
// bevor die alte fertig ist, wird die alte beendet (nur die neueste zaehlt). Ein Waechter beendet
// Anfragen, die laenger als 45 s haengen, und meldet das als Fehler – die Oberflaeche bleibt nie
// im Zustand «wird geladen» stehen.
//
// Alpe: Vorher wartete eine zweite Anfrage, bis die erste fertig war, und ging verloren,
// wenn der Prozess beim Ende der Ausgabe noch als laufend galt («Spiele werden geladen …» blieb).
Item {
    id: root

    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("sport").toString().replace(/^file:\/\//, ""))
    property int timeoutMs: 45000
    property var active: null            // laufender Prozess
    property int serial: 0
    readonly property bool busy: active !== null

    signal result(var data, var args)

    visible: false

    function run(args) {
        if (active) {
            const old = active;
            active = null;
            old.cancelled = true;
            old.running = false;
            old.destroy(1000);
        }
        serial += 1;
        const proc = runner.createObject(root, {
            "args": args,
            "serial": serial
        });
        active = proc;
        proc.command = [root.helper].concat(args);
        proc.running = true;
        watchdog.restart();
    }

    function finish(proc, text) {
        if (proc.cancelled || proc !== active)
            return;
        active = null;
        watchdog.stop();
        let data = null;
        try {
            data = JSON.parse((text || "").trim());
        } catch (error) {
            data = {
                "error": "Das Sport-Hilfsprogramm hat keine gültige Antwort geliefert."
            };
        }
        root.result(data, proc.args);
        proc.destroy(1000);
    }

    Timer {
        id: watchdog

        interval: root.timeoutMs
        onTriggered: {
            const proc = root.active;
            if (!proc)
                return;
            root.active = null;
            proc.cancelled = true;
            proc.running = false;
            proc.destroy(1000);
            root.result({
                "error": "Zeitüberschreitung: Die Quelle hat nach " + Math.round(root.timeoutMs / 1000) + " s nicht geantwortet (Protokoll: ~/.cache/alpe/sport/log.txt)."
            }, proc.args);
        }
    }

    Component {
        id: runner

        Process {
            id: proc

            property var args: []
            property int serial: 0
            property bool cancelled: false
            property bool finished: false

            stdout: StdioCollector {
                onStreamFinished: {
                    proc.finished = true;
                    root.finish(proc, text);
                }
            }

            // Endet der Prozess ohne Ausgabe (z. B. python3 fehlt), trotzdem melden.
            onExited: exitCode => {
                if (!proc.finished)
                    Qt.callLater(() => {
                        if (!proc.finished)
                            root.finish(proc, "");
                    });
            }
        }
    }
}
