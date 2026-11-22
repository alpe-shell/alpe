import QtQuick
Item { property string text; property string variant; property bool danger; property var tooltipText; property string iconName; property int buttonHeight; property bool busy; property color backgroundColor; property color textColor; signal clicked(); readonly property bool isButton: true }
