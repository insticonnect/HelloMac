import Foundation

/// In-memory runtime settings, mirrored to the settings table so they
/// survive restarts. Reads/writes are cheap value types; benign races are ok.
final class Config {
    static let shared = Config()

    var paused = false
    var captureText = true
    var captureURLs = true
    var autoRevise = true
    var port: UInt16 = 4789
    var excludedApps: Set<String> = [
        "1Password", "1Password 7", "Keychain Access", "Passwords", "Bitwarden", "KeePassXC"
    ]

    private weak var store: Store?

    func load(from store: Store) {
        self.store = store
        paused = store.setting("paused") == "1"
        captureText = store.setting("capture_text") != "0"
        captureURLs = store.setting("capture_urls") != "0"
        autoRevise = store.setting("auto_revise") != "0"
        if let p = UInt16(store.setting("port") ?? ""), p > 1024 { port = p }
        if let raw = store.setting("excluded_apps"), !raw.isEmpty {
            excludedApps = Set(raw.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
        }
    }

    func save() {
        guard let store = store else { return }
        store.setSetting("paused", paused ? "1" : "0")
        store.setSetting("capture_text", captureText ? "1" : "0")
        store.setSetting("capture_urls", captureURLs ? "1" : "0")
        store.setSetting("auto_revise", autoRevise ? "1" : "0")
        store.setSetting("port", String(port))
        store.setSetting("excluded_apps", excludedApps.sorted().joined(separator: "\n"))
    }

    func isExcluded(app: String) -> Bool {
        return excludedApps.contains(app)
    }
}
