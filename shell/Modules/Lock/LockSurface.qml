pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Wayland
import qs.Common
import "Alpe"

FocusScope {
    id: root

    required property WlSessionLock lock
    required property var pam
    required property string sharedPasswordBuffer
    required property string screenName
    property bool inputRevealed: false
    signal inputRevealRequested(bool revealed)

    required property bool isLocked

    signal passwordChanged(string newPassword)
    signal unlockRequested

    HoverHandler {
        enabled: root.pam.awaitingActivityRetry
        onPointChanged: root.pam.retryFprintOnActivity()
    }

    PointHandler {
        onActiveChanged: {
            if (active)
                root.pam.retryFprintOnActivity();
        }
    }

    Keys.onPressed: event => {
        root.pam.retryFprintOnActivity();
        if (videoScreensaver.active && videoScreensaver.inputEnabled) {
            videoScreensaver.dismiss();
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    // Alpe: Sperrbildschirm im Alpe-Design (wie am PC) oder der des Ursprungsprojekts.
    readonly property bool alpe: SettingsData.alpeLockStyle !== "standard"
    readonly property var lockContent: contentLoader.item

    Loader {
        id: contentLoader
        anchors.fill: parent
        active: !root.alpe
        focus: !root.alpe
        sourceComponent: Component {
            LockScreenContent {
                anchors.fill: parent
                demoMode: false
                sessionLock: root.lock
                pam: root.pam
                passwordBuffer: root.sharedPasswordBuffer
                inputRevealed: root.inputRevealed
                onInputRevealRequested: revealed => root.inputRevealRequested(revealed)
                screenName: root.screenName
                enabled: !videoScreensaver.active
                focus: !videoScreensaver.active
                opacity: videoScreensaver.active ? 0 : 1
                onUnlockRequested: root.unlockRequested()
                onPasswordEdited: text => root.passwordChanged(text)

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }
            }
        }
    }

    Loader {
        id: alpeLoader
        anchors.fill: parent
        active: root.alpe
        focus: root.alpe
        enabled: !videoScreensaver.active
        opacity: videoScreensaver.active ? 0 : 1
        sourceComponent: Component {
            AlpeLockSurface {
                pam: root.pam
                screenName: root.screenName
                onUnlockRequested: root.unlockRequested()
                onPasswordEdited: text => root.passwordChanged(text)
            }
        }
    }

    VideoScreensaver {
        id: videoScreensaver
        anchors.fill: parent
        screenName: root.screenName
        onDismissed: Qt.callLater(() => root.alpe ? alpeLoader.item?.reset() : root.lockContent?.focusPasswordField())
    }

    Component.onCompleted: forceActiveFocus()

    onIsLockedChanged: {
        if (isLocked) {
            forceActiveFocus();
            root.lockContent?.resetLockState();
            alpeLoader.item?.reset();
            if (SettingsData.lockScreenVideoEnabled) {
                videoScreensaver.start();
            }
            return;
        }
        if (root.lockContent)
            root.lockContent.unlocking = false;
    }
}
