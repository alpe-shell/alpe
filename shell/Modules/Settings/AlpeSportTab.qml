pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.DDash
import qs.Modules.Settings.Widgets

// Alpe: Einstellungen des Sport-Plugins an einem Ort. Wettbewerbe (an/aus wie im Dashboard,
// dazu die Reihenfolge), Favoriten, Mitteilungen und Leiste, Streamingdienste je Wettbewerb,
// Nachladen, Zwischenspeicher. Gespeichert wird in den Plugin-Daten (plugin_settings.json →
// alpeSport), die Schalter der Wettbewerbe in den Dashboard-Optionen (eine Quelle für beide).
Item {
    id: root

    property var parentModal: null

    readonly property string pluginId: "alpeSport"
    readonly property string entryId: "plugin_alpeSport"
    readonly property string pluginDir: PluginService.getPluginPath ? PluginService.getPluginPath(pluginId) : ""
    readonly property bool available: pluginDir !== ""
    readonly property string helper: pluginDir + "/sport"

    property var store: ({})
    property var leagues: []
    property var cache: null
    property string streamLeague: ""
    property string draftName: ""
    property string draftUrl: ""
    property string testState: ""

    readonly property var order: store.order ?? []
    readonly property var orderedLeagues: {
        const list = leagues.slice();
        const rank = id => {
            const at = order.indexOf(id);
            return at < 0 ? 1000 + leagues.findIndex(l => l.id === id) : at;
        };
        return list.sort((a, b) => rank(a.id) - rank(b.id));
    }
    readonly property var favorites: store.favorites ?? []
    readonly property var favoriteNames: store.favoriteNames ?? ({})
    readonly property var streams: store.streams ?? ({})

    function load() {
        store = SettingsData.getPluginSettingsForPlugin ? (SettingsData.getPluginSettingsForPlugin(pluginId) ?? {}) : {};
    }

    function save(key, value) {
        PluginService.savePluginData(pluginId, key, value);
        load();
    }

    function optionKey(id) {
        return "liga_" + id.replace(/\./g, "_");
    }

    function leagueEnabled(league) {
        const stored = DashRegistry.storedOptions ? DashRegistry.storedOptions(entryId) : {};
        const key = optionKey(league.id);
        return key in stored ? stored[key] === true || stored[key] === "true" : league["default"] !== false;
    }

    function setLeague(league, on) {
        DashRegistry.setOption(entryId, optionKey(league.id), on);
    }

    function move(id, step) {
        const ids = orderedLeagues.map(l => l.id);
        const at = ids.indexOf(id);
        const to = at + step;
        if (at < 0 || to < 0 || to >= ids.length)
            return;
        ids.splice(at, 1);
        ids.splice(to, 0, id);
        save("order", ids);
    }

    function removeFavorite(key) {
        save("favorites", favorites.filter(k => k !== key));
    }

    function pickStreamLeague(id) {
        streamLeague = id;
        draftName = streams[id]?.name ?? "";
        draftUrl = streams[id]?.url ?? "";
    }

    function saveStream() {
        if (streamLeague === "" || draftUrl.trim() === "")
            return;
        let url = draftUrl.trim();
        if (!/^https?:\/\//i.test(url))
            url = "https://" + url;
        const copy = Object.assign({}, streams);
        copy[streamLeague] = {
            "name": draftName.trim() || url.replace(/^https?:\/\/(www\.)?/i, "").split("/")[0],
            "url": url
        };
        draftUrl = url;
        save("streams", copy);
    }

    function removeStream(id) {
        const copy = Object.assign({}, streams);
        delete copy[id];
        save("streams", copy);
        if (id === streamLeague)
            pickStreamLeague(id);
    }

    function leagueName(id) {
        return leagues.find(l => l.id === id)?.name ?? id;
    }

    function sportName(sport) {
        return ({
                "hockey": "Eishockey",
                "soccer": "Fussball",
                "basketball": "Basketball"
            })[sport] ?? sport;
    }

    function size(bytes) {
        return bytes >= 1048576 ? (bytes / 1048576).toFixed(1) + " MB" : Math.round(bytes / 1024) + " KB";
    }

    function run(args, done) {
        if (!available)
            return;
        Proc.runCommand("alpe-sport-" + args[0], ["python3", "-I", helper].concat(args), (output, code) => {
            try {
                done(JSON.parse(output));
            } catch (e) {}
        }, 0, 30000);
    }

    Component.onCompleted: {
        load();
        run(["leagues"], answer => {
            root.leagues = answer.leagues ?? [];
            if (root.streamLeague === "" && root.leagues.length > 0)
                root.pickStreamLeague(root.leagues[0].id);
        });
        run(["cache"], answer => root.cache = answer);
    }

    Connections {
        target: PluginService

        function onPluginDataChanged(changedId) {
            if (changedId === root.pluginId)
                root.load();
        }
    }

    SettingsPage {
        SettingsCard {
            width: parent.width
            iconName: "sports_soccer"
            title: "Sport"
            settingKey: "alpeSport"
            tags: ["sport", "fussball", "eishockey", "nba", "wettbewerbe"]

            SettingsNoteRow {
                visible: !root.available
                text: "Das Plugin «Sport» ist nicht aktiv. Einschalten unter Plugins oder mit «alpe plugins»."
            }

            SettingsRow {
                visible: root.available
                title: "Wettbewerbe ein- und ausschalten, Reihenfolge festlegen"
                subtitle: "Gilt für den Sport-Tab, die Karte «Sport heute» und die Mitteilungen. Pfeile ändern die Reihenfolge in der Leiste links."
                iconName: "info"
            }

            Repeater {
                model: root.orderedLeagues

                SettingsToggleRow {
                    id: leagueRow

                    required property var modelData
                    required property int index

                    width: parent ? parent.width : 0
                    text: modelData.name
                    description: modelData.country + (modelData.kind === "cup" ? " · Cup" : modelData.kind === "national" ? " · Länderspiele" : "")
                    checked: root.leagueEnabled(modelData)
                    onToggled: checked => root.setLeague(modelData, checked)

                    accessory: [
                        DActionButton {
                            iconName: "arrow_upward"
                            iconColor: Theme.surfaceVariantText
                            enabled: leagueRow.index > 0
                            opacity: enabled ? 1 : 0.3
                            tooltipText: "Nach oben"
                            onClicked: root.move(leagueRow.modelData.id, -1)
                        },
                        DActionButton {
                            iconName: "arrow_downward"
                            iconColor: Theme.surfaceVariantText
                            enabled: leagueRow.index < root.orderedLeagues.length - 1
                            opacity: enabled ? 1 : 0.3
                            tooltipText: "Nach unten"
                            onClicked: root.move(leagueRow.modelData.id, 1)
                        }
                    ]
                }
            }

            SettingsRow {
                visible: root.order.length > 0
                title: "Reihenfolge zurücksetzen"
                iconName: "restart_alt"

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Zurücksetzen"
                    variant: "tonal"
                    onClicked: root.save("order", [])
                }
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "star"
            title: "Favoriten"
            settingKey: "alpeSportFavorites"
            tags: ["favoriten", "teams", "sport"]

            SettingsRow {
                visible: root.favorites.length === 0
                title: "Noch keine Favoriten"
                subtitle: "Im Sport-Tab beim Spieldetail auf den Stern klicken oder in der Tabelle mit der rechten Maustaste."
                iconName: "star_outline"
            }

            Repeater {
                model: root.favorites

                SettingsRow {
                    id: favoriteRow

                    required property string modelData
                    readonly property var known: root.favoriteNames[modelData] ?? null

                    width: parent ? parent.width : 0
                    title: known?.name ?? ("Team " + modelData.split(":")[1])
                    subtitle: root.sportName(modelData.split(":")[0])
                    iconName: modelData.startsWith("hockey") ? "sports_hockey" : modelData.startsWith("basketball") ? "sports_basketball" : "sports_soccer"

                    DActionButton {
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: "close"
                        iconColor: Theme.surfaceVariantText
                        tooltipText: "Aus den Favoriten entfernen"
                        onClicked: root.removeFavorite(favoriteRow.modelData)
                    }
                }
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "notifications"
            title: "Mitteilungen und Leiste"
            settingKey: "alpeSportNotify"
            tags: ["mitteilungen", "tor", "leiste", "live", "benachrichtigung"]

            SettingsToggleRow {
                width: parent.width
                text: "Tore"
                description: "Fussball und Eishockey: eine Mitteilung pro Tor deiner Favoriten, mit Spielstand und Minute."
                checked: root.store.notifyGoals ?? true
                onToggled: checked => root.save("notifyGoals", checked)
            }

            SettingsToggleRow {
                width: parent.width
                text: "Spielbeginn"
                description: "Anpfiff bzw. erstes Bully, auch NBA."
                checked: root.store.notifyStart ?? true
                onToggled: checked => root.save("notifyStart", checked)
            }

            SettingsToggleRow {
                width: parent.width
                text: "Schlussresultat"
                description: "Mit n.V. oder n.P., wenn es so ausging."
                checked: root.store.notifyEnd ?? true
                onToggled: checked => root.save("notifyEnd", checked)
            }

            SettingsToggleRow {
                width: parent.width
                text: "Live-Spiel in der Leiste"
                description: "Logo, Resultat und Minute des laufenden Favoritenspiels; Klick öffnet das Spiel. Das Element «Sport» muss in der Leiste stehen (Leiste → Widgets)."
                checked: root.store.barLive ?? true
                onToggled: checked => root.save("barLive", checked)
            }

            SettingsToggleRow {
                width: parent.width
                text: "Anstehende Spiele in der Leiste"
                description: "Zeigt das nächste Favoritenspiel ab drei Stunden vor Beginn mit Anstosszeit."
                checked: root.store.barUpcoming ?? true
                onToggled: checked => root.save("barUpcoming", checked)
            }

            SettingsRow {
                title: "Probe-Mitteilung"
                subtitle: root.testState !== "" ? root.testState : "Schickt eine Mitteilung, wie sie bei einem Tor erscheint."
                iconName: "campaign"

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Senden"
                    variant: "tonal"
                    onClicked: {
                        Proc.runCommand("alpe-sport-test", ["notify-send", "--app-name=Sport", "--icon=trophy", "Tor für EV Zug", "EV Zug 2:1 HC Lugano  ·  34'"], (output, code) => {
                            root.testState = code === 0 ? "Gesendet." : "notify-send fehlt (Paket libnotify). Die Mitteilungen laufen dann über gdbus.";
                        }, 0, 10000);
                    }
                }
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "live_tv"
            title: "Streamingdienste"
            settingKey: "alpeSportStreams"
            tags: ["stream", "streaming", "tv", "übertragung", "mysports", "blue", "dazn", "sky"]

            SettingsRow {
                title: "Link je Wettbewerb"
                subtitle: "Erscheint im Spieldetail unten neben dem Fernsehsender und öffnet die Seite im Browser. Rechte wechseln oft – hier jederzeit änderbar."
                iconName: "info"
            }

            SettingsDropdownRow {
                width: parent.width
                text: "Wettbewerb"
                options: root.orderedLeagues.map(l => l.name)
                currentValue: root.leagueName(root.streamLeague)
                onValueChanged: value => {
                    const league = root.leagues.find(l => l.name === value);
                    if (league)
                        root.pickStreamLeague(league.id);
                }
            }

            SettingsTextFieldRow {
                width: parent.width
                text: "Dienst"
                description: "Name auf dem Knopf, z. B. MySports"
                placeholderText: "Name"
                value: root.draftName
                onValueEdited: value => root.draftName = value
                onEditingFinished: value => root.draftName = value
            }

            SettingsTextFieldRow {
                width: parent.width
                text: "Adresse"
                description: "Seite, die sich öffnen soll"
                placeholderText: "https://"
                value: root.draftUrl
                onValueEdited: value => root.draftUrl = value
                onEditingFinished: value => root.draftUrl = value
                onAccepted: value => {
                    root.draftUrl = value;
                    root.saveStream();
                }
            }

            SettingsRow {
                title: root.streams[root.streamLeague] ? "Geändert speichern" : "Hinzufügen"
                iconName: "save"

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Speichern"
                    enabled: root.draftUrl.trim() !== ""
                    onClicked: root.saveStream()
                }
            }

            Repeater {
                model: Object.keys(root.streams).sort((a, b) => root.orderedLeagues.findIndex(l => l.id === a) - root.orderedLeagues.findIndex(l => l.id === b))

                SettingsRow {
                    id: streamRow

                    required property string modelData
                    readonly property var stream: root.streams[modelData]

                    width: parent ? parent.width : 0
                    title: root.leagueName(modelData) + "  →  " + (stream?.name ?? "")
                    subtitle: stream?.url ?? ""
                    iconName: "play_circle"

                    Row {
                        anchors.verticalCenter: parent.verticalCenter

                        DActionButton {
                            iconName: "open_in_new"
                            iconColor: Theme.surfaceVariantText
                            tooltipText: "Im Browser öffnen"
                            onClicked: Qt.openUrlExternally(streamRow.stream.url)
                        }

                        DActionButton {
                            iconName: "edit"
                            iconColor: Theme.surfaceVariantText
                            tooltipText: "Bearbeiten"
                            onClicked: root.pickStreamLeague(streamRow.modelData)
                        }

                        DActionButton {
                            iconName: "delete"
                            iconColor: Theme.surfaceVariantText
                            tooltipText: "Entfernen"
                            onClicked: root.removeStream(streamRow.modelData)
                        }
                    }
                }
            }
        }

        // Alpe
        SettingsCard {
            width: parent.width
            iconName: "width_full"
            title: "Sport-Tab"
            settingKey: "alpeSportTab"
            tags: ["breite", "grösse", "dash", "spieldetail", "verbreitern"]

            SettingsToggleRow {
                width: parent.width
                text: "Dash für das Spieldetail verbreitern"
                description: "Ein Klick auf ein Spiel macht das Dash breiter und zeigt das Detail neben der Liste, schliessen macht es wieder schmal. Aus: Das Detail liegt über der Liste, wenn das Dash zu schmal ist."
                checked: root.store.growDetail ?? true
                onToggled: checked => root.save("growDetail", checked)
            }
        }

        SettingsCard {
            width: parent.width
            iconName: "sync"
            title: "Aktualisierung und Zwischenspeicher"
            settingKey: "alpeSportRefresh"
            tags: ["aktualisieren", "intervall", "cache", "zwischenspeicher"]

            SettingsSliderRow {
                width: parent.width
                text: "Laufende Spiele nachladen"
                description: "Im offenen Sport-Tab und für die Mitteilungen. Kürzer heisst schneller informiert, aber mehr Abrufe bei ESPN und dem Verband."
                value: Number(root.store.refreshLive) || 30
                minimum: 15
                maximum: 120
                step: 5
                unit: " s"
                onSliderDragFinished: finalValue => root.save("refreshLive", finalValue)
            }

            SettingsRow {
                title: "Ohne laufendes Spiel"
                subtitle: "Der Hintergrunddienst schaut nur nach, wenn ein Favorit heute spielt: bis 15 Minuten vor Beginn alle 30 Minuten, danach im obigen Takt."
                iconName: "schedule"
            }

            SettingsRow {
                title: "Zwischenspeicher"
                subtitle: root.cache ? root.size(root.cache.bytes) + " in " + root.cache.files + " Dateien (Antworten der Quellen, Vereinslogos)" : "Wird gemessen …"
                iconName: "database"

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Leeren"
                    variant: "tonal"
                    onClicked: root.run(["cache", "clear"], answer => root.cache = answer)
                }
            }
        }
    }
}
