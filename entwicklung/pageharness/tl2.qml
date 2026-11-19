import QtQuick
import Quickshell
import qs.Common
import "lockalpe"
// Prüft AlpeLockSurface (Sperre der Shell, Mac) mit einer PAM-Attrappe.
Rectangle {
    width: 2560; height: 1664; color: "black"
    property var pageItem: s
    QtObject {
        id: pam
        property string buffer: ""
        property string state: ""
        property bool unlockInProgress: false
        property bool responseSubmitted: false
        property var log: []
        signal unlockRequested
        function submitPassword() { log = log.concat([buffer]); if (buffer === "geheim") unlockRequested(); else { state = ""; state = "fail" } }
    }
    AlpeLockSurface { id: s; anchors.fill: parent; pam: pam; screenName: "eDP-1"; onUnlockRequested: console.log("ENTSPERRT") ; onPasswordEdited: t => {} }
    Component.onCompleted: SessionData.wallpaperPath = "/home/claude/harness/wall.png"
    Timer { interval: 600; running: true; onTriggered: {
        const v = s.children.find(c => c.hasOwnProperty("fieldIndex"));
        v.text = "falsch"; s.submit();
        console.log("falsch: Versuche " + s.attempts + " Meldung " + v.failMessage + " failing " + v.failing);
        v.text = "geheim"; s.submit();
        console.log("PAM bekam: " + pam.log.join(","));
    } }
}
