pragma Singleton
import QtQuick
QtObject { property bool batteryAvailable: false; property int refCount: 0; property var upowerPeripherals: [{name: "Logitech X2 SUPERSTRIKE", percentage: 75, type: 5, icon: "mouse", charging: false}]; function addRef() { refCount++ } function removeRef() { refCount-- } }
