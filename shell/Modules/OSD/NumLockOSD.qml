import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

AlpeOSD {
    id: root

    osdKind: "numLock"

    osdWidth: Theme.osdHeight
    osdHeight: Theme.osdHeight
    autoHideInterval: 2000
    enableMouseInteraction: false

    readonly property bool currentNumLockState: ShellBackend.numLockState
    property bool lastNumLockState: false
    property bool stateInitialized: false

    onCurrentNumLockStateChanged: {
        if (stateInitialized && ShellBackend.evdevStateInitialized && lastNumLockState !== currentNumLockState && SettingsData.osdNumLockEnabled)
            root.show();
        lastNumLockState = currentNumLockState;
    }

    Component.onCompleted: {
        lastNumLockState = currentNumLockState;
        stateInitialized = true;
    }

    content: Item {
        OsdIcon {
            tonal: false
            anchors.centerIn: parent
            iconName: "dialpad"
            iconColor: root.currentNumLockState ? Theme.primary : Theme.outline
        }
    }
}
