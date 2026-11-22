import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

AlpeOSD {
    id: root

    osdKind: "capsLock"

    osdWidth: Theme.osdHeight
    osdHeight: Theme.osdHeight
    autoHideInterval: 2000
    enableMouseInteraction: false

    property bool lastCapsLockState: false

    Connections {
        target: ShellBackend

        function onCapsLockStateChanged() {
            if (lastCapsLockState !== ShellBackend.capsLockState && SettingsData.osdCapsLockEnabled) {
                root.show();
            }
            lastCapsLockState = ShellBackend.capsLockState;
        }
    }

    Component.onCompleted: {
        lastCapsLockState = ShellBackend.capsLockState;
    }

    content: Item {
        OsdIcon {
            tonal: false
            anchors.centerIn: parent
            iconName: ShellBackend.capsLockState ? "shift_lock" : "shift_lock_off"
            iconColor: Theme.primary
        }
    }
}
