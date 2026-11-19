import QtQuick
import QtQuick.Effects
import QtQuick.Window
import qs.Common

Item {
    id: root

    property string confirmTitle: ""
    property string confirmMessage: ""
    property string reviewUrl: ""
    property Item returnFocusItem: null
    property string confirmButtonText: I18n.tr("Confirm")
    property string cancelButtonText: I18n.tr("Cancel")
    property bool danger: false
    property var onConfirm: function () {}
    property var onCancel: function () {}
    property real backgroundOpacity: Theme.scrimAlpha
    // Alpe: Was unter dem Dialog liegt, liegt im selben Fenster; die Unschärfe des Compositors
    // reicht nicht hinein. Der Dialog zeichnet deshalb den Inhalt darunter selbst weich: den
    // ersten sichtbaren Geschwister-Baustein (die Seite), sofern nichts anderes angegeben ist.
    property Item blurSource: null
    readonly property Item _blurSource: {
        if (blurSource)
            return blurSource;
        const siblings = parent ? parent.children : [];
        for (let i = 0; i < siblings.length; i++)
            if (siblings[i] !== root && siblings[i].visible && siblings[i].width > 0 && siblings[i].height > 0)
                return siblings[i];
        return null;
    }

    signal dialogClosed

    function show(title, message, onConfirmCallback, onCancelCallback) {
        showWithOptions({
            "title": title,
            "message": message,
            "onConfirm": onConfirmCallback,
            "onCancel": onCancelCallback
        });
    }

    function showWithOptions(options) {
        returnFocusItem = root.Window.window?.activeFocusItem ?? null;
        confirmTitle = options.title || "";
        confirmMessage = options.message || "";
        reviewUrl = options.reviewUrl || "";
        confirmButtonText = options.confirmText || I18n.tr("Confirm");
        cancelButtonText = options.cancelText || I18n.tr("Cancel");
        danger = options.danger === true;
        onConfirm = options.onConfirm || (() => {});
        onCancel = options.onCancel || (() => {});
        visible = true;
        dialogContent.keyboardNavigation = false;
        dialogContent.selectedButton = options.confirmByDefault === true ? 1 : 0;
        focusDialog();
    }

    function focusDialog() {
        if (!visible)
            return;
        overlayFocusScope.forceActiveFocus();
    }

    function close() {
        visible = false;
        const focusItem = returnFocusItem;
        returnFocusItem = null;
        if (focusItem?.visible && focusItem.enabled)
            focusItem.forceActiveFocus(Qt.OtherFocusReason);
        dialogClosed();
    }

    function _activate(button) {
        const cancelCallback = onCancel;
        const confirmCallback = onConfirm;
        close();
        if (button === 0) {
            cancelCallback && cancelCallback();
            return;
        }
        confirmCallback && confirmCallback();
    }

    anchors.fill: parent
    visible: false
    z: 100

    Connections {
        target: root.Window.window
        enabled: root.visible

        function onActiveFocusItemChanged() {
            if (!overlayFocusScope.activeFocus)
                Qt.callLater(root.focusDialog);
        }
    }

    FocusScope {
        id: overlayFocusScope

        anchors.fill: parent
        focus: root.visible

        Keys.onPressed: event => dialogContent.handleKey(event)

        Rectangle {
            anchors.fill: parent
            color: Theme.backdropColor
            opacity: root.backgroundOpacity
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root._activate(0)
        }

        Rectangle {
            id: card
            width: Math.min(Theme.smallBreakpoint, parent.width - Theme.spacingL * 2)
            height: dialogContent.implicitHeight + Theme.spacingL * 2
            anchors.centerIn: parent
            radius: Theme.windowRadius
            color: Theme.foregroundColor(Theme.cardSurface, Theme.isFloatingWindow(root))
            border.color: Theme.outlineMedium
            border.width: Theme.layerOutlineWidth

            // Weichgezeichneter Ausschnitt der Seite unter der Karte
            ShaderEffectSource {
                id: behind
                anchors.fill: parent
                visible: false
                live: root.visible
                sourceItem: root.visible ? root._blurSource : null
                sourceRect: {
                    const src = root._blurSource;
                    if (!src || !root.visible)
                        return Qt.rect(0, 0, 0, 0);
                    card.x;
                    card.y;
                    const p = src.mapFromItem(card, 0, 0);
                    return Qt.rect(p.x, p.y, card.width, card.height);
                }
            }

            // Deckende Grundfläche: Die Seite selbst ist durchsichtig, ohne sie schiene die
            // scharfe Schrift durch.
            Rectangle {
                anchors.fill: parent
                z: -2
                visible: root.visible && root._blurSource !== null
                radius: card.radius
                color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 1)
            }

            MultiEffect {
                anchors.fill: parent
                z: -1
                visible: root.visible && root._blurSource !== null
                source: behind
                autoPaddingEnabled: false
                blurEnabled: true
                blurMax: 48
                blur: 1
                saturation: 0.1
                maskEnabled: true
                maskSource: cardMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }

            Item {
                id: cardMask
                anchors.fill: parent
                layer.enabled: true
                visible: false
                Rectangle {
                    anchors.fill: parent
                    radius: card.radius
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
            }

            ConfirmDialogContent {
                id: dialogContent

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: Theme.spacingL
                anchors.rightMargin: Theme.spacingL
                anchors.topMargin: Theme.spacingL
                confirmTitle: root.confirmTitle
                confirmMessage: root.confirmMessage
                reviewUrl: root.reviewUrl
                confirmButtonText: root.confirmButtonText
                cancelButtonText: root.cancelButtonText
                danger: root.danger
                onButtonActivated: button => root._activate(button)
                onCancelled: root._activate(0)
            }
        }
    }
}
