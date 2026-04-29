import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let displayManager = DisplayManager()

    private var extendedItem: NSMenuItem!
    private var mirrorItem: NSMenuItem!
    private var mainDisplayItem: NSMenuItem!
    private var mainDisplayMenu: NSMenu!
    private var resolutionItem: NSMenuItem!
    private var resolutionMenu: NSMenu!

    private final class ResolutionTarget: NSObject {
        let displayID: CGDirectDisplayID
        let mode: CGDisplayMode
        init(displayID: CGDirectDisplayID, mode: CGDisplayMode) {
            self.displayID = displayID
            self.mode = mode
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "display.2",
                accessibilityDescription: "Display Mode"
            )
        }

        let menu = NSMenu()

        extendedItem = NSMenuItem(
            title: "拡張ディスプレイ",
            action: #selector(switchToExtended),
            keyEquivalent: "e"
        )
        extendedItem.target = self

        mirrorItem = NSMenuItem(
            title: "ミラーリング",
            action: #selector(switchToMirror),
            keyEquivalent: "m"
        )
        mirrorItem.target = self

        menu.addItem(extendedItem)
        menu.addItem(mirrorItem)
        menu.addItem(.separator())

        mainDisplayItem = NSMenuItem(title: "主ディスプレイ", action: nil, keyEquivalent: "")
        mainDisplayMenu = NSMenu()
        mainDisplayItem.submenu = mainDisplayMenu
        menu.addItem(mainDisplayItem)

        resolutionItem = NSMenuItem(title: "解像度", action: nil, keyEquivalent: "")
        resolutionMenu = NSMenu()
        resolutionItem.submenu = resolutionMenu
        menu.addItem(resolutionItem)

        let openSettingsItem = NSMenuItem(
            title: "ディスプレイ設定を開く…",
            action: #selector(openDisplaySettings),
            keyEquivalent: ""
        )
        openSettingsItem.target = self
        menu.addItem(openSettingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "終了",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem.menu = menu
        menu.delegate = self

        updateCheckmarks()
    }

    @objc private func switchToExtended() {
        displayManager.disableMirroring()
        updateCheckmarks()
    }

    @objc private func switchToMirror() {
        displayManager.enableMirroring()
        updateCheckmarks()
    }

    @objc private func switchMainDisplay(_ sender: NSMenuItem) {
        guard let num = sender.representedObject as? NSNumber else { return }
        let displayID = CGDirectDisplayID(num.uint32Value)
        displayManager.setMainDisplay(displayID)
        updateCheckmarks()
    }

    @objc private func switchResolution(_ sender: NSMenuItem) {
        guard let target = sender.representedObject as? ResolutionTarget else { return }
        displayManager.setMode(target.mode, for: target.displayID)
        updateCheckmarks()
    }

    @objc private func openDisplaySettings() {
        // macOS 13+ : System Settings の Displays ペイン
        if let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    private func updateCheckmarks() {
        let mirroring = displayManager.isMirroring()
        extendedItem.state = mirroring ? .off : .on
        mirrorItem.state = mirroring ? .on : .off
        updateMainDisplaySubmenu(mirroring: mirroring)
        updateResolutionSubmenu()
    }

    private func updateMainDisplaySubmenu(mirroring: Bool) {
        mainDisplayMenu.removeAllItems()
        let displays = displayManager.onlineDisplays().filter { $0.mirrorOf == kCGNullDirectDisplay }

        // ミラーリング中 or 1台のみなら非表示
        mainDisplayItem.isHidden = mirroring || displays.count < 2

        for display in displays {
            let name = displayManager.displayName(display.id)
            let item = NSMenuItem(title: name, action: #selector(switchMainDisplay(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = NSNumber(value: display.id)
            item.state = display.isMain ? .on : .off
            mainDisplayMenu.addItem(item)
        }
    }

    private func updateResolutionSubmenu() {
        resolutionMenu.removeAllItems()
        let displays = displayManager.onlineDisplays().filter { $0.mirrorOf == kCGNullDirectDisplay }

        guard !displays.isEmpty else {
            resolutionItem.isHidden = true
            return
        }
        resolutionItem.isHidden = false

        if displays.count == 1 {
            addResolutionItems(to: resolutionMenu, for: displays[0].id)
        } else {
            for display in displays {
                let name = displayManager.displayName(display.id)
                let item = NSMenuItem(title: name, action: nil, keyEquivalent: "")
                let submenu = NSMenu()
                addResolutionItems(to: submenu, for: display.id)
                item.submenu = submenu
                resolutionMenu.addItem(item)
            }
        }
    }

    private func addResolutionItems(to menu: NSMenu, for displayID: CGDirectDisplayID) {
        let modes = displayManager.availableModes(for: displayID)
        let currentModeID = displayManager.currentMode(for: displayID)?.ioDisplayModeID

        for rm in modes {
            var title = String(format: "%d × %d (x%.2f)", rm.width, rm.height, rm.scale)
            if rm.refreshRate > 0 {
                title += String(format: " @ %.0fHz", rm.refreshRate)
            }
            let item = NSMenuItem(title: title, action: #selector(switchResolution(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = ResolutionTarget(displayID: displayID, mode: rm.mode)
            item.state = (rm.mode.ioDisplayModeID == currentModeID) ? .on : .off
            menu.addItem(item)
        }
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        updateCheckmarks()
    }
}
