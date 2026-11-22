import QtQuick
import qs.Common
import qs.Alpe.Widgets
import "sport.js" as S

// Eine Spielzeile wie bei FotMob: Status | Heim + Logo | Resultat | Logo + Gast
Item {
    id: root

    property var match: ({})
    property bool selected: false
    property bool favorite: false
    property real rowHeight: 44

    readonly property bool live: match.status === "live"
    readonly property bool done: match.status === "post"
    readonly property bool scored: S.hasScore(match)
    readonly property string penalties: S.penaltiesText(match)

    signal clicked

    implicitHeight: rowHeight
    height: rowHeight

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadiusS
        color: root.selected ? Theme.withAlpha(Theme.primary, 0.14) : mouse.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.06) : "transparent"
    }

    Item {
        id: statusBox

        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingS
        anchors.verticalCenter: parent.verticalCenter
        width: 60
        height: parent.height

        Rectangle {
            id: liveDot

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: 3
            visible: root.live
            color: Theme.success

            SequentialAnimation on opacity {
                running: root.live
                loops: Animation.Infinite
                NumberAnimation {
                    to: 0.25
                    duration: 900
                }
                NumberAnimation {
                    to: 1
                    duration: 900
                }
            }
        }

        StyledText {
            anchors.left: root.live ? liveDot.right : parent.left
            anchors.leftMargin: root.live ? 5 : 0
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: root.match.status === "pre" ? "" : S.shortLabel(root.match.label || "")
            font.pixelSize: Theme.fontSizeSmall
            font.weight: root.live ? Font.DemiBold : Font.Normal
            color: root.live ? Theme.success : Theme.surfaceVariantText
        }
    }

    // Mitte: Resultat oder Anstoss
    Item {
        id: center

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: (statusBox.width + Theme.spacingS - trailing.width) / 2
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(64, scoreText.implicitWidth + Theme.spacingL)
        height: parent.height

        Rectangle {
            anchors.centerIn: parent
            width: scoreText.implicitWidth + Theme.spacingM
            height: 24
            radius: Theme.cornerRadiusXS
            color: root.live ? Theme.withAlpha(Theme.success, 0.16) : root.scored ? Theme.withAlpha(Theme.surfaceText, 0.07) : "transparent"
        }

        StyledText {
            id: scoreText

            anchors.centerIn: parent
            anchors.verticalCenterOffset: root.penalties !== "" ? -5 : 0
            text: S.centerText(root.match)
            font.pixelSize: root.scored ? Theme.fontSizeMedium : Theme.fontSizeSmall
            font.weight: root.scored ? Font.Bold : Font.Medium
            font.features: {
                "tnum": 1
            }
            color: root.live ? Theme.success : root.match.status === "canceled" || root.match.status === "postponed" ? Theme.error : Theme.surfaceText
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: scoreText.bottom
            anchors.topMargin: -1
            visible: root.penalties !== ""
            text: root.penalties
            font.pixelSize: Theme.fontSizeSmall - 2
            color: Theme.surfaceVariantText
        }
    }

    // Heim (rechtsbuendig zur Mitte)
    Row {
        anchors.right: center.left
        anchors.rightMargin: Theme.spacingXS
        anchors.left: statusBox.right
        anchors.leftMargin: Theme.spacingXS
        anchors.verticalCenter: parent.verticalCenter
        layoutDirection: Qt.RightToLeft
        spacing: Theme.spacingS

        Crest {
            anchors.verticalCenter: parent.verticalCenter
            team: root.match.home
            size: 22
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, parent.width - 22 - Theme.spacingS)
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            text: root.match.home?.short || root.match.home?.name || ""
            font.pixelSize: Theme.fontSizeMedium
            font.weight: root.done && root.match.home?.winner ? Font.DemiBold : Font.Normal
            color: root.done && root.match.away?.winner ? Theme.surfaceVariantText : Theme.surfaceText
        }
    }

    // Gast
    Row {
        anchors.left: center.right
        anchors.leftMargin: Theme.spacingXS
        anchors.right: trailing.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingS

        Crest {
            anchors.verticalCenter: parent.verticalCenter
            team: root.match.away
            size: 22
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, parent.width - 22 - Theme.spacingS)
            elide: Text.ElideRight
            text: root.match.away?.short || root.match.away?.name || ""
            font.pixelSize: Theme.fontSizeMedium
            font.weight: root.done && root.match.away?.winner ? Font.DemiBold : Font.Normal
            color: root.done && root.match.home?.winner ? Theme.surfaceVariantText : Theme.surfaceText
        }
    }

    Item {
        id: trailing

        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingXS
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: parent.height

        AlpeIcon {
            anchors.centerIn: parent
            visible: root.favorite
            name: "star"
            filled: true
            size: 14
            color: Theme.warning
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
