"""Prüft tools/release-pruefen.sh: Tag gegen Brand.qml und CHANGELOG.md.

    python3 tests/test_release.py
"""
import os, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(HERE, "tools", "release-pruefen.sh")
checks = 0


def expect(got, want, what):
    global checks
    assert got == want, "%s: %r statt %r" % (what, got, want)
    checks += 1


def repo(brand=None, patch=None, changelog="# Änderungen\n\n## 1.1 (Dezember 2026)\n\n- neu\n\n## 1.0 (November 2026)\n"):
    root = tempfile.mkdtemp()
    os.makedirs(os.path.join(root, "tools"))
    shutil.copy(SCRIPT, os.path.join(root, "tools", "release-pruefen.sh"))
    os.makedirs(os.path.join(root, "shell", "Common") if brand else os.path.join(root, "schichten"))
    if brand:
        with open(os.path.join(root, "shell", "Common", "Brand.qml"), "w") as handle:
            handle.write('Singleton {\n    readonly property string version: "%s"\n}\n' % brand)
    if patch:
        with open(os.path.join(root, "schichten", "0001-Alpe.patch"), "w") as handle:
            handle.write('-    readonly property string version: "0.9"\n+    readonly property string version: "%s"\n' % patch)
    with open(os.path.join(root, "CHANGELOG.md"), "w") as handle:
        handle.write(changelog)
    return root


def run(root, *args):
    out = subprocess.run(["bash", os.path.join(root, "tools", "release-pruefen.sh"), *args], capture_output=True, text=True)
    return out.returncode, out.stdout


expect(run(repo(brand="1.1"), "v1.1")[0], 0, "Quellbaum: alles passt")
code, out = run(repo(brand="1.0"), "v1.1")
expect((code, "Brand.qml hat Version «1.0»" in out), (1, True), "Brand.qml veraltet")
code, out = run(repo(brand="1.1", changelog="## 1.0 (November 2026)\n"), "v1.1")
expect((code, "CHANGELOG.md ist «1.0»" in out), (1, True), "CHANGELOG ohne neuen Eintrag")
expect(run(repo(patch="1.1"), "v1.1")[0], 0, "Schichten: Version aus der Patch-Datei (neue Zeile, nicht die alte)")
expect(run(repo(patch="1.0"), "v1.1")[0], 1, "Schichten: falsche Version")
expect(run(repo(brand="1.1"), "neu")[0], 1, "kein Versions-Tag")
expect(run(repo(brand="1.1"))[0], 2, "ohne Tag: Aufruf erklären")
# Das Repository selbst: der oberste CHANGELOG-Eintrag und Brand.qml stimmen überein
code, out = run(HERE, "v" + subprocess.run(["sed", "-n", r"s/^## \([0-9][0-9.]*\).*/\1/p", os.path.join(HERE, "CHANGELOG.md")], capture_output=True, text=True).stdout.split()[0])
expect(code, 0, "dieses Repository: Brand.qml und CHANGELOG.md gleich\n" + out)
print("alle %d Prüfungen bestanden" % checks)
