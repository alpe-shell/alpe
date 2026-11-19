#!/bin/sh
# Alpe – die wenigen Dinge, die Root brauchen. Aufruf über pkexec aus den Einstellungen
# («Dieses Gerät»); jede Eingabe wird streng geprüft.
#
#   alpe-root.sh charge PROZENT              Ladegrenze setzen und beim Start wiederherstellen
#                                            (100 nimmt die Grenze und den Startdienst weg)
#   alpe-root.sh lid AKKU NETZ ANGEDOCKT     Verhalten beim Zuklappen (logind)
#                                            Werte: suspend lock ignore poweroff hibernate
#
# Für Tests: ALPE_ROOT_PREFIX setzt ein Verzeichnis vor /etc und /sys.
set -eu
P="${ALPE_ROOT_PREFIX:-}"

batteries() {
    for bat in "$P"/sys/class/power_supply/*; do
        [ "$(cat "$bat/type" 2>/dev/null)" = Battery ] && printf '%s\n' "$bat"
    done
}

case "${1:-}" in
charge)
    value="${2:-}"
    case "$value" in ''|*[!0-9]*) echo "ungültig: $value" >&2; exit 2 ;; esac
    [ "$value" -ge 50 ] && [ "$value" -le 100 ] || { echo "erlaubt: 50–100" >&2; exit 2; }
    found=0
    for bat in $(batteries); do
        if [ -w "$bat/charge_control_end_threshold" ] || [ -n "$P" ]; then
            echo "$value" > "$bat/charge_control_end_threshold" && found=1
        fi
    done
    [ "$found" = 1 ] || { echo "kein Akku mit charge_control_end_threshold" >&2; exit 3; }
    unit="$P/etc/systemd/system/alpe-ladegrenze.service"
    if [ "$value" -ge 100 ]; then
        rm -f "$P/etc/alpe/ladegrenze"
        [ -n "$P" ] || systemctl disable --now alpe-ladegrenze.service >/dev/null 2>&1 || true
        rm -f "$unit"
    else
        mkdir -p "$P/etc/alpe" "$(dirname "$unit")"
        echo "$value" > "$P/etc/alpe/ladegrenze"
        cat > "$unit" <<UNIT
[Unit]
Description=Alpe: Ladegrenze des Akkus wiederherstellen
After=sysinit.target

[Service]
Type=oneshot
# systemd ersetzt \$NAME selbst; für die Shell steht deshalb \$\$.
ExecStart=/bin/sh -c 'v=\$\$(cat /etc/alpe/ladegrenze); for b in /sys/class/power_supply/*; do [ "\$\$(cat \$\$b/type 2>/dev/null)" = Battery ] && [ -w \$\$b/charge_control_end_threshold ] && echo \$\$v > \$\$b/charge_control_end_threshold; done; true'

[Install]
WantedBy=multi-user.target
UNIT
        [ -n "$P" ] || { systemctl daemon-reload; systemctl enable alpe-ladegrenze.service >/dev/null 2>&1; }
    fi
    echo "ok"
    ;;
lid)
    for v in "${2:-}" "${3:-}" "${4:-}"; do
        case "$v" in suspend|lock|ignore|poweroff|hibernate) ;; *) echo "ungültig: $v" >&2; exit 2 ;; esac
    done
    dir="$P/etc/systemd/logind.conf.d"
    mkdir -p "$dir"
    cat > "$dir/60-alpe-deckel.conf" <<CONF
# Alpe: Verhalten beim Zuklappen (Einstellungen → Dieses Gerät)
[Login]
HandleLidSwitch=$2
HandleLidSwitchExternalPower=$3
HandleLidSwitchDocked=$4
CONF
    # logind liest seine Einstellungen bei SIGHUP neu (systemd ≥ 254).
    [ -n "$P" ] || systemctl kill -s HUP systemd-logind.service >/dev/null 2>&1 || true
    echo "ok"
    ;;
*)
    sed -n '2,12p' "$0" >&2; exit 2 ;;
esac
