import QtQuick
import qs.Common
import qs.Alpe.Widgets

SettingsRow {
    id: root

    property string url: ""

    resetKeys: []
    clickable: url !== ""
    onClicked: Qt.openUrlExternally(url)

    AlpeIcon {
        anchors.verticalCenter: parent.verticalCenter
        name: "open_in_new"
        size: Theme.iconSize
        color: root.supportingContentColor
    }
}
