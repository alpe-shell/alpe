import QtQuick
import qs.Common
import qs.Services
Item {
    function leaves(h) { return SettingsTabs.hubRows(h).map(e => e.id).join(",") }
    function side() { return SettingsTabs.structure.filter(e => !e.separator && SettingsTabs.isVisible(SettingsTabs.page(e.id))).map(e => e.id + "[" + e.text + "|" + e.icon + "]").join(" ") }
    Component.onCompleted: {
        console.log("A power:", leaves("power_battery"), "| resolve:", SettingsTabs.resolvePage("power_battery"), "| text:", SettingsTabs.page("power_battery").text);
        console.log("A network:", leaves("network"), "| icon:", SettingsTabs.page("network").icon, "| hint:", SettingsTabs.hubHint(SettingsTabs.page("network")));
        console.log("A security:", leaves("security_accounts"), "| resolve:", SettingsTabs.resolvePage("security"), "| hint:", SettingsTabs.page("lock_screen").hint);
        console.log("A system:", leaves("system"));
        console.log("A tab102:", SettingsTabs.pageForTabIndex(102), SettingsTabs.pageForTabIndex(11), SettingsTabs.resolvePage("headset"), SettingsTabs.resolvePage("kwin"));
        console.log("A searchable:", SettingsTabs.isSearchable("lock_screen", false), SettingsTabs.isSearchable("lock_screen", true), SettingsTabs.isSearchable("network_wifi", false), SettingsTabs.isSearchable("battery", false), SettingsTabs.isSearchable("alpe_pages", true), SettingsTabs.isSearchable("plugin:alpeRadar", false));
        NetworkService.wifiDevices = [{name: "wlan0"}]; BatteryService.batteryAvailable = true;
        console.log("B (wifi+battery, wifi hidden by default):", leaves("network"), "|", leaves("power_battery"), "|", SettingsTabs.page("power_battery").text, SettingsTabs.page("network").icon, "avail:", SettingsTabs.isAvailable(SettingsTabs.page("network_wifi")));
        SettingsTabs.setPageHidden("network_wifi", false);
        console.log("C (wifi shown):", leaves("network"), SettingsTabs.page("network").icon, JSON.stringify(SettingsData.settingsHiddenPages));
        SettingsTabs.setPageHidden("wellbeing", true); SettingsTabs.setPageHidden("about", true); SettingsTabs.setPageHidden("alpe_peripherals", true); SettingsTabs.setPageHidden("power_sleep", true);
        console.log("D hidden:", JSON.stringify(SettingsData.settingsHiddenPages), "| wellbeing:", SettingsTabs.isVisible(SettingsTabs.page("wellbeing")), "about:", SettingsTabs.isVisible(SettingsTabs.page("about")), "power hub:", SettingsTabs.isVisible(SettingsTabs.page("power_battery")), leaves("power_battery"), SettingsTabs.resolvePage("power"));
        CompositorService.isKwin = false;
        console.log("E (kein KWin) system:", leaves("system"), "| lock hint:", SettingsTabs.page("lock_screen").hint, SettingsTabs.isSearchable("lock_screen", false));
        console.log("F sidebar:", side());
    }
}
