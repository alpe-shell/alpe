pragma Singleton
import QtQuick
// runCommand: Aufrufe werden gesammelt; ein Test kann mit responder(cmd, callback) antworten.
QtObject { property string backendBin: "/usr/bin/alpe-dienst"; property var calls: []; property var responder: null
  function runCommand(id, command, callback, debounceMs, timeoutMs, owner) { calls = calls.concat([command]); if (responder) responder(command, callback) }
  function release(id) {} }
