pragma Singleton
import QtQuick
QtObject { function getFocusedScreen() { return null } property bool isKwin: true; property bool isNiri: false; property bool isHyprland: false; property bool isMango: false; property string displayName: "KWin"; property bool supportsWindowRules: false; property bool supportsLayoutConfig: false; property bool supportsInputConfig: false; property bool supportsPointerConfig: false }
