#!/usr/bin/env python3
"""Alpe: packaging/fedora/quickshell.spec für das COPR alpe-shell/alpe (Plan 6.3, 0.8 Nr. 97; E3, Nachtlauf vom
28.11.2026, Punkt 2.1).

    python3 tests/test_spec_quickshell.py

Liest die Spec als Text (ohne rpm): Name quickshell, Version 0.3.2 und damit nicht unter der Untergrenze, die
alpe-shell.spec verlangt; Release nicht unter 0.3.2-4 eines fremden COPR; Quelle das Archiv des Tags mit Prüfsumme,
die vor dem Entpacken geprüft wird; Herkunft und Lizenz der Vorlage im Kopf; Lizenzfeld nach dem Quelltext (P7);
Crash-Handler aus, jemalloc an und in %check geprüft, DISTRIBUTOR für das eigene COPR; keine Epoch/Obsoletes/
Conflicts, keine Scriptlets, keine fremden COPR-Namen.
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC = os.path.join(REPO, "packaging", "fedora", "quickshell.spec")
ALPE_SPEC = os.path.join(REPO, "packaging", "fedora", "alpe-shell.spec")
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


text = open(SPEC, encoding="utf-8").read()
ohne_kommentar = "\n".join(z for z in text.splitlines() if not z.lstrip().startswith("#"))
kopf = "\n".join(z for z in text.splitlines()[:30] if z.startswith("#"))


def tags(name):
    return [m.group(1).strip() for m in re.finditer(r"^%s:\s*(.+)$" % re.escape(name), ohne_kommentar, re.M)]


def abschnitt(name):
    m = re.search(r"^%%%s\b.*?\n(.*?)(?=^%%(?:prep|conf|build|install|check|files|changelog|pre|post|preun|postun)\b|\Z)"
                  % name, ohne_kommentar, re.M | re.S)
    return m.group(1) if m else ""


def zahlen(v):
    return tuple(int(x) for x in v.split("."))


check(tags("Name") == ["quickshell"], "Name: quickshell (alpe-shell verlangt genau diesen Namen)")
version = tags("Version")
check(version == ["0.3.2"], "Version: 0.3.2 (%s)" % version)
mindest = re.findall(r"^Requires:\s*quickshell\s*>=\s*([\d.]+)\s*$", open(ALPE_SPEC, encoding="utf-8").read(), re.M)
check(len(mindest) == 1 and version and zahlen(version[0]) >= zahlen(mindest[0]),
      "Version nicht unter der Untergrenze in alpe-shell.spec (%s)" % mindest)
release = tags("Release")
m = re.fullmatch(r"(\d+)%\{\?dist\}", release[0]) if len(release) == 1 else None
check(m is not None and int(m.group(1)) > 4,
      "Release über 4 (fremdes COPR liefert 0.3.2-4; bei Gleichstand entschiede nicht die Version) (%s)" % release)
check(tags("License") == ["LGPL-3.0-only AND BSD-3-Clause AND HPND-sell-variant AND MIT"],
      "License nach dem Quelltext (P7): LGPL-3.0-only AND BSD-3-Clause AND HPND-sell-variant AND MIT")
quelle = tags("Source0")
check(len(quelle) == 1 and quelle[0].startswith("https://git.outfoxxed.me/%{name}/%{name}/archive/v%{version}.tar.gz"),
      "Source0: Archiv des Tags v%{version} beim Ursprung")
summe = re.findall(r"^%global quelle_sha256 ([0-9a-f]{64})$", ohne_kommentar, re.M)
check(len(summe) == 1, "Prüfsumme sha256 als Makro festgehalten")
prep = abschnitt("prep")
check('echo "%{quelle_sha256}  %{SOURCE0}" | sha256sum -c -' in prep and "%autosetup" in prep
      and prep.index("sha256sum") < prep.index("%autosetup"), "%prep prüft die Prüfsumme vor dem Entpacken")
check(re.search(r"^%global commit [0-9a-f]{40}$", ohne_kommentar, re.M) is not None
      and "-DGIT_REVISION=%{commit}" in abschnitt("conf"), "GIT_REVISION aus dem festen Commit des Tags")
check("rpms/quickshell" in kopf and "f45" in kopf and re.search(r"\b[0-9a-f]{40}\b", kopf) is not None,
      "Kopf nennt die Vorlage: dist-git rpms/quickshell, Zweig f45, Commit")
check("MIT" in kopf and "Contributor Agreement" in kopf, "Kopf nennt die Lizenz der Vorlage (MIT nach FPCA)")
conf = abschnitt("conf")
check("-DCRASH_HANDLER=OFF" in conf, "-DCRASH_HANDLER=OFF (cpptrace fehlt in Fedora)")
check("-DUSE_JEMALLOC=ON" in conf, "-DUSE_JEMALLOC=ON")
check('-DDISTRIBUTOR="Fedora COPR (alpe-shell/alpe)"' in conf, "DISTRIBUTOR nennt das eigene COPR")
check("CRASH_REPORTER" not in ohne_kommentar and "breakpad" not in ohne_kommentar,
      "kein Schalter CRASH_REPORTER/breakpad (gibt es in 0.3.x nicht)")
br = tags("BuildRequires")
check("pkgconfig(jemalloc)" in br, "BuildRequires: pkgconfig(jemalloc)")
check("libjemalloc" in abschnitt("check") and "readelf" in abschnitt("check"), "%check prüft, dass jemalloc gelinkt ist")
check("binutils" in br, "BuildRequires: binutils (readelf in %check)")
check("qt6-qtsvg%{?_isa}" in tags("Requires"), "Requires: qt6-qtsvg (SVG-Bilder und -Symbole, BUILD.md)")
for t in ("Epoch", "Obsoletes", "Conflicts"):
    check(not tags(t), "kein %s:" % t)
check(sorted(p.split()[0] for p in tags("Provides")) == ["PolicyKit-authentication-agent", "desktop-notification-daemon"],
      "Provides nur die zwei virtuellen der Vorlage")
scriptlets = re.findall(r"^%(pre|post|preun|postun|pretrans|posttrans)\b", ohne_kommentar, re.M)
check(not scriptlets, "keine Scriptlets")
coprs = set(re.findall(r"COPR\s+\(?([\w.-]+/[\w.-]+)", text, re.I))
check(coprs <= {"alpe-shell/alpe"} and "copr.fedorainfracloud.org" not in text, "nur das eigene COPR genannt (%s)" % sorted(coprs))
dateien = [z.strip() for z in abschnitt("files").splitlines()]
for d in ("%{_bindir}/qs", "%{_bindir}/quickshell", "%license LICENSE*", "%{_qt6_qmldir}/Quickshell/"):
    check(d in dateien, "%%files: %s" % d)

print("\n%s" % ("alle Prüfungen bestanden" if not failures else "%d FEHLER" % failures))
sys.exit(1 if failures else 0)
