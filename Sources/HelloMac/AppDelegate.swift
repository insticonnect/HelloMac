import Cocoa
import SwiftUI

/// Global handles shared across subsystems.
final class AppState {
    static let shared = AppState()
    var tracker: Tracker?
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    let popover = NSPopover()

    var store: Store!
    var tracker: Tracker!
    var capture: ContentCapture!
    var scheduler: ReminderScheduler!
    var httpServer: HttpServer!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ask for Accessibility permission (shows the System Settings prompt).
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        if !trusted {
            print("HelloMac: waiting for Accessibility permission — grant it in System Settings → Privacy & Security → Accessibility, then relaunch if capture stays empty.")
        }

        store = Store()
        Config.shared.load(from: store)

        tracker = Tracker(store: store)
        AppState.shared.tracker = tracker

        capture = ContentCapture(store: store)
        tracker.onWindowChange = { [weak self] in
            self?.capture.windowChanged()
        }

        scheduler = ReminderScheduler(store: store)
        httpServer = HttpServer(store: store)

        tracker.start()
        capture.start()
        scheduler.start()
        httpServer.start()

        setupMenuBar()
        print("HelloMac: running. Dashboard: \(httpServer.dashboardURL)")
    }

    func applicationWillTerminate(_ notification: Notification) {
        tracker?.stop()
        capture?.stop()
        scheduler?.stop()
        httpServer?.stop()
    }

    private func setupMenuBar() {
        let contentView = MenuBarView(tracker: tracker, store: store) { [weak self] in
            self?.openDashboard()
        }
        popover.contentSize = NSSize(width: 280, height: 340)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile",
                                   accessibilityDescription: "HelloMac")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func openDashboard() {
        if let url = URL(string: httpServer.dashboardURL) {
            NSWorkspace.shared.open(url)
        }
        popover.performClose(nil)
    }
}
