# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
swift build              # Debug build
swift build -c release   # Release build
swift run Muxy            # Run the app
```

Requires macOS 14+ and Swift 6.0+. No external dependency managers needed — everything is SPM-based.

## Architecture

Muxy is a macOS terminal multiplexer built with SwiftUI that uses [libghostty](https://github.com/ghostty-org/ghostty) for terminal emulation and rendering via Metal.

### Core Components

- **GhosttyService** (singleton) — Manages the single `ghostty_app_t` instance per process. Loads config from `~/.config/ghostty/config`, runs a 120fps tick timer, and handles clipboard callbacks.

- **GhosttyTerminalNSView** — AppKit `NSView` that hosts a ghostty surface (`ghostty_surface_t`). Handles all keyboard/mouse input routing to libghostty and manages the Metal rendering layer. This is bridged into SwiftUI via `GhosttyTerminalRepresentable`.

- **AppState** (@Observable) — Manages the mapping of projects → tabs → split pane trees. Tracks active project, active tab per project, and provides tab lifecycle operations (create, close, select).

- **ProjectStore** (@Observable) — Persists projects as JSON to `~/Library/Application Support/Muxy/projects.json`. Projects are directories the user adds via NSOpenPanel.

## GhosttyKit Integration

`GhosttyKit/` is a C module wrapping `ghostty.h` — the libghostty API. The precompiled static library lives in `GhosttyKit.xcframework/`. The `ghostty/` submodule contains the full Ghostty source for reference but is not compiled directly.

Key libghostty types: `ghostty_app_t` (app), `ghostty_surface_t` (terminal surface), `ghostty_config_t` (configuration). Surfaces are created when terminal views move to a window and destroyed on removal.

### Building libghostty

To rebuild the xcframework from the ghostty submodule (requires Zig):

```bash
cd ghostty
zig build -Demit-xcframework=true -Dxcframework-target=native   # fast, host arch only
zig build -Demit-xcframework=true -Dxcframework-target=universal # full universal build
cp -R macos/GhosttyKit.xcframework ../GhosttyKit.xcframework
```

See [docs/building-ghostty.md](docs/building-ghostty.md) for full details.

## Data Persistence

- **Projects:** `~/Library/Application Support/Muxy/projects.json`
- **Ghostty config:** `~/.config/ghostty/config`
- **Terminal state (tabs, splits):** in-memory only, lost on app close

## Top Level Rules

- Security first
- Maintainability
- Scalability
- Clean Code
- Clean Architecture
- Best Practices
- No Hacky Solutions

## Main Rules

- No commenting allowed in the codebase
- All code must be self-explanatory and cleanly structured
- Use early returns instead of nested conditionals
- Don't patch symptoms, fix root causes
- For every task, Consider how it will impact the architecture and code quality, not just the immediate problem
