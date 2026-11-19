import QtQuick
// Attrappe: ListView mit dem Mass, das die Seiten zum Zurückscrollen brauchen
ListView { readonly property real maximumContentY: Math.max(originY, contentHeight - height + originY) }
