# DMS Backend & CLI

Go-based backend for Dux Modular Shell providing system integration, IPC, and installation tools.

**See [root README](../README.md) for project overview and installation.**

## Components

**dms CLI**
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
| `dwl-ipc-unstable-v2`                     | dwl/MangoWC IPC for tags, outputs, etc.                     |

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

- Plugin registry integration
- Plugin lifecycle management
- Settings persistence

## CLI Commands

- `dms run [-d]` - Start shell (optionally as daemon)
- `dms restart` / `dms kill` - Manage running processes
- `dms ipc <command>` - Send IPC commands (toggle launcher, notifications, etc.)
- `dms plugins [install|browse|search|lock|restore]` - Plugin management and portable exact-revision lockfiles
- `dms brightness [list|set]` - Control display/monitor brightness
- `dms color pick` - Native color picker (see below)
- `dms update` - Update DMS and dependencies (disabled in distro packages)
- `dms greeter` - Deprecated; forwards to the standalone [dms-greeter](https://github.com/duxlabs-dev/dux-greeter) binary

### Color Picker

Native Wayland color picker with magnifier, no external dependencies. Supports HiDPI and fractional scaling.

```bash
dms color pick              # Pick color, output hex
dms color pick --rgb        # Output as RGB (255 128 64)
dms color pick --hsv        # Output as HSV (24 75% 100%)
dms color pick --json       # Output all formats as JSON
dms color pick -a           # Auto-copy to clipboard
```

The on-screen preview displays the selected format. JSON output includes hex, RGB, HSL, HSV, and CMYK values.

## Building

Requires Go 1.25+

**Development build:**

```bash
make              # Build dms CLI
make test         # Run tests
```

**Distribution build:**

```bash
make dist         # Build without update features
```

Produces `bin/dms-linux-amd64` and `bin/dms-linux-arm64`

**Installation:**

```bash
sudo make install  # Install to /usr/local/bin/dms
```

## Development

**Regenerating Wayland Protocol Bindings:**

Protocol XML files live in `internal/proto/xml/`. Bindings are generated with the [dankgo](https://github.com/duxlabs-dev/dux-go) `go-wayland-scanner`:

```bash
go run github.com/duxlabs-dev/dux-go/cmd/go-wayland-scanner@latest \
  -i internal/proto/xml/wlr-gamma-control-unstable-v1.xml \
  -pkg wlr_gamma_control -o internal/proto/wlr_gamma_control/gamma_control.go
```

**Module Structure:**

- `cmd/` - Binary entrypoints (dms)
- `internal/distros/` - Distribution-specific installation logic
- `internal/proto/` - Wayland protocol bindings
- `pkg/` - Shared packages
