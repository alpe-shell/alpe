pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.Alpe.Widgets
import qs.Modules.Settings.Widgets

FocusScope {
    id: root

    focus: true

    SettingsPage {
        id: mainColumn

        SettingsCard {
            iconName: "folder"
            title: I18n.tr("Directory", "plugin settings card title, folder where plugins are placed")
            settingKey: "pluginDirectory"
            tags: ["plugins", "directory", "folder", "path"]

            SettingsRow {
                body: StyledText {
                    text: PluginService.pluginDirectory
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    isMonospace: true
                    width: parent.width
                    elide: Text.ElideMiddle
                    horizontalAlignment: Text.AlignLeft
                }
            }

            SettingsRow {
                body: StyledText {
                    text: I18n.tr("Place plugin directories here. Each plugin should have a %1 manifest file.", "plugin directory note, %1 is the manifest file name").arg("plugin.json")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                    width: parent.width
                    horizontalAlignment: Text.AlignLeft
                }
            }

            Flow {
                width: parent.width
                spacing: Theme.spacingS

                AlpeButton {
                    text: PluginService.pluginDirectoryExists ? I18n.tr("Open folder") : I18n.tr("Create folder")
                    iconName: PluginService.pluginDirectoryExists ? "folder_open" : "create_new_folder"
                    maximumWidth: parent.width
                    wrapText: true
                    onClicked: {
                        if (PluginService.pluginDirectoryExists) {
                            PluginService.openPluginDirectory();
                            return;
                        }
                        PluginService.createPluginDirectory();
                    }
                }
                AlpeButton {
                    text: I18n.tr("Scan", "verb, button that scans for plugins, wifi networks or bluetooth devices")
                    iconName: "refresh"
                    variant: "tonal"
                    maximumWidth: parent.width
                    wrapText: true
                    onClicked: {
                        PluginService.scanPlugins();
                        if (DMSService.dmsAvailable && DMSService.apiVersion >= 8)
                            DMSService.listInstalled();
                    }
                }
            }
        }
    }
}
