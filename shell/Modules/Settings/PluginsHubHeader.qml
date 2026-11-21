pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Widgets
import "../../Common/QmlUtils.js" as QmlUtils
import qs.Modals.Common
import qs.Modules.Settings.Widgets

Column {
    id: root

    property var parentModal: null

    property string searchQuery: ""
    property string filterOverride: ""
    readonly property var filterKeys: ["all", "enabled", "disabled"]
    readonly property int filterIndex: filterKeys.indexOf(filterOverride || CacheData.pluginViewFilter)
    property string actionError: ""
    readonly property var sortKeys: ["name", "author", "modified"]
    readonly property int sortIndex: sortKeys.indexOf(CacheData.pluginViewSort.by)
    readonly property bool descending: CacheData.pluginViewSort.descending
    property var uninstalling: ({})
    property var uninstallErrors: ({})
    readonly property string pendingRevealPluginId: PluginService.pendingSettingsRevealPluginId
    readonly property var sortOptions: [I18n.tr("Name"), I18n.tr("Author", "installed plugins sort option, plugin author"), I18n.tr("Last modified", "plugin directory modification time")]
    readonly property var filterOptions: [I18n.tr("All"), I18n.tr("Enabled"), I18n.tr("Disabled")]

    FontMetrics {
        id: pluginTitleMetrics
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Theme.fontWeightMedium
    }

    FontMetrics {
        id: pluginDescriptionMetrics
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
    }

    readonly property var filteredPlugins: plugins.filter(row => {
        const loaded = PluginService.loadedPlugins[row.pluginId] !== undefined;
        if (filterIndex === 1 && !loaded)
            return false;
        if (filterIndex === 2 && loaded)
            return false;
        const plugin = PluginService.availablePlugins[row.pluginId];
        return [row.text, row.hint, plugin?.author, row.pluginId].join(" ").toLowerCase().includes(searchQuery.trim().toLowerCase());
    }).sort((a, b) => {
        let comparison = 0;
        switch (sortIndex) {
        case 1:
            comparison = (PluginService.availablePlugins[a.pluginId]?.author || "").localeCompare(PluginService.availablePlugins[b.pluginId]?.author || "");
            break;
        case 2:
            comparison = modifiedAt(a) - modifiedAt(b);
            break;
        default:
            comparison = a.text.localeCompare(b.text);
        }
        if (comparison !== 0)
            return descending ? -comparison : comparison;
        return a.text.localeCompare(b.text) || a.pluginId.localeCompare(b.pluginId);
    })

    readonly property var plugins: SettingsTabs.pluginHubRows
    readonly property var incompatiblePlugins: {
        PluginService.loadedPlugins;
        return PluginService.getIncompatiblePlugins();
    }

    width: parent?.width ?? 0
    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true
    spacing: Theme.spacingL

    onPendingRevealPluginIdChanged: revealTimer.restart()
    onVisibleChanged: {
        if (!visible)
            filterOverride = "";
    }

    Component.onCompleted: {
        revealTimer.restart();
    }

    function revealPlugin(pluginId) {
        PluginService.pendingSettingsRevealPluginId = pluginId;
        revealTimer.restart();
    }

    function setFilter(index) {
        if (index < 0 || index >= filterKeys.length)
            return;
        CacheData.set("pluginViewFilter", filterKeys[index]);
        filterOverride = "";
    }

    Timer {
        id: revealTimer
        interval: 0
        onTriggered: {
            if (!root.visible || !root.pendingRevealPluginId)
                return;
            if (!PluginService.availablePlugins[root.pendingRevealPluginId])
                return;
            root.searchQuery = "";
            root.filterOverride = "all";
            const key = "installedPlugin:" + root.pendingRevealPluginId;
            const entry = SettingsSearchService.registeredCards[key];
            if (!entry)
                return;
            SettingsSearchService.navigateToSection(key);
            entry.item.focusTarget.forceActiveFocus(Qt.TabFocusReason);
            PluginService.pendingSettingsRevealPluginId = "";
        }
    }

    function setSort(index) {
        if (index < 0 || index >= sortKeys.length)
            return;
        CacheData.set("pluginViewSort", {
            by: sortKeys[index],
            descending: index === sortIndex ? descending : index === 2
        });
    }

    function modifiedAt(row) {
        const directory = PluginService.availablePlugins[row.pluginId]?.pluginDirectory;
        return PluginService.directoryModifiedTimes[directory] || 0;
    }

    function requestUninstall(row) {
        if (uninstalling[row.pluginId])
            return;
        uninstallConfirm.showWithOptions({
            title: I18n.tr("Uninstall"),
            message: I18n.tr("Uninstall %1?", "plugin removal confirmation").arg(row.text),
            confirmText: I18n.tr("Uninstall"),
            danger: true,
            onConfirm: () => uninstall(row)
        });
    }

    function uninstall(row) {
        const id = row.pluginId;
        uninstalling = Object.assign({}, uninstalling, {
            [id]: true
        });
        uninstallErrors = Object.assign({}, uninstallErrors, {
            [id]: ""
        });
        DMSService.uninstall(id, response => {
            const pending = Object.assign({}, uninstalling);
            delete pending[id];
            uninstalling = pending;
            if (response.error) {
                uninstallErrors = Object.assign({}, uninstallErrors, {
                    [id]: response.error
                });
                return;
            }
            PluginService.scanPlugins();
        });
    }

    ConfirmDialogOverlay {
        id: uninstallConfirm
        parent: root.parentModal?.modalFocusScope ?? root.parent
    }

    function setEnabled(row, enabled) {
        actionError = "";
        if (enabled) {
            PluginService.enablePlugin(row.pluginId, ok => {
                if (ok)
                    return;
                const error = PluginService.pluginLoadErrors[row.pluginId];
                actionError = error ? [error.title, error.details].filter(Boolean).join("\n") : I18n.tr("Failed to enable plugin: %1").arg(row.text);
            });
            return;
        }
        if (!PluginService.disablePlugin(row.pluginId))
            actionError = I18n.tr("Failed to disable plugin: %1").arg(row.text);
    }

    Connections {
        target: PluginService

        function onPluginListUpdated() {
            revealTimer.restart();
        }
    }

    SettingsCard {
        settingKey: "pluginManagerUnavailable"
        visible: !DMSService.dmsAvailable

        SettingsRow {
            iconName: "warning"
            title: I18n.tr("Plugin manager unavailable")
            subtitle: I18n.tr("The %1 environment variable is not set or the socket is unavailable. Automated plugin management requires it.", "plugin manager unavailable notice, %1 is an environment variable").arg("ALPE_SOCKET")
        }
    }

    SettingsCard {
        settingKey: "pluginsIncompatible"
        visible: root.incompatiblePlugins.length > 0

        SettingsRow {
            iconName: "error"
            title: I18n.tr("Incompatible plugins loaded")
            subtitle: I18n.tr("Some plugins require a newer version of DMS:") + " " + root.incompatiblePlugins.map(plugin => plugin.name + " (" + plugin.requires_dms + ")").join(", ")
            subtitleColor: Theme.error
        }
    }

    RowLayout {
        width: parent.width
        spacing: Theme.spacingS
        visible: root.plugins.length > 0

        Item {
            Layout.fillWidth: true
        }

        DButton {
            text: "Plugin-Ordner"
            buttonHeight: Theme.buttonHeightXS
            horizontalPadding: Theme.spacingS
            variant: "text"
            maximumWidth: root.width / 2
            wrapText: true
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: (Theme.buttonHeightS - Theme.buttonHeightXS) / 2
            onClicked: keyboard => root.parentModal?.navigateTo("plugins_manage", keyboard)
        }
    }

    StyledText {
        width: parent.width
        visible: text !== ""
        text: root.actionError
        color: Theme.error
        wrapMode: Text.Wrap
    }

    DCard {
        id: storeCard
        color: SettingsMetrics.rowColor
        width: parent.width
        implicitHeight: storeContent.implicitHeight + pad * 2
        visible: root.plugins.length === 0
        pad: Theme.spacingL

        ColumnLayout {
            id: storeContent
            width: parent.width
            spacing: Theme.spacingM

            DIcon {
                name: "extension"
                size: Theme.iconSizeLarge
                color: storeCard.accentColor
            }
            StyledText {
                Layout.fillWidth: true
                text: "Noch keine Plugins"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Theme.fontWeightMedium
                color: storeCard.contentColor
                wrapMode: Text.Wrap
            }
            StyledText {
                Layout.fillWidth: true
                text: "Plugins liegen als Ordner mit einer plugin.json im Plugin-Ordner."
                color: storeCard.mutedColor
                wrapMode: Text.Wrap
            }
            Flow {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                spacing: Theme.spacingS

                DButton {
                    text: "Plugin-Ordner"
                    iconName: "folder_open"
                    maximumWidth: parent.width
                    wrapText: true
                    onClicked: keyboard => root.parentModal?.navigateTo("plugins_manage", keyboard)
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.spacingS
        visible: root.plugins.length > 0

        DSearchField {
            width: parent.width
            text: root.searchQuery
            placeholderText: I18n.tr("Search plugins...", "plugin search placeholder")
            maximumLength: 100
            onTextEdited: root.searchQuery = text
        }
        Flow {
            width: parent.width
            spacing: Theme.spacingS

            DSplitButton {
                id: filterButton
                text: I18n.tr("Filter") + ": " + root.filterOptions[root.filterIndex]
                iconName: "filter_list"
                size: "xs"
                variant: root.filterIndex > 0 ? "tonal" : "outlined"
                maximumWidth: parent.width
                expanded: filterMenu.menuVisible
                tooltipText: root.filterOptions[(root.filterIndex + 1) % root.filterKeys.length]
                menuTooltipText: I18n.tr("Filter")
                onClicked: root.setFilter((root.filterIndex + 1) % root.filterKeys.length)
                onMenuClicked: {
                    filterMenu.currentValue = root.filterOptions[root.filterIndex];
                    filterMenu.openDropdownMenu();
                }

                DDropdown {
                    id: filterMenu
                    showTrigger: false
                    popupAnchorItem: filterButton.trailingButton
                    focusReturnTarget: filterButton.trailingButton
                    alignPopupRight: !I18n.isRtl
                    popupWidth: Math.min(root.width, Theme.smallBreakpoint / 2)
                    options: root.filterOptions
                    onValueChanged: value => root.setFilter(options.indexOf(value))
                }
            }
            DSplitButton {
                id: sortButton
                text: I18n.tr("Sort by") + ": " + root.sortOptions[root.sortIndex]
                iconName: root.descending ? "arrow_downward" : "arrow_upward"
                size: "xs"
                variant: "tonal"
                maximumWidth: parent.width
                expanded: sortMenu.menuVisible
                tooltipText: root.sortOptions[(root.sortIndex + 1) % root.sortKeys.length]
                menuTooltipText: I18n.tr("Sort by")
                Accessible.description: [root.sortOptions[root.sortIndex], root.descending ? I18n.tr("Descending") : I18n.tr("Ascending")].join(" · ")
                onClicked: root.setSort((root.sortIndex + 1) % root.sortKeys.length)
                onMenuClicked: {
                    sortMenu.currentValue = root.sortOptions[root.sortIndex];
                    sortMenu.openDropdownMenu();
                }

                DDropdown {
                    id: sortMenu
                    showTrigger: false
                    popupAnchorItem: sortButton.trailingButton
                    focusReturnTarget: sortButton.trailingButton
                    alignPopupRight: !I18n.isRtl
                    popupWidth: Math.min(root.width, Theme.smallBreakpoint / 2)
                    options: root.sortOptions.concat([I18n.tr("Ascending"), I18n.tr("Descending")])
                    optionIcons: ["sort_by_alpha", "person", "schedule", root.descending ? "arrow_upward" : "check", root.descending ? "check" : "arrow_downward"]
                    onValueChanged: value => {
                        const index = options.indexOf(value);
                        if (index < 0)
                            return;
                        if (index < root.sortKeys.length) {
                            root.setSort(index);
                            return;
                        }
                        CacheData.set("pluginViewSort", {
                            by: root.sortKeys[root.sortIndex],
                            descending: index === root.sortKeys.length + 1
                        });
                    }
                }
            }
        }
    }

    StyledText {
        width: parent.width
        visible: root.plugins.length > 0 && root.filteredPlugins.length === 0
        text: I18n.tr("No plugins found", "empty plugin list")
        color: Theme.onSurfaceVariant
        wrapMode: Text.Wrap
    }

    GridLayout {
        id: installedGrid
        width: parent.width
        columns: width >= Theme.mediumBreakpoint ? 3 : width >= Theme.smallBreakpoint ? 2 : 1
        columnSpacing: Theme.spacingM
        rowSpacing: Theme.spacingM

        Repeater {
            model: root.filteredPlugins

            DCard {
                id: installedCard
                required property var modelData
                readonly property bool loaded: PluginService.loadedPlugins[modelData.pluginId] !== undefined
                readonly property var plugin: PluginService.availablePlugins[modelData.pluginId] || ({})
                readonly property var loadError: PluginService.pluginLoadErrors[modelData.pluginId]
                readonly property bool compatible: PluginService.checkPluginCompatibility(plugin.requires_dms)
                readonly property string problem: root.uninstallErrors[modelData.pluginId] || (loadError ? [loadError.title, loadError.details].filter(Boolean).join("\n") : !compatible ? I18n.tr("Requires %1", "version requirement").arg(plugin.requires_dms) : "")
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: (installedGrid.width - installedGrid.columnSpacing * (installedGrid.columns - 1)) / installedGrid.columns
                Layout.fillHeight: true
                implicitHeight: cardContent.implicitHeight + pad * 2
                pad: Theme.spacingL
                radius: Theme.cornerRadiusM
                readonly property string highlightKey: "installedPlugin:" + modelData.pluginId
                color: SettingsSearchService.highlightSection === highlightKey ? Theme.blend(SettingsMetrics.rowColor, Theme.primary, SettingsMetrics.highlightBlend) : SettingsMetrics.rowColor
                clickable: true
                Accessible.name: modelData.text
                onClicked: keyboard => root.parentModal?.navigateTo(modelData.id, keyboard)

                Timer {
                    interval: 0
                    running: true
                    onTriggered: {
                        const flickable = QmlUtils.findParentFlickable(installedCard.parent);
                        if (!flickable)
                            return;
                        SettingsSearchService.registerCard(installedCard.highlightKey, installedCard, flickable);
                        revealTimer.restart();
                    }
                }
                Component.onDestruction: SettingsSearchService.unregisterCard(highlightKey, installedCard)

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    spacing: Theme.spacingS

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.minimumHeight: Math.ceil(pluginTitleMetrics.height) * 2 + Theme.spacingXXS + pluginMetadata.implicitHeight
                        Layout.maximumHeight: Layout.minimumHeight
                        spacing: Theme.spacingS
                        DIcon {
                            id: pluginIcon
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: Math.max(0, (pluginTitle.implicitHeight - height) / 2)
                            name: installedCard.modelData.icon
                            size: Theme.iconSize
                            color: Theme.primary
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: Math.max(0, (pluginIcon.height - pluginTitle.implicitHeight) / 2)
                            spacing: Theme.spacingXXS

                            StyledText {
                                id: pluginTitle
                                Layout.fillWidth: true
                                text: installedCard.modelData.text
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Theme.fontWeightMedium
                                color: Theme.onSurface
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignTop
                            }
                            Item {
                                id: pluginMetadata
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                implicitHeight: Math.max(Theme.spacingL, Math.ceil(pluginDescriptionMetrics.height), versionBadge.implicitHeight)

                                DBadge {
                                    id: versionBadge
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    text: installedCard.plugin.version || ""
                                    visible: text !== ""
                                    maximumWidth: parent.width
                                    color: installedCard.chipColor
                                    textColor: Theme.onSurfaceVariant
                                    Accessible.name: I18n.tr("Version %1", "accessible name of plugin version badge, %1 is the version number").arg(text)
                                }

                                StyledText {
                                    anchors.left: versionBadge.visible ? versionBadge.right : parent.left
                                    anchors.leftMargin: versionBadge.visible ? Theme.spacingXS : 0
                                    anchors.baseline: versionBadge.visible ? versionBadge.baseline : undefined
                                    width: Math.max(0, parent.width - (versionBadge.visible ? versionBadge.width + Theme.spacingXS : 0))
                                    visible: root.sortKeys[root.sortIndex] === "author"
                                    text: I18n.tr("by %1", "author attribution").arg(installedCard.plugin.author || I18n.tr("Unknown", "unknown author"))
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.onSurfaceVariant
                                    wrapMode: Text.NoWrap
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        DToggle {
                            Layout.alignment: Qt.AlignTop
                            enabled: !root.uninstalling[installedCard.modelData.pluginId]
                            checked: installedCard.loaded
                            Accessible.name: installedCard.modelData.text
                            onToggled: value => root.setEnabled(installedCard.modelData, value)
                        }
                    }
                    StyledText {
                        Layout.fillWidth: true
                        Layout.minimumHeight: Math.ceil(pluginDescriptionMetrics.height) * 2
                        Layout.maximumHeight: Layout.minimumHeight
                        text: installedCard.modelData.hint
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        color: Theme.onSurfaceVariant
                        font.pixelSize: Theme.fontSizeSmall
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignTop
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        visible: installedCard.problem !== "" || !!root.uninstalling[installedCard.modelData.pluginId]
                        spacing: Theme.spacingS
                        DActionButton {
                            visible: installedCard.problem !== ""
                            buttonSize: Theme.buttonHeightXS
                            iconName: "error"
                            iconColor: Theme.error
                            tooltipText: installedCard.problem
                            onClicked: root.actionError = installedCard.modelData.text + ": " + installedCard.problem
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: root.uninstalling[installedCard.modelData.pluginId] ? I18n.tr("Uninstalling: %1", "uninstallation progress").arg(installedCard.modelData.text) : installedCard.problem
                            color: installedCard.problem ? Theme.error : Theme.onSurfaceVariant
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            Accessible.description: installedCard.problem
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(settingsButton.implicitHeight, cardActions.implicitHeight)

                        DIconButton {
                            id: settingsButton
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            iconName: "settings"
                            variant: "tonal"
                            Accessible.name: I18n.tr("Settings")
                            onClicked: keyboard => root.parentModal?.navigateTo(installedCard.modelData.id, keyboard)
                        }
                        Row {
                            id: cardActions
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingXS

                            DIconButton {
                                iconName: "delete"
                                Accessible.name: I18n.tr("Uninstall")
                                visible: installedCard.plugin.source !== "system"
                                enabled: DMSService.dmsAvailable && !root.uninstalling[installedCard.modelData.pluginId]
                                onClicked: root.requestUninstall(installedCard.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
