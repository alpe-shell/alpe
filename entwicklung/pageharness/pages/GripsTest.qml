pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets

// Alpe: Griffleisten. Fenster ohne Titelleiste lassen sich sonst nur mit Meta und Maustaste
// bewegen. Das KWin-Skript meldet, wo der obere Rand eines solchen Fensters sichtbar ist
// (KwinService.visibleGrips); hier liegt über jeder dieser Stellen eine schmale, durchsichtige
// Fläche. Ein Druck darauf lässt das Skript das Fenster dem Zeiger nachführen, bis die Taste
// losgelassen wird; am Bildschirmrand rastet es ein. Rechtsklick öffnet ein Fenstermenü.
// Die Flächen sind so klein wie die Leisten selbst: Was immer schiefgeht, mehr als diesen
// Streifen können sie nicht abfangen.
Item {
    id: root

    // Offenes Fenstermenü: {id, output, x, y} oder null
    property var menu: null

    function screenNamed(name) {
        return Quickshell.screens.find(candidate => candidate.name === name) ?? null;
    }

    Variants {
        model: CompositorService.isKwin ? KwinService.visibleGrips : []

        Win {
            id: grip

            required property var modelData
            readonly property var target: root.screenNamed(grip.modelData.output)

            screen: target
            visible: target !== null
            color: "transparent"
            // Wie beim Hinweisfenster der Shell: -1 heisst, die Lage zählt ab dem Bildschirmrand, nicht ab der Leiste.

            implicitWidth: grip.modelData.w
            implicitHeight: grip.modelData.h

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                // Die Hand zeigt, dass hier gezogen wird; gedrückt schliesst sie sich.
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                onPressed: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        root.menu = {
                            "id": grip.modelData.id,
                            "output": grip.modelData.output,
                            "x": grip.modelData.x + mouse.x,
                            "y": grip.modelData.y + mouse.y
                        };
                        return;
                    }
                    KwinService.gripBegin();
                }
                onReleased: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        KwinService.gripEnd();
                }
                onCanceled: KwinService.gripEnd()
            }
        }
    }

    // Vorschau, wohin das Fenster einrastet. Nimmt keine Eingaben an.
    Win {
        id: preview

        readonly property var snap: KwinService.snapPreview
        readonly property var target: snap ? root.screenNamed(snap.output) : null

        screen: target
        visible: CompositorService.isKwin && snap !== null && target !== null
        color: "transparent"
        

        implicitWidth: Math.max(1, preview.snap?.w ?? 1)
        implicitHeight: Math.max(1, preview.snap?.h ?? 1)

        Rectangle {
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            radius: Theme.cornerRadiusL
            color: Theme.withAlpha(Theme.primary, 0.16)
            border.width: 2
            border.color: Theme.withAlpha(Theme.primary, 0.7)
        }
    }

    // Fenstermenü. Eine durchsichtige Fläche über dem Bildschirm schliesst es beim Klick daneben.
    Win {
        id: menuWindow

        readonly property var target: root.menu ? root.screenNamed(root.menu.output) : null
        readonly property var info: root.menu ? KwinService.windowInfo(root.menu.id) : null

        screen: target
        visible: CompositorService.isKwin && root.menu !== null && target !== null
        color: "transparent"

        function run(action) {
            const id = root.menu?.id ?? "";
            root.menu = null;
            if (id !== "")
                KwinService.windowAction(id, action);
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: root.menu = null
        }

        Item {
            anchors.fill: parent
            focus: menuWindow.visible
            Keys.onEscapePressed: root.menu = null
        }

        Rectangle {
            id: card

            readonly property var entries: [["minimize", "minimize", "Minimieren"], ["maximize", menuWindow.info?.maximized ? "close_fullscreen" : "open_in_full", menuWindow.info?.maximized ? "Wiederherstellen" : "Maximieren"], ["above", "vertical_align_top", "Im Vordergrund halten"], ["alldesktops", "select_all", menuWindow.info?.onAllDesktops ? "Nur auf dieser Arbeitsfläche" : "Auf allen Arbeitsflächen"], ["close", "close", "Schliessen"]]

            x: Math.min(Math.max(0, (root.menu?.x ?? 0) - 12), menuWindow.width - width - Theme.spacingS)
            y: Math.min((root.menu?.y ?? 0) + 6, menuWindow.height - height - Theme.spacingS)
            width: 236
            height: column.implicitHeight + Theme.spacingS * 2
            radius: Theme.cornerRadiusL
            color: Theme.surfaceContainerHigh
            border.width: 1
            border.color: Theme.outlineVariant

            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: column
                anchors.fill: parent
                anchors.margins: Theme.spacingS

                StyledText {
                    width: parent.width
                    leftPadding: Theme.spacingS
                    bottomPadding: Theme.spacingXS
                    text: menuWindow.info?.title || menuWindow.info?.appId || ""
                    visible: text !== ""
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                Repeater {
                    model: card.entries

                    Rectangle {
                        id: entry

                        required property var modelData
                        readonly property bool danger: modelData[0] === "close"

                        width: column.width
                        height: 34
                        radius: Theme.cornerRadius
                        color: hover.containsMouse ? (danger ? Theme.withAlpha(Theme.error, 0.16) : Theme.surfaceTextHover) : "transparent"

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.spacingS
                            spacing: Theme.spacingS

                            DIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: entry.modelData[1]
                                size: 18
                                color: entry.danger ? Theme.error : Theme.surfaceText
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: entry.modelData[2]
                                font.pixelSize: Theme.fontSizeMedium
                                color: entry.danger ? Theme.error : Theme.surfaceText
                            }
                        }

                        MouseArea {
                            id: hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: menuWindow.run(entry.modelData[0])
                        }
                    }
                }
            }
        }
    }
}
