import Cocoa
import Foundation
import Combine
import IOKit.pwr_mgt

/// The activity logger: samples the frontmost app/window every second,
/// writes timeline events on change, detects idle, and flags watched videos.
/// (Ported and extended from the field-tested mitthu tracker.)
final class Tracker: ObservableObject {
    @Published var currentAppName: String = "Starting…"
    @Published var currentWindowTitle: String = ""
    @Published var isIdle: Bool = false

    private let store: Store
    private var timer: Timer?
    private var lastEventStart = Date()
    private var lastAppName = ""
    private var lastWindowTitle = ""
    private var lastURL: String? = nil
    private var lastIsIdle = false

    private let idleThreshold: TimeInterval = 300

    var onWindowChange: (() -> Void)? = nil

    init(store: Store) {
        self.store = store
    }

    func start() {
        lastEventStart = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        saveCurrentEvent()
    }

    private func tick() {
        if Config.shared.paused {
            // Close out whatever was open and idle-park the tracker.
            if lastAppName != "Paused" {
                saveCurrentEvent()
                lastAppName = "Paused"; lastWindowTitle = ""; lastIsIdle = true
                lastEventStart = Date()
                currentAppName = "Paused"; currentWindowTitle = ""; isIdle = true
            }
            return
        }

        let anyInput = CGEventType(rawValue: ~0)!
        let idleSecs = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: anyInput)
        var nowIsIdle = idleSecs >= idleThreshold
        if nowIsIdle && isDisplaySleepPrevented() {
            nowIsIdle = false // Watching a video counts as active.
        }

        var activeApp = "Idle"
        var activeTitle = ""

        if !nowIsIdle, let details = AXReader.frontmostDetails() {
            let name = details.app.localizedName ?? "Unknown"
            if name == "loginwindow" {
                nowIsIdle = true
            } else {
                activeApp = name
                activeTitle = details.title
                // URL is carried on `lastURL`, refreshed by ContentCapture and
                // read directly in saveCurrentEvent().
            }
        }

        if activeApp != lastAppName || activeTitle != lastWindowTitle || nowIsIdle != lastIsIdle {
            saveCurrentEvent()
            lastAppName = activeApp
            lastWindowTitle = activeTitle
            lastIsIdle = nowIsIdle
            lastEventStart = Date()

            DispatchQueue.main.async {
                self.currentAppName = activeApp
                self.currentWindowTitle = activeTitle
                self.isIdle = nowIsIdle
            }
            onWindowChange?()
        }
    }

    func noteURL(_ url: String?) {
        lastURL = url
    }

    private func saveCurrentEvent() {
        let now = Date()
        let duration = now.timeIntervalSince(lastEventStart)
        guard duration > 0.5, !lastAppName.isEmpty, lastAppName != "Paused" else { return }

        store.insertEvent(app: lastIsIdle ? "Idle" : lastAppName,
                          title: lastIsIdle ? "" : lastWindowTitle,
                          url: lastIsIdle ? nil : lastURL,
                          start: lastEventStart, end: now,
                          isIdle: lastIsIdle)

        // Long-enough media session? Record it as a "watched" memory.
        if !lastIsIdle && duration >= 300 {
            Extractors.detectWatched(app: lastAppName, title: lastWindowTitle,
                                     url: lastURL, ts: lastEventStart.timeIntervalSince1970,
                                     store: store)
        }
    }

    private func isDisplaySleepPrevented() -> Bool {
        var assertions: Unmanaged<CFDictionary>?
        let result = IOPMCopyAssertionsStatus(&assertions)
        if result == kIOReturnSuccess, let dict = assertions?.takeRetainedValue() as? [String: Any] {
            if let level = dict[kIOPMAssertionTypePreventUserIdleDisplaySleep] as? Int {
                return level > 0
            }
            if let level = dict["PreventUserIdleDisplaySleep"] as? Int {
                return level > 0
            }
        }
        return false
    }
}
