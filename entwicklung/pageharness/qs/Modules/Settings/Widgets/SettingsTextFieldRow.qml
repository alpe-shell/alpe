import QtQuick
SettingsRow { property string text; property string description; property string value; property string placeholderText; signal valueEdited(string value); signal editingFinished(string value); signal accepted(string value); title: text; subtitle: description }
