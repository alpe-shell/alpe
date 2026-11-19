#!/usr/bin/env bash
# Alpe unter KDE Plasma: Plasmas eigene Oberfläche (plasmashell: Leiste, Desktop) durch Alpe ersetzen.
# KWin, die Systemeinstellungen, KRunner und alle KDE-Programme bleiben; nur die Oberfläche wechselt.
#
#   bash tools/kde-sitzung.sh status     zeigt, wer die Oberfläche stellt
#   bash tools/kde-sitzung.sh ein        ab der nächsten Anmeldung Alpe statt plasmashell
#   bash tools/kde-sitzung.sh ein --jetzt  dazu sofort umschalten (ohne Abmelden)
#   bash tools/kde-sitzung.sh aus        zurück zu Plasmas Oberfläche
#
# Technisch: plasma-plasmashell.service wird maskiert (Plasma startet seine Dienste über systemd)
# und dms.service eingeschaltet (gehört zur grafischen Sitzung). «aus» nimmt beides zurück.
set -uo pipefail
SYSTEMCTL="${ALPE_SYSTEMCTL:-systemctl}"
say() { printf '%s\n' "$*"; }
sc() { "$SYSTEMCTL" --user "$@"; }

masked() { [ "$(sc is-enabled plasma-plasmashell.service 2>/dev/null)" = masked ]; }
enabled() { sc is-enabled --quiet dms.service 2>/dev/null; }
systemd_boot() {
    command -v kreadconfig6 >/dev/null 2>&1 || return 0
    [ "$(kreadconfig6 --file startkderc --group General --key systemdBoot 2>/dev/null)" != false ]
}

case "${1:-status}" in
status)
    if masked && enabled; then say "Alpe stellt die Oberfläche (plasmashell abgeschaltet, dms.service an)."
    elif masked; then say "plasmashell ist abgeschaltet, dms.service aber nicht eingeschaltet – nach der Anmeldung fehlt die Oberfläche. Beheben: bash $0 ein"
    elif enabled; then say "dms.service ist an, plasmashell aber auch – beide Oberflächen laufen. Beheben: bash $0 ein"
    else say "Plasma stellt die Oberfläche. Wechseln: bash $0 ein"; fi
    systemd_boot || say "HINWEIS: Plasma startet nicht über systemd (startkderc systemdBoot=false) – das Abschalten von plasmashell wirkt so nicht."
    ;;
ein)
    sc cat dms.service >/dev/null 2>&1 || { say "dms.service fehlt – zuerst DMS installieren (get.sh macht das)."; exit 1; }
    systemd_boot || { say "Plasma startet nicht über systemd (startkderc systemdBoot=false). Bitte zuerst einschalten:"
        say "   kwriteconfig6 --file startkderc --group General --key systemdBoot --delete"; exit 1; }
    sc mask plasma-plasmashell.service >/dev/null 2>&1 && say "plasmashell abgeschaltet (maskiert)"
    sc enable dms.service >/dev/null 2>&1 && say "dms.service eingeschaltet"
    if [ "${2:-}" = "--jetzt" ]; then
        sc stop plasma-plasmashell.service 2>/dev/null
        sc start dms.service && say "Alpe läuft jetzt."
    else
        say "Wirksam ab der nächsten Anmeldung. Zurück: bash $0 aus"
    fi
    ;;
aus)
    sc unmask plasma-plasmashell.service >/dev/null 2>&1 && say "plasmashell wieder zugelassen"
    sc disable dms.service >/dev/null 2>&1 && say "dms.service ausgeschaltet"
    if [ "${2:-}" = "--jetzt" ]; then
        sc stop dms.service 2>/dev/null
        sc start plasma-plasmashell.service && say "Plasma läuft jetzt."
    else
        say "Wirksam ab der nächsten Anmeldung."
    fi
    ;;
*)
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
