import Foundation

/// Rule-based intelligence: categorize activity, spot deadlines/bills in
/// captured text ("goes into brain"), and detect watched videos.
enum Extractors {

    // MARK: - Categorization (fallback heuristic; user rules take priority)

    /// Buckets an app/title into Study / Entertainment / Work / Other when no
    /// user rule matches. Users override any of this from the dashboard.
    static func heuristicCategory(app: String, title: String, url: String? = nil) -> String {
        let a = app.lowercased()
        let t = (title + " " + (url ?? "")).lowercased()

        // Study: dev tools + learning material.
        if ["xcode", "visual studio code", "code", "terminal", "iterm2", "intellij idea", "pycharm", "anki"].contains(where: { a.contains($0) }) {
            return "Study"
        }
        // A college portal, LMS or MOOC host is study material whatever the
        // page is called.
        if let u = url?.lowercased(), studyHosts.contains(where: { u.contains($0) }) {
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

    /// Evidence that a video was actually *playing*, gathered from signals the
    /// app already collects: the accessibility text (ContentCapture) and the
    /// display-sleep power assertion (Tracker).
    struct PlayerSignals: Equatable {
        var timecode = false        // "12:34 / 45:07" — a player's position/duration
        var controls = false        // play/pause alongside fullscreen, mute, speed
        var mediaAssertion = false  // something is holding display sleep off
        var audio = false           // sound is actually coming out of the Mac

        static let none = PlayerSignals()

        /// Union, for accumulating evidence across one window session.
        func merging(_ other: PlayerSignals) -> PlayerSignals {
            return PlayerSignals(timecode: timecode || other.timecode,
                                 controls: controls || other.controls,
                                 mediaAssertion: mediaAssertion || other.mediaAssertion,
                                 audio: audio || other.audio)
        }
    }

    /// "12:34 / 45:07" (a player's time display) or "0:14 of 12:45" (how a
    /// seek slider reads its value out). Every real player has one of the two,
    /// and a wall of video thumbnails has neither — those show bare durations —
    /// which is what keeps this off a YouTube grid.
    private static let timecodeRegex = try! NSRegularExpression(
        pattern: #"\d{1,2}:\d{2}(:\d{2})?\s*(/|of)\s*\d{1,2}:\d{2}"#, options: [.caseInsensitive])

    private static let controlWords = [
        "fullscreen", "full screen", "mute", "unmute", "playback speed",
        "captions", "subtitles", "picture-in-picture", "1.25x", "1.5x"
    ]

    /// Play/Pause as whole words — a plain `contains("play")` would fire on
    /// "display" and "playlist".
    private static let transportRegex = try! NSRegularExpression(
        pattern: #"\b(play(ing)?|pause[d]?)\b"#, options: [.caseInsensitive])

    /// Reads captured on-screen text for the hallmarks of a video player. This
    /// is the platform-independent signal — it recognises a lecture on a college
    /// portal that no brand list will ever name.
    static func playerSignals(in text: String) -> PlayerSignals {
        guard !text.isEmpty else { return .none }
        var signals = PlayerSignals()
        let range = NSRange(text.startIndex..., in: text)
        signals.timecode = timecodeRegex.firstMatch(in: text, options: [], range: range) != nil
        let lower = text.lowercased()
        let hasTransport = transportRegex.firstMatch(in: lower, options: [], range: NSRange(lower.startIndex..., in: lower)) != nil
        signals.controls = hasTransport && controlWords.contains(where: { lower.contains($0) })
        return signals
    }

    /// Sites that are video by name — one signal among several, not the whole
    /// test any more. Users add their own under Settings → Video sources.
    private static let videoMarkers = [
        "youtube", "netflix", "prime video", "hotstar", "jiocinema", "disney+",
        "udemy", "coursera", "nptel", "swayam", "edx.org", "khan academy", "khanacademy",
        "unacademy", "vedantu", "byju", "physics wallah", "pw live",
        "skillshare", "pluralsight", "linkedin learning",
        "vimeo", "twitch", "dailymotion", "loom.com", "wistia",
        "panopto", "kaltura", "echo360", "brightcove", "bilibili"
    ]

    /// Native players — the app name alone settles it.
    private static let videoApps = ["vlc", "iina", "quicktime player", "mpv", "infuse", "movist", "elmedia"]

    /// URL shapes that mean "a video page", whatever the host is.
    private static let videoURLMarkers = [
        "/watch", "watch?v=", "/embed/", "/video/", "/videos/", "/lecture",
        "/lesson", "/player", "/stream", ".m3u8", ".mp4"
    ]

    /// Hosts that make something study material regardless of its title.
    private static let studyHosts = [
        ".edu", ".ac.in", ".ac.uk", ".edu.au", "moodle", "canvas", "blackboard",
        "classroom.google", "coursera", "udemy", "nptel", "swayam", "edx.org",
        "khanacademy", "unacademy", "vedantu", "byju", "physics wallah", "pw.live",
        "panopto", "echo360"
    ]

    private static let studyPhrases = [
        "lecture", "tutorial", "course", "chapter", "lesson", "module",
        "semester", "syllabus", "practical", "revision", "assignment",
        "problem set", "walkthrough", "iitm", "online degree"
    ]
    /// Matched on word boundaries so "class" misses "classical" and "unit"
    /// misses "united".
    private static let studyWords = ["class", "unit", "week", "lab", "exam", "notes"]

    /// A named video site or app: the built-in list plus the user's own.
    static func knownVideoSource(_ haystack: String) -> Bool {
        if videoMarkers.contains(where: { haystack.contains($0) }) { return true }
        return Config.shared.videoSources.contains {
            let s = $0.lowercased()
            return !s.isEmpty && haystack.contains(s)
        }
    }

    /// Study material: a learning host (college portal, LMS, MOOC) or a title
    /// that reads like coursework.
    static func isStudyMaterial(_ haystack: String) -> Bool {
        if studyHosts.contains(where: { haystack.contains($0) }) { return true }
        if studyPhrases.contains(where: { haystack.contains($0) }) { return true }
        return studyWords.contains(where: { containsWord($0, in: haystack) })
    }

    /// How strongly this activity looks like a video that was actually playing.
    /// Additive and rule-based so it stays debuggable — `detectWatched` logs the
    /// score together with the reasons behind it.
    ///
    /// `direct` marks evidence tied to the front window itself. The awake signal
    /// is system-wide (a Zoom call in another window holds it too) and a brand
    /// name in a *title* is just browsing, so those two alone never suffice —
    /// but a brand-named *app* (the Prime Video app, say) is the window itself.
    static func videoScore(app: String, title: String, url: String?,
                           signals: PlayerSignals) -> (score: Int, direct: Bool, reasons: [String]) {
        let a = app.lowercased()
        let u = (url ?? "").lowercased()
        let haystack = (title + " " + app + " " + (url ?? "")).lowercased()

        var score = 0
        var reasons: [String] = []
        func add(_ points: Int, _ why: String) { score += points; reasons.append(why) }

        if videoApps.contains(where: { a.contains($0) }) { add(3, "player app") }
        if signals.timecode { add(3, "timecode") }
        if signals.controls { add(2, "player controls") }
        if signals.audio { add(2, "audio playing") }
        if signals.mediaAssertion { add(2, "display kept awake") }
        if !u.isEmpty && videoURLMarkers.contains(where: { u.contains($0) }) { add(2, "video url") }
        if knownVideoSource(haystack) { add(2, "known source") }
        // A learning host (college portal, LMS) tips the scale — a lecture
        // playing there shouldn't need a brand name to be believed.
        if !u.isEmpty && studyHosts.contains(where: { u.contains($0) }) { add(1, "learning site") }

        let direct = signals.timecode || signals.controls
            || videoApps.contains(where: { a.contains($0) })
            || (!u.isEmpty && videoURLMarkers.contains(where: { u.contains($0) }))
            || knownVideoSource(a)
        return (score, direct, reasons)
    }

    /// Last ~20 detection decisions, so "why didn't my lecture appear?" can be
    /// answered from Settings instead of a terminal. Written on the main
    /// thread, read from HTTP server threads — hence the lock.
    private static var _detectionLog: [String] = []
    private static let logLock = NSLock()

    static var detectionLog: [String] {
        logLock.lock(); defer { logLock.unlock() }
        return _detectionLog
    }

    private static func logDecision(_ line: String) {
        print("MitthuAI: \(line)")
        let stamp = McpServer.fmtTime(Date().timeIntervalSince1970)
        logLock.lock(); defer { logLock.unlock() }
        _detectionLog.append("[\(stamp)] \(line)")
        if _detectionLog.count > 20 { _detectionLog.removeFirst(_detectionLog.count - 20) }
    }

    /// Called when a window session ends. `duration` is how long that one title
    /// held the screen; `signals` is the playback evidence gathered while it did.
    static func detectWatched(app: String, title: String, url: String?, ts: Double,
                              duration: Double, signals: PlayerSignals, store: Store) {
        guard !title.isEmpty else { return }
        let haystack = (title + " " + app + " " + (url ?? "")).lowercased()

        // With both text and URL capture switched off there is no evidence to
        // weigh, so fall back to the old name-only rule rather than see nothing.
        let blind = !Config.shared.captureText && !Config.shared.captureURLs
        let (score, direct, reasons) = videoScore(app: app, title: title, url: url, signals: signals)
        let why = reasons.joined(separator: ", ")
        guard blind ? knownVideoSource(haystack) : (score >= 3 && direct) else {
            if score > 0 { logDecision("not a video (score \(score): \(why)) — \(title.prefix(60))") }
            return
        }

        // Strong evidence is trusted sooner; a weak match still has to hold the
        // screen for the old five minutes before it counts as watched.
        guard duration >= (score >= 5 ? 60 : 300) else {
            logDecision("video seen but only \(Int(duration))s (score \(score): \(why)) — \(title.prefix(60))")
            return
        }

        let cleanTitle = title
            .replacingOccurrences(of: " - YouTube", with: "")
            .replacingOccurrences(of: " – YouTube", with: "")
        guard let factId = store.addFact(kind: "watched", title: String(cleanTitle.prefix(140)),
                                         detail: url ?? "", dueTs: nil, source: app) else { return }
        logDecision("watched (score \(score): \(why)) — \(cleanTitle.prefix(60))")

        // Study material auto-enrolls in the revision ladder (configurable).
        // Anything a user rule files under Study counts as well — that's the
        // escape hatch for a site none of the built-in lists know about.
        let isStudy = isStudyMaterial(haystack)
            || store.categoryFor(app: app, title: title, url: url) == "Study"
        if Config.shared.autoRevise && isStudy {
            store.addRevisionLadder(factId: factId, baseTs: ts)
        }
    }

    /// Word-boundary match, for markers too short to use as substrings.
    private static func containsWord(_ word: String, in text: String) -> Bool {
        return firstMatch(#"\b"# + NSRegularExpression.escapedPattern(for: word) + #"\b"#, text) != nil
    }
}
