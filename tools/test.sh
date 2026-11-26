#!/usr/bin/env bash
# Alpe: alle Prüfungen auf einmal – dieselben wie auf GitHub (Actions) vor jedem Push.
#
#   bash tools/test.sh          Tests gegen shell/ und core/ im Repository (Oberfläche anderswo: $ALPE_SHELL_DIR)
#   alpe test                   dasselbe über den Befehl alpe
#
# Seitenladen (QML) läuft nur, wenn PySide6 da ist; Go-Test nur, wenn go da ist.
set -uo pipefail
ALPE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
export ALPE_SHELL_DIR="${ALPE_SHELL_DIR:-$ALPE_DIR/shell}"
cd "$ALPE_DIR" || exit 1
fails=0
step() { printf '\n\033[1m== %s\033[0m\n' "$1"; }
run() { "$@" || { fails=$((fails + 1)); printf '\033[31m✗ fehlgeschlagen:\033[0m %s\n' "$*"; }; }

step "Neue Dateien: nichts über 1 MB, keine Programme (gegenüber origin/phase-a)"
run bash tools/neue-dateien-pruefen.sh

step "KWin-Brücke (node)"
if command -v node >/dev/null; then run node tests/test_bridge.js; else echo "node fehlt – übersprungen"; fi

step "Einstellungen: Migration, Sicherungen aus 1.0 (node)"
if command -v node >/dev/null; then run node --test tests/test_einstellungen.mjs tests/test_logoform.mjs tests/test_sicherungen.mjs; else echo "node fehlt – übersprungen"; fi

step "Oberfläche: alle Node-Tests (bekannte Fehlschläge: tests/data/node-bekannte-fehlschlaege.txt)"
if command -v node >/dev/null; then run python3 tools/node-tests.py; else echo "node fehlt – übersprungen"; fi

for t in tests/test_*.py; do
    step "$t"
    run python3 "$t"
done

step "Namensprüfung (streng seit D7.8: jeder Fund ausserhalb der Ausnahmeliste ist ein Fehler; Plan 2.3.3)"
run bash tools/namen-pruefen.sh --streng

step "Skripte (bash -n)"
run bash -n get.sh install.sh bootstrap.sh tools/*.sh tools/alpe
run python3 tools/hyprlock2qml.py lockscreen/hyprlock.conf --json >/dev/null

step "Einstellungsseiten laden (QML)"
if python3 -c 'import PySide6' 2>/dev/null; then
    run env QT_QPA_PLATFORM=offscreen python3 entwicklung/pageharness/loadall.py
    # Alpe: Kürzelseite mit 400 Aktionen – nur sichtbare Zeilen, Suche ohne Hänger
    run bash -c 'out=$(python3 entwicklung/pageharness/kuerzel_last.py 2>&1); echo "$out"; ! grep -q "Fehler:" <<<"$out"'
else
    echo "PySide6 fehlt – übersprungen (pip install PySide6)"
fi

step "Sport-Tab laden (QML, Musterdaten)"
if python3 -c 'import PySide6' 2>/dev/null; then
    # Musterdaten in einem Temp-Ordner neu erzeugen; die eingecheckten bleiben unverändert.
    fixtures="$(mktemp -d)"
    before="$(cd entwicklung/sportharness/fixtures && find . -type f -not -path './cache/*' -print0 | sort -z | xargs -0 sha256sum | sha256sum)"
    cp -r entwicklung/sportharness/fixtures/. "$fixtures/"
    rm -rf "$fixtures/cache"
    export ALPE_SPORT_FIXTURES="$fixtures"
    python3 -c 'import PIL' 2>/dev/null && python3 entwicklung/sportharness/make_fixtures.py >/dev/null
    for scene in tab_wide tab_table tab_detail_narrow tab_hockey tab_nba card rail_closes_detail tab_nati query_supersede table_link league_stats nl_stats player_from_detail stream_chip bar_widget tab_grows; do
        run env QT_QPA_PLATFORM=offscreen SHOT_DELAY=1200 python3 entwicklung/sportharness/shot.py "entwicklung/sportharness/scenes/$scene.qml"
    done
    unset ALPE_SPORT_FIXTURES
    rm -rf "$fixtures"
    after="$(cd entwicklung/sportharness/fixtures && find . -type f -not -path './cache/*' -print0 | sort -z | xargs -0 sha256sum | sha256sum)"
    run test "$before" = "$after"   # eingecheckte Musterdaten unverändert
else
    echo "PySide6 fehlt – übersprungen (pip install PySide6)"
fi

step "Plugin claudeCodeUsage (eigene Tests; Temp-HOME, curl als Attrappe)"
for t in plugins/claudeCodeUsage/tests/test-*.sh; do
    run bash "$t" >/dev/null
done

step "Hintergrunddienst (go test)"
if [ -n "${ALPE_SKIP_GO:-}" ]; then
    echo "ALPE_SKIP_GO gesetzt – übersprungen"
elif command -v go >/dev/null && [ -d "$ALPE_DIR/core" ]; then
    run bash -c 'cd "$1" && go test ./internal/server -run TestReadAlpeOff -count=1' _ "$ALPE_DIR/core"
else
    echo "go oder $ALPE_DIR/core fehlt – übersprungen"
fi

# Plan 0.8 Nr. 136: PAM-Dienste und Richtlinie des Dienstes (sicherheitsrelevant) bei jedem Lauf, abgeschottet – eigenes
# HOME und alle XDG-Ordner in einem Temp-Ordner, ohne Session-Bus und Display; die Go-Caches werden vor dem Wechsel von
# HOME festgehalten (CLAUDE.md, Plan 0.8 Nr. 40).
step "Dienst: PAM und Richtlinie (go test -count=1 ./internal/pam ./internal/clipolicy, abgeschottet)"
if [ -n "${ALPE_SKIP_GO:-}" ]; then
    echo "ALPE_SKIP_GO gesetzt – übersprungen"
elif command -v go >/dev/null && [ -d "$ALPE_DIR/core" ]; then
    go_heim="$(mktemp -d)"
    mkdir -p "$go_heim/.config" "$go_heim/.local/share" "$go_heim/.local/state" "$go_heim/.cache" "$go_heim/run"
    chmod 700 "$go_heim/run"
    run env -u DBUS_SESSION_BUS_ADDRESS -u WAYLAND_DISPLAY -u DISPLAY \
        GOMODCACHE="$(go env GOMODCACHE)" GOCACHE="$(go env GOCACHE)" GOPATH="$(go env GOPATH)" \
        HOME="$go_heim" XDG_CONFIG_HOME="$go_heim/.config" XDG_DATA_HOME="$go_heim/.local/share" \
        XDG_STATE_HOME="$go_heim/.local/state" XDG_CACHE_HOME="$go_heim/.cache" XDG_RUNTIME_DIR="$go_heim/run" \
        bash -c 'cd "$1" && go test -count=1 ./internal/pam ./internal/clipolicy' _ "$ALPE_DIR/core"
    rm -rf "$go_heim"
else
    echo "go oder $ALPE_DIR/core fehlt – übersprungen"
fi

echo
if [ "$fails" = 0 ]; then printf '\033[32malles grün\033[0m\n'; else printf '\033[31m%d Prüfung(en) fehlgeschlagen\033[0m\n' "$fails"; fi
exit $((fails > 0))
