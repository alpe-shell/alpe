pragma Singleton
import QtQuick
QtObject { property bool isConnected: true; property int apiVersion: 40; property var requests: []; signal connectionStateChanged(); signal brightnessStateUpdate(var data); signal brightnessDeviceUpdate(var device); function sendRequest(m, p, cb) { requests = requests.concat([m + " " + JSON.stringify(p)]); } }
