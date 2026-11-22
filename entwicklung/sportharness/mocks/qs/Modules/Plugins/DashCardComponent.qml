import QtQuick
import qs.Common
// Attrappe von DashCardComponent (Card/AlpeCard): Inhalt in einem gepolsterten Feld.
Rectangle {
    property string pluginId: "alpeSport"
    property bool live: true
    property bool clickable: true
    property real pad: 12
    property var pluginData: ({ "favorites": ["hockey:101144", "soccer:132"] })
    property var options: ({})
    property color accentColor: Theme.primary
    property color contentColor: Theme.surfaceText
    default property alias content: inner.data
    radius: 16
    color: Theme.surfaceContainerHigh
    Item { id: inner; anchors.fill: parent; anchors.margins: parent.pad }
}
