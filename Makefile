# Alpe – Bau, Installation, Prüfung und Quellarchiv (Plan Abschnitt 1 und 6.1).
#
#   make build                              Dienst (ohne eingebettete Oberfläche) und Sperrpaket nach $(BUILD)/
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

.PHONY: all build dienst sperrpaket install test dist help

# Sperrpaket für den KDE-Sperrbildschirm, beim Bau zusammengesetzt (Plan 6.1, 0.8 Nr. 86)
SPERR := $(BUILD_ABS)/plasma/org.alpe.desktop
LOCKVIEW := shell/Modules/Lock/Alpe

all: build

build: dienst sperrpaket

# «build» baut immer neu. «install» nimmt Dienst und Sperrpaket, wie sie gebaut sind, und baut nur, was fehlt – im
# Paketbau läuft install in einem eigenen Schritt mit eigener Umgebung (makepkg: package(), RPM: %install); ein
# Neubau dort verlöre die GOFLAGS des Bauschritts (-buildmode=pie, Plan 6.2).
dienst:
	@test -n "$(VERSION)" || { echo "Version aus $(BRAND_QML) nicht lesbar"; exit 1; }
	@mkdir -p $(BUILD_ABS)
	cd core && CGO_ENABLED=0 $(GO) build -trimpath -buildvcs=false -ldflags '$(LDFLAGS)' -o $(BUILD_ABS)/alpe-dienst ./cmd/alpe-dienst
	@echo "gebaut: $(BUILD)/alpe-dienst $(VERSION) (ohne eingebettete Oberfläche)"

# Das Paket aus lockscreen/org.alpe.desktop, dazu die Ansicht aus shell/Modules/Lock/Alpe (HyprlockView.qml,
# layout.js und der ganze Ordner fonts) – dieselben Schritte wie «lockscreen.sh install» ins Home. Die Version in
# metadata.json kommt aus Brand.qml wie die des Dienstes (Plan 0.8 Nr. 86; tests/test_version.py).
sperrpaket:
	@test -n "$(VERSION)" || { echo "Version aus $(BRAND_QML) nicht lesbar"; exit 1; }
	rm -rf $(SPERR)
	mkdir -p $(dir $(SPERR))
	cp -R lockscreen/org.alpe.desktop $(SPERR)
	cp $(LOCKVIEW)/HyprlockView.qml $(LOCKVIEW)/layout.js $(SPERR)/contents/lockscreen/
	cp -R $(LOCKVIEW)/fonts/. $(SPERR)/contents/lockscreen/fonts/
	sed 's/"Version": *"[^"]*"/"Version": "$(VERSION)"/' lockscreen/org.alpe.desktop/metadata.json > $(SPERR)/metadata.json
	@grep -q '"Version": "$(VERSION)"' $(SPERR)/metadata.json || { echo "Version in metadata.json nicht gesetzt"; exit 1; }
	@echo "zusammengesetzt: $(BUILD)/plasma/org.alpe.desktop $(VERSION)"

$(BUILD_ABS)/alpe-dienst:
	$(MAKE) dienst

$(SPERR)/metadata.json:
	$(MAKE) sperrpaket

install: $(BUILD_ABS)/alpe-dienst $(SPERR)/metadata.json
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
	install -d $(DESTDIR)$(PREFIX)/share/plasma/shells/org.alpe.desktop
	tar -C $(SPERR) -cf - . | tar -C $(DESTDIR)$(PREFIX)/share/plasma/shells/org.alpe.desktop --no-same-owner -xf -
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
	@test -n "$(DIST_VERSION)" || { echo "Version aus HEAD:$(BRAND_QML) nicht lesbar"; exit 1; }
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
