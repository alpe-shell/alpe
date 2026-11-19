#!/usr/bin/env bash
# lint.sh <Datei relativ zu quickshell> ...  : zeigt nur Warnungen, die es im Stand HEAD~N (Basis) nicht gab
set -u
REPO=/home/claude/src/dux-shell
BASE="${LINT_BASE:-5e390f6}"
python3 /home/claude/tools/mklint.py "$REPO/quickshell" >/dev/null
rm -rf /tmp/lintbase && mkdir -p /tmp/lintbase
for f in "$@"; do
    new=$(cd /tmp/lint && pyside6-qmllint -I /tmp/lint "qs/$f" 2>&1 | grep "^Warning" | sed -E 's/:[0-9]+:[0-9]+:/:/' | sort)
    if git -C "$REPO" cat-file -e "$BASE:quickshell/$f" 2>/dev/null; then
        cp "/tmp/lint/qs/$f" /tmp/lintbase/cur.qml
        git -C "$REPO" show "$BASE:quickshell/$f" > "/tmp/lint/qs/$f"
        old=$(cd /tmp/lint && pyside6-qmllint -I /tmp/lint "qs/$f" 2>&1 | grep "^Warning" | sed -E 's/:[0-9]+:[0-9]+:/:/' | sort)
        cp /tmp/lintbase/cur.qml "/tmp/lint/qs/$f"
    else
        old=""
    fi
    added=$(comm -13 <(printf '%s\n' "$old") <(printf '%s\n' "$new") | grep -v '^$')
    n=$(printf '%s' "$added" | grep -c . )
    echo "== $f: $n neue Warnung(en)"
    [ "$n" -gt 0 ] && printf '%s\n' "$added" | sed 's/^/   /'
done
