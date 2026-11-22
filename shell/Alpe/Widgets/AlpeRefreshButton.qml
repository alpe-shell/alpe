import QtQuick
import qs.Alpe.Common

AlpeActionButton {
    id: root

    property bool busy: false

    iconName: busy ? "" : "refresh"
    Accessible.name: tooltipText || I18n.tr("Refresh")
    enabled: !busy

    AlpeSpinner {
        anchors.centerIn: parent
        size: root.iconSize
        strokeWidth: Style.spinnerStrokeWidth
        color: root.iconColor
        running: root.busy && root.visible
        visible: root.busy
    }
}
