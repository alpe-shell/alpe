pragma Singleton
import QtQuick
// Dunkles Material-3-Schema wie aus matugen, Abstaende und Schriften wie in Alpe.
QtObject {
    function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    property color surface: "#111318"
    property color surfaceContainer: "#1d2024"
    property color surfaceContainerHigh: "#272a2f"
    property color surfaceContainerHighest: "#32353a"
    property color primary: "#a8c7fa"
    property color onPrimary
    property color primaryContainer: "#284777"
    property color onPrimaryContainer
    Component.onCompleted: { onPrimary = "#0a305f"; onPrimaryContainer = "#d6e3ff" }
    property color secondary: "#bec6dc"
    property color tertiary: "#ddbce0"
    property color success: "#81c995"
    property color warning: "#f2c35b"
    property color error: "#ffb4ab"
    property color outline: "#8e9099"
    property color outlineVariant: "#44474e"
    property color surfaceText: "#e2e2e9"
    property color surfaceTextMedium: "#c9cbd3"
    property color surfaceVariantText: "#a9acb6"
    property real spacingXS: 4
    property real spacingS: 8
    property real spacingM: 12
    property real spacingL: 16
    property real spacingXL: 24
    property real cornerRadiusXS: 6
    property real cornerRadiusS: 10
    property real cornerRadius: 16
    property real fontSizeSmall: 12
    property real fontSizeMedium: 14
    property real fontSizeLarge: 16
    property real fontSizeXLarge: 20
    property real fontSizeXXLarge: 24
}
