# Alpe – Bau, Installation, Prüfung und Quellarchiv (Plan Abschnitt 1 und 6.1).
#
#   make build                              Dienst bauen (ohne eingebettete Oberfläche) nach $(BUILD)/
#   make install DESTDIR=… PREFIX=/usr      Paketbaum unter DESTDIR anlegen (das Paket setzt DESTDIR immer)
#   make test                               dieselben Prüfungen wie tools/test.sh
#   make dist                               Quellarchiv $(BUILD)/alpe-<Version>.tar.gz mit vendorten Go-Modulen
#
# Die Version steht allein in shell/Common/Brand.qml (Plan 0.5 Nr. 2); der Dienst bekommt sie beim Bau.
# Der Dienst bettet die Oberfläche nicht ein (Bau ohne Tag «withshell», Plan Abschnitt 1): Er startet mit
# -c $(PREFIX)/share/alpe/shell. GOFLAGS aus der Umgebung (etwa -mod=vendor -buildmode=pie im Paketbau) gelten.

PREFIX ?= /usr
DESTDIR ?=
BUILD ?= build
GO ?= go

BRAND_QML := shell/Common/Brand.qml
VERSION := $(shell sed -n 's/.*property string version: "\([^"]*\)".*/\1/p' $(BRAND_QML) | head -1)
COMMIT := $(shell git rev-parse --short=8 HEAD 2>/dev/null || echo unknown)
# Reproduzierbar, wenn SOURCE_DATE_EPOCH gesetzt ist (Paketbau); sonst die Zeit des Baus.
BUILD_TIME := $(shell date -u $${SOURCE_DATE_EPOCH:+-d @$$SOURCE_DATE_EPOCH} '+%Y-%m-%d_%H:%M:%S')
LDFLAGS := -s -w -X main.Version=$(VERSION) -X github.com/alpe-shell/alpe/core/internal/brand.Version=$(VERSION) \
	-X main.buildTime=$(BUILD_TIME) -X main.commit=$(COMMIT)

BUILD_ABS := $(abspath $(BUILD))
SHARE := $(DESTDIR)$(PREFIX)/share/alpe

# Werkzeuge, die Nutzer brauchen – ausdrücklich, keine Wildcard (Plan 0.8 Nr. 109 (3)). Prüf- und
# Entwicklungsskripte (test.sh, test-commit.sh, node-tests.py, namen-*, werte-*, neue-dateien-pruefen.sh,
# release-pruefen.sh, standbild.py, build-basemap.py, radar-probe.py, backend.sh) kommen nicht ins Paket.
TOOLS := alpe activate-plugins.py design.py entfernen.sh fastfetch.py hyprlock2qml.py kde-sitzung.sh \
	kopfleiste.py kuerzel.py lockscreen.sh maclock.sh titelleisten.py

# Was aus shell/ und plugins/ nicht ins Paket gehört: Tests und Testdaten (dieselbe Liste wie beim Einbetten,
# core/shell-test-excludes.txt), Werkzeuge der Entwicklung, Zwischendateien.
EXCLUDES := --exclude-from=core/shell-test-excludes.txt --exclude=.qmlls.ini --exclude=__pycache__ \
	--exclude='*.qmlc' --exclude='*.jsc' --exclude='./translations/*.py' --exclude=./scripts/qmllint-entrypoints.sh

.PHONY: all build install test dist help

all: build

build:
	@test -n "$(VERSION)" || { echo "Version aus $(BRAND_QML) nicht lesbar"; exit 1; }
	@mkdir -p $(BUILD_ABS)
	cd core && CGO_ENABLED=0 $(GO) build -trimpath -ldflags '$(LDFLAGS)' -o $(BUILD_ABS)/alpe-dienst ./cmd/alpe-dienst
	@echo "gebaut: $(BUILD)/alpe-dienst $(VERSION) (ohne eingebettete Oberfläche)"

install: build
	install -Dm755 $(BUILD_ABS)/alpe-dienst $(DESTDIR)$(PREFIX)/bin/alpe-dienst
	install -d $(SHARE)/shell $(SHARE)/plugins $(SHARE)/tools $(SHARE)/design $(SHARE)/lockscreen
	tar -C shell $(EXCLUDES) -cf - . | tar -C $(SHARE)/shell --no-same-owner -xf -
	tar -C plugins $(EXCLUDES) -cf - . | tar -C $(SHARE)/plugins --no-same-owner -xf -
	tar -C design --exclude=__pycache__ -cf - . | tar -C $(SHARE)/design --no-same-owner -xf -
	tar -C lockscreen -cf - . | tar -C $(SHARE)/lockscreen --no-same-owner -xf -
	for t in $(TOOLS); do \
		if [ -x tools/$$t ]; then install -m755 tools/$$t $(SHARE)/tools/$$t; else install -m644 tools/$$t $(SHARE)/tools/$$t; fi || exit 1; \
	done
	install -d $(DESTDIR)$(PREFIX)/bin
	ln -sfn ../share/alpe/tools/alpe $(DESTDIR)$(PREFIX)/bin/alpe
	install -Dm644 LICENSE $(DESTDIR)$(PREFIX)/share/licenses/alpe-shell/LICENSE
	install -Dm644 NOTICE $(DESTDIR)$(PREFIX)/share/licenses/alpe-shell/NOTICE

test:
	bash tools/test.sh

# Quellarchiv aus dem eingecheckten Stand (git archive HEAD), Go-Module vendort, damit der Paketbau ohne Netz
# läuft (Plan 6.2). Reproduzierbar: feste Reihenfolge, Besitzer 0, Zeit des Commits, gzip ohne Namen und Zeit.
dist:
	@git rev-parse --git-dir >/dev/null 2>&1 || { echo "make dist braucht ein Git-Repository"; exit 1; }
	rm -rf $(BUILD_ABS)/dist
	mkdir -p $(BUILD_ABS)/dist
	git archive --format=tar --prefix=alpe-$(VERSION)/ HEAD | tar -C $(BUILD_ABS)/dist -xf -
	cd $(BUILD_ABS)/dist/alpe-$(VERSION)/core && $(GO) mod vendor
	tar -C $(BUILD_ABS)/dist --sort=name --owner=0 --group=0 --numeric-owner \
		--mtime=@$$(git log -1 --format=%ct HEAD) -cf - alpe-$(VERSION) | gzip -n > $(BUILD_ABS)/alpe-$(VERSION).tar.gz
	rm -rf $(BUILD_ABS)/dist
	@echo "Quellarchiv: $(BUILD)/alpe-$(VERSION).tar.gz"

help:
	@sed -n '2,10p' Makefile
