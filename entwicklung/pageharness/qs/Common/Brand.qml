pragma Singleton

import Quickshell

// Alpe: Name, Version und Herkunft an einer Stelle. Alles Sichtbare liest von hier;
// VERSION und CODENAME bleiben die des Ursprungsprojekts, weil Plugins und die
// Aktualisierungsprüfung sich auf dessen Versionsnummern beziehen.
Singleton {
    readonly property string name: "Alpe"
    readonly property string version: "1.3"
    readonly property string codename: "Zugerberg"
    readonly property string upstreamName: "Dux Modular Shell"
    readonly property string upstreamVersion: "2.1.2"
    readonly property string upstreamUrl: "https://github.com/duxlabs-dev/dux-shell"

    // Wartungsbefehl für die Systemaktualisierung; gibt es ihn, ersetzt er den Weg über den Dienst.
    readonly property string updateCommand: "update-all"
    // Pakete, die nie als Aktualisierung erscheinen: der Unterbau ist bewusst festgehalten.
    readonly property var heldPackages: ["dux-shell", "dms", "dms-cli"]
    // Die Systemprüfung des Ursprungsprojekts kennt KWin nicht und meldet dort Fehler, die keine sind.
    readonly property bool systemCheck: false
    // Willkommensgruss beim ersten Start und Versionshinweise des Ursprungsprojekts
    readonly property bool welcome: false

}
