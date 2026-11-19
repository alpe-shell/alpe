import QtQuick
SettingsRow { property string text; property string description; property bool checked; property alias accessory: acc.data; signal toggled(bool checked); title: text; subtitle: description; Item { id: acc } }
