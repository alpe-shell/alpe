#!/usr/bin/env python3
"""Alpe: packaging/fedora/matugen.spec für das COPR alpe-shell/alpe (Plan 6.3; E3, Nachtlauf vom 28.11.2026,
Punkt 3.1; Entscheide P2 und P6).

    python3 tests/test_spec_matugen.py

Liest die Spec als Text (ohne rpm): Name matugen, Version ein festes Release, das die Untergrenze aus alpe-shell.spec
erfüllt; Release über 4.2.0-1 eines fremden COPR; Quelle das Archiv des Tags mit Prüfsumme, die vor dem Entpacken
geprüft wird; Bau mit «cargo build --release --locked» und CARGO_HOME im Bauordner; %check prüft Fassung und
--prefer; Lizenzfeld GPL-2.0-or-later und die Lizenzen der gelinkten Crates (Liste aus dem Nachtlauf, Punkt 3.1) in
SPDX-Schreibweise ohne «/»; keine Epoch/Obsoletes/Provides/Conflicts, keine Scriptlets, keine fremden COPR-Namen.
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC = os.path.join(REPO, "packaging", "fedora", "matugen.spec")
ALPE_SPEC = os.path.join(REPO, "packaging", "fedora", "alpe-shell.spec")
failures = 0

# Ausdrücke der 187 gelinkten Crates (cargo tree, aarch64 und x86_64 gleich), «A/B» als «A OR B», ohne matugen selbst
CRATE_LIZENZEN = {
    "(0BSD OR MIT OR Apache-2.0)", "Apache-2.0", "(Apache-2.0 OR BSL-1.0)", "(Apache-2.0 OR MIT)",
    "(Apache-2.0 WITH LLVM-exception OR Apache-2.0 OR MIT)", "BSD-2-Clause", "(BSD-2-Clause OR Apache-2.0 OR MIT)",
    "BSD-3-Clause", "(BSD-3-Clause OR Apache-2.0)", "(BSD-3-Clause OR MIT)", "(CC0-1.0 OR Apache-2.0)", "MIT",
    "(MIT OR Apache-2.0)", "(MIT OR Apache-2.0 OR CC0-1.0)", "(MIT OR Apache-2.0 OR Zlib)", "(MIT OR Zlib OR Apache-2.0)",
    "MPL-2.0", "Unicode-DFS-2016", "(Unlicense OR MIT)", "Zlib", "(Zlib OR Apache-2.0 OR MIT)",
}


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


text = open(SPEC, encoding="utf-8").read()
ohne_kommentar = "\n".join(z for z in text.splitlines() if not z.lstrip().startswith("#"))


def tags(name):
    return [m.group(1).strip() for m in re.finditer(r"^%s:\s*(.+)$" % re.escape(name), ohne_kommentar, re.M)]


def abschnitt(name):
    m = re.search(r"^%%%s\b.*?\n(.*?)(?=^%%(?:prep|conf|build|install|check|files|changelog|pre|post|preun|postun)\b|\Z)"
                  % name, ohne_kommentar, re.M | re.S)
    return m.group(1) if m else ""


def zahlen(v):
    return tuple(int(x) for x in v.split("."))


def teile(ausdruck):
    """Oberste Ebene eines SPDX-Ausdrucks an « AND » trennen (Klammern bleiben zusammen)."""
    tiefe, start, aus = 0, 0, []
    for i, z in enumerate(ausdruck):
        tiefe += {"(": 1, ")": -1}.get(z, 0)
        if tiefe == 0 and ausdruck.startswith(" AND ", i):
            aus.append(ausdruck[start:i])
            start = i + 5
    aus.append(ausdruck[start:])
    return aus


check(tags("Name") == ["matugen"], "Name: matugen (alpe-shell verlangt genau diesen Namen)")
version = tags("Version")
check(len(version) == 1 and re.fullmatch(r"\d+\.\d+\.\d+", version[0]) is not None, "Version ist ein festes Release (%s)" % version)
mindest = re.findall(r"^Requires:\s*matugen\s*>=\s*([\d.]+)", open(ALPE_SPEC, encoding="utf-8").read(), re.M)
check(not mindest or (version and zahlen(version[0]) >= zahlen(mindest[0])),
      "Version nicht unter der Untergrenze in alpe-shell.spec (%s)" % mindest)
check(version and zahlen(version[0]) >= (4, 1), "Version mindestens 4.1 (--prefer, P2)")
release = tags("Release")
m = re.fullmatch(r"(\d+)%\{\?dist\}", release[0]) if len(release) == 1 else None
check(m is not None and int(m.group(1)) > 1, "Release über 1 (fremdes COPR liefert 4.2.0-1) (%s)" % release)
quelle = tags("Source0")
check(len(quelle) == 1 and quelle[0].startswith("%{url}/archive/refs/tags/v%{version}.tar.gz"), "Source0: Archiv des Tags v%{version}")
check(tags("URL") == ["https://github.com/InioX/matugen"], "URL: github.com/InioX/matugen")
summe = re.findall(r"^%global quelle_sha256 ([0-9a-f]{64})$", ohne_kommentar, re.M)
check(len(summe) == 1, "Prüfsumme sha256 als Makro festgehalten")
prep = abschnitt("prep")
check('echo "%{quelle_sha256}  %{SOURCE0}" | sha256sum -c -' in prep and "%autosetup" in prep
      and prep.index("sha256sum") < prep.index("%autosetup"), "%prep prüft die Prüfsumme vor dem Entpacken")
bau = abschnitt("build")
check(re.search(r"^cargo build --release --locked\s*$", bau, re.M) is not None, "Bau mit cargo build --release --locked (P6)")
check("CARGO_HOME=%{_builddir}" in bau, "CARGO_HOME im Bauordner, nicht im Home des Bauenden")
check("--offline" not in bau and "--frozen" not in bau, "kein --offline/--frozen (Crates kommen beim Bau aus dem Netz, P6)")
pruefung = abschnitt("check")
check("--version" in pruefung and "matugen %{version}" in pruefung, "%check: Fassung")
check("--prefer" in pruefung, "%check: Option --prefer vorhanden (P2)")
lizenz = tags("License")
check(len(lizenz) == 1, "genau ein License-Feld")
if lizenz:
    t = teile(lizenz[0])
    check(t[0] == "GPL-2.0-or-later", "License beginnt mit GPL-2.0-or-later (matugen selbst)")
    check(set(t[1:]) == CRATE_LIZENZEN and len(t[1:]) == len(CRATE_LIZENZEN),
          "License: genau die Ausdrücke der gelinkten Crates, je einmal (fehlt: %s, zu viel: %s)"
          % (sorted(CRATE_LIZENZEN - set(t[1:])), sorted(set(t[1:]) - CRATE_LIZENZEN)))
    check("/" not in lizenz[0] and "LicenseRef" not in lizenz[0], "License ohne «/» und ohne LicenseRef")
    check(lizenz[0].count("(") == lizenz[0].count(")"), "License: Klammern ausgeglichen")
for t in ("Epoch", "Obsoletes", "Provides", "Conflicts"):
    check(not tags(t), "kein %s:" % t)
scriptlets = re.findall(r"^%(pre|post|preun|postun|pretrans|posttrans)\b", ohne_kommentar, re.M)
check(not scriptlets, "keine Scriptlets")
coprs = set(re.findall(r"COPR\s+\(?([\w.-]+/[\w.-]+)", text, re.I))
check(coprs <= {"alpe-shell/alpe"} and "copr.fedorainfracloud.org" not in text, "nur das eigene COPR genannt (%s)" % sorted(coprs))
dateien = [z.strip() for z in abschnitt("files").splitlines()]
check("%{_bindir}/%{name}" in dateien and "%license LICENSE" in dateien, "%files: Programm und LICENSE")

print("\n%s" % ("alle Prüfungen bestanden" if not failures else "%d FEHLER" % failures))
sys.exit(1 if failures else 0)
