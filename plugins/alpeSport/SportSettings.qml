import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets

// Einstellungen unter «Plugins»: Verweis auf die Alpe-Seite «Sport», wo alles beisammen ist.
Item {
    id: root

    property var pluginService: null

    implicitHeight: column.implicitHeight + Theme.spacingM * 2

    Column {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingM

        StyledText {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Wettbewerbe und Reihenfolge, Favoriten, Mitteilungen bei Toren, das Live-Spiel in der Leiste und die Streamingdienste je Wettbewerb stehen auf der Seite «Sport» (Zeit & Wetter)."
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
        }

        DButton {
            text: "Sport-Einstellungen öffnen"
            iconName: "sports_soccer"
            onClicked: PopoutService.openSettingsWithTab("alpe_sport")
        }
    }
}
