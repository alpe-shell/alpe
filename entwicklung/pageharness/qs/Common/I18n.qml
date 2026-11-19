pragma Singleton
import QtQuick
QtObject { function tr(t, c) { return t } function duration(s) { return s >= 3600 ? (s / 3600) + " h" : s >= 60 ? (s / 60) + " min" : s + " s" } function locale() { return Qt.locale("de_CH") } }
