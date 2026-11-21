BINARY_NAME=dms
SOURCE_DIR=cmd/dms
BUILD_DIR=bin
SHELL_SRC=../shell
EMBED_DIR=internal/shellembed/dist
PREFIX ?= /usr/local
INSTALL_DIR=$(PREFIX)/bin

GO=go
GOFLAGS=-ldflags="-s -w"

# Alpe: Die Version steht allein in shell/Common/Brand.qml (Plan 0.5 Nr. 2); der Dienst
# bekommt sie beim Bau. tests/test_version.py prüft, dass «dms version» sie meldet.
BRAND_QML=$(SHELL_SRC)/Common/Brand.qml
BRAND_VERSION=$(shell sed -n 's/.*property string version: "\([^"]*\)".*/\1/p' $(BRAND_QML) | head -1)
COMMIT_HASH=$(shell git rev-parse --short=8 HEAD 2>/dev/null || echo "unknown")
VERSION=$(BRAND_VERSION)
BUILD_TIME?=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
COMMIT?=$(COMMIT_HASH)

VERSION_LDFLAGS=-X main.Version=$(VERSION) -X main.buildTime=$(BUILD_TIME) -X main.commit=$(COMMIT)
BUILD_LDFLAGS=-ldflags='-s -w $(VERSION_LDFLAGS)'

# Architecture to build for dist target (amd64, arm64, or all)
ARCH ?= all
# Target OSes for dist builds
DIST_OSES ?= linux freebsd

ifeq ($(ARCH),all)
DIST_ARCHS = amd64 arm64
else
DIST_ARCHS = $(ARCH)
endif

.PHONY: all build sync-shell dist clean install uninstall install-config uninstall-config test fmt vet deps print-version help

# Default target
all: build

sync-shell:
	@test -e $(SHELL_SRC)/DCommon/Widgets/DIcon.qml || { echo "DCommon missing in $(SHELL_SRC)"; exit 1; }
	@rm -rf $(EMBED_DIR)
	@mkdir -p $(EMBED_DIR)
	@tar -C $(SHELL_SRC) --exclude=.qmlls.ini --exclude-from=shell-test-excludes.txt -chf - . | tar -C $(EMBED_DIR) -xf -
	@rm -rf $(EMBED_DIR)/.git* $(EMBED_DIR)/.github
	@rm -rf $(EMBED_DIR)/tests
	@find $(EMBED_DIR) -type d \( -name .claude -o -name .vscode \) -prune -exec rm -rf {} +
	@rm -f $(EMBED_DIR)/scripts/i18nsync.py $(EMBED_DIR)/scripts/build-vscode-vsix.sh $(EMBED_DIR)/scripts/qmllint-entrypoints.sh
	@rm -f $(EMBED_DIR)/translations/*.py $(EMBED_DIR)/translations/WORKFLOW.md
	@cd $(EMBED_DIR) && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | cut -c1-16 > .dankrev

# Build the main binary (dms)
build: sync-shell
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 $(GO) build -tags withshell $(BUILD_LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) ./$(SOURCE_DIR)
	@echo "Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

# Build distro binaries for each DIST_OSES/DIST_ARCHS pair
dist: sync-shell
	@echo "Building $(BINARY_NAME) for distribution ($(DIST_OSES) x $(DIST_ARCHS))..."
	@mkdir -p $(BUILD_DIR)
	@for os in $(DIST_OSES); do \
		for arch in $(DIST_ARCHS); do \
			echo "Building for $$os/$$arch..."; \
			CGO_ENABLED=0 GOOS=$$os GOARCH=$$arch $(GO) build -tags 'distro_binary withshell' $(BUILD_LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-$$os-$$arch ./$(SOURCE_DIR) || exit 1; \
			echo "  $(BUILD_DIR)/$(BINARY_NAME)-$$os-$$arch"; \
		done; \
	done
	@echo "Distribution builds complete"

install:
	@echo "Installing $(BINARY_NAME) to $(INSTALL_DIR)..."
	@install -D -m 755 $(BUILD_DIR)/$(BINARY_NAME) $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "Installation complete"

uninstall:
	@echo "Uninstalling $(BINARY_NAME) from $(INSTALL_DIR)..."
	@rm -f $(INSTALL_DIR)/$(BINARY_NAME)
	@echo "Uninstall complete"

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR) $(EMBED_DIR)
	@echo "Clean complete"

test:
	@echo "Running tests..."
	$(GO) test -v ./...

fmt:
	@echo "Formatting Go code..."
	$(GO) fmt ./...

vet:
	@echo "Running go vet..."
	$(GO) vet $$($(GO) list ./... | grep -v internal/highlight/lexers)
	$(GO) vet -composites=false ./internal/highlight/lexers

deps:
	@echo "Updating dependencies..."
	$(GO) mod tidy
	$(GO) mod download

dev:
	@echo "Building $(BINARY_NAME) for development..."
	@mkdir -p $(BUILD_DIR)
	$(GO) build -ldflags='$(VERSION_LDFLAGS)' -o $(BUILD_DIR)/$(BINARY_NAME) ./$(SOURCE_DIR)
	@echo "Development build complete: $(BUILD_DIR)/$(BINARY_NAME)"

check-go:
	@echo "Checking Go version..."
	@go version | grep -E "go1\.(2[2-9]|[3-9][0-9])" > /dev/null || (echo "ERROR: Go 1.22 or higher required" && exit 1)
	@echo "Go version OK"

version: check-go
	@echo "Version: $(VERSION)"
	@echo "Build Time: $(BUILD_TIME)"
	@echo "Commit: $(COMMIT)"

print-version:
	@echo "$(VERSION)"

help:
	@echo "Available targets:"
	@echo "  all                 - Build the main binary (dms) (default)"
	@echo "  build               - Build the main binary (dms) with the embedded UI"
	@echo "  sync-shell          - Copy quickshell/ into the embed dir (runs before tagged builds)"
	@echo "  dist                - Build dms for linux/freebsd amd64/arm64"
	@echo "                        Use ARCH=amd64 or ARCH=arm64 and/or DIST_OSES=linux to narrow"
	@echo "  install             - Install dms to $(INSTALL_DIR)"
	@echo "  uninstall           - Remove dms from $(INSTALL_DIR)"
	@echo "  clean               - Clean build artifacts"
	@echo "  test                - Run tests"
	@echo "  fmt                 - Format Go code"
	@echo "  vet                 - Run go vet"
	@echo "  deps                - Update dependencies"
	@echo "  dev                 - Build with debug info"
	@echo "  check-go            - Check Go version compatibility"
	@echo "  version             - Show version information"
	@echo "  help                - Show this help message"
