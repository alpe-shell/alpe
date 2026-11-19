import QtQuick
import QtQuick.Effects
import Quickshell.Io
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.DDash

DashTabComponent {
    id: root

    // Ausschnitt in LV95 (West, Sued, Ost, Nord); das Hilfsprogramm meldet denselben.
    property var extent: [2400000, 1000000, 2920000, 1370000]
    property var frames: []
    property var legend: []
    property int current: 0
    property bool playing: true
    property bool loaded: false
    property string failure: ""
    property real nowMs: Date.now()

    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("radar").toString().replace(/^file:\/\//, ""))
    readonly property int frameCount: Number(options.frames ?? 12) || 12
    readonly property int aheadMinutes: Number(options.ahead ?? 60) || 0
    // Index des juengsten gemessenen Bildes; danach folgt die Hochrechnung.
    readonly property int nowIndex: {
        let last = -1;
        for (let i = 0; i < frames.length; i++) {
            if (!frames[i].forecast)
                last = i;
        }
        return last;
    }
    readonly property bool onForecast: frames[current]?.forecast === true
    readonly property var cities: [
        ["Zürich", 47.3769, 8.5417], ["Bern", 46.948, 7.4474], ["Genf", 46.2044, 6.1432],
        ["Basel", 47.5596, 7.5886], ["Luzern", 47.0502, 8.3093], ["St. Gallen", 47.4245, 9.3767],
        ["Lugano", 46.0037, 8.9511], ["Chur", 46.8508, 9.532], ["Sion", 46.2331, 7.3606],
        ["Lausanne", 46.5197, 6.6323]
    ]

    focusTarget: playButton
    implicitHeight: Math.max(DashMetrics.tabMinHeight, content.implicitHeight + Theme.spacingM * 2)

    onLiveChanged: {
        if (live)
            refresh();
    }
    onFrameCountChanged: {
        if (live)
            refresh();
    }
    onAheadMinutesChanged: {
        if (live)
            refresh();
    }
    Component.onCompleted: {
        if (live)
            refresh();
    }

    // Naeherungsformel von swisstopo, in der Schweiz auf etwa einen Meter genau.
    function lv95(latitude, longitude) {
        const p = (latitude * 3600 - 169028.66) / 10000;
        const q = (longitude * 3600 - 26782.5) / 10000;
        return {
            east: 2600072.37 + 211455.93 * q - 10938.51 * q * p - 0.36 * q * p * p - 44.54 * q * q * q,
            north: 1200147.07 + 308807.95 * p + 3745.25 * q * q + 76.63 * p * p - 194.56 * q * q * p + 119.79 * p * p * p
        };
    }

    function refresh() {
        if (updater.running)
            return;
        updater.command = [root.helper, "update", "--frames", String(root.frameCount), "--ahead", String(root.aheadMinutes)];
        updater.running = true;
    }

    function receive(text) {
        let data = null;
        try {
            data = JSON.parse(text.trim());
        } catch (error) {
            data = null;
        }
        if (!data || data.error || !Array.isArray(data.frames) || data.frames.length === 0) {
            // Ein Fehler beim Nachladen laesst den vorhandenen Film stehen.
            failure = data?.error ?? I18n.trFor(pluginId, "Das Radar-Hilfsprogramm hat nicht geantwortet.");
            return;
        }
        failure = "";
        const wasNow = !loaded || current === nowIndex;
        if (Array.isArray(data.extent) && data.extent.length === 4)
            extent = data.extent;
        legend = Array.isArray(data.legend) ? data.legend : [];
        frames = data.frames;
        if (wasNow || current >= frames.length)
            current = Math.max(0, nowIndex);
        loaded = true;
        nowMs = Date.now();
    }

    function step(delta) {
        if (frames.length === 0)
            return;
        playing = false;
        current = (current + delta + frames.length) % frames.length;
    }

    function clock(index) {
        const frame = frames[index];
        return frame ? Qt.formatTime(new Date(frame.time), "HH:mm") : "";
    }

    function age(index) {
        const frame = frames[index];
        if (!frame)
            return "";
        const minutes = Math.round((nowMs - new Date(frame.time).getTime()) / 60000);
        if (frame.forecast)
            return minutes >= 0 ? I18n.trFor(pluginId, "Hochrechnung") : I18n.trFor(pluginId, "Hochrechnung · in %1 Min.").arg(-minutes);
        return minutes < 60 ? I18n.trFor(pluginId, "vor %1 Min.").arg(Math.max(0, minutes)) : I18n.trFor(pluginId, "vor %1 Std.").arg(Math.round(minutes / 60));
    }

    function restoreFocus() {
        playButton.forceActiveFocus(Qt.OtherFocusReason);
    }

    function handleKeyEvent(event) {
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier))
            return false;
        switch (event.key) {
        case Qt.Key_Space:
            playing = !playing;
            return true;
        case Qt.Key_Left:
            step(-1);
            return true;
        case Qt.Key_Right:
            step(1);
            return true;
        }
        return false;
    }

    Process {
        id: updater

        stdout: StdioCollector {
            onStreamFinished: root.receive(text)
        }
    }

    // Alle 2 Minuten nachsehen, alle 5 Minuten gibt es ein neues Bild. Nur solange der Tab sichtbar ist.
    Timer {
        interval: 120000
        repeat: true
        running: root.live
        onTriggered: {
            root.nowMs = Date.now();
            root.refresh();
        }
    }

    Timer {
        interval: root.current >= root.frames.length - 1 ? 1800 : 450
        repeat: true
        running: root.live && root.playing && root.frames.length > 1
        onTriggered: root.current = (root.current + 1) % root.frames.length
    }

    Column {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        Rectangle {
            id: map

            function viewX(east) {
                return (east - root.extent[0]) / (root.extent[2] - root.extent[0]) * width;
            }

            function viewY(north) {
                return (root.extent[3] - north) / (root.extent[3] - root.extent[1]) * height;
            }

            width: parent.width
            height: Math.round(width * (root.extent[3] - root.extent[1]) / (root.extent[2] - root.extent[0]))
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh
            clip: true

            Item {
                id: mapLayer

                width: map.width
                height: map.height

                Image {
                    anchors.fill: parent
                    source: Qt.resolvedUrl("map-water.png")
                    opacity: 0.35
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1
                        colorizationColor: Theme.primary
                    }
                }

                Repeater {
                    model: root.frames

                    Image {
                        required property int index
                        required property var modelData

                        anchors.fill: parent
                        source: "file://" + modelData.path
                        smooth: true
                        asynchronous: true
                        visible: index === root.current
                    }
                }

                Image {
                    anchors.fill: parent
                    source: Qt.resolvedUrl("map-lines.png")
                    opacity: 0.7
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1
                        colorizationColor: Theme.surfaceText
                    }
                }
            }

            Repeater {
                model: root.options.cities !== false ? root.cities : []

                Item {
                    id: city

                    required property var modelData
                    readonly property var point: root.lv95(modelData[1], modelData[2])

                    x: map.viewX(point.east)
                    y: map.viewY(point.north)
                    visible: x > 0 && x < map.width && y > 0 && y < map.height

                    Rectangle {
                        width: 4
                        height: 4
                        radius: 2
                        x: -2
                        y: -2
                        color: Theme.surfaceVariantText
                    }

                    StyledText {
                        x: 5
                        y: -height / 2
                        text: city.modelData[0]
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        style: Text.Outline
                        styleColor: Theme.surfaceContainerHigh
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: Theme.spacingS
                visible: root.onForecast
                width: forecastLabel.implicitWidth + Theme.spacingM * 2
                height: forecastLabel.implicitHeight + Theme.spacingXS * 2
                radius: height / 2
                color: Theme.tertiary

                StyledText {
                    id: forecastLabel

                    anchors.centerIn: parent
                    text: I18n.trFor(root.pluginId, "Hochrechnung")
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: Theme.surfaceContainerHigh
                }
            }

            StyledText {
                anchors.centerIn: parent
                width: parent.width - Theme.spacingL * 2
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: !root.loaded
                text: root.failure !== "" ? root.failure : I18n.trFor(root.pluginId, "Radarbilder werden geladen …")
                font.pixelSize: Theme.fontSizeMedium
                color: root.failure !== "" ? Theme.error : Theme.surfaceVariantText
            }

        }

        Item {
            width: parent.width
            height: Math.max(playButton.height, timeColumn.height)

            DActionButton {
                id: playButton

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                iconName: root.playing ? "pause" : "play_arrow"
                iconColor: Theme.surfaceText
                enabled: root.frames.length > 1
                onClicked: root.playing = !root.playing
            }

            Column {
                id: timeColumn

                anchors.left: playButton.right
                anchors.leftMargin: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(clockText.implicitWidth, ageText.implicitWidth, 64)

                NumericText {
                    id: clockText

                    text: root.loaded ? root.clock(root.current) : "--:--"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                StyledText {
                    id: ageText

                    text: root.loaded ? root.age(root.current) : ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            Row {
                id: ticks

                anchors.left: timeColumn.right
                anchors.leftMargin: Theme.spacingM
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 20
                spacing: 2

                Repeater {
                    model: root.frames.length

                    Item {
                        id: tick

                        required property int index

                        width: Math.max(2, (ticks.width - ticks.spacing * (root.frames.length - 1)) / Math.max(1, root.frames.length))
                        height: ticks.height

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: tick.index === root.current ? 8 : 4
                            radius: height / 2
                            readonly property bool ahead: root.frames[tick.index]?.forecast === true

                            color: tick.index === root.current ? (ahead ? Theme.tertiary : Theme.primary) : ahead ? Theme.withAlpha(Theme.tertiary, 0.45) : tick.index < root.current ? Theme.surfaceVariantText : Theme.outlineVariant
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.playing = false;
                                root.current = tick.index;
                            }
                        }
                    }
                }
            }

        }

        Item {
            width: parent.width
            height: Math.max(legendRow.height, sourceText.height)

            Row {
                id: legendRow

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Repeater {
                    model: root.legend

                    Column {
                        id: swatch

                        required property int index
                        required property var modelData

                        spacing: 2

                        Rectangle {
                            width: 30
                            height: 6
                            color: swatch.modelData.color
                        }

                        StyledText {
                            text: swatch.index % 2 === 0 ? String(swatch.modelData.from) : ""
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                    }
                }

                StyledText {
                    leftPadding: Theme.spacingS
                    visible: root.legend.length > 0
                    text: "mm/h"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            StyledText {
                id: sourceText

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.failure !== "" && root.loaded ? root.failure : root.onForecast ? I18n.trFor(root.pluginId, "Eigene Hochrechnung aus Daten von MeteoSchweiz") : I18n.trFor(root.pluginId, "Quelle: MeteoSchweiz")
                font.pixelSize: Theme.fontSizeSmall
                color: root.failure !== "" && root.loaded ? Theme.error : Theme.surfaceVariantText
            }
        }
    }
}
