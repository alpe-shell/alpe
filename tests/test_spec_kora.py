#!/usr/bin/env python3
"""Alpe: packaging/fedora/kora-icon-theme.spec für das COPR alpe-shell/alpe (Plan 6.3, 0.8 Nr. 91, 99, 105; E3,
Nachtlauf vom 27.11.2026, Punkt 3.1).

    python3 tests/test_spec_kora.py

Liest die Spec als Text (ohne rpm): Name kora-icon-theme (so verlangt es alpe-shell), Quelle ein festes Release mit
Prüfsumme, die beim Entpacken geprüft wird, Lizenz GPL-3.0-only, noarch, Requires breeze-icon-theme und
hicolor-icon-theme (index.theme erbt von beiden), keine Epoch/Obsoletes/Provides/Conflicts (0.8 Nr. 99), keine
Scriptlets, keine fremden COPR-Namen, beide Themen in %files und eine %check-Prüfung.
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC = os.path.join(REPO, "packaging", "fedora", "kora-icon-theme.spec")
ALPE_SPEC = os.path.join(REPO, "packaging", "fedora", "alpe-shell.spec")
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


text = open(SPEC, encoding="utf-8").read()
ohne_kommentar = "\n".join(z for z in text.splitlines() if not z.lstrip().startswith("#"))


def tags(name):
    return [m.group(1).strip() for m in re.finditer(r"^%s:\s*(.+)$" % re.escape(name), ohne_kommentar, re.M)]


def abschnitt(name):
    m = re.search(r"^%%%s\b.*?\n(.*?)(?=^%%(?:prep|build|install|check|files|changelog|pre|post|preun|postun)\b|\Z)"
                  % name, ohne_kommentar, re.M | re.S)
    return m.group(1) if m else ""


check(tags("Name") == ["kora-icon-theme"], "Name: kora-icon-theme (alpe-shell verlangt genau diesen Namen)")
check("Requires:       kora-icon-theme" in open(ALPE_SPEC, encoding="utf-8").read(), "alpe-shell.spec verlangt kora-icon-theme ohne Version")
version = tags("Version")
check(len(version) == 1 and re.fullmatch(r"\d+\.\d+\.\d+", version[0]) is not None, "Version ist ein festes Release (%s)" % version)
check(tags("License") == ["GPL-3.0-only"], "License: GPL-3.0-only (LICENSE = GPL-3.0, README «GPL3» ohne «or later»)")
check(tags("BuildArch") == ["noarch"], "BuildArch: noarch")
quelle = tags("Source0")
check(len(quelle) == 1 and quelle[0].startswith("%{url}/archive/refs/tags/v%{version}.tar.gz"), "Source0: Archiv des Tags v%{version}")
check(tags("URL") == ["https://github.com/bikass/kora"], "URL: github.com/bikass/kora (Plan 6.3)")
summe = re.findall(r"^%global kora_sha256 ([0-9a-f]{64})$", ohne_kommentar, re.M)
check(len(summe) == 1, "Prüfsumme sha256 als Makro festgehalten")
prep = abschnitt("prep")
check('echo "%{kora_sha256}  %{SOURCE0}" | sha256sum -c -' in prep and prep.index("sha256sum") < prep.index("%autosetup"),
      "%prep prüft die Prüfsumme vor dem Entpacken")
requires = tags("Requires")
check(sorted(requires) == ["breeze-icon-theme", "hicolor-icon-theme"], "Requires: breeze-icon-theme, hicolor-icon-theme (0.8 Nr. 105)")
for t in ("Epoch", "Obsoletes", "Provides", "Conflicts"):
    check(not tags(t), "kein %s: (0.8 Nr. 99)" % t)
scriptlets = re.findall(r"^%(pre|post|preun|postun|pretrans|posttrans)\b", ohne_kommentar, re.M)
check(not scriptlets, "keine Scriptlets")
coprs = set(re.findall(r"COPR\s+([\w.-]+/[\w.-]+)", text, re.I))
check(coprs <= {"alpe-shell/alpe"} and "copr.fedorainfracloud.org" not in text, "nur das eigene COPR genannt (%s)" % sorted(coprs))
dateien = [z.strip() for z in abschnitt("files").splitlines()]
for thema in ("kora", "kora-pgrey"):
    check("%%{_datadir}/icons/%s/*" % thema in dateien and "%%dir %%{_datadir}/icons/%s" % thema in dateien,
          "%%files: Thema %s" % thema)
check("%license LICENSE" in dateien, "%license LICENSE")
pruefung = abschnitt("check")
check("Inherits=breeze,hicolor" in pruefung and "-xtype l" in pruefung, "%check: index.theme erbt von breeze/hicolor, keine kaputte Verknüpfung")
check("create-new-icon-theme.cache.sh" in abschnitt("install"), "%install: Werkzeug des Ursprungs nicht im Paket")

# packaging/fedora/kora-icon-theme.rpmlintrc: eigene Datei je Paket (P17, Nachtlauf vom 29.11.2026, 3.1), jeder Filter
# mit Kommentar darüber
rc_pfad = os.path.join(REPO, "packaging", "fedora", "kora-icon-theme.rpmlintrc")
check(os.path.isfile(rc_pfad), "packaging/fedora/kora-icon-theme.rpmlintrc vorhanden (P17)")
if os.path.isfile(rc_pfad):
    rc_zeilen = open(rc_pfad, encoding="utf-8").read().splitlines()
    ohne_grund = [z for i, z in enumerate(rc_zeilen) if z.startswith("addFilter(") and not (i and rc_zeilen[i - 1].startswith("#"))]
    check(any(z.startswith("addFilter(") for z in rc_zeilen) and not ohne_grund,
          "kora-icon-theme.rpmlintrc: jeder Filter mit Begründung darüber (ohne: %s)" % ohne_grund)

print("\n%s" % ("alle Prüfungen bestanden" if not failures else "%d FEHLER" % failures))
sys.exit(1 if failures else 0)
