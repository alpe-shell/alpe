#!/usr/bin/env bash
# Alpe: Prüft, dass gegenüber dem Stand auf GitHub keine grossen Dateien und keine Programme
# (ELF) ins Repository kommen – weder in Commits noch vorgemerkt noch als neue, nicht ignorierte
# Datei (die «git add -A» mitnähme).
#
#   bash tools/neue-dateien-pruefen.sh            vergleicht mit origin/phase-a
#   ALPE_PRUEF_BASIS=origin/main bash tools/…     anderer Vergleichsstand
#   ALPE_PRUEF_MAX=1048576                        Grenze in Bytes (Vorgabe 1 MB)
#
# Ergebnis: 0 = in Ordnung (oder Vergleichsstand fehlt, dann nur Hinweis), 1 = Fund.
set -uo pipefail
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." || exit 1
basis="${ALPE_PRUEF_BASIS:-origin/phase-a}"
max="${ALPE_PRUEF_MAX:-1048576}"

if ! git rev-parse --verify --quiet "$basis^{commit}" >/dev/null; then
    echo "Vergleichsstand $basis fehlt – übersprungen"
    exit 0
fi

funde=0
pruefe() {
    local datei="$1" groesse kopf
    [ -f "$datei" ] && [ ! -L "$datei" ] || return 0
    groesse=$(stat -c %s -- "$datei")
    if [ "$groesse" -gt "$max" ]; then
        echo "FEHLER zu gross ($groesse Bytes > $max): $datei"
        funde=$((funde + 1))
    fi
    kopf=$(head -c 4 -- "$datei" | od -An -tx1 | tr -d ' \n')
    if [ "$kopf" = "7f454c46" ]; then
        echo "FEHLER Programm (ELF): $datei"
        funde=$((funde + 1))
    fi
}

# Hinzugefügt seit dem Vergleichsstand: in Commits und vorgemerkt (Index gegen Basis), dazu
# neue, nicht ignorierte Dateien im Arbeitsbaum.
while IFS= read -r -d '' datei; do pruefe "$datei"; done < <(git diff --cached --name-only --diff-filter=A -z "$basis")
while IFS= read -r -d '' datei; do pruefe "$datei"; done < <(git ls-files --others --exclude-standard -z)

if [ "$funde" -eq 0 ]; then
    echo "ok    keine neuen Dateien über $max Bytes, keine Programme (gegenüber $basis)"
    exit 0
fi
exit 1
