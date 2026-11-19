import QtQuick
QtObject { property var parentModal; property string browserTitle; property string bucket; property var filters: []; property string mode; property bool showHiddenFiles; signal accepted(var paths); property int opened: 0; function open() { opened++ } }
