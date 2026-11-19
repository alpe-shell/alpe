#!/usr/bin/env bash
# Alpe – eigener Hintergrunddienst.
#
# Die Shell besteht aus Oberfläche (QML, ~/dux-shell/quickshell) und einem Hintergrunddienst
# (Go, Befehl "dms"). Beide müssen zueinander passen. Statt des Dienstes aus dem Paket des
# Ursprungsprojekts baut dieses Skript ihn aus demselben Quellbaum wie die Oberfläche; danach
# ist Alpe vom Paketstand unabhängig, und eine Paketaktualisierung kann nichts mehr verschieben.
#
#   backend.sh status          was läuft, was gebaut ist
#   backend.sh build           bauen nach ~/.local/lib/alpe/alpe (der vorige Bau bleibt als alpe.prev)
#   backend.sh use alpe        die Shell mit dem eigenen Dienst starten
#   backend.sh use system      zurück zum Dienst aus dem Paket
#   backend.sh rollback        vorigen Bau wiederherstellen
#
# Braucht zum Bauen: go und make (CachyOS: sudo pacman -S --needed go make;
# Fedora: sudo dnf install golang make).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHELL_DIR="${ALPE_SHELL_DIR:-$HOME/dux-shell}"
UI="$SHELL_DIR/quickshell"
LIB="$HOME/.local/lib/alpe"
BIN="$LIB/alpe"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
DROPIN="$CONFIG/systemd/user/dms.service.d/zz-alpe-backend.conf"
LINKDIR="$HOME/.local/bin"

say() { printf '%s\n' "$*"; }
die() { say "FEHLER: $*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

brand_version() { sed -n 's/.*property string version: "\([^"]*\)".*/\1/p' "$UI/Common/Brand.qml" 2>/dev/null | head -1; }
base_version() { cat "$HERE/BASE" 2>/dev/null | sed 's/^v//'; }
version_of() { [ -x "$1" ] && "$1" version 2>/dev/null | head -1; }

uses_systemd() { systemctl --user cat dms.service >/dev/null 2>&1 && systemctl --user is-enabled --quiet dms.service 2>/dev/null; }

case "${1:-}" in
status)
    say "Eigener Dienst:   $( [ -x "$BIN" ] && version_of "$BIN" || echo "nicht gebaut" )  ($BIN)"
    say "Dienst im Paket:  $(version_of /usr/bin/dms || echo "keiner")"
    if [ -e "$DROPIN" ]; then say "dms.service:      startet den eigenen Dienst ($DROPIN)"
    elif uses_systemd; then say "dms.service:      startet den Dienst aus dem Paket"; fi
    if [ -L "$LINKDIR/dms" ] && [ "$(readlink "$LINKDIR/dms")" = "$BIN" ]; then say "Befehl dms:       ~/.local/bin/dms -> eigener Dienst"; fi
    running="$( { pgrep -a -x alpe; pgrep -a -x dms; } 2>/dev/null | grep ' run' | head -1 || true)"
    say "Läuft gerade:     ${running:-nichts gefunden}"
    ;;
build)
    have go || die "go fehlt (CachyOS: sudo pacman -S --needed go; Fedora: sudo dnf install golang)"
    have make || die "make fehlt"
    [ -d "$SHELL_DIR/core" ] || die "$SHELL_DIR/core fehlt – zuerst Alpe einrichten (install.sh oder bootstrap.sh)"
    [ -e "$UI/DCommon/Widgets/DIcon.qml" ] || git -C "$SHELL_DIR" submodule update --init --depth 1
    version="$(base_version)-alpe$(brand_version)"
    say "== Baue den Hintergrunddienst $version"
    say "   Quelle: $SHELL_DIR (Zweig $(git -C "$SHELL_DIR" rev-parse --abbrev-ref HEAD), $(git -C "$SHELL_DIR" rev-parse --short HEAD))"
    # Go lädt bei Bedarf die passende Toolchain und die Module selbst nach (GOTOOLCHAIN=auto).
    GOTOOLCHAIN="${GOTOOLCHAIN:-auto}" make -C "$SHELL_DIR/core" build VERSION="$version" COMMIT="$(git -C "$SHELL_DIR" rev-parse --short=8 HEAD)" >/dev/null \
        || die "Bau gescheitert (Ausgabe oben). Der bisherige Dienst bleibt unverändert."
    built="$SHELL_DIR/core/bin/dms"
    [ -x "$built" ] || die "Kein Ergebnis in $built"
    got="$(version_of "$built")"
    case "$got" in *"$version"*) ;; *) die "Der neue Bau meldet «$got» statt $version – nicht übernommen" ;; esac
    mkdir -p "$LIB"
    [ -x "$BIN" ] && cp -f "$BIN" "$BIN.prev"
    install -m755 "$built" "$BIN.new" && mv -f "$BIN.new" "$BIN"
    # Der Bau legt eine Kopie der Oberfläche in den Quellbaum (von Git ignoriert); weg damit.
    rm -rf "$SHELL_DIR/core/internal/shellembed/dist" "$SHELL_DIR/core/bin"
    say "   gebaut: $BIN ($got)"
    if [ -e "$DROPIN" ] || { [ -L "$LINKDIR/dms" ] && [ "$(readlink "$LINKDIR/dms")" = "$BIN" ]; }; then
        say "   wird bereits verwendet – mit dem nächsten Neustart der Shell aktiv"
    else
        say "   Verwenden mit:  bash $0 use alpe"
    fi
    ;;
use)
    case "${2:-}" in
    alpe)
        [ -x "$BIN" ] || die "Zuerst bauen: bash $0 build"
        if uses_systemd; then
            mkdir -p "$(dirname "$DROPIN")"
            printf '# Alpe: eigener Hintergrunddienst. Zurück: bash %s use system\n[Service]\nExecStart=\nExecStart=%s -c %s run --session\n' "$0" "$BIN" "$UI" > "$DROPIN"
            systemctl --user daemon-reload
            say "dms.service startet jetzt $BIN"
            systemctl --user restart dms.service && say "Shell neu gestartet"
        else
            # Ohne systemd-Dienst (Hyprland startet "dms run"): ~/.local/bin/dms vor den
            # Befehl aus dem Paket stellen. So trifft jeder Aufruf denselben Dienst.
            mkdir -p "$LINKDIR"
            if [ -e "$LINKDIR/dms" ] && [ ! -L "$LINKDIR/dms" ]; then
                mv "$LINKDIR/dms" "$LINKDIR/dms.vor-alpe"
                say "bisheriges ~/.local/bin/dms gesichert als dms.vor-alpe"
            fi
            ln -sfn "$BIN" "$LINKDIR/dms"
            say "~/.local/bin/dms zeigt auf den eigenen Dienst"
            case ":$PATH:" in *":$LINKDIR:"*) ;; *) say "HINWEIS: ~/.local/bin steht nicht im Suchpfad dieser Sitzung" ;; esac
            say "Wirksam nach dem nächsten Start der Shell (ab- und wieder anmelden)."
        fi
        mkdir -p "$LINKDIR"
        ln -sfn "$BIN" "$LINKDIR/alpe"
        ;;
    system)
        if [ -e "$DROPIN" ]; then
            rm -f "$DROPIN"
            systemctl --user daemon-reload
            systemctl --user restart dms.service && say "dms.service startet wieder den Dienst aus dem Paket"
        fi
        if [ -L "$LINKDIR/dms" ] && [ "$(readlink "$LINKDIR/dms")" = "$BIN" ]; then
            rm -f "$LINKDIR/dms"
            [ -e "$LINKDIR/dms.vor-alpe" ] && mv "$LINKDIR/dms.vor-alpe" "$LINKDIR/dms"
            say "~/.local/bin/dms entfernt"
        fi
        if [ -x /usr/bin/dms ]; then mkdir -p "$LINKDIR"; ln -sfn /usr/bin/dms "$LINKDIR/alpe"; fi
        ;;
    *) die "use alpe | use system" ;;
    esac
    ;;
rollback)
    [ -x "$BIN.prev" ] || die "Kein vorheriger Bau vorhanden"
    mv -f "$BIN.prev" "$BIN"
    say "Vorheriger Bau wiederhergestellt: $(version_of "$BIN")"
    uses_systemd && [ -e "$DROPIN" ] && systemctl --user restart dms.service && say "Shell neu gestartet"
    ;;
*)
    sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 2
    ;;
esac
