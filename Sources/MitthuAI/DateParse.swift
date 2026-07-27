import Foundation

/// Pulling a due date out of a line of captured text.
///
/// The engine is `NSDataDetector` — the same on-device date parser macOS uses
/// for "Add to Calendar" in Mail. It reads every format people actually write
/// ("Sep 12, 2026", "12th Sept", "12/09/2026", "next Friday") in the user's
/// locale, which a hand-rolled regex never managed.
///
/// The rules layered on top are what make it right for *deadlines*:
/// the date must belong to the deadline keyword, an explicit year is never
/// second-guessed, and nothing implausible is allowed through.
enum DateParse {

    /// How to read a numeric date whose day/month order is genuinely ambiguous
    /// ("12/09/2026"). `auto` follows the Mac's region setting.
    enum Order: String {
        case auto, dmy, mdy
    }

    struct Found {
        let ts: Double          // when the reminder should fire
        let matched: String     // the text this came from, for the log
        let ambiguous: Bool     // numeric date that could be read either way
        let via: String         // "detector" | "regex" | "model"
    }

    /// Words that mean "this line is about a deadline". Kept here because the
    /// date has to be anchored to whichever one matched.
    static let dueKeywords = [
        "due", "pending", "expires", "expiry", "deadline", "pay by",
        "payment due", "renew", "overdue", "last date", "submit by",
        "apply by", "closes on", "valid till", "valid until", "before"
    ]

    /// Sanity window: a deadline in the past is a stale mail, and one more
    /// than two years out is almost always a misparse.
    private static let maxFuture: TimeInterval = 2 * 365 * 86400

    private static let yearRegex = try! NSRegularExpression(pattern: #"\b(19|20)\d{2}\b"#)
    private static let timeRegex = try! NSRegularExpression(
        pattern: #"\d{1,2}\s*(:\d{2})?\s*(am|pm)|\d{1,2}:\d{2}"#, options: [.caseInsensitive])
    /// A numeric date where both leading numbers are 1...12, so day-vs-month
    /// cannot be decided from the digits alone.
    private static let numericRegex = try! NSRegularExpression(
        pattern: #"\b(\d{1,2})\s*[/.-]\s*(\d{1,2})\s*[/.-]\s*(\d{2,4})\b"#)

    private static let detector = try? NSDataDetector(
        types: NSTextCheckingResult.CheckingType.date.rawValue)

    /// The deadline date for a line, or nil when there isn't a believable one.
    /// `nextLine` is consulted too — mail and tables often put "Last date to
    /// apply:" and the date itself on separate lines.
    static func dueDate(in line: String, nextLine: String? = nil) -> Found? {
        if let f = parse(line) { return f }
        if let next = nextLine, !next.isEmpty, keywordRange(in: line) != nil {
            // The keyword was on this line, so a bare date on the next one
            // belongs to it.
            return parse(next, assumeAnchored: true)
        }
        return nil
    }

    /// Where the deadline keyword sits, so the date can be anchored to it.
    static func keywordRange(in line: String) -> Range<String.Index>? {
        let lower = line.lowercased()
        var best: Range<String.Index>? = nil
        for kw in dueKeywords {
            if let r = lower.range(of: kw) {
                // Earliest keyword wins: the date usually follows it.
                if best == nil || r.lowerBound < best!.lowerBound {
                    best = Range(uncheckedBounds: (r.lowerBound, r.upperBound))
                }
            }
        }
        guard let b = best else { return nil }
        // Map the lowercased offsets back onto the original string.
        let start = line.index(line.startIndex, offsetBy: lower.distance(from: lower.startIndex, to: b.lowerBound))
        let end = line.index(line.startIndex, offsetBy: lower.distance(from: lower.startIndex, to: b.upperBound))
        return start..<end
    }

    private static func parse(_ line: String, assumeAnchored: Bool = false) -> Found? {
        let ns = line as NSString
        let full = NSRange(location: 0, length: ns.length)
        let anchor: Int
        if assumeAnchored {
            anchor = 0
        } else if let kr = keywordRange(in: line) {
            anchor = ns.range(of: String(line[kr])).location
        } else {
            anchor = 0
        }

        var candidates: [(date: Date, range: NSRange)] = []
        detector?.enumerateMatches(in: line, options: [], range: full) { m, _, _ in
            if let m = m, let d = m.date { candidates.append((d, m.range)) }
        }

        // Prefer the date that follows the deadline keyword and sits nearest
        // to it — "…open for Sep 2026 term, Last date to Apply : Sep 12, 2026"
        // must yield the 12th, not the year digits of the first phrase.
        let after = candidates.filter { $0.range.location >= anchor }
        let pick = (after.isEmpty ? candidates : after)
            .min { abs($0.range.location - anchor) < abs($1.range.location - anchor) }

        if let p = pick {
            let matched = ns.substring(with: p.range)
            if let ts = normalize(p.date, matched: matched, line: line) {
                return Found(ts: ts, matched: matched,
                             ambiguous: isAmbiguous(matched), via: "detector")
            }
        }
        return regexFallback(line, anchor: anchor, ns: ns)
    }

    /// Apply the deadline rules to a detected date: honour an explicit year,
    /// default the time to 9am, and refuse anything implausible.
    private static func normalize(_ date: Date, matched: String, line: String) -> Double? {
        let cal = Calendar.current
        let now = Date()
        var value = date

        let hadYear = has(yearRegex, matched)
        let hadTime = has(timeRegex, matched)

        if !hadTime {
            value = cal.startOfDay(for: value).addingTimeInterval(9 * 3600)
        }

        if value < cal.startOfDay(for: now) {
            // A written-out year is a fact, not a guess: a 2024 mail is simply
            // stale, and rolling it forward is how "January 2024" became a
            // 2027 deadline. Only a year-less date may roll.
            guard !hadYear else { return nil }
            guard let rolled = cal.date(byAdding: .year, value: 1, to: value),
                  rolled >= cal.startOfDay(for: now) else { return nil }
            value = rolled
        }
        guard value.timeIntervalSince(now) <= maxFuture else { return nil }
        return value.timeIntervalSince1970
    }

    private static func isAmbiguous(_ matched: String) -> Bool {
        let ns = matched as NSString
        guard let m = numericRegex.firstMatch(in: matched, options: [],
                                              range: NSRange(location: 0, length: ns.length)),
              let a = Int(ns.substring(with: m.range(at: 1))),
              let b = Int(ns.substring(with: m.range(at: 2))) else { return false }
        return (1...12).contains(a) && (1...12).contains(b) && a != b
    }

    /// Re-read a numeric date under the user's pinned order. `auto` keeps the
    /// detector's system-locale reading.
    static func applyOrder(_ found: Found, order: Order) -> Found {
        guard order != .auto, found.ambiguous else { return found }
        let ns = found.matched as NSString
        guard let m = numericRegex.firstMatch(in: found.matched, options: [],
                                              range: NSRange(location: 0, length: ns.length)),
              let a = Int(ns.substring(with: m.range(at: 1))),
              let b = Int(ns.substring(with: m.range(at: 2))),
              var y = Int(ns.substring(with: m.range(at: 3))) else { return found }
        if y < 100 { y += 2000 }
        let day = order == .dmy ? a : b
        let month = order == .dmy ? b : a
        var comps = DateComponents()
        comps.year = y; comps.month = month; comps.day = day
        comps.hour = 9
        guard let d = Calendar.current.date(from: comps),
              let ts = normalize(d, matched: found.matched, line: found.matched) else { return found }
        return Found(ts: ts, matched: found.matched, ambiguous: true, via: found.via)
    }

    // MARK: - Regex fallback

    private static let months = ["jan", "feb", "mar", "apr", "may", "jun",
                                 "jul", "aug", "sep", "oct", "nov", "dec"]
    /// "Sep 12, 2026" / "Sept 12th". Requiring a word boundary on both sides of
    /// the day — with any ordinal suffix inside it — is the fix for the original
    /// bug: a two-digit run inside "2026" has no boundary between its halves,
    /// so a year can no longer be misread as a day.
    private static let monthDayRegex = try! NSRegularExpression(
        pattern: #"(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s+\b(\d{1,2})(?:st|nd|rd|th)?\b(?:\s*,?\s*\b((?:19|20)\d{2})\b)?"#,
        options: [.caseInsensitive])
    /// "12 September 2026" / "12th Sept".
    private static let dayMonthRegex = try! NSRegularExpression(
        pattern: #"\b(\d{1,2})(?:st|nd|rd|th)?\b\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?(?:\s*,?\s*\b((?:19|20)\d{2})\b)?"#,
        options: [.caseInsensitive])
    /// "2026-09-12" — unambiguous, and worth keeping in the fallback.
    private static let isoRegex = try! NSRegularExpression(
        pattern: #"\b((?:19|20)\d{2})-(\d{1,2})-(\d{1,2})\b"#)

    private static func regexFallback(_ line: String, anchor: Int, ns: NSString) -> Found? {
        let full = NSRange(location: 0, length: ns.length)
        var best: (ts: Double, matched: String)? = nil
        var bestDistance = Int.max

        func consider(_ m: NSTextCheckingResult, month: Int, day: Int, yearRange: NSRange) {
            var comps = DateComponents()
            comps.month = month; comps.day = day; comps.hour = 9
            if yearRange.location != NSNotFound, let y = Int(ns.substring(with: yearRange)) {
                comps.year = y
            } else {
                comps.year = Calendar.current.component(.year, from: Date())
            }
            guard let d = Calendar.current.date(from: comps) else { return }
            let matched = ns.substring(with: m.range)
            guard let ts = normalize(d, matched: matched, line: line) else { return }
            let distance = m.range.location >= anchor ? m.range.location - anchor
                                                      : (anchor - m.range.location) + ns.length
            if distance < bestDistance { bestDistance = distance; best = (ts, matched) }
        }

        for m in isoRegex.matches(in: line, options: [], range: full) {
            guard let mo = Int(ns.substring(with: m.range(at: 2))),
                  let day = Int(ns.substring(with: m.range(at: 3))) else { continue }
            consider(m, month: mo, day: day, yearRange: m.range(at: 1))
        }
        for m in monthDayRegex.matches(in: line, options: [], range: full) {
            let name = ns.substring(with: m.range(at: 1)).lowercased()
            guard let mo = months.firstIndex(of: String(name.prefix(3))),
                  let day = Int(ns.substring(with: m.range(at: 2))) else { continue }
            consider(m, month: mo + 1, day: day, yearRange: m.range(at: 3))
        }
        for m in dayMonthRegex.matches(in: line, options: [], range: full) {
            guard let day = Int(ns.substring(with: m.range(at: 1))) else { continue }
            let name = ns.substring(with: m.range(at: 2)).lowercased()
            guard let mo = months.firstIndex(of: String(name.prefix(3))) else { continue }
            consider(m, month: mo + 1, day: day, yearRange: m.range(at: 3))
        }

        guard let b = best else { return nil }
        return Found(ts: b.ts, matched: b.matched, ambiguous: isAmbiguous(b.matched), via: "regex")
    }

    /// "2026-09-12" — for prompts and log lines.
    static func isoDay(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    private static func has(_ re: NSRegularExpression, _ s: String) -> Bool {
        return re.firstMatch(in: s, options: [],
                             range: NSRange(location: 0, length: (s as NSString).length)) != nil
    }

    /// Shared by ModelAssist: a timestamp is only believable if it survives the
    /// same window everything else does.
    static func plausible(_ ts: Double) -> Bool {
        let now = Date()
        let d = Date(timeIntervalSince1970: ts)
        return d >= Calendar.current.startOfDay(for: now) && d.timeIntervalSince(now) <= maxFuture
    }
}
