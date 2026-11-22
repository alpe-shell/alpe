import QtQuick
Item {
    id: b
    property string iconName: ""
    property int iconSize: 20
    property color iconColor: "white"
    property bool iconFilled: false
    property int buttonSize: 32
    property var tooltipText: null
    signal clicked
    width: buttonSize; height: buttonSize
    AlpeIcon { anchors.centerIn: parent; name: b.iconName; size: b.iconSize; color: b.iconColor; filled: b.iconFilled }
    MouseArea { anchors.fill: parent; onClicked: b.clicked() }
}
