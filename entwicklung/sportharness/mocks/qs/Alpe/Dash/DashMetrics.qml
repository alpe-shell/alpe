pragma Singleton
import QtQuick
// Attrappe: Rasterrechnung wie Alpe/Dash/DashMetrics.qml (Spalte 128, Abstand 8, Rand 14),
// dazu die Verbreiterung von Alpe.
QtObject {
    property int minimumTabRows: 2
    property int defaultTabRows: 5
    property int defaultGridColumns: 6
    property int minimumGridColumns: 3
    property int widenedGridColumns: 11
    property var storedColumns: ({})
    property var panelWidening: ({})
    function heightForRows(rows) { return rows * 96 + (rows - 1) * 12 }
    function storedPanelColumns(id) { return storedColumns[id] ?? 0 }
    function widthFor(weekNumbers, screenWidth, columns) { return 128 * columns + 8 * (columns - 1) + 28 }
    function contentWidthFor(weekNumbers, columns) { return widthFor(weekNumbers, undefined, columns) - 28 }
    function panelColumnsFor(id) { return Math.max(storedPanelColumns(id) || defaultGridColumns, panelWidening[id] ?? 0) }
    function widenPanel(id, columns) {
        const wanted = columns > 0 ? Math.max(minimumGridColumns, Math.min(widenedGridColumns, Math.round(columns))) : 0;
        if ((panelWidening[id] ?? 0) === wanted) return;
        const next = Object.assign({}, panelWidening);
        if (wanted > 0) next[id] = wanted; else delete next[id];
        panelWidening = next;
    }
    function columnsForContentWidth(contentWidth, weekNumbers) {
        for (let c = minimumGridColumns; c < widenedGridColumns; c++)
            if (contentWidthFor(weekNumbers, c) >= contentWidth) return c;
        return widenedGridColumns;
    }
}
