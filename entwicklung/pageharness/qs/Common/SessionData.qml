pragma Singleton
import QtQuick
QtObject { property string lastBrightnessDevice: "ddc:i2c-5"; property var brightnessUserSetValues: ({}); signal brightnessDisplayHintChanged(string deviceName); function getBrightnessExponential(d) { return false } function getBrightnessExponent(d) { return 1.2 } function setLastBrightnessDevice(d) {} function setBrightnessUserSetValue(d, v) {} function clearBrightnessUserSetValue(d) {} function resolveTerminal() { return "kitty" } property string wallpaperPath: ""; function getMonitorWallpaperImage(n) { return wallpaperPath } }
