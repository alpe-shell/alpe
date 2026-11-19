pragma Singleton
import QtQuick
// Attrappe: globale Variablen und Plugin-Daten wie Services/PluginService.qml
QtObject {
    property var globalVars: ({})
    property var store: ({ "alpeSport": { "favorites": ["hockey:101144", "soccer:132"] } })
    signal globalVarChanged(string pluginId, string varName)
    signal pluginDataChanged(string pluginId)
    function getGlobalVar(pluginId, name, def) { return globalVars[pluginId] && name in globalVars[pluginId] ? globalVars[pluginId][name] : def }
    function setGlobalVar(pluginId, name, value) {
        const all = Object.assign({}, globalVars); all[pluginId] = Object.assign({}, all[pluginId] ?? {}); all[pluginId][name] = value
        globalVars = all; globalVarChanged(pluginId, name)
    }
    function savePluginData(pluginId, key, value) { const all = Object.assign({}, store); all[pluginId] = Object.assign({}, all[pluginId] ?? {}); all[pluginId][key] = value; store = all; pluginDataChanged(pluginId) }
    function loadPluginData(pluginId, key, def) { return store[pluginId]?.[key] ?? def }
    function getPluginPath(pluginId) { return "" }
}
