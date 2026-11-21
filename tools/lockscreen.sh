#!/usr/bin/env bash
# Alpe – Sperrbildschirm für den KDE-Sperrdienst einrichten.
#
#   lockscreen.sh status      was eingestellt ist und ob es lädt
#   lockscreen.sh install     Alpe-Design nach ~/.local/share/plasma/shells kopieren, unsichtbar
#                             zur Probe laden und nur einschalten, wenn es fehlerfrei lädt
#   lockscreen.sh use alpe    Alpe-Design verwenden (nach erfolgreicher Probe)
#   lockscreen.sh use kde     Design von KDE verwenden
#   lockscreen.sh repair      kaputte Verweise aufräumen (etwa auf ein entferntes Caelestia)
#   lockscreen.sh hyprlock DATEI
#                             eine hyprlock.conf als eigenes Layout übernehmen (ersetzt das in
#                             den Einstellungen gestaltete; dort lässt es sich weiter bearbeiten)
#   lockscreen.sh vorlage     eigenes Layout löschen, zurück zur Vorlage
#   lockscreen.sh show [SEK]  Sperrbildschirm zur Ansicht zeigen (sperrt nicht), Vorgabe 15 s
#
# Gestaltet wird der Sperrbildschirm in Alpes Einstellungen (Sicherheit → Sperrbildschirm
# gestalten); gespeichert ist das Layout in kscreenlockerrc ([Greeter][LnF][General] Layout).
# Ohne eigenes Layout gilt ~/.config/alpe/hyprlock.conf, sonst die neutrale Vorlage lockscreen/hyprlock.conf.
#
# Der Sperrdienst nimmt sein Design aus dem «Shell-Paket», das in plasmashellrc steht
# ([Shell] ShellPackage). Zeigt der Eintrag auf ein Paket, dessen Bausteine fehlen, erscheint
# KDEs blaues Notdesign. Dieses Skript schaltet nur auf ein Paket um, das zur Probe geladen hat.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$HERE/lockscreen/org.alpe.desktop"
# Ab 1.7 liegt die Ansicht (HyprlockView.qml, Vorlage, Schriften) im Shell-Code; sie wird
# beim Einrichten ins Design kopiert. So nutzen KDE-Sperre, Shell-Sperre und Vorschau dieselbe.
SHELL_DIR="${ALPE_SHELL_DIR:-$HERE/shell}"
VIEW="$SHELL_DIR/Modules/Lock/Alpe"
SHELLS="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/shells"
TARGET="$SHELLS/org.alpe.desktop"
ATTIC="${XDG_DATA_HOME:-$HOME/.local/share}/alpe/alte-shells"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/alpe/lock-probe.log"

say() { printf '%s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

greeter() {
    local candidate
    for candidate in /usr/lib/kscreenlocker_greet /usr/libexec/kscreenlocker_greet \
        /usr/lib64/libexec/kscreenlocker_greet /usr/lib/*/libexec/kscreenlocker_greet; do
        [ -x "$candidate" ] && { printf '%s' "$candidate"; return 0; }
    done
    return 1
}

current() { have kreadconfig6 && kreadconfig6 --file plasmashellrc --group Shell --key ShellPackage 2>/dev/null; }

set_shell() {
    if [ -z "$1" ]; then
        kwriteconfig6 --file plasmashellrc --group Shell --key ShellPackage --delete
    else
        kwriteconfig6 --file plasmashellrc --group Shell --key ShellPackage "$1"
    fi
}

shell_dir() {   # Name -> Ordner, falls vorhanden
    local base
    for base in "$SHELLS" /usr/share/plasma/shells; do
        [ -d "$base/$1" ] && { printf '%s' "$base/$1"; return 0; }
    done
    return 1
}

# Probe: Sperrbildschirm im Testmodus mit dem angegebenen Paket. Er sperrt nichts; nach der
# Wartezeit wird er beendet. Rückgabe 0, wenn das Design ohne Rückfall auf das Notdesign lud.
probe() {   # Paketname, Sekunden
    local bin
    bin="$(greeter)" || { say "   kscreenlocker_greet nicht gefunden"; return 2; }
    mkdir -p "$(dirname "$LOG")"
    # Unsichtbar (offscreen): Geprüft wird nur, ob das Design fehlerfrei lädt. Sichtbar zeigt es «show».
    QT_QPA_PLATFORM=offscreen QT_LOGGING_RULES="kscreenlocker*=true" timeout "${2:-5}" "$bin" --testing --shell "$1" > "$LOG" 2>&1
    local rc=$?
    # Bricht der Greeter offscreen vorzeitig ab, ohne dass QML schuld ist: sichtbar wiederholen
    if [ "$rc" != 124 ] && [ "$rc" != 0 ] && ! grep -Eqi 'falling back|Failed to load|Lockscreen QML outdated' "$LOG"; then
        QT_LOGGING_RULES="kscreenlocker*=true" timeout "${2:-5}" "$bin" --testing --shell "$1" > "$LOG" 2>&1
    fi
    if grep -Eqi 'falling back|Failed to load|Lockscreen QML outdated' "$LOG"; then
        grep -Ei 'is not installed|is not a type|unavailable|Error' "$LOG" | sed 's/^/      /' | head -6
        return 1
    fi
    return 0
}

# Alpe 1.0: Eine eigene Vorlage unter ~/.config/alpe/hyprlock.conf hat Vorrang vor der neutralen
# im Repository (wie oben im Kopf der Vorlage beschrieben).
conf_path() {
    local own="${XDG_CONFIG_HOME:-$HOME/.config}/alpe/hyprlock.conf"
    if [ -f "$own" ]; then printf '%s' "$own"; else printf '%s' "$HERE/lockscreen/hyprlock.conf"; fi
}
lnf() { kreadconfig6 --file kscreenlockerrc --group Greeter --group LnF --group General --key "$1" 2>/dev/null; }
set_lnf() {
    if [ -z "$2" ]; then kwriteconfig6 --file kscreenlockerrc --group Greeter --group LnF --group General --key "$1" --delete
    else kwriteconfig6 --file kscreenlockerrc --group Greeter --group LnF --group General --key "$1" "$2"; fi
}

# hyprlock.conf -> layout.js im installierten Paket. Schlägt das fehl, bleibt die alte Datei.
build_layout() {
    local conf
    conf="$(conf_path)"
    [ -d "$TARGET" ] || return 0
    have python3 || { say "   python3 fehlt – Aufbau aus der hyprlock.conf übersprungen"; return 0; }
    say "   Vorlage: $conf"
    python3 -I "$HERE/tools/hyprlock2qml.py" "$conf" -o "$TARGET/contents/lockscreen/layout.js" \
        || say "   FEHLER beim Umsetzen – der bisherige Aufbau bleibt"
}

# Bildpfade des gültigen Layouts: aus den Einstellungen, sonst aus der Vorlage.
image_paths() {
    local layout
    layout="$(lnf Layout)"
    if [ -n "$layout" ] && have python3; then
        printf '%s' "$layout" | python3 -I -c 'import json,sys
try:
    for w in json.load(sys.stdin).get("widgets", []):
        if w.get("type") == "image" and w.get("path"): print(w["path"])
except Exception: pass'
    else
        awk '/^[[:space:]]*image[[:space:]]*\{/{img=1} img && /^[[:space:]]*path[[:space:]]*=/{sub(/^[^=]*=[[:space:]]*/,""); sub(/[[:space:]]*#.*/,""); print; img=0} /\}/{img=0}' "$(conf_path)"
    fi
}

images_check() {
    local path missing=0
    while IFS= read -r path; do
        path="${path/#\~/$HOME}"
        if [ ! -f "$path" ]; then
            [ "$missing" = 0 ] && say "   Bilder des Layouts, die hier fehlen:"
            say "      $path"
            missing=$((missing + 1))
        fi
    done < <(image_paths)
    if [ "$missing" -gt 0 ]; then
        say "   (ohne sie bleibt die Stelle leer; vom MacBook holen, etwa: scp -r macbook:Pictures/Hyprlock ~/Pictures/)"
    else
        say "   alle Bilder des Layouts vorhanden"
    fi
}

repair() {
    local now dir
    now="$(current)"
    case "$now" in
        ""|org.kde.plasma.desktop|org.alpe.desktop) ;;
        *)
            dir="$(shell_dir "$now" || true)"
            say "   Verweis auf das Shell-Paket «$now» entfernt (KDE nimmt wieder sein eigenes)"
            set_shell ""
            if [ -n "$dir" ] && [ "${dir#"$SHELLS"/}" != "$dir" ]; then
                mkdir -p "$ATTIC"
                mv "$dir" "$ATTIC/$(basename "$dir").$(date +%Y%m%d-%H%M%S)"
                say "   Paket verschoben nach $ATTIC"
            fi
            ;;
    esac
    # Übrige Pakete unter ~/.local/share, die nicht von Alpe sind, nur nennen.
    for dir in "$SHELLS"/*; do
        [ -d "$dir" ] || continue
        case "$(basename "$dir")" in org.alpe.desktop) continue ;; esac
        say "   HINWEIS: weiteres Shell-Paket $dir (wird nicht verwendet, kann weg)"
    done
}

kde_check() {
    shell_dir org.kde.plasma.desktop >/dev/null || say "   HINWEIS: KDEs eigenes Design (Paket plasma-desktop) fehlt; ohne Alpe-Design bliebe nur das Notdesign."
}

pam_check() {
    local found=""
    for file in /etc/pam.d/kde /usr/lib/pam.d/kde; do [ -e "$file" ] && found="$file"; done
    if [ -n "$found" ]; then
        say "   Anmeldedienst (PAM) «kde»: $found"
    else
        say "   FEHLT: PAM-Dienst «kde» weder in /etc/pam.d noch in /usr/lib/pam.d."
        say "          Ohne ihn lehnt PAM jedes Passwort ab. Neu installieren: sudo pacman -S kscreenlocker"
    fi
}

case "${1:-}" in
status)
    now="$(current)"
    say "Shell-Paket für den Sperrbildschirm: ${now:-<Vorgabe: org.kde.plasma.desktop>}"
    if [ -n "$now" ] && ! shell_dir "$now" >/dev/null; then say "   FEHLT: Paket «$now» ist nicht installiert"; fi
    [ -d "$TARGET" ] && say "Alpe-Design installiert: $TARGET" || say "Alpe-Design nicht installiert"
    style="$(kreadconfig6 --file kscreenlockerrc --group Greeter --group LnF --group General --key Style 2>/dev/null)"
    say "Stil: ${style:-hyprlock (Vorgabe)}"
    if [ -n "$(lnf Layout)" ]; then say "Layout: eigenes (in den Einstellungen gestaltet)"
    else say "Layout: Vorlage $(conf_path)"; fi
    images_check
    kde_check
    pam_check
    ;;
repair)
    repair
    pam_check
    ;;
install)
    have kwriteconfig6 && have kreadconfig6 || { say "   kwriteconfig6/kreadconfig6 fehlen – kein KDE? übersprungen"; exit 0; }
    repair
    mkdir -p "$SHELLS"
    rm -rf "$TARGET.neu"
    [ -f "$VIEW/HyprlockView.qml" ] || { say "   FEHLT: $VIEW/HyprlockView.qml – zuerst den Shell-Code auf 1.7 bringen (bash $HERE/install.sh)"; exit 1; }
    cp -r "$SOURCE" "$TARGET.neu" \
        && cp "$VIEW/HyprlockView.qml" "$VIEW/layout.js" "$TARGET.neu/contents/lockscreen/" \
        && cp -r "$VIEW/fonts" "$TARGET.neu/contents/lockscreen/" \
        && rm -rf "$TARGET" && mv "$TARGET.neu" "$TARGET"
    say "   Alpe-Design kopiert nach $TARGET"
    build_layout
    images_check
    # Einmalig mit 1.4.3: Wer den Stil nie bewusst gewählt hat oder noch «klar» (die alte
    # Vorgabe) hat, bekommt den Stil «hyprlock» wie am MacBook.
    marker="${XDG_STATE_HOME:-$HOME/.local/state}/alpe/lockstil-1.4.3"
    if [ ! -e "$marker" ]; then
        style="$(kreadconfig6 --file kscreenlockerrc --group Greeter --group LnF --group General --key Style 2>/dev/null)"
        if [ -z "$style" ] || [ "$style" = klar ]; then
            kwriteconfig6 --file kscreenlockerrc --group Greeter --group LnF --group General --key Style hyprlock
            say "   Stil auf «hyprlock» (wie am MacBook) gestellt; zurück: Einstellungen → Sperrbildschirm → Stil"
        fi
        mkdir -p "$(dirname "$marker")" && touch "$marker"
    fi
    if [ "$(current)" = org.alpe.desktop ]; then
        say "   ist bereits eingeschaltet"
    elif [ "${ALPE_LOCK_PROBE:-1}" = 0 ]; then
        say "   Probe übersprungen; einschalten mit: bash $0 use alpe"
    else
        say "   Probe: Sperrbildschirm wird unsichtbar geladen (gesperrt wird nichts; ansehen: bash $0 show)"
        if probe org.alpe.desktop 5; then
            set_shell org.alpe.desktop
            say "   Probe bestanden – Alpe-Design eingeschaltet"
        else
            say "   Probe nicht bestanden – KDE-Design bleibt. Meldungen: $LOG"
        fi
    fi
    kde_check
    pam_check
    ;;
use)
    case "${2:-}" in
    alpe)
        [ -d "$TARGET" ] || { say "Zuerst: bash $0 install"; exit 1; }
        if probe org.alpe.desktop 5; then set_shell org.alpe.desktop; say "Alpe-Design eingeschaltet"
        else say "Probe nicht bestanden, nichts geändert. Meldungen: $LOG"; exit 1; fi
        ;;
    kde)
        set_shell ""
        say "KDE-Design eingeschaltet"
        ;;
    *) say "use alpe | use kde"; exit 2 ;;
    esac
    ;;
hyprlock)
    [ -f "${2:-}" ] || { say "Aufruf: bash $0 hyprlock /pfad/hyprlock.conf"; exit 1; }
    json="$(python3 -I "$HERE/tools/hyprlock2qml.py" "$2" --json)" || { say "Umsetzen fehlgeschlagen"; exit 1; }
    old="$(lnf Layout)"
    if [ -n "$old" ]; then
        mkdir -p "$(dirname "$LOG")"; printf '%s\n' "$old" > "$(dirname "$LOG")/layout.vorher.json"
        say "   bisheriges Layout gesichert: $(dirname "$LOG")/layout.vorher.json"
    fi
    set_lnf Layout "$json"
    set_lnf Style hyprlock
    say "   übernommen; weiter gestalten in den Einstellungen (Sicherheit → Sperrbildschirm gestalten)"
    images_check
    ;;
vorlage)
    set_lnf Layout ""
    say "   eigenes Layout gelöscht – es gilt die Vorlage ($(conf_path))"
    ;;
show)
    bin="$(greeter)" || { say "kscreenlocker_greet nicht gefunden"; exit 2; }
    say "Sperrbildschirm zur Ansicht, ${2:-15} Sekunden (sperrt nicht; Passwort entsperrt die Ansicht)"
    timeout "${2:-15}" "$bin" --testing --shell org.alpe.desktop >/dev/null 2>&1
    ;;
*)
    sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 2
    ;;
esac
