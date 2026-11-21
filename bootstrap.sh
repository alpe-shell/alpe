#!/usr/bin/env bash
# Alpe auf einem weiteren Rechner einrichten (Desktop oder Laptop, KWin oder Hyprland).
# Holt den Shell-Code des Ursprungsprojekts im passenden Stand, legt die Alpe-Schichten
# darauf und stellt den Start der Shell auf diesen Code um. Gefahrlos mehrfach ausfuehrbar.
#
#   bash ~/alpe/bootstrap.sh --check          nur pruefen und zeigen, was getan wuerde
#   bash ~/alpe/bootstrap.sh                  einrichten
#   bash ~/alpe/bootstrap.sh --build-backend  den Hintergrunddienst selbst bauen und verwenden
#   bash ~/alpe/bootstrap.sh --force          trotz abweichendem Hintergrunddienst fortfahren
#   bash ~/alpe/bootstrap.sh --undo           Start der Shell wieder auf den alten Stand
#
# Braucht: git, python3, Quickshell und den Hintergrunddienst "dms" des Ursprungsprojekts.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_DIR="${ALPE_SHELL_DIR:-$HOME/dux-shell}"
UPSTREAM="${ALPE_UPSTREAM:-https://github.com/duxlabs-dev/dux-shell}"
BASE="$(cat "$HERE/BASE")"                       # z. B. v2.1.2
WANT="${BASE#v}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
DROPIN="$CONFIG/systemd/user/dms.service.d/alpe.conf"
HYPR_MAIN="$CONFIG/hypr/hyprland.conf"
HYPR_ALPE="$CONFIG/hypr/alpe.conf"

CHECK=0; BUILD=0; FORCE=0; UNDO=0
for arg in "$@"; do
    case "$arg" in
        --check) CHECK=1 ;;
        --build-backend) BUILD=1 ;;
        --force) FORCE=1 ;;
        --undo) UNDO=1 ;;
        *) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
    esac
done

say() { printf '%s\n' "$*"; }
run() { if [ "$CHECK" = 1 ]; then say "   wuerde: $*"; else "$@"; fi; }
have() { PATH="$HOME/.local/bin:$PATH" command -v "$1" >/dev/null 2>&1; }
die() { say "   FEHLER: $*"; exit 1; }

if command -v pacman >/dev/null 2>&1; then PKG="sudo pacman -S --needed"
elif command -v dnf >/dev/null 2>&1; then PKG="sudo dnf install"
else PKG="(Paketverwaltung)"; fi

# ---------------------------------------------------------------- Rueckbau
if [ "$UNDO" = 1 ]; then
    say "== Start der Shell zuruecksetzen"
    if [ -e "$DROPIN" ]; then
        run rm -f "$DROPIN"
        run systemctl --user daemon-reload
        say "   entfernt: $DROPIN"
    fi
    if [ -e "$HYPR_ALPE" ]; then
        run rm -f "$HYPR_ALPE"
        [ -e "$HYPR_MAIN" ] && run sed -i '\|^source = .*/hypr/alpe\.conf$|d' "$HYPR_MAIN"
        say "   entfernt: $HYPR_ALPE und der Verweis darauf"
    fi
    if [ -x "$HOME/.local/lib/alpe/alpe" ]; then
        if [ "$CHECK" = 1 ]; then say "   wuerde: eigenen Hintergrunddienst abmelden"; else bash "$HERE/tools/backend.sh" use system | sed 's/^/   /'; fi
    fi
    say "Fertig. Shell neu starten (dms restart oder systemctl --user restart dms.service)."
    say "Der Shell-Code in $SHELL_DIR bleibt liegen und stoert nicht."
    exit 0
fi

# ---------------------------------------------------------------- Lage
say "== Rechner"
os="unbekannt"; [ -r /etc/os-release ] && os="$(. /etc/os-release && printf '%s' "${PRETTY_NAME:-$ID}")"
model=""
if [ -r /proc/device-tree/model ]; then model="$(tr -d '\000' < /proc/device-tree/model)"
elif [ -r /sys/class/dmi/id/product_name ]; then model="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null) $(cat /sys/class/dmi/id/product_name)"; fi
battery="nein"; for supply in /sys/class/power_supply/*; do [ "$(cat "$supply/type" 2>/dev/null)" = Battery ] && [ "$(cat "$supply/scope" 2>/dev/null)" != Device ] && battery="ja"; done
say "   $os, $(uname -m)${model:+, $model}"
say "   Akku: $battery   Sitzung: ${XDG_CURRENT_DESKTOP:-unbekannt}"
say "   Alpe richtet sich danach zur Laufzeit; es gibt nur eine Ausgabe fuer alle Rechner."

say "== Voraussetzungen"
missing=0
for tool in git python3; do
    have "$tool" && say "   $tool vorhanden" || { say "   FEHLT: $tool  ->  $PKG $tool"; missing=1; }
done
if have qs || have quickshell; then say "   Quickshell vorhanden"; else say "   FEHLT: Quickshell (kommt mit dem Paket des Ursprungsprojekts)"; missing=1; fi

# Ein selbst gebauter Dienst (tools/backend.sh) liegt in ~/.local/lib/alpe und passt immer zum
# Shell-Code, weil er aus demselben Quellbaum entsteht.
OWN="$HOME/.local/lib/alpe/alpe"
version_of() { "$1" version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/^v//'; }
DMS_BIN=""; installed=""
if have dms; then DMS_BIN="$(PATH="$HOME/.local/bin:$PATH" command -v dms)"; installed="$(version_of "$DMS_BIN")"; fi
if [ "$BUILD" = 1 ]; then
    say "   Hintergrunddienst: wird aus dem Shell-Code gebaut (tools/backend.sh), danach verwendet"
    have go || { say "   FEHLT: go  ->  $PKG go (Fedora: golang)"; missing=1; }
    have make || { say "   FEHLT: make  ->  $PKG make"; missing=1; }
    [ -n "$installed" ] || DMS_BIN="$OWN"
elif [ -x "$OWN" ] && [ "$(version_of "$OWN")" = "$WANT" ]; then
    say "   Hintergrunddienst: eigener Bau in $OWN (passt)"
elif [ "$installed" = "$WANT" ]; then
    say "   Hintergrunddienst: $DMS_BIN, Version $installed (passt)"
elif [ -z "$installed" ]; then
    say "   FEHLT: der Hintergrunddienst 'dms'."
    say "          Entweder das Paket des Ursprungsprojekts installieren oder mit --build-backend selbst bauen."
    missing=1
else
    say "   ACHTUNG: dms ist Version $installed, der Shell-Code erwartet $WANT."
    say "            Oberflaeche und Dienst muessen zusammenpassen. Drei Wege:"
    say "            1. das Paket auf $WANT bringen, falls die Paketquelle diesen Stand fuehrt"
    say "            2. bash $0 --build-backend   baut den passenden Dienst selbst (braucht go und make)"
    say "            3. bash $0 --force           trotzdem fortfahren (nur bei kleinem Abstand sinnvoll)"
    [ "$FORCE" = 1 ] || missing=1
fi
[ "$missing" = 0 ] || { say "Abgebrochen: zuerst das Fehlende beheben. Veraendert wurde nichts."; exit 1; }

# ---------------------------------------------------------------- Shell-Code
say "== Shell-Code in $SHELL_DIR"
if [ ! -d "$SHELL_DIR/.git" ]; then
    [ -e "$SHELL_DIR" ] && die "$SHELL_DIR gibt es schon, ist aber kein Git-Repository."
    say "   hole $UPSTREAM im Stand $BASE"
    run git -c advice.detachedHead=false clone --quiet --branch "$BASE" --depth 1 --recurse-submodules --shallow-submodules "$UPSTREAM" "$SHELL_DIR"
    run git -C "$SHELL_DIR" checkout --quiet -b alpe
else
    branch="$(git -C "$SHELL_DIR" rev-parse --abbrev-ref HEAD)"
    if [ "$branch" = alpe ]; then
        say "   vorhanden, Zweig alpe"
    elif [ -z "$(git -C "$SHELL_DIR" status --porcelain --untracked-files=no)" ] && [ "$(git -C "$SHELL_DIR" describe --tags --exact-match 2>/dev/null)" = "$BASE" ]; then
        say "   vorhanden im Stand $BASE; lege den Zweig alpe an"
        run git -C "$SHELL_DIR" checkout --quiet -b alpe
    else
        die "Zweig '$branch' ist weder 'alpe' noch der unveraenderte Stand $BASE. Bitte selbst klaeren."
    fi
fi
if [ "$CHECK" = 0 ]; then
    [ -e "$SHELL_DIR/quickshell/DCommon/Widgets" ] || git -C "$SHELL_DIR" submodule update --quiet --init --depth 1 \
        || die "Der Baustein dux-qml-common fehlt und liess sich nicht holen."
    # 'git am' braucht einen Namen; ohne eigenen bekommt nur dieses Repository einen.
    git -C "$SHELL_DIR" config user.name >/dev/null 2>&1 || git -C "$SHELL_DIR" config user.name "Alpe"
    git -C "$SHELL_DIR" config user.email >/dev/null 2>&1 || git -C "$SHELL_DIR" config user.email "alpe@localhost"
fi

# ---------------------------------------------------------------- Schichten und Plugins
if [ "$CHECK" = 1 ] && [ ! -d "$SHELL_DIR/.git" ]; then
    say "== Alpe-Schichten: $(ls "$HERE"/schichten/*.patch | wc -l) Stueck wuerden eingespielt, dazu die Plugins"
else
    ALPE_SHELL_DIR="$SHELL_DIR" ALPE_NO_RESTART=1 bash "$HERE/install.sh" $([ "$CHECK" = 1 ] && printf -- '--check')
fi

# ---------------------------------------------------------------- Start umstellen
say "== Start der Shell"
UI="$SHELL_DIR/quickshell"
wired=0
unit_exec="$(systemctl --user cat dms.service 2>/dev/null | sed -n 's/^ExecStart=//p' | grep -v '^$' | tail -1 || true)"
# Alpe: Die Umlenkung gilt, sobald es den Dienst gibt – auch wenn er noch aus ist. Unter KDE schaltet
# ihn erst «alpe kde ein» (get.sh Schritt 4) ein; ohne Umlenkung startete dort die unveränderte DMS
# aus /usr/share (eigener Sperrbildschirm, keine Griffleisten).
enabled=0; systemctl --user is-enabled --quiet dms.service 2>/dev/null && enabled=1
if [ -n "$unit_exec" ]; then
    if printf '%s' "$unit_exec" | grep -q -- " -c $UI " && { [ -z "$DMS_BIN" ] || [ "${unit_exec%% *}" = "$DMS_BIN" ]; }; then
        say "   dms.service startet schon mit diesem Code"
    else
        rest="$(printf '%s' "$unit_exec" | sed -E 's/^[^ ]+//; s/ -c [^ ]+//')"
        line="${DMS_BIN:-${unit_exec%% *}} -c $UI${rest:- run --session}"
        say "   dms.service: $line"
        if [ "$CHECK" = 0 ]; then
            mkdir -p "$(dirname "$DROPIN")"
            printf '# Alpe: die Shell aus %s starten. Zurueck: bash %s/bootstrap.sh --undo\n[Service]\nExecStart=\nExecStart=%s\n' "$UI" "$HERE" "$line" > "$DROPIN"
            systemctl --user daemon-reload
        fi
        say "   geschrieben: $DROPIN"
    fi
    # Nicht eingeschaltet: Hyprland startet die Shell womöglich selbst – das regelt der Teil darunter.
    [ "$enabled" = 1 ] && wired=1
    if [ "$CHECK" = 0 ] && { [ "$enabled" = 1 ] || systemctl --user is-active --quiet dms.service 2>/dev/null; }; then
        systemctl --user restart dms.service && say "   Shell neu gestartet"
    fi
fi
if [ "$wired" = 0 ] && [ -e "$HYPR_MAIN" ]; then
    # Hyprland startet die Shell selbst (exec-once). Die Umgebungsvariable lenkt jeden Aufruf
    # von "dms run" auf den Alpe-Code, ohne die bestehende Zeile anzufassen.
    say "   Hyprland: Umgebungsvariable DMS_SHELL_DIR in $HYPR_ALPE"
    if [ "$CHECK" = 0 ]; then
        {
            printf '# Alpe: die Shell aus %s starten. Zurueck: bash %s/bootstrap.sh --undo\n' "$UI" "$HERE"
            printf 'env = DMS_SHELL_DIR,%s\n' "$UI"
        } > "$HYPR_ALPE"
        if ! grep -q 'hypr/alpe\.conf' "$HYPR_MAIN"; then
            [ -e "$HYPR_MAIN.vor-alpe" ] || cp "$HYPR_MAIN" "$HYPR_MAIN.vor-alpe"
            # An den Anfang: Variablen muessen stehen, bevor exec-once die Shell startet.
            sed -i "1i source = $HYPR_ALPE" "$HYPR_MAIN"
            say "   Verweis in $HYPR_MAIN eingetragen (Sicherung: hyprland.conf.vor-alpe)"
        fi
    fi
    starts="$(grep -rnE '\bdms( +-[a-z-]+)* +run' "$CONFIG/hypr" 2>/dev/null | grep -v '\.vor-alpe' || true)"
    if [ -n "$starts" ]; then say "   Gestartet wird die Shell hier:"; printf '%s\n' "$starts" | sed 's/^/      /'
    else say "   HINWEIS: Keine Zeile mit 'dms run' in $CONFIG/hypr gefunden – wie startet die Shell bisher?"; fi
    say "   Wirksam nach dem naechsten Start von Hyprland: einmal ab- und wieder anmelden."
    wired=1
fi
if [ "$wired" = 0 ] && [ -n "$unit_exec" ]; then
    say "   dms.service ist noch aus und startet, sobald er eingeschaltet ist, mit diesem Code"
    say "   (KDE: alpe kde ein – get.sh fragt gleich danach)."
elif [ "$wired" = 0 ]; then
    say "   Weder ein dms.service noch eine Hyprland-Konfiguration gefunden."
    say "   Die Shell startet mit diesem Code so:  ${DMS_BIN:-dms} -c $UI run"
fi

if [ "$BUILD" = 1 ]; then
    say "== Eigener Hintergrunddienst"
    if [ "$CHECK" = 1 ]; then say "   wuerde: tools/backend.sh build und use alpe"
    else
        ALPE_SHELL_DIR="$SHELL_DIR" bash "$HERE/tools/backend.sh" build | sed 's/^/   /'
        ALPE_SHELL_DIR="$SHELL_DIR" bash "$HERE/tools/backend.sh" use alpe | sed 's/^/   /'
    fi
fi

say ""
if [ "$CHECK" = 1 ]; then say "Pruefung beendet, veraendert wurde nichts."; else
    say "Fertig. Unter Einstellungen -> Ueber steht jetzt Alpe; -> System -> Dieses Geraet zeigt, was erkannt wurde."
    say "Zurueck auf den alten Stand:  bash $HERE/bootstrap.sh --undo"
fi
