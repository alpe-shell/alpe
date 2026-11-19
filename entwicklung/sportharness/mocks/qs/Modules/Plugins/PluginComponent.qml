import QtQuick
// Attrappe von Modules/Plugins/PluginComponent.qml: zeigt die waagrechte Pille direkt an.
Item {
    id: root
    property string pluginId: "alpeSport"
    property var pluginService: null
    property var pluginData: ({ "favorites": ["hockey:101144", "soccer:132"] })
    property real widgetThickness: 30
    property real barThickness: 40
    property int iconSize: 18
    property int textSize: 13
    property Component horizontalBarPill: null
    property Component verticalBarPill: null
    property var pillClickAction: null
    property bool effectiveVisible: true
    function setVisibilityOverride(v) { effectiveVisible = v }
    function clearVisibilityOverride() { effectiveVisible = true }
    function click() { if (pillClickAction) pillClickAction(0, 0, 100, "center", null) }
    implicitWidth: pill.item ? pill.item.implicitWidth : 0
    implicitHeight: widgetThickness
    Loader { id: pill; anchors.verticalCenter: parent.verticalCenter; sourceComponent: root.horizontalBarPill; visible: root.effectiveVisible }
}
