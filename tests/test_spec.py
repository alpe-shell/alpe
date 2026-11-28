#!/usr/bin/env python3
"""Alpe: packaging/fedora/alpe-shell.spec nach Plan 6.3 (E3; Nachtlauf vom 27.11.2026, Punkt 2.1).

    python3 tests/test_spec.py

Liest die Spec als Text (ohne rpm, ohne etwas zu bauen) und vergleicht mit Plan 6.3, Brand.qml und dem PKGBUILD: Name,
Version = Brand.version, Lizenzfeld inhaltlich wie license=() im PKGBUILD (mit AND verbunden), kein Conflicts,
Obsoletes oder Provides, keine Scriptlets und kein systemctl (das Paket schaltet keine Unit ein), kein BusName in der
Unit, keine fremden COPR-Namen, Requires/Recommends nach Plan 6.3 und den Entscheiden des Nachtlaufs, Archivname und
Ordner an genau einer Stelle (Makro), Bau mit make build, %check mit go test wie check() im PKGBUILD, make install mit
DESTDIR, %license mit den Lizenztexten aus make install, %files mit den Pfaden aus Plan 6.1.
"""
import os
import re
import shutil
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC = os.path.join(REPO, "packaging", "fedora", "alpe-shell.spec")
PKGBUILD = os.path.join(REPO, "packaging", "arch", "PKGBUILD")
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


text = open(SPEC, encoding="utf-8").read()
# Kommentare zählen für die Felder nicht
zeilen = [z for z in text.splitlines() if not z.lstrip().startswith("#")]
ohne_kommentar = "\n".join(zeilen)


def tags(name):
    return [m.group(1).strip() for m in re.finditer(r"^%s:\s*(.+)$" % re.escape(name), ohne_kommentar, re.M)]


def abschnitt(name):
    m = re.search(r"^%%%s\b.*?\n(.*?)(?=^%%(?:prep|build|install|check|files|changelog|pre|post|preun|postun|"
                  r"pretrans|posttrans|triggerin|triggerun)\b|\Z)" % name, ohne_kommentar, re.M | re.S)
    return m.group(1) if m else ""


brand = re.search(r'readonly property string version:\s*"([^"]+)"',
                  open(os.path.join(REPO, "shell", "Common", "Brand.qml"), encoding="utf-8").read()).group(1)
plan = open(os.path.join(REPO, "docs", "plan", "phase-a-plan.md"), encoding="utf-8").read()
plan63 = re.search(r"^### 6\.3 .*?(?=^### 6\.4 )", plan, re.M | re.S).group(0)
gomod = re.search(r"^go (\d+\.\d+(?:\.\d+)?)$", open(os.path.join(REPO, "core", "go.mod"), encoding="utf-8").read(), re.M).group(1)

check(tags("Name") == ["alpe-shell"], "Name: alpe-shell")
check(tags("Version") == [brand], "Version = Version aus Brand.qml (%s)" % brand)
check(len(tags("Release")) == 1 and tags("Release")[0].endswith("%{?dist}"), "Release mit %{?dist}")
check(sorted(tags("ExclusiveArch")[0].split()) == ["aarch64", "x86_64"] if tags("ExclusiveArch") else False,
      "ExclusiveArch: x86_64 aarch64 (Chroots fedora-45-aarch64 und fedora-45-x86_64, Plan 6.3)")

# Lizenzfeld: inhaltlich wie im PKGBUILD, in der Schreibweise von Fedora (SPDX mit AND)
if shutil.which("bash"):
    aus = subprocess.run(["bash", "-c", 'source "$1"; printf "%s\\n" "${license[@]}"', "lesen", PKGBUILD],
                         capture_output=True, text=True, env={"PATH": os.environ.get("PATH", "")})
    arch_lizenz = aus.stdout.split()
    check(aus.returncode == 0 and arch_lizenz, "PKGBUILD lässt sich mit bash lesen (license=)")
    check(tags("License") == [" AND ".join(arch_lizenz)],
          "License = license=() des PKGBUILD mit AND verbunden (%d Kennungen)" % len(arch_lizenz))
else:
    print("bash fehlt – Vergleich des Lizenzfelds mit dem PKGBUILD übersprungen")
lizenz = tags("License")[0] if tags("License") else ""
check(" OR " not in lizenz and "FTL" in lizenz.split(" AND ") and "GPL-3.0-only" in lizenz.split(" AND "),
      "License: FTL (gewählt, nicht FTL OR GPL-2.0-or-later) und GPL-3.0-only (0.8 Nr. 113, 114)")

# Kein Conflicts, Obsoletes oder Provides (Plan 6.2, 6.3: die Pakete teilen keine Datei)
for t in ("Conflicts", "Obsoletes", "Provides", "Epoch"):
    check(not tags(t), "kein %s:" % t)

# Keine Scriptlets, die eine Unit einschalten oder starten (Plan 6.1)
scriptlets = re.findall(r"^%(pre|post|preun|postun|pretrans|posttrans|triggerin|triggerun|systemd_\w+)\b", ohne_kommentar, re.M)
check(not scriptlets, "keine Scriptlets (%s)" % ", ".join(scriptlets) if scriptlets else "keine Scriptlets")
check("systemctl" not in ohne_kommentar, "kein systemctl in der Spec")
unit = open(os.path.join(REPO, "packaging", "systemd", "alpe.service"), encoding="utf-8").read()
check(re.search(r"^\s*BusName\s*=", unit, re.M) is None and "BusName" not in ohne_kommentar,
      "kein BusName= in der Unit und keiner aus der Spec (0.8 Nr. 120)")

# Keine fremden COPR-Namen: jede Nennung eines COPR in der Spec (auch in Kommentaren) ist alpe-shell/alpe
coprs = set(re.findall(r"COPR\s+([\w.-]+/[\w.-]+)", text, re.I))
check(coprs <= {"alpe-shell/alpe"}, "nur das eigene COPR alpe-shell/alpe genannt (%s)" % sorted(coprs))
fremd = [n for n in ("avengemedia", "errornointernet", "hazel-bunny", "lionheartp", "matinlotfali") if n in text.lower()]
check(not fremd and "copr.fedorainfracloud.org" not in text, "keine fremden COPR-Namen und keine COPR-Adresse (%s)" % fremd)

# Abhängigkeiten
requires = tags("Requires")
recommends = tags("Recommends")
suggests = tags("Suggests")
pflicht = ["quickshell >= 0.3.2", "matugen >= 4.1", "python3", "accountsservice", "qt6-qtmultimedia", "wireplumber",
           "kora-icon-theme", "breeze-icon-theme", "sound-theme-freedesktop"]
check(all(p in requires for p in pflicht), "Requires: Plan 6.3 und sound-theme-freedesktop (%s)" % [p for p in pflicht if p not in requires])
# matugen genau einmal und mit Mindestfassung 4.1, wie im PKGBUILD (0.8 Nr. 144) und in Plan 6.3
# Vergleich mit der Liste `Requires: …` in 6.3 selbst, nicht mit dem ganzen Abschnitt (die Begründung nennt die Grenze auch)
plan_requires = [r.strip() for r in re.search(r"`Requires: ([^`]*)`", plan63).group(1).split(",")]
check([r for r in requires if r.split()[0] == "matugen"] == ["matugen >= 4.1"]
      and [r for r in plan_requires if r.split()[0] == "matugen"] == ["matugen >= 4.1"],
      "Requires: matugen >= 4.1 genau einmal, wie in der Liste `Requires:` von Plan 6.3 (0.8 Nr. 144)")
check(not any(r.split()[0] in ("lua", "wtype") for r in requires), "Requires ohne lua und ohne wtype")
check(not any("kora-icon-theme" in r and r != "kora-icon-theme" for r in requires), "kora-icon-theme ohne Version (0.8 Nr. 99)")
plan_recommends = re.search(r"`Recommends: ([^`]*)`", plan63).group(1).replace(",", " ").split()
check(set(plan_recommends) <= set(recommends), "Recommends: Liste aus Plan 6.3 (%s)" % sorted(set(plan_recommends) - set(recommends)))
check("wtype" in recommends and "/usr/bin/dsearch" in recommends, "Recommends: wtype und /usr/bin/dsearch (0.8 Nr. 26)")
# Zweck von wtype als Kommentar direkt über der Zeile Recommends: wtype (0.8 Nr. 146)
wtype_kommentar = re.search(r"^#([^\n]*)\nRecommends:\s+wtype$", text, re.M)
check(wtype_kommentar is not None
      and "Texteingabe für eigene Befehle und fremde Plugins (nur Hyprland)" in wtype_kommentar.group(1),
      "Kommentar über Recommends: wtype nennt den Zweck «Texteingabe für eigene Befehle und fremde Plugins (nur Hyprland)»")
check(not set(recommends) & set(r.split()[0] for r in requires), "nichts zugleich in Requires und Recommends")
# Paketnamen einer Zeile ohne die Bedingung: «(a if b)» → a, «(a or b)» → a, b
def pakete(eintrag):
    ohne_bedingung = re.sub(r"\s+(if|unless)\s+.*$", "", eintrag.strip().strip("()"))
    return [p.split()[0] for p in re.split(r"\s+(?:or|and|with)\s+", ohne_bedingung) if p.split()]


check(not any("kwin" in p.lower() for s in suggests + recommends for p in pakete(s)),
      "keine KWin-Effekte (kein Paket in Fedora; kwin nur als Bedingung erlaubt)")
# Gegenstück zu optdepends plasma-workspace (Feststelltaste auf der KDE-Sperre, 0.8 Nr. 140): nur wenn KWin installiert
# ist (Entscheid P14 vom 28.11.2026; KWin heisst unter Fedora 45 «kwin»), nirgends unbedingt
check("(plasma-workspace if kwin)" in recommends, "Recommends: (plasma-workspace if kwin) (0.8 Nr. 140, P14)")
check(not any(p.split()[0] == "plasma-workspace" for p in requires + recommends + suggests),
      "plasma-workspace nirgends unbedingt (nicht in Requires, Recommends ohne Bedingung oder Suggests)")
plasma_kommentar = re.search(r"^#([^\n]*(?:\n#[^\n]*)*)\nRecommends:\s+\(plasma-workspace if kwin\)$", text, re.M)
check(plasma_kommentar is not None and "Feststelltaste" in plasma_kommentar.group(1)
      and "0.8 Nr. 140" in plasma_kommentar.group(1),
      "Kommentar über Recommends: (plasma-workspace if kwin) nennt die Feststelltaste und 0.8 Nr. 140")
# Suggests: die übrigen optdepends, nicht mehr vorläufig (0.8 Nr. 141 (8))
check("(power-profiles-daemon or tuned-ppd)" in suggests, "Suggests: Energieprofile als (power-profiles-daemon or tuned-ppd)")
check("vorläufig" not in text.lower(), "Suggests-Block (und die ganze Spec) nicht als vorläufig markiert")
build_requires = tags("BuildRequires")
check("golang >= %s" % gomod in build_requires, "BuildRequires: golang >= %s (core/go.mod)" % gomod)
check("make" in build_requires and "systemd-rpm-macros" in build_requires, "BuildRequires: make, systemd-rpm-macros")

# Archivname und Ordner an genau einer Stelle
quelle = re.findall(r"^%global quelle (\S+)$", ohne_kommentar, re.M)
check(len(quelle) == 1, "Makro «quelle» genau einmal definiert")
check(quelle == ["%{name}-%{version}"], "%global quelle %{name}-%{version} (Nachtlauf vom 28.11.2026, Punkt 1.2)")
# Derselbe Name wie das Archiv von make dist: DIST_NAME im Makefile (0.8 Nr. 132), mit Name: eingesetzt
makefile = open(os.path.join(REPO, "Makefile"), encoding="utf-8").read()
dist_name = re.findall(r"DIST_NAME := (\S+)\)", makefile)
erwarteter_name = dist_name[0].replace("$(DIST_VERSION)", "<v>") if len(dist_name) == 1 else None
spec_name = (quelle[0].replace("%{name}", tags("Name")[0] if tags("Name") else "?").replace("%{version}", "<v>")
             if quelle else None)
check(erwarteter_name is not None and spec_name == erwarteter_name,
      "Archivname der Spec = DIST_NAME im Makefile (%s gegen %s)" % (spec_name, erwarteter_name))
ausserhalb = ohne_kommentar.replace("%global quelle " + (quelle[0] if quelle else ""), "")
check(re.search(r"(alpe(-shell)?|%\{name\})-%\{version\}", ausserhalb) is None,
      "Archiv- und Ordnername nur im Makro, sonst nirgends ausgeschrieben (auch nicht als %{name}-%{version})")
check(any(s.endswith("/%{quelle}.tar.gz") for s in tags("Source0")), "Source0: %{quelle}.tar.gz aus dem Release")
check(re.search(r"^%autosetup -n %\{quelle\}$", abschnitt("prep"), re.M) is not None, "%prep: %autosetup -n %{quelle}")

# Bau, Prüfung, Installation wie im PKGBUILD
bau = abschnitt("build")
check(re.search(r"^%\{__make\} build\b", bau, re.M) is not None, "%build: make build")
for name, inhalt in (("%build", bau), ("%check", abschnitt("check"))):
    check("-mod=vendor" in inhalt and "-trimpath" in inhalt and "-buildmode=pie" in inhalt and "GOPROXY=off" in inhalt
          and "CGO_ENABLED=0" in inhalt, "%s: GOFLAGS -mod=vendor -trimpath -buildmode=pie, GOPROXY=off, CGO_ENABLED=0" % name)
pruefen = abschnitt("check")
check("cd core" in pruefen and "go test -count=1 ./..." in pruefen and 'HOME="$heim"' in pruefen
      and "XDG_RUNTIME_DIR=" in pruefen and "-u DBUS_SESSION_BUS_ADDRESS" in pruefen,
      "%check: go test ./... in core, eigenes Home und XDG-Ordner, ohne Session-Bus (wie check() im PKGBUILD)")
# XDG_RUNTIME_DIR nicht im Bauordner: Dort werden die Socket-Pfade der dmenu-Tests zu lang (Nachtlauf vom 28.11.2026,
# 1.1). Entscheid P12: kurzer Ordner aus mktemp -d unter /tmp, trap räumt ihn weg.
laufzeit_wert = re.findall(r'XDG_RUNTIME_DIR="?([^"\s]+)"?', pruefen)
laufzeit_var = re.fullmatch(r"\$\{?(\w+)\}?", laufzeit_wert[0]).group(1) if len(laufzeit_wert) == 1 and re.fullmatch(r"\$\{?\w+\}?", laufzeit_wert[0]) else None
laufzeit_zuweisung = re.findall(r"^%s=(.+)$" % re.escape(laufzeit_var), pruefen, re.M) if laufzeit_var else []
check(len(laufzeit_wert) == 1 and laufzeit_var is not None and laufzeit_var != "heim"
      and laufzeit_zuweisung == ["$(mktemp -d /tmp/alpe-check.XXXXXX)"],
      "%%check: XDG_RUNTIME_DIR aus mktemp -d unter /tmp (%s = %s), nicht unter dem Bauordner"
      % (laufzeit_wert, laufzeit_zuweisung))
check(not any(s in (laufzeit_wert[0] if laufzeit_wert else "") + "".join(laufzeit_zuweisung)
              for s in ("%{_builddir}", "$heim", "%{buildroot}", "RPM_BUILD_DIR")),
      "%check: XDG_RUNTIME_DIR enthält weder %{_builddir} noch $heim noch den Buildroot")
check(laufzeit_var is not None and re.search(r"""^trap 'rm -rf "\$%s"' EXIT$""" % re.escape(laufzeit_var), pruefen, re.M) is not None,
      "%check: trap 'rm -rf …' EXIT räumt den Laufzeitordner auch nach rotem go test weg (P12)")
check(re.search(r"^%\{__make\} install DESTDIR=%\{buildroot\} PREFIX=%\{_prefix\}$", abschnitt("install"), re.M) is not None,
      "%install: make install DESTDIR=%{buildroot} PREFIX=%{_prefix}")

# %files: Lizenztexte aus make install als %license, Pfade aus Plan 6.1
dateien = abschnitt("files")
for datei in ("LICENSE", "NOTICE", "GPL-3.0-only.txt", "FTL.txt"):
    check(re.search(r"^%%license %%\{lizenzdir\}/%s$" % re.escape(datei), dateien, re.M) is not None, "%%license %s" % datei)
# Die Texte der vendorten Go-Module (make install, 0.8 Nr. 131) als ganzer Ordner, keine einzelnen Dateien darunter
check(re.search(r"^%license %\{lizenzdir\}/vendor/$", dateien, re.M) is not None,
      "%license %{lizenzdir}/vendor/ (Lizenztexte der vendorten Go-Module, als Ordner)")
check(re.search(r"^%license %\{lizenzdir\}/vendor/\S", dateien, re.M) is None,
      "keine einzelnen Dateien unter %{lizenzdir}/vendor/ in %files")
check(re.search(r"^%global lizenzdir %\{_defaultlicensedir\}/%\{name\}$", ohne_kommentar, re.M) is not None,
      "Makro für den Lizenzpfad (/usr/share/licenses/alpe-shell)")
check(re.search(r"^%dir %\{lizenzdir\}$", dateien, re.M) is not None,
      "%dir %{lizenzdir} (der Lizenzordner gehört dem Paket; Nachtlauf vom 28.11.2026, 1.2)")
check(re.search(r"^%doc\s", dateien, re.M) is not None, "%doc vorhanden")
erwartet = ["%{_bindir}/alpe-dienst", "%{_bindir}/alpe", "%{_datadir}/alpe/", "%{_datadir}/plasma/shells/org.alpe.desktop/",
            "%{_userunitdir}/alpe.service", "%{_datadir}/applications/io.github.alpe_shell.Alpe.desktop",
            "%{_datadir}/applications/io.github.alpe_shell.Alpe.Notepad.desktop", "%{_datadir}/applications/alpe-open.desktop",
            "%{_datadir}/icons/hicolor/scalable/apps/io.github.alpe_shell.Alpe.svg", "%{bash_completions_dir}/alpe-dienst",
            "%{zsh_completions_dir}/_alpe-dienst", "%{fish_completions_dir}/alpe-dienst.fish"]
vorhanden = [z.strip() for z in dateien.splitlines()]
check(all(e in vorhanden for e in erwartet), "%%files: Pfade aus Plan 6.1 (%s)" % [e for e in erwartet if e not in vorhanden])

# rpmlintrc (Nachtlauf vom 29.11.2026, 1.1): statisch gelinkter Dienst und die Skripte ohne Ausführungsrecht einzeln,
# kein Filter für ganze Ordner; jeder Skript-Filter nennt eine Datei, die im Repository ohne x-Recht und mit Shebang liegt
rc_text = open(os.path.join(REPO, "packaging", "fedora", "alpe-shell.rpmlintrc"), encoding="utf-8").read()
filter_ = re.findall(r'^addFilter\(r?"([^"]*)"\)$', rc_text, re.M)
check(r"statically-linked-binary /usr/bin/alpe-dienst$" in filter_, "rpmlintrc: statically-linked-binary nur für /usr/bin/alpe-dienst")
skript_filter = [f for f in filter_ if f.startswith("non-executable-script ")]
falsch = []
for f in skript_filter:
    m = re.fullmatch(r"non-executable-script /usr/share/alpe/((?:shell/scripts|tools)/[\w.-]+) ", f.replace("\\.", "."))
    pfad = os.path.join(REPO, m.group(1)) if m else None
    if not (pfad and os.path.isfile(pfad) and not os.stat(pfad).st_mode & 0o111
            and open(pfad, "rb").read(2) == b"#!"):
        falsch.append(f)
check(len(skript_filter) == 13 and not falsch,
      "rpmlintrc: 13 Skripte einzeln gefiltert, je eine Datei ohne x-Recht mit Shebang im Repository (falsch: %s)" % falsch)
check(not any(re.search(r"/\s*$|/\)|\.\*|\(\w+\|", f) for f in filter_ if f.startswith("non-executable-script")),
      "rpmlintrc: kein Filter für ganze Ordner oder mit Mustern")

print("\n%s" % ("alle Prüfungen bestanden" if not failures else "%d FEHLER" % failures))
sys.exit(1 if failures else 0)
