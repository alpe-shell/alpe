#!/usr/bin/env python3
"""Prüft tools/node-tests.py mit einer kleinen Attrappe von shell/tests.

    python3 tests/test_node_tests.py
"""
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
TOOL = os.path.join(os.path.dirname(HERE), "tools", "node-tests.py")
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    if not cond:
        failures += 1


if not shutil.which("node"):
    print("node fehlt – übersprungen")
    sys.exit(0)

tmp = tempfile.mkdtemp()
os.makedirs(os.path.join(tmp, "tests"))


def datei(name, body):
    with open(os.path.join(tmp, "tests", name), "w") as handle:
        handle.write('import test from "node:test";\nimport assert from "node:assert/strict";\n' + body)


def run():
    return subprocess.run([sys.executable, TOOL], env=dict(os.environ, ALPE_SHELL_DIR=tmp), capture_output=True, text=True)


datei("gut.test.mjs", 'test("geht", () => assert.equal(1, 1));\n')
datei("dock-model.test.mjs", 'test("compositor window identity survives reorder and rejects null", () => assert.equal(1, 2));\n')
r = run()
check(r.returncode == 0 and "1 bekannt" in r.stdout, "nur ein bekannter Fehlschlag: grün")
check("HINWEIS" in r.stdout, "bekannte, hier nicht vorhandene Fehlschläge werden als behoben genannt")

datei("neu.test.mjs", 'test("bricht neu", () => assert.equal(1, 2));\n')
r = run()
check(r.returncode == 1 and "neu.test.mjs: bricht neu" in r.stdout, "neuer Fehlschlag: rot")
os.remove(os.path.join(tmp, "tests", "neu.test.mjs"))

datei("kaputt.test.mjs", 'import "./gibtsnicht.mjs";\n')
r = run()
check(r.returncode == 1 and "kaputt.test.mjs" in r.stdout, "Datei, die beim Laden abbricht: rot")

shutil.rmtree(tmp)
print("alle Prüfungen bestanden" if failures == 0 else "%d Prüfung(en) fehlgeschlagen" % failures)
sys.exit(1 if failures else 0)
