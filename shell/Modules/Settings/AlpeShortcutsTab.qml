pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets

// Alpe: Tastenkürzel unter KWin. Alle globalen Kürzel aus kglobalaccel (KWin, Alpe, Plasma,
// Programme) an einem Ort; ändern wie in KDEs Dialog über setForeignShortcutKeys. Ersetzt unter
// KWin die Seite des Ursprungsprojekts, die nur Niri und Hyprland kennt.
//
// Alpe: Die Liste ist eine ListView (nur sichtbare Zeilen entstehen). Vorher stand jede der
// über 300 Aktionen als SettingsRow in einer SettingsGroup; die legt bei jeder neuen Zeile alle
// Zeilen neu aus und baut ihre Hintergründe neu – bei jedem Tastendruck in der Suche, was die
// Shell minutenlang festhielt. Die Suche wartet jetzt 150 ms. Während der Aufnahme hält ein
// ShortcutInhibitor (keyboard-shortcuts-inhibit, von KWin unterstützt) KWins Kürzel an, sonst
// löste Meta+… die bestehende Aktion aus, statt hier anzukommen. Neu: Kürzel für Programme und
// eigene Befehle anlegen, wie «Neu hinzufügen» in KDEs Systemeinstellungen.
Item {
    id: root

    property var parentModal: null

    property var info: null
    property bool loading: false
    property string filter: ""
    property string filterText: ""
    property string group: ""
    // Aufnahme: Zeile {component, action, componentName, actionName, keys} oder neues Kürzel {isNew, spec}
    property var capture: null
    // Kombination, die schon belegt ist: {combo, owner, target}
    property var conflict: null
    property string message: ""

    // Neues Kürzel
    property string newKind: "app"           // app | command
    property var apps: []                    // [{id, name}]
    property string newApp: ""               // Desktop-Datei-ID
    property string newName: ""
    property string newCommand: ""

    // Angezeigte Zeilen (von rebuild() gefüllt, nicht als Bindung: sonst rechnet jede Taste alles neu)
    property var shown: []
    property int total: 0

    readonly property string groupCustom: "Eigene Befehle"
    readonly property string groupApps: "Programme starten"

    AlpeKwinBackend {
        id: backend
    }

    readonly property bool inhibiting: inhibitor.active

    ShortcutInhibitor {
        id: inhibitor
        window: root.parentModal
        enabled: root.capture !== null
    }

    Timer {
        id: filterDelay
        interval: 150
        onTriggered: root.filter = root.filterText
    }

    // Wer während der Aufnahme weggeht, soll KDEs Kürzel nicht dauerhaft angehalten zurücklassen.
    Timer {
        id: captureTimeout
        interval: 20000
        onTriggered: {
            root.endCapture();
            root.message = "Aufnahme beendet (keine Taste gedrückt).";
        }
    }

    function refresh() {
        loading = true;
        backend.run(["shortcuts"], result => {
            loading = false;
            if (result)
                info = result;
        });
    }

    function loadApps() {
        backend.run(["apps"], result => {
            if (result && result.apps)
                apps = result.apps;
        });
    }

    Component.onCompleted: {
        refresh();
        loadApps();
    }
    Component.onDestruction: {
        if (capture !== null)
            backend.run(["block", "off"]);
    }

    onComponentsChanged: rebuild(true)
    onFilterChanged: rebuild(false)
    onGroupChanged: rebuild(false)

    readonly property var components: info ? info.components : []
    readonly property var groupNames: {
        const out = [];
        for (const c of components)
            if (out.indexOf(groupOf(c)) < 0)
                out.push(groupOf(c));
        return out;
    }

    function groupOf(c) {
        return c.custom ? groupCustom : c.launch ? groupApps : c.name;
    }

    function rebuild(keepScroll) {
        const y = list.contentY - list.originY;
        const out = [];
        const needle = filter.trim().toLowerCase();
        let count = 0;
        let last = null;
        for (const c of components) {
            const g = groupOf(c);
            if (group !== "" && g !== group)
                continue;
            for (const a of c.actions) {
                count += 1;
                const keys = a.keys.map(k => keyText(k)).join(", ");
                // Bei Programmen heisst die Aktion «Starten»: der Name des Programms ist der Titel.
                const title = c.launch && a.action === "_launch" ? c.name : a.name;
                if (needle !== "" && (title + " " + a.name + " " + c.name + " " + keys).toLowerCase().indexOf(needle) < 0)
                    continue;
                const changed = JSON.stringify(a.keys) !== JSON.stringify(a.defaults);
                const row = {
                    "uid": c.component + "\u0001" + a.action,
                    "group": g,
                    "component": c.component,
                    "componentName": c.name,
                    "action": a.action,
                    "actionName": title,
                    "keys": a.keys,
                    "defaults": a.defaults,
                    "keyLabel": keys !== "" ? keys : "–",
                    "changed": changed && !c.launch,
                    "removable": c.launch === true,
                    "custom": c.custom === true,
                    "command": c.command ?? "",
                    "first": last === null || last.group !== g,
                    "last": true
                };
                if (last !== null && last.group === g)
                    last.last = false;
                out.push(row);
                last = row;
            }
        }
        total = count;
        shown = out;
        // Ein neues Modell macht die erste Zeile zur aktuellen (die Bindung -1 geht dabei verloren),
        // und die aktuelle Zeile bekäme den Fokus.
        list.currentIndex = -1;
        if (keepScroll)
            Qt.callLater(() => list.contentY = Math.min(list.originY + y, list.maximumContentY));
    }

    function subtitleOf(row) {
        const parts = [];
        if (row.group !== row.componentName && !row.custom && row.action !== "_launch")
            parts.push(row.componentName);
        if (row.custom && row.command !== "")
            parts.push(row.command);
        if (row.changed && row.defaults.length > 0)
            parts.push("Vorgabe: " + row.defaults.map(k => keyText(k)).join(", "));
        return parts.join(" · ");
    }

    // ---------------------------------------------------------------- Tasten

    readonly property int modMask: Qt.ShiftModifier | Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier
    readonly property var names: ({
            [Qt.Key_Escape]: "Esc", [Qt.Key_Tab]: "Tab", [Qt.Key_Backtab]: "Tab", [Qt.Key_Backspace]: "Rücktaste",
            [Qt.Key_Return]: "Eingabe", [Qt.Key_Enter]: "Eingabe", [Qt.Key_Insert]: "Einfg", [Qt.Key_Delete]: "Entf",
            [Qt.Key_Pause]: "Pause", [Qt.Key_Print]: "Druck", [Qt.Key_Home]: "Pos1", [Qt.Key_End]: "Ende",
            [Qt.Key_Left]: "←", [Qt.Key_Up]: "↑", [Qt.Key_Right]: "→", [Qt.Key_Down]: "↓",
            [Qt.Key_PageUp]: "Bild↑", [Qt.Key_PageDown]: "Bild↓", [Qt.Key_Space]: "Leertaste",
            [Qt.Key_VolumeDown]: "Leiser", [Qt.Key_VolumeUp]: "Lauter", [Qt.Key_VolumeMute]: "Stumm",
            [Qt.Key_MediaPlay]: "Wiedergabe", [Qt.Key_MediaTogglePlayPause]: "Wiedergabe/Pause", [Qt.Key_MediaStop]: "Stopp",
            [Qt.Key_MediaPrevious]: "Zurück", [Qt.Key_MediaNext]: "Weiter", [Qt.Key_MonBrightnessUp]: "Heller",
            [Qt.Key_MonBrightnessDown]: "Dunkler", [Qt.Key_Calculator]: "Rechner", [Qt.Key_Launch0]: "Start 0",
            [Qt.Key_MicMute]: "Mikrofon aus", [Qt.Key_PowerOff]: "Ein/Aus", [Qt.Key_Sleep]: "Ruhezustand"
        })

    function keyText(combo) {
        combo = combo | 0;
        if (combo === 0)
            return "";
        const parts = [];
        if (combo & Qt.MetaModifier)
            parts.push("Meta");
        if (combo & Qt.ControlModifier)
            parts.push("Strg");
        if (combo & Qt.AltModifier)
            parts.push("Alt");
        if (combo & Qt.ShiftModifier)
            parts.push("Umschalt");
        const key = combo & ~(modMask | Qt.KeypadModifier);
        let name = names[key];
        if (name === undefined) {
            if (key >= Qt.Key_F1 && key <= Qt.Key_F35)
                name = "F" + (key - Qt.Key_F1 + 1);
            else if (key >= 0x20 && key < 0x7f)
                name = String.fromCharCode(key).toUpperCase();
            else if (key >= 0xa0 && key <= 0xff)
                name = String.fromCharCode(key).toUpperCase();
            else
                name = "0x" + key.toString(16);
        }
        parts.push(name);
        return parts.join("+");
    }

    function owner(combo, except) {
        for (const c of components)
            for (const a of c.actions)
                if (a.keys.indexOf(combo) >= 0 && !(c.component === except.component && a.action === except.action))
                    return {
                        "component": c.component,
                        "componentName": c.name,
                        "action": a.action,
                        "actionName": c.launch && a.action === "_launch" ? c.name : a.name,
                        "keys": a.keys
                    };
        return null;
    }

    function setKeys(target, keys, then) {
        backend.run(["shortcut-set", JSON.stringify({
                "component": target.component,
                "action": target.action,
                "componentName": target.componentName,
                "actionName": target.actionName,
                "keys": keys
            })], () => {
            if (then)
                then();
            else
                refresh();
        });
    }

    // Kombination einer Zeile oder einem neuen Kürzel geben.
    function assign(target, combo) {
        if (target.isNew) {
            backend.run(["shortcut-new", JSON.stringify(Object.assign({}, target.spec, {
                    "keys": [combo]
                }))], result => {
                if (result && result.ok) {
                    message = "«" + target.actionName + "» startet jetzt mit " + keyText(combo) + ".";
                    newName = "";
                    newCommand = "";
                } else {
                    message = "Konnte das Kürzel nicht anlegen" + (result && result.error ? ": " + result.error : ".");
                }
                refresh();
            });
            return;
        }
        // Neue Kombination ersetzt die erste; eine zweite bleibt.
        const rest = target.keys.filter((k, i) => i > 0 && k !== combo);
        setKeys(target, [combo].concat(rest));
        message = target.actionName + ": " + keyText(combo);
    }

    function remove(row) {
        backend.run(["shortcut-remove", JSON.stringify({
                "component": row.component,
                "action": row.action
            })], () => refresh());
        message = row.custom ? "«" + row.actionName + "» entfernt." : row.actionName + ": kein Kürzel mehr";
    }

    function beginCapture(row) {
        conflict = null;
        message = "";
        capture = row;
        backend.run(["block", "on"]);
        captureTimeout.restart();
        catcher.forceActiveFocus();
    }

    function endCapture() {
        captureTimeout.stop();
        if (capture !== null)
            backend.run(["block", "off"]);
        capture = null;
    }

    function captured(combo) {
        const target = capture;
        endCapture();
        const other = owner(combo, target);
        if (other) {
            conflict = {
                "combo": combo,
                "owner": other,
                "target": target
            };
            return;
        }
        assign(target, combo);
    }

    function resolveConflict(take) {
        const c = conflict;
        conflict = null;
        if (!take || !c)
            return;
        setKeys(c.owner, c.owner.keys.filter(k => k !== c.combo), () => root.assign(c.target, c.combo));
        message = keyText(c.combo) + " gehört jetzt zu «" + c.target.actionName + "», nicht mehr zu «" + c.owner.actionName + "».";
    }

    readonly property var newApplication: apps.find(a => a.id === newApp) ?? null
    readonly property bool newReady: newKind === "app" ? newApplication !== null : newName.trim() !== "" && newCommand.trim() !== ""

    function captureNew() {
        if (!newReady)
            return;
        if (newKind === "app")
            beginCapture({
                "isNew": true,
                "component": newApplication.id,
                "action": "_launch",
                "componentName": newApplication.name,
                "actionName": newApplication.name,
                "keys": [],
                "spec": {
                    "kind": "app",
                    "id": newApplication.id,
                    "name": newApplication.name
                }
            });
        else
            beginCapture({
                "isNew": true,
                "component": "",
                "action": "_launch",
                "componentName": newName.trim(),
                "actionName": newName.trim(),
                "keys": [],
                "spec": {
                    "kind": "command",
                    "name": newName.trim(),
                    "command": newCommand.trim()
                }
            });
    }

    // Unsichtbarer Fänger für die Aufnahme
    Item {
        id: catcher
        focus: root.capture !== null
        Keys.onPressed: event => {
            event.accepted = true;
            const k = event.key;
            if (k === Qt.Key_Shift || k === Qt.Key_Control || k === Qt.Key_Alt || k === Qt.Key_Meta || k === Qt.Key_Super_L || k === Qt.Key_Super_R || k === Qt.Key_AltGr || k === Qt.Key_unknown)
                return;
            const mods = event.modifiers & root.modMask;
            if (k === Qt.Key_Escape && mods === 0) {
                root.endCapture();
                return;
            }
            if ((k === Qt.Key_Backspace || k === Qt.Key_Delete) && mods === 0) {
                const target = root.capture;
                root.endCapture();
                if (target.isNew)
                    return;
                root.setKeys(target, []);
                root.message = target.actionName + ": kein Kürzel mehr";
                return;
            }
            // Buchstaben als Grossbuchstaben-Code wie Qt; Umschalt+Tab kommt als Backtab.
            const key = k === Qt.Key_Backtab ? Qt.Key_Tab : k;
            root.captured(mods | key);
        }
        onActiveFocusChanged: if (!activeFocus && root.capture !== null) root.endCapture()
    }

    // Alpe: Suche und Bereich stehen fest über der Liste, nicht in ihrem Kopf. In der Liste
    // nahm ihr Fokusbereich dem Suchfeld nach jedem Buchstaben den Fokus (neues Modell → neue
    // aktuelle Zeile); ausserhalb kann er das nicht.
    Column {
        id: toolbar

        width: list.columnWidth
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        topPadding: Theme.spacingXS + SettingsMetrics.focusGutter
        bottomPadding: SettingsMetrics.cardGap

        SettingsCard {
            width: parent.width
            iconName: "keyboard"
            title: "Tastenkürzel"
            settingKey: "alpeShortcuts"
            tags: ["tastenkürzel", "shortcuts", "keybinds", "kwin", "kglobalaccel"]

            SettingsNoteRow {
                visible: root.info !== null && !root.info.available
                text: "Der Dienst für globale Kürzel (kglobalaccel) antwortet nicht."
            }

            SettingsTextFieldRow {
                text: "Suchen"
                placeholderText: "Aktion, Bereich oder Taste, etwa «Meta+S»"
                value: root.filterText
                onValueEdited: value => {
                    root.filterText = value;
                    filterDelay.restart();
                }
            }

            SettingsDropdownRow {
                text: "Bereich"
                enableFuzzySearch: true
                options: ["Alle Bereiche"].concat(root.groupNames)
                currentValue: root.group === "" ? "Alle Bereiche" : root.group
                onValueChanged: value => root.group = value === "Alle Bereiche" ? "" : value
            }

            SettingsRow {
                visible: root.capture !== null
                title: root.capture ? "Taste drücken für «" + root.capture.actionName + "»" : ""
                subtitle: "Esc bricht ab" + (root.capture && !root.capture.isNew ? ", Rücktaste entfernt das Kürzel" : "") + ". KDEs Kürzel ruhen so lange."
                iconName: "keyboard_alt"
                active: true
            }

            SettingsRow {
                visible: root.conflict !== null
                title: root.conflict ? root.keyText(root.conflict.combo) + " ist schon vergeben" : ""
                subtitle: root.conflict ? "an «" + root.conflict.owner.actionName + "» (" + root.conflict.owner.componentName + ")" : ""
                iconName: "warning"
                iconColor: Theme.warning

                body: Flow {
                    width: parent.width
                    spacing: Theme.spacingS
                    DButton {
                        text: "Trotzdem übernehmen"
                        onClicked: root.resolveConflict(true)
                    }
                    DButton {
                        text: "Abbrechen"
                        variant: "text"
                        onClicked: root.resolveConflict(false)
                    }
                }
            }

            SettingsNoteRow {
                visible: root.message !== ""
                text: root.message
            }

            SettingsNoteRow {
                visible: root.loading && root.info === null
                text: "Lese die Kürzel …"
            }
        }
    }

    DListView {
        id: list

        readonly property real columnWidth: Math.min(SettingsMetrics.contentMaxWidth, width - SettingsMetrics.focusGutter * 2)

        anchors.top: toolbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        keyNavigationEnabled: false
        // Sonst gibt die ListView jeder neuen Zeile den Fokus und nimmt ihn dem Suchfeld.
        currentIndex: -1
        spacing: SettingsMetrics.groupGap
        model: root.shown

        header: Item {
            width: list.width
            height: headerColumn.height + SettingsMetrics.cardGap

            Column {
                id: headerColumn
                width: list.columnWidth
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: SettingsMetrics.focusGutter
                spacing: SettingsMetrics.cardGap

                SettingsCard {
                    width: parent.width
                    iconName: "add"
                    title: "Neues Kürzel"
                    settingKey: "alpeShortcutNew"
                    tags: ["neu", "befehl", "programm", "starten", "eigenes kürzel"]

                    SettingsDropdownRow {
                        text: "Art"
                        options: ["Programm starten", "Befehl ausführen"]
                        currentValue: root.newKind === "app" ? "Programm starten" : "Befehl ausführen"
                        onValueChanged: value => root.newKind = value === "Programm starten" ? "app" : "command"
                    }

                    SettingsDropdownRow {
                        visible: root.newKind === "app"
                        text: "Programm"
                        enableFuzzySearch: true
                        emptyText: root.apps.length === 0 ? "Lese die Programme …" : "Programm wählen"
                        options: root.apps.map(a => a.name)
                        currentValue: root.newApplication ? root.newApplication.name : ""
                        onValueChanged: value => {
                            const hit = root.apps.find(a => a.name === value);
                            root.newApp = hit ? hit.id : "";
                        }
                    }

                    SettingsTextFieldRow {
                        visible: root.newKind === "command"
                        text: "Name"
                        placeholderText: "etwa «Terminal»"
                        value: root.newName
                        onValueEdited: value => root.newName = value
                    }

                    SettingsTextFieldRow {
                        visible: root.newKind === "command"
                        text: "Befehl"
                        placeholderText: "etwa «kitty --single-instance»"
                        value: root.newCommand
                        onValueEdited: value => root.newCommand = value
                    }

                    SettingsRow {
                        title: "Taste festlegen"
                        subtitle: root.newReady ? "Danach die gewünschte Kombination drücken." : root.newKind === "app" ? "Zuerst ein Programm wählen." : "Zuerst Name und Befehl eingeben."
                        iconName: "keyboard_alt"

                        DButton {
                            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                            text: "Aufnehmen"
                            iconName: "radio_button_checked"
                            variant: "tonal"
                            enabled: root.newReady && root.capture === null
                            onClicked: root.captureNew()
                        }
                    }
                }

                SettingsSectionLabel {
                    width: parent.width
                    text: root.shown.length === root.total ? root.total + " Aktionen" : root.shown.length + " von " + root.total + " Aktionen"
                }
            }
        }

        delegate: Item {
            id: entry

            required property var modelData
            required property int index

            width: list.width
            height: entryColumn.height

            Column {
                id: entryColumn
                width: list.columnWidth
                anchors.horizontalCenter: parent.horizontalCenter

                // Bereichsname über der ersten Zeile eines Bereichs
                SettingsSectionLabel {
                    width: parent.width
                    visible: entry.modelData.first && root.group === ""
                    text: entry.modelData.group
                }

                SettingsRow {
                    id: row
                    width: parent.width
                    inGroup: true
                    topRadius: entry.modelData.first ? Theme.groupedListOuterRadius : SettingsMetrics.groupInnerRadius
                    bottomRadius: entry.modelData.last ? Theme.groupedListOuterRadius : SettingsMetrics.groupInnerRadius
                    dividerBefore: !entry.modelData.first
                    title: entry.modelData.actionName
                    singleLineTitle: true
                    subtitle: root.subtitleOf(entry.modelData)
                    trailingBadge: entry.modelData.keyLabel
                    clickable: true
                    active: root.capture !== null && root.capture.action === entry.modelData.action && root.capture.component === entry.modelData.component
                    onClicked: root.beginCapture(entry.modelData)

                    DButton {
                        visible: entry.modelData.changed
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        text: "Vorgabe"
                        iconName: "restart_alt"
                        variant: "text"
                        onClicked: root.setKeys(entry.modelData, entry.modelData.defaults)
                    }

                    DActionButton {
                        visible: entry.modelData.removable
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        iconName: "delete"
                        iconColor: Theme.surfaceVariantText
                        tooltipText: entry.modelData.custom ? "Befehl und Kürzel entfernen" : "Kürzel entfernen"
                        onClicked: root.remove(entry.modelData)
                    }
                }
            }
        }

        footer: Item {
            width: list.width
            height: SettingsMetrics.pagePaddingV
        }
    }
}
