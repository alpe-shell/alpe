import QtQuick
import qs.Alpe.Common

Item {
    width: parent?.width ?? 0
    height: FileBrowserMetrics.menuDividerHeight

    Rectangle {
        anchors.centerIn: parent
        width: parent.width - Style.spacingM * 2
        height: Style.dividerWidth
        color: Style.outlineVariant
    }
}
