#!/usr/bin/env bash
# Alpe einspielen: Plugins kopieren, Sperrbildschirm, Namen, Titelleisten, Befehl alpe; Shell neu starten.
# Gefahrlos mehrfach ausfuehrbar. Braucht kein sudo.
#
#   bash ~/alpe/install.sh            alles
#   bash ~/alpe/install.sh --check    nur zeigen, was getan wuerde
#
# Auf einem neuen Rechner zuerst:  bash ~/alpe/bootstrap.sh   (stellt den Start der Shell um, ruft dann dies)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_DIR="${ALPE_SHELL_DIR:-$HERE/shell}"
PLUGIN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dms/plugins"
CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

say() { printf '%s\n' "$*"; }
run() { if [ "$CHECK" = 1 ]; then say "   wuerde: $*"; else "$@"; fi; }

say "== Plugins nach $PLUGIN_DIR"
run mkdir -p "$PLUGIN_DIR"
for plugin in "$HERE"/plugins/*/; do
    name="$(basename "$plugin")"
    run rm -rf "$PLUGIN_DIR/$name"
    run cp -r "$plugin" "$PLUGIN_DIR/$name"
    say "   $name"
done

say "== Plugins einschalten"
if [ "$CHECK" = 1 ]; then python3 "$HERE/tools/activate-plugins.py" --check; else python3 "$HERE/tools/activate-plugins.py"; fi

# Der Shell-Code liegt im Alpe-Ordner selbst (shell/); er wird nicht mehr aus Schichten gebaut.
[ -f "$SHELL_DIR/shell.qml" ] || { say "   FEHLER: $SHELL_DIR/shell.qml fehlt – der Alpe-Ordner ist unvollständig."; exit 1; }
pending=0

# Das KDE-Design braucht die Ansicht aus dem Shell-Code (Modules/Lock/Alpe).
case "${XDG_CURRENT_DESKTOP:-}" in
    *KDE*|*kwin*|*KWIN*)
        say "== Sperrbildschirm (KDE)"
        if [ "$CHECK" = 1 ]; then bash "$HERE/tools/lockscreen.sh" status | sed 's/^/   /'
        else ALPE_SHELL_DIR="$SHELL_DIR" bash "$HERE/tools/lockscreen.sh" install; fi ;;
esac

# Alpe: Prozessanzeigen (auch die eigene Prozessliste der Shell) nehmen den Namen aus dem
# Desktop-Eintrag der App-ID dev.duxlabs.shell; der aus dem Paket heisst «Dux Modular Shell».
# Ein eigener Eintrag unter ~/.local/share/applications hat Vorrang. Dazu ein Zusatz für den
# Dienst: Beschreibung «Alpe» und MALLOC_ARENA_MAX=2 – glibc legt sonst bis zu acht Speicher-
# Arenen pro Kern an; die Shell hat je Fenster einen eigenen Zeichen-Thread, das bläht RSS auf.
# Programme, die man aus der Shell startet, bekommen die Begrenzung nicht (SessionService).
say "== Name «Alpe» und Speicher-Arenen"
APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/dms.service.d"
if [ "$CHECK" = 1 ]; then
    say "   wuerde: $APPS_DIR/dev.duxlabs.shell.desktop (Name=Alpe), $UNIT_DIR/zz-alpe-name.conf"
else
    mkdir -p "$APPS_DIR" "$UNIT_DIR"
    cat > "$APPS_DIR/dev.duxlabs.shell.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Alpe
GenericName=Desktop-Shell
Comment=Alpe – Shell auf Basis von Dux Modular Shell
Exec=dms run
Icon=dev.duxlabs.shell
Terminal=false
NoDisplay=true
StartupNotify=false
Categories=Utility;
DESKTOP
    cat > "$UNIT_DIR/zz-alpe-name.conf" <<'UNIT'
# Alpe (install.sh): Name in systemctl und Prozessanzeigen, begrenzte Speicher-Arenen
[Unit]
Description=Alpe (Shell)

[Service]
Environment=MALLOC_ARENA_MAX=2 ALPE_SHELL_ARENA=1
UNIT
    systemctl --user daemon-reload 2>/dev/null || true
    say "   Prozessname «Alpe», Speicher-Arenen begrenzt (wirkt nach dem Neustart der Shell)"
fi

# Alpe: fastfetch mit Bergkette und Version aus Brand.qml, nur wenn fastfetch eingerichtet ist
if [ -e "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/config.jsonc" ] || [ -e "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/config.json" ]; then
    say "== fastfetch"
    if [ "$CHECK" = 1 ]; then python3 "$HERE/tools/fastfetch.py" --check; else python3 "$HERE/tools/fastfetch.py" || true; fi
fi

# Alpe: Proton VPN mit schlanker Kopfleiste – einmalig; «alpe kopfleiste aus» bleibt aus
MARK="${XDG_CONFIG_HOME:-$HOME/.config}/alpe/kopfleiste-eingerichtet"
if command -v protonvpn-app >/dev/null 2>&1 && [ ! -e "$MARK" ]; then
    say "== Proton VPN"
    if [ "$CHECK" = 1 ]; then say "   wuerde: Kopfleiste schlank (alpe kopfleiste)"
    else python3 "$HERE/tools/kopfleiste.py" schlank | sed 's/^/   /' && mkdir -p "$(dirname "$MARK")" && touch "$MARK"; fi
fi

# Alpe: Fenster ohne Titelleiste als KWin-Regel (einmalig; «alpe titelleisten an» bleibt an).
# Wer die Titelleisten behalten will: «alpe titelleisten an» nach dem Einspielen.
# Hängt eine verwaiste eigene Regel wieder ein, sonst legt es «Alpe: ohne Titelleiste» an.
case "${XDG_CURRENT_DESKTOP:-}" in
    *KDE*|*kwin*|*KWIN*)
        # Alpe: KWin ab 6.8 löscht beim Lesen jede Fensterregel, die nicht in einer alten Liste
        # «rules» steht. Zuerst die Datei ins neue Format bringen (Order), dann die Regel anlegen.
        MARK="${XDG_CONFIG_HOME:-$HOME/.config}/alpe/titelleisten-eingerichtet-2"
        say "== Titelleisten (KWin)"
        if [ "$CHECK" = 1 ]; then say "   wuerde: kwinrulesrc ins Format von KWin 6.8 bringen (alpe-kwin.py migrate)"
        else python3 -I "$SHELL_DIR/scripts/alpe-kwin.py" migrate | python3 -I -c '
import json, sys
d = json.load(sys.stdin)
print("   KWin %s: Fensterregeln %s" % (d.get("kwin") or "?", "ins neue Format gebracht (Order statt rules)" if d.get("migrated") else "im passenden Format"))'
        fi
        if [ "$CHECK" = 1 ]; then ALPE_SHELL_DIR="$SHELL_DIR" python3 "$HERE/tools/titelleisten.py" status | sed 's/^/   /'
        elif [ ! -e "$MARK" ]; then
            ALPE_SHELL_DIR="$SHELL_DIR" python3 "$HERE/tools/titelleisten.py" aus | sed 's/^/   /' && mkdir -p "$(dirname "$MARK")" && touch "$MARK"
        else ALPE_SHELL_DIR="$SHELL_DIR" python3 "$HERE/tools/titelleisten.py" status | sed 's/^/   /'; fi ;;
esac

say "== Befehl 'alpe'"
# Ab 1.7 ein kleines Skript (tools/alpe): eigene Befehle wie «alpe doctor», alles andere geht an
# den Hintergrunddienst (eigener Bau oder dms aus dem Paket) wie bisher.
if [ "$CHECK" = 1 ]; then
    say "   wuerde: ~/.local/bin/alpe -> $HERE/tools/alpe"
else
    mkdir -p "$HOME/.local/bin"
    [ -L "$HOME/.local/bin/alpe" ] || [ ! -e "$HOME/.local/bin/alpe" ] || mv "$HOME/.local/bin/alpe" "$HOME/.local/bin/alpe.vorher"
    ln -sfn "$HERE/tools/alpe" "$HOME/.local/bin/alpe"
    say "   ~/.local/bin/alpe -> $HERE/tools/alpe   (alpe help)"
fi

say "== Voraussetzungen"
if command -v pacman >/dev/null 2>&1; then PKG="sudo pacman -S --needed"; H5=python-h5py; AUR="paru -S"
elif command -v dnf >/dev/null 2>&1; then PKG="sudo dnf install"; H5=python3-h5py; AUR=""
else PKG="(Paketverwaltung)"; H5=h5py; AUR=""; fi
python3 -c "import h5py" 2>/dev/null && say "   h5py vorhanden (Radar)" || say "   FEHLT: h5py fuer Python (Radar)  ->  $PKG $H5"
have() { PATH="$HOME/.local/bin:$PATH" command -v "$1" >/dev/null 2>&1; }
have ffmpeg && say "   ffmpeg vorhanden (Standbild eines Video-Hintergrunds)" || say "   EMPFOHLEN: ffmpeg fuer Video-Hintergruende auf dem Sperrbildschirm  ->  $PKG ffmpeg"
have update-all && say "   update-all gefunden (Systemaktualisierung)" || say "   HINWEIS: update-all nicht gefunden; die Aktualisierung laeuft dann ueber den Dienst wie bisher"
if have headsetcontrol || have hyper_headset_cli; then
    say "   Headset-Werkzeug vorhanden: $(have headsetcontrol && printf 'headsetcontrol '; have hyper_headset_cli && printf 'hyper_headset_cli')"
else
    [ -n "$AUR" ] && say "   OPTIONAL: Akkustand eines Funk-Headsets  ->  $AUR headsetcontrol   (HyperX: $AUR hyper-headset-git)"
fi
case "${XDG_CURRENT_DESKTOP:-}" in
    *KDE*|*kwin*|*KWIN*)
        for tool in kscreen-doctor kreadconfig6 kwriteconfig6 kcmshell6; do
            have "$tool" || say "   FEHLT: $tool (KWin-Seiten der Einstellungen)"
        done ;;
esac
if command -v pacman >/dev/null 2>&1 && pacman -Qq dux-shell >/dev/null 2>&1; then
    if grep -Eq '^[[:space:]]*IgnorePkg[[:space:]]*=.*\bdux-shell\b' /etc/pacman.conf 2>/dev/null; then
        say "   dux-shell ist von Updates ausgenommen"
    else
        say "   EMPFOHLEN: dux-shell von Updates ausnehmen (siehe README, Abschnitt Unterbau)"
    fi
fi

case "${XDG_CURRENT_DESKTOP:-}" in
    *Hyprland*|*hyprland*)
        if command -v hyprlock >/dev/null 2>&1; then
            say "   hyprlock vorhanden: gestalten unter Einstellungen -> Sicherheit -> Sperrbildschirm gestalten"
        fi
        have slurp && say "   slurp vorhanden (Fensterregeln: Fenster anklicken)" || say "   EMPFOHLEN: slurp, damit «Fenster anklicken» in den Fensterregeln per Klick waehlt  ->  $PKG slurp" ;;
esac

if [ "$CHECK" = 0 ] && [ "${ALPE_NO_RESTART:-0}" != 1 ]; then
    if systemctl --user is-active --quiet dms.service 2>/dev/null; then
        say "== Shell neu starten"
        systemctl --user restart dms.service
    elif [ "$pending" = 1 ]; then
        say "== Shell neu starten:  dms restart"
    fi
fi
say "Fertig."
