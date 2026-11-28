#!/usr/bin/env bash
# Alpe: Crate-Archiv für packaging/fedora/matugen.spec (Source1; Entscheid P19 vom 28.11.2026)
#
#   bash packaging/fedora/matugen-vendor.sh QUELLARCHIV ZIELORDNER
#
# QUELLARCHIV ist das Archiv des Tags (Source0 der Spec, matugen-<Version>.tar.gz); seine Prüfsumme wird zuerst
# geprüft. Das Skript entpackt es in einen Temp-Ordner, holt mit «cargo vendor --locked --versioned-dirs» genau die
# Crates aus Cargo.lock (braucht Netz, als einziger Schritt) und packt den Ordner vendor/ reproduzierbar nach
# ZIELORDNER/matugen-<Version>-vendor.tar.gz: Namen sortiert, alle Zeiten gleich der Zeit von Cargo.lock im
# Quellarchiv, Besitzer 0/0 numerisch, Modi ohne Schreibrecht für Gruppe und andere, gzip ohne Name und Zeit.
# Am Ende stehen Grösse und sha256 – die sha256 gehört ins Makro vendor_sha256 der Spec.
#
# Gedacht für einen Chroot von Fedora (mock) mit cargo, tar, gzip; CARGO_HOME liegt im Temp-Ordner, nichts geht ins
# Home des Aufrufers. Ein bestehendes Archiv wird nicht überschrieben. Das Archiv kommt nicht ins Repository
# (packaging/fedora/LIESMICH.md).
set -euo pipefail
umask 022
export LC_ALL=C TZ=UTC

version=4.2.0
# Gleich %global quelle_sha256 in matugen.spec (tests/test_spec_matugen.py prüft das)
quelle_sha256=82044ab8ac3e793b2b94f8f75917b348b4038585133a77c07f5de59c88d65244

[ $# -eq 2 ] || { echo "Aufruf: $0 QUELLARCHIV ZIELORDNER" >&2; exit 2; }
quelle=$(readlink -f "$1")
ziel=$(readlink -f "$2")
archiv="$ziel/matugen-$version-vendor.tar.gz"
[ -d "$ziel" ] || { echo "Zielordner fehlt: $ziel" >&2; exit 2; }
[ ! -e "$archiv" ] || { echo "besteht schon, wird nicht überschrieben: $archiv" >&2; exit 2; }

echo "$quelle_sha256  $quelle" | sha256sum -c -

arbeit=$(mktemp -d)
trap 'rm -rf "$arbeit"' EXIT
tar -xzf "$quelle" -C "$arbeit"
baum="$arbeit/matugen-$version"
[ -f "$baum/Cargo.lock" ] || { echo "Cargo.lock fehlt im Quellarchiv" >&2; exit 1; }

# Nur Crates von crates.io: Git-Quellen bräuchten eine eigene Ersetzung in der Cargo-Konfiguration der Spec
if grep -q '^source = "git+' "$baum/Cargo.lock"; then
    echo "Cargo.lock enthält Git-Quellen – die Spec ersetzt nur crates-io" >&2
    exit 1
fi

export CARGO_HOME="$arbeit/cargo-home"
(cd "$baum" && cargo vendor --locked --versioned-dirs vendor > "$arbeit/cargo-vendor-config.toml")
echo "Konfiguration laut cargo vendor (die Spec schreibt dieselbe Ersetzung):"
cat "$arbeit/cargo-vendor-config.toml"

zeit=$(stat -c %Y "$baum/Cargo.lock")
anzahl=$(find "$baum/vendor" -mindepth 1 -maxdepth 1 -type d | wc -l)
echo "Crates unter vendor/: $anzahl; Zeit für alle Einträge: $zeit ($(date -u -d "@$zeit" '+%Y-%m-%d %H:%M:%S UTC'))"

(cd "$baum" && tar --format=gnu --sort=name --mtime="@$zeit" --owner=0 --group=0 --numeric-owner \
    --mode='u+rw,go-w,a+rX' -cf - vendor) | gzip -9 -n > "$archiv.teil"
mv "$archiv.teil" "$archiv"

echo "Archiv: $archiv"
echo "Grösse: $(stat -c %s "$archiv") Byte"
sha256sum "$archiv"
