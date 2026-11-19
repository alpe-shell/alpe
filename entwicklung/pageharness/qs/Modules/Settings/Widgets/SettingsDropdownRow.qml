import QtQuick
SettingsRow { property string text; property string description; property string currentValue; property var options: []; property string emptyText; property bool enableFuzzySearch; signal valueChanged(string value); title: text }
