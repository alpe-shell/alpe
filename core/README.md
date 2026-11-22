# Alpe backend (`alpe-dienst`)

Go-based backend for Alpe providing system integration and IPC.

**See [root README](../README.md) for project overview and installation.**

## Components

**alpe-dienst**
Command-line interface and daemon for shell management and system control.

## System Integration

### Wayland Protocols (Client)

All Wayland protocols are consumed as a client - connecting to the compositor.

| Protocol                                  | Purpose                                                     |
| ----------------------------------------- | ----------------------------------------------------------- |
| `wlr-gamma-control-unstable-v1`           | Night mode color temperature control                        |
| `wlr-screencopy-unstable-v1`              | Screen capture for color picker/screenshot                  |
| `wlr-layer-shell-unstable-v1`             | Overlay surfaces for color picker UI/screenshot             |
| `wlr-output-management-unstable-v1`       | Display configuration                                       |
| `wlr-output-power-management-unstable-v1` | DPMS on/off CLI                                             |
| `wp-viewporter`                           | Fractional scaling support (color picker/screenshot UIs)    |
| `keyboard-shortcuts-inhibit-unstable-v1`  | Inhibit compositor shortcuts during color picker/screenshot |
| `ext-data-control-v1`                     | Clipboard history and persistence                           |
| `ext-workspace-v1`                        | Workspace integration                                       |

### DBus Interfaces

**Client (consuming external services):**

| Interface                        | Purpose                                       |
| -------------------------------- | --------------------------------------------- |
| `org.bluez`                      | Bluetooth management with pairing agent       |
| `org.freedesktop.NetworkManager` | Network management                            |
| `net.connman.iwd`                | iwd Wi-Fi backend                             |
| `org.freedesktop.network1`       | systemd-networkd integration                  |
| `org.freedesktop.login1`         | Session control, sleep inhibitors, brightness |
| `org.freedesktop.Accounts`       | User account information                      |
| `org.freedesktop.portal.Desktop` | Desktop appearance settings (color scheme)    |
| CUPS via IPP + D-Bus             | Printer management with job notifications     |

**Server (implementing interfaces):**

| Interface                     | Purpose                                |
| ----------------------------- | -------------------------------------- |
| `org.freedesktop.ScreenSaver` | Screensaver inhibit for video playback |

Custom IPC via unix socket (JSON API) for shell communication.

### Hardware Control

| Subsystem | Method              | Purpose                            |
| --------- | ------------------- | ---------------------------------- |
| DDC/CI    | I2C direct          | External monitor brightness        |
| Backlight | logind or sysfs     | Internal display brightness        |
| evdev     | `/dev/input/event*` | Keyboard state (caps lock LED)     |
| udev      | netlink monitor     | Backlight device updates (for OSD) |

### Plugin System

- Local plugin management (list, uninstall)
- Plugin lifecycle management
- Settings persistence

## CLI Commands

- `alpe-dienst run [-d]` - Start shell (optionally as daemon)
- `alpe-dienst restart` / `alpe-dienst kill` - Manage running processes
- `alpe-dienst ipc <command>` - Send IPC commands (toggle launcher, notifications, etc.)
- `alpe-dienst plugins [list|uninstall]` - Manage locally installed plugins
- `alpe-dienst brightness [list|set]` - Control display/monitor brightness
- `alpe-dienst color pick` - Native color picker (see below)

### Color Picker

Native Wayland color picker with magnifier, no external dependencies. Supports HiDPI and fractional scaling.

```bash
alpe-dienst color pick              # Pick color, output hex
alpe-dienst color pick --rgb        # Output as RGB (255 128 64)
alpe-dienst color pick --hsv        # Output as HSV (24 75% 100%)
alpe-dienst color pick --json       # Output all formats as JSON
alpe-dienst color pick -a           # Auto-copy to clipboard
```

The on-screen preview displays the selected format. JSON output includes hex, RGB, HSL, HSV, and CMYK values.

## Building

Requires Go 1.25+

**Development build:**

```bash
make              # Build alpe-dienst
make test         # Run tests
```

**Distribution build:**

```bash
make dist         # Build without update features
```

Produces `bin/alpe-dienst-linux-amd64` and `bin/alpe-dienst-linux-arm64`

**Installation:**

```bash
sudo make install  # Install to /usr/local/bin/alpe-dienst
```

## Development

**Regenerating Wayland Protocol Bindings:**

Protocol XML files live in `internal/proto/xml/`. Bindings are generated with the [dux-go](https://github.com/duxlabs-dev/dux-go) `go-wayland-scanner`:

```bash
go run github.com/duxlabs-dev/dux-go/cmd/go-wayland-scanner@latest \
  -i internal/proto/xml/wlr-gamma-control-unstable-v1.xml \
  -pkg wlr_gamma_control -o internal/proto/wlr_gamma_control/gamma_control.go
```

**Regenerating mocks:**

Mocks under `internal/mocks/` are generated, never edited by hand. Run `mockery` (v3.9.1) in `core/`;
`.mockery.yml` points at the template `.mockery/testify.templ` (stock testify template without
expecter helpers for `MarshalJSON`/`UnmarshalJSON`, so `go vet` stays clean).

**Module Structure:**

- `cmd/` - Binary entrypoints (alpe-dienst)
- `internal/osinfo/` - Operating system detection (os-release, image-based systems)
- `internal/proto/` - Wayland protocol bindings
- `pkg/` - Shared packages
