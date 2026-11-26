#!/usr/bin/env python3
"""Alpe: der Schritt «Dienst: PAM und Richtlinie» in tools/test.sh (Plan 0.8 Nr. 136; Nachtlauf vom 27.11.2026, 1.10).

    python3 tests/test_testsh.py

tools/test.sh führt «go test -count=1 ./internal/pam ./internal/clipolicy» als eigenen Schritt aus, abgeschottet:
eigenes HOME und alle XDG-Ordner in einem Temp-Ordner, ohne Session-Bus und Display, die Go-Caches vor dem Wechsel
von HOME festgehalten. Der Test schneidet den Schritt aus tools/test.sh heraus und führt ihn mit einer Attrappe für
go aus (kein echter Go-Lauf, nichts im echten HOME): Die Attrappe hält fest, mit welchen Argumenten, in welchem Ordner
und mit welcher Umgebung «go test» lief. Dazu: mit ALPE_SKIP_GO übersprungen, der Temp-Ordner wird aufgeräumt, ein
Fehlschlag von go test zählt als Fehlschlag des Laufs.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
failures = 0


def check(cond, msg, extra=None):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    if not cond and extra is not None:
        print("       " + str(extra)[-800:])
    failures += 0 if cond else 1


if not shutil.which("bash"):
    print("bash fehlt – übersprungen")
    sys.exit(0)

text = open(os.path.join(REPO, "tools", "test.sh"), encoding="utf-8").read()
m = re.search(r'^step "Dienst: PAM und Richtlinie[^\n]*\n.*?^fi\n', text, re.M | re.S)
check(m is not None, "tools/test.sh hat den Schritt «Dienst: PAM und Richtlinie»")
if not m:
    sys.exit(1)
schritt = m.group(0)
check("go test -count=1 ./internal/pam ./internal/clipolicy" in schritt, "der Schritt ruft go test -count=1 für ./internal/pam und ./internal/clipolicy auf")
check(text.index(schritt) > text.index('step "Hintergrunddienst (go test)"'), "eigener Schritt nach dem bisherigen Go-Schritt")
# In der CI läuft tools/test.sh mit ALPE_SKIP_GO; die Pakete laufen dort im Go-Schritt mit.
workflow = open(os.path.join(REPO, ".github", "workflows", "tests.yml"), encoding="utf-8").read()
check("(cd core && go test -count=1 ./internal/pam ./internal/clipolicy)" in workflow,
      "CI: der Go-Schritt führt ./internal/pam und ./internal/clipolicy aus (tools/test.sh überspringt sie dort)")

# Attrappe für go: «go env X» liefert einen festen Cache-Pfad (wie vor dem Wechsel von HOME), «go test …» schreibt
# Argumente, Ordner und Umgebung in eine Datei und endet mit $GO_ATTRAPPE_RC.
ATTRAPPE = r'''#!/bin/bash
if [ "$1" = env ]; then
    echo "/echte-caches/$2"
    exit 0
fi
{
    echo "ARGS=$*"
    echo "PWD=$PWD"
    env | sort
} > "$GO_ATTRAPPE_LOG"
exit "${GO_ATTRAPPE_RC:-0}"
'''

HARNESS = r'''
set -uo pipefail
ALPE_DIR="$1"
fails=0
step() { echo "== $1"; }
run() { "$@" || { fails=$((fails + 1)); echo "fehlgeschlagen: $*"; }; }
source "$2"
echo "FAILS=$fails"
'''

tmp = tempfile.mkdtemp(prefix="alpe-test-testsh-")
try:
    bin_dir = os.path.join(tmp, "bin")
    os.makedirs(bin_dir)
    with open(os.path.join(bin_dir, "go"), "w", encoding="utf-8") as handle:
        handle.write(ATTRAPPE)
    os.chmod(os.path.join(bin_dir, "go"), 0o755)
    alpe = os.path.join(tmp, "alpe")
    os.makedirs(os.path.join(alpe, "core"))
    schritt_datei = os.path.join(tmp, "schritt.sh")
    with open(schritt_datei, "w", encoding="utf-8") as handle:
        handle.write(schritt)
    temp_fuer_mktemp = os.path.join(tmp, "mktemp")
    os.makedirs(temp_fuer_mktemp)
    log = os.path.join(tmp, "go.log")
    echtes_heim = os.path.join(tmp, "echtes-heim")
    os.makedirs(echtes_heim)
    basis = {"PATH": bin_dir + ":" + os.environ.get("PATH", ""), "GO_ATTRAPPE_LOG": log, "TMPDIR": temp_fuer_mktemp,
             "HOME": echtes_heim, "XDG_CONFIG_HOME": echtes_heim + "/c", "XDG_DATA_HOME": echtes_heim + "/d",
             "XDG_STATE_HOME": echtes_heim + "/s", "XDG_CACHE_HOME": echtes_heim + "/k", "XDG_RUNTIME_DIR": echtes_heim + "/r",
             "DBUS_SESSION_BUS_ADDRESS": "unix:path=/nirgends", "WAYLAND_DISPLAY": "wayland-9", "DISPLAY": ":9"}

    def lauf(**extra):
        if os.path.exists(log):
            os.remove(log)
        return subprocess.run(["bash", "-c", HARNESS, "harness", alpe, schritt_datei], capture_output=True, text=True,
                              env=dict(basis, **extra))

    aus = lauf()
    check(aus.returncode == 0 and "FAILS=0" in aus.stdout and os.path.isfile(log), "Lauf mit go-Attrappe: grün", aus.stdout + aus.stderr)
    umgebung = {}
    if os.path.isfile(log):
        for zeile in open(log, encoding="utf-8").read().splitlines():
            if "=" in zeile:
                k, v = zeile.split("=", 1)
                umgebung.setdefault(k, v)
    check(umgebung.get("ARGS") == "test -count=1 ./internal/pam ./internal/clipolicy" and umgebung.get("PWD") == os.path.join(alpe, "core"),
          "go test -count=1 ./internal/pam ./internal/clipolicy im Ordner core", umgebung.get("ARGS"))
    heim = umgebung.get("HOME", "")
    check(heim.startswith(temp_fuer_mktemp + "/") and heim != echtes_heim, "eigenes HOME in einem Temp-Ordner (nicht das HOME des Aufrufers)", heim)
    erwartet = {"XDG_CONFIG_HOME": heim + "/.config", "XDG_DATA_HOME": heim + "/.local/share", "XDG_STATE_HOME": heim + "/.local/state",
                "XDG_CACHE_HOME": heim + "/.cache", "XDG_RUNTIME_DIR": heim + "/run"}
    check(heim and all(umgebung.get(k) == v for k, v in erwartet.items()), "alle XDG-Ordner im Temp-HOME",
          {k: umgebung.get(k) for k in erwartet})
    check(not {"DBUS_SESSION_BUS_ADDRESS", "WAYLAND_DISPLAY", "DISPLAY"} & set(umgebung), "ohne Session-Bus und Display",
          sorted({"DBUS_SESSION_BUS_ADDRESS", "WAYLAND_DISPLAY", "DISPLAY"} & set(umgebung)))
    check(umgebung.get("GOMODCACHE") == "/echte-caches/GOMODCACHE" and umgebung.get("GOCACHE") == "/echte-caches/GOCACHE"
          and umgebung.get("GOPATH") == "/echte-caches/GOPATH", "Go-Caches vor dem Wechsel von HOME festgehalten (go env)",
          {k: umgebung.get(k) for k in ("GOMODCACHE", "GOCACHE", "GOPATH")})
    check(os.listdir(temp_fuer_mktemp) == [], "der Temp-Ordner wird danach entfernt", os.listdir(temp_fuer_mktemp))
    check(os.listdir(echtes_heim) == [], "im HOME des Aufrufers entsteht nichts", os.listdir(echtes_heim))

    aus = lauf(GO_ATTRAPPE_RC="1")
    check("FAILS=1" in aus.stdout and os.listdir(temp_fuer_mktemp) == [], "schlägt go test fehl, zählt der Schritt als Fehlschlag (und räumt auf)",
          aus.stdout + aus.stderr)

    aus = lauf(ALPE_SKIP_GO="1")
    check("FAILS=0" in aus.stdout and "ALPE_SKIP_GO gesetzt – übersprungen" in aus.stdout and not os.path.exists(log),
          "mit ALPE_SKIP_GO übersprungen", aus.stdout + aus.stderr)
finally:
    shutil.rmtree(tmp, ignore_errors=True)

print("\n%s" % ("alle Prüfungen bestanden" if not failures else "%d FEHLER" % failures))
sys.exit(1 if failures else 0)
