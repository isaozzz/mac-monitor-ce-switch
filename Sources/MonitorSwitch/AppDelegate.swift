import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let displayManager = DisplayManager()

    private var extendedItem: NSMenuItem!
    private var mirrorItem: NSMenuItem!
    private var mainDisplayItem: NSMenuItem!
    private var mainDisplayMenu: NSMenu!

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

    private func updateCheckmarks() {
        let mirroring = displayManager.isMirroring()
        extendedItem.state = mirroring ? .off : .on
        mirrorItem.state = mirroring ? .on : .off
        updateMainDisplaySubmenu(mirroring: mirroring)
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
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        updateCheckmarks()
    }
}
