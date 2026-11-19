#!/usr/bin/env bash
# Alpe: Systemaktualisierung mit dem eigenen Wartungsbefehl in einem Terminalfenster.
#
#   alpe-update.sh launch <Terminal oder ""> <Befehl> [Terminal-Argumente ...]
#       öffnet ein Terminal in einer eigenen systemd-Scope. So überlebt die
#       Aktualisierung einen Neustart der Shell, etwa wenn sie Quickshell erneuert.
#   alpe-update.sh run <Befehl>
#       läuft im Terminal: führt den Befehl aus und hält den Stand fest.
#   alpe-update.sh open <Terminal oder ""> <Titel> <Programm> [Argumente ...]
#       beliebiges Programm in einem Terminalfenster, etwa ein Protokoll.
#
# Stand: ~/.local/state/alpe/update.json, von der Shell beobachtet.
set -u

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/alpe"
STATE="$STATE_DIR/update.json"
TITLE="Alpe – Systemaktualisierung"
APP_ID="alpe.update"

json_string() { printf '%s' "$1" | sed -e 's/[\\"]/\\&/g' | tr -d '\000-\037'; }

write_state() {   # Zustand, Beginn, Ende, Code
    mkdir -p "$STATE_DIR" || return 1
    printf '{"state":"%s","command":"%s","started":%s,"finished":%s,"code":%s}\n' \
        "$1" "$(json_string "$COMMAND")" "$2" "$3" "$4" > "$STATE.$$.tmp" && mv -f "$STATE.$$.tmp" "$STATE"
}

find_terminal() {
    local wanted="$1" candidate
    for candidate in "$wanted" "${TERMINAL:-}" kitty ghostty foot alacritty wezterm konsole gnome-terminal xterm; do
        [ -n "$candidate" ] && command -v "$candidate" >/dev/null 2>&1 && { printf '%s' "$candidate"; return 0; }
    done
    return 1
}

case "${1:-}" in
open)
    wanted="${2:-}"; TITLE="${3:-Alpe}"; shift 3 2>/dev/null || shift $#
    [ $# -gt 0 ] || { echo "kein Programm angegeben" >&2; exit 2; }
    terminal="$(find_terminal "$wanted")" || { echo "kein Terminal gefunden" >&2; exit 3; }
    APP_ID="alpe.terminal"
    case "$(basename "$terminal")" in
        kitty|alacritty) argv=("$terminal" --class "$APP_ID" -T "$TITLE" -e) ;;
        foot)            argv=("$terminal" "--app-id=$APP_ID" "--title=$TITLE") ;;
        ghostty)         argv=("$terminal" "--class=$APP_ID" "--title=$TITLE" -e) ;;
        wezterm)         argv=("$terminal" start --always-new-process --class "$APP_ID" --) ;;
        konsole)         argv=("$terminal" -p "tabtitle=$TITLE" -e) ;;
        gnome-terminal)  argv=("$terminal" "--title=$TITLE" --) ;;
        *)               argv=("$terminal" -e) ;;
    esac
    exec setsid -f "${argv[@]}" "$@"
    ;;
launch)
    wanted="${2:-}"; COMMAND="${3:-}"; shift 3 2>/dev/null || shift $#
    if [ -z "$COMMAND" ]; then echo "kein Befehl angegeben" >&2; exit 2; fi
    terminal="$(find_terminal "$wanted")" || { echo "kein Terminal gefunden" >&2; exit 3; }
    self="$(readlink -f "$0")"
    case "$(basename "$terminal")" in
        kitty|alacritty) argv=("$terminal" --class "$APP_ID" -T "$TITLE" "$@" -e) ;;
        foot)            argv=("$terminal" "--app-id=$APP_ID" "--title=$TITLE" "$@") ;;
        ghostty)         argv=("$terminal" "--class=$APP_ID" "--title=$TITLE" "$@" -e) ;;
        wezterm)         argv=("$terminal" start --always-new-process --class "$APP_ID" "$@" --) ;;
        konsole)         argv=("$terminal" -p "tabtitle=$TITLE" "$@" -e) ;;
        gnome-terminal)  argv=("$terminal" --wait "--title=$TITLE" "$@" --) ;;
        *)               argv=("$terminal" "$@" -e) ;;
    esac
    argv+=(bash "$self" run "$COMMAND")
    if command -v systemd-run >/dev/null 2>&1; then
        exec systemd-run --user --scope --collect --quiet --unit "alpe-update-$(date +%s)" -- "${argv[@]}"
    fi
    exec setsid -f "${argv[@]}"
    ;;
run)
    COMMAND="${2:-}"
    case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
    if [ -z "$COMMAND" ]; then echo "kein Befehl angegeben" >&2; exit 2; fi
    started="$(date +%s)"; finished=0; code=-1; state="aborted"
    # Wird das Fenster mitten im Lauf geschlossen, bleibt "aborted" stehen statt "running".
    trap 'write_state "$state" "$started" "$(date +%s)" "$code"' EXIT
    trap 'exit 130' HUP INT TERM
    write_state running "$started" 0 null
    printf '\033[1;36m=== %s ===\033[0m\n\033[2m$ %s\033[0m\n\n' "$TITLE" "$COMMAND"
    bash -c "$COMMAND"
    code=$?
    if [ "$code" -eq 0 ]; then
        state="done"
        printf '\n\033[1;32m=== Fertig. Eingabetaste schliesst das Fenster. ===\033[0m\n'
    else
        state="failed"
        printf '\n\033[1;31m=== Mit Fehlern beendet (Code %s). Eingabetaste schliesst das Fenster. ===\033[0m\n' "$code"
    fi
    write_state "$state" "$started" "$(date +%s)" "$code"
    trap - EXIT
    read -r _ || true
    exit "$code"
    ;;
*)
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 2
    ;;
esac
