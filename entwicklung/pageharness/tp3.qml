import QtQuick
import Quickshell
import qs.Common
import "pages"
Item {
    width: 900; height: 1200
    property var perf: ({ processes: [{ pid: 12, name: "Oberfläche (Quickshell)", pss: 312000, cpu: 1.4, threads: 31, exe: "/usr/bin/quickshell" }, { pid: 11, name: "Dienst (eigener Bau)", pss: 41000, cpu: 0.2, threads: 14, exe: "/home/nutzer/.local/lib/alpe/alpe" }],
        totalPss: 353000, memTotal: 16000000, memAvailable: 9000000, off: ["bluetooth"], parts: [], ownBackend: true })
    property var sv: ({ available: true, services: [{ Id: "dms.service", ActiveState: "active", own: false, dropins: [], UnitFileState: "enabled" },
        { Id: "plasma-plasmashell.service", ActiveState: "inactive", own: true, dropins: [], UnitFileState: "masked" },
        { Id: "app-arch\\x2dupdate\\x2dtray@autostart.service", Description: "Tray", ActiveState: "active", own: false, dropins: [], UnitFileState: "static" },
        { Id: "app-kitty@ba394d4fb82249daa0dd21770eb00120.service", ActiveState: "active", own: false, dropins: [], UnitFileState: "static" }] })
    Component.onCompleted: {
        Proc.responder = (cmd, cb) => {
            const out = cmd.join(" ").indexOf("alpe-perf.py") >= 0 ? (cmd.indexOf("off") >= 0 ? { off: [] } : perf) : (cmd[3] === "services" ? sv : {});
            Qt.callLater(() => cb(JSON.stringify(out), 0));
        };
        l.active = true; m.active = true;
    }
    Loader { id: l; active: false; width: 880; sourceComponent: AlpePerformanceTab {} }
    Loader { id: m; active: false; width: 880; sourceComponent: AlpeServicesTab {} }
    Timer { interval: 400; running: true; onTriggered: {
        const p = l.item;
        console.log("Leistung: " + p.info.processes.map(x => x.name + " " + p.mb(x.pss) + " " + x.cpu + "%").join(" | ") + " | zusammen " + p.mb(p.info.totalPss));
        Proc.calls = []; p.setPart("wellbeing", true);
        console.log("Teil aus: " + JSON.stringify(Proc.calls[0].slice(3)) + " | Neustart nötig " + p.restartNeeded);
        const s = m.item;
        console.log("Dienste: eigene " + s.own.length + " maskiert " + s.masked.map(x => s.pretty(x.Id)) + " | weitere " + s.others.map(x => s.pretty(x.Id)));
        Proc.calls = []; s.journal("dms.service");
        console.log("Protokoll: " + JSON.stringify(Quickshell.calls[Quickshell.calls.length - 1]));
        Qt.quit();
    } }
}
