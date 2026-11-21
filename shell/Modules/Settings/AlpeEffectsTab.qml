pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets

// Alpe: Fenster & Effekte unter KWin. Abgerundete Ecken (KDE-Rounded-Corners,
// kwinrc [Round-Corners]), Weichzeichnen (Better Blur DX, kwinrc [Effect-better-blur-dx]),
// Platzierung neuer Fenster (kwinrc [Windows] Placement) und Animationstempo
// (kdeglobals [KDE] AnimationDurationFactor). Jede Änderung wirkt sofort.
// Alpe: unter Hyprland die Unschärfe – Modus, Feineinstellungen und was gerade gilt.
Item {
    id: root

    property var parentModal: null

    readonly property var st: backend.state
    readonly property var corners: st ? st.corners : ({})
    readonly property var blur: st ? st.blur : ({})
    readonly property var fx: st ? st.effects : null

    AlpeKwinBackend {
        id: backend
    }

    function num(group, key, fallback) {
        const v = parseFloat(group[key]);
        return isNaN(v) ? fallback : v;
    }

    function flag(group, key, fallback) {
        return group[key] === undefined ? fallback : group[key] === "true";
    }

    // Schieberegler: sofort in die Anzeige, verzögert in die Datei.
    property var pending: []
    function set(file, group, key, value) {
        pending = pending.filter(e => !(e[0] === file && e[1] === group && e[2] === key)).concat([[file, group, key, value]]);
        writeTimer.restart();
    }
    Timer {
        id: writeTimer
        interval: 350
        onTriggered: {
            const entries = root.pending;
            root.pending = [];
            backend.apply(entries);
        }
    }

    function toggleEffect(id, on) {
        backend.run(["effect", id, on ? "on" : "off"], () => backend.refresh());
    }

    function effectState(e) {
        if (!e)
            return "";
        if (!e.installed)
            return "Nicht installiert";
        if (e.loaded)
            return "Aktiv";
        return e.enabled ? "Eingeschaltet, aber nicht geladen – nach einem KWin-Update oft neu zu bauen" : "Aus";
    }

    readonly property var placementValues: ["Smart", "Centered", "UnderMouse", "ZeroCornered", "Maximizing", "Random"]
    readonly property var placementOptions: ["Freien Platz suchen", "Mittig", "Unter dem Mauszeiger", "Oben links", "Maximiert", "Zufällig"]

    readonly property var speedValues: [0, 0.25, 0.5, 0.75, 1, 1.5, 2]
    readonly property var speedOptions: ["Keine Animationen", "Sehr schnell", "Schnell", "Etwas schneller", "Normal", "Etwas langsamer", "Langsam"]
    function nearestSpeed(v) {
        let best = 4;
        for (let i = 0; i < speedValues.length; i++)
            if (Math.abs(speedValues[i] - v) < Math.abs(speedValues[best] - v))
                best = i;
        return best;
    }

    SettingsPage {
        SettingsNoteRow {
            visible: root.st === null && CompositorService.isKwin
            width: parent.width
            text: backend.loading ? "Lese die KWin-Einstellungen …" : "Die KWin-Einstellungen liessen sich nicht lesen (scripts/alpe-kwin.py, python3)."
        }

        // ---------------------------------------------------------- Ecken
        SettingsCard {
            width: parent.width
            visible: root.st !== null && CompositorService.isKwin
            iconName: "rounded_corner"
            title: "Abgerundete Ecken"
            settingKey: "alpeCorners"
            tags: ["ecken", "rounded corners", "radius", "kwin"]

            SettingsToggleRow {
                text: "Ecken abrunden"
                description: root.effectState(root.fx ? root.fx.corners : null)
                enabled: !!(root.fx && root.fx.corners.installed)
                checked: !!(root.fx && (root.fx.corners.loaded || root.fx.corners.enabled))
                onToggled: checked => root.toggleEffect("kwin4_effect_shapecorners", checked)
            }

            SettingsSliderRow {
                text: "Radius"
                unit: "px"
                minimum: 0
                maximum: 40
                value: root.num(root.corners, "Size", 20)
                onSliderValueChanged: v => root.set("kwinrc", "Round-Corners", "Size", v)
            }

            SettingsSliderRow {
                text: "Radius inaktiver Fenster"
                unit: "px"
                minimum: 0
                maximum: 40
                value: root.num(root.corners, "InactiveCornerRadius", 20)
                onSliderValueChanged: v => root.set("kwinrc", "Round-Corners", "InactiveCornerRadius", v)
            }

            SettingsToggleRow {
                text: "Weiche Form (Squircle)"
                description: "Ecken wie bei macOS statt Viertelkreis."
                checked: root.flag(root.corners, "UseSquircleShape", true)
                onToggled: checked => root.set("kwinrc", "Round-Corners", "UseSquircleShape", checked)
            }

            SettingsSliderRow {
                text: "Umrandung"
                description: "Feine Linie um aktive Fenster, in Pixeln. 0 blendet sie aus."
                unit: "px"
                minimum: 0
                maximum: 5
                value: root.num(root.corners, "OutlineThickness", 1)
                onSliderValueChanged: v => {
                    root.set("kwinrc", "Round-Corners", "OutlineThickness", v);
                    root.set("kwinrc", "Round-Corners", "InactiveOutlineThickness", v);
                }
            }

            SettingsToggleRow {
                text: "Auch maximierte Fenster abrunden"
                checked: !root.flag(root.corners, "DisableRoundMaximize", true)
                onToggled: checked => root.set("kwinrc", "Round-Corners", "DisableRoundMaximize", !checked)
            }
        }

        // ---------------------------------------------------------- Weichzeichnen
        SettingsCard {
            width: parent.width
            visible: root.st !== null && CompositorService.isKwin
            iconName: "blur_on"
            title: "Weichzeichnen"
            settingKey: "alpeBlur"
            tags: ["blur", "weichzeichnen", "better blur", "transparenz"]

            SettingsToggleRow {
                text: "Better Blur DX"
                description: root.effectState(root.fx ? root.fx.blur : null) + (root.fx && root.fx.kwinblur.loaded ? " – KWins eigene Unschärfe ist ebenfalls an; beim Einschalten wird sie abgeschaltet." : "")
                enabled: !!(root.fx && root.fx.blur.installed)
                checked: !!(root.fx && (root.fx.blur.loaded || root.fx.blur.enabled))
                onToggled: checked => root.toggleEffect("better_blur_dx", checked)
            }

            SettingsSliderRow {
                text: "Stärke"
                minimum: 1
                maximum: 15
                value: root.num(root.blur, "BlurStrength", 15)
                onSliderValueChanged: v => root.set("kwinrc", "Effect-better-blur-dx", "BlurStrength", v)
            }

            SettingsSliderRow {
                text: "Körnung"
                minimum: 0
                maximum: 14
                value: root.num(root.blur, "NoiseStrength", 5)
                onSliderValueChanged: v => root.set("kwinrc", "Effect-better-blur-dx", "NoiseStrength", v)
            }

            SettingsSliderRow {
                text: "Helligkeit"
                unit: "%"
                minimum: 50
                maximum: 150
                value: root.num(root.blur, "Brightness", 100)
                onSliderValueChanged: v => root.set("kwinrc", "Effect-better-blur-dx", "Brightness", v)
            }

            SettingsSliderRow {
                text: "Sättigung"
                unit: "%"
                minimum: 0
                maximum: 200
                value: root.num(root.blur, "Saturation", 150)
                onSliderValueChanged: v => root.set("kwinrc", "Effect-better-blur-dx", "Saturation", v)
            }

            SettingsSliderRow {
                text: "Kontrast"
                unit: "%"
                minimum: 50
                maximum: 150
                value: root.num(root.blur, "Contrast", 100)
                onSliderValueChanged: v => root.set("kwinrc", "Effect-better-blur-dx", "Contrast", v)
            }

            SettingsSliderRow {
                text: "Eckenradius der Unschärfe"
                description: "Gleich gross wie der Radius der Ecken, damit an den Ecken nichts übersteht."
                unit: "px"
                minimum: 0
                maximum: 40
                value: root.num(root.blur, "CornerRadius", 0)
                onSliderValueChanged: v => root.set("kwinrc", "Effect-better-blur-dx", "CornerRadius", v)
            }

            SettingsToggleRow {
                text: "Menüs weichzeichnen"
                checked: root.flag(root.blur, "BlurMenus", false)
                onToggled: checked => root.set("kwinrc", "Effect-better-blur-dx", "BlurMenus", checked)
            }

            SettingsToggleRow {
                text: "Docks und Leisten weichzeichnen"
                checked: root.flag(root.blur, "BlurDocks", false)
                onToggled: checked => root.set("kwinrc", "Effect-better-blur-dx", "BlurDocks", checked)
            }

            SettingsRow {
                title: "Weichgezeichnete Programme"
                subtitle: root.st && root.st.blurClasses.length > 0 ? root.st.blurClasses.join(" · ") : "keine"
                iconName: "web_asset"

                body: Flow {
                    width: parent.width
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.st ? root.st.blurClasses : []

                        DButton {
                            required property string modelData
                            text: modelData
                            iconName: "close"
                            variant: "tonal"
                            tooltipText: "Aus der Liste nehmen"
                            onClicked: {
                                const rest = root.st.blurClasses.filter(c => c !== modelData);
                                backend.apply([["kwinrc", "Effect-better-blur-dx", "WindowClasses", rest.length > 0 ? rest.join("\n") : null]]);
                            }
                        }
                    }
                }
            }

            SettingsNavRow {
                title: "Programm hinzufügen"
                hint: "Über eine Fensterregel: «Hintergrund weichzeichnen», meist mit Deckkraft"
                iconName: "select_window"
                onClicked: keyboard => root.parentModal?.navigateTo("window_rules", keyboard)
            }
        }

        // ---------------------------------------------------------- Fenster
        SettingsCard {
            width: parent.width
            visible: root.st !== null && CompositorService.isKwin
            iconName: "open_in_new"
            title: "Neue Fenster"
            settingKey: "alpePlacement"

            SettingsDropdownRow {
                text: "Platzierung"
                description: "Wo KWin ein neues Fenster öffnet, wenn keine Regel etwas anderes sagt."
                options: root.placementOptions
                currentValue: root.st ? root.placementOptions[Math.max(0, root.placementValues.indexOf(root.st.placement))] : ""
                onValueChanged: value => backend.apply([["kwinrc", "Windows", "Placement", root.placementValues[root.placementOptions.indexOf(value)]]])
            }
        }

        // ---------------------------------------------------------- Animationen
        SettingsCard {
            width: parent.width
            visible: root.st !== null && CompositorService.isKwin
            iconName: "animation"
            title: "Animationen"
            settingKey: "alpeAnimations"

            SettingsDropdownRow {
                text: "Tempo"
                description: "Gilt für KWin und KDE-Programme (wie «Animationsgeschwindigkeit» in den KDE-Einstellungen). Die Shell hat ihr eigenes Tempo unter «Schriftarten & Bewegung»."
                options: root.speedOptions
                currentValue: root.st ? root.speedOptions[root.nearestSpeed(parseFloat(root.st.animation))] : ""
                onValueChanged: value => backend.apply([["kdeglobals", "KDE", "AnimationDurationFactor", root.speedValues[root.speedOptions.indexOf(value)]]])
            }
        }

        // ---------------------------------------------------------- Hyprland
        SettingsCard {
            width: parent.width
            visible: CompositorService.isHyprland
            iconName: "blur_on"
            title: "Unschärfe"
            settingKey: "alpeHyprBlur"
            tags: ["blur", "unschärfe", "hyprland", "weichzeichnen", "artefakte"]

            SettingsDropdownRow {
                readonly property var values: ["standard", "tuned", "off"]
                readonly property var labels: ["Wie in DMS eingestellt", "Mit Feineinstellungen", "Aus – bei Darstellungsfehlern"]
                text: "Modus"
                description: SettingsData.alpeHyprBlurMode === "off" ? "Hyprland zeichnet nichts weich; Shell-Flächen und Fenster bleiben durchsichtig." : "Stärke und Stil der Unschärfe stehen unter «Interface-Stil». Hier kommen die Feinheiten dazu."
                options: labels
                currentValue: labels[Math.max(0, values.indexOf(SettingsData.alpeHyprBlurMode))]
                onValueChanged: value => SettingsData.set("alpeHyprBlurMode", values[labels.indexOf(value)])
            }

            SettingsRow {
                title: "Robust einstellen"
                subtitle: "Gegen flackernde oder fehlerhafte Unschärfe: Optimierungen an, keine Unschärfe hinter Popups und Spezial-Arbeitsflächen, Deckkraft der Fenster beachten."
                iconName: "healing"

                DButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Anwenden"
                    variant: "tonal"
                    onClicked: {
                        SettingsData.set("alpeHyprBlurNewOptimizations", true);
                        SettingsData.set("alpeHyprBlurPopups", false);
                        SettingsData.set("alpeHyprBlurSpecial", false);
                        SettingsData.set("alpeHyprBlurIgnoreOpacity", true);
                        SettingsData.set("alpeHyprBlurMode", "tuned");
                        live.refresh();
                    }
                }
            }

            Repeater {
                model: SettingsData.alpeHyprBlurMode === "tuned" ? [["alpeHyprBlurNoise", "Körnung", 0, 100, "‰"], ["alpeHyprBlurContrast", "Kontrast", 0, 200, "%"], ["alpeHyprBlurBrightness", "Helligkeit", 0, 200, "%"], ["alpeHyprBlurVibrancy", "Farbsättigung", 0, 100, "%"]] : []

                SettingsSliderRow {
                    required property var modelData
                    width: parent ? parent.width : 0
                    text: modelData[1]
                    minimum: modelData[2]
                    maximum: modelData[3]
                    unit: modelData[4]
                    value: SettingsData[modelData[0]]
                    onSliderDragFinished: v => SettingsData.set(modelData[0], v)
                }
            }

            Repeater {
                model: SettingsData.alpeHyprBlurMode === "tuned" ? [["alpeHyprBlurNewOptimizations", "Optimierungen", "Rechnet die Unschärfe nur neu, wenn sich darunter etwas ändert. Sparsamer, selten Fehler."], ["alpeHyprBlurIgnoreOpacity", "Deckkraft der Fenster nicht beachten", "Zeichnet auch hinter fast deckenden Fenstern weich."], ["alpeHyprBlurPopups", "Popups weichzeichnen", "Menüs und Popups von Programmen; häufige Quelle von Fehlern."], ["alpeHyprBlurSpecial", "Spezial-Arbeitsflächen weichzeichnen", "Hintergrund des Scratchpads; kostet Leistung."]] : []

                SettingsToggleRow {
                    required property var modelData
                    width: parent ? parent.width : 0
                    text: modelData[1]
                    description: modelData[2]
                    checked: !!SettingsData[modelData[0]]
                    onToggled: checked => SettingsData.set(modelData[0], checked)
                }
            }

            SettingsRow {
                title: "Warum hat ein Programm keine Unschärfe?"
                subtitle: "Hyprland zeichnet nur hinter durchsichtigen Fenstern weich. Programme wie Nautilus malen ihren Hintergrund deckend: Erst eine Fensterregel mit Deckkraft unter 100 % (etwa 90 %) macht sie durchsichtig. Eine Regel mit Deckkraft 100 % ändert nichts."
                iconName: "help"
            }

            SettingsNavRow {
                title: I18n.tr("Window rules")
                hint: "Deckkraft je Programm, etwa Nautilus 90 %"
                iconName: "select_window"
                onClicked: keyboard => root.parentModal?.navigateTo("window_rules", keyboard)
            }
        }

        SettingsCard {
            id: live
            width: parent.width
            visible: CompositorService.isHyprland
            iconName: "fact_check"
            title: "Was in Hyprland gerade gilt"
            settingKey: "alpeHyprBlurLive"

            property var values: ({})
            readonly property var keys: ["enabled", "size", "passes", "noise", "contrast", "brightness", "vibrancy", "xray", "ignore_opacity", "new_optimizations", "popups", "special"]

            function refresh() {
                Proc.runCommand("alpe-hypr-blur", ["sh", "-c", 'for k in "$@"; do printf "%s\\t" "$k"; hyprctl -j getoption "decoration:blur:$k" 2>/dev/null | tr -d "\\n"; echo; done', "sh"].concat(keys), (output, code) => {
                    const next = {};
                    for (const line of String(output).split("\n")) {
                        const tab = line.indexOf("\t");
                        if (tab < 0)
                            continue;
                        try {
                            const o = JSON.parse(line.slice(tab + 1));
                            const v = o.int !== undefined ? o.int : o.float !== undefined ? Number(o.float).toFixed(3) : o.str !== undefined ? o.str : o.custom;
                            next[line.slice(0, tab)] = v;
                        } catch (e) {}
                    }
                    live.values = next;
                }, 0, 8000);
            }

            Timer {
                interval: 1500
                running: live.visible && root.visible
                repeat: true
                triggeredOnStart: true
                onTriggered: live.refresh()
            }

            Repeater {
                model: live.keys.filter(k => live.values[k] !== undefined)

                SettingsRow {
                    required property string modelData
                    width: parent ? parent.width : 0
                    title: "decoration:blur:" + modelData
                    trailingBadge: String(live.values[modelData])
                }
            }

            SettingsNoteRow {
                visible: Object.keys(live.values).length === 0
                text: "hyprctl antwortet nicht."
            }
        }
    }
}
