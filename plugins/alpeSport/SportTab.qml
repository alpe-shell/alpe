import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.DDash
import "sport.js" as S

// Sport-Tab im Aufbau von FotMob: links die Wettbewerbe, in der Mitte die Spiele des Tages oder die
// Seite eines Wettbewerbs (Spiele, Tabelle), rechts bzw. darueber das Spieldetail.
DashTabComponent {
    id: root

    // ------------------------------------------------------------------ Zustand
    property int rowBudget: DashMetrics.defaultTabRows
    property var leagues: fallbackLeagues
    property date day: S.midnight(new Date())
    property date today: S.midnight(new Date())
    property string view: "day"              // day | live | fav | league
    property string leagueId: ""
    property string leagueTab: "matches"     // matches | table | stats
    property var statsData: ({})             // Alpe: Bestenlisten je Wettbewerb
    property string statsFailure: ""
    property var player: null                // Alpe: offenes Spielerblatt {id, name, league, team}

    property var dayData: null
    property string dayFailure: ""
    property var leagueData: ({})
    property string leagueFailure: ""

    property string detailKey: ""            // "<liga>/<spiel>"
    property var detailPreview: null
    property var detailData: null
    property string detailFailure: ""

    readonly property var favorites: pluginData.favorites ?? []
    readonly property var streams: pluginData.streams ?? ({})
    // Alpe: Nachladen laufender Spiele (Sekunden) aus den Sport-Einstellungen
    readonly property int liveSeconds: Math.max(15, Math.min(300, Number(pluginData.refreshLive) || 30))
    readonly property var enabledLeagues: S.ordered(leagues, pluginData.order).filter(l => {
        const value = options[S.optionKey(l.id)];
        return value === undefined ? l["default"] !== false : value === true || value === "true";
    })
    readonly property var enabledIds: enabledLeagues.map(l => l.id)
    readonly property var dayLeagues: (dayData?.leagues ?? []).filter(l => enabledIds.indexOf(l.id) >= 0)
    readonly property int liveCount: dayLeagues.reduce((n, l) => n + l.matches.filter(m => m.status === "live").length, 0)
    readonly property bool dayIsToday: day.getTime() === today.getTime()
    readonly property var currentLeague: leagues.find(l => l.id === leagueId) ?? null
    readonly property var currentLeagueData: leagueData[leagueId] ?? null

    readonly property bool wide: width >= wideThreshold
    readonly property real railWidth: width >= 760 ? 184 : 52
    readonly property bool detailOpen: detailKey !== ""
    readonly property bool playerOpen: player !== null
    readonly property bool sideOpen: detailOpen || playerOpen
    readonly property real detailWidth: Math.min(430, Math.max(360, width * 0.4))

    // Alpe: Spieldetail und Spielerblatt machen das Dash breiter, damit sie neben
    // der Liste stehen statt darüber – die Liste behält ihre Breite. Geschlossen gehen die Spalten
    // zurück. Abschaltbar in den Sport-Einstellungen («growDetail»). Ohne die Schnittstelle der
    // Shell (DashMetrics.widenPanel) oder auf zu schmalem Bildschirm bleibt es beim Überlagern.
    readonly property real wideThreshold: 1000
    readonly property bool growForDetail: pluginData.growDetail ?? true
    readonly property bool canWiden: typeof DashMetrics.widenPanel === "function"
    readonly property int baseColumns: canWiden ? DashMetrics.storedPanelColumns(entryId) || DashMetrics.defaultGridColumns : 0
    // Feste Grössen: zu (Wettbewerbe und Spiele) 6 × 8, mit Detail daneben zwei Spalten breiter (8 × 8).
    readonly property int detailExtraColumns: 2
    readonly property int tabRows: 8
    readonly property int wantedColumns: {
        if (!canWiden || !growForDetail || !sideOpen || editMode || entryId === "")
            return 0;
        return Math.min(DashMetrics.widenedGridColumns, baseColumns + detailExtraColumns);
    }
    property string widenedId: ""

    function applyWidening() {
        if (!canWiden)
            return;
        if (widenedId !== "" && widenedId !== entryId)
            DashMetrics.widenPanel(widenedId, 0);
        widenedId = entryId;
        if (entryId !== "")
            DashMetrics.widenPanel(entryId, wantedColumns);
    }

    onWantedColumnsChanged: applyWidening()
    onEntryIdChanged: applyWidening()
    Component.onDestruction: {
        if (canWiden && widenedId !== "")
            DashMetrics.widenPanel(widenedId, 0);
    }

    readonly property var fallbackLeagues: [
        {"id": "nl", "name": "National League", "short": "NL", "sport": "hockey", "kind": "league", "country": "Schweiz", "default": true},
        {"id": "nba", "name": "NBA", "short": "NBA", "sport": "basketball", "kind": "league", "country": "USA", "default": true},
        {"id": "eng.1", "name": "Premier League", "short": "PL", "sport": "soccer", "kind": "league", "country": "England", "default": true},
        {"id": "esp.1", "name": "LaLiga", "short": "LaLiga", "sport": "soccer", "kind": "league", "country": "Spanien", "default": true},
        {"id": "ger.1", "name": "Bundesliga", "short": "BL", "sport": "soccer", "kind": "league", "country": "Deutschland", "default": true},
        {"id": "ita.1", "name": "Serie A", "short": "Serie A", "sport": "soccer", "kind": "league", "country": "Italien", "default": true},
        {"id": "fra.1", "name": "Ligue 1", "short": "Ligue 1", "sport": "soccer", "kind": "league", "country": "Frankreich", "default": true}
    ]

    focusTarget: root
    // Acht Zeilen, offen wie zu, soweit der Bildschirm reicht
    implicitHeight: DashMetrics.heightForRows(Math.max(DashMetrics.minimumTabRows, Math.min(rowBudget, tabRows)))
    menuActions: [
        {
            "label": "Aktualisieren",
            "iconName": "refresh",
            "enabled": true,
            "action": () => root.refresh(true)
        },
        {
            "label": "Zu heute",
            "iconName": "today",
            "enabled": !root.dayIsToday || root.view === "league",
            "action": () => root.goToday()
        }
    ]

    // ------------------------------------------------------------------ Ablauf
    Component.onCompleted: {
        leaguesQuery.run(["leagues"]);
        if (live)
            refresh(false);
        Qt.callLater(takePendingMatch);
    }

    // Alpe: Klick auf das Spiel in der Leiste (oder eine Mitteilung) öffnet hier das Detail.
    function takePendingMatch() {
        const service = pluginService ?? PluginService;
        const pending = service?.getGlobalVar("alpeSport", "openMatch", null);
        if (!pending || !pending.match)
            return;
        service.setGlobalVar("alpeSport", "openMatch", null);
        if (view === "league")
            view = "day";
        if (S.isoDate(new Date(pending.match.start || Date.now())) !== S.isoDate(day))
            day = S.midnight(new Date(pending.match.start || Date.now()));
        if (detailKey !== pending.match.league + "/" + pending.match.id)
            openMatch(pending.match);
    }

    Connections {
        target: root.pluginService ?? PluginService

        function onGlobalVarChanged(pluginId, varName) {
            if (pluginId === "alpeSport" && varName === "openMatch")
                Qt.callLater(root.takePendingMatch);
        }
    }
    onLiveChanged: {
        if (live) {
            today = S.midnight(new Date());
            refresh(false);
        }
    }
    onDayChanged: {
        dayData = null;
        loadDay();
    }
    onEnabledIdsChanged: {
        if (live)
            loadDay();
    }

    function refresh(force) {
        if (view === "league")
            loadLeague();
        else
            loadDay();
        if (detailOpen)
            loadDetail();
    }

    // Fehler der Quellen sichtbar machen statt still eine leere Liste zu zeigen
    function sourceProblem(data) {
        const errors = data?.errors ?? [];
        if (errors.length === 0)
            return "";
        if (data.stale)
            return "Keine Verbindung – letzter Stand (" + errors[0] + ")";
        return "Quelle antwortet nicht: " + errors[0];
    }

    function loadDay() {
        dayQuery.run(["day", S.isoDate(view === "live" ? today : day), "--leagues", enabledIds.join(",")]);
    }

    function loadLeague() {
        if (leagueId !== "")
            leagueQuery.run(["league", leagueId]);
        if (leagueTab === "stats")
            loadStats();
    }

    function loadStats() {
        if (leagueId !== "" && currentLeague?.kind !== "national")
            statsQuery.run(["stats", leagueId]);
    }

    function openPlayer(p) {
        if (!p?.id)
            return;
        player = p;
    }

    function closePlayer() {
        player = null;
    }

    function loadDetail() {
        if ((detailData?.match ?? detailPreview)?.noDetail)
            return;
        const parts = detailKey.split("/");
        if (parts.length === 2)
            matchQuery.run(["match", parts[0], parts[1]]);
    }

    function show(nextView, id) {
        // Schmal liegt das Detail ueber der Liste: ein Klick in der Leiste soll die Liste zeigen.
        if (!wide && detailOpen)
            closeDetail();
        if (!wide)
            player = null;
        view = nextView;
        if (nextView === "league") {
            if (leagueId !== id) {
                leagueId = id;
                leagueTab = currentLeague?.kind === "league" ? leagueTab : "matches";
            }
            loadLeague();
        } else {
            if (nextView === "live" && !dayIsToday)
                day = today;
            loadDay();
        }
    }

    function goToday() {
        today = S.midnight(new Date());
        if (view === "league")
            view = "day";
        day = today;
    }

    function openMatch(match) {
        player = null;
        const key = match.league + "/" + match.id;
        if (detailKey === key && wide) {
            closeDetail();
            return;
        }
        detailKey = key;
        detailPreview = match;
        detailData = null;
        detailFailure = "";
        detailPane.resetView();
        if (match.noDetail) {                     // Länderspiel Eishockey: nur was die Liste weiss
            detailData = {
                "match": match,
                "league": leagues.find(l => l.id === match.league) ?? null,
                "venue": match.venue ?? "",
                "attendance": 0,
                "referee": "",
                "periods": [],
                "events": [],
                "stats": [],
                "lineups": {},
                "leaders": [],
                "players": {}
            };
            return;
        }
        loadDetail();
        const league = leagues.find(l => l.id === match.league);
        if (league && league.kind !== "national" && !leagueData[match.league])
            tableQuery.run(["league", match.league]);
    }

    function closeDetail() {
        detailKey = "";
        detailData = null;
        detailPreview = null;
    }

    function toggleFavorite(sport, team) {
        if (!team)
            return;
        const key = S.teamKey(sport, team);
        setData("favorites", S.toggled(favorites, key));
        rememberNames([[sport, team]]);
    }

    // Alpe: Namen der Favoriten für die Sport-Einstellungen merken (die Liste kennt nur Kennungen)
    function rememberNames(pairs) {
        const known = pluginData.favoriteNames ?? {};
        let copy = null;
        for (const [sport, team] of pairs) {
            if (!team)
                continue;
            const key = S.teamKey(sport, team);
            if (known[key]?.name === team.name)
                continue;
            copy = copy ?? Object.assign({}, known);
            copy[key] = {
                "name": team.name,
                "abbr": team.abbr ?? ""
            };
        }
        if (copy)
            setData("favoriteNames", copy);
    }

    function rememberFrom(matches) {
        const pairs = [];
        for (const m of matches ?? [])
            for (const side of ["home", "away"])
                if (favorites.indexOf(S.favKey(m, side)) >= 0 && !(pluginData.favoriteNames ?? {})[S.favKey(m, side)])
                    pairs.push([m.sport, m[side]]);
        if (pairs.length > 0)
            rememberNames(pairs);
    }

    function handleKeyEvent(event) {
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier))
            return false;
        if (event.key === Qt.Key_Escape && playerOpen) {
            closePlayer();
            return true;
        }
        if (event.key === Qt.Key_Escape && detailOpen) {
            closeDetail();
            return true;
        }
        if (view === "day" || view === "fav") {
            if (event.key === Qt.Key_Left) {
                day = S.addDays(day, -1);
                return true;
            }
            if (event.key === Qt.Key_Right) {
                day = S.addDays(day, 1);
                return true;
            }
        }
        return false;
    }

    function restoreFocus() {
        root.forceActiveFocus(Qt.OtherFocusReason);
    }

    // ------------------------------------------------------------------ Abfragen
    SportQuery {
        id: leaguesQuery

        onResult: (data, args) => {
            if ((data?.leagues?.length ?? 0) > 0)
                root.leagues = data.leagues;
        }
    }

    SportQuery {
        id: dayQuery

        onResult: (data, args) => {
            if (args[1] !== S.isoDate(root.view === "live" ? root.today : root.day))
                return;                                   // veraltet: inzwischen anderer Tag
            if (!data || data.error) {
                root.dayFailure = data?.error ?? "Keine Antwort";
                return;
            }
            root.dayFailure = root.sourceProblem(data);
            root.dayData = data;
            // Antworten aus Signalen sind keine echten JS-Arrays (kein flatMap): von Hand sammeln
            const all = [];
            for (let i = 0; i < (data.leagues?.length ?? 0); i++)
                for (let j = 0; j < (data.leagues[i].matches?.length ?? 0); j++)
                    all.push(data.leagues[i].matches[j]);
            root.rememberFrom(all);
        }
    }

    SportQuery {
        id: leagueQuery

        onResult: (data, args) => {
            if (!data || data.error) {
                root.leagueFailure = data?.error ?? "Keine Antwort";
                return;
            }
            root.leagueFailure = root.sourceProblem(data);
            const copy = Object.assign({}, root.leagueData);
            copy[args[1]] = data;
            root.leagueData = copy;
            if (args[1] === root.leagueId)
                Qt.callLater(matchesList.jumpToFocus);
        }
    }

    // Tabelle fuer das Spieldetail, ohne die Liga-Ansicht zu stoeren
    SportQuery {
        id: tableQuery

        onResult: (data, args) => {
            if (!data || data.error)
                return;
            const copy = Object.assign({}, root.leagueData);
            copy[args[1]] = data;
            root.leagueData = copy;
        }
    }

    SportQuery {
        id: statsQuery

        onResult: (data, args) => {
            if (!data || data.error) {
                root.statsFailure = data?.error ?? "Keine Antwort";
                return;
            }
            root.statsFailure = root.sourceProblem(data);
            const copy = Object.assign({}, root.statsData);
            copy[args[1]] = data;
            root.statsData = copy;
        }
    }

    SportQuery {
        id: matchQuery

        onResult: (data, args) => {
            if (args[1] + "/" + args[2] !== root.detailKey)
                return;
            if (!data || data.error) {
                root.detailFailure = data?.error ?? "Keine Antwort";
                return;
            }
            root.detailFailure = "";
            root.detailData = data;
        }
    }

    // Nachladen: alle 30 s, solange etwas laeuft, sonst seltener. Nur solange der Tab sichtbar ist.
    Timer {
        interval: root.liveCount > 0 ? root.liveSeconds * 1000 : root.dayIsToday ? 120000 : 900000
        repeat: true
        running: root.live && root.view !== "league"
        onTriggered: {
            root.today = S.midnight(new Date());
            if (!dayQuery.busy)                    // eine laufende Anfrage nicht abbrechen
                root.loadDay();
        }
    }

    Timer {
        interval: (root.currentLeagueData?.matches ?? []).some(m => m.status === "live") ? Math.max(45, root.liveSeconds) * 1000 : 300000
        repeat: true
        running: root.live && root.view === "league"
        onTriggered: {
            if (!leagueQuery.busy)
                root.loadLeague();
        }
    }

    Timer {
        interval: root.liveSeconds * 1000
        repeat: true
        running: root.live && root.detailOpen && (root.detailData?.match?.status ?? root.detailPreview?.status) === "live"
        onTriggered: {
            if (!matchQuery.busy)
                root.loadDetail();
        }
    }

    // ------------------------------------------------------------------ Leiste links
    Rectangle {
        id: rail

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.railWidth
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        DFlickable {
            anchors.fill: parent
            anchors.margins: Theme.spacingXS
            contentWidth: width
            contentHeight: railColumn.implicitHeight
            clip: true

            Column {
                id: railColumn

                width: parent.width
                spacing: 1

                RailItem {
                    width: railColumn.width
                    compact: root.railWidth < 100
                    icon: "calendar_today"
                    text: "Alle Spiele"
                    active: root.view === "day"
                    onClicked: root.show("day")
                }

                RailItem {
                    width: railColumn.width
                    compact: root.railWidth < 100
                    icon: "sensors"
                    text: "Live"
                    badge: root.liveCount > 0 ? String(root.liveCount) : ""
                    badgeColor: Theme.success
                    active: root.view === "live"
                    onClicked: root.show("live")
                }

                RailItem {
                    width: railColumn.width
                    compact: root.railWidth < 100
                    icon: "star"
                    text: "Favoriten"
                    active: root.view === "fav"
                    onClicked: root.show("fav")
                }

                Rectangle {
                    width: railColumn.width - Theme.spacingM * 2
                    x: Theme.spacingM
                    height: 1
                    color: Theme.outlineVariant
                }

                StyledText {
                    visible: root.railWidth >= 100
                    leftPadding: Theme.spacingS
                    topPadding: Theme.spacingS
                    bottomPadding: Theme.spacingXS
                    text: "Wettbewerbe"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                Repeater {
                    model: root.enabledLeagues

                    RailItem {
                        required property var modelData

                        width: railColumn.width
                        compact: root.railWidth < 100
                        league: Object.assign({}, modelData, {
                            "logo": (root.dayData?.leagues ?? []).find(l => l.id === modelData.id)?.logo ?? root.leagueData[modelData.id]?.league?.logo ?? ""
                        })
                        text: modelData.name
                        badge: {
                            const l = (root.dayData?.leagues ?? []).find(x => x.id === modelData.id);
                            const n = l ? l.matches.filter(m => m.status === "live").length : 0;
                            return n > 0 ? String(n) : "";
                        }
                        badgeColor: Theme.success
                        active: root.view === "league" && root.leagueId === modelData.id
                        onClicked: root.show("league", modelData.id)
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------ Mitte
    Item {
        id: main

        anchors.left: rail.right
        anchors.leftMargin: Theme.spacingM
        anchors.right: root.wide && root.sideOpen ? detailPane.left : parent.right
        anchors.rightMargin: root.wide && root.sideOpen ? Theme.spacingM : 0
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        // Kopf: Datum oder Wettbewerb
        Item {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 40

            // Tage
            Row {
                id: dateStrip

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: root.view === "day" || root.view === "fav"
                spacing: Theme.spacingXS

                DActionButton {
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "chevron_left"
                    iconColor: Theme.surfaceText
                    tooltipText: "Vorheriger Tag"
                    onClicked: root.day = S.addDays(root.day, -1)
                }

                Repeater {
                    model: {
                        const span = main.width >= 620 ? 2 : main.width >= 420 ? 1 : 0;
                        const out = [];
                        for (let i = -span; i <= span; i++)
                            out.push(S.addDays(root.day, i));
                        return out;
                    }

                    Rectangle {
                        id: dayChip

                        required property var modelData
                        readonly property bool active: modelData.getTime() === root.day.getTime()
                        readonly property bool isToday: modelData.getTime() === root.today.getTime()

                        anchors.verticalCenter: parent.verticalCenter
                        width: dayText.implicitWidth + Theme.spacingL * 2
                        height: 30
                        radius: 15
                        color: active ? Theme.primary : dayMouse.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.08) : "transparent"

                        StyledText {
                            id: dayText

                            anchors.centerIn: parent
                            text: S.dayLabel(dayChip.modelData, root.today)
                            font.pixelSize: Theme.fontSizeSmall + 1
                            font.weight: dayChip.active || dayChip.isToday ? Font.DemiBold : Font.Normal
                            color: dayChip.active ? Theme.onPrimary : dayChip.isToday ? Theme.primary : Theme.surfaceText
                        }

                        MouseArea {
                            id: dayMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.day = dayChip.modelData
                        }
                    }
                }

                DActionButton {
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "chevron_right"
                    iconColor: Theme.surfaceText
                    tooltipText: "Nächster Tag"
                    onClicked: root.day = S.addDays(root.day, 1)
                }
            }

            // Live
            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter
                visible: root.view === "live"
                spacing: Theme.spacingS

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: root.liveCount > 0 ? Theme.success : Theme.outline
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.liveCount === 1 ? "1 Spiel läuft" : root.liveCount + " Spiele laufen"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.DemiBold
                    color: Theme.surfaceText
                }
            }

            // Wettbewerb
            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingXS
                anchors.right: leagueTabs.left
                anchors.verticalCenter: parent.verticalCenter
                visible: root.view === "league"
                spacing: Theme.spacingS

                LeagueIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    league: Object.assign({}, root.currentLeague ?? {}, {
                        "logo": root.currentLeagueData?.league?.logo ?? ""
                    })
                    size: 28
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: -2

                    StyledText {
                        text: root.currentLeague?.name ?? ""
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.DemiBold
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: root.currentLeague?.country ?? ""
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }
            }

            SegmentBar {
                id: leagueTabs

                anchors.right: refreshBox.left
                anchors.rightMargin: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter
                // Alpe: dritter Reiter Statistik (Bestenlisten), ausser bei Länderspielen
                readonly property var keys: {
                    const out = ["matches"];
                    if (root.currentLeague?.kind === "league" || !!root.currentLeagueData?.table)
                        out.push("table");
                    if (root.currentLeague && root.currentLeague.kind !== "national")
                        out.push("stats");
                    return out;
                }
                visible: root.view === "league" && keys.length > 1
                model: keys.map(k => ({
                            "matches": "Spiele",
                            "table": "Tabelle",
                            "stats": "Statistik"
                        })[k])
                currentIndex: Math.max(0, keys.indexOf(root.leagueTab))
                onSelected: index => {
                    root.leagueTab = keys[index];
                    if (root.leagueTab === "stats" && !root.statsData[root.leagueId])
                        root.loadStats();
                }
            }

            Row {
                id: refreshBox

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: main.width >= 560
                    text: {
                        const stamp = root.view === "league" ? root.currentLeagueData?.updated : root.dayData?.updated;
                        return stamp ? "Stand " + S.clock(stamp) : "";
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                DActionButton {
                    id: refreshButton

                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "refresh"
                    iconColor: Theme.surfaceVariantText
                    tooltipText: "Aktualisieren"
                    onClicked: root.refresh(true)

                    RotationAnimation on rotation {
                        running: dayQuery.busy || leagueQuery.busy
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                        onRunningChanged: if (!running)
                            refreshButton.rotation = 0
                    }
                }
            }
        }

        StyledText {
            id: failureText

            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            visible: text !== ""
            text: root.view === "league" ? (root.leagueTab === "stats" ? root.statsFailure : root.leagueFailure) : root.dayFailure
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.error
            bottomPadding: Theme.spacingXS
        }

        // Tagesansicht (Alle, Live, Favoriten)
        DFlickable {
            id: dayList

            anchors.top: failureText.visible ? failureText.bottom : header.bottom
            anchors.topMargin: Theme.spacingS
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: root.view !== "league"
            contentWidth: width
            contentHeight: dayColumn.implicitHeight + Theme.spacingS
            clip: true

            readonly property var blocks: {
                const out = [];
                for (const league of root.dayLeagues) {
                    let matches = league.matches;
                    if (root.view === "live")
                        matches = matches.filter(m => m.status === "live");
                    else if (root.view === "fav")
                        matches = matches.filter(m => S.isFavoriteMatch(m, root.favorites));
                    if (matches.length > 0)
                        out.push({
                            "league": league,
                            "matches": matches
                        });
                }
                // Favoriten und laufende Spiele nach oben, sonst Reihenfolge der Leiste
                if (root.view === "day" && root.favorites.length > 0) {
                    const favs = [];
                    for (const b of out) {
                        const f = b.matches.filter(m => S.isFavoriteMatch(m, root.favorites));
                        if (f.length > 0)
                            favs.push(...f);
                    }
                    if (favs.length > 0)
                        out.unshift({
                            "league": {
                                "id": "",
                                "name": "Meine Teams",
                                "country": "",
                                "sport": "soccer",
                                "kind": "fav"
                            },
                            "matches": favs.sort((a, b) => a.start < b.start ? -1 : 1)
                        });
                }
                return out;
            }

            Column {
                id: dayColumn

                width: dayList.width
                spacing: Theme.spacingS

                Repeater {
                    model: dayList.blocks

                    LeagueBlock {
                        required property var modelData

                        width: dayColumn.width
                        league: modelData.league
                        matches: modelData.matches
                        favorites: root.favorites
                        selectedId: root.detailKey
                        onOpenLeague: id => {
                            if (id !== "")
                                root.show("league", id);
                        }
                        onOpenMatch: match => root.openMatch(match)
                    }
                }

                Item {
                    width: dayColumn.width
                    height: Math.max(160, dayList.height - 20)
                    visible: dayList.blocks.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        DIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: root.view === "live" ? "sensors_off" : root.view === "fav" ? "star" : "event_busy"
                            size: 36
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.dayData === null ? "Spiele werden geladen …" : root.view === "live" ? "Gerade läuft kein Spiel" : root.view === "fav" ? (root.favorites.length === 0 ? "Noch keine Favoriten" : "Deine Teams spielen an diesem Tag nicht") : "Keine Spiele an diesem Tag"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.min(320, dayList.width - 40)
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            visible: root.view === "fav" && root.favorites.length === 0
                            text: "Im Spieldetail den Stern beim Team antippen oder in der Tabelle mit Rechtsklick folgen."
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                    }
                }
            }
        }

        // Wettbewerb: Spiele nach Tagen
        DListView {
            id: matchesList

            anchors.top: failureText.visible ? failureText.bottom : header.bottom
            anchors.topMargin: Theme.spacingS
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: root.view === "league" && root.leagueTab === "matches"
            clip: true
            spacing: Theme.spacingS
            model: S.groupByDay(root.currentLeagueData?.matches ?? [])

            function jumpToFocus() {
                if (count > 0)
                    positionViewAtIndex(S.focusGroup(model, root.today), ListView.Beginning);
            }

            delegate: Rectangle {
                id: dayCard

                required property var modelData

                width: matchesList.width
                height: dayCardColumn.implicitHeight + Theme.spacingS * 2
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Column {
                    id: dayCardColumn

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingS

                    StyledText {
                        leftPadding: Theme.spacingS
                        topPadding: 2
                        bottomPadding: Theme.spacingXS
                        text: S.longDay(dayCard.modelData.day, root.today) + ([...new Set(dayCard.modelData.matches.map(m => m.round).filter(r => !!r))].length === 1 ? "  ·  " + dayCard.modelData.matches[0].round : "")
                        font.pixelSize: Theme.fontSizeSmall + 1
                        font.weight: Font.DemiBold
                        color: dayCard.modelData.day.getTime() === root.today.getTime() ? Theme.primary : Theme.surfaceText
                    }

                    Repeater {
                        model: dayCard.modelData.matches

                        MatchRow {
                            required property var modelData

                            width: dayCardColumn.width
                            match: modelData
                            favorite: S.isFavoriteMatch(modelData, root.favorites)
                            selected: root.detailKey === modelData.league + "/" + modelData.id
                            onClicked: root.openMatch(modelData)
                        }
                    }
                }
            }
        }

        StyledText {
            anchors.centerIn: matchesList
            visible: matchesList.visible && matchesList.count === 0
            text: root.currentLeagueData ? "Keine Spiele in diesem Zeitraum" : "Spiele werden geladen …"
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceVariantText
        }

        // Wettbewerb: Tabelle
        DFlickable {
            id: tableFlick

            anchors.top: failureText.visible ? failureText.bottom : header.bottom
            anchors.topMargin: Theme.spacingS
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: root.view === "league" && root.leagueTab === "table"
            contentWidth: width
            contentHeight: tableCard.height + Theme.spacingS
            clip: true

            Rectangle {
                id: tableCard

                width: tableFlick.width
                height: standings.implicitHeight + Theme.spacingS * 2
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                StandingsView {
                    id: standings

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingS
                    table: root.currentLeagueData?.table ?? null
                    sport: root.currentLeague?.sport ?? "soccer"
                    favorites: root.favorites
                    highlight: root.detailData ? [root.detailData.match.home.id, root.detailData.match.away.id] : []
                    onToggleFavorite: team => root.toggleFavorite(root.currentLeague?.sport ?? "soccer", team)
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: !root.currentLeagueData?.table
                    text: root.currentLeagueData ? "Keine Tabelle verfügbar" : "Tabelle wird geladen …"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                }
            }
        }

        // Wettbewerb: Statistik
        DFlickable {
            id: statsFlick

            anchors.top: failureText.visible ? failureText.bottom : header.bottom
            anchors.topMargin: Theme.spacingS
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: root.view === "league" && root.leagueTab === "stats"
            contentWidth: width
            contentHeight: statsView.implicitHeight + Theme.spacingS
            clip: true

            StatsView {
                id: statsView

                width: statsFlick.width
                stats: root.statsData[root.leagueId] ?? null
                favorites: root.favorites
                sport: root.currentLeague?.sport ?? "soccer"
                onOpenPlayer: p => root.openPlayer(p)
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 60
                visible: (statsView.stats?.categories ?? []).length === 0
                text: statsQuery.busy ? "Bestenlisten werden geladen …" : statsView.stats ? "Keine Statistik verfügbar" : ""
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceVariantText
            }
        }
    }

    // ------------------------------------------------------------------ Spieldetail
    MatchDetail {
        id: detailPane

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.wide ? root.detailWidth : main.width
        visible: root.detailOpen
        overlay: !root.wide
        detail: root.detailData
        preview: root.detailPreview
        loading: matchQuery.busy
        failure: root.detailFailure
        favorites: root.favorites
        streams: root.streams
        table: root.leagueData[(root.detailData?.match ?? root.detailPreview)?.league ?? ""]?.table ?? null
        onCloseRequested: root.closeDetail()
        onOpenPlayer: p => root.openPlayer(p)
        onToggleFavorite: team => root.toggleFavorite(detailPane.sport, team)
        onOpenLeague: id => {
            if (!root.wide)
                root.closeDetail();
            root.show("league", id);
        }
        // «Ganze Tabelle ›»: Wettbewerb mit dem Reiter Tabelle; breit bleibt das Spiel daneben offen
        onOpenTable: id => {
            if (!root.wide)
                root.closeDetail();
            root.show("league", id);
            root.leagueTab = "table";
        }
    }

    // ------------------------------------------------------------------ Spielerblatt
    PlayerSheet {
        id: playerSheet

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.wide ? root.detailWidth : main.width
        visible: root.playerOpen
        overlay: !root.wide
        player: root.player
        onCloseRequested: root.closePlayer()
    }
}
