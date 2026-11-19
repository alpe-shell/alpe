import QtQuick
QtObject { id: p; property bool running: false; property var command: []; property QtObject stdout: null; signal exited(int exitCode); signal started()
  default property list<QtObject> kids
  onRunningChanged: if (running) Registry.started(p) }
