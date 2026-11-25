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
# Zusatz zu den ldflags für den Paketbau (etwa eine Build-ID); ersetzt die Versionsflags nicht
EXTRA_LDFLAGS ?=

BRAND_QML := shell/Common/Brand.qml
VERSION_SED := sed -n 's/.*property string version: "\([^"]*\)".*/\1/p'
VERSION := $(shell $(VERSION_SED) $(BRAND_QML) | head -1)
# Nur das eigene Repository zählt (nicht ein umschliessendes, etwa der Klon eines AUR-Pakets); im Quellarchiv
# steht der Commit in der Datei COMMIT, die «make dist» schreibt.
IM_REPO := $(shell [ "$$(git -C $(CURDIR) rev-parse --show-toplevel 2>/dev/null)" = "$(CURDIR)" ] && echo ja)
COMMIT := $(if $(IM_REPO),$(shell git rev-parse --short=8 HEAD),$(or $(shell cat COMMIT 2>/dev/null),unknown))
# Reproduzierbar, wenn SOURCE_DATE_EPOCH gesetzt ist (Paketbau); sonst die Zeit des Baus.
BUILD_TIME := $(shell date -u $${SOURCE_DATE_EPOCH:+-d @$$SOURCE_DATE_EPOCH} '+%Y-%m-%d_%H:%M:%S')
LDFLAGS := -s -w -X main.Version=$(VERSION) -X github.com/alpe-shell/alpe/core/internal/brand.Version=$(VERSION) \
	-X main.buildTime=$(BUILD_TIME) -X main.commit=$(COMMIT) $(EXTRA_LDFLAGS)

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

# «build» baut immer neu. «install» nimmt den gebauten Dienst, wie er ist, und baut nur, wenn er fehlt – im
# Paketbau läuft install in einem eigenen Schritt mit eigener Umgebung (makepkg: package(), RPM: %install); ein
# Neubau dort verlöre die GOFLAGS des Bauschritts (-buildmode=pie, Plan 6.2).
build:
	@test -n "$(VERSION)" || { echo "Version aus $(BRAND_QML) nicht lesbar"; exit 1; }
	@mkdir -p $(BUILD_ABS)
	cd core && CGO_ENABLED=0 $(GO) build -trimpath -buildvcs=false -ldflags '$(LDFLAGS)' -o $(BUILD_ABS)/alpe-dienst ./cmd/alpe-dienst
	@echo "gebaut: $(BUILD)/alpe-dienst $(VERSION) (ohne eingebettete Oberfläche)"

$(BUILD_ABS)/alpe-dienst:
	$(MAKE) build

install: $(BUILD_ABS)/alpe-dienst
	install -Dm755 $(BUILD_ABS)/alpe-dienst $(DESTDIR)$(PREFIX)/bin/alpe-dienst
	install -d $(SHARE)/shell $(SHARE)/plugins $(SHARE)/tools $(SHARE)/design $(SHARE)/lockscreen $(SHARE)/assets
	# Logo für fastfetch: tools/fastfetch.py liest ../assets/fastfetch-logo.txt (Baum spiegelt das Repo, Plan 1)
	install -m644 assets/fastfetch-logo.txt $(SHARE)/assets/fastfetch-logo.txt
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
# läuft (Plan 6.2). Version und Commit kommen aus HEAD, nicht aus dem Arbeitsbaum. Reproduzierbar: feste
# Reihenfolge, Besitzer 0, Modi unabhängig von der umask, Zeit des Commits, gzip ohne Namen und Zeit. Das Ergebnis
# hängt noch an der Go-Version, die vendort (vendor/modules.txt).
dist:
	@test -n "$(IM_REPO)" || { echo "make dist braucht dieses Git-Repository ($(CURDIR))"; exit 1; }
	$(eval DIST_VERSION := $(shell git show HEAD:$(BRAND_QML) | $(VERSION_SED) | head -1))
	rm -rf $(BUILD_ABS)/dist
	mkdir -p $(BUILD_ABS)/dist
	git archive --format=tar --prefix=alpe-$(DIST_VERSION)/ HEAD | tar -C $(BUILD_ABS)/dist -xf -
	git rev-parse --short=8 HEAD > $(BUILD_ABS)/dist/alpe-$(DIST_VERSION)/COMMIT
	cd $(BUILD_ABS)/dist/alpe-$(DIST_VERSION)/core && $(GO) mod vendor
	tar -C $(BUILD_ABS)/dist --sort=name --owner=0 --group=0 --numeric-owner --mode=u+rwX,go=rX \
		--mtime=@$$(git log -1 --format=%ct HEAD) -cf - alpe-$(DIST_VERSION) | gzip -n > $(BUILD_ABS)/alpe-$(DIST_VERSION).tar.gz
	rm -rf $(BUILD_ABS)/dist
	@echo "Quellarchiv: $(BUILD)/alpe-$(DIST_VERSION).tar.gz"

help:
	@sed -n '2,10p' Makefile
