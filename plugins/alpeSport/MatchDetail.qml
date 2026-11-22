import QtQuick
import qs.Common
import qs.Alpe.Widgets
import "sport.js" as S

// Spieldetail: Kopf mit Resultat, dann Reiter Übersicht / Statistik / Aufstellung (NBA: Spieler).
Item {
    id: root

    property var detail: null
    property var preview: null          // Spielzeile, solange das Detail laedt
    property bool loading: false
    property string failure: ""
    property var favorites: []
    property bool overlay: false        // ueber der Liste (schmal) statt daneben
    property var table: null            // Tabelle des Wettbewerbs (falls geladen)
    property var streams: ({})          // Alpe: {liga: {name, url}} aus den Sport-Einstellungen
    readonly property var stream: S.streamFor(streams, match?.league ?? "")

    // Ausschnitt: nur die Gruppe(n) mit den beiden Teams, je die beiden Zeilen und ihre Nachbarn
    readonly property var tableExcerpt: {
        if (!table || !match)
            return null;
        const ids = [match.home?.id, match.away?.id];
        const groups = [];
        for (const g of table.groups ?? []) {
            const rows = g.rows ?? [];
            const keep = new Set();
            rows.forEach((r, i) => {
                if (ids.indexOf(r.team.id) >= 0) {
                    keep.add(i - 1);
                    keep.add(i);
                    keep.add(i + 1);
                }
            });
            const picked = rows.filter((r, i) => keep.has(i));
            if (picked.length > 0)
                groups.push({
                    "name": g.name,
                    "rows": picked
                });
        }
        return groups.length > 0 ? {
            "columns": table.columns,
            "groups": groups
        } : null;
    }

    readonly property var match: detail?.match ?? preview ?? null
    readonly property string sport: match?.sport ?? "soccer"
    readonly property bool live: match?.status === "live"
    readonly property var tabs: {
        const out = [{
                "key": "facts",
                "text": "Übersicht"
            }];
        if ((detail?.stats ?? []).some(x => (Number(x.hv) || 0) > 0 || (Number(x.av) || 0) > 0))
            out.push({
                "key": "stats",
                "text": "Statistik"
            });
        const lu = detail?.lineups ?? {};
        if (sport === "basketball" && Object.keys(detail?.players ?? {}).length > 0)
            out.push({
                "key": "box",
                "text": "Spieler"
            });
        else if ((lu.home && ((lu.home.lines ?? []).length > 0 || (lu.home.blocks ?? []).length > 0)) || (lu.away && ((lu.away.lines ?? []).length > 0 || (lu.away.blocks ?? []).length > 0)))
            out.push({
                "key": "lineup",
                "text": "Aufstellung"
            });
        return out;
    }
    property string tab: "facts"
    readonly property string currentTab: tabs.some(t => t.key === tab) ? tab : "facts"
    property string side: "home"

    signal closeRequested
    signal toggleFavorite(var team)
    signal openLeague(string leagueId)
    signal openTable(string leagueId)
    signal openPlayer(var player)

    function playerClicked(player) {
        if (player?.id)
            root.openPlayer(Object.assign({}, player, {
                "league": root.match?.league ?? ""
            }));
    }

    function resetView() {
        tab = "facts";
        side = "home";
        flick.contentY = 0;
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: root.overlay ? Theme.surfaceContainer : Theme.surfaceContainerHigh

        // Klicks und Mausrad nicht an die Liste darunter durchreichen
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            onWheel: wheel => wheel.accepted = true
        }
    }

    AlpeFlickable {
        id: flick

        anchors.fill: parent
        anchors.margins: Theme.spacingS
        contentWidth: width
        contentHeight: body.implicitHeight + Theme.spacingM
        clip: true

        Column {
            id: body

            width: flick.width
            spacing: Theme.spacingM

            // Kopfleiste
            Item {
                width: parent.width
                height: 32

                AlpeActionButton {
                    id: closeButton

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: root.overlay ? "arrow_back" : "close"
                    iconColor: Theme.surfaceText
                    tooltipText: root.overlay ? "Zurück" : "Schliessen"
                    onClicked: root.closeRequested()
                }

                Row {
                    anchors.left: closeButton.right
                    anchors.leftMargin: Theme.spacingXS
                    anchors.right: busy.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS

                    LeagueIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        league: root.detail?.league ?? ({
                                "sport": root.sport
                            })
                        size: 16
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, parent.width - 24)
                        elide: Text.ElideRight
                        text: [root.detail?.league?.name ?? "", root.match?.round ?? ""].filter(x => !!x).join(" · ")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: !!root.match?.league
                            onClicked: root.openLeague(root.match.league)
                        }
                    }
                }

                AlpeIcon {
                    id: busy

                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    name: "progress_activity"
                    size: 16
                    color: Theme.surfaceVariantText
                    opacity: root.loading ? 1 : 0

                    RotationAnimation on rotation {
                        running: root.loading
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1000
                    }
                }
            }

            // Resultat
            Item {
                width: parent.width
                height: hero.implicitHeight
                visible: !!root.match

                Row {
                    id: hero

                    width: parent.width

                    TeamHead {
                        width: (hero.width - scoreColumn.width) / 2
                        team: root.match?.home ?? null
                        sport: root.sport
                        favorite: root.favorites.indexOf(S.teamKey(root.sport, root.match?.home)) >= 0
                        onToggle: root.toggleFavorite(root.match.home)
                    }

                    Column {
                        id: scoreColumn

                        width: Math.max(110, scoreText.implicitWidth + Theme.spacingL)
                        spacing: 2
                        topPadding: Theme.spacingS

                        StyledText {
                            id: scoreText

                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.match ? (S.hasScore(root.match) ? root.match.home.score + " – " + root.match.away.score : root.match.timeUnknown ? "vs." : S.clock(root.match.start)) : ""
                            font.pixelSize: S.hasScore(root.match) ? Theme.fontSizeXXLarge + 6 : Theme.fontSizeXLarge
                            font.weight: Font.Bold
                            font.features: {
                                "tnum": 1
                            }
                            color: root.live ? Theme.success : Theme.surfaceText
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                const m = root.match;
                                if (!m)
                                    return "";
                                if (m.status === "pre")
                                    return S.dayLabel(new Date(m.start)) + (m.timeUnknown ? " · Zeit offen" : "");
                                return m.label || "";
                            }
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: root.live ? Font.DemiBold : Font.Normal
                            color: root.live ? Theme.success : Theme.surfaceVariantText
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: text !== ""
                            text: S.penaltiesText(root.match ?? {})
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                    }

                    TeamHead {
                        width: (hero.width - scoreColumn.width) / 2
                        team: root.match?.away ?? null
                        sport: root.sport
                        favorite: root.favorites.indexOf(S.teamKey(root.sport, root.match?.away)) >= 0
                        onToggle: root.toggleFavorite(root.match.away)
                    }
                }
            }

            // Abschnitte (Halbzeiten, Drittel, Viertel)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingXS
                visible: (root.detail?.periods ?? []).length > 0

                Repeater {
                    model: root.detail?.periods ?? []

                    Rectangle {
                        required property var modelData

                        width: periodColumn.implicitWidth + Theme.spacingM
                        height: periodColumn.implicitHeight + Theme.spacingXS * 2
                        radius: Theme.cornerRadiusS
                        color: Theme.withAlpha(Theme.surfaceText, 0.06)

                        Column {
                            id: periodColumn

                            anchors.centerIn: parent

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: parent.parent.modelData.name
                                font.pixelSize: Theme.fontSizeSmall - 2
                                color: Theme.surfaceVariantText
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: parent.parent.modelData.home + ":" + parent.parent.modelData.away
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.DemiBold
                                font.features: {
                                    "tnum": 1
                                }
                                color: Theme.surfaceText
                            }
                        }
                    }
                }
            }

            SegmentBar {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.tabs.length > 1
                model: root.tabs
                currentIndex: Math.max(0, root.tabs.findIndex(t => t.key === root.currentTab))
                onSelected: index => root.tab = root.tabs[index].key
            }

            StyledText {
                width: parent.width
                visible: root.failure !== "" && !root.detail
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: root.failure
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.error
            }

            StyledText {
                width: parent.width
                visible: root.loading && !root.detail
                horizontalAlignment: Text.AlignHCenter
                text: "Spieldaten werden geladen …"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            // ---------------------------------------------------------------- Übersicht
            Column {
                width: parent.width
                spacing: Theme.spacingM
                visible: root.currentTab === "facts" && !!root.detail

                // Verlauf
                Column {
                    width: parent.width
                    spacing: 2
                    visible: (root.detail?.events ?? []).length > 0

                    Repeater {
                        model: root.detail?.events ?? []

                        EventRow {
                            required property var modelData

                            width: parent.width
                            event: modelData
                            sport: root.sport
                        }
                    }
                }

                StyledText {
                    width: parent.width
                    visible: (root.detail?.events ?? []).length === 0 && root.sport !== "basketball"
                    horizontalAlignment: Text.AlignHCenter
                    text: root.match?.noDetail ? "Für Länderspiele im Eishockey liefert der Verband nur das Resultat." : root.match?.status === "pre" ? "Das Spiel hat noch nicht begonnen." : "Keine Ereignisse"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                // Tabelle (Ausschnitt um beide Teams)
                Column {
                    width: parent.width
                    spacing: Theme.spacingXS
                    visible: root.tableExcerpt !== null

                    Item {
                        width: parent.width
                        height: tableTitle.implicitHeight

                        StyledText {
                            id: tableTitle

                            text: "Tabelle"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.DemiBold
                            color: Theme.surfaceText
                        }

                        StyledText {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Ganze Tabelle ›"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.primary

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openTable(root.match.league)
                            }
                        }
                    }

                    StandingsView {
                        width: parent.width
                        table: root.tableExcerpt
                        sport: root.sport
                        favorites: root.favorites
                        highlight: [root.match?.home?.id ?? "", root.match?.away?.id ?? ""]
                        footer: false
                        onToggleFavorite: team => root.toggleFavorite(team)
                    }
                }

                // Topspieler (NBA, Hockey)
                Column {
                    width: parent.width
                    spacing: Theme.spacingXS
                    visible: (root.detail?.leaders ?? []).length > 0

                    StyledText {
                        text: "Topspieler"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.DemiBold
                        color: Theme.surfaceText
                    }

                    Repeater {
                        model: root.detail?.leaders ?? []

                        Item {
                            id: leader

                            required property var modelData

                            width: parent.width
                            height: 32

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.cornerRadiusXS
                                color: leaderMouse.containsMouse && leaderMouse.enabled ? Theme.withAlpha(Theme.surfaceText, 0.06) : "transparent"
                            }

                            MouseArea {
                                id: leaderMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !!leader.modelData.id
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.playerClicked(leader.modelData)
                            }

                            Crest {
                                id: leaderCrest

                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                team: leader.modelData.side === "home" ? root.match?.home : root.match?.away
                                size: 20
                            }

                            StyledText {
                                anchors.left: leaderCrest.right
                                anchors.leftMargin: Theme.spacingS
                                anchors.right: leaderValue.left
                                anchors.rightMargin: Theme.spacingS
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: leader.modelData.name + "  ·  " + leader.modelData.title
                                font.pixelSize: Theme.fontSizeSmall + 1
                                color: Theme.surfaceText
                            }

                            StyledText {
                                id: leaderValue

                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: leader.modelData.value
                                font.pixelSize: Theme.fontSizeSmall + 1
                                font.weight: Font.DemiBold
                                color: Theme.surfaceText
                            }
                        }
                    }
                }

                // Infos
                Rectangle {
                    width: parent.width
                    height: infoColumn.implicitHeight + Theme.spacingM
                    radius: Theme.cornerRadiusS
                    color: Theme.withAlpha(Theme.surfaceText, 0.04)
                    visible: infoRepeater.count > 0

                    Column {
                        id: infoColumn

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Theme.spacingS

                        Repeater {
                            id: infoRepeater

                            model: {
                                const d = root.detail;
                                const m = root.match;
                                if (!d || !m)
                                    return [];
                                const out = [];
                                if (m.start)
                                    out.push(["event", S.longDay(new Date(m.start)) + (m.timeUnknown ? "" : ", " + S.clock(m.start))]);
                                if (m.round && m.league && m.league.indexOf("sui.") === 0)
                                    out.push(["emoji_events", m.round]);
                                if (d.venue)
                                    out.push(["stadium", d.venue]);
                                if (d.attendance)
                                    out.push(["groups", S.formatAttendance(d.attendance) + " Zuschauer"]);
                                if (d.referee)
                                    out.push(["sports", d.referee]);
                                // TV und, falls in den Sport-Einstellungen hinterlegt, der Streamingdienst
                                if ((m.tv ?? []).length > 0 || root.stream)
                                    out.push(["tv", (m.tv ?? []).join(", "), root.stream ? "stream" : ""]);
                                return out;
                            }

                            Row {
                                id: infoRow

                                required property var modelData
                                readonly property bool hasStream: modelData[2] === "stream"

                                width: infoColumn.width
                                height: hasStream ? 32 : 26
                                spacing: Theme.spacingS

                                AlpeIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: infoRow.modelData[0]
                                    size: 16
                                    color: Theme.surfaceVariantText
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.min(implicitWidth, infoRow.width - 24 - (infoRow.hasStream ? streamChip.width + Theme.spacingS : 0))
                                    visible: text !== ""
                                    elide: Text.ElideRight
                                    text: infoRow.modelData[1]
                                    font.pixelSize: Theme.fontSizeSmall + 1
                                    color: Theme.surfaceText
                                }

                                // Streamingdienst: öffnet die hinterlegte Seite im Browser
                                Rectangle {
                                    id: streamChip

                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: infoRow.hasStream
                                    width: streamLabel.implicitWidth + 16 + Theme.spacingS * 3
                                    height: 26
                                    radius: 13
                                    color: streamMouse.containsMouse ? Theme.primary : Theme.primaryContainer

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: Theme.spacingXS

                                        AlpeIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            name: "play_circle"
                                            size: 16
                                            filled: true
                                            color: streamMouse.containsMouse ? Theme.onPrimary : Theme.onPrimaryContainer
                                        }

                                        StyledText {
                                            id: streamLabel

                                            anchors.verticalCenter: parent.verticalCenter
                                            text: root.stream?.name || "Stream"
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.DemiBold
                                            color: streamMouse.containsMouse ? Theme.onPrimary : Theme.onPrimaryContainer
                                        }
                                    }

                                    MouseArea {
                                        id: streamMouse

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.openUrlExternally(root.stream.url)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------------------------- Statistik
            Column {
                width: parent.width
                spacing: Theme.spacingM
                visible: root.currentTab === "stats"

                Repeater {
                    model: root.currentTab === "stats" ? (root.detail?.stats ?? []) : []

                    StatBar {
                        required property var modelData
                        required property int index

                        width: parent.width
                        stat: modelData
                        split: index === 0 && modelData.label === "Ballbesitz"
                    }
                }
            }

            // ---------------------------------------------------------------- Aufstellung / Spieler
            Column {
                width: parent.width
                spacing: Theme.spacingM
                visible: root.currentTab === "lineup" || root.currentTab === "box"

                SegmentBar {
                    anchors.horizontalCenter: parent.horizontalCenter
                    model: [root.match?.home?.short ?? "Heim", root.match?.away?.short ?? "Gast"]
                    currentIndex: root.side === "home" ? 0 : 1
                    onSelected: index => root.side = index === 0 ? "home" : "away"
                }

                Pitch {
                    width: Math.min(parent.width, 440)
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.currentTab === "lineup" && root.sport === "soccer"
                    lineup: root.detail?.lineups?.[root.side] ?? null
                    team: root.match?.[root.side] ?? null
                    onPlayerClicked: p => root.playerClicked(p)
                }

                // Ersatzbank (Fussball)
                Column {
                    width: parent.width
                    visible: root.currentTab === "lineup" && root.sport === "soccer" && (root.detail?.lineups?.[root.side]?.bench ?? []).length > 0
                    spacing: 0

                    StyledText {
                        text: "Ersatzbank"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.DemiBold
                        color: Theme.surfaceText
                        bottomPadding: Theme.spacingXS
                    }

                    Repeater {
                        model: root.detail?.lineups?.[root.side]?.bench ?? []

                        Item {
                            id: benchRow

                            required property var modelData

                            width: parent.width
                            height: 26

                            MouseArea {
                                anchors.fill: parent
                                enabled: !!benchRow.modelData.id
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: root.playerClicked(benchRow.modelData)
                            }

                            StyledText {
                                id: benchNum

                                width: 28
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.modelData.num
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }

                            StyledText {
                                anchors.left: benchNum.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.modelData.name
                                font.pixelSize: Theme.fontSizeSmall + 1
                                color: Theme.surfaceText
                            }

                            AlpeIcon {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                visible: parent.modelData.subIn === true
                                name: "arrow_upward"
                                size: 14
                                color: Theme.success
                            }
                        }
                    }
                }

                HockeyLines {
                    width: parent.width
                    visible: root.currentTab === "lineup" && root.sport === "hockey"
                    lineup: root.detail?.lineups?.[root.side] ?? null
                    onPlayerClicked: p => root.playerClicked(p)
                }

                BoxScore {
                    width: parent.width
                    visible: root.currentTab === "box"
                    box: root.detail?.players?.[root.side] ?? null
                    onPlayerClicked: p => root.playerClicked(p)
                }
            }
        }
    }
}
