import QtQuick
// Attrappe: liest statt des Hilfsprogramms eine Musterdatei aus ../../../fixtures oder, wenn shot.py
// die Kontext-Eigenschaft fixturesUrl setzt (ALPE_SPORT_FIXTURES), aus jenem Ordner.
QtObject {
    id: p
    property bool running: false
    property var command: []
    property QtObject stdout: null
    signal exited(int exitCode)
    onRunningChanged: {
        if (!running)
            return;
        const args = command.slice(1);
        let name = args[0] + ".json";
        if (args[0] === "league")
            name = "league-" + args[1] + ".json";
        else if (args[0] === "match")
            name = "match-" + args[1] + "-" + args[2] + ".json";
        else if (args[0] === "stats")
            name = "stats-" + args[1] + ".json";
        else if (args[0] === "player")
            name = "player-" + args[1] + ".json";
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            p.stdout.text = xhr.responseText || "{\"error\": \"Musterdatei fehlt: " + name + "\"}";
            p.running = false;
            p.stdout.streamFinished();
            p.exited(0);
        };
        const base = typeof fixturesUrl !== "undefined" ? fixturesUrl : Qt.resolvedUrl("../../../fixtures/");
        xhr.open("GET", base + name);
        xhr.send();
    }
}
