import QtQuick
SettingsRow { property string text; property real value; property int minimum; property int maximum; property string unit; property int step; signal sliderValueChanged(int newValue); signal sliderDragFinished(int finalValue); property string description; title: text; subtitle: description }
