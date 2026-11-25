"""Prüft, dass die Version nur aus shell/Common/Brand.qml kommt (Plan 0.5 Nr. 2):
das Makefile in core/ liest sie dort, und der damit gebaute Dienst meldet sie.

    python3 tests/test_version.py

Der Bau läuft über «make dev» in einen Temp-Ordner (ohne eingebettete Oberfläche, nichts im
Quellbaum). Ohne go oder make, oder mit ALPE_SKIP_GO, wird nur das Makefile geprüft bzw. übersprungen.
"""
import os, re, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORE = os.path.join(HERE, "core")
BRAND = os.path.join(HERE, "shell", "Common", "Brand.qml")
checks = 0


def expect(got, want, what):
    global checks
    assert got == want, "%s: %r statt %r" % (what, got, want)
    checks += 1


def make(*args, env=None):
    out = subprocess.run(["make", "-s", "-C", CORE, *args], capture_output=True, text=True, env=env)
    assert out.returncode == 0, "make %s: %s" % (" ".join(args), out.stderr)
    return out.stdout.strip()


brand = re.search(r'readonly property string version:\s*"([^"]+)"', open(BRAND, encoding="utf-8").read()).group(1)
expect(bool(re.fullmatch(r"\d+(\.\d+)+", brand)), True, "Brand.qml trägt eine Versionsnummer")
for gone in ("VERSION", "CODENAME"):
    expect(os.path.exists(os.path.join(HERE, "shell", gone)), False, "shell/%s gibt es nicht mehr" % gone)

if not shutil.which("make"):
    print("make fehlt – übersprungen")
    sys.exit(0)

expect(make("print-version"), brand, "Makefile liest die Version aus Brand.qml")
# Eine zufällig gesetzte Umgebungsvariable darf die Version nicht still ersetzen.
expect(make("print-version", env=dict(os.environ, VERSION="9.9.9")), brand, "VERSION aus der Umgebung wirkt nicht")

# Sperrpaket (Plan 0.8 Nr. 86): «make sperrpaket» im Makefile der Wurzel setzt es zusammen; die Version in
# metadata.json kommt aus derselben Quelle wie Brand.version – nicht aus der Datei im Repository.
import json
sperr_tmp = tempfile.mkdtemp(prefix="alpe-sperrpaket-")
try:
    out = subprocess.run(["make", "-s", "-C", HERE, "sperrpaket", "BUILD=" + sperr_tmp], capture_output=True, text=True,
                         env=dict(os.environ, VERSION="9.9.9"))
    expect(out.returncode, 0, "make sperrpaket: %s" % out.stderr)
    paket = os.path.join(sperr_tmp, "plasma", "org.alpe.desktop")
    meta = json.load(open(os.path.join(paket, "metadata.json"), encoding="utf-8"))
    expect(meta["KPlugin"]["Version"], brand, "Version in metadata.json des Sperrpakets = Brand.version")
    expect(meta["KPlugin"]["Id"], "org.alpe.desktop", "Id des Sperrpakets")
    quelle = json.load(open(os.path.join(HERE, "lockscreen", "org.alpe.desktop", "metadata.json"), encoding="utf-8"))
    quelle["KPlugin"]["Version"] = brand
    expect(meta, quelle, "metadata.json sonst unverändert aus lockscreen/org.alpe.desktop")
    ansicht = os.path.join(HERE, "shell", "Modules", "Lock", "Alpe")
    lock = os.path.join(paket, "contents", "lockscreen")
    for name in ("HyprlockView.qml", "layout.js"):
        expect(open(os.path.join(lock, name), "rb").read() == open(os.path.join(ansicht, name), "rb").read(), True,
               "%s aus shell/Modules/Lock/Alpe im Paket" % name)
    for name in os.listdir(os.path.join(ansicht, "fonts")):
        expect(open(os.path.join(lock, "fonts", name), "rb").read() == open(os.path.join(ansicht, "fonts", name), "rb").read(), True,
               "ganzer Ordner fonts aus shell/Modules/Lock/Alpe im Paket: %s" % name)
    for name in ("LockScreen.qml", "CapsLock.qml", "config.xml"):
        expect(os.path.isfile(os.path.join(lock, name)), True, "%s aus lockscreen/org.alpe.desktop im Paket" % name)
finally:
    shutil.rmtree(sperr_tmp, ignore_errors=True)

if os.environ.get("ALPE_SKIP_GO") or not shutil.which("go"):
    print("go fehlt oder ALPE_SKIP_GO – Bau übersprungen; %d Prüfungen bestanden" % checks)
    sys.exit(0)

out_dir = tempfile.mkdtemp(prefix="alpe-version-")
try:
    env = dict(os.environ, CGO_ENABLED="0")
    env.pop("GOFLAGS", None)
    make("dev", "BUILD_DIR=" + out_dir, env=env)
    got = subprocess.run([os.path.join(out_dir, "alpe-dienst"), "version"], capture_output=True, text=True).stdout.strip()
    expect(got, "alpe-dienst " + brand, "«alpe-dienst version» meldet die Version aus Brand.qml")
    # Plan 0.8 Nr. 67: Der User-Agent trägt dieselbe Version, auf drei Stellen ergänzt. Die Hilfe von
    # «dl» nennt ihn; so zeigt sich, dass der Bau die Nummer wirklich einsetzt (und nicht «dev»).
    agent = "Alpe/%s (+https://github.com/alpe-shell/alpe)" % ".".join((brand.split(".") + ["0", "0"])[:max(3, len(brand.split(".")))])
    hilfe = subprocess.run([os.path.join(out_dir, "alpe-dienst"), "dl", "--help"], capture_output=True, text=True).stdout
    expect(agent in hilfe, True, "User-Agent des gebauten Dienstes ist %s" % agent)
finally:
    shutil.rmtree(out_dir, ignore_errors=True)

print("alle %d Prüfungen bestanden" % checks)
