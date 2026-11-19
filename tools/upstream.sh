#!/usr/bin/env bash
# Alpe – einen neuen Stand des Ursprungsprojekts übernehmen.
#
#   upstream.sh check              neue Versionen des Ursprungsprojekts anzeigen
#   upstream.sh try <stand>        Alpe-Schichten auf <stand> legen und prüfen (z. B. v2.2.0
#                                  oder master). Geschieht in einem eigenen Arbeitsordner;
#                                  die laufende Shell bleibt unberührt.
#   upstream.sh resume <stand>     nach einem gelösten Konflikt die restlichen Schichten und Prüfungen
#   upstream.sh adopt <stand>      einen erfolgreich geprüften Stand übernehmen (Entwicklungsstände
#                                  wie master nur mit --dev, und nur auf diesem Rechner): Zweig alpe
#                                  umstellen, Schichten und BASE im Alpe-Ordner erneuern,
#                                  Shell neu starten (und den eigenen Dienst neu bauen)
#   upstream.sh abandon <stand>    Versuch verwerfen
#   upstream.sh back               nach einer Übernahme zurück auf den Stand davor
#
# Ablauf: check → try → (Fehler beheben, try erneut) → adopt. Bis adopt ist nichts verändert.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHELL_DIR="${ALPE_SHELL_DIR:-$HOME/dux-shell}"
UPSTREAM="${ALPE_UPSTREAM:-https://github.com/duxlabs-dev/dux-shell}"
TRY_ROOT="${ALPE_TRY_ROOT:-$HOME/.cache/alpe/upstream}"
BASE="$(cat "$HERE/BASE")"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/alpe/upstream"

say() { printf '%s\n' "$*"; }
die() { say "FEHLER: $*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
git_s() { git -C "$SHELL_DIR" "$@"; }

slug() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '-'; }
need_ref() { [ -n "${1:-}" ] || die "Welcher Stand? z. B. $0 ${2:-try} v2.2.0  oder  master"; }

fetch_ref() {   # holt <stand> als lokale Referenz alpe-upstream/<stand>, gibt den Commit aus
    local ref="$1" target="refs/alpe-upstream/$(slug "$1")"
    if git_s fetch --quiet --depth 1 --no-tags "$UPSTREAM" "refs/tags/$ref:$target" 2>/dev/null \
        || git_s fetch --quiet --depth 1 --no-tags "$UPSTREAM" "refs/heads/$ref:$target" 2>/dev/null \
        || git_s fetch --quiet --depth 1 --no-tags "$UPSTREAM" "$ref:$target" 2>/dev/null; then
        git_s rev-parse "$target"
    else
        die "Stand «$ref» nicht gefunden bei $UPSTREAM"
    fi
}

RERERE="$HERE/rerere"
rerere_load() {   # gespeicherte Konfliktlösungen bereitstellen; git am nutzt sie von selbst
    git_s config rerere.enabled true
    git_s config rerere.autoUpdate true
    local cache; cache="$(git_s rev-parse --path-format=absolute --git-common-dir)/rr-cache"
    mkdir -p "$cache"
    for entry in "$RERERE"/*/; do
        [ -d "$entry" ] && [ ! -e "$cache/$(basename "$entry")" ] && cp -r "${entry%/}" "$cache"/
    done
    return 0
}
rerere_save() {   # neue Lösungen in den Alpe-Ordner übernehmen
    local cache; cache="$(git_s rev-parse --path-format=absolute --git-common-dir)/rr-cache"
    [ -d "$cache" ] || return 0
    mkdir -p "$RERERE"
    for entry in "$cache"/*/; do
        [ -e "$entry/postimage" ] && mkdir -p "$RERERE/$(basename "$entry")" && cp "$entry/preimage" "$entry/postimage" "$RERERE/$(basename "$entry")/"
    done
    return 0
}

apply_patches() {   # Arbeitsordner Basis-Commit Stand – legt fehlende Schichten auf, 1 bei Konflikt
    local dir="$1" base="$2" ref="$3" applied title
    applied="$(git -C "$dir" log --format=%s "$base"..HEAD)"
    for patch in "$HERE"/shell/*.patch; do
        title="$(git mailinfo /dev/null /dev/null < "$patch" | sed -n 's/^Subject: //p' | head -1)"
        if printf '%s\n' "$applied" | grep -Fxq -- "$title"; then
            say "   schon da: $title"; continue
        fi
        if git -C "$dir" am --quiet -3 "$patch" >/dev/null 2>&1; then
            say "   ok:       $title"
        elif [ -z "$(git -C "$dir" diff --name-only --diff-filter=U)" ] \
            && GIT_EDITOR=true git -C "$dir" am --continue >/dev/null 2>&1; then
            # rerere hat den Konflikt mit einer früher gespeicherten Lösung bereinigt
            say "   gelöst:   $title (gespeicherte Lösung, bitte ansehen)"
        else
            say "   KONFLIKT: $title"
            git -C "$dir" diff --name-only --diff-filter=U | sed 's/^/             /'
            say ""
            say "Diese Schicht passt nicht von selbst auf $ref. Lösen:"
            say "   cd $dir"
            say "   in den genannten Dateien die Stellen zwischen <<<<<<< und >>>>>>> bereinigen"
            say "   git add <dateien> && git am --continue"
            say "   danach: bash $0 resume $ref"
            say "Oder verwerfen: bash $0 abandon $ref"
            return 1
        fi
    done
}

run_tests() {   # Arbeitsordner
    local dir="$1" failed=0
    say "== Prüfungen"
    if have node; then
        if ALPE_SHELL_DIR="$dir" node "$HERE/tests/test_bridge.js" > "$dir/.alpe-test-bridge.log" 2>&1; then
            say "   KWin-Skript: $(tail -1 "$dir/.alpe-test-bridge.log")"
        else say "   KWin-Skript: FEHLER (siehe $dir/.alpe-test-bridge.log)"; failed=1; fi
    else say "   KWin-Skript: übersprungen (node fehlt)"; fi
    for test in test_headset test_brightness; do
        if ALPE_SHELL_DIR="$dir" python3 "$HERE/tests/$test.py" > "$dir/.alpe-$test.log" 2>&1; then
            say "   $test: $(tail -1 "$dir/.alpe-$test.log")"
        else say "   $test: FEHLER (siehe $dir/.alpe-$test.log)"; failed=1; fi
    done
    # QML: jede Datei, die eine Alpe-Schicht berührt, muss sich übersetzen lassen.
    local lint=""
    for candidate in qmllint qmllint6 /usr/lib/qt6/bin/qmllint /usr/lib64/qt6/bin/qmllint pyside6-qmllint; do
        have "$candidate" && { lint="$candidate"; break; }
    done
    if [ -n "$lint" ]; then
        local files errors=0
        files="$(git -C "$dir" diff --name-only "$2"..HEAD -- '*.qml' | sed 's|^|'"$dir"'/|')"
        for file in $files; do
            [ -e "$file" ] || continue
            # Nur Syntax- und Ladefehler zählen; Warnungen zu Typen ausserhalb der Shell sind üblich.
            if "$lint" --max-warnings -1 "$file" 2>&1 | grep -qE '^(Error: |[^ ]+:[0-9]+:[0-9]+: )'; then
                say "   QML-Fehler: ${file#"$dir"/}"; errors=1
            fi
        done
        if [ "$errors" = 0 ]; then say "   QML: $(printf '%s\n' "$files" | grep -c .) geänderte Dateien ohne Syntaxfehler"; else failed=1; fi
    else
        say "   QML: übersprungen (qmllint fehlt; CachyOS: qt6-declarative)"
    fi
    if have go && [ -d "$dir/core" ]; then
        if (cd "$dir/core" && GOTOOLCHAIN="${GOTOOLCHAIN:-auto}" go build -o /dev/null ./cmd/dms) > "$dir/.alpe-go.log" 2>&1; then
            say "   Hintergrunddienst: übersetzt"
        elif grep -q 'go: download go' "$dir/.alpe-go.log"; then
            say "   Hintergrunddienst: übersprungen (passende Go-Version $(sed -n 's/^go: downloading \(go[0-9.]*\).*/\1/p' "$dir/.alpe-go.log" | head -1) nicht ladbar)"
        else say "   Hintergrunddienst: FEHLER beim Übersetzen (siehe $dir/.alpe-go.log)"; failed=1; fi
    fi
    return "$failed"
}

case "${1:-}" in
check)
    say "Alpe beruht auf $BASE. Neuere Stände bei $UPSTREAM:"
    tags="$(git ls-remote --tags --refs "$UPSTREAM" 2>/dev/null | sed 's|.*refs/tags/||' | grep -E '^v[0-9]' | sort -V)"
    newer="$(printf '%s\n' "$tags" | awk -v base="$BASE" 'found {print} $0 == base {found=1}')"
    if [ -n "$newer" ]; then printf '%s\n' "$newer" | sed 's/^/   Version /'; else say "   keine neuere Version"; fi
    head="$(git ls-remote "$UPSTREAM" refs/heads/master 2>/dev/null | cut -c1-8)"
    [ -n "$head" ] && say "   Entwicklungsstand: master ($head) – nur zum Ausprobieren"
    say "Ausprobieren:  bash $0 try <stand>"
    ;;
try)
    need_ref "${2:-}" try
    ref="$2"; name="$(slug "$ref")"; dir="$TRY_ROOT/$name"
    [ -d "$SHELL_DIR/.git" ] || die "$SHELL_DIR ist kein Git-Repository"
    say "== Hole $ref"
    commit="$(fetch_ref "$ref")"
    say "   $commit"
    if [ -d "$dir" ]; then
        git_s worktree remove --force "$dir" 2>/dev/null || rm -rf "$dir"
        git_s worktree prune
    fi
    git_s branch -D "alpe-try-$name" >/dev/null 2>&1 || true
    mkdir -p "$TRY_ROOT"
    git_s worktree add --quiet -b "alpe-try-$name" "$dir" "$commit"
    git -C "$dir" config user.name >/dev/null 2>&1 || git -C "$dir" config user.name "Alpe"
    git -C "$dir" config user.email >/dev/null 2>&1 || git -C "$dir" config user.email "alpe@localhost"
    git -C "$dir" submodule update --quiet --init --depth 1 2>/dev/null || say "   HINWEIS: Baustein dux-qml-common nicht geholt"
    rerere_load
    say "== Schichten auflegen ($dir)"
    apply_patches "$dir" "$commit" "$ref" || exit 1
    if run_tests "$dir" "$commit"; then
        say ""
        say "Alles bestanden. Übernehmen mit:  bash $0 adopt $ref"
        printf '%s\n' "$commit" > "$dir/.alpe-tried"
        rerere_save
    else
        say ""
        say "Mindestens eine Prüfung ist gescheitert; nicht übernehmen, bevor das geklärt ist."
        exit 1
    fi
    ;;
resume)
    # nach einem gelösten Konflikt: restliche Schichten, dann Prüfungen
    need_ref "${2:-}" resume
    ref="$2"; name="$(slug "$ref")"; dir="$TRY_ROOT/$name"
    [ -d "$dir" ] || die "Kein Versuch für $ref"
    commit="$(git_s rev-parse "refs/alpe-upstream/$name")"
    if [ -d "$(git -C "$dir" rev-parse --git-path rebase-apply)" ]; then
        die "Die angehaltene Schicht ist noch offen: in $dir  git add <dateien> && git am --continue"
    fi
    apply_patches "$dir" "$commit" "$ref" || exit 1
    run_tests "$dir" "$commit" && { printf '%s\n' "$commit" > "$dir/.alpe-tried"; rerere_save; say "Übernehmen mit:  bash $0 adopt $ref"; }
    ;;
adopt)
    need_ref "${2:-}" adopt
    ref="$2"; name="$(slug "$ref")"; dir="$TRY_ROOT/$name"
    [ -e "$dir/.alpe-tried" ] || die "Zuerst erfolgreich prüfen: bash $0 try $ref"
    dev=0
    case "$ref" in
        v[0-9]*) ;;
        *) [ "${3:-}" = "--dev" ] || die "$ref ist keine Version. Andere Rechner (bootstrap.sh) könnten diesen Stand nicht nachbauen.
       Nur auf diesem Rechner ausprobieren:  bash $0 adopt $ref --dev
       (Schichten und BASE im Alpe-Ordner bleiben dann beim veröffentlichten Stand $BASE.)"
           dev=1 ;;
    esac
    commit="$(cat "$dir/.alpe-tried")"
    [ -z "$(git_s status --porcelain --untracked-files=no)" ] || die "$SHELL_DIR hat ungesicherte Änderungen – zuerst committen oder verwerfen"
    old="$(git_s rev-parse alpe)"
    stamp="$(date +%Y%m%d-%H%M)"
    git_s branch -f "alpe-vor-$name-$stamp" "$old"
    new="$(git -C "$dir" rev-parse HEAD)"
    say "== Zweig alpe: $(git_s rev-parse --short "$old") → $(git_s rev-parse --short "$new")"
    git_s checkout --quiet alpe
    git_s reset --quiet --hard "$new"
    git_s submodule update --quiet --init --depth 1 2>/dev/null || true
    say "   Sicherung des alten Stands: Zweig alpe-vor-$name-$stamp"
    if [ "$dev" = 1 ]; then
        say "   Entwicklungsstand nur auf diesem Rechner; der Alpe-Ordner bleibt bei $BASE"
    else
        say "== Alpe-Ordner erneuern"
        saved="$STATE/$name-$stamp"; mkdir -p "$saved/shell"
        cp "$HERE"/shell/*.patch "$saved/shell/"; cp "$HERE/BASE" "$saved/"; [ -e "$HERE/BASE.commit" ] && cp "$HERE/BASE.commit" "$saved/"
        tmp="$(mktemp -d)"
        git_s format-patch --quiet --start-number 0 -o "$tmp" "$commit"..alpe
        rm -f "$HERE"/shell/*.patch
        mv "$tmp"/*.patch "$HERE/shell/"
        rmdir "$tmp"
        printf '%s\n' "$ref" > "$HERE/BASE"
        printf '%s\n' "$commit" > "$HERE/BASE.commit"
        say "   $(ls "$HERE"/shell/*.patch | wc -l) Schichten, BASE: $(cat "$HERE/BASE")"
    fi
    git_s worktree remove --force "$dir" 2>/dev/null || true
    git_s branch -D "alpe-try-$name" >/dev/null 2>&1 || true
    if [ -x "$HOME/.local/lib/alpe/alpe" ]; then
        say "== Eigener Hintergrunddienst neu bauen"
        ALPE_SHELL_DIR="$SHELL_DIR" bash "$HERE/tools/backend.sh" build | sed 's/^/   /'
    elif have dms; then
        say "   HINWEIS: Der Dienst aus dem Paket ($(dms version 2>/dev/null | head -1)) passt womöglich nicht mehr;"
        say "            eigener Dienst:  bash $HERE/tools/backend.sh build && bash $HERE/tools/backend.sh use alpe"
    fi
    if systemctl --user is-active --quiet dms.service 2>/dev/null; then
        systemctl --user restart dms.service && say "== Shell neu gestartet"
    fi
    say ""
    [ -d "$HERE/.git" ] && say "Im Alpe-Ordner festhalten:  cd $HERE && git add -A && git commit -m \"Ursprung $ref\""
    say "Zurück, falls etwas nicht stimmt:  bash $0 back"
    ;;
abandon)
    need_ref "${2:-}" abandon
    ref="$2"; name="$(slug "$ref")"; dir="$TRY_ROOT/$name"
    git -C "$dir" am --abort 2>/dev/null || true
    git_s worktree remove --force "$dir" 2>/dev/null || rm -rf "$dir"
    git_s worktree prune
    git_s branch -D "alpe-try-$name" >/dev/null 2>&1 || true
    git_s update-ref -d "refs/alpe-upstream/$name" 2>/dev/null || true
    say "Versuch $ref verworfen"
    ;;
back)
    last="$(git_s for-each-ref --sort=-committerdate --format='%(refname:short)' 'refs/heads/alpe-vor-*' | head -1)"
    [ -n "$last" ] || die "Keine Sicherung gefunden"
    [ -z "$(git_s status --porcelain --untracked-files=no)" ] || die "$SHELL_DIR hat ungesicherte Änderungen"
    git_s checkout --quiet alpe
    git_s reset --quiet --hard "$last"
    say "Zweig alpe zurück auf $last"
    saved="$STATE/${last#alpe-vor-}"
    if [ -d "$saved/shell" ]; then
        rm -f "$HERE"/shell/*.patch; cp "$saved"/shell/*.patch "$HERE/shell/"
        cp "$saved/BASE" "$HERE/BASE"; rm -f "$HERE/BASE.commit"
        [ -e "$saved/BASE.commit" ] && cp "$saved/BASE.commit" "$HERE/BASE.commit"
        say "Alpe-Ordner: $(ls "$HERE"/shell/*.patch | wc -l) Schichten, BASE $(cat "$HERE/BASE")"
    fi
    git_s branch -D "$last" >/dev/null
    if systemctl --user is-active --quiet dms.service 2>/dev/null; then systemctl --user restart dms.service && say "Shell neu gestartet"; fi
    ;;
*)
    sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit 2
    ;;
esac
