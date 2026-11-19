pragma Singleton
import QtQuick
import qs.Common
QtObject { property var availablePluginsList: [{id: "alpeRadar", name: "Niederschlagsradar", version: "1.0.0", icon: "radar"}, {id: "alpeMeteoSwiss", name: "MeteoSchweiz", version: "1.0.0"}, {id: "other", name: "Other"}]; property var loadedPlugins: ({alpeRadar: {}})
  signal pluginDataChanged(string pluginId)
  function getPluginPath(id) { return id === "alpeSport" ? "/opt/alpe/plugins/alpeSport" : "" }
  function savePluginData(id, key, value) { const all = Object.assign({}, SettingsData.pluginSettings); all[id] = Object.assign({}, all[id] ?? {}); all[id][key] = value; SettingsData.pluginSettings = all; pluginDataChanged(id); return true }
  function loadPluginData(id, key, def) { return SettingsData.pluginSettings[id]?.[key] ?? def } }
