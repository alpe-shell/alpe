#!/usr/bin/env bash
# Alpe: tools/test.sh auf genau einem Commit – oder auf mehreren nacheinander (Sammellauf).
#
#   bash tools/test-commit.sh HASH [HASH …]    je Commit: Temp-Worktree, eigenes HOME/XDG, tools/test.sh, Protokoll
#   bash tools/test-commit.sh --gruen HASH     0, wenn für diesen Commit ein grünes Protokoll vorliegt, sonst 1
#
# HASH ist immer der volle Hash (40 Hex-Zeichen). Symbolische Namen (HEAD, Branch, Tag) und gekürzte Hashes werden
# abgelehnt: Sie zeigen beim Start eines Sammellaufs nicht mehr sicher auf den gemeinten Commit (am 24.11.2026 prüfte
# ein Sammellauf mit «HEAD» den falschen). Geprüft wird der Commit selbst, nicht der Arbeitsbaum (Plan 0.8 Nr. 72).
#
# Protokolle: $ALPE_TEST_PROTOKOLLE (sonst ${TMPDIR:-/tmp}/alpe-test-protokolle), je Commit test-<voller Hash>.log.
# Die erste und die letzte Zeile nennen den geprüften Hash, die letzte den Rückgabewert von tools/test.sh.
# Vor der Haltprüfung: «--gruen <voller Hash der Spitze>» muss 0 liefern (CLAUDE.md, «Prüfen vor jedem Commit»).
# Ergebnis: 0 = alle grün, 1 = mindestens einer rot (bzw. kein grünes Protokoll), 2 = Aufruffehler.
set -uo pipefail
ALPE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
protokolle="${ALPE_TEST_PROTOKOLLE:-${TMPDIR:-/tmp}/alpe-test-protokolle}"

aufruf() {
    echo "Aufruf: bash tools/test-commit.sh HASH [HASH …]   oder   bash tools/test-commit.sh --gruen HASH" >&2
    echo "        HASH = voller Hash, 40 Hex-Zeichen (git rev-parse HEAD); HEAD, Branch-Namen und gekürzte Hashes gelten nicht" >&2
    exit 2
}

voller_hash() {
    [[ "$1" =~ ^[0-9a-f]{40}$ ]] && return 0
    echo "FEHLER: «$1» ist kein voller Hash (40 Hex-Zeichen). Symbolische Namen wie HEAD und gekürzte Hashes werden abgelehnt." >&2
    return 1
}

# Liegt für den Commit ein grünes Protokoll vor? Name, erste und letzte Zeile müssen denselben vollen Hash nennen.
gruen() {
    local hash="$1" log="$protokolle/test-$1.log" kopf schluss
    if [ ! -f "$log" ]; then
        echo "kein Protokoll von tools/test.sh für $hash ($log)"
        return 1
    fi
    kopf="$(head -n 1 "$log")"
    schluss="$(tail -n 1 "$log")"
    if [[ "$kopf" != "### tools/test.sh auf Commit $hash, "* ]]; then
        echo "Protokoll $log nennt in der ersten Zeile nicht den Commit $hash"
        return 1
    fi
    if [[ "$schluss" != "### Ende "*", Commit $hash, Rückgabewert 0" ]]; then
        echo "Protokoll $log ist nicht grün oder unvollständig: $schluss"
        return 1
    fi
    echo "grünes Protokoll für $hash: $log"
    return 0
}

[ $# -ge 1 ] || aufruf
if [ "$1" = "--gruen" ]; then
    [ $# -eq 2 ] || aufruf
    voller_hash "$2" || exit 2
    gruen "$2"
    exit $?
fi

# Erst alle Angaben prüfen, dann laufen: Ein Sammellauf mit einer falschen Angabe startet gar nicht.
for hash in "$@"; do
    voller_hash "$hash" || exit 2
    if ! git -C "$ALPE_DIR" cat-file -e "$hash^{commit}" 2>/dev/null; then
        echo "FEHLER: Im Repository gibt es keinen Commit $hash." >&2
        exit 2
    fi
done

# Go-Caches festhalten, bevor HOME wechselt (CLAUDE.md, «Das laufende System»).
go_umgebung=()
if command -v go >/dev/null; then
    go_umgebung=("GOMODCACHE=$(go env GOMODCACHE)" "GOCACHE=$(go env GOCACHE)" "GOPATH=$(go env GOPATH)")
fi
mkdir -p "$protokolle" || exit 2
rot=0
for hash in "$@"; do
    arbeit="$(mktemp -d "${TMPDIR:-/tmp}/alpe-test-commit.XXXXXX")" || exit 2
    baum="$arbeit/baum" heim="$arbeit/heim" log="$protokolle/test-$hash.log"
    if ! git -C "$ALPE_DIR" worktree add --detach "$baum" "$hash" >/dev/null 2>&1; then
        echo "FEHLER: Temp-Worktree für $hash liess sich nicht anlegen." >&2
        rm -rf "$arbeit"
        exit 2
    fi
    ist="$(git -C "$baum" rev-parse HEAD)"
    if [ "$ist" != "$hash" ]; then
        echo "FEHLER: Der Temp-Worktree steht auf $ist statt auf $hash." >&2
        git -C "$ALPE_DIR" worktree remove --force "$baum" >/dev/null 2>&1
        rm -rf "$arbeit"
        exit 2
    fi
    mkdir -p "$heim/.config" "$heim/.local/share" "$heim/.local/state" "$heim/.cache" "$heim/run"
    chmod 700 "$heim/run"
    echo "### tools/test.sh auf Commit $hash, Temp-Worktree $baum, Beginn $(date '+%F %T')" >"$log"
    env -u DBUS_SESSION_BUS_ADDRESS -u WAYLAND_DISPLAY -u DISPLAY -u ALPE_SHELL_DIR \
        HOME="$heim" XDG_CONFIG_HOME="$heim/.config" XDG_DATA_HOME="$heim/.local/share" XDG_STATE_HOME="$heim/.local/state" \
        XDG_CACHE_HOME="$heim/.cache" XDG_RUNTIME_DIR="$heim/run" "${go_umgebung[@]}" \
        bash "$baum/tools/test.sh" >>"$log" 2>&1
    rc=$?
    echo "### Ende $(date '+%F %T'), Commit $hash, Rückgabewert $rc" >>"$log"
    git -C "$ALPE_DIR" worktree remove --force "$baum" >/dev/null 2>&1
    rm -rf "$arbeit"
    if [ "$rc" = 0 ]; then
        echo "tools/test.sh auf $hash: grün (Rückgabewert 0), Protokoll $log"
    else
        echo "tools/test.sh auf $hash: ROT (Rückgabewert $rc), Protokoll $log"
        rot=1
    fi
done
exit "$rot"
