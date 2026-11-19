import QtQuick
QtObject {
    property bool busy: false
    property bool unlocked: false
    property string promptForSecret: ""
    property string errorMessage: ""
    property string infoMessage: ""
    property bool promptReady: false
    property string correct: "geheim"
    property var log: []
    signal succeeded
    signal failed(int kind)
    function startAuthenticating() { log = log.concat(["start"]) }
    function stopAuthenticating() { log = log.concat(["stop"]) }
    function respond(r) {
        if (!promptReady) { log = log.concat(["respond-ohne-abfrage"]); return; }
        promptReady = false;
        log = log.concat(["respond " + r]);
        if (r === correct) { unlocked = true; succeeded(); } else failed(0);
    }
    function prompt() { promptReady = true; promptForSecret = "Passwort:"; promptForSecretChanged(); }
}
