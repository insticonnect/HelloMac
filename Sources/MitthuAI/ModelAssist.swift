import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Optional last-resort date reading by Apple's on-device model.
///
/// Deliberately narrow. The deterministic parser in `DateParse` handles the
/// formats people actually write, runs in microseconds, and can't invent an
/// answer — so this is only asked about lines that mention a deadline and that
/// the parser could not resolve (or could only resolve ambiguously). That's a
/// handful of lines a day, not the 10-second capture firehose.
///
/// Three gates, any of which keeps it out of the way entirely:
///   • `#if canImport(FoundationModels)` — pre-macOS-26 SDKs compile this out
///   • `#available(macOS 26, *)` + the model's own availability check
///   • `Config.modelAssist`, off by default
///
/// Everything it returns is verified against the source text before use: a
/// model that invents a date is worse than no date at all.
enum ModelAssist {

    /// Human-readable state for the Settings panel — including the honest
    /// "this binary wasn't built with it" case.
    static var status: String {
        #if canImport(FoundationModels)
        if #available(macOS 26, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return "ready"
            case .unavailable(let reason):
                return "unavailable (\(reason))"
            @unknown default:
                return "unavailable"
            }
        }
        return "needs macOS 26 with Apple Intelligence"
        #else
        return "not built into this app (needs the macOS 26 SDK)"
        #endif
    }

    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    /// Cheap guards so a bad day can't turn into a battery drain: one request
    /// at a time, a modest hourly budget, and no repeats of the same line.
    private static let lock = NSLock()
    private static var inFlight = false
    private static var seen = Set<String>()
    private static var hourStart = Date().timeIntervalSince1970
    private static var usedThisHour = 0
    private static let hourlyBudget = 40

    private static func claim(_ line: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        let now = Date().timeIntervalSince1970
        if now - hourStart > 3600 { hourStart = now; usedThisHour = 0 }
        guard !inFlight, usedThisHour < hourlyBudget, !seen.contains(line) else { return false }
        inFlight = true
        usedThisHour += 1
        seen.insert(line)
        if seen.count > 400 { seen.removeAll() }
        return true
    }

    private static func release() {
        lock.lock(); inFlight = false; lock.unlock()
    }

    /// Ask the model for the deadline on `line`; `completion` runs only when a
    /// date survives validation.
    static func dueDate(in line: String, completion: @escaping (Double) -> Void) {
        guard Config.shared.modelAssist, isAvailable, claim(line) else { return }
        #if canImport(FoundationModels)
        if #available(macOS 26, *) {
            Task.detached(priority: .utility) {
                defer { release() }
                let today = DateParse.isoDay(Date())
                let instructions = """
                You extract deadline dates from text a user has on screen. \
                Today is \(today). Reply with ONLY the single deadline date in \
                YYYY-MM-DD form, or the word NONE if the text states no clear \
                future deadline. No explanation.
                """
                do {
                    let session = LanguageModelSession(instructions: instructions)
                    let reply = try await session.respond(to: line)
                    if let ts = validate(reply.content, against: line) {
                        await MainActor.run { completion(ts) }
                    }
                } catch {
                    print("MitthuAI: on-device model failed — \(error)")
                }
            }
            return
        }
        #endif
        release()
    }

    /// A model answer is only usable if the text actually supports it: strict
    /// YYYY-MM-DD, the day must appear as a number in the line, an explicit
    /// year in the line must match, and it must pass the same sanity window
    /// every other date does.
    static func validate(_ reply: String, against line: String) -> Double? {
        let trimmed = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        let ns = trimmed as NSString
        guard let m = try? NSRegularExpression(pattern: #"^(\d{4})-(\d{2})-(\d{2})$"#)
                .firstMatch(in: trimmed, options: [],
                            range: NSRange(location: 0, length: ns.length)),
              let year = Int(ns.substring(with: m.range(at: 1))),
              let month = Int(ns.substring(with: m.range(at: 2))),
              let day = Int(ns.substring(with: m.range(at: 3))) else { return nil }

        // The day has to be visible in the source text.
        let dayTokens = tokens(in: line)
        guard dayTokens.contains(day) else { return nil }
        // If the text names years, the answer must use one of them.
        let years = tokens(in: line).filter { $0 > 1900 && $0 < 2200 }
        if !years.isEmpty && !years.contains(year) { return nil }

        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day; comps.hour = 9
        guard let date = Calendar.current.date(from: comps) else { return nil }
        let ts = date.timeIntervalSince1970
        guard DateParse.plausible(ts) else { return nil }
        return ts
    }

    private static func tokens(in line: String) -> Set<Int> {
        var out = Set<Int>()
        let ns = line as NSString
        let re = try! NSRegularExpression(pattern: #"\b\d{1,4}\b"#)
        for m in re.matches(in: line, options: [], range: NSRange(location: 0, length: ns.length)) {
            if let v = Int(ns.substring(with: m.range)) { out.insert(v) }
        }
        return out
    }
}
