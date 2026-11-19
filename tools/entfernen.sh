#!/usr/bin/env bash
# Alpe entfernen – der Rechner wie vor der Installation.
#
#   alpe entfernen [--check]           Alpe weg, KDE/Hyprland wie vorher; DMS-Paket und
#                                      DMS-Einstellungen bleiben, ebenso ~/.config/alpe (Sicherungen)
#   alpe entfernen --alles [--check]   dazu: Einstellungen von DMS, kitty und fastfetch (soweit sie
#                                      erst mit Alpe kamen), ~/.config/alpe, die Pakete, die get.sh
#                                      installiert hat (Liste zuerst mit pacman --print), und ~/alpe
#   --ja                               ohne Rückfragen (Pakete werden trotzdem erst gezeigt)
#
# Zurückgespielt wird die älteste Sicherung unter ~/.config/alpe/design-sicherung: der Stand
# unmittelbar vor dem ersten «alpe design apply» (KWin, Sperrbildschirm, kitty, fastfetch …).
set -uo pipefail

HERE="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
SHELL_DIR="${ALPE_SHELL_DIR:-$HOME/dux-shell}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"

CHECK=0; ALL=0; YES=0
for arg in "$@"; do
    case "$arg" in
        --check) CHECK=1 ;;
        --alles) ALL=1 ;;
        --ja) YES=1 ;;
        *) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
    esac
done

say() { printf '   %s\n' "$*"; }
bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
run() { if [ "$CHECK" = 1 ]; then say "würde: $*"; else "$@"; fi; }
gone() { local p; for p in "$@"; do [ -e "$p" ] || [ -L "$p" ] || continue; run rm -rf "$p"; [ "$CHECK" = 1 ] || say "entfernt: ${p/#"$HOME"/\~}"; done; }
ask() {
    [ "$YES" = 1 ] || [ "$CHECK" = 1 ] && return 0
    local answer; printf '   %s [J/n] ' "$1"; read -r answer </dev/tty || answer=""
    case "${answer:-j}" in j|J|ja|y|Y) return 0 ;; *) return 1 ;; esac
}
kde() { case "${XDG_CURRENT_DESKTOP:-}" in *KDE*|*kwin*|*KWIN*) return 0 ;; esac; return 1; }
kwrite() { command -v kwriteconfig6 >/dev/null && run kwriteconfig6 "$@"; }

[ "$CHECK" = 1 ] && printf '\nProbelauf – nichts wird verändert.\n'
if [ "$CHECK" = 0 ] && [ "$YES" = 0 ]; then
    printf '\nAlpe wird entfernt%s.\n' "$([ "$ALL" = 1 ] && echo ' – mit allen Einstellungen und den von Alpe installierten Paketen')"
    ask "Weiter?" || exit 0
fi

# Merkliste der Pakete lesen, bevor ~/.config/alpe verschwindet
pkgs=()
[ -f "$CONFIG/alpe/pakete" ] && mapfile -t pkgs < <(grep -v '^\s*$' "$CONFIG/alpe/pakete")
oldest="$(ls -1d "$CONFIG"/alpe/design-sicherung/*/ 2>/dev/null | sort | head -1)"
oldest="${oldest%/}"

# ---------------------------------------------------------------- Oberfläche
if kde; then
    bold "KDE Plasma"
    [ -f "$HERE/tools/kde-sitzung.sh" ] && run bash "$HERE/tools/kde-sitzung.sh" aus --jetzt | sed 's/^/   /'
    [ -f "$HERE/tools/lockscreen.sh" ] && run bash "$HERE/tools/lockscreen.sh" use kde | sed 's/^/   /'
else
    run systemctl --user stop dms.service 2>/dev/null
fi
[ -f "$HERE/tools/kopfleiste.py" ] && run python3 "$HERE/tools/kopfleiste.py" aus | sed 's/^/   /'

# ---------------------------------------------------------------- Einstellungen von vorher
bold "Einstellungen von vor Alpe"
if [ -n "$oldest" ]; then
    say "älteste Sicherung: ${oldest/#"$HOME"/\~}"
    for f in kwinrc kwinrulesrc kdeglobals kscreenlockerrc; do
        [ -f "$oldest/$f" ] && run cp "$oldest/$f" "$CONFIG/$f" && say "zurück: $f"
    done
    [ "$ALL" = 0 ] && for f in settings.json plugin_settings.json; do
        [ -f "$oldest/$f" ] && run cp "$oldest/$f" "$CONFIG/dms/$f" && say "zurück: dms/$f"
    done
    [ "$ALL" = 0 ] && [ -f "$oldest/session.json" ] && run cp "$oldest/session.json" "$STATE/dms/session.json" && say "zurück: dms/session.json"
    [ -f "$oldest/hyprlock.conf" ] && run cp "$oldest/hyprlock.conf" "$CONFIG/hypr/hyprlock.conf" && say "zurück: hypr/hyprlock.conf"
    for app in kitty fastfetch; do
        if [ -d "$oldest/programme/$app" ]; then
            gone "$CONFIG/$app"; run cp -r "$oldest/programme/$app" "$CONFIG/$app"; say "zurück: $app"
        elif [ "$ALL" = 1 ]; then
            gone "$CONFIG/$app"       # kam erst mit dem Design
        fi
    done
else
    say "keine Sicherung gefunden (Design nie eingespielt) – KDE-Dateien bleiben, wie sie sind"
fi
if kde; then
    # Nach dem Zurückspielen: die Sicherung entstand erst nach install.sh (Titelleisten-Regel, Sperre beim Start)
    kwrite --file kscreenlockerrc --group Daemon --key LockOnStart --delete
    if [ -f "$SHELL_DIR/quickshell/scripts/alpe-kwin.py" ]; then
        run env ALPE_SHELL_DIR="$SHELL_DIR" python3 "$HERE/tools/titelleisten.py" an | sed 's/^/   /'
        run env ALPE_SHELL_DIR="$SHELL_DIR" python3 "$HERE/tools/kuerzel.py" zurueck
    fi
    command -v qdbus6 >/dev/null && run qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1
fi
# fastfetch.py legt vor dem Umbau eine eigene Sicherung an
for b in "$CONFIG"/fastfetch/config.json*.vor-alpe; do
    [ -f "$b" ] && [ -z "$oldest" -o ! -d "$oldest/programme/fastfetch" ] && run mv "$b" "${b%.vor-alpe}" && say "zurück: fastfetch/$(basename "${b%.vor-alpe}")"
done
gone "$CONFIG/fastfetch/alpe-logo.txt"

# ---------------------------------------------------------------- Start der Shell
bold "Start der Shell"
[ -f "$HERE/bootstrap.sh" ] && run bash "$HERE/bootstrap.sh" --undo | sed 's/^/   /'
gone "$CONFIG/systemd/user/dms.service.d/alpe.conf" "$CONFIG/systemd/user/dms.service.d/zz-alpe-name.conf" \
     "$CONFIG/systemd/user/dms.service.d/zz-alpe-backend.conf"
rmdir "$CONFIG/systemd/user/dms.service.d" 2>/dev/null
run systemctl --user daemon-reload 2>/dev/null

# ---------------------------------------------------------------- Dateien
bold "Dateien von Alpe"
gone "$DATA/applications/dev.duxlabs.shell.desktop" "$DATA/plasma/shells/org.alpe.desktop" \
     "$DATA/alpe" "$HOME/.local/lib/alpe" "$SHELL_DIR"
for p in "$HERE"/plugins/*/; do gone "$CONFIG/dms/plugins/$(basename "$p")"; done
if [ -L "$HOME/.local/bin/alpe" ]; then
    gone "$HOME/.local/bin/alpe"
    [ -e "$HOME/.local/bin/alpe.vorher" ] && run mv "$HOME/.local/bin/alpe.vorher" "$HOME/.local/bin/alpe"
fi

if [ "$ALL" = 1 ]; then
    bold "Alles übrige"
    gone "$CONFIG/dms" "$STATE/dms" "$CACHE/dms" "$CONFIG/alpe"
else
    say "bleibt: ~/.config/alpe (Sicherungen), Einstellungen von DMS – ganz weg mit «alpe entfernen --alles»"
fi

# ---------------------------------------------------------------- Pakete
if [ "$ALL" = 1 ] && [ "${#pkgs[@]}" -gt 0 ]; then
    bold "Pakete, die Alpe installiert hat"
    present=()
    for p in "${pkgs[@]}"; do
        if command -v pacman >/dev/null; then pacman -Q "$p" >/dev/null 2>&1 && present+=("$p")
        elif command -v rpm >/dev/null; then rpm -q "$p" >/dev/null 2>&1 && present+=("$p"); fi
    done
    if [ "${#present[@]}" -eq 0 ]; then
        say "keine mehr installiert"
    elif command -v pacman >/dev/null; then
        say "würde entfernt (mit nicht mehr gebrauchten Abhängigkeiten):"
        pacman -Rs --print "${present[@]}" 2>&1 | sed 's/^/      /'
        if [ "$CHECK" = 0 ] && ask "Diese Pakete entfernen?"; then
            sudo pacman -Rns "${present[@]}" </dev/tty
        fi
    else
        say "zum Entfernen: sudo dnf remove ${present[*]}"
    fi
elif [ "$ALL" = 1 ]; then
    say "Keine Liste der von Alpe installierten Pakete (~/.config/alpe/pakete) – Pakete bleiben."
fi

# ---------------------------------------------------------------- Repository
if [ "$ALL" = 1 ] && [ -d "$HERE/.git" -o -f "$HERE/bootstrap.sh" ]; then
    bold "Alpe selbst"
    gone "$HERE"
fi

bold "Fertig"
if [ "$CHECK" = 1 ]; then say "Probelauf – nichts verändert."
else
    say "Einmal ab- und wieder anmelden, dann ist der Rechner wie vor Alpe."
    kde || say "Hyprland: eine Zeile «exec-once = dms run» in der eigenen hyprland.conf bleibt – sie gehört zu DMS."
fi
