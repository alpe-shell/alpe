#!/usr/bin/env bash
# Alpe: prüft den KDE-Sperrbildschirm, ohne die Sitzung zu sperren.
#
#   alpe-lockcheck.sh test [paket]
#                              startet den Sperrbildschirm im Testmodus (ein Fenster, kein
#                              Sperren; das Passwort schliesst es, sonst nach 90 s von selbst)
#                              und gibt danach eine Zeile JSON mit dem Befund aus
#   alpe-lockcheck.sh report   ausführlicher Bericht als Text (für die Fehlersuche)
#
# Hintergrund: Lädt das Design des Sperrbildschirms nicht (fehlendes Paket, entferntes globales
# Design), zeigt KDE ein blaues Notdesign. Der Testmodus zeigt dasselbe gefahrlos und nennt in
# seinen Meldungen den Grund.
set -u

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/alpe"
LOG="$CACHE/lock-test.log"

greeter() {
    local candidate
    for candidate in /usr/lib/kscreenlocker_greet /usr/libexec/kscreenlocker_greet \
        /usr/lib64/libexec/kscreenlocker_greet /usr/lib/*/libexec/kscreenlocker_greet; do
        [ -x "$candidate" ] && { printf '%s' "$candidate"; return 0; }
    done
    return 1
}

run_greeter() {   # Sekunden [Shell-Paket]
    mkdir -p "$CACHE"
    local bin
    bin="$(greeter)" || { : > "$LOG"; return 127; }
    if [ -n "${2:-}" ]; then
        QT_LOGGING_RULES="${QT_LOGGING_RULES:-kscreenlocker*=true}" timeout "$1" "$bin" --testing --shell "$2" > "$LOG" 2>&1
    else
        QT_LOGGING_RULES="${QT_LOGGING_RULES:-kscreenlocker*=true}" timeout "$1" "$bin" --testing > "$LOG" 2>&1
    fi
}

fallback_used() { grep -Eqi 'falling back to (built-in|default)|fallbacktheme|Lockscreen QML outdated' "$LOG" 2>/dev/null; }

missing_modules() {
    # Die Meldung kommt auch verschachtelt vor, dann mit maskierten Anführungszeichen.
    grep -oE 'module \\?"[^"\\]+\\?" is not installed' "$LOG" 2>/dev/null | sed -E 's/module \\?"([^"\\]+).*/\1/' | sort -u
}

# Paket zu einem QML-Modul: zuerst die Dateiliste von pacman, sonst eine Tabelle der üblichen.
package_for() {
    local module="$1" path found
    path="usr/lib/qt6/qml/$(printf '%s' "$module" | tr . /)/qmldir"
    if command -v pacman >/dev/null 2>&1; then
        found="$(pacman -Fq "$path" 2>/dev/null | head -1 | sed 's|.*/||')"
        [ -n "$found" ] && { printf '%s' "$found"; return 0; }
    fi
    case "$module" in
        org.kde.breeze.components*|org.kde.plasma.workspace*|org.kde.plasma.private.sessions*|org.kde.plasma.private.keyboardindicator*|org.kde.plasma.wallpapers*|org.kde.plasma.lookandfeel*) printf 'plasma-workspace' ;;
        org.kde.breeze*) printf 'breeze' ;;
        org.kde.plasma.plasma5support*) printf 'plasma5support' ;;
        org.kde.plasma.components*|org.kde.plasma.extras*|org.kde.plasma.core*|org.kde.plasma.plasmoid*) printf 'libplasma' ;;
        org.kde.kirigami*) printf 'kirigami' ;;
        org.kde.ksvg*) printf 'ksvg' ;;
        org.kde.kquickcontrolsaddons*|org.kde.kquickcontrols*) printf 'kdeclarative' ;;
        org.kde.kscreenlocker*) printf 'kscreenlocker' ;;
        org.kde.kitemmodels*) printf 'kitemmodels' ;;
        org.kde.kcmutils*) printf 'kcmutils' ;;
        org.kde.config*) printf 'kconfig' ;;
        org.kde.coreaddons*) printf 'kcoreaddons' ;;
        org.kde.kwindowsystem*) printf 'kwindowsystem' ;;
        org.kde.desktop*|org.kde.qqc2desktopstyle*) printf 'qqc2-desktop-style' ;;
        QtQuick.VirtualKeyboard*) printf 'qt6-virtualkeyboard' ;;
        Qt5Compat*) printf 'qt6-5compat' ;;
        QtMultimedia*) printf 'qt6-multimedia' ;;
        *) return 1 ;;
    esac
}

suggestion() {
    local module package packages=""
    for module in $(missing_modules); do
        package="$(package_for "$module")" || continue
        case " $packages " in *" $package "*) ;; *) packages="$packages $package" ;; esac
    done
    packages="${packages# }"
    [ -n "$packages" ] || return 1
    if command -v pacman >/dev/null 2>&1; then
        printf 'sudo pacman -S --needed %s' "$packages"
    elif command -v dnf >/dev/null 2>&1; then
        printf 'sudo dnf install %s' "$packages"
    else
        printf '%s' "$packages"
    fi
}

json_string() { printf '%s' "$1" | sed -e 's/[\\"]/\\&/g' | tr -d '\000-\037'; }

summary_json() {   # Rückgabewert des Greeters
    local code="$1" found=true fallback=false modules="" module first=1 hint
    greeter >/dev/null || found=false
    fallback_used && fallback=true
    for module in $(missing_modules); do
        [ "$first" = 1 ] || modules="$modules,"
        modules="$modules\"$(json_string "$module")\""; first=0
    done
    hint="$(suggestion || true)"
    printf '{"greeter":%s,"fallback":%s,"missing":[%s],"suggest":"%s","code":%s,"errors":%s}\n' \
        "$found" "$fallback" "$modules" "$(json_string "$hint")" "$code" \
        "$(grep -Eci 'is not installed|unavailable|is not a type|ReferenceError|TypeError' "$LOG" 2>/dev/null || true)"
}

section() { printf '\n=== %s ===\n' "$1"; }
read_config() { command -v kreadconfig6 >/dev/null 2>&1 && kreadconfig6 --file "$1" --group "$2" --key "$3" 2>/dev/null; }

case "${1:-}" in
test)
    run_greeter 90 "${2:-}"; code=$?
    summary_json "$code"
    ;;
report)
    echo "Alpe – Bericht zum KDE-Sperrbildschirm, $(date '+%Y-%m-%d %H:%M')"
    section "Pakete"
    if command -v pacman >/dev/null 2>&1; then
        pacman -Q kscreenlocker plasma-workspace libplasma kirigami ksvg kdeclarative plasma5support breeze qqc2-desktop-style kwin 2>&1
    elif command -v rpm >/dev/null 2>&1; then
        rpm -q kscreenlocker plasma-workspace libplasma kf6-kirigami kf6-ksvg kf6-kdeclarative plasma5support kwin 2>&1
    fi
    section "Design"
    theme="$(read_config kscreenlockerrc Greeter Theme)"
    global="$(read_config kdeglobals KDE LookAndFeelPackage)"
    echo "Sperrbildschirm-Design (kscreenlockerrc): ${theme:-<keins gesetzt>}"
    echo "Globales Design (kdeglobals):             ${global:-<keins gesetzt, Vorgabe org.kde.breeze.desktop>}"
    echo "Hintergrund-Plugin:                       $(read_config kscreenlockerrc Greeter WallpaperPlugin)"
    shell="$(read_config plasmashellrc Shell ShellPackage)"
    echo "Shell-Paket (plasmashellrc) – daraus kommt der Sperrbildschirm: ${shell:-<Vorgabe org.kde.plasma.desktop>}"
    for base in "${XDG_DATA_HOME:-$HOME/.local/share}/plasma/shells" /usr/share/plasma/shells; do
        [ -d "$base" ] && for dir in "$base"/*; do [ -e "$dir/contents/lockscreen/LockScreen.qml" ] && echo "  Sperrbildschirm vorhanden in: $dir"; done
    done
    for name in "$theme" "$global" org.kde.breeze.desktop; do
        [ -n "$name" ] || continue
        for base in "$HOME/.local/share/plasma/look-and-feel" /usr/share/plasma/look-and-feel; do
            if [ -d "$base/$name" ]; then
                printf '  %s/%s: vorhanden' "$base" "$name"
                [ -e "$base/$name/contents/lockscreen/LockScreen.qml" ] && printf ', mit eigenem Sperrbildschirm' || printf ', ohne eigenen Sperrbildschirm (nimmt die Vorgabe)'
                printf '\n'
            fi
        done
        [ -d "$HOME/.local/share/plasma/look-and-feel/$name" ] || [ -d "/usr/share/plasma/look-and-feel/$name" ] || echo "  $name: FEHLT"
    done
    section "Testlauf (6 Sekunden, sperrt nicht)"
    if greeter >/dev/null; then
        echo "Programm: $(greeter)"
        run_greeter 6; code=$?
        echo "Rückgabewert: $code (124 heisst: lief bis zum Ende der Testzeit, also normal)"
        if fallback_used; then echo "BEFUND: Das Design lädt nicht, KDE nimmt das blaue Notdesign."; else echo "Befund: kein Hinweis auf das Notdesign."; fi
        modules="$(missing_modules | tr '\n' ' ')"
        [ -n "$modules" ] && echo "Fehlende QML-Module: $modules"
        hint="$(suggestion || true)"
        [ -n "$hint" ] && echo "Vorschlag: $hint"
        echo "--- Meldungen (gekürzt) ---"
        grep -Ei 'kscreenlocker|falling back|not installed|unavailable|is not a type|Error|PAM|qml' "$LOG" | head -60
    else
        echo "kscreenlocker_greet nicht gefunden – ist das Paket kscreenlocker installiert?"
    fi
    section "Anmeldung (PAM)"
    ls -l /etc/pam.d/kde* /usr/lib/pam.d/kde* 2>/dev/null || echo "kein PAM-Dienst kde* gefunden"
    for file in /etc/pam.d/kde /usr/lib/pam.d/kde; do [ -e "$file" ] && { echo "--- $file ---"; cat "$file"; break; }; done
    echo "--- gesperrte Fehlversuche ---"; faillock --user "$USER" 2>&1 | head -12
    ls -l /usr/bin/unix_chkpwd /usr/sbin/unix_chkpwd 2>/dev/null
    section "Umgebung von KWin"
    pid="$(pgrep -u "$(id -u)" -f '(^|/)kwin_wayland( |$)' | head -1)"
    if [ -n "$pid" ] && [ -r "/proc/$pid/environ" ]; then
        tr '\0' '\n' < "/proc/$pid/environ" | grep -E '^(QML|QT_|KDE_|PLASMA|XDG_CURRENT_DESKTOP|XDG_SESSION)' | sort
    else
        echo "kwin_wayland läuft nicht oder ist nicht lesbar"
    fi
    section "Journal (letzte Meldungen der Sperre)"
    journalctl --user -b --no-pager -o cat -g 'kscreenlocker|screenlocker|ksld' 2>/dev/null | tail -40
    section "Notausgang"
    echo "Hängt der Sperrbildschirm: Strg+Alt+F3, anmelden, 'loginctl unlock-sessions', zurück mit Strg+Alt+F1 oder F2."
    ;;
*)
    sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 2
    ;;
esac
