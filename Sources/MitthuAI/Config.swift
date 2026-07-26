import Foundation

/// In-memory runtime settings, mirrored to the settings table so they
/// survive restarts. Reads/writes are cheap value types; benign races are ok.
final class Config {
    static let shared = Config()

    var paused = false
    var captureText = true
    var captureURLs = true
    var autoRevise = true
    var turboEmbeddings = false   // BYO OpenAI key path (opt-in)
    var relayEnabled = false      // Claude.ai web access via mitthuai relay
    var relayURL = "wss://relay.mitthuai.com/agent"
    var pairingURL = "https://mitthuai.com"
    var port: UInt16 = 4789
    var launchAtLogin = true      // start with macOS (on by default; see LoginItem)
    /// Whether `launch_at_login` has ever been written. Lets LoginItem tell a
    /// fresh install (opt in) from a user who deliberately switched it off.
    var launchAtLoginStored = false
    var excludedApps: Set<String> = [
        "1Password", "1Password 7", "Keychain Access", "Passwords", "Bitwarden", "KeePassXC"
    ]
    /// Extra sites/keywords that always count as video, on top of what the
    /// detector works out on its own. One per line in Settings.
    var videoSources: [String] = []

    private weak var store: Store?

    func load(from store: Store) {
        self.store = store
        paused = store.setting("paused") == "1"
        captureText = store.setting("capture_text") != "0"
        captureURLs = store.setting("capture_urls") != "0"
        autoRevise = store.setting("auto_revise") != "0"
        turboEmbeddings = store.setting("turbo_embeddings") == "1"
        relayEnabled = store.setting("relay_enabled") == "1"
        if let u = store.setting("relay_url"), !u.isEmpty { relayURL = u }
        if let u = store.setting("pairing_url"), !u.isEmpty { pairingURL = u }
        if let p = UInt16(store.setting("port") ?? ""), p > 1024 { port = p }
        if let v = store.setting("launch_at_login") {
            launchAtLogin = v == "1"
            launchAtLoginStored = true
        }
        if let raw = store.setting("video_sources"), !raw.isEmpty {
            videoSources = raw.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
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
        store.setSetting("turbo_embeddings", turboEmbeddings ? "1" : "0")
        store.setSetting("relay_enabled", relayEnabled ? "1" : "0")
        store.setSetting("relay_url", relayURL)
        store.setSetting("pairing_url", pairingURL)
        store.setSetting("port", String(port))
        store.setSetting("launch_at_login", launchAtLogin ? "1" : "0")
        store.setSetting("excluded_apps", excludedApps.sorted().joined(separator: "\n"))
        store.setSetting("video_sources", videoSources.joined(separator: "\n"))
    }

    func isExcluded(app: String) -> Bool {
        return excludedApps.contains(app)
    }
}
