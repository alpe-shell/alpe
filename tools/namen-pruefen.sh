#!/usr/bin/env bash
# Alpe: Namensprüfung, siehe tools/namen-pruefen.py (Plan 9, 2.3.3).
exec python3 "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/namen-pruefen.py" "$@"
