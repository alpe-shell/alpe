import QtQuick
Item {
    property alias name: icon.text
    property alias size: icon.font.pixelSize
    property alias color: icon.color
    property bool filled: false
    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight
    width: icon.font.pixelSize
    height: icon.font.pixelSize
    Text { id: icon; anchors.centerIn: parent; font.family: "Material Symbols Rounded"; font.variableAxes: { "FILL": parent.filled ? 1 : 0 }; font.pixelSize: 24; renderType: Text.QtRendering }
}
