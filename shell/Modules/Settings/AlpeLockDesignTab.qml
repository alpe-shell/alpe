pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Modals.FileBrowser
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets

// Alpe: Sperrbildschirm gestalten. Die Vorschau ist der echte Sperrbildschirm: Die Seite lädt
// Modules/Lock/Alpe/HyprlockView.qml (dieselbe Ansicht nutzen KDE-Design und Shell-Sperre) und
// schaltet dort den Bearbeitungsmodus ein. Elemente anklicken, ziehen, mit dem Mausrad
// vergrössern; Feinheiten in den Karten darunter. Gespeichert wird das Layout als JSON: unter
// KWin in kscreenlockerrc ([Greeter][LnF][General] Layout) für den KDE-Sperrbildschirm, sonst
// (Alpe, Hyprland) in den Einstellungen der Shell (alpeLockLayout) für ihre eigene Sperre.
Item {
    id: root

    property var parentModal: null

    readonly property string home: Quickshell.env("HOME")
    readonly property string lockDir: Quickshell.shellDir + "/Modules/Lock/Alpe"
    readonly property string toolsDir: home + "/alpe/tools"
    readonly property bool kde: CompositorService.isKwin
    // Alpe: Unter Hyprland mit hyprlock gestaltet die Seite die hyprlock.conf selbst.
    property bool hyprlockFound: false
    readonly property string hyprConf: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/hypr/hyprlock.conf"
    readonly property string hyprScript: Quickshell.shellDir + "/scripts/alpe-hyprlock.py"
    readonly property string mode: kde ? "kde" : SettingsData.alpeLockStyle === "standard" ? "standard" : SettingsData.alpeLockStyle === "alpe" ? "shell" : (hyprlockFound ? "hyprlock" : "shell")
    readonly property bool hyprMode: mode === "hyprlock"

    // Arbeitskopie des Layouts und Zustand
    property var layout: null
    property bool custom: false
    property bool configRead: false
    property string storedLayout: ""
    property string lockStyle: ""
    property string localeName: ""
    property int selected: -1
    property var history: []
    property string mergeKey: ""
    property real mergeTime: 0
    property string notice: ""

    readonly property bool installed: preview.status === Loader.Ready
    readonly property var defaults: installed ? preview.item.defaultLayout : null
    readonly property var widgets: layout && layout.widgets ? layout.widgets : []
    readonly property var sel: selected >= 0 && selected < widgets.length ? widgets[selected] : null
    readonly property var bg: layout && layout.background ? layout.background : ({})
    readonly property var ref: layout && layout.reference ? layout.reference : ({ "width": 2560, "height": 1664 })
    readonly property string desktopImage: {
        const first = Quickshell.screens[0]?.name ?? "";
        const path = String(first !== "" ? SessionData.getMonitorWallpaperImage(first) : VideoWallpaperService.imageFor(SessionData.wallpaperPath || ""));
        return VideoWallpaperService.isVideo(path) ? "" : path.replace(/^file:\/\//, "");
    }

    // ---------------------------------------------------------------- Laden und Speichern

    function clone(value) {
        return JSON.parse(JSON.stringify(value));
    }

    function tryInit() {
        if (layout !== null || !configRead || !installed)
            return;
        let parsed = null;
        if (storedLayout !== "") {
            try {
                parsed = JSON.parse(storedLayout);
            } catch (e) {
                parsed = null;
                notice = "Das gespeicherte Layout war beschädigt; angezeigt wird die Vorlage.";
            }
        }
        custom = !!(parsed && parsed.widgets);
        layout = normalize(custom ? parsed : clone(defaults));
    }

    // Fehlende Felder ergänzen, damit die Karten immer etwas zum Anzeigen haben.
    function normalize(l) {
        l.reference = l.reference || { "width": 2560, "height": 1664 };
        l.background = l.background || {};
        if (l.background.blurRadius === undefined) {
            const b = l.background;
            l.background.blurRadius = b.blurPasses > 0 ? Math.round((b.blurSize || 7) * Math.pow(2, b.blurPasses) * 3) : 0;
        }
        for (const k of [["brightness", 0.8172], ["contrast", 0.8917], ["vibrancy", 0.1696]])
            if (l.background[k[0]] === undefined)
                l.background[k[0]] = k[1];
        l.general = l.general || { "ignoreEmptyInput": true };
        l.widgets = l.widgets || [];
        return l;
    }

    // Jede Änderung geht hierdurch: Stand für «Rückgängig» merken, übernehmen, verzögert speichern.
    // Gleichartige Änderungen kurz hintereinander (Schieberegler, Mausrad) zählen als eine.
    function commit(next, key) {
        const now = Date.now();
        if (!(key && key === mergeKey && now - mergeTime < 1200))
            history = history.concat([JSON.stringify(layout)]).slice(-60);
        mergeKey = key || "";
        mergeTime = now;
        layout = next;
        saveTimer.restart();
    }

    function edit(fn, key) {
        if (!layout)
            return;
        const next = clone(layout);
        fn(next);
        commit(next, key);
    }

    function editAt(index, fn, key) {
        edit(l => {
            if (index >= 0 && index < l.widgets.length)
                fn(l.widgets[index]);
        }, key ? key + ":" + index : "");
    }

    function editSel(fn, key) {
        editAt(selected, fn, key);
    }

    function undo() {
        if (history.length === 0)
            return;
        const last = history[history.length - 1];
        history = history.slice(0, -1);
        mergeKey = "";
        layout = JSON.parse(last);
        if (selected >= widgets.length)
            selected = -1;
        saveTimer.restart();
    }

    Timer {
        id: saveTimer
        interval: 500
        onTriggered: root.save()
    }

    // Unter KWin in kscreenlockerrc, sonst in die Einstellungen der Shell.
    function lnf(key, value) {
        if (hyprMode && key === "Locale") {
            SettingsData.set("alpeLockLocale", String(value));
            saveTimer.restart();
            return;
        }
        if (hyprMode && key === "Layout") {
            // Zurück zur Vorlage: hyprlock.conf aus der Vorlage neu schreiben.
            if (value === "" && defaults)
                Qt.callLater(() => root.save());
            return;
        }
        if (!kde) {
            const map = { "Layout": "alpeLockLayout", "Locale": "alpeLockLocale", "Style": "alpeLockStyle" };
            if (map[key])
                SettingsData.set(map[key], key === "Style" ? (value === "hyprlock" ? "alpe" : "standard") : String(value));
            return;
        }
        if (value === "")
            Quickshell.execDetached(["kwriteconfig6", "--file", "kscreenlockerrc", "--group", "Greeter", "--group", "LnF", "--group", "General", "--key", key, "--delete"]);
        else
            Quickshell.execDetached(["kwriteconfig6", "--file", "kscreenlockerrc", "--group", "Greeter", "--group", "LnF", "--group", "General", "--key", key, String(value)]);
    }

    function save() {
        if (!layout)
            return;
        if (hyprMode) {
            Proc.runCommand("alpe-hyprlock-write", ["python3", "-I", hyprScript, "write", hyprConf, JSON.stringify(layout), "--locale", localeName, "--wallpaper", desktopImage], (out, code) => {
                if (code !== 0)
                    root.notice = "hyprlock.conf liess sich nicht schreiben (" + code + ").";
            }, 0, 15000);
            custom = true;
            return;
        }
        lnf("Layout", JSON.stringify(layout));
        custom = true;
    }

    function resetToTemplate() {
        if (!defaults)
            return;
        commit(normalize(clone(defaults)), "");
        saveTimer.stop();
        lnf("Layout", "");
        custom = false;
        selected = -1;
    }

    Component.onCompleted: {
        if (kde)
            return;
        lockStyle = SettingsData.alpeLockStyle === "standard" ? "standard" : "hyprlock";
        localeName = SettingsData.alpeLockLocale || "";
        Proc.runCommand("alpe-hyprlock-probe", ["sh", "-c", "command -v hyprlock >/dev/null"], (out, code) => {
            root.hyprlockFound = code === 0;
            if (root.hyprMode)
                root.readHyprlock();
            else {
                root.storedLayout = SettingsData.alpeLockLayout || "";
                root.configRead = true;
                root.tryInit();
            }
        }, 0, 5000);
    }

    // hyprlock.conf einlesen; fehlt sie, gilt die Vorlage.
    function readHyprlock() {
        Proc.runCommand("alpe-hyprlock-read", ["sh", "-c", '[ -f "$1" ] || exit 3; python3 -I "$2" "$1" --json', "sh", hyprConf, hyprScript], (out, code) => {
            root.storedLayout = code === 0 ? String(out).trim() : "";
            root.configRead = true;
            root.tryInit();
        }, 0, 10000);
    }

    Process {
        id: reader
        running: root.kde
        command: ["sh", "-c", 'command -v kreadconfig6 >/dev/null 2>&1 || exit 0; for k in Style Locale Layout; do printf "%s=%s\\n" "$k" "$(kreadconfig6 --file kscreenlockerrc --group Greeter --group LnF --group General --key "$k")"; done']
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    const cut = line.indexOf("=");
                    if (cut < 0)
                        continue;
                    const value = line.slice(cut + 1);
                    switch (line.slice(0, cut)) {
                    case "Style":
                        root.lockStyle = value.trim();
                        break;
                    case "Locale":
                        root.localeName = value.trim();
                        break;
                    case "Layout":
                        root.storedLayout = value.trim();
                        break;
                    }
                }
                root.configRead = true;
                root.tryInit();
            }
        }
    }

    // hyprlock.conf übernehmen: tools/hyprlock2qml.py --json
    Process {
        id: importer
        property string path: ""
        command: ["python3", "-I", root.toolsDir + "/hyprlock2qml.py", path, "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text);
                    root.commit(root.normalize(parsed), "");
                    root.selected = -1;
                    root.notice = "hyprlock.conf übernommen. «Rückgängig» holt das vorherige Layout zurück.";
                } catch (e) {
                    root.notice = "Die Datei liess sich nicht umsetzen (braucht ~/alpe/tools/hyprlock2qml.py und python3).";
                }
            }
        }
    }

    // ---------------------------------------------------------------- Bausteine

    function typeName(w) {
        if (!w)
            return "";
        if (w.type === "input")
            return "Passwortfeld";
        if (w.type === "image")
            return "Bild";
        if (w.type === "shape")
            return "Fläche";
        return "Text";
    }

    function describe(w) {
        if (w.type === "image")
            return String(w.path || "").split("/").pop() || "kein Bild gewählt";
        if (w.type === "input")
            return plain(w.placeholder || "");
        if (w.type === "shape")
            return Math.round(parseFloat(w.size[0])) + " × " + Math.round(parseFloat(w.size[1]));
        return friendly(w);
    }

    function plain(t) {
        return String(t).replace(/<[^>]*>/g, "");
    }

    // Text eines Labels so, wie man ihn eingibt: strftime-Platzhalter und $USER.
    function friendly(w) {
        if (!w)
            return "";
        if (w.format !== undefined)
            return String(w.format);
        return String(w.text || "").replace(/\{date:([^}]*)\}/g, "$1").replace(/\{USER\}/g, "$USER");
    }

    readonly property var presets: [["Stunden", "%H"], ["Minuten", "%M"], ["Uhrzeit", "%H:%M"], ["Datum", "%A, %d. %B"], ["Datum kurz", "%d.%m.%Y"], ["Wochentag", "%A"], ["Begrüssung", "Hallo $USER"]]

    function addLabel() {
        edit(l => l.widgets.push({
                "type": "label", "format": "Hallo $USER", "position": ["0", "300"], "halign": "center", "valign": "center",
                "zindex": 5, "rotate": 0, "opacity": 1, "color": "#ffffffff", "fontSize": 24,
                "font": { "family": "JetBrains Mono", "weight": 400, "italic": false }, "align": "center",
                "shadow": { "size": 3, "passes": 0, "color": "#ff000000", "boost": 1.2 }
            }), "");
        selected = widgets.length - 1;
    }

    function addImage(path) {
        edit(l => l.widgets.push({
                "type": "image", "path": path, "position": ["0", "0"], "halign": "center", "valign": "center",
                "zindex": 0, "rotate": 0, "opacity": 1, "size": 350, "rounding": 0, "borderSize": 0,
                "borderColor": "#66ffffff", "shadow": { "size": 0, "passes": 0, "color": "#ff000000", "boost": 1.2 }
            }), "");
        selected = widgets.length - 1;
    }

    function removeSelected() {
        if (!sel || sel.type === "input")
            return;
        const index = selected;
        selected = -1;
        edit(l => l.widgets.splice(index, 1), "");
    }

    function duplicateSelected() {
        if (!sel || sel.type === "input")
            return;
        const copy = clone(sel);
        copy.position = [String(Math.round(num(copy.position[0], ref.width) + 40)), String(Math.round(num(copy.position[1], ref.height) - 40))];
        edit(l => l.widgets.push(copy), "");
        selected = widgets.length - 1;
    }

    // Ebene: höher oder tiefer als das nächste Element darüber/darunter.
    function restack(delta) {
        editSel(w => w.zindex = (w.zindex || 0) + delta, "z");
    }

    // Position: Prozent in Bezugspixel umrechnen, dann rechnen.
    function num(value, axis) {
        const text = String(value);
        if (text.endsWith("%"))
            return parseFloat(text) / 100 * axis;
        const n = parseFloat(text);
        return isNaN(n) ? 0 : n;
    }

    function moveBy(index, dx, dy) {
        if (index < 0) {
            // Kein Passwortfeld im Layout: das gezeichnete Ersatzfeld wird beim Ziehen zum echten.
            const f = clone(preview.item.fallbackField);
            f.position = [String(Math.round(num(f.position[0], ref.width) + dx)), String(Math.round(num(f.position[1], ref.height) + dy))];
            edit(l => l.widgets.push(f), "");
            selected = widgets.length - 1;
            return;
        }
        editAt(index, w => w.position = [String(Math.round(num(w.position[0], ref.width) + dx)), String(Math.round(num(w.position[1], ref.height) + dy))], "");
    }

    function resizeBy(index, steps) {
        const f = steps > 0 ? 1.06 : 1 / 1.06;
        editAt(index, w => {
            if (w.type === "label")
                w.fontSize = Math.max(4, Math.round(w.fontSize * f * 10) / 10);
            else if (w.type === "image")
                w.size = Math.max(10, Math.round(w.size * f));
            else
                w.size = [String(Math.max(10, Math.round(num(w.size[0], ref.width) * f))), String(Math.max(6, Math.round(num(w.size[1], ref.height) * f)))];
        }, "wheel");
    }

    // ---------------------------------------------------------------- Farben (#AARRGGBB)

    function hex2(n) {
        const s = Math.round(Math.max(0, Math.min(255, n))).toString(16);
        return s.length < 2 ? "0" + s : s;
    }

    function argb(c, alpha) {
        return "#" + hex2(alpha * 255) + hex2(c.r * 255) + hex2(c.g * 255) + hex2(c.b * 255);
    }

    function alphaOf(value) {
        return Qt.color(value || "#ffffffff").a;
    }

    function withAlpha(value, alpha) {
        return argb(Qt.color(value || "#ffffffff"), alpha);
    }

    // Farbwahl über den Farbdialog der Shell; die Deckkraft bleibt.
    function pickColor(current, title, apply) {
        const modal = PopoutService.colorPickerModal;
        if (!modal)
            return;
        const keep = alphaOf(current);
        modal.selectedColor = Qt.color(current || "#ffffffff");
        modal.pickerTitle = title;
        modal.onColorSelectedCallback = function (picked) {
            apply(argb(picked, keep));
        };
        modal.show(true);
    }

    readonly property var weights: [[100, "Dünn"], [200, "Extraleicht"], [300, "Leicht"], [400, "Normal"], [500, "Mittel"], [600, "Halbfett"], [700, "Fett"], [800, "Extrafett"], [900, "Schwarz"]]
    readonly property var weightNames: weights.map(w => w[1])
    function weightName(value) {
        let best = weights[3];
        for (const w of weights)
            if (Math.abs(w[0] - value) < Math.abs(best[0] - value))
                best = w;
        return best[1];
    }

    // Schriften: die beiden mitgelieferten zuerst, dann alles, was installiert ist.
    readonly property var fontOptions: {
        const own = ["Alfa Slab One", "JetBrains Mono"];
        return own.concat(Qt.fontFamilies().filter(f => own.indexOf(f) < 0 && !f.startsWith(".")));
    }

    readonly property var localeValues: ["", "de_CH", "en_US", "fr_CH", "it_CH"]
    readonly property var localeOptions: ["Sprache des Systems", "Deutsch", "English", "Français", "Italiano"]

    // ---------------------------------------------------------------- Dateiwahl

    FileBrowserModal {
        id: imageBrowser
        parentModal: root.parentModal
        browserTitle: "Bild für den Sperrbildschirm"
        bucket: "alpe-lock"
        filters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.svg", "*.gif"]
        property bool replace: false
        property bool background: false
        onAccepted: paths => {
            if (paths.length === 0)
                return;
            if (background)
                root.edit(l => {
                    l.background.source = "image";
                    l.background.image = paths[0];
                }, "");
            else if (replace && root.sel && root.sel.type === "image")
                root.editSel(w => w.path = paths[0], "");
            else
                root.addImage(paths[0]);
        }
    }

    FileBrowserModal {
        id: confBrowser
        parentModal: root.parentModal
        browserTitle: "hyprlock.conf übernehmen"
        bucket: "alpe-hyprlock"
        filters: ["*.conf", "*"]
        onAccepted: paths => {
            if (paths.length === 0)
                return;
            importer.path = paths[0];
            importer.running = true;
        }
    }

    FontLoader {
        source: "file://" + root.lockDir + "/fonts/AlfaSlabOne-Regular.ttf"
        id: slabFont
    }
    FontLoader { source: "file://" + root.lockDir + "/fonts/JetBrainsMono-Regular.ttf" }
    FontLoader { source: "file://" + root.lockDir + "/fonts/JetBrainsMono-ExtraBold.ttf" }

    // ---------------------------------------------------------------- Seite

    SettingsPage {
        SettingsCard {
            width: parent.width
            iconName: "preview"
            title: "Vorschau"
            settingKey: "alpeLockPreview"
            tags: ["sperrbildschirm", "lockscreen", "layout", "hyprlock", "gestalten"]

            SettingsNoteRow {
                visible: preview.status === Loader.Error
                text: "Die Ansicht fehlt im Shell-Code (Modules/Lock/Alpe). «bash ~/alpe/install.sh» spielt sie ein."
            }

            SettingsRow {
                visible: root.installed && root.lockStyle !== "" && root.lockStyle !== "hyprlock"
                title: "Gerade ist ein anderer Stil eingestellt"
                subtitle: root.kde ? "Was du hier gestaltest, erscheint erst mit dem Stil «Eigenes Layout»." : "Die Shell sperrt gerade mit dem Sperrbildschirm des Ursprungsprojekts."
                iconName: "info"

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Eigenes Layout verwenden"
                    variant: "tonal"
                    onClicked: {
                        root.lnf("Style", "hyprlock");
                        root.lockStyle = "hyprlock";
                    }
                }
            }

            // Die Bühne hat das Seitenverhältnis des ersten Bildschirms; darin liegt der
            // Sperrbildschirm in voller Auflösung, verkleinert gezeichnet.
            Item {
                id: stage
                visible: root.installed
                width: parent.width
                readonly property var screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
                readonly property real screenW: screen ? screen.width : 2560
                readonly property real screenH: screen ? screen.height : 1440
                height: Math.round(width * screenH / screenW)
                clip: true

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.cornerRadius
                    color: "#000000"
                }

                // Klick ins Leere hebt die Auswahl auf.
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.selected = -1
                }

                Item {
                    id: canvas
                    width: stage.screenW
                    height: stage.screenH
                    scale: stage.width / stage.screenW
                    transformOrigin: Item.TopLeft

                    // Eigenes Bild oder das Desktop-Bild; bei Video dessen Standbild.
                    readonly property string wall: root.bg.source === "image" ? String(root.bg.image || "") : root.desktopImage
                    readonly property real blurPx: (root.bg.blurRadius || 0) * (preview.item ? preview.item.unit : 1)

                    Rectangle {
                        anchors.fill: parent
                        color: canvas.wall.startsWith("#") ? canvas.wall : "#1b2330"
                    }

                    Image {
                        id: wallImage
                        anchors.fill: parent
                        visible: false
                        source: canvas.wall !== "" && !canvas.wall.startsWith("#") ? "file://" + canvas.wall.replace(/^file:\/\//, "") : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 1920
                        asynchronous: true
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: wallImage
                        visible: wallImage.status === Image.Ready
                        autoPaddingEnabled: false
                        blurEnabled: canvas.blurPx > 0
                        blurMax: 64
                        blur: Math.min(1, canvas.blurPx / 64)
                        blurMultiplier: Math.max(0, canvas.blurPx / 64 - 1)
                        saturation: root.bg.vibrancy || 0
                        contrast: (root.bg.contrast || 1) - 1
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, Math.max(0, Math.min(1, 1 - (root.bg.brightness === undefined ? 1 : root.bg.brightness))))
                    }

                    Loader {
                        id: preview
                        anchors.fill: parent
                        source: "file://" + root.lockDir + "/HyprlockView.qml"
                        onStatusChanged: root.tryInit()
                    }

                    Binding { target: preview.item; property: "custom"; value: root.layout; when: root.installed && root.layout !== null }
                    Binding { target: preview.item; property: "editing"; value: true; when: root.installed }
                    Binding { target: preview.item; property: "selected"; value: root.selected; when: root.installed }
                    Binding { target: preview.item; property: "editScale"; value: 1 / Math.max(0.05, canvas.scale); when: root.installed }
                    Binding { target: preview.item; property: "localeName"; value: root.localeName; when: root.installed }
                    Binding { target: preview.item; property: "userName"; value: Quickshell.env("USER") || ""; when: root.installed }
                    Binding { target: preview.item; property: "fallbackSans"; value: Theme.fontFamily || "Noto Sans"; when: root.installed }
                    Binding { target: preview.item; property: "slabFamily"; value: slabFont.status === FontLoader.Ready ? slabFont.font.family : ""; when: root.installed }

                    Timer {
                        interval: 1000
                        repeat: true
                        running: root.installed && root.visible
                        onTriggered: preview.item.now = new Date()
                    }

                    Connections {
                        target: root.installed ? preview.item : null
                        function onPicked(index) {
                            root.selected = index;
                        }
                        function onMoved(index, dx, dy) {
                            root.moveBy(index, dx, dy);
                        }
                        function onResized(index, steps) {
                            root.resizeBy(index, steps);
                        }
                    }
                }
            }

            SettingsRow {
                visible: root.installed
                title: root.hyprMode ? "hyprlock: " + root.hyprConf.replace(root.home, "~") : root.custom ? "Eigenes Layout" : "Vorlage: hyprlock.conf des MacBooks"
                subtitle: root.notice !== "" ? root.notice : "Element anklicken und ziehen, Mausrad ändert die Grösse. Gilt ab dem nächsten Sperren."
                iconName: "touch_app"
            }

            Flow {
                visible: root.installed
                width: parent.width
                spacing: Theme.spacingS

                DButton {
                    text: "Text"
                    iconName: "title"
                    variant: "tonal"
                    onClicked: root.addLabel()
                }
                DButton {
                    text: "Bild"
                    iconName: "add_photo_alternate"
                    variant: "tonal"
                    onClicked: {
                        imageBrowser.replace = false;
                        imageBrowser.background = false;
                        imageBrowser.open();
                    }
                }
                DButton {
                    text: "Rückgängig"
                    iconName: "undo"
                    variant: "text"
                    enabled: root.history.length > 0
                    onClicked: root.undo()
                }
                DButton {
                    text: "Vorlage"
                    iconName: "restart_alt"
                    variant: "text"
                    onClicked: root.resetToTemplate()
                }
                DButton {
                    text: "hyprlock.conf übernehmen"
                    iconName: "file_open"
                    variant: "text"
                    onClicked: confBrowser.open()
                }
                DButton {
                    text: root.kde ? "Echt ansehen" : "Jetzt sperren"
                    iconName: root.kde ? "visibility" : "lock"
                    variant: "text"
                    onClicked: {
                        root.save();
                        if (root.kde)
                            Quickshell.execDetached(["bash", Quickshell.shellDir + "/scripts/alpe-lockcheck.sh", "test", "org.alpe.desktop"]);
                        else
                            Qt.callLater(() => Quickshell.execDetached(root.hyprMode ? ["sh", "-c", "sleep 0.8; pidof hyprlock >/dev/null || hyprlock"] : [Proc.dmsBin, "ipc", "call", "lock", "lock"]));
                    }
                }
            }
        }

        // ---------------------------------------------------------- Elemente
        SettingsCard {
            width: parent.width
            visible: root.installed && root.layout !== null
            iconName: "layers"
            title: "Elemente"
            settingKey: "alpeLockElements"

            Repeater {
                model: root.widgets

                SettingsRow {
                    required property var modelData
                    required property int index
                    width: parent ? parent.width : 0
                    title: root.typeName(modelData)
                    subtitle: root.describe(modelData)
                    iconName: modelData.type === "image" ? "image" : modelData.type === "input" ? "password" : modelData.type === "shape" ? "rectangle" : "text_fields"
                    trailingBadge: "Ebene " + (modelData.zindex || 0)
                    clickable: true
                    active: root.selected === index
                    onClicked: root.selected = index
                }
            }
        }

        // ---------------------------------------------------------- Ausgewähltes Element
        SettingsCard {
            width: parent.width
            visible: root.sel !== null
            iconName: "tune"
            title: root.sel ? root.typeName(root.sel) : ""
            settingKey: "alpeLockElement"

            // --- Text
            SettingsTextFieldRow {
                visible: root.sel && root.sel.type === "label"
                text: "Inhalt"
                description: "%H Stunde · %M Minute · %A Wochentag · %d Tag · %B Monat · %Y Jahr · $USER Name; <b>fett</b>, <i>kursiv</i>"
                value: root.friendly(root.sel)
                onEditingFinished: value => {
                    if (value !== root.friendly(root.sel))
                        root.editSel(w => {
                            w.format = value;
                            delete w.text;
                        }, "");
                }
            }

            SettingsDropdownRow {
                visible: root.sel && root.sel.type === "label"
                text: "Vorlage für den Inhalt"
                options: root.presets.map(p => p[0])
                currentValue: {
                    const f = root.friendly(root.sel);
                    const hit = root.presets.find(p => p[1] === f);
                    return hit ? hit[0] : "";
                }
                emptyText: "Eigener Text"
                onValueChanged: value => {
                    const hit = root.presets.find(p => p[0] === value);
                    if (hit)
                        root.editSel(w => {
                            w.format = hit[1];
                            delete w.text;
                        }, "");
                }
            }

            SettingsDropdownRow {
                visible: root.sel && root.sel.type === "label"
                text: "Schrift"
                enableFuzzySearch: true
                options: root.fontOptions
                currentValue: root.sel && root.sel.font ? root.sel.font.family : ""
                onValueChanged: value => root.editSel(w => {
                        w.font = w.font || {};
                        w.font.family = value;
                    }, "")
            }

            SettingsDropdownRow {
                visible: root.sel && root.sel.type === "label"
                text: "Strichstärke"
                options: root.weightNames
                currentValue: root.sel && root.sel.font ? root.weightName(root.sel.font.weight || 400) : "Normal"
                onValueChanged: value => {
                    const hit = root.weights.find(w => w[1] === value);
                    if (hit)
                        root.editSel(w => {
                            w.font = w.font || {};
                            w.font.weight = hit[0];
                        }, "");
                }
            }

            SettingsToggleRow {
                visible: root.sel && root.sel.type === "label"
                text: "Kursiv"
                checked: !!(root.sel && root.sel.font && root.sel.font.italic)
                onToggled: checked => root.editSel(w => {
                        w.font = w.font || {};
                        w.font.italic = checked;
                    }, "")
            }

            SettingsSliderRow {
                visible: root.sel && root.sel.type === "label"
                text: "Grösse"
                unit: "pt"
                minimum: 6
                maximum: 300
                value: root.sel && root.sel.fontSize ? Math.round(root.sel.fontSize) : 24
                onSliderValueChanged: newValue => root.editSel(w => w.fontSize = newValue, "fontSize")
            }

            SettingsToggleRow {
                visible: root.sel && root.sel.type === "label"
                text: "Schatten"
                description: "Weicher dunkler Schein um die Schrift, hebt sie vom Hintergrund ab."
                checked: !!(root.sel && root.sel.shadow && root.sel.shadow.passes > 0)
                onToggled: checked => root.editSel(w => {
                        w.shadow = w.shadow || { "size": 3, "color": "#ff000000", "boost": 1.2 };
                        w.shadow.passes = checked ? 3 : 0;
                    }, "")
            }

            // --- Bild
            SettingsRow {
                visible: root.sel && root.sel.type === "image"
                title: "Datei"
                subtitle: root.sel ? String(root.sel.path || "") : ""
                iconName: "image"

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wählen …"
                    variant: "tonal"
                    onClicked: {
                        imageBrowser.replace = true;
                        imageBrowser.background = false;
                        imageBrowser.open();
                    }
                }
            }

            SettingsSliderRow {
                visible: root.sel && root.sel.type === "image"
                text: "Grösse"
                description: "Länge der kürzeren Bildseite, in Pixeln des MacBook-Bildschirms."
                unit: "px"
                minimum: 20
                maximum: 1600
                value: root.sel && root.sel.size ? Math.round(root.sel.size) : 350
                onSliderValueChanged: newValue => root.editSel(w => w.size = newValue, "size")
            }

            SettingsToggleRow {
                visible: root.sel && root.sel.type === "image"
                text: "Rund zuschneiden"
                checked: !!(root.sel && root.sel.rounding === -1)
                onToggled: checked => root.editSel(w => w.rounding = checked ? -1 : 0, "")
            }

            SettingsSliderRow {
                // hyprlock kennt keine Deckkraft für Bilder und Flächen.
                visible: root.sel && (root.sel.type === "image" || root.sel.type === "shape") && !root.hyprMode
                text: "Deckkraft"
                unit: "%"
                minimum: 0
                maximum: 100
                value: root.sel ? Math.round((root.sel.opacity === undefined ? 1 : root.sel.opacity) * 100) : 100
                onSliderValueChanged: newValue => root.editSel(w => w.opacity = newValue / 100, "opacity")
            }

            SettingsSliderRow {
                visible: root.sel && root.sel.type !== "input"
                text: "Drehung"
                unit: "°"
                minimum: -180
                maximum: 180
                value: root.sel ? Math.round(root.sel.rotate || 0) : 0
                onSliderValueChanged: newValue => root.editSel(w => w.rotate = newValue, "rotate")
            }

            // --- Passwortfeld
            SettingsSliderRow {
                visible: root.sel && root.sel.type === "input"
                text: "Breite"
                unit: "px"
                minimum: 80
                maximum: 1400
                value: root.sel && root.sel.size ? Math.round(root.num(root.sel.size[0], root.ref.width)) : 200
                onSliderValueChanged: newValue => root.editSel(w => w.size = [String(newValue), w.size[1]], "w")
            }

            SettingsSliderRow {
                visible: root.sel && root.sel.type === "input"
                text: "Höhe"
                unit: "px"
                minimum: 20
                maximum: 300
                value: root.sel && root.sel.size ? Math.round(root.num(root.sel.size[1], root.ref.height)) : 50
                onSliderValueChanged: newValue => root.editSel(w => w.size = [w.size[0], String(newValue)], "h")
            }

            SettingsTextFieldRow {
                visible: root.sel && root.sel.type === "input"
                text: "Platzhalter"
                value: root.sel && root.sel.type === "input" ? String(root.sel.placeholder || "") : ""
                onEditingFinished: value => root.editSel(w => w.placeholder = value, "")
            }

            SettingsSliderRow {
                visible: root.sel && root.sel.type === "input"
                text: "Rahmen"
                unit: "px"
                minimum: 0
                maximum: 10
                value: root.sel ? Math.round(root.sel.outline || 0) : 0
                onSliderValueChanged: newValue => root.editSel(w => {
                        w.outline = newValue;
                        // Ein unsichtbarer Rahmen bekommt beim Einschalten eine sichtbare Farbe.
                        if (newValue > 0 && root.alphaOf(w.outerColor) === 0)
                            w.outerColor = "#66ffffff";
                    }, "outline")
            }

            SettingsSliderRow {
                visible: root.sel && root.sel.type === "input"
                text: "Punktgrösse"
                description: "Grösse der Punkte beim Tippen, im Verhältnis zur Feldhöhe."
                unit: "%"
                minimum: 5
                maximum: 80
                value: root.sel ? Math.round((root.sel.dotsSize || 0.33) * 100) : 33
                onSliderValueChanged: newValue => root.editSel(w => w.dotsSize = newValue / 100, "dots")
            }

            SettingsToggleRow {
                visible: root.sel && root.sel.type === "input"
                text: "Abgerundet (Pille)"
                checked: !!(root.sel && (root.sel.rounding === undefined || root.sel.rounding === -1))
                onToggled: checked => root.editSel(w => w.rounding = checked ? -1 : 12, "")
            }

            // --- Farben (Text: Schrift; Passwortfeld: Fläche, Schrift, Rahmen; Fläche: Füllung)
            Repeater {
                model: !root.sel ? [] : root.sel.type === "label" ? [["color", "Farbe"]] : root.sel.type === "input" ? [["innerColor", "Feldfarbe"], ["fontColor", "Schrift und Punkte"], ["outerColor", "Rahmenfarbe"]] : root.sel.type === "shape" ? [["color", "Farbe"]] : []

                SettingsRow {
                    id: colorRow
                    required property var modelData
                    readonly property string key: modelData[0]
                    readonly property string value: root.sel ? String(root.sel[key] || "#ffffffff") : "#ffffffff"
                    width: parent ? parent.width : 0
                    title: modelData[1]
                    subtitle: "Deckkraft " + Math.round(root.alphaOf(value) * 100) + " %"
                    iconName: "palette"

                    body: Column {
                        width: parent.width
                        spacing: Theme.spacingS

                        Row {
                            spacing: Theme.spacingS

                            Repeater {
                                model: [["Weiss", "#ffffff"], ["Grau", "#c8c8c8"], ["Schwarz", "#000000"], ["Akzent", String(Theme.primary)]]

                                Rectangle {
                                    required property var modelData
                                    width: 34
                                    height: 34
                                    radius: 17
                                    color: modelData[1]
                                    border.width: 2
                                    border.color: Theme.outlineVariant
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.editSel(w => w[colorRow.key] = root.withAlpha(parent.modelData[1], Math.max(0.05, root.alphaOf(w[colorRow.key]))), "")
                                    }
                                }
                            }

                            DButton {
                                text: "Eigene …"
                                iconName: "colorize"
                                variant: "text"
                                onClicked: root.pickColor(colorRow.value, colorRow.modelData[1], hex => root.editSel(w => w[colorRow.key] = hex, ""))
                            }
                        }

                        SettingsSliderControl {
                            width: parent.width
                            minimum: 0
                            maximum: 100
                            unit: "%"
                            value: Math.round(root.alphaOf(colorRow.value) * 100)
                            onSliderValueChanged: newValue => root.editSel(w => w[colorRow.key] = root.withAlpha(w[colorRow.key], newValue / 100), "alpha:" + colorRow.key)
                        }
                    }
                }
            }

            // --- Für alle
            SettingsRow {
                visible: root.sel !== null
                title: "Anordnen"
                subtitle: "Ebene " + (root.sel ? root.sel.zindex || 0 : 0) + " – höhere Ebenen liegen über tieferen."
                iconName: "flip_to_front"

                body: Flow {
                    width: parent.width
                    spacing: Theme.spacingS

                    DButton {
                        text: "Nach vorne"
                        iconName: "flip_to_front"
                        variant: "tonal"
                        onClicked: root.restack(1)
                    }
                    DButton {
                        text: "Nach hinten"
                        iconName: "flip_to_back"
                        variant: "tonal"
                        onClicked: root.restack(-1)
                    }
                    DButton {
                        text: "Waagrecht mittig"
                        iconName: "align_horizontal_center"
                        variant: "tonal"
                        onClicked: root.editSel(w => {
                            w.halign = "center";
                            w.position = ["0", w.position[1]];
                        }, "")
                    }
                    DButton {
                        visible: root.sel && root.sel.type !== "input"
                        text: "Duplizieren"
                        iconName: "content_copy"
                        variant: "text"
                        onClicked: root.duplicateSelected()
                    }
                    DButton {
                        visible: root.sel && root.sel.type !== "input"
                        text: "Entfernen"
                        iconName: "delete"
                        variant: "text"
                        danger: true
                        onClicked: root.removeSelected()
                    }
                }
            }
        }

        // ---------------------------------------------------------- Hintergrund
        SettingsCard {
            width: parent.width
            visible: root.installed && root.layout !== null
            iconName: "wallpaper"
            title: "Hintergrund"
            settingKey: "alpeLockBackground"

            SettingsDropdownRow {
                text: "Bild"
                description: root.bg.source === "image" ? String(root.bg.image || "noch keins gewählt") : (root.desktopImage !== "" ? "Wechselt mit dem Desktop. Bei einem Video-Hintergrund ein Standbild daraus." : "Das Desktop-Bild ist ein Video, dessen Standbild noch fehlt (braucht ffmpeg), oder eine Farbe.")
                options: ["Wie der Desktop", "Eigenes Bild"]
                currentValue: root.bg.source === "image" ? "Eigenes Bild" : "Wie der Desktop"
                onValueChanged: value => {
                    if (value === "Eigenes Bild") {
                        if (root.bg.image) {
                            root.edit(l => l.background.source = "image", "");
                        } else {
                            imageBrowser.background = true;
                            imageBrowser.open();
                        }
                    } else {
                        root.edit(l => l.background.source = "desktop", "");
                    }
                }
            }

            SettingsRow {
                visible: root.bg.source === "image"
                title: "Eigenes Bild"
                subtitle: String(root.bg.image || "")
                iconName: "image"

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wählen …"
                    variant: "tonal"
                    onClicked: {
                        imageBrowser.background = true;
                        imageBrowser.open();
                    }
                }
            }

            SettingsSliderRow {
                text: "Unschärfe"
                unit: "px"
                minimum: 0
                maximum: 400
                value: Math.round(root.bg.blurRadius || 0)
                onSliderValueChanged: newValue => root.edit(l => l.background.blurRadius = newValue, "blur")
            }

            SettingsSliderRow {
                text: "Helligkeit"
                unit: "%"
                minimum: 10
                maximum: 100
                value: Math.round((root.bg.brightness === undefined ? 1 : root.bg.brightness) * 100)
                onSliderValueChanged: newValue => root.edit(l => l.background.brightness = newValue / 100, "brightness")
            }

            SettingsSliderRow {
                text: "Kontrast"
                unit: "%"
                minimum: 50
                maximum: 150
                value: Math.round((root.bg.contrast === undefined ? 1 : root.bg.contrast) * 100)
                onSliderValueChanged: newValue => root.edit(l => l.background.contrast = newValue / 100, "contrast")
            }

            SettingsSliderRow {
                text: "Farbsättigung"
                unit: "%"
                minimum: -100
                maximum: 100
                value: Math.round((root.bg.vibrancy || 0) * 100)
                onSliderValueChanged: newValue => root.edit(l => l.background.vibrancy = newValue / 100, "vibrancy")
            }

        }

        // ---------------------------------------------------------- Sprache
        SettingsCard {
            width: parent.width
            visible: root.installed
            iconName: "translate"
            title: "Datum"
            settingKey: "alpeLockLocale"

            SettingsDropdownRow {
                text: "Sprache für Wochentag und Monat"
                options: root.localeOptions
                currentValue: root.localeOptions[Math.max(0, root.localeValues.indexOf(root.localeName))]
                onValueChanged: value => {
                    const index = root.localeOptions.indexOf(value);
                    if (index < 0)
                        return;
                    root.localeName = root.localeValues[index];
                    root.lnf("Locale", root.localeName);
                }
            }
        }
    }
}
