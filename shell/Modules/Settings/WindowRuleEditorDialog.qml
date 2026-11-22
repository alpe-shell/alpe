pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import "../../Common/WindowRuleMerge.js" as WindowRuleMerge
import qs.Services
import qs.Alpe.Widgets
import qs.Widgets
import qs.Modules.Settings.Widgets

AlpeDialog {
    id: root

    property var editingRule: null
    property var targetWindow: null
    property bool submitting: false
    property bool applying: false
    readonly property bool isEditMode: editingRule !== null
    readonly property bool isHyprland: CompositorService.isHyprland
    readonly property bool fieldsEnabled: !submitting
    readonly property bool halfPair: isHyprland && (!!moveXInput.text.trim() !== !!moveYInput.text.trim() || !!sizeWInput.text.trim() !== !!sizeHInput.text.trim())

    property var openingFlags: []
    property var hyprFlags: []
    property bool opacityOn: false
    property int opacityValue: 100
    property bool cornerRadiusOn: false
    property int cornerRadiusValue: 12
    property var storedMatch: ({})
    property var storedActions: ({})
    property var hyprEffectFlags: []
    property int focusOnActivateTri: 0
    property bool scrollingWidthOn: false
    property int scrollingWidthValue: 50
    property string tonemapValue: ""
    property string contentValue: ""
    property int fullscreenInternalValue: -1
    property int fullscreenClientValue: -1

    readonly property var triLabels: [I18n.tr("Default"), I18n.tr("On"), I18n.tr("Off")]
    readonly property var tonemapOptions: root.withCurrent(["", "off", "on", "clamp", "limited"], root.tonemapValue)
    readonly property var contentOptions: root.withCurrent(["", "none", "photo", "video", "game"], root.contentValue)
    // Index is the Hyprland state + 1; 0 leaves the match unset.
    readonly property var fullscreenStateLabels: [I18n.tr("Default"), I18n.tr("None"), I18n.tr("Maximized", "adjective, Hyprland window fullscreen state 1"), I18n.tr("Fullscreen"), I18n.tr("Maximized and fullscreen", "Hyprland window fullscreen state 3")]
    readonly property var hyprMatchKeys: ["initialClass", "initialTitle", "tag", "workspace", "content", "xdgTag", "fullscreenStateInternal", "fullscreenStateClient"]
    readonly property var hyprFocusOptions: [
        {
            "label": I18n.tr("No initial focus"),
            "value": "noInitialFocus",
            "tooltip": I18n.tr("Opens without taking keyboard focus", "window rule option tooltip")
        },
        {
            "label": I18n.tr("Stay focused"),
            "value": "stayFocused",
            "tooltip": I18n.tr("Keeps focus while the window is open", "window rule option tooltip")
        }
    ]
    readonly property var hyprPointerOptions: [
        {
            "label": I18n.tr("Confine pointer"),
            "value": "confinePointer",
            "tooltip": I18n.tr("Keeps the pointer inside the window", "window rule option tooltip")
        },
        {
            "label": I18n.tr("No XDG drags"),
            "value": "noXdgDrags",
            "tooltip": I18n.tr("Ignores drag and drop started by the window", "window rule option tooltip")
        }
    ]
    readonly property var hyprRenderOptions: [
        {
            "label": I18n.tr("No glow"),
            "value": "noGlow",
            "needs": "decoration:glow:enabled"
        },
        {
            "label": I18n.tr("No wobble"),
            "value": "noWobble",
            "needs": "decoration:wobble:enabled"
        },
        {
            "label": I18n.tr("No auto HDR"),
            "value": "noAutoHdr",
            "tooltip": I18n.tr("Never switches the monitor to HDR for this window", "window rule option tooltip")
        }
    ].filter(option => !option.needs || HyprlandService.hyprSupports(option.needs))
    readonly property var hyprEffectOptions: root.hyprFocusOptions.concat(root.hyprPointerOptions, root.hyprRenderOptions)
    readonly property var openingOptions: [
        {
            "label": I18n.tr("Float"),
            "value": "float"
        },
        {
            "label": I18n.tr("Maximize", "verb, window rule action to open the window maximized"),
            "value": "maximize"
        },
        {
            "label": I18n.tr("Fullscreen", "window rule action, open the window fullscreen"),
            "value": "fullscreen"
        }
    ]
    readonly property var hyprOptions: [
        {
            "label": I18n.tr("Tile"),
            "value": "tile"
        },
        {
            "label": I18n.tr("No focus"),
            "value": "nofocus"
        },
        {
            "label": I18n.tr("No border"),
            "value": "noborder"
        },
        {
            "label": I18n.tr("No shadow"),
            "value": "noshadow"
        },
        {
            "label": I18n.tr("No dim"),
            "value": "nodim"
        },
        {
            "label": I18n.tr("No blur"),
            "value": "noblur"
        },
        {
            "label": I18n.tr("No anim"),
            "value": "noanim"
        },
        {
            "label": I18n.tr("No Rounding"),
            "value": "norounding"
        },
        {
            "label": I18n.tr("Pin", "verb, keep an item pinned in place"),
            "value": "pin"
        },
        {
            "label": I18n.tr("Opaque", "adjective, window rule checkbox forcing an opaque window"),
            "value": "opaque"
        }
    ]

    signal ruleSubmitted
    signal ruleApplied

    embedded: nativeWindow
    opened: nativeWindow
    maximumWidth: SettingsMetrics.formDialogWidth
    surfaceColor: Theme.hostSurface
    title: isEditMode ? I18n.tr("Edit Window Rule") : I18n.tr("New Window Rule")
    closeEnabled: !submitting
    acceptEnabled: !submitting && !halfPair
    onAccepted: submit()

    ListModel {
        id: extraMatchModel
    }

    function show(window) {
        editingRule = null;
        targetWindow = window || null;
        resetForm();
        if (targetWindow?.appId) {
            nameInput.text = targetWindow.appId;
            appIdInput.text = "^" + targetWindow.appId + "$";
        }
        // Alpe: mit «Fenster wählen» angeklickt, Titel gleich mit übernehmen (wie KDE)
        if (targetWindow?.alpePicked && targetWindow.title) {
            const t = String(targetWindow.title).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
            titleInput.text = "^" + t + "$";
        }
        present();
    }

    function showEdit(rule) {
        if (!rule) {
            show();
            return;
        }
        editingRule = rule;
        targetWindow = null;
        resetForm();
        populateForm(rule);
        present();
    }

    function showCopy(rule) {
        if (!rule) {
            show();
            return;
        }
        editingRule = null;
        targetWindow = null;
        resetForm();
        populateForm(rule);
        present();
    }

    function present() {
        opened = true;
        forceActiveFocus();
        nameInput.forceActiveFocus();
    }

    function flagSet(flags, value, checked) {
        const next = flags.filter(flag => flag !== value);
        if (checked)
            next.push(value);
        return next;
    }

    function triFromBool(value) {
        if (value === true)
            return 1;
        if (value === false)
            return 2;
        return 0;
    }

    function applyCond(target, key, triState) {
        if (triState === 1)
            target[key] = true;
        else if (triState === 2)
            target[key] = false;
    }

    function defaultLabel(value) {
        return value === "" ? I18n.tr("Default") : value;
    }

    // A value written by hand that the list does not know must still show and save.
    function withCurrent(values, current) {
        return values.includes(current) ? values : values.concat([current]);
    }

    function resetForm() {
        nameInput.text = "";
        appIdInput.text = "";
        titleInput.text = "";
        extraMatchModel.clear();
        for (const cond of matchConditions)
            cond.triState = 0;
        openingFlags = [];
        hyprFlags = [];
        opacityOn = false;
        opacityValue = 100;
        cornerRadiusOn = false;
        cornerRadiusValue = 12;
        storedMatch = {};
        storedActions = {};
        hyprEffectFlags = [];
        focusOnActivateTri = 0;
        scrollingWidthOn = false;
        scrollingWidthValue = 50;
        tonemapValue = "";
        contentValue = "";
        fullscreenInternalValue = -1;
        fullscreenClientValue = -1;
        hyprMatchCard.expanded = false;
        hyprEffectsCard.expanded = false;
        for (const field of [moveXInput, moveYInput, sizeWInput, sizeHInput, monitorInput, hyprWorkspaceInput, initialClassInput, initialTitleInput, matchTagInput, xdgTagInput, matchWorkspaceInput, borderColorInput, suppressEventInput])
            field.text = "";
    }

    function populateForm(rule) {
        nameInput.text = rule.name || "";
        const matchList = (rule.matches && rule.matches.length > 0) ? rule.matches : [rule.matchCriteria || {}];
        const match = matchList[0] || {};
        storedMatch = match;
        appIdInput.text = match.appId || "";
        titleInput.text = match.title || "";
        for (let i = 1; i < matchList.length; i++)
            extraMatchModel.append({
                "rowAppId": matchList[i].appId || "",
                "rowTitle": matchList[i].title || "",
                "rowStored": JSON.stringify(matchList[i])
            });
        for (const cond of matchConditions)
            cond.triState = triFromBool(match[cond.key]);
        initialClassInput.text = match.initialClass || "";
        initialTitleInput.text = match.initialTitle || "";
        matchTagInput.text = match.tag || "";
        xdgTagInput.text = match.xdgTag || "";
        matchWorkspaceInput.text = match.workspace || "";
        contentValue = match.content || "";
        fullscreenInternalValue = match.fullscreenStateInternal ?? -1;
        fullscreenClientValue = match.fullscreenStateClient ?? -1;
        hyprMatchCard.expanded = hyprMatchKeys.some(key => match[key] !== undefined && match[key] !== "");

        const actions = rule.actions || {};
        storedActions = actions;
        const flags = [];
        if (actions.openFloating)
            flags.push("float");
        if (actions.openMaximized)
            flags.push("maximize");
        if (actions.openFullscreen)
            flags.push("fullscreen");
        openingFlags = flags;

        opacityOn = actions.opacity !== undefined && actions.opacity !== null;
        opacityValue = opacityOn ? Math.round(actions.opacity * 100) : 100;
        cornerRadiusOn = actions.cornerRadius !== undefined && actions.cornerRadius !== null;
        cornerRadiusValue = cornerRadiusOn ? actions.cornerRadius : 12;
        hyprFlags = hyprOptions.map(option => option.value).filter(value => actions[value]);
        moveXInput.text = actions.moveX || "";
        moveYInput.text = actions.moveY || "";
        sizeWInput.text = actions.sizeWidth || "";
        sizeHInput.text = actions.sizeHeight || "";
        monitorInput.text = actions.monitor || "";
        hyprWorkspaceInput.text = actions.workspace || "";

        hyprEffectFlags = hyprEffectOptions.map(option => option.value).filter(value => actions[value] === true);
        focusOnActivateTri = triFromBool(actions.focusOnActivate);
        scrollingWidthOn = actions.scrollingWidth !== undefined && actions.scrollingWidth !== null;
        scrollingWidthValue = scrollingWidthOn ? Math.round(actions.scrollingWidth * 100) : 50;
        tonemapValue = actions.tonemap || "";
        borderColorInput.text = actions.borderColor || "";
        suppressEventInput.text = actions.suppressEvent || "";
        hyprEffectsCard.expanded = hyprEffectFlags.length > 0 || focusOnActivateTri !== 0 || scrollingWidthOn || !!tonemapValue || !!borderColorInput.text || !!suppressEventInput.text;

    }

    function collectMatches() {
        const conds = matchConditions.filter(cond => cond.visible);
        const owned = ["appId", "title"].concat(conds.map(cond => cond.key), isHyprland ? hyprMatchKeys : []);
        const matchCriteria = WindowRuleMerge.carry(storedMatch, owned);
        if (appIdInput.text.trim())
            matchCriteria.appId = appIdInput.text.trim();
        if (titleInput.text.trim())
            matchCriteria.title = titleInput.text.trim();
        for (const cond of conds)
            applyCond(matchCriteria, cond.key, cond.triState);
        if (isHyprland) {
            const texts = {
                "initialClass": initialClassInput.text.trim(),
                "initialTitle": initialTitleInput.text.trim(),
                "tag": matchTagInput.text.trim(),
                "xdgTag": xdgTagInput.text.trim(),
                "workspace": matchWorkspaceInput.text.trim(),
                "content": contentValue
            };
            for (const key in texts) {
                if (texts[key])
                    matchCriteria[key] = texts[key];
            }
            if (fullscreenInternalValue >= 0)
                matchCriteria.fullscreenStateInternal = fullscreenInternalValue;
            if (fullscreenClientValue >= 0)
                matchCriteria.fullscreenStateClient = fullscreenClientValue;
        }
        const matches = [];
        if (Object.keys(matchCriteria).length > 0)
            matches.push(matchCriteria);
        return {
            matchCriteria,
            matches
        };
    }

    function ownedActionKeys() {
        const keys = ["opacity", "openFloating", "openMaximized", "openFullscreen", "cornerRadius"];
        if (isHyprland)
            return keys.concat(hyprOptions.map(option => option.value), hyprEffectOptions.map(option => option.value), ["sizeWidth", "sizeHeight", "moveX", "moveY", "monitor", "workspace", "focusOnActivate", "scrollingWidth", "tonemap", "borderColor", "suppressEvent"]);
        return keys;
    }

    function collectActions() {
        const actions = WindowRuleMerge.carry(storedActions, ownedActionKeys());
        const has = value => openingFlags.includes(value);
        if (opacityOn)
            actions.opacity = opacityValue / 100;
        if (has("float"))
            actions.openFloating = true;
        if (has("maximize"))
            actions.openMaximized = true;
        if (has("fullscreen"))
            actions.openFullscreen = true;
        if (cornerRadiusOn)
            actions.cornerRadius = cornerRadiusValue;

        if (isHyprland) {
            for (const flag of hyprFlags)
                actions[flag] = true;
            if (sizeWInput.text.trim())
                actions.sizeWidth = sizeWInput.text.trim();
            if (sizeHInput.text.trim())
                actions.sizeHeight = sizeHInput.text.trim();
            if (moveXInput.text.trim())
                actions.moveX = moveXInput.text.trim();
            if (moveYInput.text.trim())
                actions.moveY = moveYInput.text.trim();
            if (monitorInput.text.trim())
                actions.monitor = monitorInput.text.trim();
            if (hyprWorkspaceInput.text.trim())
                actions.workspace = hyprWorkspaceInput.text.trim();
            for (const flag of hyprEffectFlags)
                actions[flag] = true;
            applyCond(actions, "focusOnActivate", focusOnActivateTri);
            if (scrollingWidthOn)
                actions.scrollingWidth = scrollingWidthValue / 100;
            if (tonemapValue)
                actions.tonemap = tonemapValue;
            if (borderColorInput.text.trim())
                actions.borderColor = borderColorInput.text.trim();
            if (suppressEventInput.text.trim())
                actions.suppressEvent = suppressEventInput.text.trim();
        }

        return actions;
    }

    function submit(keepOpen = false) {
        if (submitting || !acceptEnabled)
            return;
        const {
            matchCriteria,
            matches
        } = collectMatches();
        const ruleData = {
            name: nameInput.text.trim() || matchCriteria.appId || I18n.tr("Rule", "noun, fallback name for an unnamed window rule"),
            matchCriteria: matchCriteria,
            actions: collectActions(),
            enabled: true
        };
        // No exclude editor yet; carry existing excludes through so an edit doesn't delete them (#2996)
        if (isEditMode && (editingRule.excludes?.length ?? 0) > 0)
            ruleData.excludes = editingRule.excludes;

        const compositor = CompositorService.compositor;
        const ruleJson = JSON.stringify(ruleData);
        const args = isEditMode ? [Proc.backendBin, "config", "windowrules", "update", compositor, editingRule.id, ruleJson] : [Proc.backendBin, "config", "windowrules", "add", compositor, ruleJson];
        submitting = true;
        applying = keepOpen;
        Proc.runCommand(isEditMode ? "update-windowrule" : "add-windowrule", args, (output, exitCode) => {
            root.submitting = false;
            root.applying = false;
            if (exitCode !== 0)
                return;
            CompositorService.reloadAfterWindowRuleWrite();
            if (keepOpen)
                root.ruleApplied();
            else
                root.ruleSubmitted();
        });
    }

    component MatchCond: StyledButton {
        id: mc

        property string label: ""
        property string key: ""
        property int triState: 0
        property string unsetLabel: I18n.tr("Default")
        readonly property var stateText: [mc.unsetLabel, "true", "false"]
        readonly property var stateColor: [Theme.surfaceVariantText, Theme.primary, Theme.error]

        width: condRow.implicitWidth + Theme.spacingM * 2
        height: Theme.buttonHeightXS
        radius: Theme.cornerRadiusS
        color: enabled ? Theme.chipSurface : Theme.onSurface_12
        border.width: Theme.outlineWidth
        border.color: !enabled ? "transparent" : mc.triState === 0 ? Theme.outlineVariant : mc.stateColor[mc.triState]
        enabled: root.fieldsEnabled
        Accessible.role: Accessible.Button
        Accessible.name: label + ": " + stateText[triState]
        onClicked: triState = (triState + 1) % 3

        Row {
            id: condRow
            anchors.centerIn: parent
            spacing: Theme.spacingXS

            StyledText {
                text: mc.label
                font.pixelSize: Theme.fontSizeSmall
                color: mc.enabled ? Theme.onSurface : Theme.onSurface_38
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: stateBadge.implicitWidth + Theme.spacingS * 2
                height: stateBadge.implicitHeight + Theme.spacingXXS * 2
                radius: Theme.fullRadius(width, height)
                color: mc.enabled ? Theme.withAlpha(mc.stateColor[mc.triState], Theme.stateLayerPressed) : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    id: stateBadge
                    anchors.centerIn: parent
                    text: mc.stateText[mc.triState]
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Theme.fontWeightMedium
                    color: mc.enabled ? mc.stateColor[mc.triState] : Theme.onSurface_38
                }
            }
        }

        StateLayer {
            control: mc
            disabled: !mc.enabled
            stateColor: Theme.primary
        }

        FocusRing {
            visible: mc.visualFocus
        }
    }

    component FieldRow: SettingsRow {
        default property alias fields: fieldRow.data

        body: Row {
            id: fieldRow
            width: parent.width
            spacing: Theme.spacingS
        }
    }

    component Field: AlpeTextField {
        property int share: 1
        property int shares: 2

        width: Math.round((parent.width - parent.spacing * (shares - 1)) * share / shares)
        outlined: true
        enabled: root.fieldsEnabled
        onAccepted: root.submit()
    }

    readonly property var matchConditions: [condFloating, condFocused, condXwayland, condFullscreen, condPinned, condGroup, condModal]

    actions: [
        AlpeButton {
            text: I18n.tr("Cancel")
            enabled: root.closeEnabled
            variant: "text"
            onClicked: root.rejected()
        },
        AlpeButton {
            visible: root.isEditMode
            text: I18n.tr("Apply")
            enabled: root.acceptEnabled
            busy: root.applying
            variant: "tonal"
            onClicked: root.submit(true)
        },
        AlpeButton {
            text: root.isEditMode ? I18n.tr("Save") : I18n.tr("Add")
            enabled: root.acceptEnabled
            busy: root.submitting && !root.applying
            onClicked: root.submit()
        }
    ]

    SettingsGroup {
        SettingsRow {
            body: AlpeTextField {
                id: nameInput
                width: parent.width
                outlined: true
                leftIconName: "edit"
                labelText: I18n.tr("Rule Name")
                enabled: root.fieldsEnabled
                onAccepted: root.submit()
            }
        }
    }

    SettingsCard {
        title: I18n.tr("Match Criteria")
        SettingsRow {
            body: AlpeTextField {
                id: appIdInput
                width: parent.width
                outlined: true
                leftIconName: "apps"
                labelText: root.isHyprland ? I18n.tr("Class regex (e.g. ^firefox$)") : I18n.tr("App ID regex (e.g. ^firefox$)")
                enabled: root.fieldsEnabled
                onAccepted: root.submit()
            }
        }

        FieldRow {
            Field {
                id: titleInput
                width: parent.width - (addTitle.visible ? addTitle.width + parent.spacing : 0)
                leftIconName: "title"
                labelText: I18n.tr("Title regex (optional)")
            }

            AlpeActionButton {
                id: addTitle
                anchors.verticalCenter: parent.verticalCenter
                iconName: "add"
                visible: !root.isEditMode && !!root.targetWindow?.title
                tooltipText: I18n.tr("Add Title")
                onClicked: titleInput.text = "^" + root.targetWindow.title + "$"
            }
        }

        Repeater {
            model: extraMatchModel

            delegate: FieldRow {
                id: extraRow

                required property int index
                required property string rowAppId
                required property string rowTitle

                Field {
                    width: Math.round((parent.width - parent.spacing * 2 - removeMatch.width) / 2)
                    leftIconName: "apps"
                    labelText: I18n.tr("App ID regex")
                    text: extraRow.rowAppId
                    onTextEdited: extraMatchModel.setProperty(extraRow.index, "rowAppId", text)
                }

                Field {
                    width: Math.round((parent.width - parent.spacing * 2 - removeMatch.width) / 2)
                    leftIconName: "title"
                    labelText: I18n.tr("Title regex (optional)")
                    text: extraRow.rowTitle
                    onTextEdited: extraMatchModel.setProperty(extraRow.index, "rowTitle", text)
                }

                AlpeActionButton {
                    id: removeMatch
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "close"
                    Accessible.name: I18n.tr("Remove match")
                    onClicked: extraMatchModel.remove(extraRow.index)
                }
            }
        }
    }

    SettingsCard {
        title: I18n.tr("Match Conditions")
        visible: root.isHyprland

        SettingsRow {
            subtitle: I18n.tr("Optional state-based conditions applied to the first match.")
        }

        SettingsRow {
            body: Flow {
                width: parent.width
                spacing: Theme.spacingS

                MatchCond {
                    id: condFloating
                    key: "isFloating"
                    label: I18n.tr("Floating", "adjective, window rule match condition for floating windows")
                }
                MatchCond {
                    id: condFocused
                    key: "isFocused"
                    label: I18n.tr("Focused", "adjective, window rule match condition for the focused window")
                    visible: root.isHyprland
                }
                MatchCond {
                    id: condXwayland
                    key: "xwayland"
                    label: "XWayland"
                    visible: root.isHyprland
                }
                MatchCond {
                    id: condFullscreen
                    key: "fullscreen"
                    label: I18n.tr("Fullscreen", "adjective, window rule match condition for fullscreen windows")
                    visible: root.isHyprland
                }
                MatchCond {
                    id: condPinned
                    key: "pinned"
                    label: I18n.tr("Pinned", "adjective, state of a pinned window, clipboard entry or item")
                    visible: root.isHyprland
                }
                MatchCond {
                    id: condGroup
                    key: "group"
                    label: I18n.tr("Group", "noun, window rule match condition for windows in a Hyprland group")
                    visible: root.isHyprland
                }
                MatchCond {
                    id: condModal
                    key: "modal"
                    label: I18n.tr("Modal", "adjective, window rule match condition for modal dialogs")
                    visible: root.isHyprland
                }
            }
        }
    }

    SettingsCard {
        id: hyprMatchCard
        title: I18n.tr("Advanced Matching")
        visible: root.isHyprland
        collapsible: true
        expanded: false

        SettingsRow {
            subtitle: I18n.tr("Prefix a tag with negative: to match windows without it.", "window rule editor hint, negative: is literal syntax")
        }

        FieldRow {
            Field {
                id: initialClassInput
                leftIconName: "apps"
                labelText: I18n.tr("Initial class")
                placeholderText: "^steam$"
            }

            Field {
                id: initialTitleInput
                leftIconName: "title"
                labelText: I18n.tr("Initial title")
                placeholderText: "^Login$"
            }
        }

        FieldRow {
            Field {
                id: matchTagInput
                leftIconName: "sell"
                labelText: I18n.tr("Tag", "noun, Hyprland window tag in window rule match")
                placeholderText: "games"
            }

            Field {
                id: xdgTagInput
                leftIconName: "label"
                labelText: I18n.tr("XDG tag")
                placeholderText: "^portal$"
            }
        }

        FieldRow {
            Field {
                id: matchWorkspaceInput
                shares: 1
                leftIconName: "view_module"
                labelText: I18n.tr("Workspace")
                placeholderText: "w[tv1]"
            }
        }

        SettingsDropdownRow {
            text: I18n.tr("Content", "noun, window content type match: photo, video or game")
            options: root.contentOptions.map(root.defaultLabel)
            currentValue: root.defaultLabel(root.contentValue)
            enabled: root.fieldsEnabled
            onValueChanged: value => root.contentValue = root.contentOptions.find(option => root.defaultLabel(option) === value) ?? ""
        }

        SettingsDropdownRow {
            text: I18n.tr("Fullscreen state")
            options: root.fullscreenStateLabels
            currentValue: root.fullscreenStateLabels[root.fullscreenInternalValue + 1] ?? root.fullscreenStateLabels[0]
            enabled: root.fieldsEnabled
            onValueChanged: value => root.fullscreenInternalValue = root.fullscreenStateLabels.indexOf(value) - 1
        }

        SettingsDropdownRow {
            text: I18n.tr("Client fullscreen state")
            description: I18n.tr("The state the app believes it is in", "window rule match, Hyprland client fullscreen state")
            options: root.fullscreenStateLabels
            currentValue: root.fullscreenStateLabels[root.fullscreenClientValue + 1] ?? root.fullscreenStateLabels[0]
            enabled: root.fieldsEnabled
            onValueChanged: value => root.fullscreenClientValue = root.fullscreenStateLabels.indexOf(value) - 1
        }
    }

    SettingsCard {
        title: I18n.tr("Window Opening")

        SettingsRow {
            body: AlpeFilterChips {
                width: parent.width
                multiSelect: true
                showCounts: false
                enabled: root.fieldsEnabled
                model: root.openingOptions
                selectedValues: root.openingFlags
                onSelectionToggled: (index, selected) => root.openingFlags = root.flagSet(root.openingFlags, root.openingOptions[index].value, selected)
            }
        }
    }

    SettingsCard {
        title: I18n.tr("Dynamic Properties")
        visible: root.isHyprland

        SettingsToggleSliderRow {
            text: I18n.tr("Opacity")
            checked: root.opacityOn
            value: root.opacityValue
            minimum: 10
            unit: "%"
            enabled: root.fieldsEnabled
            onToggled: checked => root.opacityOn = checked
            onSliderValueChanged: newValue => root.opacityValue = newValue
        }

        SettingsToggleSliderRow {
            text: I18n.tr("Corner radius")
            checked: root.cornerRadiusOn
            value: root.cornerRadiusValue
            maximum: 20
            unit: "px"
            enabled: root.fieldsEnabled
            onToggled: checked => root.cornerRadiusOn = checked
            onSliderValueChanged: newValue => root.cornerRadiusValue = newValue
        }
    }

    SettingsCard {
        title: I18n.tr("Hyprland Options")
        visible: root.isHyprland

        SettingsRow {
            body: AlpeFilterChips {
                width: parent.width
                multiSelect: true
                showCounts: false
                enabled: root.fieldsEnabled
                model: root.hyprOptions
                selectedValues: root.hyprFlags
                onSelectionToggled: (index, selected) => root.hyprFlags = root.flagSet(root.hyprFlags, root.hyprOptions[index].value, selected)
            }
        }

        FieldRow {
            Field {
                id: moveXInput
                leftIconName: "open_with"
                labelText: "X"
                placeholderText: "0"
            }

            Field {
                id: moveYInput
                leftIconName: "open_with"
                labelText: "Y"
                placeholderText: "0"
            }
        }

        FieldRow {
            Field {
                id: sizeWInput
                leftIconName: "width"
                labelText: I18n.tr("W")
                placeholderText: "800"
            }

            Field {
                id: sizeHInput
                leftIconName: "height"
                labelText: I18n.tr("H", "abbreviation of height, window rule size field label")
                placeholderText: "600"
            }
        }

        FieldRow {
            Field {
                id: monitorInput
                leftIconName: "monitor"
                labelText: I18n.tr("Monitor", "noun, display output field in window rule editor")
                placeholderText: "DP-1"
            }

            Field {
                id: hyprWorkspaceInput
                leftIconName: "view_module"
                labelText: I18n.tr("Workspace")
                placeholderText: "1"
            }
        }
    }

    SettingsCard {
        id: hyprEffectsCard
        title: I18n.tr("Advanced")
        visible: root.isHyprland
        collapsible: true
        expanded: false

        SettingsRow {
            title: I18n.tr("Focus", "noun, window rule editor group of keyboard focus options")

            body: AlpeFilterChips {
                width: parent.width
                multiSelect: true
                showCounts: false
                enabled: root.fieldsEnabled
                model: root.hyprFocusOptions
                selectedValues: root.hyprEffectFlags
                onSelectionToggled: (index, selected) => root.hyprEffectFlags = root.flagSet(root.hyprEffectFlags, root.hyprFocusOptions[index].value, selected)
            }
        }

        SettingsButtonGroupRow {
            text: I18n.tr("Focus on activate")
            description: I18n.tr("Focus the window when it asks to be activated", "window rule option, Hyprland focus_on_activate")
            model: root.triLabels
            currentIndex: root.focusOnActivateTri
            enabled: root.fieldsEnabled
            onSelectionChanged: (index, selected) => {
                if (selected)
                    root.focusOnActivateTri = index;
            }
        }

        SettingsRow {
            title: I18n.tr("Pointer")

            body: AlpeFilterChips {
                width: parent.width
                multiSelect: true
                showCounts: false
                enabled: root.fieldsEnabled
                model: root.hyprPointerOptions
                selectedValues: root.hyprEffectFlags
                onSelectionToggled: (index, selected) => root.hyprEffectFlags = root.flagSet(root.hyprEffectFlags, root.hyprPointerOptions[index].value, selected)
            }
        }

        SettingsRow {
            title: I18n.tr("Rendering", "window rule editor group of render options")

            body: AlpeFilterChips {
                width: parent.width
                multiSelect: true
                showCounts: false
                enabled: root.fieldsEnabled
                model: root.hyprRenderOptions
                selectedValues: root.hyprEffectFlags
                onSelectionToggled: (index, selected) => root.hyprEffectFlags = root.flagSet(root.hyprEffectFlags, root.hyprRenderOptions[index].value, selected)
            }
        }

        SettingsDropdownRow {
            text: I18n.tr("Tone mapping")
            options: root.tonemapOptions.map(root.defaultLabel)
            currentValue: root.defaultLabel(root.tonemapValue)
            enabled: root.fieldsEnabled
            onValueChanged: value => root.tonemapValue = root.tonemapOptions.find(option => root.defaultLabel(option) === value) ?? ""
        }

        SettingsToggleSliderRow {
            text: I18n.tr("Column Width")
            description: I18n.tr("Scrolling", "Hyprland tiling layout name")
            checked: root.scrollingWidthOn
            value: root.scrollingWidthValue
            minimum: 10
            maximum: 100
            unit: "%"
            enabled: root.fieldsEnabled
            onToggled: checked => root.scrollingWidthOn = checked
            onSliderValueChanged: newValue => root.scrollingWidthValue = newValue
        }

        FieldRow {
            Field {
                id: borderColorInput
                leftIconName: "border_color"
                labelText: I18n.tr("Border color")
                placeholderText: "rgb(ff0000) rgb(880808)"
            }

            Field {
                id: suppressEventInput
                leftIconName: "block"
                labelText: I18n.tr("Suppress events")
                placeholderText: "maximize fullscreen"
            }
        }
    }
}
