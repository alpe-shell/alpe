# Symbolthema kora für das COPR alpe-shell/alpe (Plan 6.3, 0.8 Nr. 91, 99, 105; E3)
#
# Das ausgelieferte Design von Alpe nennt kora als Symbolthema; alpe-shell verlangt es mit «Requires: kora-icon-theme»
# ohne Version und Herkunft. Quelle: festes Release mit Prüfsumme (wird beim Entpacken geprüft).
# Lizenz am Quelltext belegt: LICENSE ist der Text der GPL-3.0, README.md «## License – GPL3» ohne «or later».

%global kora_sha256 159bdb7a09409a12e54a71136ec8889c51b0bf7c145c8b20e3509dc1e90089bd
%global themen kora kora-pgrey

Name:           kora-icon-theme
Version:        2.0.6
Release:        1%{?dist}
Summary:        Symbolthema kora (SVG)
License:        GPL-3.0-only
URL:            https://github.com/bikass/kora
# Release v2.0.6 (Tag-Commit 58ed0dd8bfda26fbff0b424c46c9bd2c43fa1527)
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/kora-%{version}.tar.gz

BuildArch:      noarch

# index.theme: Inherits=breeze,hicolor (0.8 Nr. 105)
Requires:       breeze-icon-theme
Requires:       hicolor-icon-theme

%description
kora ist ein SVG-Symbolthema für Linux-Oberflächen, mit der Variante
kora-pgrey. Es erbt fehlende Symbole von breeze und hicolor.

%prep
echo "%{kora_sha256}  %{SOURCE0}" | sha256sum -c -
%autosetup -n kora-%{version}

%build
# nichts zu bauen

%install
install -d %{buildroot}%{_datadir}/icons
for t in %{themen}; do
  cp -a "$t" %{buildroot}%{_datadir}/icons/
  # Werkzeug und vorgebauter Cache des Ursprungs gehören nicht ins Paket; den Cache legt das System an (unten als
  # Geisterdatei geführt)
  rm -f %{buildroot}%{_datadir}/icons/"$t"/create-new-icon-theme.cache.sh %{buildroot}%{_datadir}/icons/"$t"/icon-theme.cache
done
# Einige SVG tragen im Ursprung das Ausführungsrecht
find %{buildroot}%{_datadir}/icons -type f -exec chmod 0644 {} +
find %{buildroot}%{_datadir}/icons -type d -exec chmod 0755 {} +

%check
# Beide Themen vollständig: index.theme mit Inherits=breeze,hicolor, keine Verknüpfung ins Leere
for t in %{themen}; do
  grep -qx 'Inherits=breeze,hicolor' %{buildroot}%{_datadir}/icons/"$t"/index.theme
done
test -z "$(find %{buildroot}%{_datadir}/icons -xtype l)"

%files
%license LICENSE
%doc README.md
%dir %{_datadir}/icons/kora
%{_datadir}/icons/kora/*
%ghost %attr(0644,root,root) %{_datadir}/icons/kora/icon-theme.cache
%dir %{_datadir}/icons/kora-pgrey
%{_datadir}/icons/kora-pgrey/*
%ghost %attr(0644,root,root) %{_datadir}/icons/kora-pgrey/icon-theme.cache

%changelog
* Fri Nov 27 2026 Alpe <alpe-shell@users.noreply.github.com> - 2.0.6-1
- Erste Spec für das COPR alpe-shell/alpe (Plan 6.3, E3)
