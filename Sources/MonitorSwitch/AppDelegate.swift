import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let displayManager = DisplayManager()

    private var extendedItem: NSMenuItem!
    private var mirrorItem: NSMenuItem!

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

    private func updateCheckmarks() {
        let mirroring = displayManager.isMirroring()
        extendedItem.state = mirroring ? .off : .on
        mirrorItem.state = mirroring ? .on : .off
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        updateCheckmarks()
    }
}
