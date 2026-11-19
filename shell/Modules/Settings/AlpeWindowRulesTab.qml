pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets

// Alpe: Fensterregeln unter KWin (kwinrulesrc), ersetzt dort die Seite des Ursprungsprojekts,
// die nur Niri und Hyprland kennt. Pro Regel: Programm, Deckkraft, Weichzeichnen (Better Blur DX),
// Titelleiste, Lage und Grösse merken, im Vordergrund.
Item {
    id: root

    property var parentModal: null

    readonly property var rules: backend.state ? backend.state.rules : []
    readonly property var blurClasses: backend.state ? backend.state.blurClasses : []
    readonly property bool blurReady: backend.state ? !!(backend.state.effects.blur.loaded || backend.state.effects.blur.enabled) : false
    property string selectedId: ""
    // Entwurf der gewählten Regel: Änderungen erst mit «Übernehmen».
    property var draft: null
    property bool dirty: false
    property bool picking: false

    AlpeKwinBackend {
        id: backend
    }

    readonly property var matchValues: [1, 2, 3, 0]
    readonly property var matchOptions: ["Genau dieses Programm", "Name enthält", "Regulärer Ausdruck", "Alle Programme"]
    // Titel als zweites Kriterium (kwinrulesrc title/titlematch), wie im KDE-Dialog
    readonly property var titleMatchValues: [0, 1, 2, 3]
    readonly property var titleMatchOptions: ["Titel egal", "Genau dieser Titel", "Titel enthält", "Regulärer Ausdruck"]

    // Laufende Programme für «Neue Regel»
    readonly property var runningApps: {
        const seen = {};
        const out = [];
        for (const t of (KwinService.toplevels || [])) {
            const id = String(t.appId || "");
            if (id !== "" && !seen[id]) {
                seen[id] = true;
                out.push(id);
            }
        }
        return out.sort();
    }

    function blurred(rule) {
        return !!rule.wmclass && blurClasses.some(c => c.toLowerCase() === String(rule.wmclass).toLowerCase());
    }

    function summary(rule) {
        const parts = [];
        const match = parseInt(rule.wmclassmatch || 0);
        parts.push(match === 0 || !rule.wmclass ? "alle Programme" : rule.wmclass);
        if (parseInt(rule.titlematch || 0) > 0 && rule.title)
            parts.push("Titel «" + String(rule.title).slice(0, 30) + "»");
        if (parseInt(rule.opacityactiverule || 0) > 0)
            parts.push("Deckkraft " + rule.opacityactive + " %");
        if (blurred(rule))
            parts.push("weichgezeichnet");
        if (parseInt(rule.noborderrule || 0) > 0)
            parts.push(rule.noborder === "true" ? "ohne Titelleiste" : "mit Titelleiste");
        if (parseInt(rule.positionrule || 0) === 4)
            parts.push("Lage merken");
        if (parseInt(rule.sizerule || 0) === 4)
            parts.push("Grösse merken");
        if (parseInt(rule.aboverule || 0) > 0 && rule.above === "true")
            parts.push("im Vordergrund");
        if (rule.other && rule.other.filter(k => !/^(Description|wmclass|wmclassmatch|wmclasscomplete|types|title|titlematch)$/.test(k)).length > 0)
            parts.push("weitere KDE-Einstellungen");
        return parts.join(" · ");
    }

    function select(rule) {
        selectedId = rule ? rule.id : "";
        draft = rule ? {
            "id": rule.id,
            "Description": rule.Description || "",
            "wmclass": rule.wmclass || "",
            "wmclassmatch": parseInt(rule.wmclassmatch || 0),
            "title": rule.title || "",
            "titlematch": parseInt(rule.titlematch || 0),
            "opacityOn": parseInt(rule.opacityactiverule || 0) > 0,
            "opacityactive": parseInt(rule.opacityactive || 100),
            "inactiveOn": parseInt(rule.opacityinactiverule || 0) > 0,
            "opacityinactive": parseInt(rule.opacityinactive || 100),
            "blur": blurred(rule),
            "border": parseInt(rule.noborderrule || 0) === 0 ? "keep" : (rule.noborder === "true" ? "hide" : "show"),
            "position": parseInt(rule.positionrule || 0) === 4,
            "size": parseInt(rule.sizerule || 0) === 4,
            "above": parseInt(rule.aboverule || 0) > 0 && rule.above === "true"
        } : null;
        dirty = false;
    }

    function change(key, value) {
        const next = Object.assign({}, draft);
        next[key] = value;
        draft = next;
        dirty = true;
    }

    function newRule(app, title) {
        selectedId = "";
        draft = {
            "id": "", "Description": app ? app : "Neue Regel", "wmclass": app || "", "wmclassmatch": app ? 1 : 0,
            "title": title || "", "titlematch": title ? 1 : 0,
            "opacityOn": false, "opacityactive": 90, "inactiveOn": false, "opacityinactive": 85,
            "blur": false, "border": "keep", "position": false, "size": false, "above": false
        };
        dirty = true;
    }

    // Entwurf -> Schlüssel der kwinrulesrc (null löscht)
    function values(d) {
        const v = {
            "Description": d.Description || d.wmclass || "Regel",
            "wmclass": d.wmclassmatch === 0 ? null : d.wmclass,
            "wmclassmatch": d.wmclassmatch,
            "wmclasscomplete": d.wmclassmatch === 0 ? null : false,
            "title": d.titlematch > 0 && d.title ? d.title : null,
            "titlematch": d.titlematch > 0 && d.title ? d.titlematch : null,
            "opacityactive": d.opacityOn ? d.opacityactive : null,
            "opacityactiverule": d.opacityOn ? 2 : null,
            "opacityinactive": d.inactiveOn ? d.opacityinactive : null,
            "opacityinactiverule": d.inactiveOn ? 2 : null,
            "noborder": d.border === "keep" ? null : d.border === "hide",
            "noborderrule": d.border === "keep" ? null : 2,
            "positionrule": d.position ? 4 : null,
            "sizerule": d.size ? 4 : null,
            "above": d.above ? true : null,
            "aboverule": d.above ? 2 : null
        };
        if (!d.position)
            v.position = null;
        if (!d.size)
            v.size = null;
        return v;
    }

    function save() {
        if (!draft)
            return;
        const payload = {
            "id": draft.id,
            "values": values(draft),
            "blur": draft.wmclassmatch !== 0 && draft.wmclass !== "" && draft.blur
        };
        backend.run(["rule-set", JSON.stringify(payload)], result => {
            dirty = false;
            const id = result && result.id ? result.id : draft.id;
            backend.run(["state"], state => {
                if (state)
                    backend.state = state;
                select(rules.find(r => r.id === id) || null);
            });
        });
    }

    function remove() {
        if (!draft || draft.id === "") {
            select(null);
            return;
        }
        // Weichzeichnen gehört zur Regel: beim Löschen aus der Liste nehmen.
        const id = draft.id;
        const finish = () => backend.run(["rule-delete", id], () => {
                select(null);
                backend.refresh();
            });
        if (draft.blur)
            backend.run(["rule-set", JSON.stringify({ "id": id, "values": {}, "blur": false })], finish);
        else
            finish();
    }

    SettingsPage {
        SettingsCard {
            width: parent.width
            iconName: "select_window"
            title: "Regeln"
            settingKey: "alpeWindowRules"
            tags: ["fensterregeln", "window rules", "deckkraft", "opacity", "blur", "titelleiste"]

            SettingsNoteRow {
                visible: backend.state !== null && root.rules.length === 0
                text: "Noch keine Regeln."
            }

            Repeater {
                model: root.rules

                SettingsRow {
                    required property var modelData
                    width: parent ? parent.width : 0
                    title: modelData.Description || modelData.wmclass || "Regel"
                    subtitle: root.summary(modelData)
                    iconName: parseInt(modelData.wmclassmatch || 0) === 0 ? "select_all" : "web_asset"
                    clickable: true
                    showChevron: true
                    active: root.selectedId === modelData.id
                    onClicked: root.select(modelData)
                }
            }

            SettingsRow {
                title: "Fenster wählen"
                subtitle: root.picking ? "Jetzt das gewünschte Fenster anklicken (Esc bricht ab) …" : "Fenster anklicken – Alpe füllt Klasse und Titel ein (KWin zeigt ein Fadenkreuz)."
                iconName: "ads_click"

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.picking ? "Warte …" : "Fenster anklicken"
                    iconName: "ads_click"
                    variant: "tonal"
                    enabled: !root.picking
                    onClicked: {
                        root.picking = true;
                        backend.run(["pick"], info => {
                            root.picking = false;
                            const cls = info && (info.resourceClass || info.desktopFile) ? String(info.resourceClass || info.desktopFile) : "";
                            if (cls === "")
                                return;
                            // Wie am Mac: immer eine neue Regel mit Klasse und Titel (genau); der Titel
                            // lässt sich danach auf «enthält» oder «egal» stellen.
                            const caption = info.caption ? String(info.caption) : "";
                            root.newRule(cls, caption);
                            if (caption)
                                root.change("Description", cls + " (" + caption.slice(0, 40) + ")");
                        });
                    }
                }
            }

            SettingsDropdownRow {
                text: "Neue Regel für"
                description: "Ein laufendes Programm wählen; der Name lässt sich danach ändern."
                options: ["Anderes Programm …"].concat(root.runningApps)
                currentValue: ""
                emptyText: "Programm wählen"
                onValueChanged: value => root.newRule(value === "Anderes Programm …" ? "" : value)
            }
        }

        SettingsCard {
            width: parent.width
            visible: root.draft !== null
            iconName: "tune"
            title: root.draft && root.draft.id === "" ? "Neue Regel" : "Regel bearbeiten"
            settingKey: "alpeWindowRuleEdit"

            SettingsTextFieldRow {
                text: "Name"
                value: root.draft ? root.draft.Description : ""
                onEditingFinished: value => root.change("Description", value)
            }

            SettingsDropdownRow {
                text: "Gilt für"
                options: root.matchOptions
                currentValue: root.draft ? root.matchOptions[Math.max(0, root.matchValues.indexOf(root.draft.wmclassmatch))] : ""
                onValueChanged: value => root.change("wmclassmatch", root.matchValues[root.matchOptions.indexOf(value)])
            }

            SettingsTextFieldRow {
                visible: root.draft && root.draft.wmclassmatch !== 0
                text: "Fensterklasse"
                description: "Wie KWin das Programm nennt, etwa kitty, dev.zed.Zed, org.gnome.Nautilus."
                value: root.draft ? root.draft.wmclass : ""
                onEditingFinished: value => root.change("wmclass", value.trim())
            }

            SettingsDropdownRow {
                text: "Fenstertitel"
                description: "Zusätzlich zur Klasse; «Titel enthält» passt auch, wenn sich der Titel ändert."
                options: root.titleMatchOptions
                currentValue: root.draft ? root.titleMatchOptions[Math.max(0, root.titleMatchValues.indexOf(root.draft.titlematch))] : ""
                onValueChanged: value => root.change("titlematch", root.titleMatchValues[root.titleMatchOptions.indexOf(value)])
            }

            SettingsTextFieldRow {
                visible: !!(root.draft && root.draft.titlematch !== 0)
                text: "Titel"
                value: root.draft ? root.draft.title : ""
                onEditingFinished: value => root.change("title", value)
            }

            SettingsToggleRow {
                text: "Deckkraft, wenn aktiv"
                checked: !!(root.draft && root.draft.opacityOn)
                onToggled: checked => root.change("opacityOn", checked)
            }

            SettingsSliderRow {
                visible: !!(root.draft && root.draft.opacityOn)
                text: "Deckkraft aktiv"
                unit: "%"
                minimum: 20
                maximum: 100
                value: root.draft ? root.draft.opacityactive : 100
                onSliderDragFinished: finalValue => root.change("opacityactive", finalValue)
            }

            SettingsToggleRow {
                text: "Deckkraft, wenn inaktiv"
                checked: !!(root.draft && root.draft.inactiveOn)
                onToggled: checked => root.change("inactiveOn", checked)
            }

            SettingsSliderRow {
                visible: !!(root.draft && root.draft.inactiveOn)
                text: "Deckkraft inaktiv"
                unit: "%"
                minimum: 20
                maximum: 100
                value: root.draft ? root.draft.opacityinactive : 100
                onSliderDragFinished: finalValue => root.change("opacityinactive", finalValue)
            }

            SettingsToggleRow {
                visible: !!(root.draft && root.draft.wmclassmatch !== 0)
                text: "Hintergrund weichzeichnen"
                description: root.blurReady ? "Über Better Blur DX. Wirkt nur, wo das Fenster durchscheint – meist zusammen mit einer Deckkraft unter 100 %." : "Better Blur DX ist nicht aktiv; einschalten unter «Fenster & Effekte»."
                checked: !!(root.draft && root.draft.blur)
                onToggled: checked => root.change("blur", checked)
            }

            SettingsDropdownRow {
                text: "Titelleiste"
                options: ["Nicht ändern", "Ausblenden", "Anzeigen"]
                currentValue: !root.draft ? "" : root.draft.border === "hide" ? "Ausblenden" : root.draft.border === "show" ? "Anzeigen" : "Nicht ändern"
                onValueChanged: value => root.change("border", value === "Ausblenden" ? "hide" : value === "Anzeigen" ? "show" : "keep")
            }

            SettingsToggleRow {
                text: "Lage merken"
                description: "Das Fenster öffnet dort, wo es zuletzt war."
                checked: !!(root.draft && root.draft.position)
                onToggled: checked => root.change("position", checked)
            }

            SettingsToggleRow {
                text: "Grösse merken"
                checked: !!(root.draft && root.draft.size)
                onToggled: checked => root.change("size", checked)
            }

            SettingsToggleRow {
                text: "Immer im Vordergrund"
                checked: !!(root.draft && root.draft.above)
                onToggled: checked => root.change("above", checked)
            }

            SettingsRow {
                title: root.dirty ? "Nicht übernommene Änderungen" : "Übernommen"
                subtitle: "Weitere Eigenschaften derselben Regel bleiben erhalten, auch wenn Alpe sie nicht zeigt."
                iconName: root.dirty ? "edit" : "check_circle"

                body: Flow {
                    width: parent.width
                    spacing: Theme.spacingS

                    DButton {
                        text: "Übernehmen"
                        iconName: "check"
                        enabled: root.dirty
                        onClicked: root.save()
                    }
                    DButton {
                        text: root.draft && root.draft.id === "" ? "Verwerfen" : "Regel löschen"
                        iconName: "delete"
                        variant: "text"
                        danger: true
                        onClicked: root.remove()
                    }
                }
            }
        }
    }
}
