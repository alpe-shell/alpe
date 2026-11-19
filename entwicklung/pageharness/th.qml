import QtQuick
import Quickshell
import qs.Common
import qs.Services
import "pages"
// Gestalter im hyprlock-Modus (Mac): hyprlock.conf lesen, ändern, zurückschreiben.
Item {
    width: 900; height: 1400
    property string conf: "{\"general\":{\"ignoreEmptyInput\":true,\"hideCursor\":false},\"background\":{\"path\":\"/home/nutzer/Pictures/Hyprlock/wallpaper.jpg\",\"source\":\"image\",\"image\":\"/home/nutzer/Pictures/Hyprlock/wallpaper.jpg\",\"color\":\"#ff111111\",\"blurPasses\":3,\"blurSize\":7.0,\"noise\":0.0117,\"contrast\":0.8916,\"brightness\":0.7172,\"vibrancy\":0.1696,\"vibrancyDarkness\":0.0},\"widgets\":[{\"position\":[\"110\",\"250\"],\"monitor\":\"eDP-1\",\"halign\":\"center\",\"valign\":\"center\",\"zindex\":0,\"rotate\":0,\"opacity\":1.0,\"type\":\"image\",\"path\":\"/home/nutzer/Pictures/Hyprlock/logo.png\",\"size\":350.0,\"rounding\":-1.0,\"borderSize\":0.0,\"borderColor\":\"#66ffffff\",\"shadow\":{\"size\":0,\"passes\":0,\"color\":\"#ff000000\",\"boost\":1.2},\"order\":0},{\"position\":[\"990\",\"-650\"],\"monitor\":\"eDP-1\",\"halign\":\"center\",\"valign\":\"center\",\"zindex\":0,\"rotate\":0,\"opacity\":1.0,\"type\":\"image\",\"path\":\"/home/nutzer/Pictures/Hyprlock/bild1.png\",\"size\":350.0,\"rounding\":-10.0,\"borderSize\":0.0,\"borderColor\":\"#ffdddddd\",\"shadow\":{\"size\":0,\"passes\":0,\"color\":\"#ff000000\",\"boost\":1.2},\"order\":1},{\"position\":[\"-990\",\"-650\"],\"monitor\":\"eDP-1\",\"halign\":\"center\",\"valign\":\"center\",\"zindex\":0,\"rotate\":0,\"opacity\":1.0,\"type\":\"image\",\"path\":\"/home/nutzer/Pictures/Hyprlock/bild2.png\",\"size\":350.0,\"rounding\":-10.0,\"borderSize\":0.0,\"borderColor\":\"#ffdddddd\",\"shadow\":{\"size\":0,\"passes\":0,\"color\":\"#ff000000\",\"boost\":1.2},\"order\":2},{\"position\":[\"600\",\"450\"],\"monitor\":\"eDP-1\",\"halign\":\"center\",\"valign\":\"center\",\"zindex\":0,\"rotate\":0,\"opacity\":1.0,\"type\":\"image\",\"path\":\"/home/nutzer/Pictures/Hyprlock/bild3.png\",\"size\":350.0,\"rounding\":-10.0,\"borderSize\":0.0,\"borderColor\":\"#ffdddddd\",\"shadow\":{\"size\":0,\"passes\":0,\"color\":\"#ff000000\",\"boost\":1.2},\"order\":3},{\"position\":[\"-120\",\"200\"],\"monitor\":\"eDP-1\",\"halign\":\"center\",\"valign\":\"center\",\"zindex\":0,\"rotate\":0,\"opacity\":1.0,\"type\":\"image\",\"path\":\"/home/nutzer/Pictures/Hyprlock/bild4.png\",\"size\":450.0,\"rounding\":-10.0,\"borderSize\":0.0,\"borderColor\":\"#ffdddddd\",\"shadow\":{\"size\":0,\"passes\":0,\"color\":\"#ff000000\",\"boost\":1.2},\"order\":4},{\"position\":[\"-800\",\"450\"],\"monitor\":\"eDP-1\",\"halign\":\"center\",\"valign\":\"center\",\"zindex\":0,\"rotate\":0,\"opacity\":1.0,\"type\":\"image\",\"path\":\"/home/nutzer/Pictures/Hyprlock/bild5.png\",\"size\":550.0,\"rounding\":-10.0,\"borderSize\":0.0,\"borderColor\":\"#ffdddddd\",\"shadow\":{\"size\":0,\"passes\":0,\"color\":\"#ff000000\",\"boost\":1.2},\"order\":5},{\"position\":[\"0\",\"-350\"],\"monitor\":\"\",\"halign\":\"center\",\"valign\":\"top\",\"zindex\":5,\"rotate\":0,\"opacity\":1.0,\"type\":\"label\",\"text\":\"{date:%H}\",\"update\":1000,\"color\":\"#bfffffff\",\"fontSize\":150.0,\"font\":{\"family\":\"AlfaSlabOne\",\"weight\":400,\"italic\":false},\"align\":\"center\",\"shadow\":{\"size\":3.0,\"passes\":0,\"color\":\"#ff000000\",\"boost\":1.2},\"order\":6},{\"position\":[\"0\",\"-520\"],\"monitor\":\"eDP-1\",\"halign\":\"center\",\"valign\":\"top\",\"zindex\":5,\"rotate\":0,\"opacity\":1.0,\"type\":\"label\",\"text\":\"{date:%M}\",\"update\":1000,\"color\":\"#bfffffff\",\"fontSize\":150.0,\"font\":{\"family\":\"AlfaSlabOne\",\"weight\":400,\"italic\":false},\"align\":\"center\",\"shadow\":{\"size\":0,\"passes\":0,\"color\":\"#ff000000\",\"boost\":1.2},\"order\":7},{\"position\":[\"0\",\"20\"],\"monitor\":\"eDP-1\",\"halign\":\"center\",\"valign\":\"center\",\"zindex\":5,\"rotate\":0,\"opacity\":1.0,\"type\":\"label\",\"text\":\"{date:%A, %d. %B}\",\"update\":1000,\"color\":\"#ffffffff\",\"fontSize\":24.0,\"font\":{\"family\":\"JetBrains Mono Nerd Font Mono\",\"weight\":400,\"italic\":false},\"align\":\"center\",\"shadow\":{\"size\":0,\"passes\":0,\"color\":\"#ff000000\",\"boost\":1.2},\"order\":8},{\"position\":[\"0\",\"-40\"],\"monitor\":\"eDP-1\",\"halign\":\"center\",\"valign\":\"center\",\"zindex\":20,\"rotate\":0,\"opacity\":1.0,\"type\":\"input\",\"size\":[\"200\",\"50\"],\"outline\":1.0,\"outerColor\":\"#00ffffff\",\"innerColor\":\"#1affffff\",\"fontColor\":\"#ffc8c8c8\",\"fontFamily\":\"Sans\",\"checkColor\":\"#ffcc8822\",\"failColor\":\"#ffcc2222\",\"capslockColor\":\"\",\"dotsSize\":0.1,\"dotsSpacing\":1.0,\"dotsCenter\":true,\"dotsRounding\":-1,\"hideInput\":false,\"fadeOnEmpty\":false,\"rounding\":-1,\"placeholder\":\"Passwort...\",\"failText\":\"<i>{FAIL} <b>({ATTEMPTS})</b></i>\",\"failTimeout\":2000,\"order\":9}],\"reference\":{\"width\":2560,\"height\":1664}}"
    Component.onCompleted: {
        CompositorService.isKwin = false;
        Quickshell.shellDir = "/home/claude/src/alpe/entwicklung/pageharness/lockshell";
        Quickshell.environment = ({ "HOME": "/home/nutzer", "USER": "nutzer" });
        Proc.responder = (cmd, cb) => {
            const j = cmd.join(" ");
            if (j.indexOf("command -v hyprlock") >= 0) return Qt.callLater(() => cb("", 0));
            if (j.indexOf("--json") >= 0) return Qt.callLater(() => cb(conf, 0));
            Qt.callLater(() => cb("{\"ok\":true}", 0));
        };
        l.active = true;
    }
    Loader { id: l; active: false; width: 880; sourceComponent: AlpeLockDesignTab {} }
    Timer { interval: 600; running: true; onTriggered: {
        const p = l.item;
        console.log("Modus " + p.mode + " | Datei " + p.hyprConf + " | Elemente " + p.widgets.length + " | eigene " + p.custom);
        const i = p.widgets.findIndex(w => w.type === "label");
        Proc.calls = [];
        p.moveBy(i, 0, 50);
        p.save();
        const w = Proc.calls.find(c => c.indexOf("write") >= 0);
        console.log("schreibt: " + (w ? w.slice(3, 5).join(" ") + " … --locale " + w[w.indexOf("--locale") + 1] : "nichts"));
        const lay = JSON.parse(w[w.indexOf("write") + 2]);
        console.log("verschoben: " + JSON.stringify(lay.widgets[i].position));
        Qt.quit();
    } }
}
