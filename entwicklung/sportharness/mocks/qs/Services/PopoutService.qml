pragma Singleton
import QtQuick
QtObject {
    property var dashOpened: []
    function openDankDash(tab) { dashOpened = dashOpened.concat([tab]) }
    function openSettingsWithTab(tab) {}
}
