import QtQuick
import qs.Common
import qs.Services
Item { Component.onCompleted: {
    console.log("battery ->", SettingsTabs.resolvePage("battery"), "| wifi ->", SettingsTabs.resolvePage("network_wifi"), "| power ->", SettingsTabs.resolvePage("power"), "| security ->", SettingsTabs.resolvePage("security"), "| theme(hidden child) ->", SettingsTabs.resolvePage("theme"), "| greeter ->", SettingsTabs.resolvePage("greeter"), "| about ->", SettingsTabs.resolvePage("about"), "| plugins ->", SettingsTabs.resolvePage("plugins"), "| dock_general ->", SettingsTabs.resolvePage("dock_general"));
    SettingsTabs.setPageHidden("alpe_peripherals", true);
    console.log("ohne Geräte-Akkus: power ->", SettingsTabs.resolvePage("power"), "battery ->", SettingsTabs.resolvePage("battery"));
    BatteryService.batteryAvailable = true;
    console.log("mit Akku: battery ->", SettingsTabs.resolvePage("battery"));
} }
