import QtQuick
ListModel { id: m; property var values: []
  function sync() { clear(); for (const v of values || []) append({"modelData": v}) }
  onValuesChanged: sync(); Component.onCompleted: sync() }
