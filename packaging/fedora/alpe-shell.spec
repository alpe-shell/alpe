# Alpe – RPM-Paket für Fedora und Fedora Asahi Remix, gebaut im COPR alpe-shell/alpe (Plan 6.3; E3)
#
# Gebaut wird aus dem Quellarchiv von «make dist» (Go-Module vendort): ohne Netz, mit «make build», «go test» und
# «make install DESTDIR». Kein Conflicts, Obsoletes oder Provides auf das Paket von Alpe 1.0: Die Pakete teilen keine
# Datei, und das alte darf während des Umzugs als Rückweg installiert bleiben (Plan 6.2, 6.3). Das Paket aktiviert und
# startet keine Unit (Plan 6.1: eingeschaltet wird je Compositor durch «alpe einrichten»/«alpe kde ein»).
#
# Die Version folgt shell/Common/Brand.qml (wie pkgver im PKGBUILD; tests/test_spec.py prüft beides).

# Name des Quellarchivs und des Ordners darin – genau hier, sonst nirgends (packaging/fedora/LIESMICH.md); wie
# DIST_NAME im Makefile (alpe-shell-<Version>, 0.8 Nr. 132) und $pkgname-$pkgver im PKGBUILD
%global quelle %{name}-%{version}
# Lizenztexte, die «make install» ablegt (Makefile, Plan 6.1)
%global lizenzdir %{_defaultlicensedir}/%{name}
# Der Dienst ist mit -s -w gebaut (Makefile); ein Debug-Paket bliebe leer.
%global debug_package %{nil}

Name:           alpe-shell
Version:        1.0
Release:        1%{?dist}
Summary:        Desktop-Shell für Linux, massgeschneidert für die Schweiz

# Inhaltlich wie license=() im PKGBUILD (Plan 6.2, 0.8 Nr. 113–117, 126, 142; Einzelheiten in NOTICE), in der
# SPDX-Schreibweise von Fedora mit AND. FTL statt (FTL OR GPL-2.0-or-later): Alpe hat die FTL gewählt (0.8 Nr. 114).
# Logo und Zeichen von Alpe stehen unter CC-BY-SA-4.0 (0.8 Nr. 142).
License:        MIT AND GPL-3.0-only AND Apache-2.0 AND BSD-2-Clause AND BSD-3-Clause AND OFL-1.1 AND CC-BY-3.0 AND CC-BY-4.0 AND CC-BY-SA-3.0 AND CC-BY-SA-4.0 AND CC0-1.0 AND FTL
URL:            https://github.com/alpe-shell/alpe
Source0:        %{url}/releases/download/v%{version}/%{quelle}.tar.gz

ExclusiveArch:  x86_64 aarch64

# go.mod verlangt Go 1.27.3; Fedora 45 liefert es in updates (Plan 6.3, «Go-Version»)
BuildRequires:  golang >= 1.27.3
BuildRequires:  make
BuildRequires:  systemd-rpm-macros
BuildRequires:  desktop-file-utils

# Plan 6.3; quickshell, matugen und kora-icon-theme kommen aus dem eigenen COPR (0.8 Nr. 91, 97, 99)
Requires:       quickshell >= 0.3.2
Requires:       qt6-qtbase
Requires:       qt6-qtdeclarative
Requires:       qt6-qtmultimedia
Requires:       qt6-qtsvg
Requires:       accountsservice
Requires:       python3
# Das ausgelieferte Design setzt matugenSourceMode «lightness», das braucht --prefer ab matugen 4.1 (0.8 Nr. 144);
# Fedora 45 hat nur 3.1.0 (rust-matugen), darum aus dem eigenen COPR
Requires:       matugen >= 4.1
# wpexec für den Codec-Wechsel bei Bluetooth; WirePlumber als Sitzungsverwalter (0.8 Nr. 96)
Requires:       wireplumber
Requires:       sound-theme-freedesktop
# kora ohne Version und Herkunft (0.8 Nr. 99); kora erbt von breeze und hicolor (0.8 Nr. 105)
Requires:       kora-icon-theme
Requires:       breeze-icon-theme
Requires:       hicolor-icon-theme

# Plan 6.3
Recommends:     python3-h5py
Recommends:     ffmpeg-free
Recommends:     slurp
Recommends:     hyprlock
Recommends:     hypridle
Recommends:     kitty
Recommends:     fastfetch
# wtype: Texteingabe für eigene Befehle und fremde Plugins (nur Hyprland); nichts in Alpe selbst ruft es auf (0.8 Nr. 133, 146)
Recommends:     wtype
# Dateisuche im Starter; läuft auch ohne (0.8 Nr. 26). Als Datei, weil Fedora kein Paket dieses Namens hat.
Recommends:     /usr/bin/dsearch

# Die übrigen optdepends des PKGBUILD (Entscheid des Maintainers vom 28.11.2026, 0.8 Nr. 141 (8)); Energieprofile mit
# einem der beiden Dienste
Suggests:       cava
Suggests:       cups-pk-helper
Suggests:       (power-profiles-daemon or tuned-ppd)
Suggests:       NetworkManager
Suggests:       i2c-tools
Suggests:       qt6ct
Suggests:       headsetcontrol

%description
Alpe ist eine Desktop-Shell für Linux auf Grundlage von Quickshell,
massgeschneidert für die Schweiz. Sie läuft unter KDE Plasma mit KWin
und unter Hyprland. Das Paket liefert den Dienst alpe-dienst, die
Oberfläche, Plugins, Werkzeuge (Befehl alpe), das Design, den
KDE-Sperrbildschirm und die Benutzer-Unit alpe.service. Eingeschaltet
wird Alpe pro Benutzer mit «alpe einrichten»; das Paket aktiviert keine
Unit.

%prep
%autosetup -n %{quelle}

%build
# Wie im PKGBUILD: vendort, ohne Netz, Caches im Bauordner
export CGO_ENABLED=0
export GOFLAGS='-mod=vendor -trimpath -buildmode=pie'
export GOPROXY=off
export GOTOOLCHAIN=local
export GOCACHE=%{_builddir}/%{quelle}-go-cache
export GOPATH=%{_builddir}/%{quelle}-go-path
# Build-ID für rpm (das Makefile reicht EXTRA_LDFLAGS an den Linker weiter)
%{__make} build EXTRA_LDFLAGS='-B gobuildid'

%install
%{__make} install DESTDIR=%{buildroot} PREFIX=%{_prefix}

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/*.desktop
export CGO_ENABLED=0
export GOFLAGS='-mod=vendor -trimpath -buildmode=pie'
export GOPROXY=off
export GOTOOLCHAIN=local
export GOCACHE=%{_builddir}/%{quelle}-go-cache
export GOPATH=%{_builddir}/%{quelle}-go-path
# Die Tests des Dienstes laufen mit eigenem Home und eigenen XDG-Ordnern, nie gegen das des Bauenden (wie check() im
# PKGBUILD).
heim=%{_builddir}/%{quelle}-check-home
mkdir -p "$heim/run"
chmod 700 "$heim/run"
cd core
env -u DBUS_SESSION_BUS_ADDRESS -u WAYLAND_DISPLAY -u DISPLAY \
  HOME="$heim" XDG_CONFIG_HOME="$heim/.config" XDG_DATA_HOME="$heim/.local/share" XDG_STATE_HOME="$heim/.local/state" \
  XDG_CACHE_HOME="$heim/.cache" XDG_RUNTIME_DIR="$heim/run" \
  go test -count=1 ./...

# Keine Scriptlets: Das Paket fasst $HOME nie an und schaltet keine Unit ein (Plan 6.1).

%files
%license %{lizenzdir}/LICENSE
%license %{lizenzdir}/NOTICE
%license %{lizenzdir}/GPL-3.0-only.txt
%license %{lizenzdir}/FTL.txt
# Lizenztexte der vendorten Go-Module, Pfad wie unter core/vendor (0.8 Nr. 131); als ganzer Ordner
%license %{lizenzdir}/vendor/
%doc README.md CHANGELOG.md
%{_bindir}/alpe-dienst
%{_bindir}/alpe
%{_datadir}/alpe/
%dir %{_datadir}/plasma
%dir %{_datadir}/plasma/shells
%{_datadir}/plasma/shells/org.alpe.desktop/
%{_userunitdir}/alpe.service
%{_datadir}/applications/io.github.alpe_shell.Alpe.desktop
%{_datadir}/applications/io.github.alpe_shell.Alpe.Notepad.desktop
%{_datadir}/applications/alpe-open.desktop
%{_datadir}/icons/hicolor/scalable/apps/io.github.alpe_shell.Alpe.svg
%{bash_completions_dir}/alpe-dienst
%{zsh_completions_dir}/_alpe-dienst
%{fish_completions_dir}/alpe-dienst.fish

%changelog
* Thu Nov 26 2026 Alpe <alpe-shell@users.noreply.github.com> - 1.0-1
- Erste Spec für das COPR alpe-shell/alpe (Plan 6.3, E3)
