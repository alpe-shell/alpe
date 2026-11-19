import QtQuick
// Attrappe mit derselben Oberflaeche wie Modules/Plugins/DashTabComponent.qml
Item {
    property string pluginId: "alpeSport"
    property var pluginService: null
    property string entryId: "plugin_alpeSport"
    property Item focusTarget: null
    property bool editMode: false
    property var menuActions: []
    property bool live: true
    property var pluginData: ({ "favorites": ["hockey:101144", "soccer:132"] })
    property var options: ({})
    function getData(key, def) { return pluginData[key] ?? def }
    function setData(key, value) { const c = Object.assign({}, pluginData); c[key] = value; pluginData = c }
}
