import QtQuick
import qs.Common
import qs.Alpe.Widgets
import "sport.js" as S

// Ein Ereignis im Verlauf: Heim links, Gast rechts, Minute in der Mitte. Pausen als Trenner.
Item {
    id: root

    property var event: ({})
    property string sport: "soccer"

    readonly property bool divider: event.type === "half" || event.type === "fulltime"
    readonly property bool home: event.side === "home"
    readonly property bool goal: event.type === "goal" || event.type === "penalty" || event.type === "owngoal"

    implicitHeight: divider ? 34 : Math.max(40, content.implicitHeight + Theme.spacingS)
    height: implicitHeight

    // Trenner «Pause 1:0»
    Item {
        anchors.fill: parent
        visible: root.divider

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 1
            color: Theme.outlineVariant
        }

        Rectangle {
            anchors.centerIn: parent
            width: dividerText.implicitWidth + Theme.spacingL
            height: 22
            radius: 11
            color: Theme.surfaceContainerHighest

            StyledText {
                id: dividerText

                anchors.centerIn: parent
                text: (root.event.player ?? "") + (root.event.score ? "  " + root.event.score : "")
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }
        }
    }

    // Minute
    Rectangle {
        id: minute

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        visible: !root.divider
        width: Math.max(40, minuteText.implicitWidth + Theme.spacingS)
        height: 22
        radius: 11
        color: root.goal ? Theme.withAlpha(Theme.primary, 0.16) : "transparent"

        StyledText {
            id: minuteText

            anchors.centerIn: parent
            text: root.event.minute ?? ""
            font.pixelSize: Theme.fontSizeSmall
            font.weight: root.goal ? Font.DemiBold : Font.Normal
            font.features: {
                "tnum": 1
            }
            color: root.goal ? Theme.primary : Theme.surfaceVariantText
        }
    }

    Row {
        id: content

        visible: !root.divider
        anchors.verticalCenter: parent.verticalCenter
        layoutDirection: root.home ? Qt.RightToLeft : Qt.LeftToRight
        x: root.home ? 0 : minute.x + minute.width + Theme.spacingS
        width: root.width / 2 - minute.width / 2 - Theme.spacingS
        spacing: Theme.spacingS

        // Symbol
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20

            AlpeIcon {
                anchors.centerIn: parent
                visible: S.eventIcon(root.event.type, root.sport) !== ""
                name: S.eventIcon(root.event.type, root.sport)
                size: 18
                filled: root.goal
                color: root.event.type === "owngoal" || root.event.type === "penmiss" ? Theme.error : root.goal ? Theme.surfaceText : root.event.type === "sub" ? Theme.primary : Theme.surfaceVariantText
            }

            Rectangle {
                anchors.centerIn: parent
                visible: root.event.type === "yellow" || root.event.type === "yellowred"
                anchors.horizontalCenterOffset: root.event.type === "yellowred" ? -3 : 0
                width: 11
                height: 15
                radius: 2
                color: "#f5c518"
            }

            Rectangle {
                anchors.centerIn: parent
                visible: root.event.type === "red" || root.event.type === "yellowred"
                anchors.horizontalCenterOffset: root.event.type === "yellowred" ? 3 : 0
                anchors.verticalCenterOffset: root.event.type === "yellowred" ? 2 : 0
                width: 11
                height: 15
                radius: 2
                color: "#e53935"
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: content.width - 28
            spacing: 0

            Row {
                anchors.right: root.home ? parent.right : undefined
                spacing: Theme.spacingXS
                layoutDirection: root.home ? Qt.RightToLeft : Qt.LeftToRight

                AlpeIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.event.type === "sub"
                    name: "arrow_upward"
                    size: 13
                    color: Theme.success
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, content.width - 28 - (scoreChip.visible ? scoreChip.width + Theme.spacingXS : 0) - (root.event.type === "sub" ? 17 : 0))
                    elide: Text.ElideRight
                    text: root.event.player ?? ""
                    font.pixelSize: Theme.fontSizeSmall + 1
                    font.weight: root.goal ? Font.DemiBold : Font.Normal
                    color: Theme.surfaceText
                }

                Rectangle {
                    id: scoreChip

                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.goal && !!root.event.score
                    width: scoreLabel.implicitWidth + Theme.spacingS
                    height: 18
                    radius: 5
                    color: Theme.withAlpha(Theme.surfaceText, 0.08)

                    StyledText {
                        id: scoreLabel

                        anchors.centerIn: parent
                        text: root.event.score ?? ""
                        font.pixelSize: Theme.fontSizeSmall - 1
                        font.weight: Font.DemiBold
                        color: Theme.surfaceText
                    }
                }
            }

            Row {
                anchors.right: root.home ? parent.right : undefined
                visible: !!root.event.detail
                spacing: Theme.spacingXS
                layoutDirection: root.home ? Qt.RightToLeft : Qt.LeftToRight

                AlpeIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.event.type === "sub"
                    name: "arrow_downward"
                    size: 13
                    color: Theme.error
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, content.width - 28 - (root.event.type === "sub" ? 17 : 0))
                    elide: Text.ElideRight
                    text: root.event.detail ?? ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }
        }
    }
}
