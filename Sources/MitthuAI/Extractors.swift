import Foundation

/// Rule-based intelligence: categorize activity, spot deadlines/bills in
/// captured text ("goes into brain"), and detect watched videos.
enum Extractors {

    // MARK: - Categorization (fallback heuristic; user rules take priority)

    /// Buckets an app/title into Study / Entertainment / Work / Other when no
    /// user rule matches. Users override any of this from the dashboard.
    static func heuristicCategory(app: String, title: String) -> String {
        let a = app.lowercased()
        let t = title.lowercased()

        // Study: dev tools + learning material.
        if ["xcode", "visual studio code", "code", "terminal", "iterm2", "intellij idea", "pycharm", "anki"].contains(where: { a.contains($0) }) {
            return "Study"
        }
        if t.contains("udemy") || t.contains("coursera") || t.contains("khan academy") || t.contains("nptel")
            || t.contains("lecture") || t.contains("tutorial") || t.contains("course")
            || (a.contains("preview") && t.contains(".pdf")) {
            return "Study"
        }

        // Entertainment: media + social.
        if t.contains("youtube") || t.contains("netflix") || t.contains("prime video") || t.contains("hotstar")
            || a.contains("spotify") || a.contains("music") || a.contains("tv") || a.contains("vlc")
            || a.contains("messages") || a.contains("whatsapp") || a.contains("telegram") || a.contains("discord") {
            return "Entertainment"
        }

        // Work: comms + meetings + mail.
        if a.contains("slack") || a.contains("teams") || a.contains("zoom") || a.contains("meet")
            || a.contains("mail") || a.contains("outlook") || t.contains("inbox") {
            return "Work"
        }

        return "Other"
    }

    // MARK: - Deadline / bill extraction from captured text

    private static let dueKeywords = [
        "due", "pending", "expires", "expiry", "deadline", "pay by",
        "payment due", "renew", "overdue", "last date", "submit by"
    ]

    private static let moneyRegex = try! NSRegularExpression(
        pattern: #"[$₹€£]\s?\d[\d,]*(\.\d+)?|(\d[\d,]*(\.\d+)?\s?(USD|INR|EUR|Rs\.?))"#,
        options: [.caseInsensitive])

    static func extractFacts(from text: String, source: String, store: Store) {
        for rawLine in text.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.count > 8 && line.count < 400 else { continue }
            let lower = line.lowercased()
            guard dueKeywords.contains(where: { lower.contains($0) }) else { continue }

            guard let due = parseDate(in: lower) else { continue }

            let range = NSRange(line.startIndex..., in: line)
            let hasMoney = moneyRegex.firstMatch(in: line, options: [], range: range) != nil
            let kind = hasMoney ? "bill" : "deadline"
            let title = String(line.prefix(120))

            store.addFact(kind: kind, title: title, detail: line, dueTs: due, source: source)
        }
    }

    /// Parse a due date out of a line of text. Supports:
    /// "in N days", "tomorrow", "today", 22/07/2026, 2026-07-22, "July 26" / "26 July".
    static func parseDate(in lower: String) -> Double? {
        let now = Date()
        let cal = Calendar.current

        func at9am(_ date: Date) -> Double {
            let start = cal.startOfDay(for: date)
            return start.timeIntervalSince1970 + 9 * 3600
        }

        if let m = firstMatch(#"in\s+(\d{1,3})\s+days?"#, lower), let n = Double(m[1]) {
            return at9am(now.addingTimeInterval(n * 86400))
        }
        if lower.contains("tomorrow") {
            return at9am(now.addingTimeInterval(86400))
        }
        if let m = firstMatch(#"(\d{4})-(\d{2})-(\d{2})"#, lower) {
            return dateFrom(y: m[1], mo: m[2], d: m[3]).map(at9am)
        }
        if let m = firstMatch(#"(\d{1,2})[/-](\d{1,2})[/-](\d{4})"#, lower) {
            // Ambiguous d/m vs m/d: prefer d/m (IN/EU); fall back if invalid.
            if let d = dateFrom(y: m[3], mo: m[2], d: m[1]) ?? dateFrom(y: m[3], mo: m[1], d: m[2]) {
                return at9am(d)
            }
        }
        let months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]
        if let m = firstMatch(#"(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?\s+(\d{1,2})"#, lower),
           let mo = months.firstIndex(of: m[1]), let day = Int(m[2]) {
            return monthDay(month: mo + 1, day: day).map(at9am)
        }
        if let m = firstMatch(#"(\d{1,2})(st|nd|rd|th)?\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*"#, lower),
           let day = Int(m[1]), let mo = months.firstIndex(of: m[3]) {
            return monthDay(month: mo + 1, day: day).map(at9am)
        }
        return nil
    }

    private static func firstMatch(_ pattern: String, _ text: String) -> [String]? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let m = re.firstMatch(in: text, options: [], range: range) else { return nil }
        var groups: [String] = []
        for i in 0..<m.numberOfRanges {
            if let r = Range(m.range(at: i), in: text) {
                groups.append(String(text[r]))
            } else {
                groups.append("")
            }
        }
        return groups
    }

    private static func dateFrom(y: String, mo: String, d: String) -> Date? {
        guard let yy = Int(y), let mm = Int(mo), let dd = Int(d),
              (1...12).contains(mm), (1...31).contains(dd) else { return nil }
        var comps = DateComponents()
        comps.year = yy; comps.month = mm; comps.day = dd
        return Calendar.current.date(from: comps)
    }

    /// Month+day with no year → the next occurrence of that date.
    private static func monthDay(month: Int, day: Int) -> Date? {
        guard (1...12).contains(month), (1...31).contains(day) else { return nil }
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        guard var date = cal.date(from: comps) else { return nil }
        if date < cal.startOfDay(for: Date()) {
            comps.year = year + 1
            guard let next = cal.date(from: comps) else { return nil }
            date = next
        }
        return date
    }

    // MARK: - Watched-video detection

    private static let videoMarkers = [
        "youtube", "netflix", "prime video", "hotstar", "udemy",
        "coursera", "nptel", "vimeo", "twitch", "vlc"
    ]
    private static let studyMarkers = ["lecture", "tutorial", "course", "class", "chapter", "lesson", "unit"]

    static func detectWatched(app: String, title: String, url: String?, ts: Double, store: Store) {
        let haystack = (title + " " + app + " " + (url ?? "")).lowercased()
        guard videoMarkers.contains(where: { haystack.contains($0) }) else { return }
        guard !title.isEmpty else { return }

        let cleanTitle = title
            .replacingOccurrences(of: " - YouTube", with: "")
            .replacingOccurrences(of: " – YouTube", with: "")
        guard let factId = store.addFact(kind: "watched", title: String(cleanTitle.prefix(140)),
                                         detail: url ?? "", dueTs: nil, source: app) else { return }

        // Study material auto-enrolls in the revision ladder (configurable).
        let isStudy = studyMarkers.contains(where: { haystack.contains($0) })
        if Config.shared.autoRevise && isStudy {
            store.addRevisionLadder(factId: factId, baseTs: ts)
        }
    }
}
