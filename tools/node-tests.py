#!/usr/bin/env python3
"""Alpe: alle Node-Tests der Oberfläche (shell/tests/*.test.mjs) gegen eine feste Liste bekannter
Fehlschläge (tests/data/node-bekannte-fehlschlaege.txt).

    python3 tools/node-tests.py          Oberfläche in shell/ (oder $ALPE_SHELL_DIR)

Ergebnis 0: nur bekannte Fehlschläge. 1: ein neuer Fehlschlag (oder eine Testdatei bricht ab, ohne
einen Test zu melden). Bekannte Fehlschläge, die inzwischen bestehen, werden genannt, machen aber
nicht rot – dann die Liste nachführen.
"""
import glob
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(REPO, "shell")
LISTE = os.path.join(REPO, "tests", "data", "node-bekannte-fehlschlaege.txt")


def bekannte():
    with open(LISTE, encoding="utf-8") as handle:
        return {line.rstrip("\n") for line in handle if line.strip() and not line.startswith("#")}


def main():
    known = bekannte()
    failed, passed_files = set(), 0
    files = sorted(glob.glob(os.path.join(SHELL, "tests", "*.test.mjs")))
    for path in files:
        name = os.path.basename(path)
        proc = subprocess.run(["node", "--test", "--test-reporter=tap", path], cwd=SHELL,
                              capture_output=True, text=True)
        notok = [re.sub(r"^\s*not ok \d+ - ", "", line) for line in proc.stdout.splitlines()
                 if re.match(r"^\s*not ok \d+ - ", line)]
        for test in notok:
            failed.add("%s: %s" % (name, test))
        if proc.returncode != 0 and not notok:
            failed.add("%s: (Datei bricht ab, kein Test gemeldet)" % name)
        if proc.returncode == 0:
            passed_files += 1
    neu = sorted(failed - known)
    behoben = sorted(known - failed)
    print("%d Dateien, %d ohne Fehlschlag, %d Fehlschläge (%d bekannt)" % (len(files), passed_files, len(failed), len(failed & known)))
    for item in behoben:
        print("HINWEIS bekannter Fehlschlag besteht jetzt (Liste nachführen): " + item)
    for item in neu:
        print("FEHLER neuer Fehlschlag: " + item)
    return 1 if neu else 0


if __name__ == "__main__":
    sys.exit(main())
