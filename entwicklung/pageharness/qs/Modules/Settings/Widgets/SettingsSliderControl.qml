import QtQuick
Item { property real value; property int minimum; property int maximum; property string unit; signal sliderValueChanged(int newValue); signal sliderDragFinished(int finalValue) }
