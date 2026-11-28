#!/usr/bin/env python3
"""Alpe: packaging/arch/PKGBUILD nach Plan 6.2 (E2; Nachtlauf vom 26.11.2026, Punkt 2.1).

    python3 tests/test_pkgbuild.py

Liest das PKGBUILD mit bash (ohne makepkg und ohne etwas zu bauen) und vergleicht es mit Plan 6.2: Name, Architekturen,
depends (Liste aus 6.2 und kora-icon-theme, quickshell>=0.3.2, kein lua), makedepends, optdepends, kein conflicts und
kein replaces, das Lizenzfeld wie in 6.2 festgelegt, Quelle das Archiv von make dist, und die Schritte: make build,
go test im Ordner core mit -mod=vendor ohne Netz und eigenem Home, make install mit DESTDIR und PREFIX=/usr.
Dazu der CI-Job «arch-paket» (Plan 9, 0.8 Nr. 127): archlinux:latest, Bau aus dem Archiv von make dist, makepkg -s als
eigener Benutzer ohne -d, namcap, kora aus dem AUR, Token nur lesend, Zeitgrenze.
"""
import os
import re
import shutil
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PKGBUILD = os.path.join(REPO, "packaging", "arch", "PKGBUILD")
failures = 0


def check(cond, msg):
    global failures
    print(("ok    " if cond else "FEHLER ") + msg)
    failures += 0 if cond else 1


if not shutil.which("bash"):
    print("bash fehlt – übersprungen")
    sys.exit(0)

# Arrays und Funktionen ausgeben, ohne etwas auszuführen: PKGBUILD in einer leeren Umgebung lesen.
lesen = r'''
set -e
source "$1"
for name in pkgname pkgver arch license depends makedepends optdepends conflicts replaces provides source sha256sums options; do
    declare -n wert="$name" 2>/dev/null || continue
    printf '%s=' "$name"; printf '%s\x1f' "${wert[@]}"; printf '\n'
done
for f in build check package; do printf '== %s\n' "$f"; declare -f "$f"; done
declare -f _go_umgebung
'''
aus = subprocess.run(["bash", "-c", lesen, "lesen", PKGBUILD], capture_output=True, text=True, env={"PATH": os.environ.get("PATH", "")})
check(aus.returncode == 0, "PKGBUILD lässt sich mit bash lesen (rc %d) %s" % (aus.returncode, aus.stderr[-300:]))
felder = {}
for zeile in aus.stdout.splitlines():
    m = re.match(r"^(\w+)=(.*)$", zeile)
    if m and m.group(1) in ("pkgname", "pkgver", "arch", "license", "depends", "makedepends", "optdepends", "conflicts",
                            "replaces", "provides", "source", "sha256sums", "options"):
        felder[m.group(1)] = [w for w in m.group(2).split("\x1f") if w]
funktionen = aus.stdout

plan = open(os.path.join(REPO, "docs", "plan", "phase-a-plan.md"), encoding="utf-8").read()
abschnitt = re.search(r"^### 6\.2 .*?(?=^### 6\.3 )", plan, re.M | re.S).group(0)
plan_depends = re.search(r"`depends=\(([^)]*)\)`", abschnitt).group(1).split()
plan_license = re.search(r"\*\*Umgesetzt in E2.*?`license=\(([^)]*)\)`", abschnitt, re.S).group(1).split()
plan_optdepends = re.findall(r"`([a-z0-9][a-z0-9.+-]*)`", re.search(r"^- `optdepends`:(.*?)(?=^- )", abschnitt, re.M | re.S).group(1))
brand = re.search(r'readonly property string version:\s*"([^"]+)"', open(os.path.join(REPO, "shell", "Common", "Brand.qml"), encoding="utf-8").read()).group(1)

check(felder.get("pkgname") == ["alpe-shell"], "pkgname=alpe-shell")
check(felder.get("pkgver") == [brand], "pkgver = Version aus Brand.qml (%s; entschieden, Plan 0.8 Nr. 134)" % brand)
check(sorted(felder.get("arch", [])) == ["aarch64", "x86_64"], "arch=(x86_64 aarch64)")
depends = felder.get("depends", [])
check(sorted(depends) == sorted(plan_depends + ["kora-icon-theme"]),
      "depends = Liste aus Plan 6.2 und kora-icon-theme (0.8 Nr. 91): %s" % sorted(set(depends) ^ set(plan_depends + ["kora-icon-theme"])))
check("quickshell>=0.3.2" in depends and {"wireplumber", "breeze-icons", "hicolor-icon-theme", "kora-icon-theme"} <= set(depends)
      and not any(d == "lua" or d.startswith("lua") for d in depends), "depends: quickshell>=0.3.2, wireplumber, breeze-icons, hicolor-icon-theme, kora, kein lua")
# ausdrücklich, nicht nur über die Liste im Plan: Klänge aus dem System (0.8 Nr. 128), wtype nur optional (Nr. 133)
check("sound-theme-freedesktop" in depends and "wtype" not in depends
      and any(o.startswith("wtype: ") for o in felder.get("optdepends", [])),
      "sound-theme-freedesktop in depends (Nr. 128); wtype nicht in depends, sondern in optdepends mit Zweck (Nr. 133)")
check(sorted(felder.get("makedepends", [])) == ["git", "go", "make"], "makedepends=(go make git)")
opt = [o.split(":", 1)[0] for o in felder.get("optdepends", [])]
check(set(plan_optdepends) <= set(opt) and set(opt) - set(plan_optdepends) <= {"dsearch"} and all(":" in o for o in felder.get("optdepends", [])),
      "optdepends = Liste aus Plan 6.2 und dsearch (0.8 Nr. 26), je mit Zweck: %s" % sorted(set(opt) ^ set(plan_optdepends)))
check(not felder.get("conflicts") and not felder.get("replaces"), "kein conflicts und kein replaces (Plan 6.2)")
check(felder.get("license") == plan_license, "license = das in Plan 6.2 festgelegte Feld (%d Kennungen)" % len(plan_license))
check(felder.get("source") == ["https://github.com/alpe-shell/alpe/releases/download/v%s/alpe-shell-%s.tar.gz" % (brand, brand)],
      "Quelle: das Archiv von make dist (alpe-shell-<Version>.tar.gz, Plan 0.8 Nr. 132) aus dem Release")
check(funktionen.count('cd "$pkgname-$pkgver') == 3 and "alpe-$pkgver" not in funktionen,
      "build/check/package wechseln in den Ordner alpe-shell-<Version>/ des Archivs ($pkgname-$pkgver)")
check("make build" in funktionen.split("== build", 1)[1].split("== check", 1)[0], "build(): make build")
pruefen = funktionen.split("== check", 1)[1].split("== package", 1)[0]
check('cd "$pkgname-$pkgver/core"' in pruefen and "go test -count=1 ./..." in pruefen and 'HOME="$heim"' in pruefen
      and "XDG_RUNTIME_DIR=" in pruefen and "-u DBUS_SESSION_BUS_ADDRESS" in pruefen,
      "check(): go test ./... in core, mit eigenem Home und XDG-Ordnern, ohne Session-Bus")
umgebung = funktionen.split("_go_umgebung ()", 1)[-1]
check("-mod=vendor" in umgebung and "-trimpath" in umgebung and "GOPROXY=off" in umgebung and "CGO_ENABLED=0" in umgebung
      and "-buildmode=pie" in umgebung,
      "Go-Umgebung: GOFLAGS -mod=vendor -trimpath -buildmode=pie, GOPROXY=off (ohne Netz), CGO_ENABLED=0 (Plan 6.2)")
check('make install DESTDIR="$pkgdir" PREFIX=/usr' in funktionen.split("== package", 1)[1], 'package(): make install DESTDIR="$pkgdir" PREFIX=/usr')

# CI (Plan 9, 0.8 Nr. 127): eigener Job, der das PKGBUILD in archlinux:latest aus dem Archiv von make dist baut, mit
# makepkg (nie als root) und namcap. Ohne YAML-Parser (in der CI nicht installiert): der Block des Jobs bis zum nächsten.
workflow = open(os.path.join(REPO, ".github", "workflows", "tests.yml"), encoding="utf-8").read()
job = re.search(r"^  arch-paket:\n(.*?)(?=^  \S|\Z)", workflow, re.M | re.S)
check(job is not None, "CI: eigener Job «arch-paket»")
if job:
    text = job.group(1)
    check(re.search(r"^    container: archlinux:latest$", text, re.M) is not None, "CI-Job läuft im Container archlinux:latest")
    check("make dist" in text and "cp packaging/arch/PKGBUILD /tmp/alpe-dist/alpe-shell-*.tar.gz" in text,
          "CI-Job baut aus dem Archiv von make dist, das neben dem PKGBUILD liegt")
    # -d auch in zusammengezogenen Kurzoptionen (-sd, -sdi) – Prüfung zu 2.4
    check("sudo -u bauer makepkg -s --noconfirm" in text and not re.search(r"^\s*makepkg", text, re.M) and "--nodeps" not in text
          and not re.search(r"makepkg[^\n]*\s-[A-Za-z]*d", text),
          "CI-Job: makepkg -s als eigener Benutzer, nie als root, ohne -d/--nodeps")
    check(re.search(r"uses: actions/checkout@v\d+\n\s+with:\n\s+persist-credentials: false", text) is not None
          and re.search(r"^    permissions:\n      contents: read$", text, re.M) is not None,
          "CI-Job: Token nur lesend und nicht im Arbeitsbaum (fremder Code aus dem AUR läuft im Job)")
    check(re.search(r"^    timeout-minutes: \d+$", text, re.M) is not None, "CI-Job: mit Zeitgrenze")
    check("namcap PKGBUILD" in text and "namcap alpe-shell-*.pkg.tar.zst" in text, "CI-Job: namcap auf PKGBUILD und Paket")
    check("aur.archlinux.org/kora-icon-theme.git" in text, "CI-Job: kora-icon-theme aus dem AUR (Abhängigkeit, nicht in den Paketquellen)")
    # Plan 0.8 Nr. 137: auf einen Commit des AUR-Repositorys festgenagelt, vor makepkg (Lieferkette, Wiederholbarkeit)
    kora = re.search(r"git clone (?:--depth \d+ )?https://aur\.archlinux\.org/kora-icon-theme\.git (\S+)\n(.*?)makepkg -si", text, re.S)
    check(kora is not None and "--depth" not in kora.group(0)
          and re.search(r"git (?:-c \S+ )?checkout [0-9a-f]{40}\n", kora.group(2)) is not None,
          "CI-Job: kora-icon-theme auf einen vollen Commit des AUR-Repositorys festgenagelt (checkout vor makepkg, Nr. 137)")
    check("python3 tests/test_makefile.py" not in text, "CI-Job ruft tests/test_makefile.py nicht auf (der Check in test_makefile.py verlangt genau einen Aufruf)")

print("\n%s" % ("alle Prüfungen bestanden" if not failures else "%d FEHLER" % failures))
sys.exit(1 if failures else 0)
