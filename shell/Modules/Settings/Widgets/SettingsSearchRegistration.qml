import QtQuick
import qs.Services
import "../../../Common/QmlUtils.js" as QmlUtils

QtObject {
    id: root

    required property Item target
    property string settingKey: ""

    // Wird die Karte abgebaut (auch eine abgebrochene asynchrone Erzeugung), setzt Qt
    // `target` auf null, während die Bindungen noch ausgewertet werden.
    readonly property Item flickable: target ? QmlUtils.findParentFlickable(target.parent) : null
    readonly property bool pageVisible: flickable?.visible ?? false

    function sync() {
        if (!settingKey || !target)
            return;
        if (!pageVisible) {
            SettingsSearchService.unregisterCard(settingKey, target);
            return;
        }
        SettingsSearchService.registerCard(settingKey, target, flickable, QmlUtils.findParentCollapsible(target.parent));
    }

    onPageVisibleChanged: Qt.callLater(sync)

    Component.onDestruction: {
        if (settingKey)
            SettingsSearchService.unregisterCard(settingKey, target);
    }
}
