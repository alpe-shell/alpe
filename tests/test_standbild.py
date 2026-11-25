#!/usr/bin/env python3
"""Alpe: Standbild der Sperre (Plan 0.8 Nr. 106).

Prüft ohne ffmpeg: Das Standbild design/kde/bilder/jagged-peaks-wolkenzug.jpg liegt vor, das Video hat die in
tools/standbild.py festgehaltene Prüfsumme (sonst wurde das Video geändert, ohne das Bild neu zu erzeugen), das Bild
ebenso, es ist nicht grösser als 1 MiB, steht in NOTICE und im Manifest; das Skript ruft ffmpeg wie die Shell auf.
Dazu design.py export: Das Standbild bleibt beim Export erhalten und steht im Manifest – nur für Videos des
eingespielten Designs, nicht für eigene Videos der Nutzer.
"""
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(REPO, "shell")
failures = 0


def check(cond, msg, ausgabe=None):
    """ausgabe (ein CompletedProcess) wird nur bei einem Fehlschlag angehängt."""
    global failures
    print(("ok    " if cond else "FEHLER ") + msg + ("" if cond or ausgabe is None else "\n" + ausgabe.stdout + ausgabe.stderr))
    failures += 0 if cond else 1


spec = importlib.util.spec_from_file_location("standbild", os.path.join(REPO, "tools", "standbild.py"))
sb = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sb)

# --- Das Bild im Repository
fehler = sb.pruefen()
check(fehler == [], "Standbild da, Video und Bild mit den festgehaltenen Prüfsummen, höchstens 1 MiB: %s" % fehler)
check(os.path.getsize(sb.BILD) <= 1024 * 1024 and sb.GRENZE == 1024 * 1024, "Grenze 1 MiB wie die Prüfung neuer Dateien, ohne Ausnahme")
with tempfile.TemporaryDirectory(prefix="alpe-standbild-test-") as tmp:
    weg = sb.pruefen(bild=os.path.join(tmp, "fehlt.jpg"))
    check(len(weg) == 1 and weg[0].startswith("Standbild fehlt"), "Test wird rot, wenn das Bild fehlt")
    anders = os.path.join(tmp, "video.mp4")
    with open(sb.VIDEO, "rb") as quelle, open(anders, "wb") as ziel:
        ziel.write(quelle.read() + b"\0")
    geaendert = sb.pruefen(video=anders)
    check(len(geaendert) == 1 and geaendert[0].startswith("Video geändert"), "Test wird rot, wenn das Video sich ändert, ohne dass das Bild neu erzeugt wurde")
    kopie = os.path.join(tmp, "bild.jpg")
    with open(sb.BILD, "rb") as quelle, open(kopie, "wb") as ziel:
        ziel.write(quelle.read()[:-1])
    check([f.split(" (")[0] for f in sb.pruefen(bild=kopie)] == ["Standbild geändert"], "Test wird rot, wenn das Bild nicht aus dem festgehaltenen Lauf stammt")

# --- Derselbe Aufruf wie in der Shell
poster_js = open(os.path.join(SHELL, "Common", "VideoPoster.js"), encoding="utf-8").read()
filter_js = re.search(r'^var FILTER = "(.*)";$', poster_js, re.M)
quality_js = re.search(r'^var QUALITY = "(.*)";$', poster_js, re.M)
check(filter_js and quality_js and filter_js.group(1) == sb.FILTER and quality_js.group(1) == sb.QUALITAET,
      "tools/standbild.py ruft ffmpeg mit demselben Filter und derselben Qualität auf wie die Shell (VideoPoster.js)")
service = open(os.path.join(SHELL, "Services", "VideoWallpaperService.qml"), encoding="utf-8").read()
check("VideoPoster.script()" in service and "VideoPoster.BUNDLED_EXIT" in service and "ffmpeg -nostdin" not in service,
      "VideoWallpaperService nimmt das Skript aus VideoPoster.js (mitgeliefertes Standbild vor ffmpeg)")
skript = open(os.path.join(REPO, "tools", "standbild.py"), encoding="utf-8").read()
check(skript.count("shutil.copyfile(teil, BILD)") == 1 and "open(BILD, \"w" not in skript,
      "tools/standbild.py schreibt genau eine Datei, das Bild")

# --- NOTICE und Manifest
notice = open(os.path.join(REPO, "NOTICE"), encoding="utf-8").read()
check("design/kde/bilder/jagged-peaks-wolkenzug.jpg" in notice and "eigene Ableitung des eigenen Videos" in notice,
      "NOTICE: Standbild als eigene Ableitung des Videos, Lizenz wie das Video")
manifest = json.load(open(os.path.join(REPO, "design", "kde", "manifest.json"), encoding="utf-8"))
check("jagged-peaks-wolkenzug.jpg" in manifest["bilder"] and "jagged-peaks-wolkenzug.mp4" in manifest["bilder"],
      "Manifest des Designs führt Video und Standbild")

# --- design.py export erhält das Standbild
TOOL = os.path.join(REPO, "tools", "design.py")


def lauf(h, design, *args):
    env = dict(os.environ, HOME=h, XDG_CONFIG_HOME=os.path.join(h, ".config"), XDG_STATE_HOME=os.path.join(h, ".local", "state"),
               XDG_DATA_HOME=os.path.join(h, ".local", "share"), XDG_DATA_DIRS=os.path.join(h, "sys"), ALPE_SHELL_DIR=SHELL,
               ALPE_DESIGN_DIR=design, XDG_CURRENT_DESKTOP="KDE", ALPE_DESIGN_NO_SERVICE="1")
    return subprocess.run([sys.executable, TOOL] + list(args), env=env, capture_output=True, text=True, stdin=subprocess.DEVNULL)


def schreibe(pfad, inhalt):
    os.makedirs(os.path.dirname(pfad), exist_ok=True)
    with open(pfad, "wb" if isinstance(inhalt, bytes) else "w") as handle:
        handle.write(inhalt)


with tempfile.TemporaryDirectory(prefix="alpe-standbild-export-") as tmp:
    h, design = os.path.join(tmp, "h"), os.path.join(tmp, "design")
    eingespielt = os.path.join(h, ".local", "share", "alpe", "design", "bilder")
    video = os.path.join(eingespielt, "berg.mp4")
    schreibe(video, b"VIDEO-1")
    schreibe(os.path.join(eingespielt, "berg.jpg"), b"STANDBILD-1")
    schreibe(os.path.join(h, ".config", "alpe", "settings.json"), json.dumps({"cornerRadius": 9}))
    sitzung = os.path.join(h, ".local", "state", "alpe", "session.json")
    schreibe(sitzung, json.dumps({"wallpaperPath": video}))
    out = lauf(h, design, "export", "--bilder", "ja")
    ziel = os.path.join(design, "kde", "bilder")
    man = json.load(open(os.path.join(design, "kde", "manifest.json"))) if out.returncode == 0 else {}
    check(out.returncode == 0 and open(os.path.join(ziel, "berg.jpg"), "rb").read() == b"STANDBILD-1" and man.get("bilder") == ["berg.mp4", "berg.jpg"],
          "Export: Standbild neben dem Video des eingespielten Designs kommt mit und steht im Manifest", out)

    # Zweiter Export: Neben dem eingespielten Video fehlt das Standbild jetzt – es kommt aus dem bisherigen Export,
    # weil dort dasselbe Video lag.
    os.remove(os.path.join(eingespielt, "berg.jpg"))
    out = lauf(h, design, "export", "--bilder", "ja")
    man = json.load(open(os.path.join(design, "kde", "manifest.json"))) if out.returncode == 0 else {}
    check(out.returncode == 0 and os.path.isfile(os.path.join(ziel, "berg.jpg")) and open(os.path.join(ziel, "berg.jpg"), "rb").read() == b"STANDBILD-1"
          and "berg.jpg" in man.get("bilder", []),
          "Export räumt design/kde ab, das Standbild bleibt trotzdem erhalten (aus dem bisherigen Export, gleiches Video)", out)

    # Anderes Video unter demselben Namen: das alte Standbild passt nicht mehr und kommt nicht mit.
    schreibe(video, b"VIDEO-2")
    out = lauf(h, design, "export", "--bilder", "ja")
    man = json.load(open(os.path.join(design, "kde", "manifest.json"))) if out.returncode == 0 else {}
    check(out.returncode == 0 and not os.path.exists(os.path.join(ziel, "berg.jpg")) and man.get("bilder") == ["berg.mp4"],
          "Export: zu einem geänderten Video kommt das alte Standbild nicht mit", out)

    # Eigenes Video ausserhalb des Designs: ein .jpg daneben wird nicht als Standbild genommen.
    eigen = os.path.join(h, "Videos", "see.mp4")
    schreibe(eigen, b"EIGEN")
    schreibe(os.path.join(h, "Videos", "see.jpg"), b"IRGENDWAS")
    schreibe(sitzung, json.dumps({"wallpaperPath": eigen}))
    out = lauf(h, design, "export", "--bilder", "ja")
    man = json.load(open(os.path.join(design, "kde", "manifest.json"))) if out.returncode == 0 else {}
    check(out.returncode == 0 and man.get("bilder") == ["see.mp4"] and not os.path.exists(os.path.join(ziel, "see.jpg")),
          "Export: zu einem eigenen Video der Nutzer wird kein .jpg daneben mitgenommen", out)

print("\n%s" % ("alle Prüfungen bestanden" if not failures else "%d FEHLER" % failures))
sys.exit(1 if failures else 0)
