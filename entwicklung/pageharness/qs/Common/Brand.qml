pragma Singleton

import Quickshell

// Alpe: Name, Version und Herkunft an einer Stelle. Einzige Quelle der Version (Plan 0.5 Nr. 2):
// Das Makefile in core/ liest «version» hieraus und gibt sie dem Dienst beim Bau mit,
// bootstrap.sh und tools/ lesen sie ebenfalls hier.
Singleton {
    readonly property string name: "Alpe"
    // App-ID, Desktop-Datei und Wayland-app_id (Plan 0.4 Nr. 2; im Dienst brand.AppID).
    readonly property string appId: "io.github.alpe_shell.Alpe"
    readonly property string version: "1.0"
    readonly property string codename: "Zugerberg"
    // Öffentliches Repository (Installation, Fehler melden)
    readonly property string url: "https://github.com/alpe-shell/alpe"
    readonly property string upstreamName: "Dux Modular Shell"
    // Stand des Ursprungsprojekts, auf dem Alpe aufbaut (Herkunft; Plugins beziehen sich mit «requires_alpe» auf «version»).
    readonly property string upstreamVersion: "2.1.2"
    readonly property string upstreamUrl: "https://github.com/duxlabs-dev/dux-shell"

    // Wartungsbefehl für die Systemaktualisierung; gibt es ihn, ersetzt er den Weg über den Dienst.
    readonly property string updateCommand: "update-all"
    // Die Systemprüfung des Ursprungsprojekts kennt KWin nicht und meldet dort Fehler, die keine sind.
    readonly property bool systemCheck: false
}
