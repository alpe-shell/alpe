#!/usr/bin/env bash
# Alpe installieren – ein Befehl:
#
#   curl -fsSL https://raw.githubusercontent.com/alpe-shell/alpe/main/get.sh | bash
#
# Was geschieht (jeder Schritt mit Rückfrage, nichts ohne Zustimmung):
#   1. prüft Rechner und Sitzung (KDE Plasma oder Hyprland; Arch/CachyOS oder Fedora/Asahi)
#   2. installiert DMS (Dux Modular Shell), falls es fehlt – Arch/CachyOS: Paket dux-shell, sonst DMS-Installer
#   3. holt Alpe nach ~/alpe (git) und richtet es ein (bootstrap.sh, install.sh)
#   4. KDE: ersetzt Plasmas Oberfläche durch Alpe (zurück: alpe kde aus)
#   5. spielt das Alpe-Design ein (Leiste, Dock, Dash, Farben, Sperrbildschirm)
#
# Optionen (bei «| bash» so: curl … | bash -s -- --check):
#   --check       nur zeigen, was getan würde
#   --ja          alle Fragen mit der Vorgabe beantworten (ohne Rückfrage)
#   --ohne-design das Design nicht einspielen (eigene Einstellungen bleiben, wie sie sind)
set -euo pipefail

REPO_URL="${ALPE_REPO_URL:-https://github.com/alpe-shell/alpe.git}"
DMS_INSTALLER="${ALPE_DMS_INSTALLER:-https://install.duxlabs.dev}"
DIR="${ALPE_HOME:-$HOME/alpe}"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

CHECK=0; YES=0; DESIGN=1
for arg in "$@"; do
    case "$arg" in
        --check) CHECK=1 ;;
        --ja|--yes|-y) YES=1 ;;
        --ohne-design) DESIGN=0 ;;
        *) sed -n '2,18p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 2 ;;
    esac
done

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
say() { printf '   %s\n' "$*"; }
warn() { printf '   \033[33m!\033[0m %s\n' "$*"; }
die() { printf '\n\033[31mAbgebrochen:\033[0m %s\n' "$*"; exit 1; }
have() { PATH="$HOME/.local/bin:$PATH" command -v "$1" >/dev/null 2>&1; }

# Fragen kommen vom Terminal, auch wenn das Skript über eine Pipe läuft.
ask() {   # ask "Frage" j|n  -> 0 für ja
    local question="$1" default="$2" answer hint
    [ "$default" = j ] && hint="[J/n]" || hint="[j/N]"
    if [ "$YES" = 1 ] || [ "$CHECK" = 1 ] || ! { : </dev/tty; } 2>/dev/null; then
        printf '   %s %s %s\n' "$question" "$hint" "$([ "$default" = j ] && echo ja || echo nein)"
        [ "$default" = j ]; return
    fi
    printf '   %s %s ' "$question" "$hint"
    read -r answer </dev/tty || answer=""
    answer="$(printf '%s' "${answer:-$default}" | tr '[:upper:]' '[:lower:]')"
    case "$answer" in j|ja|y|yes) return 0 ;; *) return 1 ;; esac
}
run() { if [ "$CHECK" = 1 ]; then say "würde: $*"; else "$@"; fi; }
# Paketverwaltungen fragen nach: Eingabe vom Terminal, nie aus der Pipe, in der dieses Skript steckt
run_tty() {
    if [ "$CHECK" = 1 ]; then say "würde: $*"
    elif { : </dev/tty; } 2>/dev/null; then "$@" </dev/tty
    else "$@" </dev/null; fi
}

cat <<'EOF'

           ▲
          ▟█▙         ▲          A L P E
     ▲   ▟███▙       ▟█▙         Desktop-Shell aus der Schweiz
    ▟█▙ ▟█████▙     ▟███▙        für KDE Plasma und Hyprland
   ▟███▟███████▙   ▟█████▙
EOF

# ---------------------------------------------------------------- 1. Rechner
bold "1. Rechner"
[ "$(id -u)" = 0 ] && [ -z "${ALPE_ALLOW_ROOT:-}" ] && die "Bitte als normaler Benutzer ausführen, nicht als root (sudo fragt Alpe selbst)."
ID="" ID_LIKE="" PRETTY_NAME=""
[ -r /etc/os-release ] && . /etc/os-release
family=""
case " ${ID:-} ${ID_LIKE:-} " in
    *" arch "*|*" cachyos "*|*" endeavouros "*|*" manjaro "*) family=arch ;;
    *" fedora "*) family=fedora ;;
esac
desktop="$(printf '%s' "${XDG_CURRENT_DESKTOP:-}" | tr '[:upper:]' '[:lower:]')"
session=""
case "$desktop" in *kde*|*kwin*) session=kde ;; *hyprland*) session=hyprland ;; esac
[ -z "$session" ] && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && session=hyprland
say "${PRETTY_NAME:-unbekanntes System}, $(uname -m), Sitzung: ${XDG_CURRENT_DESKTOP:-unbekannt}"
PKG=(); H5=""; FF=""; GO=(); EXTRA=()
case "$family" in
    arch) PKG=(sudo pacman -S --needed); H5=python-h5py; FF=ffmpeg; GO=(go make); EXTRA=() ;;
    fedora) PKG=(sudo dnf install -y); H5=python3-h5py; FF=ffmpeg-free; GO=(golang make); EXTRA=(slurp) ;;
    *) warn "Alpe ist für Arch/CachyOS und Fedora (auch Asahi) gebaut. Hier fehlen die Paketnamen – Pakete bitte selbst installieren." ;;
esac
case "$session" in
    kde) say "KDE Plasma: Alpe ersetzt Plasmas Oberfläche, KWin und alle KDE-Programme bleiben." ;;
    hyprland) say "Hyprland: Alpe startet als Shell von Hyprland." ;;
    *) warn "Weder KDE Plasma noch Hyprland erkannt. Getestet ist Alpe unter KDE Plasma 6.8 (KWin) und Hyprland."
       ask "Trotzdem weiter?" n || exit 0 ;;
esac
first=1; [ -e "$CONFIG/dms/settings.json" ] && first=0

# Was Alpe selbst installiert, merkt es sich – «alpe entfernen --alles» bietet genau das zum Entfernen an.
LEDGER="$CONFIG/alpe/pakete"
installed_pkg() {
    case "$family" in
        arch) pacman -Q "$1" >/dev/null 2>&1 ;;
        fedora) rpm -q "$1" >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}
remember() {   # remember paket…  (nur die, die es vorher nicht gab)
    [ "$CHECK" = 1 ] && return 0
    mkdir -p "$(dirname "$LEDGER")"
    local p
    for p in "$@"; do
        installed_pkg "$p" && ! grep -qx "$p" "$LEDGER" 2>/dev/null && printf '%s\n' "$p" >> "$LEDGER"
    done
    return 0
}
install_pkgs() {
    [ "${#PKG[@]}" -gt 0 ] || { warn "bitte selbst installieren: $*"; return 1; }
    local p new=()
    for p in "$@"; do installed_pkg "$p" || new+=("$p"); done
    [ "${#new[@]}" -gt 0 ] || return 0
    run_tty "${PKG[@]}" "${new[@]}" && remember "${new[@]}"
}

# ---------------------------------------------------------------- 2. Grundlagen und DMS
bold "2. Grundlagen"
need=()
for tool in git python3 curl; do have "$tool" || need+=("$tool"); done
if [ "${#need[@]}" -gt 0 ]; then
    say "fehlt: ${need[*]}"
    ask "Jetzt installieren?" j && install_pkgs "${need[@]}" || die "${need[*]} wird gebraucht."
else say "git, python3, curl vorhanden"; fi

if have dms && { have qs || have quickshell; }; then
    say "DMS vorhanden ($(dms version 2>/dev/null | head -1 || echo dms))"
elif [ "$family" = arch ]; then
    # Arch/CachyOS: DMS liegt in «extra» und braucht keinen Compositor – genau richtig für KWin.
    # (Der DMS-Installer würde niri/Hyprland/mango samt Konfiguration einrichten.)
    say "Alpe baut auf DMS (Dux Modular Shell) auf: Paket dux-shell (bringt Quickshell mit)"
    if ask "DMS jetzt installieren?" j; then
        install_pkgs dux-shell matugen qt6-multimedia wtype || die "DMS liess sich nicht installieren."
    else
        die "Ohne DMS geht es nicht. Später einfach diesen Befehl wiederholen."
    fi
elif [ "$session" = kde ]; then
    die "Unter KDE bitte DMS (dux-shell) und Quickshell über die Paketquellen installieren – der DMS-Installer richtet einen eigenen Compositor ein. Danach diesen Befehl wiederholen."
else
    say "Alpe baut auf DMS (Dux Modular Shell) auf. Dessen Installer richtet DMS und Quickshell ein:"
    say "   curl -fsSL $DMS_INSTALLER | sh"
    say "Dort «Hyprland» wählen und bestehende Konfigurationen behalten (preserve)."
    if ask "DMS jetzt installieren?" j; then
        if [ "$CHECK" = 1 ]; then say "würde den DMS-Installer ausführen"
        else sh -c "curl -fsSL '$DMS_INSTALLER' | sh" </dev/tty || die "Der DMS-Installer ist nicht durchgelaufen."; fi
    else
        die "Ohne DMS geht es nicht. Später einfach diesen Befehl wiederholen."
    fi
fi

opt=()
if [ -n "$family" ]; then
    python3 -c 'import h5py' 2>/dev/null || opt+=("$H5")
    have ffmpeg || opt+=("$FF")
    for p in "${EXTRA[@]}"; do have "$p" || opt+=("$p"); done
fi
if [ "${#opt[@]}" -gt 0 ]; then
    say "empfohlen: ${opt[*]} (Regenradar, Video-Hintergründe$([ "$family" = fedora ] && echo ', Fenster anklicken'))"
    ask "Mit installieren?" j && install_pkgs "${opt[@]}" || warn "ohne – einzelne Funktionen fehlen dann"
fi

# Terminal und Systeminfo im Alpe-Design (Einstellungen kommen mit dem Design in Schritt 5)
apps=()
have kitty || apps+=(kitty)
have fastfetch || apps+=(fastfetch)
if [ "${#apps[@]}" -gt 0 ] && [ -n "$family" ]; then
    say "Zum Design gehören: ${apps[*]} (Terminal und Systeminfo mit Alpe-Logo)"
    ask "Mit installieren?" j && install_pkgs "${apps[@]}" || warn "ohne – das Design spielt deren Einstellungen trotzdem ein"
fi

# KDE: Unschärfe und runde Ecken. Beide Effekte gibt es nur im AUR (bzw. COPR) und sie müssen
# nach jedem KWin-Update neu gebaut werden – das AUR-Programm erledigt das beim nächsten Update.
if [ "$session" = kde ]; then
    fx=()
    for p in kwin-effects-better-blur-dx kwin-effect-rounded-corners; do installed_pkg "$p" || fx+=("$p"); done
    aur=""
    for helper in paru yay; do have "$helper" && { aur="$helper"; break; }; done
    if [ "${#fx[@]}" -eq 0 ]; then
        say "KWin-Effekte vorhanden (Better Blur DX, abgerundete Ecken)"
    elif [ "$family" = arch ] && [ -n "$aur" ]; then
        say "Für Unschärfe und runde Ecken: ${fx[*]} (AUR, wird mit $aur gebaut, dauert ein paar Minuten)"
        if ask "Mit installieren?" j; then
            run_tty "$aur" -S --needed "${fx[@]}" && remember "${fx[@]}" || warn "Effekte nicht installiert – später: $aur -S ${fx[*]}"
        fi
    elif [ "$family" = arch ]; then
        warn "Für Unschärfe und runde Ecken fehlen ${fx[*]} (AUR) – ohne paru oder yay hier nicht installierbar."
    else
        warn "Für Unschärfe und runde Ecken: Better Blur DX und KDE-Rounded-Corners (Fedora: COPR infinality/kwin-effects-better-blur-dx und matinlotfali/KDE-Rounded-Corners)."
    fi
fi

# ---------------------------------------------------------------- 3. Alpe holen und einrichten
bold "3. Alpe nach ${DIR/#"$HOME"/\~}"
if [ -d "$DIR/.git" ]; then
    say "vorhanden, hole die neuste Fassung"
    run git -C "$DIR" pull --ff-only --quiet || warn "git pull ging nicht (eigene Änderungen?) – nehme den vorhandenen Stand"
elif [ -e "$DIR" ]; then
    [ -f "$DIR/bootstrap.sh" ] || die "$DIR gibt es schon und ist kein Alpe."
    say "vorhanden (ohne git, etwa aus einem Archiv) – nehme diesen Stand"
else
    run git clone --quiet --depth 1 "$REPO_URL" "$DIR"
fi

log="$(mktemp)"
trap 'rm -f "$log"' EXIT
if [ ! -f "$DIR/bootstrap.sh" ]; then
    say "würde: bash $DIR/bootstrap.sh"
else
    boot=(bash "$DIR/bootstrap.sh")
    [ "$CHECK" = 1 ] && boot+=(--check)
    set +e
    "${boot[@]}" 2>&1 | tee "$log" | sed 's/^/   /'
    status="${PIPESTATUS[0]}"
    set -e
    if [ "$status" != 0 ] && [ "$CHECK" = 0 ]; then
        grep -q "erwartet" "$log" || die "Einrichten fehlgeschlagen – Ausgabe oben."
        say "Der installierte DMS-Dienst ist eine andere Version als der Shell-Code von Alpe."
        say "Alpe kann den passenden Dienst selbst bauen (dauert ein paar Minuten, braucht go und make)."
        ask "Dienst bauen?" j || die "Ohne passenden Dienst laufen Oberfläche und Dienst nicht zusammen."
        if ! have go || ! have make; then install_pkgs "${GO[@]}" || die "go und make fehlen."; fi
        set +e
        bash "$DIR/bootstrap.sh" --build-backend 2>&1 | sed 's/^/   /'
        status="${PIPESTATUS[0]}"
        set -e
        [ "$status" = 0 ] || die "Einrichten fehlgeschlagen – Ausgabe oben."
    fi
fi

# ---------------------------------------------------------------- 4. KDE: Oberfläche
if [ "$session" = kde ]; then
    bold "4. Oberfläche von KDE Plasma"
    state=""
    [ -f "$DIR/tools/kde-sitzung.sh" ] && state="$(bash "$DIR/tools/kde-sitzung.sh" status 2>/dev/null | head -1 || true)"
    [ -n "$state" ] && say "$state"
    case "$state" in
        "Alpe stellt"*) ;;
        *) if ask "Plasmas Leiste und Desktop durch Alpe ersetzen? (zurück: alpe kde aus)" j; then
               run bash "$DIR/tools/kde-sitzung.sh" ein --jetzt || warn "Umschalten ging nicht – später: alpe kde ein"
           fi ;;
    esac
fi

# ---------------------------------------------------------------- 5. Design
bold "5. Design"
if [ "$DESIGN" = 0 ]; then
    say "übersprungen (--ohne-design)"
elif ! ls "$DIR"/design/*/manifest.json >/dev/null 2>&1; then
    say "Im Repository liegt kein Design – die Shell startet mit ihren Vorgaben."
else
    variant="${session:-kde}"
    default=j; [ "$first" = 0 ] && default=n
    [ "$first" = 0 ] && say "Es gibt schon Einstellungen der Shell. Das Design ersetzt Leiste, Dock, Dash, Farben und Sperrbildschirm (mit Sicherung)."
    if ask "Alpe-Design einspielen?" "$default"; then
        run python3 "$DIR/tools/design.py" apply --ja --variante "$variant" || warn "Design ging nicht ganz durch – Ausgabe oben"
    else
        say "Später: alpe design apply"
    fi
fi

# ---------------------------------------------------------------- Ende
bold "Fertig"
if [ "$CHECK" = 1 ]; then
    say "Das war ein Probelauf, verändert wurde nichts."
else
    say "Einmal ab- und wieder anmelden, dann läuft Alpe vollständig (Sperre beim Start, Fensterregeln)."
    say "Hilfe: alpe help     Zustand prüfen: alpe doctor     Aktualisieren: alpe update"
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) warn "~/.local/bin fehlt im PATH – der Befehl alpe liegt dort. Einmal eintragen:"
           case "${SHELL##*/}" in
               fish) say "   fish_add_path ~/.local/bin" ;;
               zsh) say "   echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc" ;;
               *) say "   echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc" ;;
           esac ;;
    esac
fi
