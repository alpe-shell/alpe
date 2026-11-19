pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets

// Alpe: Einstellungsseiten ausblenden, die man nicht braucht. Ausgeblendet heisst nur: nicht
// mehr in der Seitenleiste und in der Suche. Die Einstellungen dahinter bleiben, wie sie sind.
Item {
    id: root

    property var parentModal: null

    // Was auf diesem Rechner ohnehin fehlt (Akku, WLAN, Mobilfunk …), steht gar nicht zur Wahl.
    readonly property var topEntries: SettingsTabs.structure.filter(entry => !entry.separator && root.available(entry.id))
    readonly property var hubs: topEntries.filter(entry => root.listedChildren(entry).length > 1)
    readonly property int hiddenCount: SettingsTabs.hiddenList.filter(id => !SettingsTabs.isPinned(id) && SettingsTabs.page(id) && root.available(id)).length

    function listedChildren(entry) {
        return (entry.children || []).filter(child => !child.hidden && root.available(child.id));
    }

    function available(id) {
        return SettingsTabs.isAvailable(SettingsTabs.page(id));
    }

    function note(entry) {
        if (SettingsTabs.isPinned(entry.id))
            return "Immer sichtbar";
        return entry.hint || SettingsTabs.hubHint(SettingsTabs.page(entry.id)) || "";
    }

    component PageToggle: SettingsToggleRow {
        required property var modelData
        text: modelData.text
        description: root.note(modelData)
        iconName: modelData.icon
        enabled: !SettingsTabs.isPinned(modelData.id)
        checked: !SettingsTabs.isHiddenByUser(modelData.id)
        // Verzögert: Die Änderung kann die Liste neu aufbauen, in der diese Zeile steht.
        onToggled: checked => {
            const id = modelData.id;
            Qt.callLater(() => SettingsTabs.setPageHidden(id, !checked));
        }
    }

    SettingsPage {
        SettingsCard {
            width: parent.width
            iconName: "visibility"
            title: "Bereiche"
            settingKey: "alpePages"

            SettingsRow {
                title: root.hiddenCount === 0 ? "Alle Seiten sichtbar" : root.hiddenCount === 1 ? "1 Seite ausgeblendet" : root.hiddenCount + " Seiten ausgeblendet"
                subtitle: "Ausgeblendete Seiten verschwinden aus Seitenleiste und Suche. Ihre Einstellungen bleiben unverändert wirksam."
                iconName: "visibility_off"

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    buttonHeight: Theme.buttonHeightS
                    visible: root.hiddenCount > 0
                    text: "Alle einblenden"
                    iconName: "visibility"
                    backgroundColor: SettingsMetrics.controlSurface
                    textColor: Theme.surfaceText
                    onClicked: SettingsData.set("settingsHiddenPages", [])
                }
            }

            Repeater {
                model: root.topEntries

                PageToggle {}
            }
        }

        Repeater {
            model: root.hubs

            SettingsCard {
                id: hubCard
                required property var modelData
                width: parent.width
                iconName: modelData.icon
                title: modelData.text
                visible: !SettingsTabs.isHiddenByUser(modelData.id)

                Repeater {
                    model: root.listedChildren(hubCard.modelData)

                    PageToggle {}
                }
            }
        }
    }
}
