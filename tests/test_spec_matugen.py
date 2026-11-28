#!/usr/bin/env python3
"""Alpe: packaging/fedora/matugen.spec für das COPR alpe-shell/alpe (Plan 6.3; E3, Nachtlauf vom 28.11.2026,
Punkt 3.1, und vom 29.11.2026, Teil 2; Entscheide P2, P19, P20, P21).

    python3 tests/test_spec_matugen.py

Liest die Spec als Text (ohne rpm): Name matugen, Version ein festes Release, das die Untergrenze aus alpe-shell.spec
erfüllt; Release über 4.2.0-1 eines fremden COPR; Source0 das Archiv des Tags, Source1 das vendorte Crate-Archiv,
beide mit Prüfsumme, die vor dem Entpacken geprüft wird; Cargo nimmt die Crates nur aus vendor/; Bau mit
«cargo build --release --locked --offline -j%{_smp_build_ncpus}» und CARGO_HOME im Bauordner, ohne Netz;
LICENSE.dependencies aus cargo tree als %license; %check prüft Fassung, --prefer und gleicht die Lizenzen aus cargo
tree mit dem Feld License ab; Lizenzfeld GPL-2.0-or-later und die Lizenzen der gelinkten Crates (Liste aus dem
Nachtlauf, Punkt 3.1) in SPDX-Schreibweise ohne «/»; keine Epoch/Obsoletes/Provides/Conflicts, keine Scriptlets,
keine fremden COPR-Namen. Dazu packaging/fedora/matugen-vendor.sh (gleiche Fassung und Prüfsumme, reproduzierbar
gepackt) und packaging/fedora/matugen.rpmlintrc (jeder Filter begründet).
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
# Source1: vendortes Crate-Archiv mit eigener Prüfsumme, vor dem Entpacken geprüft, nach vendor/ entpackt (P19)
check(tags("Source1") == ["%{name}-%{version}-vendor.tar.gz"], "Source1: %{name}-%{version}-vendor.tar.gz (P19)")
vendor_summe = re.findall(r"^%global vendor_sha256 ([0-9a-f]{64})$", ohne_kommentar, re.M)
check(len(vendor_summe) == 1, "Prüfsumme des Crate-Archivs als Makro vendor_sha256")
check('echo "%{vendor_sha256}  %{SOURCE1}" | sha256sum -c -' in prep and "%autosetup" in prep
      and prep.index("%{SOURCE1}") < prep.index("%autosetup"), "%prep prüft das Crate-Archiv vor dem Entpacken")
check(re.search(r"^%autosetup -n %\{name\}-%\{version\} -a 1$", prep, re.M) is not None, "%autosetup -a 1 entpackt Source1 im Quellordner")
check("> .cargo/config.toml" in prep and "'[source.crates-io]'" in prep and "'replace-with = \"vendored-sources\"'" in prep
      and "'[source.vendored-sources]'" in prep and "'directory = \"vendor\"'" in prep,
      "%prep: .cargo/config.toml ersetzt crates-io durch vendor/")
check(re.search(r"^find vendor -type f -name '\*\.rs' -perm /111 -exec chmod a-x \{\} \+$", prep, re.M) is not None,
      "%prep: .rs-Dateien unter vendor/ ohne x-Recht (sonst bricht brp-mangle-shebangs am Debug-Quellpaket ab)")
bau = abschnitt("build")
check(re.search(r"^cargo build --release --locked --offline -j%\{_smp_build_ncpus\}\s*$", bau, re.M) is not None,
      "Bau mit cargo build --release --locked --offline -j%{_smp_build_ncpus} (P19, P21)")
check("CARGO_HOME=%{_builddir}" in bau, "CARGO_HOME im Bauordner, nicht im Home des Bauenden")
check(re.search(r"^cargo (build|tree)\b(?!.*--offline)", bau + abschnitt("check"), re.M) is None,
      "jeder Aufruf von cargo build/tree mit --offline (kein Netz im Bau)")
check("set -o pipefail" in bau, "%build mit set -o pipefail (cargo tree in einer Pipe)")
check(re.search(r"^cargo tree --locked --offline -e normal,no-proc-macro --prefix none --format '\{p\}: \{l\}'", bau, re.M) is not None
      and "> LICENSE.dependencies" in bau, "%build: LICENSE.dependencies aus cargo tree (normal, ohne proc-macro)")
kopf = text.split("\n%global", 1)[0]
check("Kein Netz im Bau" in kopf and "Netz (Einstellung im COPR" not in kopf, "Kopfkommentar: kein Netz im Bau")
pruefung = abschnitt("check")
check("--version" in pruefung and "matugen %{version}" in pruefung, "%check: Fassung")
check("--prefer" in pruefung, "%check: Option --prefer vorhanden (P2)")
check("set -o pipefail" in pruefung and re.search(r"^cargo tree --locked --offline -e normal,no-proc-macro --prefix none --format '\{l\}'", pruefung, re.M) is not None
      and "awk -v feld='%{license}'" in pruefung and "im Baum, nicht im Feld License" in pruefung
      and "im Feld License, nicht im Baum" in pruefung and "exit 1" in pruefung,
      "%check: Lizenzabgleich cargo tree gegen das Feld License in beide Richtungen, bricht ab (P20)")
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
check("%license LICENSE.dependencies" in dateien, "%files: %license LICENSE.dependencies (Lizenzen der Crates)")

# packaging/fedora/matugen-vendor.sh: dieselbe Fassung und Prüfsumme wie die Spec, cargo vendor --locked, reproduzierbar
skript = open(os.path.join(REPO, "packaging", "fedora", "matugen-vendor.sh"), encoding="utf-8").read()
check(re.findall(r"^version=(\S+)$", skript, re.M) == version, "matugen-vendor.sh: Fassung = Version der Spec (%s)" % version)
check(re.findall(r"^quelle_sha256=([0-9a-f]{64})$", skript, re.M) == summe, "matugen-vendor.sh: Prüfsumme der Quelle = quelle_sha256 der Spec")
check('sha256sum -c -' in skript and skript.index("sha256sum -c -") < skript.index("tar -xzf"),
      "matugen-vendor.sh prüft die Quelle vor dem Entpacken")
check("cargo vendor --locked --versioned-dirs vendor" in skript, "matugen-vendor.sh: cargo vendor --locked --versioned-dirs")
check(all(o in skript for o in ("--sort=name", '--mtime="@$zeit"', "--owner=0", "--group=0", "--numeric-owner", "gzip -9 -n")),
      "matugen-vendor.sh packt reproduzierbar (Reihenfolge, Zeit, Besitzer, gzip ohne Name und Zeit)")
check("CARGO_HOME=\"$arbeit/cargo-home\"" in skript and "set -euo pipefail" in skript,
      "matugen-vendor.sh: CARGO_HOME im Temp-Ordner, set -euo pipefail")
check("-vendor.tar.gz" in skript and re.search(r'archiv="\$ziel/matugen-\$version-vendor\.tar\.gz"', skript) is not None,
      "matugen-vendor.sh: Archivname = Source1 der Spec")

# packaging/fedora/matugen.rpmlintrc: eigene Datei je Paket (P17), jeder Filter mit Kommentar darüber
rc_pfad = os.path.join(REPO, "packaging", "fedora", "matugen.rpmlintrc")
check(os.path.isfile(rc_pfad), "packaging/fedora/matugen.rpmlintrc vorhanden (P17)")
if os.path.isfile(rc_pfad):
    rc_zeilen = open(rc_pfad, encoding="utf-8").read().splitlines()
    ohne_grund = [z for i, z in enumerate(rc_zeilen) if z.startswith("addFilter(") and not (i and rc_zeilen[i - 1].startswith("#"))]
    check(any(z.startswith("addFilter(") for z in rc_zeilen) and not ohne_grund,
          "matugen.rpmlintrc: jeder Filter mit Begründung darüber (ohne: %s)" % ohne_grund)

print("\n%s" % ("alle Prüfungen bestanden" if not failures else "%d FEHLER" % failures))
sys.exit(1 if failures else 0)
