pragma Singleton
import QtQuick
QtObject { property var shown: []; function showError(a, b, c, d) { shown = shown.concat(["ERR " + a + " | " + b]) } function dismissCategory(c) {} function showWarning(a, b, c, d) { shown = shown.concat([a + " | " + b]) } }
