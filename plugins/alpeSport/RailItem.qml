import QtQuick
import qs.Common
import qs.DCommon.Widgets

// Eintrag der linken Leiste: Symbol oder Logo, Name, Zaehler fuer laufende Spiele.
Item {
    id: root

    property string icon: ""
    property var league: null
    property string text: ""
    property string badge: ""
    property color badgeColor: Theme.primary
    property bool active: false
    property bool compact: false

    signal clicked

    implicitHeight: 38
    height: 38

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadiusS
        color: root.active ? Theme.primaryContainer : mouse.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.07) : "transparent"
    }

    Item {
        id: lead

        anchors.left: parent.left
        anchors.leftMargin: root.compact ? (root.width - width) / 2 : Theme.spacingS
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 22

        DIcon {
            anchors.centerIn: parent
            visible: root.league === null
            name: root.icon
            size: 20
            filled: root.active
            color: root.active ? Theme.onPrimaryContainer : Theme.surfaceVariantText
        }

        LeagueIcon {
            anchors.centerIn: parent
            visible: root.league !== null
            league: root.league ?? ({})
            size: 20
            tint: root.active ? Theme.onPrimaryContainer : Theme.surfaceVariantText
        }
    }

    StyledText {
        anchors.left: lead.right
        anchors.leftMargin: Theme.spacingS
        anchors.right: badgeBox.visible ? badgeBox.left : parent.right
        anchors.rightMargin: badgeBox.visible ? Theme.spacingXS : Theme.spacingS
        anchors.verticalCenter: parent.verticalCenter
        visible: !root.compact
        elide: Text.ElideRight
        text: root.text
        font.pixelSize: Theme.fontSizeSmall + 1
        font.weight: root.active ? Font.DemiBold : Font.Normal
        color: root.active ? Theme.onPrimaryContainer : Theme.surfaceText
    }

    Rectangle {
        id: badgeBox

        anchors.right: parent.right
        anchors.rightMargin: root.compact ? 2 : Theme.spacingS
        anchors.verticalCenter: root.compact ? undefined : parent.verticalCenter
        anchors.top: root.compact ? parent.top : undefined
        anchors.topMargin: 2
        visible: root.badge !== ""
        width: Math.max(18, badgeText.implicitWidth + 8)
        height: 18
        radius: 9
        color: root.badgeColor

        StyledText {
            id: badgeText

            anchors.centerIn: parent
            text: root.badge
            font.pixelSize: Theme.fontSizeSmall - 1
            font.weight: Font.Bold
            color: Theme.surface
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
