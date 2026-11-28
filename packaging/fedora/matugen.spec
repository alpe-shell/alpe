# matugen für das COPR alpe-shell/alpe (Plan 6.3; E3, Entscheide P2, P19, P20, P21 vom 28.11.2026)
#
# alpe-shell verlangt «matugen >= 4.1»: Das ausgelieferte Design nutzt --prefer (ab 4.1); Fedora hat nur 3.1.0
# (rust-matugen). Gebaut wird das Release 4.2.0.
#
# Kein Netz im Bau: Die Crates kommen aus Source1, einem Archiv des Ordners vendor/, das
# packaging/fedora/matugen-vendor.sh mit «cargo vendor --locked» aus Source0 erzeugt (reproduzierbar gepackt; Weg in
# packaging/fedora/LIESMICH.md). Beide Archive werden vor dem Entpacken gegen ihre sha256 geprüft; gebaut wird mit
# «cargo build --release --locked --offline». Damit enthält das SRPM den Quelltext aller gelinkten Crates (P19).
#
# Lizenzfeld: GPL-2.0-or-later für matugen selbst (Cargo.toml, README, LICENSE = GPL-2.0-Text), dazu die Lizenzen der
# 187 Crates, die für aarch64 und x86_64 gleich gelinkt werden – ermittelt im mock-Chroot mit
# «cargo tree --locked -e normal,no-proc-macro --target <Ziel> --format '{p}|{l}'» (Nachtlauf vom 28.11.2026, Punkt
# 3.1). Jeder Ausdruck steht so, wie das Crate ihn angibt; die alte Schreibweise «A/B» ist als «A OR B» geschrieben,
# ein Ausdruck mit AND auf oberster Ebene in seine Teile zerlegt. Die Liste ist eine Obergrenze nur gegenüber dem
# Linker: Was er verwirft, bleibt im Feld. Anders als Fedoras Makro cargo_license (dort --target all) zählt nur das
# Ziel des Bauhosts. Die Prüfung nach dem Bau vergleicht das Feld mit cargo tree und bricht bei jeder Abweichung ab
# (P20); LICENSE.dependencies nennt jedes Crate mit seiner Lizenz.
#
# Release über dem matugen 4.2.0-1 eines fremden COPR (Nachtlauf vom 28.11.2026, Punkt 2.3, «Für den Plan»).

%global quelle_sha256 82044ab8ac3e793b2b94f8f75917b348b4038585133a77c07f5de59c88d65244
# Source1 aus packaging/fedora/matugen-vendor.sh (Nachtlauf vom 29.11.2026, Punkt 2.1; zweimal erzeugt, bytegleich)
%global vendor_sha256 5c5ffd861dbb9f31a3f2c08e79439f5abaaf40175b1813fb514b6bdaaf0d55d4

Name:           matugen
Version:        4.2.0
Release:        2%{?dist}
Summary:        Farbschemata nach Material You und base16 aus einem Bild, mit Vorlagen
License:        GPL-2.0-or-later AND (0BSD OR MIT OR Apache-2.0) AND Apache-2.0 AND (Apache-2.0 OR BSL-1.0) AND (Apache-2.0 OR MIT) AND (Apache-2.0 WITH LLVM-exception OR Apache-2.0 OR MIT) AND BSD-2-Clause AND (BSD-2-Clause OR Apache-2.0 OR MIT) AND BSD-3-Clause AND (BSD-3-Clause OR Apache-2.0) AND (BSD-3-Clause OR MIT) AND (CC0-1.0 OR Apache-2.0) AND MIT AND (MIT OR Apache-2.0) AND (MIT OR Apache-2.0 OR CC0-1.0) AND (MIT OR Apache-2.0 OR Zlib) AND (MIT OR Zlib OR Apache-2.0) AND MPL-2.0 AND Unicode-DFS-2016 AND (Unlicense OR MIT) AND Zlib AND (Zlib OR Apache-2.0 OR MIT)
URL:            https://github.com/InioX/matugen
# Release v4.2.0 (Tag-Commit bb27a35d7f9e0f57cf638703f3d8e3182aed0304)
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
# Crates aus Cargo.lock, vendort (packaging/fedora/matugen-vendor.sh); liegt nicht im Repository
Source1:        %{name}-%{version}-vendor.tar.gz

ExclusiveArch:  x86_64 aarch64

BuildRequires:  cargo
BuildRequires:  rust
BuildRequires:  gcc
# Fedoras Rust-Schalter für den Bau mit cargo (build_rustflags aus macros.rust: Optimierung, Debuginfo, kein Strip)
BuildRequires:  cargo-rpm-macros

%description
matugen erzeugt aus einem Bild oder einer Farbe Farbschemata nach Material
You und base16 und füllt damit Vorlagen für Programme. Alpe ruft es für das
Farbschema der Oberfläche auf.

%prep
echo "%{quelle_sha256}  %{SOURCE0}" | sha256sum -c -
echo "%{vendor_sha256}  %{SOURCE1}" | sha256sum -c -
# Source1 entpackt nach vendor/ im Quellordner
%autosetup -n %{name}-%{version} -a 1
# Cargo nimmt die Crates nur aus vendor/ (wie die Ausgabe von cargo vendor; matugen-vendor.sh zeigt sie)
mkdir -p .cargo
printf '%%s\n' '[source.crates-io]' 'replace-with = "vendored-sources"' '' '[source.vendored-sources]' \
  'directory = "vendor"' > .cargo/config.toml
# Manche Crates liefern .rs-Dateien mit x-Recht; im Debug-Quellpaket hält brp-mangle-shebangs dann «#![no_std]» für
# einen Shebang und bricht ab (Nachtlauf vom 29.11.2026, 2.3). cargo prüft nur den Inhalt (.cargo-checksum.json).
find vendor -type f -name '*.rs' -perm /111 -exec chmod a-x {} +

%build
set -o pipefail
# Ohne Netz, genau nach Cargo.lock, aus vendor/ (P19); Ablage im Bauordner, nicht im Home des Bauenden;
# höchstens %%{_smp_build_ncpus} Jobs (P21: am Mac mit 8 GB reichte der Speicher sonst nicht)
export CARGO_HOME=%{_builddir}/%{name}-%{version}-cargo-home
export RUSTFLAGS='%{build_rustflags}'
cargo build --release --locked --offline -j%{_smp_build_ncpus}
# Lizenz je gelinktem Crate (ohne matugen selbst, ohne Wiederholungen «(*)»), wie Fedoras cargo_license
cargo tree --locked --offline -e normal,no-proc-macro --prefix none --format '{p}: {l}' \
  | awk '!/ \(\*\)$/ && !/^matugen v/' | sort -u > LICENSE.dependencies

%install
install -Dpm0755 target/release/%{name} %{buildroot}%{_bindir}/%{name}

%check
set -o pipefail
export CARGO_HOME=%{_builddir}/%{name}-%{version}-cargo-home
# Fassung und die Option, die das Design von Alpe braucht (P2)
%{buildroot}%{_bindir}/%{name} --version | grep -qx 'matugen %{version}'
%{buildroot}%{_bindir}/%{name} --help | grep -q -- '--prefer'
# Lizenzabgleich (P20): Die Ausdrücke aus cargo tree (samt matugen selbst) und das Feld License, beide an oberster
# Ebene bei « AND » zerlegt, «A/B» als «A OR B», jeder Ausdruck mit OR in Klammern, müssen gleich sein. Eine neue oder
# weggefallene Lizenz bricht den Bau.
cargo tree --locked --offline -e normal,no-proc-macro --prefix none --format '{l}' \
  | awk '{ sub(/ \(\*\)$/, ""); print }' | sort -u > lizenzen-baum.txt
awk -v feld='%{license}' '
function teile(s, a,    n, i, d, start, c) {
  n = 0; d = 0; start = 1
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == "(") d++
    else if (c == ")") d--
    else if (d == 0 && substr(s, i, 5) == " AND ") { a[++n] = substr(s, start, i - start); start = i + 5; i += 4 }
  }
  a[++n] = substr(s, start)
  return n
}
function norm(t,    d, i, c, ganz) {
  gsub("/", " OR ", t)
  while (t ~ /^\(/ && t ~ /\)$/) {
    d = 0; ganz = 1
    for (i = 1; i < length(t); i++) {
      c = substr(t, i, 1)
      if (c == "(") d++
      else if (c == ")") { d--; if (d == 0) { ganz = 0; break } }
    }
    if (!ganz) break
    t = substr(t, 2, length(t) - 2)
  }
  if (t ~ / OR /) t = "(" t ")"
  return t
}
BEGIN { n = teile(feld, f); for (i = 1; i <= n; i++) soll[norm(f[i])] = 1 }
NF { n = teile($0, b); for (i = 1; i <= n; i++) ist[norm(b[i])] = 1 }
END {
  fehler = 0
  for (k in ist) if (!(k in soll)) { print "im Baum, nicht im Feld License: " k; fehler = 1 }
  for (k in soll) if (!(k in ist)) { print "im Feld License, nicht im Baum: " k; fehler = 1 }
  if (fehler) exit 1
  print "Lizenzabgleich: " length(ist) " Ausdrücke, Feld License und cargo tree gleich"
}' lizenzen-baum.txt

%files
%license LICENSE
%license LICENSE.dependencies
%doc README.md CHANGELOG.md
%{_bindir}/%{name}

%changelog
* Sat Nov 28 2026 Alpe <alpe-shell@users.noreply.github.com> - 4.2.0-2
- Erste Spec für das COPR alpe-shell/alpe (Plan 6.3, E3)
- Crates vendort als Source1, Bau ohne Netz, LICENSE.dependencies, Lizenzabgleich im %%check
