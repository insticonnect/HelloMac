import Cocoa
import Foundation
import Combine
import IOKit.pwr_mgt
import CoreAudio

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
    /// Playback evidence collected during the current window session.
    private var sessionSignals = Extractors.PlayerSignals()
    /// Watch time per (app, title), surviving tab-aways: flicking to WhatsApp
    /// mid-lecture doesn't reset the clock — the pieces add up. An entry dies
    /// after 10 minutes out of sight (the rules engine uses the same ±10 min).
    private var dwell: [String: (total: Double, signals: Extractors.PlayerSignals,
                                 firstTs: Double, lastSeen: Double)] = [:]

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
        // Playing media holds display sleep off — both a reason not to call this
        // idle and evidence that the front window is playing something.
        let mediaAwake = isDisplaySleepPrevented()
        if nowIsIdle && mediaAwake {
            nowIsIdle = false // Watching a video counts as active.
        }
        if mediaAwake && !nowIsIdle { sessionSignals.mediaAssertion = true }
        // Sound actually coming out of the speakers — catches audio-only
        // lectures and video embeds alike (system-wide, so corroborating only).
        if !nowIsIdle && isAudioPlaying() { sessionSignals.audio = true }

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
            sessionSignals = Extractors.PlayerSignals()  // evidence belonged to the session just closed
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

    /// Playback evidence from the latest content capture, accumulated for as
    /// long as this window stays in front. Called from the capture queue, so it
    /// hops to the main thread where the rest of `sessionSignals` is touched.
    func noteVideoSignals(_ signals: Extractors.PlayerSignals) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.sessionSignals = self.sessionSignals.merging(signals)
        }
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

        // Accumulate watch time for this window. Detection judges the total —
        // not one continuous stretch — so tab-switching away and back keeps
        // counting; 120s is the floor detectWatched could possibly accept, and
        // its evidence-strength thresholds still apply to the total.
        if !lastIsIdle && !lastWindowTitle.isEmpty {
            let nowTs = now.timeIntervalSince1970
            let key = lastAppName + "|" + lastWindowTitle
            var d = dwell[key] ?? (0, Extractors.PlayerSignals(),
                                   lastEventStart.timeIntervalSince1970, nowTs)
            d.total += duration
            d.signals = d.signals.merging(sessionSignals)
            d.lastSeen = nowTs
            dwell[key] = d
            dwell = dwell.filter { nowTs - $0.value.lastSeen < 600 }
            if d.total >= 60 {
                Extractors.detectWatched(app: lastAppName, title: lastWindowTitle,
                                         url: lastURL, ts: d.firstTs,
                                         duration: d.total, signals: d.signals, store: store)
            }
        }
    }

    /// Whether the default output device is playing for anyone right now.
    /// Public CoreAudio, no permissions, a couple of mach calls per tick.
    private func isAudioPlaying() -> Bool {
        var deviceId = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                         &addr, 0, nil, &size, &deviceId) == noErr,
              deviceId != kAudioObjectUnknown else { return false }

        var running: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        addr.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere
        guard AudioObjectGetPropertyData(deviceId, &addr, 0, nil, &size, &running) == noErr else { return false }
        return running != 0
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
