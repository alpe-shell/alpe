.pragma library

// Alpe (Einstellungen v44, Session v8; Plan 2.3.2, 0.8 Nr. 13): gespeicherte Kennungen mit den Namen
// des Ursprungs tragen eigene Namen. Hier stehen die alten Namen, damit Dateien aus 1.0 und aus
// v43 umziehen; tools/design.py führt dieselben Tabellen (tests/test_design.py vergleicht sie).

// Eingebaute Starter-Einträge («Starter-Plugins»): Schlüssel in builtInPluginSettings, App-ID in
// Dock-Pins und Listen.
var STARTER_IDS = {
    "dms_settings": "alpe_settings",
    "dms_notepad": "alpe_notepad",
    "dms_sysmon": "alpe_sysmon",
    "dms_colorpicker": "alpe_colorpicker",
    "dms_settings_search": "alpe_settings_search",
    "dms_clipboard_search": "alpe_clipboard_search",
    "dms_power": "alpe_power",
    "dms_vpn": "alpe_vpn",
    "dms_qr_generator": "alpe_qr_generator"
};

// Wo auch immer einer dieser Schlüssel steht (Leisten-, Dock-, Insel-Widgets): Wert alt → neu.
var VALUES_BY_KEY = {
    "launcherLogoMode": {
        "dank": "alpe"
    },
    "islandFreeIconMode": {
        "dank": "alpe"
    }
};

// Nur auf der obersten Ebene der Einstellungen.
var SETTINGS_VALUES = {
    "matugenSpec": {
        "dms": "alpe"
    }
};

// Seiten der Einstellungen: Listen von Seiten-IDs auf der obersten Ebene der Einstellungen
// (settingsHiddenPages, Seitenauswahl unter «Alpe»).
var PAGE_LIST_KEYS = ["settingsHiddenPages"];
var PAGE_IDS = {
    "dankbar": "bar",
    "dankbar_settings": "bar_settings",
    "dankbar_appearance": "bar_appearance",
    "dankbar_dot": "bar_dot",
    "dankbar_widgets": "bar_widgets",
    "dank_dash": "dash"
};

// Material-Hintergründe in der Session: Vorlage und Form des Zeichens.
var MATERIAL_KEYS = ["materialWallpapers", "materialWallpaperProfiles"];
var MATERIAL_VALUES = {
    "preset": {
        "dank": "alpe"
    },
    "shape": {
        "dankLogo": "alpeLogo"
    }
};

function own(table, key) {
    return Object.prototype.hasOwnProperty.call(table, key);
}

// Geht den ganzen Baum durch. ids: Zeichenketten und Schlüssel, die genau einer alten Kennung
// entsprechen; byKey: Werte unter bestimmten Schlüsseln. Ein schon vorhandener neuer Schlüssel gewinnt.
function deepRename(value, ids, byKey) {
    if (typeof value === "string")
        return ids && own(ids, value) ? ids[value] : value;
    if (Array.isArray(value)) {
        for (var i = 0; i < value.length; i++)
            value[i] = deepRename(value[i], ids, byKey);
        return value;
    }
    if (!value || typeof value !== "object")
        return value;
    var keys = Object.keys(value);
    for (var k = 0; k < keys.length; k++) {
        var key = keys[k];
        var child = value[key];
        if (byKey && own(byKey, key) && typeof child === "string" && own(byKey[key], child))
            child = byKey[key][child];
        else
            child = deepRename(child, ids, byKey);
        if (ids && own(ids, key)) {
            delete value[key];
            if (!own(value, ids[key]))
                value[ids[key]] = child;
        } else {
            value[key] = child;
        }
    }
    return value;
}

function migrateSettings(settings) {
    deepRename(settings, STARTER_IDS, VALUES_BY_KEY);
    for (var key in SETTINGS_VALUES) {
        if (typeof settings[key] === "string" && own(SETTINGS_VALUES[key], settings[key]))
            settings[key] = SETTINGS_VALUES[key][settings[key]];
    }
    for (var p = 0; p < PAGE_LIST_KEYS.length; p++) {
        var list = settings[PAGE_LIST_KEYS[p]];
        if (!Array.isArray(list))
            continue;
        var pages = [];
        for (var i = 0; i < list.length; i++) {
            var id = typeof list[i] === "string" && own(PAGE_IDS, list[i]) ? PAGE_IDS[list[i]] : list[i];
            if (pages.indexOf(id) === -1)
                pages.push(id);
        }
        settings[PAGE_LIST_KEYS[p]] = pages;
    }
    return settings;
}

function migrateSession(session) {
    deepRename(session, STARTER_IDS, null);
    for (var i = 0; i < MATERIAL_KEYS.length; i++) {
        if (session[MATERIAL_KEYS[i]])
            deepRename(session[MATERIAL_KEYS[i]], null, MATERIAL_VALUES);
    }
    return session;
}
