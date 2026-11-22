pragma Singleton
import QtQuick
QtObject {
    property var dashOpened: []
    function openDash(tab) { dashOpened = dashOpened.concat([tab]) }
    function openSettingsWithTab(tab) {}
}
