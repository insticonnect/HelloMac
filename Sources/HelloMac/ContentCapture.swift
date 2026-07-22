import Foundation
import CryptoKit

/// Periodically snapshots the focused window's visible text, chunks it,
/// dedupes it, embeds it, and runs the fact extractors over it.
final class ContentCapture {
    private let store: Store
    private let queue = DispatchQueue(label: "com.hellomac.capture", qos: .utility)
    private var timer: Timer?
    private var lastHash = ""

    init(store: Store) {
        self.store = store
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.captureAsync()
        }
        // First capture shortly after launch.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.captureAsync()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Called by the tracker when the focused window changes (debounced).
    func windowChanged() {
        queue.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.capture()
        }
    }

    func captureAsync() {
        queue.async { [weak self] in
            self?.capture()
        }
    }

    private func capture() {
        guard !Config.shared.paused else { return }
        guard let snap = AXReader.snapshot(captureText: Config.shared.captureText,
                                           captureURL: Config.shared.captureURLs) else { return }

        // Let the tracker record the URL on its timeline events too.
        AppState.shared.tracker?.noteURL(snap.url)

        let text = snap.text
        guard text.count > 40 else { return }

        // Whole-screen dedupe: identical screen since last capture → skip early.
        let screenKey = hash(of: snap.appName + "|" + snap.windowTitle + "|" + text)
        if screenKey == lastHash { return }
        lastHash = screenKey

        let ts = Date().timeIntervalSince1970
        let day = Self.dayString(ts)

        for chunkText in chunk(text) {
            // Per-day chunk dedupe: same text seen again today is not re-stored.
            let h = hash(of: day + "|" + snap.appName + "|" + chunkText)
            guard let chunkId = store.insertChunk(ts: ts, app: snap.appName,
                                                  title: snap.windowTitle,
                                                  url: snap.url, text: chunkText,
                                                  hash: h) else { continue }
            if let vec = Embeddings.shared.embed(chunkText) {
                store.insertEmbedding(chunkId: chunkId, vec: vec)
            }
            Extractors.extractFacts(from: chunkText,
                                    source: "\(snap.appName): \(snap.windowTitle)",
                                    store: store)
        }
    }

    /// Split captured text into ~800-char chunks on line boundaries.
    private func chunk(_ text: String, target: Int = 800, maxChunks: Int = 16) -> [String] {
        var chunks: [String] = []
        var current = ""
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let l = line.trimmingCharacters(in: .whitespaces)
            if l.isEmpty { continue }
            if current.count + l.count + 1 > target && !current.isEmpty {
                chunks.append(current)
                current = ""
                if chunks.count >= maxChunks { return chunks }
            }
            current += (current.isEmpty ? "" : "\n") + l
        }
        if !current.isEmpty && chunks.count < maxChunks { chunks.append(current) }
        return chunks
    }

    private func hash(of s: String) -> String {
        let digest = SHA256.hash(data: Data(s.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func dayString(_ ts: Double) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone.current
        return fmt.string(from: Date(timeIntervalSince1970: ts))
    }
}
