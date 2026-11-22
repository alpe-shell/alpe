import QtQuick
import qs.Common
import qs.Alpe.Widgets

// Team im Kopf des Spieldetails: grosses Logo, Name, Bilanz (NBA) und Stern fuer Favoriten.
Column {
    id: root

    property var team: null
    property string sport: "soccer"
    property bool favorite: false

    signal toggle

    spacing: Theme.spacingXS

    Crest {
        anchors.horizontalCenter: parent.horizontalCenter
        team: root.team
        size: 52
    }

    StyledText {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        text: root.team?.name ?? ""
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.spacingXS

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: !!root.team?.record
            text: root.team?.record ?? ""
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
        }

        AlpeActionButton {
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: 26
            iconSize: 16
            iconName: "star"
            iconFilled: root.favorite
            iconColor: root.favorite ? Theme.warning : Theme.surfaceVariantText
            tooltipText: root.favorite ? "Nicht mehr folgen" : "Folgen"
            onClicked: root.toggle()
        }
    }
}
