import AppKit
import ServiceManagement
import NonoCore

/// Menu bar only (LSUIElement): a laptop icon with Enabled / Start at Login toggles.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var monitor: LidMonitor?
    private let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleLogin), keyEquivalent: "")
    private var modeItems: [Mode: NSMenuItem] = [:]
    private let defaults = UserDefaults.standard
    private static let enabledKey = "enabled"
    private static let modeKey = "mode"

    func applicationDidFinishLaunching(_ notification: Notification) {
        monitor = LidMonitor()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let menu = NSMenu()
        enabledItem.target = self
        loginItem.target = self
        menu.addItem(enabledItem)
        menu.addItem(loginItem)
        menu.addItem(.separator())

        let modeMenu = NSMenu()
        for mode in Mode.allCases {
            let item = NSMenuItem(title: Self.title(for: mode), action: #selector(selectMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            modeMenu.addItem(item)
            modeItems[mode] = item
        }
        let modeItem = NSMenuItem(title: "Mode", action: nil, keyEquivalent: "")
        modeItem.submenu = modeMenu
        menu.addItem(modeItem)
        menu.addItem(.separator())
        let test = NSMenuItem(title: "Test Sounds", action: #selector(testSounds), keyEquivalent: "")
        test.target = self
        menu.addItem(test)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit nonono", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu

        monitor?.mode = defaults.string(forKey: Self.modeKey).flatMap(Mode.init(rawValue:)) ?? .nonono
        if monitor == nil {
            enabledItem.isEnabled = false
            enabledItem.title = "No lid sensor found"
            test.isEnabled = false
        } else if defaults.object(forKey: Self.enabledKey) as? Bool ?? true {
            monitor?.start()
        }
        refresh()
    }

    @objc private func toggleEnabled() {
        guard let monitor else { return }
        if monitor.isRunning { monitor.stop() } else { monitor.start() }
        defaults.set(monitor.isRunning, forKey: Self.enabledKey)
        refresh()
    }

    @objc private func toggleLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled { try service.unregister() } else { try service.register() }
        } catch {
            log("login item: \(error)")
            let alert = NSAlert()
            alert.messageText = "Could not change Start at Login"
            alert.informativeText = "\(error.localizedDescription)\n\nThe app must be run from a fixed location such as /Applications."
            alert.runModal()
        }
        refresh()
    }

    @objc private func selectMode(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let mode = Mode(rawValue: raw) else { return }
        monitor?.mode = mode
        defaults.set(mode.rawValue, forKey: Self.modeKey)
        refresh()
    }

    @objc private func testSounds() { monitor?.testSounds() }

    private static func title(for mode: Mode) -> String {
        switch mode {
        case .nonono: return "Nonono"
        case .sadViolin: return "Sad violin"
        }
    }

    private func refresh() {
        let running = monitor?.isRunning ?? false
        enabledItem.state = running ? .on : .off
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        let current = monitor?.mode ?? .nonono
        for (mode, item) in modeItems { item.state = mode == current ? .on : .off }
        let symbol = running ? "laptopcomputer" : "laptopcomputer.slash"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: running ? "nonono enabled" : "nonono disabled")
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = running ? "nonono: watching the lid" : "nonono: disabled"
    }
}
