import QtQuick
import qs.Common
import qs.Alpe.Widgets

// Statistikzeile wie bei FotMob: Wert | Bezeichnung | Wert, darunter zwei Balken von der Mitte aus.
// Ballbesitz (split) als ein geteilter Balken.
Column {
    id: root

    property var stat: ({})
    property bool split: false

    readonly property real hv: Math.max(0, Number(stat.hv) || 0)
    readonly property real av: Math.max(0, Number(stat.av) || 0)
    readonly property real total: hv + av
    readonly property bool homeLeads: hv > av
    readonly property bool awayLeads: av > hv

    spacing: 4

    Item {
        width: parent.width
        height: label.implicitHeight

        StyledText {
            anchors.left: parent.left
            text: root.stat.home ?? ""
            font.pixelSize: Theme.fontSizeSmall + 1
            font.weight: root.homeLeads ? Font.Bold : Font.Normal
            font.features: {
                "tnum": 1
            }
            color: root.homeLeads ? Theme.surfaceText : Theme.surfaceVariantText
        }

        StyledText {
            id: label

            anchors.horizontalCenter: parent.horizontalCenter
            text: root.stat.label ?? ""
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }

        StyledText {
            anchors.right: parent.right
            text: root.stat.away ?? ""
            font.pixelSize: Theme.fontSizeSmall + 1
            font.weight: root.awayLeads ? Font.Bold : Font.Normal
            font.features: {
                "tnum": 1
            }
            color: root.awayLeads ? Theme.surfaceText : Theme.surfaceVariantText
        }
    }

    // geteilter Balken (Ballbesitz)
    Item {
        width: parent.width
        height: 8
        visible: root.split

        Rectangle {
            anchors.left: parent.left
            width: root.total > 0 ? Math.max(4, (parent.width - 3) * root.hv / root.total) : (parent.width - 3) / 2
            height: parent.height
            radius: 4
            color: Theme.primary
        }

        Rectangle {
            anchors.right: parent.right
            width: root.total > 0 ? Math.max(4, (parent.width - 3) * root.av / root.total) : (parent.width - 3) / 2
            height: parent.height
            radius: 4
            color: Theme.tertiary
        }
    }

    // zwei Balken von der Mitte aus
    Row {
        width: parent.width
        height: 6
        spacing: 4
        visible: !root.split

        Item {
            width: (parent.width - parent.spacing) / 2
            height: parent.height

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: Theme.withAlpha(Theme.surfaceText, 0.07)
            }

            Rectangle {
                anchors.right: parent.right
                width: root.total > 0 ? parent.width * root.hv / root.total : 0
                height: parent.height
                radius: 3
                color: root.homeLeads ? Theme.primary : Theme.withAlpha(Theme.primary, 0.45)
            }
        }

        Item {
            width: (parent.width - parent.spacing) / 2
            height: parent.height

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: Theme.withAlpha(Theme.surfaceText, 0.07)
            }

            Rectangle {
                anchors.left: parent.left
                width: root.total > 0 ? parent.width * root.av / root.total : 0
                height: parent.height
                radius: 3
                color: root.awayLeads ? Theme.tertiary : Theme.withAlpha(Theme.tertiary, 0.45)
            }
        }
    }
}
