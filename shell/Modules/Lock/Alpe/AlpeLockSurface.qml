pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Common
import qs.Services

// Alpe: der Sperrbildschirm des PCs für die eigene Sperre der Shell (Hyprland, Niri …).
// Dieselbe Ansicht (HyprlockView.qml) und dasselbe Layout-Format wie das KDE-Design; das Layout
// steht hier in den Einstellungen der Shell (alpeLockLayout), gestaltet auf der Seite
// «Sperrbildschirm gestalten». Angemeldet wird über die PAM-Anbindung der Shell (Pam.qml).
FocusScope {
    id: root

    required property var pam
    property string screenName: ""
    signal unlockRequested
    signal passwordEdited(string text)

    property int attempts: 0
    property date now: new Date()

    readonly property var custom: {
        const text = String(SettingsData.alpeLockLayout || "");
        if (text === "")
            return null;
        try {
            const parsed = JSON.parse(text);
            return parsed && parsed.widgets ? parsed : null;
        } catch (e) {
            return null;
        }
    }
    readonly property var bg: view.layout.background || ({})
    readonly property real blurPx: (bg.blurRadius !== undefined ? bg.blurRadius : (bg.blurPasses > 0 ? (bg.blurSize || 7) * Math.pow(2, bg.blurPasses) * 3 : 0)) * view.unit
    readonly property string wallPath: {
        if (bg.source === "image" && bg.image)
            return String(bg.image);
        const image = String(SessionData.getMonitorWallpaperImage(screenName) || "");
        return VideoWallpaperService.isVideo(image) ? "" : image.replace(/^file:\/\//, "");
    }

    function reset() {
        view.text = "";
        view.forceActiveFocus();
    }

    function submit() {
        if (view.text.length === 0) {
            if (!view.ignoreEmpty)
                view.shake();
            return;
        }
        root.pam.buffer = view.text;
        root.pam.submitPassword();
    }

    Connections {
        target: root.pam

        function onUnlockRequested() {
            root.passwordEdited("");
            root.unlockRequested();
        }

        function onStateChanged() {
            if (root.pam.state === "")
                return;
            root.attempts += 1;
            view.failMessage = root.pam.state === "max" ? "Zu viele Versuche" : root.pam.state === "error" ? "Anmeldung gestört" : "Falsches Passwort";
            view.text = "";
            view.fail();
            view.shake();
        }
    }

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Rectangle {
        anchors.fill: parent
        color: root.wallPath.startsWith("#") ? root.wallPath : "#1b2330"
    }

    Image {
        id: wall
        anchors.fill: parent
        visible: false
        source: root.wallPath !== "" && !root.wallPath.startsWith("#") ? "file://" + root.wallPath : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        // Ein Bild in Bildschirmgrösse reicht; mehr kostet nur Speicher.
        sourceSize.width: Math.max(1, root.width)
        sourceSize.height: Math.max(1, root.height)
    }

    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: wall.status === Image.Ready
        autoPaddingEnabled: false
        blurEnabled: root.blurPx > 0
        blurMax: 64
        blur: Math.min(1, root.blurPx / 64)
        blurMultiplier: Math.max(0, root.blurPx / 64 - 1)
        saturation: root.bg.vibrancy || 0
        contrast: (root.bg.contrast === undefined ? 1 : root.bg.contrast) - 1
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, Math.max(0, Math.min(1, 1 - (root.bg.brightness === undefined ? 0.8 : root.bg.brightness))))
    }

    FontLoader {
        id: slab
        source: Qt.resolvedUrl("fonts/AlfaSlabOne-Regular.ttf")
    }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-Regular.ttf") }
    FontLoader { source: Qt.resolvedUrl("fonts/JetBrainsMono-ExtraBold.ttf") }

    HyprlockView {
        id: view
        anchors.fill: parent
        focus: true
        custom: root.custom
        now: root.now
        userName: Quickshell.env("USER") || ""
        localeName: SettingsData.alpeLockLocale || ""
        effects: true
        busy: !!(root.pam.unlockInProgress || root.pam.responseSubmitted)
        attempts: root.attempts
        fallbackSans: Theme.fontFamily || "Noto Sans"
        slabFamily: slab.status === FontLoader.Ready ? slab.font.family : ""
        onSubmitted: root.submit()
        onTextChanged: root.passwordEdited(view.text)
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onPressed: mouse => {
            view.forceActiveFocus();
            mouse.accepted = false;
        }
    }

    Component.onCompleted: view.forceActiveFocus()
}
