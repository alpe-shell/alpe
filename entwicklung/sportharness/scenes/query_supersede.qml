import QtQuick
import "../../../plugins/alpeSport"
// Zwei Anfragen kurz hintereinander: nur die zweite zaehlt, sie darf nicht verloren gehen.
Item {
    property var got: []
    SportQuery { id: q; onResult: (data, args) => got.push(args.join(" ")) }
    Component.onCompleted: { q.run(["league", "nl"]); q.run(["league", "ger.1"]) }
    Timer { interval: 1200; running: true; onTriggered: {
        if (got.length !== 1 || got[0] !== "league ger.1") console.error("Fehler: erhalten " + JSON.stringify(got));
        if (q.busy) console.error("Fehler: bleibt beschäftigt");
    } }
}
