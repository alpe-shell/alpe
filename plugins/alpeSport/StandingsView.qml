import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "sport.js" as S

// Tabelle eines Wettbewerbs (NBA: zwei Conferences). Zonen links als Farbstreifen, rechts die Form.
Column {
    id: root

    property var table: null
    property string sport: "soccer"
    property var favorites: []
    property var highlight: []
    property bool footer: true              // Legende und Hinweis (aus im Spieldetail)            // Team-IDs, z. B. die beiden Teams des gewaehlten Spiels

    readonly property bool compact: width < 520
    readonly property bool showForm: width >= 600 && (table?.groups ?? []).some(g => g.rows.some(r => (r.form ?? []).length > 0))
    readonly property var columns: {
        const all = table?.columns ?? [];
        if (!compact)
            return all;
        const keep = ["gp", "gd", "pts", "pct", "gb", "w", "l"];
        return all.filter(c => keep.indexOf(c.key) >= 0 && !(sport !== "basketball" && (c.key === "w" || c.key === "l")));
    }
    readonly property var zones: {
        const seen = {};
        const out = [];
        for (const g of table?.groups ?? []) {
            for (const r of g.rows) {
                if (r.zone && !seen[r.zone.kind + r.zone.label]) {
                    seen[r.zone.kind + r.zone.label] = true;
                    out.push(r.zone);
                }
            }
        }
        return out;
    }

    signal toggleFavorite(var team)

    function zoneColor(kind) {
        switch (kind) {
        case "cl":
        case "up":
            return Theme.primary;
        case "el":
        case "playin":
            return Theme.tertiary;
        case "ecl":
            return Theme.secondary;
        case "relplay":
            return Theme.warning;
        case "rel":
            return Theme.error;
        }
        return Theme.outline;
    }

    function cellWidth(column) {
        return column.wide ? 54 : 32;
    }

    spacing: Theme.spacingS

    Repeater {
        model: root.table?.groups ?? []

        Column {
            id: group

            required property var modelData

            width: root.width
            spacing: 0

            StyledText {
                visible: group.modelData.name !== ""
                text: group.modelData.name
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                color: Theme.surfaceText
                bottomPadding: Theme.spacingXS
                topPadding: Theme.spacingXS
            }

            // Kopfzeile
            Item {
                width: parent.width
                height: 26

                StyledText {
                    x: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    text: "#"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    x: 40
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Team"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: root.columns

                        StyledText {
                            required property var modelData

                            width: root.cellWidth(modelData)
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData.label
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                    }

                    StyledText {
                        visible: root.showForm
                        width: 5 * 20 + Theme.spacingS
                        horizontalAlignment: Text.AlignHCenter
                        text: "Form"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }
            }

            Repeater {
                model: group.modelData.rows

                Item {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool fav: root.favorites.indexOf(S.teamKey(root.sport, modelData.team)) >= 0
                    readonly property bool marked: root.highlight.indexOf(modelData.team.id) >= 0
                    readonly property bool zoneBreak: index > 0 && (group.modelData.rows[index - 1].zone?.kind ?? "") !== (modelData.zone?.kind ?? "")

                    width: group.width
                    height: 34

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.cornerRadiusXS
                        color: row.marked ? Theme.withAlpha(Theme.primary, 0.14) : row.fav ? Theme.withAlpha(Theme.warning, 0.08) : rowMouse.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.05) : "transparent"
                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        visible: row.zoneBreak
                        color: Theme.outlineVariant
                    }

                    Rectangle {
                        id: rank

                        x: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 20
                        radius: 6
                        color: row.modelData.zone ? root.zoneColor(row.modelData.zone.kind) : "transparent"

                        StyledText {
                            anchors.centerIn: parent
                            text: row.modelData.rank
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.DemiBold
                            font.features: {
                                "tnum": 1
                            }
                            color: row.modelData.zone ? Theme.surface : Theme.surfaceText
                        }
                    }

                    Crest {
                        id: crest

                        x: 40
                        anchors.verticalCenter: parent.verticalCenter
                        team: row.modelData.team
                        size: 20
                    }

                    StyledText {
                        anchors.left: crest.right
                        anchors.leftMargin: Theme.spacingS
                        anchors.right: cells.left
                        anchors.rightMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: (root.compact ? row.modelData.team.short : row.modelData.team.name) || row.modelData.team.name
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: row.marked || row.fav ? Font.DemiBold : Font.Normal
                        color: Theme.surfaceText
                    }

                    Row {
                        id: cells

                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter

                        Repeater {
                            model: root.columns

                            StyledText {
                                required property var modelData

                                width: root.cellWidth(modelData)
                                horizontalAlignment: Text.AlignHCenter
                                text: row.modelData.cells[modelData.key] ?? ""
                                font.pixelSize: Theme.fontSizeSmall + 1
                                font.weight: modelData.strong ? Font.Bold : Font.Normal
                                font.features: {
                                    "tnum": 1
                                }
                                color: modelData.strong ? Theme.surfaceText : Theme.surfaceTextMedium
                            }
                        }

                        Item {
                            visible: root.showForm
                            width: 5 * 20 + Theme.spacingS
                            height: 20

                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Repeater {
                                    model: row.modelData.form ?? []

                                    Rectangle {
                                        required property var modelData

                                        width: 18
                                        height: 18
                                        radius: 5
                                        color: modelData.r === "S" ? Theme.success : modelData.r === "N" ? Theme.error : Theme.outline

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: parent.modelData.r
                                            font.pixelSize: Theme.fontSizeSmall - 1
                                            font.weight: Font.Bold
                                            color: Theme.surface
                                        }
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.RightButton
                        onClicked: root.toggleFavorite(row.modelData.team)
                    }
                }
            }
        }
    }

    // Legende der Zonen
    Flow {
        width: root.width
        spacing: Theme.spacingM
        topPadding: Theme.spacingXS
        visible: root.footer && root.zones.length > 0

        Repeater {
            model: root.zones

            Row {
                required property var modelData

                spacing: Theme.spacingXS

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10
                    height: 10
                    radius: 3
                    color: root.zoneColor(parent.modelData.kind)
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.modelData.label
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }
        }
    }

    StyledText {
        width: root.width
        wrapMode: Text.WordWrap
        visible: root.footer
        text: "Rechtsklick auf ein Team: als Favorit markieren"
        font.pixelSize: Theme.fontSizeSmall - 1
        color: Theme.withAlpha(Theme.surfaceVariantText, 0.7)
    }
}
