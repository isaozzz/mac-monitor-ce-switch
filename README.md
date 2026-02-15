# MonitorSwitch

macOS menu bar app to switch between **extended display** and **mirroring** modes.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- Lives in the macOS menu bar (no Dock icon)
- One-click switching between extended and mirrored display modes
- Shows current mode with a checkmark
- Supports multiple external displays

## Requirements

- macOS 13.0 (Ventura) or later
- Two or more connected displays

## Build & Run

```bash
swift build -c release
.build/release/MonitorSwitch
```

## Auto-start on Login

Add `.build/release/MonitorSwitch` to **System Settings > General > Login Items**.

## License

MIT License. See [LICENSE](LICENSE) for details.
