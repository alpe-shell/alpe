import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import "pages"
Rectangle {
    width: 820; height: 420; color: "#1e1e1e"
    property var pageItem: l.item
    Component.onCompleted: { Quickshell.environment = ({ "HOME": "/home/nutzer", "USER": "nutzer", "XDG_DATA_HOME": "/tmp/phdata" }); SessionData.wallpaperPath = "/home/claude/harness/wall.png" }
    Loader { id: l; x: 10; y: 10; width: 800; active: false; sourceComponent: AlpeLockDesignTab {} }
    Timer { interval: 50; running: true; onTriggered: { l.active = true; t2.start() } }
    Timer { id: t2; interval: 300; onTriggered: { Registry.answer("kreadconfig6", "Style=hyprlock\nLocale=de_CH\nLayout=\n"); l.item.selected = -1 } }
}
