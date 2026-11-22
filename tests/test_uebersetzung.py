#!/usr/bin/env python3
"""Alpe: en.json und die deutschen Kataloge bleiben vollständig (Plan 0.8 Nr. 74).

    python3 tests/test_uebersetzung.py

Prüft mit shell/translations/extract_translations.py, ohne etwas zu schreiben:
  - en.json enthält genau die Texte aus qsTr()/I18n.tr() der Oberfläche (sonst: Skript laufen lassen),
  - jeder Text hat eine deutsche Übersetzung – ausser den bekannten Lücken in
    tests/data/uebersetzung-bekannte-luecken.txt (eine Zeile je Lücke: JSON [Kontext, Text]).
    Eine neue Lücke ist ein Fehler; eine geschlossene muss aus der Liste, damit sie nicht wiederkommt.
  - keine Beinahe-Doppel unter den Texten (check_term_variants.py).
Dazu ein kleiner Baum im Temp-Ordner: Das Skript findet neue, weggefallene und unübersetzte Texte.
"""
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHELL = os.environ.get("ALPE_SHELL_DIR") or os.path.join(REPO, "shell")
SCRIPT = os.path.join(SHELL, "translations", "extract_translations.py")
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


spec = importlib.util.spec_from_file_location("extract_translations", SCRIPT)
ex = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ex)

new, gone, gaps, surplus = ex.check(SHELL)
check(not new and not gone, "en.json ist aktuell (%d fehlen, %d überzählig; sonst: python3 shell/translations/extract_translations.py)%s"
      % (len(new), len(gone), "".join("\n         " + repr(item[1]) for item in (new + gone)[:10])))

with open(os.path.join(REPO, "tests", "data", "uebersetzung-bekannte-luecken.txt"), encoding="utf-8") as handle:
    known = {tuple(json.loads(line)) for line in handle if line.strip() and not line.startswith("#")}
fresh = [pair for pair in gaps if pair not in known]
closed = sorted(known - set(gaps))
check(not fresh, "kein neuer Text ohne deutsche Übersetzung (%d bekannte Lücken)%s"
      % (len(known), "".join("\n         " + json.dumps(list(pair), ensure_ascii=False) for pair in fresh[:20])))
check(not closed, "die Liste der bekannten Lücken ist aktuell%s"
      % "".join("\n         geschlossen, aus der Liste nehmen: " + json.dumps(list(pair), ensure_ascii=False) for pair in closed[:20]))

variants = subprocess.run([sys.executable, "-B", os.path.join(SHELL, "translations", "check_term_variants.py")], capture_output=True, text=True)
check(variants.returncode == 0, "keine Beinahe-Doppel unter den Texten" + ("" if variants.returncode == 0 else "\n" + variants.stderr[-600:]))

# Das Skript selbst, an einem kleinen Baum.
tmp = tempfile.mkdtemp(prefix="alpe-uebersetzung-")
try:
    for folder in ("translations/poexports", "Alpe/translations/poexports", "Alpe/Widgets", "Modules"):
        os.makedirs(os.path.join(tmp, folder))
    for name in ("extract_translations.py",):
        shutil.copy(os.path.join(SHELL, "translations", name), os.path.join(tmp, "translations", name))
    with open(os.path.join(tmp, "Modules", "A.qml"), "w", encoding="utf-8") as handle:
        handle.write('Item {\n  text: qsTr("Alt")\n  a: I18n.tr("Offen", "Zustand eines Fensters")\n'
                     '  b: I18n.tr("Offen", "Laden", true)\n  c: I18n.tr(\'Mit "Zitat"\')\n}\n')
    with open(os.path.join(tmp, "Alpe", "Widgets", "B.qml"), "w", encoding="utf-8") as handle:
        handle.write('Item { text: I18n.tr("Bibliothek"); t: I18n.tr("Fehlt") }\n')
    with open(os.path.join(tmp, "translations", "poexports", "de.json"), "w", encoding="utf-8") as handle:
        json.dump({"Alt": {"Alt": "alt"}, "Offen": {"Offen": "offen"}, 'Mit "Zitat': {'Mit "Zitat"': "mit Zitat"},
                   "Weg": {"Weg": "weg"}, "Fehlt": {"Fehlt": ""}}, handle)
    with open(os.path.join(tmp, "Alpe", "translations", "poexports", "de.json"), "w", encoding="utf-8") as handle:
        json.dump({"Bibliothek": {"Bibliothek": "Bibliothek"}}, handle)
    with open(os.path.join(tmp, "translations", "en.json"), "w", encoding="utf-8") as handle:
        json.dump([{"term": "Alt", "context": "Alt", "reference": "", "comment": ""},
                   {"term": "Entfernt", "context": "Entfernt", "reference": "", "comment": ""}], handle)
    tool = os.path.join(tmp, "translations", "extract_translations.py")
    out = subprocess.run([sys.executable, "-B", tool, "--pruefen"], capture_output=True, text=True)
    check(out.returncode == 1 and "fehlt in en.json: 'Bibliothek'" in out.stdout and "nicht mehr in der Oberfläche: 'Entfernt'" in out.stdout,
          "--pruefen meldet eine veraltete en.json (auch Texte unter Alpe/) und schreibt nichts")
    check("ohne deutsche Übersetzung: 'Fehlt'" in out.stdout and "ohne deutsche Übersetzung: 'Offen' (Kontext 'Laden')" not in out.stdout
          and "'Mit \"Zitat\"'" not in out.stdout.split("ohne deutsche", 1)[-1],
          "Lücken wie I18n.qml nachschlägt: leere Übersetzung fehlt, Text unter anderem Kontext gilt, Bibliothekskatalog zählt")
    check("überzählig in de.json: 'Weg'" in out.stdout, "überzählige Einträge in de.json werden genannt")
    check(len(json.load(open(os.path.join(tmp, "translations", "en.json"), encoding="utf-8"))) == 2, "en.json nach --pruefen unverändert")
    out = subprocess.run([sys.executable, "-B", tool], capture_output=True, text=True)
    entries = json.load(open(os.path.join(tmp, "translations", "en.json"), encoding="utf-8"))
    keys = [(entry["context"], entry["term"], entry["comment"]) for entry in entries]
    check(out.returncode == 0 and keys == [("Alt", "Alt", ""), ("Bibliothek", "Bibliothek", ""), ("Fehlt", "Fehlt", ""),
                                           ('Mit "Zitat"', 'Mit "Zitat"', ""), ("Offen", "Offen", "Zustand eines Fensters"), ("Laden", "Offen", "")],
          "en.json neu: Hinweis-Kontext als Kommentar, echter Kontext als eigener Eintrag: " + str(keys))
    check(entries[0]["reference"] == "Modules/A.qml" and set(entries[0]) == {"term", "context", "reference", "comment"},
          "Fundstellen ohne Zeilennummern, keine Felder des Übersetzungsdienstes")
    check(subprocess.run([sys.executable, "-B", tool, "--pruefen"], capture_output=True, text=True).returncode == 0, "danach ist en.json aktuell")
finally:
    shutil.rmtree(tmp, ignore_errors=True)

print("\nalle Prüfungen bestanden" if failures == 0 else f"\n{failures} FEHLER")
sys.exit(1 if failures else 0)
