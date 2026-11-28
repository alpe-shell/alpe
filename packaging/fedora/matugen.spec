# matugen für das COPR alpe-shell/alpe (Plan 6.3; E3, Entscheide P2 und P6 vom 28.11.2026)
#
# alpe-shell verlangt «matugen >= 4.1»: Das ausgelieferte Design nutzt --prefer (ab 4.1); Fedora hat nur 3.1.0
# (rust-matugen). Gebaut wird das Release 4.2.0 mit «cargo build --release --locked»: Die Crates kommen beim Bau von
# crates.io, in genau den Fassungen und Prüfsummen von Cargo.lock. Im COPR braucht dieser Bau darum Netz
# (Einstellung im COPR, siehe packaging/fedora/LIESMICH.md); ohne Netz scheitert er beim Laden der Crates.
#
# Lizenzfeld: GPL-2.0-or-later für matugen selbst (Cargo.toml, README, LICENSE = GPL-2.0-Text), dazu die Lizenzen der
# 187 Crates, die für aarch64 und x86_64 gleich gelinkt werden – ermittelt im mock-Chroot mit
# «cargo tree --locked -e normal,no-proc-macro --target <Ziel> --format '{p}|{l}'» (Nachtlauf vom 28.11.2026, Punkt
# 3.1). Jeder Ausdruck steht so, wie das Crate ihn angibt; die alte Schreibweise «A/B» ist als «A OR B» geschrieben.
# Die Liste ist eine Obergrenze (wie bei Fedoras Makro cargo_license_summary): Was der Linker verwirft, bleibt im Feld.
#
# Release über dem matugen 4.2.0-1 eines fremden COPR (Nachtlauf vom 28.11.2026, Punkt 2.3, «Für den Plan»).

%global quelle_sha256 82044ab8ac3e793b2b94f8f75917b348b4038585133a77c07f5de59c88d65244

Name:           matugen
Version:        4.2.0
Release:        2%{?dist}
Summary:        Farbschemata nach Material You und base16 aus einem Bild, mit Vorlagen
License:        GPL-2.0-or-later AND (0BSD OR MIT OR Apache-2.0) AND Apache-2.0 AND (Apache-2.0 OR BSL-1.0) AND (Apache-2.0 OR MIT) AND (Apache-2.0 WITH LLVM-exception OR Apache-2.0 OR MIT) AND BSD-2-Clause AND (BSD-2-Clause OR Apache-2.0 OR MIT) AND BSD-3-Clause AND (BSD-3-Clause OR Apache-2.0) AND (BSD-3-Clause OR MIT) AND (CC0-1.0 OR Apache-2.0) AND MIT AND (MIT OR Apache-2.0) AND (MIT OR Apache-2.0 OR CC0-1.0) AND (MIT OR Apache-2.0 OR Zlib) AND (MIT OR Zlib OR Apache-2.0) AND MPL-2.0 AND Unicode-DFS-2016 AND (Unlicense OR MIT) AND Zlib AND (Zlib OR Apache-2.0 OR MIT)
URL:            https://github.com/InioX/matugen
# Release v4.2.0 (Tag-Commit bb27a35d7f9e0f57cf638703f3d8e3182aed0304)
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz

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
%autosetup -n %{name}-%{version}

%build
# Crates beim Bau von crates.io, genau nach Cargo.lock (P6); Ablage im Bauordner, nicht im Home des Bauenden
export CARGO_HOME=%{_builddir}/%{name}-%{version}-cargo-home
export RUSTFLAGS='%{build_rustflags}'
cargo build --release --locked

%install
install -Dpm0755 target/release/%{name} %{buildroot}%{_bindir}/%{name}

%check
# Fassung und die Option, die das Design von Alpe braucht (P2)
%{buildroot}%{_bindir}/%{name} --version | grep -qx 'matugen %{version}'
%{buildroot}%{_bindir}/%{name} --help | grep -q -- '--prefer'

%files
%license LICENSE
%doc README.md CHANGELOG.md
%{_bindir}/%{name}

%changelog
* Sat Nov 28 2026 Alpe <alpe-shell@users.noreply.github.com> - 4.2.0-2
- Erste Spec für das COPR alpe-shell/alpe (Plan 6.3, E3)
