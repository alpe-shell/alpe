#!/usr/bin/env bash
# Alpe: Passt ein Versions-Tag zum Stand im Repository? Vor jedem Release (GitHub Actions) und lokal.
#
#   bash tools/release-pruefen.sh v1.1     prüft Tag gegen shell/Common/Brand.qml und den obersten
#                                         Eintrag in CHANGELOG.md
set -uo pipefail
ALPE_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"

tag="${1:-}"
[ -n "$tag" ] || { printf 'Aufruf: %s vX.Y\n' "$0" >&2; exit 2; }
want="${tag#v}"
case "$want" in
    [0-9]*.[0-9]*) ;;
    *) printf 'FEHLER: «%s» ist kein Versions-Tag (erwartet vX.Y oder vX.Y.Z)\n' "$tag"; exit 1 ;;
esac

brand="$(sed -n 's/.*property string version: "\([^"]*\)".*/\1/p' "$ALPE_DIR/shell/Common/Brand.qml" 2>/dev/null | head -1)"
changelog="$(sed -n 's/^## \([0-9][0-9.]*\).*/\1/p' "$ALPE_DIR/CHANGELOG.md" 2>/dev/null | head -1)"

fails=0
if [ "$brand" = "$want" ]; then printf 'ok    Brand.qml: %s\n' "$brand"
else printf 'FEHLER: Brand.qml hat Version «%s», der Tag sagt «%s»\n' "${brand:-?}" "$want"; fails=1; fi
if [ "$changelog" = "$want" ]; then printf 'ok    CHANGELOG.md: oberster Eintrag %s\n' "$changelog"
else printf 'FEHLER: oberster Eintrag in CHANGELOG.md ist «%s», der Tag sagt «%s»\n' "${changelog:-?}" "$want"; fails=1; fi
exit "$fails"
