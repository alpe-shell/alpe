# Quickshell für das COPR alpe-shell/alpe (Plan 6.3, 0.8 Nr. 97; E3)
#
# Vorlage: die Fedora-Spec aus dist-git rpms/quickshell, Zweig f45, Commit a9df51973665894c628145689624dd9ad7b8cb09
# (https://src.fedoraproject.org/rpms/quickshell, dort Fassung 0.2.1^git20260209.dacfa9d-5). Die Vorlage nennt keine
# eigene Lizenz; Beiträge zu Fedora ohne Lizenzangabe stehen nach dem Fedora Project Contributor Agreement unter MIT
# (Spec-Dateien gelten dort als «Code»). Diese abgeleitete Spec steht ebenfalls unter MIT.
#
# Änderungen gegenüber der Vorlage:
# - Version 0.3.2 aus dem Tag v0.3.2 statt eines Git-Stands; Quelle mit Prüfsumme, die vor dem Entpacken geprüft wird.
# - Crash-Handler aus (CRASH_HANDLER=OFF): Er braucht cpptrace, das Fedora nicht paketiert; alpe.service setzt ohnehin
#   QS_DISABLE_CRASH_HANDLER=1. Der Schalter CRASH_REPORTER der Vorlage (breakpad) gibt es in 0.3.x nicht mehr.
# - DISTRIBUTOR nennt dieses COPR (BUILD.md des Ursprungs verlangt eine eindeutige Angabe).
# - jemalloc ausdrücklich an (USE_JEMALLOC=ON): Fedoras jemalloc ist für Seiten bis 64 KiB gebaut und läuft auf den
#   16-KB-Seiten von Fedora Asahi (Nachtlauf vom 27.11.2026, Punkt 3.3); die Prüfung nach dem Bau stellt sicher,
#   dass das Programm es linkt.
# - Lizenzfeld nach dem Quelltext (Entscheid P7 vom 28.11.2026): README «Licensed under the GNU LGPL 3» ohne «or
#   later»; Hyprland-Protokolle BSD-3-Clause; wlr-layer-shell und wlr-foreign-toplevel HPND-sell-variant;
#   wlr-screencopy MIT.
# - Summary und Beschreibung deutsch (Projektregel), Schalter breakpad und alte %%changelog-Einträge entfernt.
# - Neue BuildRequires aus den CMakeLists von 0.3.2 und eine Prüfung auf jemalloc nach dem Bau.
# - Release so gewählt, dass es nicht unter dem Quickshell 0.3.2-4 eines fremden COPR liegt (Nachtlauf vom
#   28.11.2026, Punkt 2.3).

# Nicht gebraucht
%bcond asan 0
# In RHEL nicht verfügbar (wie in der Vorlage)
%bcond x11 %[%{undefined rhel}]

# Tag v0.3.2 zeigt auf diesen Commit (git ls-remote); ohne Angabe ruft der Bau «git rev-parse» im Quellordner auf
%global commit 4f508be500dea6e5732cc3d50382a0048b17e7b1
%global quelle_sha256 f14115a73c9fff6aa6399f924b632e88c3ce2cead2657f814a7825341f35baad

Name:               quickshell
Version:            0.3.2
Release:            5%{?dist}
Summary:            Baukasten für Desktop-Shells auf Grundlage von QtQuick
License:            LGPL-3.0-only AND BSD-3-Clause AND HPND-sell-variant AND MIT
URL:                https://quickshell.org/
Source0:            https://git.outfoxxed.me/%{name}/%{name}/archive/v%{version}.tar.gz#/%{name}-%{version}.tar.gz

BuildRequires:      cmake
BuildRequires:      cmake(Qt6Core)
BuildRequires:      cmake(Qt6Qml)
BuildRequires:      cmake(Qt6CorePrivate)
BuildRequires:      cmake(Qt6QuickPrivate)
BuildRequires:      cmake(Qt6ShaderTools)
BuildRequires:      cmake(Qt6WaylandClient)
BuildRequires:      desktop-file-utils
BuildRequires:      gcc-c++
BuildRequires:      ninja-build
BuildRequires:      pkgconfig(CLI11)
BuildRequires:      pkgconfig(glib-2.0)
BuildRequires:      pkgconfig(gbm)
BuildRequires:      pkgconfig(jemalloc)
BuildRequires:      pkgconfig(libdrm)
BuildRequires:      pkgconfig(libpipewire-0.3)
BuildRequires:      pkgconfig(pam)
BuildRequires:      pkgconfig(polkit-agent-1)
BuildRequires:      pkgconfig(wayland-client)
BuildRequires:      pkgconfig(wayland-protocols)
BuildRequires:      spirv-tools
# Neu gegenüber der Vorlage, aus den CMakeLists von 0.3.2: dmabuf-Puffer (egl, VulkanHeaders), X11 (xcb), Polkit
BuildRequires:      pkgconfig(egl)
BuildRequires:      cmake(VulkanHeaders)
BuildRequires:      pkgconfig(polkit-gobject-1)
%if %{with x11}
BuildRequires:      pkgconfig(xcb)
%endif
# readelf für die Prüfung auf jemalloc (Abschnitt check)
BuildRequires:      binutils

# Laufzeitabhängigkeiten, die rpm nicht erkennt (wie in der Vorlage)
Requires:           (qt6-qtwayland%{?_isa} if qt6-qtbase%{?_isa} < 6.10)
Requires:           qt6-qtsvg%{?_isa}

%if %{with asan}
BuildRequires:      libasan
%endif

# Wie in der Vorlage: Quickshell kann Mitteilungen und Polkit-Anfragen bedienen
Provides:           desktop-notification-daemon = %{version}-%{release}
Provides:           PolicyKit-authentication-agent = %{version}-%{release}

%description
Quickshell ist ein Baukasten für Statusleisten, Widgets,
Sperrbildschirme und andere Teile einer Desktop-Oberfläche mit
QtQuick. Zusammen mit einem Wayland-Compositor entsteht daraus eine
vollständige Oberfläche.

%prep
echo "%{quelle_sha256}  %{SOURCE0}" | sha256sum -c -
%autosetup -C

%conf
%cmake  -GNinja \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_SKIP_INSTALL_RPATH=ON \
        -DDISTRIBUTOR="Fedora COPR (alpe-shell/alpe)" \
        -DINSTALL_QML_PREFIX=%{_lib}/qt6/qml \
        -DASAN=%{?with_asan:ON}%{!?with_asan:OFF} \
        -DCRASH_HANDLER=OFF \
        -DUSE_JEMALLOC=ON \
        -DX11=%{?with_x11:ON}%{!?with_x11:OFF} \
        -DGIT_REVISION=%{commit} \
        %{nil}

%build
%cmake_build

%install
%cmake_install

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/*.desktop
# jemalloc gelinkt (Plan 6.3, «Asahi-Risiko»)
readelf -d %{buildroot}%{_bindir}/quickshell | grep -q 'Shared library: \[libjemalloc\.so'

%files
%license LICENSE*
%doc BUILD.md CONTRIBUTING.md README.md changelog/
%{_bindir}/qs
%{_bindir}/quickshell
%{_datadir}/applications/org.quickshell.desktop
%{_datadir}/icons/hicolor/scalable/apps/org.quickshell.svg
%{_qt6_qmldir}/Quickshell/

%changelog
* Sat Nov 28 2026 Alpe <alpe-shell@users.noreply.github.com> - 0.3.2-5
- Quickshell 0.3.2 für das COPR alpe-shell/alpe, abgeleitet von der Fedora-Spec
  (dist-git rpms/quickshell, f45); ältere Einträge siehe dort
