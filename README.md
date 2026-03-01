# MonitorSwitch

macOS menu bar app to switch between **extended display** and **mirroring** modes, and to change the **main display**.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- Lives in the macOS menu bar (no Dock icon)
- One-click switching between extended and mirrored display modes
- Switch which display is the main display (menu bar position)
- Shows current mode with a checkmark
- Supports multiple external displays

## Requirements

- macOS 13.0 (Ventura) or later
- Two or more connected displays

## Install

### 1. Build

```bash
git clone https://github.com/isaozzz/mac-monitor-ce-switch.git
cd mac-monitor-ce-switch
swift build -c release
```

### 2. Copy binary

```bash
mkdir -p ~/bin
cp .build/arm64-apple-macosx/release/MonitorSwitch ~/bin/
```

### 3. Remove quarantine (required on first run)

```bash
xattr -dr com.apple.quarantine ~/bin/MonitorSwitch
```

### 4. Auto-start on login (LaunchAgent)

```bash
cat > ~/Library/LaunchAgents/com.monitorswitch.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.monitorswitch</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/YOUR_USERNAME/bin/MonitorSwitch</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF
```

Replace `YOUR_USERNAME` with your macOS username, then load it:

```bash
launchctl load ~/Library/LaunchAgents/com.monitorswitch.plist
launchctl start com.monitorswitch
```

The app will now start automatically on every login.

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.monitorswitch.plist
rm ~/Library/LaunchAgents/com.monitorswitch.plist
rm ~/bin/MonitorSwitch
```

## License

MIT License. See [LICENSE](LICENSE) for details.
