pragma Singleton
import QtQuick
QtObject {
    property var stored: ({})
    function storedOptions(id) { return stored[id] ?? {} }
    function setOption(id, key, value) { const all = Object.assign({}, stored); all[id] = Object.assign({}, all[id] ?? {}); all[id][key] = value; stored = all }
}
