/*
    Alpe – Sperrbildschirm «Eigenes Layout» (Stil «hyprlock»).

    Zeichnet ein Layout aus Texten, Bildern, Flächen und dem Passwortfeld. Es kommt aus den
    Einstellungen (kscreenlockerrc, Schlüssel «Layout», gesetzt von der Einstellungsseite
    «Sperrbildschirm gestalten»), sonst aus layout.js: der Vorlage, die tools/hyprlock2qml.py aus
    der hyprlock.conf des MacBooks erzeugt. Lage, Grösse und Schrift folgen den Regeln von hyprlock:

    - Masse sind Pixel des Bezugsbildschirms (layout.reference, Vorgabe 2560 × 1664);
      hier gilt der Faktor unit = min(Breite / Bezugsbreite, Höhe / Bezugshöhe).
    - position verschiebt nach rechts und nach OBEN; halign/valign legen den Ausgangspunkt fest.
    - fontSize ist in Punkt (Pango, 96 dpi): Pixel = Punkt × 4/3.
    - image: Die kürzere Bildseite wird «size» lang; rounding = -1 rundet ganz ab.
    - Schatten nur mit shadow.passes > 0, wie bei hyprlock.

    Texte: «format» enthält strftime-Platzhalter (%H, %M, %A, %d, %B …) und $USER. Ältere
    Layouts haben stattdessen «text» mit {date:…} und {USER}.

    Bearbeiten: Die Einstellungsseite lädt diese Datei als Vorschau und setzt editing. Dann
    lassen sich Elemente anklicken (picked), ziehen (moved, in Bezugspixeln, y nach oben) und mit
    dem Mausrad vergrössern (resized). Im Sperrbildschirm bleibt editing aus.
*/
import QtQuick
import QtQuick.Effects
import "layout.js" as Hyprlock

Item {
    id: view

    // Von LockScreen.qml bzw. der Einstellungsseite
    property var custom: null
    property date now: new Date()
    property string userName: ""
    property string localeName: ""
    property bool effects: true
    property bool busy: false
    property int attempts: 0
    property string failMessage: ""
    property bool capsLock: false
    property string fallbackSans: "Noto Sans"
    property string slabFamily: ""
    property bool editing: false
    property int selected: -1
    // Die Vorschau ist verkleinert: Auswahlrahmen so viel dicker, dass er sichtbar bleibt.
    property real editScale: 1
    signal submitted
    signal picked(int index)
    signal moved(int index, real dx, real dy)
    signal resized(int index, int steps)

    readonly property var defaultLayout: Hyprlock.layout
    readonly property var layout: custom && custom.widgets ? custom : defaultLayout
    readonly property var reference: layout.reference || { "width": 2560, "height": 1664 }
    readonly property real unit: Math.max(0.05, Math.min(width / reference.width, height / reference.height))
    readonly property var locale: localeName !== "" ? Qt.locale(localeName) : Qt.locale()
    readonly property bool ignoreEmpty: !!(layout.general && layout.general.ignoreEmptyInput)
    readonly property bool unlocked: typeof authenticator !== "undefined" && authenticator ? !!authenticator.unlocked : false
    property bool failing: false

    // Das Eingabefeld (unsichtbar; die Punkte zeichnet die Ansicht selbst).
    property alias text: input.text
    function forceActiveFocus() {
        if (!editing)
            input.forceActiveFocus();
    }
    function fail() {
        failing = true;
        failTimer.interval = Math.max(500, field.failTimeout || 2000);
        failTimer.restart();
    }

    readonly property int fieldIndex: {
        const list = layout.widgets || [];
        for (let i = 0; i < list.length; i++)
            if (list[i].type === "input")
                return i;
        return -1;
    }
    readonly property var field: fieldIndex >= 0 ? layout.widgets[fieldIndex] : fallbackField
    // Ohne Passwortfeld im Layout: eines in der Mitte, wie hyprlocks Vorgabe.
    readonly property var fallbackField: ({
            "type": "input", "position": ["0", "-40"], "halign": "center", "valign": "center", "zindex": 20,
            "size": ["200", "50"], "outline": 1, "outerColor": "#00ffffff", "innerColor": "#1affffff",
            "fontColor": "#ffc8c8c8", "fontFamily": "Sans", "checkColor": "#ffcc8822", "failColor": "#ffcc2222",
            "capslockColor": "", "dotsSize": 0.1, "dotsSpacing": 1, "dotsCenter": true, "dotsRounding": -1,
            "hideInput": false, "fadeOnEmpty": false, "rounding": -1, "placeholder": "Passwort...",
            "failText": "<i>{FAIL} <b>({ATTEMPTS})</b></i>", "failTimeout": 2000, "opacity": 1, "rotate": 0
        })

    Timer {
        id: failTimer
        onTriggered: view.failing = false
    }

    // ---------------------------------------------------------------- Hilfen

    function px(value, axis) {
        const text = String(value);
        if (text.endsWith("%"))
            return parseFloat(text) / 100 * axis;
        const n = parseFloat(text);
        return (isNaN(n) ? 0 : n) * unit;
    }

    function placeX(item, w) {
        if (!item || !item.position)
            return 0;
        const ox = px(item.position[0], view.width);
        if (item.halign === "left")
            return ox;
        if (item.halign === "right")
            return view.width - w + ox;
        return (view.width - w) / 2 + ox;
    }

    function placeY(item, h) {
        if (!item || !item.position)
            return 0;
        const oy = px(item.position[1], view.height);
        if (item.valign === "top")
            return -oy;
        if (item.valign === "bottom")
            return view.height - h - oy;
        return (view.height - h) / 2 - oy;
    }

    // -1 rundet ganz ab (Kreis bzw. Pille). Andere negative Werte runden nicht: So zeigt es
    // hyprlock auf dem MacBook (rounding = -10 gibt eckige Bilder, Foto vom 17.11.2026).
    function radiusFor(rounding, w, h) {
        const full = Math.min(w, h) / 2;
        if (rounding === -1)
            return full;
        if (rounding < 0)
            return 0;
        return Math.min(full, rounding * unit);
    }

    function pad(n, width, fill) {
        let s = String(n);
        while (s.length < width)
            s = fill + s;
        return s;
    }

    // strftime mit den Namen der eingestellten Sprache. %-d usw. ohne führende Null.
    function strftime(format, d) {
        let out = "";
        for (let i = 0; i < format.length; i++) {
            const c = format[i];
            if (c !== "%" || i === format.length - 1) {
                out += c;
                continue;
            }
            let k = format[++i];
            let flag = "";
            if ((k === "-" || k === "_" || k === "0") && i < format.length - 1) {
                flag = k;
                k = format[++i];
            }
            const two = n => flag === "-" ? String(n) : flag === "_" ? pad(n, 2, " ") : pad(n, 2, "0");
            const hour12 = d.getHours() % 12 === 0 ? 12 : d.getHours() % 12;
            switch (k) {
            case "H": out += two(d.getHours()); break;
            case "k": out += pad(d.getHours(), 2, " "); break;
            case "I": out += two(hour12); break;
            case "l": out += pad(hour12, 2, " "); break;
            case "M": out += two(d.getMinutes()); break;
            case "S": out += two(d.getSeconds()); break;
            case "p": out += d.getHours() < 12 ? locale.amText : locale.pmText; break;
            case "P": out += (d.getHours() < 12 ? locale.amText : locale.pmText).toLowerCase(); break;
            case "A": out += locale.dayName(d.getDay(), Locale.LongFormat); break;
            case "a": out += locale.dayName(d.getDay(), Locale.ShortFormat); break;
            case "B": out += locale.monthName(d.getMonth(), Locale.LongFormat); break;
            case "b": case "h": out += locale.monthName(d.getMonth(), Locale.ShortFormat); break;
            case "d": out += two(d.getDate()); break;
            case "e": out += flag === "-" ? String(d.getDate()) : pad(d.getDate(), 2, " "); break;
            case "m": out += two(d.getMonth() + 1); break;
            case "y": out += pad(d.getFullYear() % 100, 2, "0"); break;
            case "Y": out += d.getFullYear(); break;
            case "u": out += d.getDay() === 0 ? 7 : d.getDay(); break;
            case "w": out += d.getDay(); break;
            case "j": out += pad(Math.floor((d - new Date(d.getFullYear(), 0, 1)) / 86400000) + 1, 3, "0"); break;
            case "R": out += pad(d.getHours(), 2, "0") + ":" + pad(d.getMinutes(), 2, "0"); break;
            case "T": out += pad(d.getHours(), 2, "0") + ":" + pad(d.getMinutes(), 2, "0") + ":" + pad(d.getSeconds(), 2, "0"); break;
            case "D": out += pad(d.getMonth() + 1, 2, "0") + "/" + pad(d.getDate(), 2, "0") + "/" + pad(d.getFullYear() % 100, 2, "0"); break;
            case "F": out += d.getFullYear() + "-" + pad(d.getMonth() + 1, 2, "0") + "-" + pad(d.getDate(), 2, "0"); break;
            case "n": out += "\n"; break;
            case "t": out += "\t"; break;
            case "%": out += "%"; break;
            default: out += "%" + flag + k;
            }
        }
        return out;
    }

    function runtime(t) {
        return t.replace(/\{USER\}|\$USER/g, view.userName)
            .replace(/\{FAIL\}|\$FAIL/g, view.failMessage || "Falsches Passwort")
            .replace(/\{ATTEMPTS\}|\$ATTEMPTS/g, String(view.attempts))
            .replace(/\{(LAYOUT|PROMPT|DESC)\}/g, "");
    }

    function render(template) {
        return runtime(String(template || "").replace(/\{date:([^}]*)\}/g, (m, f) => strftime(f, view.now)));
    }

    function labelText(spec) {
        if (spec.format !== undefined)
            return runtime(strftime(String(spec.format), view.now));
        return render(spec.text);
    }

    // Schriftfamilie: wie angegeben, sonst ohne «Nerd Font»-Zusatz, sonst mitgelieferte Schrift.
    readonly property var families: Qt.fontFamilies()
    function family(spec) {
        const wanted = String(spec || "Sans");
        const norm = s => s.toLowerCase().replace(/[\s_-]/g, "");
        const candidates = [wanted, wanted.replace(/ Nerd Font( Mono| Propo)?$/i, ""), wanted.replace(/ (NFM|NFP|NF)$/i, "")];
        for (let c = 0; c < candidates.length; c++) {
            const key = norm(candidates[c]);
            if (key === "alfaslabone" && view.slabFamily !== "")
                return view.slabFamily;
            for (let i = 0; i < families.length; i++)
                if (norm(families[i]) === key)
                    return families[i];
        }
        const generic = norm(wanted);
        if (generic === "sans" || generic === "sansserif" || generic === "")
            return view.fallbackSans;
        if (generic === "monospace" || generic === "mono" || /mono/.test(generic))
            return "monospace";
        return wanted;
    }

    // ---------------------------------------------------------------- Bearbeiten

    // Fläche über einem Element: anklicken, ziehen, Mausrad. Nur mit editing.
    component EditHandle: MouseArea {
        id: handle
        required property Item target
        required property int index
        property real sx: 0
        property real sy: 0
        anchors.fill: parent
        enabled: view.editing
        visible: view.editing
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: target
        drag.threshold: 2
        onPressed: {
            sx = target.x;
            sy = target.y;
            view.picked(index);
        }
        onReleased: {
            const dx = (target.x - sx) / view.unit;
            const dy = -(target.y - sy) / view.unit;
            if (Math.abs(dx) + Math.abs(dy) > 0.5)
                view.moved(index, dx, dy);
        }
        onWheel: wheel => {
            view.picked(index);
            view.resized(index, wheel.angleDelta.y > 0 ? 1 : -1);
        }
    }

    component Selection: Rectangle {
        required property int index
        anchors.fill: parent
        anchors.margins: -4 * view.editScale
        visible: view.editing && view.selected === index
        color: "#14ffffff"
        radius: 6 * view.editScale
        border.width: 2 * view.editScale
        border.color: "#ffffffff"
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2 * view.editScale
            color: "transparent"
            radius: 4 * view.editScale
            border.width: 1 * view.editScale
            border.color: "#99000000"
        }
    }

    // ---------------------------------------------------------------- Bausteine

    Repeater {
        model: view.layout.widgets || []

        delegate: Loader {
            required property var modelData
            required property int index
            z: (modelData.zindex || 0) * 1000 + index
            // Das Eingabefeld zeichnet die Ansicht unten selbst.
            sourceComponent: modelData.type === "label" ? label : modelData.type === "image" ? picture : modelData.type === "shape" ? shape : null
        }
    }

    Component {
        id: label

        Text {
            id: t
            readonly property var spec: parent && parent.modelData ? parent.modelData : ({})
            readonly property int idx: parent ? parent.index : -1
            readonly property int weight: spec.font ? spec.font.weight : 400
            x: view.placeX(spec, width)
            y: view.placeY(spec, height)
            rotation: -(spec.rotate || 0)
            opacity: spec.opacity === undefined ? 1 : spec.opacity
            textFormat: Text.StyledText
            text: view.labelText(spec)
            color: spec.color || "#ffffffff"
            horizontalAlignment: spec.align === "left" ? Text.AlignLeft : spec.align === "right" ? Text.AlignRight : Text.AlignHCenter
            font.family: view.family(spec.font ? spec.font.family : "Sans")
            font.weight: weight
            font.italic: !!(spec.font && spec.font.italic)
            font.pixelSize: Math.max(1, (spec.fontSize || 16) * 4 / 3 * view.unit)
            renderType: Text.QtRendering
            layer.enabled: !!(view.effects && spec.shadow && spec.shadow.passes > 0)
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: t.spec.shadow.color
                shadowBlur: Math.min(1, 0.25 + 0.15 * t.spec.shadow.passes)
                shadowOpacity: Math.min(1, 0.55 * t.spec.shadow.boost)
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }

            Selection { index: t.idx }
            EditHandle { target: t; index: t.idx }
        }
    }

    Component {
        id: picture

        Item {
            id: pic
            readonly property var spec: parent && parent.modelData ? parent.modelData : ({})
            readonly property int idx: parent ? parent.index : -1
            readonly property real side: Math.max(1, (spec.size || 150) * view.unit)
            readonly property real fit: img.status === Image.Ready ? side / Math.max(1, Math.min(img.implicitWidth, img.implicitHeight)) : 0
            readonly property real radius: view.radiusFor(spec.rounding === undefined ? -1 : spec.rounding, width, height)
            readonly property bool missing: img.status === Image.Error || (spec.path || "") === ""
            // Fehlt das Bild, zeigt nur die Bearbeitung einen Platzhalter.
            width: missing ? side : img.implicitWidth * fit
            height: missing ? side : img.implicitHeight * fit
            x: view.placeX(spec, width)
            y: view.placeY(spec, height)
            rotation: -(spec.rotate || 0)
            opacity: spec.opacity === undefined ? 1 : spec.opacity
            visible: img.status === Image.Ready || (view.editing && missing)

            Image {
                id: img
                anchors.fill: parent
                source: pic.spec.path ? "file://" + pic.spec.path : ""
                fillMode: Image.Stretch
                smooth: true
                mipmap: true
                asynchronous: true
                cache: true
                visible: !view.effects || pic.radius <= 0
            }

            MultiEffect {
                anchors.fill: img
                source: img
                visible: view.effects && pic.radius > 0 && img.status === Image.Ready
                maskEnabled: true
                maskSource: mask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }

            Item {
                id: mask
                anchors.fill: img
                layer.enabled: true
                layer.smooth: true
                visible: false
                Rectangle {
                    anchors.fill: parent
                    radius: pic.radius
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: (pic.spec.borderSize || 0) > 0
                color: "transparent"
                radius: pic.radius
                border.width: Math.max(1, (pic.spec.borderSize || 0) * view.unit)
                border.color: pic.spec.borderColor || "#ffdddddd"
            }

            Rectangle {
                anchors.fill: parent
                visible: pic.missing
                radius: pic.radius
                color: "#33000000"
                border.width: 2
                border.color: "#99ffffff"
                Text {
                    anchors.centerIn: parent
                    width: parent.width * 0.9
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: "Bild fehlt\n" + String(pic.spec.path || "").split("/").pop()
                    color: "#ffffff"
                    font.pixelSize: Math.max(10, parent.height * 0.08)
                }
            }

            Selection { index: pic.idx }
            EditHandle { target: pic; index: pic.idx }
        }
    }

    Component {
        id: shape

        Rectangle {
            id: sh
            readonly property var spec: parent && parent.modelData ? parent.modelData : ({})
            readonly property int idx: parent ? parent.index : -1
            width: view.px(spec.size ? spec.size[0] : 100, view.width)
            height: view.px(spec.size ? spec.size[1] : 100, view.height)
            x: view.placeX(spec, width)
            y: view.placeY(spec, height)
            rotation: -(spec.rotate || 0)
            opacity: spec.opacity === undefined ? 1 : spec.opacity
            color: spec.color || "#ff111111"
            radius: view.radiusFor(spec.rounding === undefined ? -1 : spec.rounding, width, height)
            border.width: (spec.borderSize || 0) * view.unit
            border.color: spec.borderColor || "transparent"

            Selection { index: sh.idx }
            EditHandle { target: sh; index: sh.idx }
        }
    }

    // ---------------------------------------------------------------- Eingabefeld

    Rectangle {
        id: box

        readonly property var spec: view.field
        readonly property real dot: Math.max(2, height * spec.dotsSize)
        readonly property real gap: dot * spec.dotsSpacing
        readonly property string state_: view.busy ? "check" : view.failing ? "fail" : view.capsLock && spec.capslockColor ? "caps" : "idle"

        z: (spec.zindex || 0) * 1000 + 999
        width: view.px(spec.size[0], view.width)
        height: view.px(spec.size[1], view.height)
        x: view.placeX(spec, width) + shakeOffset
        y: view.placeY(spec, height)
        rotation: -(spec.rotate || 0)
        property real shakeOffset: 0
        opacity: (spec.opacity === undefined ? 1 : spec.opacity) * (spec.fadeOnEmpty && input.text.length === 0 && !view.failing && !view.editing ? 0 : 1)
        Behavior on opacity { NumberAnimation { duration: 200 } }

        radius: view.radiusFor(spec.rounding === undefined ? -1 : spec.rounding, width, height)
        color: spec.innerColor
        border.width: spec.outline > 0 ? Math.max(1, spec.outline * view.unit) : 0
        border.color: state_ === "check" ? spec.checkColor : state_ === "fail" ? spec.failColor : state_ === "caps" ? spec.capslockColor : spec.outerColor
        Behavior on border.color { ColorAnimation { duration: 150 } }

        TextInput {
            id: input
            anchors.fill: parent
            opacity: 0
            echoMode: TextInput.Password
            cursorVisible: false
            focus: !view.editing
            enabled: !view.editing && !view.unlocked
            Keys.onReturnPressed: view.submitted()
            Keys.onEnterPressed: view.submitted()
            Keys.onEscapePressed: text = ""
            onTextChanged: if (text.length > 0) view.failing = false
        }

        // Punkte
        Row {
            id: dots
            visible: !box.spec.hideInput && input.text.length > 0
            spacing: box.gap
            anchors.verticalCenter: parent.verticalCenter
            x: box.spec.dotsCenter ? (box.width - width) / 2 : box.height / 2
            // Nicht über den Rand hinaus: lange Passwörter zeigen nur die letzten Punkte.
            readonly property int fits: Math.max(1, Math.floor((box.width - box.height) / (box.dot + box.gap)))

            Repeater {
                model: Math.min(input.text.length, dots.fits)
                Rectangle {
                    width: box.dot
                    height: box.dot
                    radius: box.spec.dotsRounding < 0 ? width / 2 : Math.min(width / 2, box.spec.dotsRounding * view.unit)
                    color: box.spec.fontColor
                }
            }
        }

        Text {
            anchors.centerIn: parent
            width: parent.width - parent.height * 0.5
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            visible: input.text.length === 0
            textFormat: Text.StyledText
            text: view.render(view.failing ? box.spec.failText : box.spec.placeholder)
            color: box.spec.fontColor
            font.family: view.family(box.spec.fontFamily)
            // hyprlock: Schriftgrösse = Feldhöhe / 4 Punkt.
            font.pixelSize: Math.max(4, box.height / 3)
        }

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: box; property: "shakeOffset"; to: -10 * view.unit; duration: 50 }
            NumberAnimation { target: box; property: "shakeOffset"; to: 10 * view.unit; duration: 70 }
            NumberAnimation { target: box; property: "shakeOffset"; to: 0; duration: 50 }
        }

        Selection { index: view.fieldIndex }
        EditHandle { target: box; index: view.fieldIndex }
    }

    function shake() {
        shakeAnim.restart();
    }

    // Feststelltaste: hyprlock zeigt sie nur über capslock_color. Ohne diese Angabe ein leiser Hinweis.
    Text {
        z: box.z
        anchors.horizontalCenter: box.horizontalCenter
        anchors.top: box.bottom
        anchors.topMargin: box.height * 0.3
        visible: view.capsLock && !box.spec.capslockColor
        text: "Feststelltaste ist aktiv"
        color: box.spec.fontColor
        font.family: view.family(box.spec.fontFamily)
        font.pixelSize: Math.max(8, box.height / 3.4)
    }
}
