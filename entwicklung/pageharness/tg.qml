import QtQuick
import Quickshell
import qs.Common
import qs.Services
import "pages"
Item {
    width: 1280; height: 800
    GripsTest { id: g }
    function rows(item, out) { out = out || []; for (const c of item.children) { if (c.visible === false) continue; if (c.text !== undefined && c.text !== "" && c.font) out.push(c.text); rows(c, out); } return out; }
    Component.onCompleted: {
        KwinService._handleLine(JSON.stringify({payload: {data: [JSON.stringify({v: 1, seq: 1, current: "d1", activeOutput: "DP-2", active: "", desktops: [{id: "d1", name: "1", number: 1}], windows: [{id: "{a}", appId: "kitty", title: "~/alpe", output: "DP-2", desktops: ["d1"], maximized: true}], grips: [{id: "{a}", output: "DP-2", x: 100, y: 90, w: 900, h: 8, gx: 100, gy: 90}], snap: {output: "DP-2", x: 0, y: 44, w: 1564, h: 1265, kind: "left"}})]}, member: "state"}));
    }
    Timer { interval: 200; running: true; onTriggered: {
        console.log("Vorschau:", KwinService.snapPreview?.kind, "| Griffe:", KwinService.visibleGrips.length);
        g.menu = {id: "{a}", output: "DP-2", x: 300, y: 98};
        console.log("Menü:", rows(g).join(" | "));
        Quickshell.calls = [];
        KwinService.windowAction("{a}", "maximize");
        console.log("Befehl:", JSON.stringify(Quickshell.calls).indexOf("w.setMaximize(m,m)") > 0, JSON.stringify(Quickshell.calls).indexOf("var m=false") > 0);
        Qt.quit();
    } }
}
