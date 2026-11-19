pragma Singleton
import QtQuick
QtObject { property string alpeLockLayout: ""; property string alpeLockLocale: ""; property string alpeLockStyle: "auto";  property var settingsHiddenPages: ["auto"]; property bool headsetBatteryEnabled: true; property int headsetBatteryInterval: 120; property bool headsetBatteryNotifyLow: true; property int headsetBatteryLowThreshold: 15; property bool lockAtStartup: false; property bool windowGripEnabled: true; property int windowGripHeight: 8; property int windowGripOutside: 12; property bool windowGripSkipDecorated: true; property bool windowGripSnap: true; property bool lockFollowWallpaper: true; property var windowGripExcluded: []
  property var log: []
  function set(k, v) { log = log.concat([k + "=" + JSON.stringify(v)]); this[k] = v; return true } function hasSetting(k) { return true }
  property var pluginSettings: ({ "alpeSport": { "favorites": ["hockey:101144", "soccer:132"], "favoriteNames": { "hockey:101144": { "name": "EV Zug" } }, "streams": { "nl": { "name": "MySports", "url": "https://www.mysports.ch" } } } })
  function getPluginSettingsForPlugin(id) { return pluginSettings[id] ?? {} } }
