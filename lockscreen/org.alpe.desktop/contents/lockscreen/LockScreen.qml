/*
    Alpe – Sperrbildschirm für den KDE-Sperrdienst (kscreenlocker).

    Drei Stile (config «Style»):
    «hyprlock» (Vorgabe, «Eigenes Layout») – Texte, Bilder und Passwortfeld frei angeordnet;
      gestaltet in Alpes Einstellungen (Schlüssel «Layout»), Vorlage ist die hyprlock.conf des
      MacBooks (layout.js, siehe HyprlockView.qml);
    «klar» – Datum, grosse schlanke Uhr, Name und ein Passwortfeld aus Milchglas;
    «slab» – Stunden und Minuten übereinander in Alfa Slab One. Bewusst nur mit Qt-eigenen Modulen
    gebaut: Fehlt ein KDE-Baustein, lädt der Sperrbildschirm trotzdem (nur der Hinweis zur
    Feststelltaste entfällt dann).

    Vom Sperrdienst kommen: authenticator (PAM), wallpaper (das Hintergrund-Plugin, liegt schon
    unter dieser Oberfläche), config (lockscreen/config.xml), kscreenlocker_userName.
*/
import QtQuick
import QtQuick.Effects

Item {
    id: root

    // Vom Sperrdienst gesetzt und gelesen.
    property bool viewVisible: false
    property bool locked: false
    property string notification: ""
    signal clearPassword

    implicitWidth: 1280
    implicitHeight: 800

    // Masse wie in der hyprlock-Vorlage, die für 2560 × 1664 Pixel ausgelegt war.
    readonly property real unit: Math.max(0.45, Math.min(width / 2560, height / 1664) * 1.25)
    readonly property int blur: Math.max(0, Math.min(64, Number(root.cfg("Blur", 48))))
    // Nur bei reiner Software-Darstellung gibt es keine Effekte. «Unbekannt» heisst: Das Fenster
    // steht noch nicht – sonst bliebe der Hintergrund scharf.
    readonly property bool effects: root.GraphicsInfo.api !== GraphicsInfo.Software
    readonly property real dim: Math.max(0, Math.min(90, Number(root.cfg("Dim", 40)))) / 100
    readonly property string style: String(root.cfg("Style", "hyprlock"))
    readonly property bool hypr: style === "hyprlock"
    // Hintergrund im Stil «hyprlock»: Werte aus dem background-Block der hyprlock.conf.
    readonly property var hbg: hypr && hview.layout.background ? hview.layout.background : null
    // Layout aus den Einstellungen (JSON); fehlt es oder ist es kaputt, gilt die Vorlage.
    readonly property var customLayout: {
        const text = String(root.cfg("Layout", ""));
        if (text === "")
            return null;
        try {
            const parsed = JSON.parse(text);
            return parsed && parsed.widgets ? parsed : null;
        } catch (e) {
            return null;
        }
    }
    // Unschärfe in Bezugspixeln: «blurRadius» aus den Einstellungen, sonst wie hyprlock
    // (Dual-Kawase, Reichweite etwa blur_size × 2^passes; ×3 trifft das Bild am Mac).
    readonly property real hblur: !hbg ? 0 : (hbg.blurRadius !== undefined ? hbg.blurRadius : (hbg.blurPasses > 0 ? hbg.blurSize * Math.pow(2, hbg.blurPasses) * 3 : 0)) * hview.unit
    readonly property string localeName: String(root.cfg("Locale", ""))
    readonly property string sans: Qt.fontFamilies().indexOf("Inter") >= 0 ? "Inter" : "Noto Sans"
    readonly property string userName: typeof kscreenlocker_userName !== "undefined" ? String(kscreenlocker_userName) : ""
    readonly property string userImage: typeof kscreenlocker_userImage !== "undefined" ? String(kscreenlocker_userImage) : ""
    property date now: new Date()

    // Antwort, die auf ihre Abfrage wartet. Sie bleibt, bis ein Ergebnis kommt: Ist die
    // PAM-Abfrage beim Druck auf die Eingabetaste noch nicht bereit, geht sie mit der
    // nächsten Abfrage hinaus.
    property string pending: ""
    property string message: ""
    property bool failedOnce: false
    property int attempts: 0

    function cfg(key, fallback) {
        try {
            const value = config[key];
            return value === undefined || value === null || value === "" ? fallback : value;
        } catch (e) {
            return fallback;
        }
    }

    // Das sichtbare Eingabefeld des aktuellen Stils.
    readonly property var entry: hypr ? hview : field

    function submit() {
        const text = entry.text;
        if (text.length === 0) {
            if (hypr) {
                if (!hview.ignoreEmpty)
                    hview.shake();
                return;
            }
            shake.restart();
            return;
        }
        pending = text;
        message = "";
        authenticator.respond(text);
    }

    function reset() {
        pending = "";
        field.text = "";
        hview.text = "";
        entry.forceActiveFocus();
    }

    onClearPassword: reset()
    onViewVisibleChanged: {
        if (viewVisible) {
            entry.forceActiveFocus();
            authenticator.startAuthenticating();
        }
    }

    Connections {
        target: authenticator

        function onPromptForSecretChanged() {
            if (root.pending.length > 0)
                authenticator.respond(root.pending);
        }

        function onSucceeded() {
            authenticator.stopAuthenticating();
            Qt.quit();
        }

        function onFailed(kind) {
            // Nur das Passwort zählt; Fingerabdruck und Chipkarte melden sich hier ebenfalls.
            if (kind != 0)
                return;
            root.failedOnce = true;
            root.attempts += 1;
            root.message = "Falsches Passwort";
            root.reset();
            if (root.hypr)
                hview.fail();
            else
                shake.restart();
            messageTimer.restart();
            authenticator.startAuthenticating();
        }

        function onErrorMessageChanged() {
            if (authenticator.errorMessage)
                root.message = authenticator.errorMessage;
        }

        function onInfoMessageChanged() {
            if (authenticator.infoMessage)
                root.message = authenticator.infoMessage;
        }
    }

    // Hält die Abfrage am Leben, solange der Bildschirm gesperrt ist.
    Timer {
        interval: 1000
        repeat: true
        running: root.viewVisible && !authenticator.unlocked
        triggeredOnStart: true
        onTriggered: authenticator.startAuthenticating()
    }

    Timer {
        id: messageTimer
        interval: 4000
        onTriggered: root.message = ""
    }

    FontLoader {
        id: slab
        source: Qt.resolvedUrl("fonts/AlfaSlabOne-Regular.ttf")
    }

    // JetBrains Mono liegt bei, falls sie auf dem Rechner fehlt (Datum der hyprlock-Vorlage).
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-ExtraBold.ttf") }

    // ---------------------------------------------------------------- Hintergrund
    // Nur ohne Hintergrund-Plugin; sonst liegt dessen Bild schon unter dieser Oberfläche.
    Rectangle {
        anchors.fill: parent
        visible: typeof wallpaper === "undefined" || !wallpaper
        gradient: Gradient {
            GradientStop { position: 0; color: "#1b2330" }
            GradientStop { position: 1; color: "#07090d" }
        }
    }

    // Eigenes Bild aus dem Layout (background.source = "image"), sonst ohne Hintergrund-Plugin
    // das Bild aus der hyprlock.conf.
    readonly property bool ownImage: hypr && hbg !== null && hbg.source === "image" && !!hbg.image
    Image {
        id: confWall
        anchors.fill: parent
        visible: false
        source: root.ownImage ? "file://" + root.hbg.image : (root.hypr && (typeof wallpaper === "undefined" || !wallpaper) && root.hbg && root.hbg.path ? "file://" + root.hbg.path : "")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    ShaderEffectSource {
        id: backdrop
        anchors.fill: parent
        sourceItem: root.ownImage && confWall.status === Image.Ready ? confWall : (typeof wallpaper !== "undefined" && wallpaper ? wallpaper : (confWall.status === Image.Ready ? confWall : null))
        hideSource: sourceItem !== null && root.effects
        live: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: backdrop
        visible: backdrop.sourceItem !== null && root.effects
        autoPaddingEnabled: false
        blurEnabled: root.hypr ? root.hblur > 0 : root.blur > 0
        blurMax: 64
        blur: root.hypr ? Math.min(1, root.hblur / 64) : root.blur / 64
        blurMultiplier: root.hypr ? Math.max(0, root.hblur / 64 - 1) : 1.5
        saturation: root.hypr ? (root.hbg ? root.hbg.vibrancy : 0) : -0.2
        contrast: root.hypr && root.hbg ? root.hbg.contrast - 1 : 0
        brightness: root.hypr ? 0 : -root.dim
    }

    // hyprlock multipliziert mit «brightness»; Schwarz mit Deckkraft 1 − brightness tut dasselbe.
    Rectangle {
        anchors.fill: parent
        visible: root.hypr
        color: Qt.rgba(0, 0, 0, root.hbg ? Math.max(0, Math.min(1, 1 - root.hbg.brightness)) + (root.effects ? 0 : 0.15) : 0.3)
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.effects && !root.hypr
        color: Qt.rgba(0, 0, 0, root.dim + 0.15)
    }

    // Leichte Abdunklung zu den Rändern hin, damit die Mitte trägt (nicht im Stil «hyprlock»).
    Rectangle {
        anchors.fill: parent
        visible: !root.hypr
        gradient: Gradient {
            GradientStop { position: 0; color: "#33000000" }
            GradientStop { position: 0.35; color: "#00000000" }
            GradientStop { position: 0.7; color: "#00000000" }
            GradientStop { position: 1; color: "#59000000" }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // ---------------------------------------------------------------- Stil «klar»
    Column {
        id: clear
        visible: root.style === "klar"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: card.top
        anchors.bottomMargin: 56 * root.unit
        spacing: 4 * root.unit

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.now.toLocaleDateString(Qt.locale(), "dddd, d. MMMM").toUpperCase()
            font.family: root.sans
            font.pixelSize: 24 * root.unit
            font.weight: Font.Medium
            font.letterSpacing: 5 * root.unit
            color: "#d9ffffff"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "hh:mm")
            font.family: root.sans
            font.pixelSize: 230 * root.unit
            font.weight: Font.Light
            font.letterSpacing: -4 * root.unit
            font.features: { "tnum": 1 }
            color: "#ffffff"
        }
    }

    // ---------------------------------------------------------------- Stil «slab»
    Column {
        id: slabClock
        visible: root.style === "slab"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: card.top
        anchors.bottomMargin: 48 * root.unit
        spacing: 0

        Repeater {
            model: ["hh", "mm"]

            Item {
                id: line
                required property string modelData
                anchors.horizontalCenter: parent.horizontalCenter
                width: digits.implicitWidth
                height: digits.implicitHeight * 0.86

                Text {
                    y: 4 * root.unit
                    text: digits.text
                    font: digits.font
                    color: "#59000000"
                }

                Text {
                    id: digits
                    text: Qt.formatTime(root.now, line.modelData)
                    font.family: slab.status === FontLoader.Ready ? slab.font.family : root.sans
                    font.weight: slab.status === FontLoader.Ready ? Font.Normal : Font.Black
                    font.pixelSize: 170 * root.unit
                    color: "#ffffff"
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 24 * root.unit
            text: root.now.toLocaleDateString(Qt.locale(), "dddd, d. MMMM")
            font.family: root.sans
            font.pixelSize: 26 * root.unit
            font.weight: Font.DemiBold
            color: "#eeffffff"
        }
    }

    // ---------------------------------------------------------------- Anmeldung
    Column {
        id: card
        visible: !root.hypr
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: field.offset
        anchors.top: parent.verticalCenter
        anchors.topMargin: 40 * root.unit
        spacing: 22 * root.unit

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14 * root.unit
            visible: root.userName !== ""

            Rectangle {
                id: avatar
                width: 44 * root.unit
                height: width
                radius: width / 2
                color: "#33ffffff"
                border.width: 1
                border.color: "#40ffffff"
                clip: true

                Text {
                    anchors.centerIn: parent
                    visible: face.status !== Image.Ready
                    text: root.userName.charAt(0).toUpperCase()
                    font.family: root.sans
                    font.pixelSize: parent.height * 0.45
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                }

                Image {
                    id: face
                    anchors.fill: parent
                    anchors.margins: 1
                    source: root.userImage
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }

                MultiEffect {
                    anchors.fill: face
                    source: face
                    visible: face.status === Image.Ready && root.effects
                    maskEnabled: true
                    maskSource: faceMask
                }

                Item {
                    id: faceMask
                    anchors.fill: face
                    layer.enabled: true
                    visible: false
                    Rectangle { anchors.fill: parent; radius: width / 2 }
                }
            }

            Text {
                anchors.verticalCenter: avatar.verticalCenter
                text: root.userName
                font.family: root.sans
                font.pixelSize: 24 * root.unit
                font.weight: Font.Medium
                color: "#f2ffffff"
            }
        }

        Rectangle {
            id: field

            property alias text: input.text
            property real offset: 0

            anchors.horizontalCenter: parent.horizontalCenter
            width: 440 * root.unit
            height: 60 * root.unit
            radius: height / 2
            color: input.activeFocus ? "#33ffffff" : "#24ffffff"
            border.width: 1
            border.color: root.message !== "" ? "#ff8a8a" : input.activeFocus ? "#66ffffff" : "#33ffffff"

            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 160 } }

            function forceActiveFocus() {
                input.forceActiveFocus();
            }

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: parent.height * 0.6
                anchors.rightMargin: parent.height * 1.1
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                passwordMaskDelay: 0
                color: "#ffffff"
                selectionColor: "#55ffffff"
                font.family: root.sans
                font.pixelSize: parent.height * 0.3
                font.letterSpacing: 3 * root.unit
                focus: true
                clip: true
                enabled: !authenticator.unlocked

                Keys.onReturnPressed: root.submit()
                Keys.onEnterPressed: root.submit()
                Keys.onEscapePressed: root.reset()
                onTextChanged: {
                    if (text.length > 0 && root.message !== "" && root.failedOnce)
                        root.message = "";
                }
            }

            Text {
                anchors.left: input.left
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text.length === 0
                text: authenticator.busy || root.pending !== "" ? "Prüfe …" : "Passwort"
                font.family: root.sans
                font.pixelSize: parent.height * 0.3
                color: "#a6ffffff"
            }

            // Knopf zum Absenden: Kreis mit Pfeil, gezeichnet statt aus einer Symbolschrift.
            Rectangle {
                id: go
                anchors.right: parent.right
                anchors.rightMargin: parent.height * 0.12
                anchors.verticalCenter: parent.verticalCenter
                width: parent.height * 0.76
                height: width
                radius: width / 2
                color: input.text.length > 0 ? "#ffffff" : "#26ffffff"
                Behavior on color { ColorAnimation { duration: 160 } }

                Canvas {
                    anchors.centerIn: parent
                    width: parent.width * 0.42
                    height: width
                    property color ink: input.text.length > 0 ? "#1a1a1a" : "#ccffffff"
                    onInkChanged: requestPaint()
                    onPaint: {
                        const c = getContext("2d");
                        c.reset();
                        c.strokeStyle = ink;
                        c.lineWidth = Math.max(2, width * 0.14);
                        c.lineCap = "round";
                        c.lineJoin = "round";
                        c.beginPath();
                        c.moveTo(width * 0.1, height / 2);
                        c.lineTo(width * 0.9, height / 2);
                        c.moveTo(width * 0.55, height * 0.15);
                        c.lineTo(width * 0.9, height / 2);
                        c.lineTo(width * 0.55, height * 0.85);
                        c.stroke();
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.submit()
                }
            }

            SequentialAnimation {
                id: shake
                NumberAnimation { target: field; property: "offset"; to: -14 * root.unit; duration: 50 }
                NumberAnimation { target: field; property: "offset"; to: 14 * root.unit; duration: 70 }
                NumberAnimation { target: field; property: "offset"; to: -8 * root.unit; duration: 60 }
                NumberAnimation { target: field; property: "offset"; to: 0; duration: 50 }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(root.width * 0.6, 900 * root.unit)
            height: 24 * root.unit
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: [root.message, capsLock.item && capsLock.item.locked ? "Feststelltaste ist aktiv" : ""].filter(part => part !== "").join(" · ")
            font.family: root.sans
            font.pixelSize: 18 * root.unit
            color: root.message !== "" ? "#ffb4b4" : "#ccffffff"
        }
    }

    // ---------------------------------------------------------------- Stil «hyprlock»
    HyprlockView {
        id: hview
        anchors.fill: parent
        visible: root.hypr
        enabled: root.hypr
        custom: root.customLayout
        now: root.now
        userName: root.userName
        localeName: root.localeName
        effects: root.effects
        busy: authenticator.busy || root.pending !== ""
        attempts: root.attempts
        failMessage: root.message
        capsLock: !!(capsLock.item && capsLock.item.locked)
        fallbackSans: root.sans
        slabFamily: slab.status === FontLoader.Ready ? slab.font.family : ""
        onSubmitted: root.submit()
    }

    // Ein Klick irgendwohin gibt dem Passwortfeld den Fokus zurück.
    MouseArea {
        anchors.fill: parent
        z: -1
        onPressed: mouse => {
            root.entry.forceActiveFocus();
            mouse.accepted = false;
        }
    }

    Loader {
        id: capsLock
        source: Qt.resolvedUrl("CapsLock.qml")
    }

    Component.onCompleted: {
        entry.forceActiveFocus();
        authenticator.startAuthenticating();
    }
}
