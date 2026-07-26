import Foundation
import Security

/// All persistence for MitthuAI: activity events, captured text chunks
/// (with FTS5 + vector index), extracted facts, and reminders.
final class Store {
    let db: SQLiteDB
    let dataDir: URL

    init() {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        dataDir = appSupport.appendingPathComponent("MitthuAI")
        try? fm.createDirectory(at: dataDir, withIntermediateDirectories: true, attributes: nil)
        Store.migrateLegacyDataIfNeeded(fm: fm, appSupport: appSupport, newDir: dataDir)
        db = SQLiteDB(path: dataDir.appendingPathComponent("mitthuai.db").path)
        migrate()
        ensureToken()
    }

    /// One-time migration from the pre-rebrand HelloMac location.
    ///
    ///   ~/Library/Application Support/HelloMac/hellomac.db
    ///     → ~/Library/Application Support/MitthuAI/mitthuai.db
    ///
    /// Runs only when the new database does not exist yet and the old one does,
    /// so it is a no-op on fresh installs and on every launch after the first.
    /// The old files are COPIED, not moved, so the previous install stays intact
    /// as a fallback if anything goes wrong.
    private static func migrateLegacyDataIfNeeded(fm: FileManager, appSupport: URL, newDir: URL) {
        let newDB = newDir.appendingPathComponent("mitthuai.db")
        guard !fm.fileExists(atPath: newDB.path) else { return }

        let legacyDir = appSupport.appendingPathComponent("HelloMac")
        let legacyDB = legacyDir.appendingPathComponent("hellomac.db")
        guard fm.fileExists(atPath: legacyDB.path) else { return }

        // Copy the main database plus its write-ahead log sidecars, so an
        // un-checkpointed WAL doesn't silently drop the most recent activity.
        let pairs = [("hellomac.db", "mitthuai.db"),
                     ("hellomac.db-wal", "mitthuai.db-wal"),
                     ("hellomac.db-shm", "mitthuai.db-shm")]
        var copied = 0
        for (old, new) in pairs {
            let src = legacyDir.appendingPathComponent(old)
            guard fm.fileExists(atPath: src.path) else { continue }
            do {
                try fm.copyItem(at: src, to: newDir.appendingPathComponent(new))
                copied += 1
            } catch {
                print("MitthuAI migration: failed copying \(old): \(error)")
            }
        }

        if copied > 0 {
            print("MitthuAI migration: imported your HelloMac data (\(copied) file(s)) from \(legacyDir.path). The old folder was left untouched as a backup.")
        }
    }

    private func migrate() {
        db.exec("""
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ts_start REAL, ts_end REAL, duration REAL,
            app TEXT, title TEXT, url TEXT,
            is_idle INTEGER DEFAULT 0,
            category TEXT DEFAULT 'Uncategorized'
        );
        CREATE INDEX IF NOT EXISTS idx_events_ts ON events(ts_start);

        CREATE TABLE IF NOT EXISTS chunks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ts REAL, app TEXT, title TEXT, url TEXT,
            text TEXT, hash TEXT UNIQUE
        );
        CREATE INDEX IF NOT EXISTS idx_chunks_ts ON chunks(ts);

        CREATE TABLE IF NOT EXISTS embeddings (
            chunk_id INTEGER PRIMARY KEY REFERENCES chunks(id) ON DELETE CASCADE,
            dim INTEGER, vec BLOB, model TEXT DEFAULT ''
        );

        CREATE TABLE IF NOT EXISTS facts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kind TEXT, title TEXT, detail TEXT,
            due_ts REAL, created_ts REAL,
            source TEXT, status TEXT DEFAULT 'open',
            UNIQUE(kind, title)
        );

        CREATE TABLE IF NOT EXISTS reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fact_id INTEGER REFERENCES facts(id) ON DELETE CASCADE,
            fire_ts REAL, interval_idx INTEGER DEFAULT 0,
            status TEXT DEFAULT 'pending'
        );
        CREATE INDEX IF NOT EXISTS idx_reminders_fire ON reminders(fire_ts);

        CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT);

        CREATE TABLE IF NOT EXISTS rules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            app TEXT DEFAULT '',
            title_pattern TEXT DEFAULT '',
            category TEXT
        );
        """)

        // Additive migration for DBs created before the `model` column existed.
        // (ALTER errors harmlessly if the column already exists.)
        db.exec("ALTER TABLE embeddings ADD COLUMN model TEXT DEFAULT '';")
        // When a revision was actually completed (status 'done'), for history.
        db.exec("ALTER TABLE reminders ADD COLUMN done_ts REAL;")
        // When a fact was marked done — lets the History calendar place
        // completed items (even ones without a due date) on the right day.
        db.exec("ALTER TABLE facts ADD COLUMN done_ts REAL;")
        // Prior builds only ever used the Apple backend, so tag legacy vectors
        // accordingly to keep them visible to semantic search.
        db.exec("UPDATE embeddings SET model = 'apple-nl-en' WHERE model = '' OR model IS NULL;")

        db.exec("""
        CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts USING fts5(text, content='chunks', content_rowid='id');
        """)
        db.exec("""
        CREATE TRIGGER IF NOT EXISTS chunks_ai AFTER INSERT ON chunks BEGIN
            INSERT INTO chunks_fts(rowid, text) VALUES (new.id, new.text);
        END;
        """)
        db.exec("""
        CREATE TRIGGER IF NOT EXISTS chunks_ad AFTER DELETE ON chunks BEGIN
            INSERT INTO chunks_fts(chunks_fts, rowid, text) VALUES ('delete', old.id, old.text);
        END;
        """)

        seedDefaultRules()
    }

    // MARK: - Categorization rules (user-defined)

    /// The canonical category set the dashboard organizes around. Users can
    /// type any category on a rule, but these are the suggested buckets.
    static let categories = ["Study", "Entertainment", "Work", "Other"]
    static let focusCategories: Set<String> = ["Study", "Work", "Coding", "Writing"]

    private func seedDefaultRules() {
        let count = db.query("SELECT COUNT(*) AS n FROM rules").first?.int("n") ?? 0
        guard count == 0, setting("rules_seeded") == nil else { return }
        let defaults: [(String, String, String)] = [
            ("Xcode", "", "Study"),
            ("Visual Studio Code", "", "Study"),
            ("Code", "", "Study"),
            ("Terminal", "", "Study"),
            ("Safari", "YouTube", "Entertainment"),
            ("Google Chrome", "YouTube", "Entertainment"),
            ("Safari", "Netflix", "Entertainment"),
            ("Google Chrome", "Netflix", "Entertainment"),
            ("Spotify", "", "Entertainment"),
            ("Slack", "", "Work"),
            ("Microsoft Teams", "", "Work"),
            ("Zoom", "", "Work")
        ]
        for r in defaults {
            db.run("INSERT INTO rules (app, title_pattern, category) VALUES (?, ?, ?)", [r.0, r.1, r.2])
        }
        setSetting("rules_seeded", "1")
    }

    func allRules() -> [[String: Any]] {
        return db.query("SELECT id, app, title_pattern, category FROM rules ORDER BY id ASC")
    }

    /// Category for an app/title: user rules win, choosing the most specific
    /// (app-matched, then longest title pattern) and, on a tie, the newest rule.
    /// Falls back to the built-in heuristic.
    func categoryFor(app: String, title: String, url: String? = nil) -> String {
        let rows = db.query("""
            SELECT category FROM rules
            WHERE (app = ? AND title_pattern != '' AND ? LIKE '%' || title_pattern || '%')
               OR (app = ? AND title_pattern = '')
               OR (app = '' AND title_pattern != '' AND ? LIKE '%' || title_pattern || '%')
            ORDER BY (app != '') DESC, (title_pattern != '') DESC, LENGTH(title_pattern) DESC, id DESC
            LIMIT 1
            """, [app, title, app, title])
        if let cat = rows.first?.str("category"), !cat.isEmpty { return cat }
        return Extractors.heuristicCategory(app: app, title: title, url: url)
    }

    /// Add a rule, then retroactively re-tag matching past events. Also pulls
    /// in same-title activity within ±10 minutes of any match (so a video you
    /// flicked away from and back to lands in one category).
    func addRule(app: String, titlePattern: String, category: String) {
        db.run("INSERT INTO rules (app, title_pattern, category) VALUES (?, ?, ?)",
               [app, titlePattern, category])

        var conds: [String] = []
        var params: [Any?] = [category]
        if !app.isEmpty { conds.append("app = ?"); params.append(app) }
        if !titlePattern.isEmpty { conds.append("title LIKE '%' || ? || '%'"); params.append(titlePattern) }
        guard !conds.isEmpty else { return }
        let whereClause = conds.joined(separator: " AND ")

        db.run("UPDATE events SET category = ? WHERE is_idle = 0 AND \(whereClause)", params)

        // ±10-minute same-title expansion.
        let matched = db.query("SELECT DISTINCT title, ts_start, ts_end FROM events WHERE is_idle = 0 AND \(whereClause)",
                               Array(params.dropFirst()))
        for m in matched {
            let title = m.str("title")
            guard !title.isEmpty else { continue }
            db.run("""
                UPDATE events SET category = ?
                WHERE is_idle = 0 AND title = ?
                  AND ts_start >= ? AND ts_start <= ?
                """, [category, title, m.double("ts_start") - 600, m.double("ts_end") + 600])
        }
    }

    /// Tag a single observed title directly ("this video is Study"): REPLACES any
    /// existing rule for that exact app+title (so re-tapping a different category
    /// actually switches it, instead of stacking a conflicting rule), then
    /// re-tags matching history.
    func categorizeTitle(app: String, title: String, category: String) {
        // Drop any prior exact-title rule for this app so only one wins.
        db.run("DELETE FROM rules WHERE app = ? AND title_pattern = ?", [app, title])
        addRule(app: app, titlePattern: title, category: category)
        // Directly re-tag this exact title too (covers app-agnostic matches and
        // ensures an immediate switch even if the LIKE expansion missed edges).
        if app.isEmpty {
            db.run("UPDATE events SET category = ? WHERE is_idle = 0 AND title = ?", [category, title])
        } else {
            db.run("UPDATE events SET category = ? WHERE is_idle = 0 AND app = ? AND title = ?",
                   [category, app, title])
        }
    }

    func deleteRule(id: Int) {
        db.run("DELETE FROM rules WHERE id = ?", [id])
        recategorizeAll()
    }

    /// Recompute every non-idle event's category from the current rule set.
    private func recategorizeAll() {
        let events = db.query("SELECT id, app, title, url FROM events WHERE is_idle = 0")
        for e in events {
            let cat = categoryFor(app: e.str("app"), title: e.str("title"), url: e.str("url"))
            db.run("UPDATE events SET category = ? WHERE id = ?", [cat, e.int("id")])
        }
    }

    func focusStatsForDate(_ dateStr: String) -> (focus: Double, multitask: Double) {
        let (s, e) = dayBounds(dateStr)
        var focus = 0.0, multi = 0.0
        for row in db.query("""
            SELECT category, SUM(duration) AS total FROM events
            WHERE ts_start >= ? AND ts_start < ? AND is_idle = 0
            GROUP BY category
            """, [s, e]) {
            if Store.focusCategories.contains(row.str("category")) { focus += row.double("total") }
            else { multi += row.double("total") }
        }
        return (focus, multi)
    }

    func eventCountForDate(_ dateStr: String) -> Int {
        let (s, e) = dayBounds(dateStr)
        return db.query("SELECT COUNT(*) AS n FROM events WHERE ts_start >= ? AND ts_start < ?", [s, e]).first?.int("n") ?? 0
    }

    /// Multi-day report for the Trends view: per-day active/idle/focus/multitask,
    /// period totals, the preceding-period totals (for the "vs last period"
    /// deltas), and category totals across the whole range.
    func report(days: Int) -> [String: Any] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current

        var daily: [[String: Any]] = []
        var tActive = 0.0, tIdle = 0.0, tFocus = 0.0, tMulti = 0.0
        var catTotals: [String: Double] = [:]

        for i in stride(from: days - 1, through: 0, by: -1) {
            guard let d = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            let ds = fmt.string(from: d)
            let s = statsForDate(ds)
            let f = focusStatsForDate(ds)
            daily.append(["date": ds, "active": s.active, "idle": s.idle,
                          "focus": f.focus, "multitask": f.multitask])
            tActive += s.active; tIdle += s.idle; tFocus += f.focus; tMulti += f.multitask
            for row in categoryStatsForDate(ds) {
                catTotals[row.str("category"), default: 0] += row.double("total")
            }
        }

        // Preceding period of the same length, for comparison.
        var pActive = 0.0, pIdle = 0.0, pFocus = 0.0, pMulti = 0.0
        for i in 0..<days {
            guard let d = cal.date(byAdding: .day, value: -(days + i), to: today) else { continue }
            let ds = fmt.string(from: d)
            let s = statsForDate(ds)
            let f = focusStatsForDate(ds)
            pActive += s.active; pIdle += s.idle; pFocus += f.focus; pMulti += f.multitask
        }

        let categories = catTotals
            .map { ["category": $0.key, "total": $0.value] as [String: Any] }
            .sorted { ($0["total"] as? Double ?? 0) > ($1["total"] as? Double ?? 0) }

        return [
            "days": days,
            "daily": daily,
            "totals": ["active": tActive, "idle": tIdle, "focus": tFocus, "multitask": tMulti],
            "prior": ["active": pActive, "idle": pIdle, "focus": pFocus, "multitask": pMulti],
            "categories": categories
        ]
    }

    // MARK: - Settings / token

    func setting(_ key: String) -> String? {
        return db.query("SELECT value FROM settings WHERE key = ?", [key]).first?.str("value")
    }

    func setSetting(_ key: String, _ value: String) {
        db.run("INSERT INTO settings(key, value) VALUES(?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value", [key, value])
    }

    private func ensureToken() {
        if setting("api_token") == nil {
            var bytes = [UInt8](repeating: 0, count: 24)
            _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            let token = bytes.map { String(format: "%02x", $0) }.joined()
            setSetting("api_token", token)
        }
    }

    var apiToken: String { setting("api_token") ?? "" }

    // MARK: - Events

    func insertEvent(app: String, title: String, url: String?, start: Date, end: Date, isIdle: Bool) {
        let duration = end.timeIntervalSince(start)
        guard duration > 0.5 else { return }
        let category = isIdle ? "Idle" : categoryFor(app: app, title: title, url: url)
        db.run("""
            INSERT INTO events (ts_start, ts_end, duration, app, title, url, is_idle, category)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, [start.timeIntervalSince1970, end.timeIntervalSince1970, duration,
                  app, title, url, isIdle, category])
    }

    private func dayBounds(_ dateStr: String) -> (Double, Double) {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone.current
        let date = fmt.date(from: dateStr) ?? Date()
        let start = Calendar.current.startOfDay(for: date)
        return (start.timeIntervalSince1970, start.timeIntervalSince1970 + 86400)
    }

    func statsForDate(_ dateStr: String) -> (active: Double, idle: Double) {
        let (s, e) = dayBounds(dateStr)
        var active = 0.0, idle = 0.0
        for row in db.query("SELECT is_idle, SUM(duration) AS total FROM events WHERE ts_start >= ? AND ts_start < ? GROUP BY is_idle", [s, e]) {
            if row.int("is_idle") == 1 { idle = row.double("total") } else { active += row.double("total") }
        }
        return (active, idle)
    }

    func appStatsForDate(_ dateStr: String) -> [[String: Any]] {
        let (s, e) = dayBounds(dateStr)
        return db.query("""
            SELECT app, SUM(duration) AS total FROM events
            WHERE ts_start >= ? AND ts_start < ? AND is_idle = 0
            GROUP BY app ORDER BY total DESC LIMIT 12
            """, [s, e])
    }

    func categoryStatsForDate(_ dateStr: String) -> [[String: Any]] {
        let (s, e) = dayBounds(dateStr)
        return db.query("""
            SELECT category, SUM(duration) AS total FROM events
            WHERE ts_start >= ? AND ts_start < ? AND is_idle = 0
            GROUP BY category ORDER BY total DESC
            """, [s, e])
    }

    /// Merge raw events into human-level sessions: consecutive events in the
    /// same app (gap < 3 min) collapse into one block.
    func sessionsForDate(_ dateStr: String) -> [[String: Any]] {
        let (s, e) = dayBounds(dateStr)
        let events = db.query("""
            SELECT ts_start, ts_end, duration, app, title, url, is_idle, category FROM events
            WHERE ts_start >= ? AND ts_start < ? ORDER BY ts_start ASC
            """, [s, e])
        var sessions: [[String: Any]] = []
        var cur: [String: Any]? = nil

        for ev in events {
            let isIdle = ev.int("is_idle") == 1
            let app = isIdle ? "Idle" : ev.str("app")
            if var c = cur,
               c.str("app") == app,
               ev.double("ts_start") - c.double("ts_end") < 180 {
                c["ts_end"] = ev.double("ts_end")
                c["duration"] = c.double("duration") + ev.double("duration")
                let title = ev.str("title")
                // Keep the shown category aligned with the shown title, so the
                // inline chip highlight reflects the title you'd actually tag.
                if !title.isEmpty { c["title"] = title; c["category"] = ev.str("category"); c["url"] = ev.str("url") }
                var titles = c["titles"] as? [String] ?? []
                if !title.isEmpty && !titles.contains(title) && titles.count < 8 { titles.append(title) }
                c["titles"] = titles
                cur = c
            } else {
                if let c = cur { sessions.append(c) }
                cur = [
                    "app": app,
                    "title": ev.str("title"),
                    "titles": ev.str("title").isEmpty ? [String]() : [ev.str("title")],
                    "ts_start": ev.double("ts_start"),
                    "ts_end": ev.double("ts_end"),
                    "duration": ev.double("duration"),
                    "category": ev.str("category"),
                    "url": ev.str("url"),
                    "is_idle": isIdle
                ]
            }
        }
        if let c = cur { sessions.append(c) }
        // Drop micro-sessions under 15 seconds to keep the timeline readable.
        return sessions.filter { $0.double("duration") >= 15 }
    }

    // MARK: - Chunks (captured text) + hybrid search

    /// Insert a captured text chunk, returns new chunk id or nil when deduped.
    func insertChunk(ts: Double, app: String, title: String, url: String?, text: String, hash: String) -> Int64? {
        let existing = db.query("SELECT id FROM chunks WHERE hash = ?", [hash])
        if !existing.isEmpty { return nil }
        let id = db.run("""
            INSERT OR IGNORE INTO chunks (ts, app, title, url, text, hash) VALUES (?, ?, ?, ?, ?, ?)
            """, [ts, app, title, url, text, hash])
        return id > 0 ? id : nil
    }

    func insertEmbedding(chunkId: Int64, vec: [Float], model: String) {
        db.run("INSERT OR REPLACE INTO embeddings (chunk_id, dim, vec, model) VALUES (?, ?, ?, ?)",
               [chunkId, vec.count, Embeddings.data(from: vec), model])
    }

    /// Convenience single-query entry point.
    func search(query: String, from: Double?, to: Double?, limit: Int = 20) -> [[String: Any]] {
        return search(queries: [query], from: from, to: to, limit: limit)
    }

    /// Hybrid retrieval over one or more query angles (multi-query expansion):
    /// FTS5 (BM25) + vector cosine fused with reciprocal-rank fusion, then a
    /// rerank pass adding lexical-overlap and recency signals. The semantic leg
    /// only compares vectors embedded by the *same* model as the live query, so
    /// mixed-dimension histories stay correct after a backend switch.
    func search(queries: [String], from: Double?, to: Double?, limit: Int = 20) -> [[String: Any]] {
        let qs = queries.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !qs.isEmpty else { return [] }

        var ranks: [Int64: Double] = [:]

        // Keyword leg (union across all query angles).
        for q in qs {
            let terms = q.lowercased()
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map { "\"\($0)\"" }
            guard !terms.isEmpty else { continue }
            var sql = """
                SELECT c.id AS id, bm25(chunks_fts) AS rank FROM chunks_fts
                JOIN chunks c ON c.id = chunks_fts.rowid
                WHERE chunks_fts MATCH ?
                """
            var params: [Any?] = [terms.joined(separator: " OR ")]
            if let f = from { sql += " AND c.ts >= ?"; params.append(f) }
            if let t = to { sql += " AND c.ts <= ?"; params.append(t) }
            sql += " ORDER BY rank LIMIT 60"
            for (i, row) in db.query(sql, params).enumerated() {
                ranks[Int64(row.int("id")), default: 0] += 1.0 / Double(60 + i + 1)
            }
        }

        // Semantic leg — load candidate vectors once, score against each query.
        let activeModel = Embeddings.shared.modelId
        let qvecs = qs.compactMap { Embeddings.shared.embed($0) }
        if !qvecs.isEmpty {
            var sql = """
                SELECT e.chunk_id AS id, e.vec AS vec FROM embeddings e
                JOIN chunks c ON c.id = e.chunk_id
                WHERE e.model = ?
                """
            var params: [Any?] = [activeModel]
            if let f = from { sql += " AND c.ts >= ?"; params.append(f) }
            if let t = to { sql += " AND c.ts <= ?"; params.append(t) }
            let rows = db.query(sql, params)
            for q in qvecs {
                var scored: [(Int64, Float)] = []
                for row in rows {
                    guard let blob = row["vec"] as? Data else { continue }
                    let v = Embeddings.floats(from: blob)
                    guard v.count == q.count else { continue }
                    scored.append((Int64(row.int("id")), Embeddings.cosine(q, v)))
                }
                scored.sort { $0.1 > $1.1 }
                for (i, item) in scored.prefix(60).enumerated() {
                    ranks[item.0, default: 0] += 1.0 / Double(60 + i + 1)
                }
            }
        }

        // Take a wider candidate pool, then rerank with lexical + recency.
        let poolIds = ranks.sorted { $0.value > $1.value }.prefix(max(limit * 3, 40)).map { $0.key }
        guard !poolIds.isEmpty else { return [] }

        let placeholders = poolIds.map { _ in "?" }.joined(separator: ",")
        let rows = db.query("SELECT id, ts, app, title, url, text FROM chunks WHERE id IN (\(placeholders))",
                            poolIds.map { $0 as Any? })
        var byId: [Int64: [String: Any]] = [:]
        for r in rows { byId[Int64(r.int("id"))] = r }

        // Query term set for lexical overlap.
        let queryTerms = Set(qs.joined(separator: " ").lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init).filter { $0.count > 2 })
        let now = Date().timeIntervalSince1970

        var reranked: [(id: Int64, score: Double)] = []
        for id in poolIds {
            guard let r = byId[id] else { continue }
            let fused = ranks[id] ?? 0
            let text = (r.str("title") + " " + r.str("text")).lowercased()
            let hits = queryTerms.reduce(0) { $0 + (text.contains($1) ? 1 : 0) }
            let lexical = queryTerms.isEmpty ? 0 : Double(hits) / Double(queryTerms.count)
            // Recency: mild boost, half-life ~14 days.
            let ageDays = max(0, (now - r.double("ts")) / 86400)
            let recency = pow(0.5, ageDays / 14.0)
            let score = fused + 0.15 * lexical + 0.05 * recency
            reranked.append((id, score))
        }
        reranked.sort { $0.score > $1.score }

        return reranked.prefix(limit).compactMap { item -> [String: Any]? in
            guard var r = byId[item.id] else { return nil }
            let text = r.str("text")
            r["snippet"] = String(text.prefix(400))
            r.removeValue(forKey: "text")
            r["score"] = item.score
            return r
        }
    }

    // MARK: - Facts & reminders (the "brain")

    @discardableResult
    func addFact(kind: String, title: String, detail: String, dueTs: Double?, source: String) -> Int64? {
        let existing = db.query("SELECT id FROM facts WHERE kind = ? AND title = ?", [kind, title])
        if !existing.isEmpty { return nil }
        let id = db.run("""
            INSERT OR IGNORE INTO facts (kind, title, detail, due_ts, created_ts, source, status)
            VALUES (?, ?, ?, ?, ?, ?, 'open')
            """, [kind, title, detail, dueTs, Date().timeIntervalSince1970, source])
        guard id > 0 else { return nil }
        if let due = dueTs {
            let dayBefore = due - 86400
            let now = Date().timeIntervalSince1970
            if dayBefore > now { addReminder(factId: id, fireTs: dayBefore, intervalIdx: -1) }
            if due > now { addReminder(factId: id, fireTs: due, intervalIdx: -1) }
        }
        return id
    }

    func addReminder(factId: Int64, fireTs: Double, intervalIdx: Int) {
        db.run("INSERT INTO reminders (fact_id, fire_ts, interval_idx, status) VALUES (?, ?, ?, 'pending')",
               [factId, fireTs, intervalIdx])
    }

    /// Spaced-repetition ladder for a fact (e.g. a watched lecture). Idempotent:
    /// clears any existing pending revision reminders for the fact first, so
    /// re-enrolling (or auto-enroll + a manual "revise" tap) never stacks.
    func addRevisionLadder(factId: Int64, baseTs: Double? = nil) {
        db.run("""
            UPDATE reminders SET status = 'cancelled'
            WHERE fact_id = ? AND status = 'pending' AND interval_idx >= 0
            """, [factId])
        let base = baseTs ?? Date().timeIntervalSince1970
        let days: [Double] = [1, 3, 7, 14, 30]
        for (i, d) in days.enumerated() {
            addReminder(factId: factId, fireTs: base + d * 86400, intervalIdx: i)
        }
    }

    func openFacts() -> [[String: Any]] {
        return db.query("SELECT * FROM facts WHERE status = 'open' ORDER BY COALESCE(due_ts, 9e12) ASC, created_ts DESC LIMIT 100")
    }

    func importantToday() -> [String: Any] {
        let now = Date().timeIntervalSince1970
        let endOfDay = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970 + 86400
        let dueSoon = db.query("""
            SELECT * FROM facts WHERE status = 'open' AND due_ts IS NOT NULL AND due_ts < ?
            ORDER BY due_ts ASC LIMIT 30
            """, [endOfDay + 2 * 86400])
        let firingToday = db.query("""
            SELECT r.id AS reminder_id, r.fire_ts, r.interval_idx, f.id AS fact_id, f.kind, f.title, f.detail
            FROM reminders r JOIN facts f ON f.id = r.fact_id
            WHERE r.status = 'pending' AND r.fire_ts < ? AND f.status = 'open'
            ORDER BY r.fire_ts ASC LIMIT 30
            """, [endOfDay])
        let overdue = dueSoon.filter { $0.double("due_ts") < now }
        return ["due_soon": dueSoon, "revisions_today": firingToday, "overdue_count": overdue.count]
    }

    func setFactStatus(id: Int64, status: String) {
        if status == "done" {
            db.run("UPDATE facts SET status = ?, done_ts = ? WHERE id = ?",
                   [status, Date().timeIntervalSince1970, id])
        } else {
            db.run("UPDATE facts SET status = ? WHERE id = ?", [status, id])
        }
        if status != "open" {
            db.run("UPDATE reminders SET status = 'cancelled' WHERE fact_id = ? AND status = 'pending'", [id])
        }
    }

    func pendingReminders(before ts: Double) -> [[String: Any]] {
        return db.query("""
            SELECT r.id AS reminder_id, r.fire_ts, r.interval_idx, f.id AS fact_id, f.kind, f.title
            FROM reminders r JOIN facts f ON f.id = r.fact_id
            WHERE r.status = 'pending' AND r.fire_ts <= ? AND f.status = 'open'
            ORDER BY r.fire_ts ASC LIMIT 20
            """, [ts])
    }

    func markReminderFired(id: Int64) {
        db.run("UPDATE reminders SET status = 'fired' WHERE id = ?", [id])
    }

    /// The user actually did this revision (vs. just receiving the nudge).
    func markReminderDone(id: Int64) {
        db.run("UPDATE reminders SET status = 'done', done_ts = ? WHERE id = ? AND status != 'cancelled'",
               [Date().timeIntervalSince1970, id])
    }

    /// Everything the History calendar needs for a window: watch events, each
    /// revision-ladder step with its outcome, and deadline/bill due dates.
    /// Outcomes: done (revised), missed (day passed, never marked done),
    /// due (scheduled today, still actionable), upcoming (in the future),
    /// closed (the parent item was completed/dismissed before this step).
    func history(from: Double, to: Double) -> [[String: Any]] {
        var items: [[String: Any]] = []
        let now = Date().timeIntervalSince1970
        let todayStart = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970

        // Attach a clickable link when the fact's detail is a URL (watched
        // facts store the video URL there).
        func withLink(_ item: [String: Any], _ detail: String) -> [String: Any] {
            var item = item
            if detail.hasPrefix("http://") || detail.hasPrefix("https://") { item["url"] = detail }
            return item
        }

        // Watch events — the day the video/lecture was first seen.
        for f in db.query("""
            SELECT id, title, detail, created_ts FROM facts
            WHERE kind = 'watched' AND created_ts >= ? AND created_ts < ?
            ORDER BY created_ts ASC
            """, [from, to]) {
            items.append(withLink(["type": "watched", "fact_id": f.int("id"), "title": f.str("title"),
                                   "ts": f.double("created_ts"), "status": "watched"],
                                  f.str("detail")))
        }

        // Revision-ladder steps (interval_idx >= 0; idx -1 is a deadline nudge,
        // which the deadline item below already represents).
        for r in db.query("""
            SELECT r.id AS reminder_id, r.fire_ts, r.interval_idx, r.status AS rstatus,
                   f.id AS fact_id, f.title, f.detail, f.status AS fstatus
            FROM reminders r JOIN facts f ON f.id = r.fact_id
            WHERE r.interval_idx >= 0 AND r.status != 'cancelled'
              AND r.fire_ts >= ? AND r.fire_ts < ?
            ORDER BY r.fire_ts ASC
            """, [from, to]) {
            let fireTs = r.double("fire_ts")
            let status: String
            if r.str("rstatus") == "done" { status = "done" }
            else if r.str("fstatus") != "open" { status = "closed" }
            else if fireTs < todayStart { status = "missed" }
            else if fireTs <= now { status = "due" }
            else { status = "upcoming" }
            items.append(withLink(["type": "revision", "reminder_id": r.int("reminder_id"),
                                   "fact_id": r.int("fact_id"), "title": r.str("title"),
                                   "ts": fireTs, "interval_idx": r.int("interval_idx"),
                                   "status": status],
                                  r.str("detail")))
        }

        // Every non-watched item with a due date — bills, deadlines, and
        // items you add in the Brain tab — placed on its due date. Marking
        // one done in Brain shows up here as done.
        for f in db.query("""
            SELECT id, kind, title, detail, due_ts, status FROM facts
            WHERE kind != 'watched' AND due_ts IS NOT NULL
              AND due_ts >= ? AND due_ts < ?
            ORDER BY due_ts ASC
            """, [from, to]) {
            let status: String
            switch f.str("status") {
            case "done": status = "done"
            case "dismissed": status = "closed"
            default: status = f.double("due_ts") < now ? "missed" : "upcoming"
            }
            items.append(withLink(["type": "deadline", "fact_id": f.int("id"), "kind": f.str("kind"),
                                   "title": f.str("title"), "ts": f.double("due_ts"), "status": status],
                                  f.str("detail")))
        }

        // Completed items with NO due date — placed on the day they were
        // marked done, so Brain completions always reflect in the calendar.
        for f in db.query("""
            SELECT id, kind, title, detail, done_ts FROM facts
            WHERE kind != 'watched' AND due_ts IS NULL AND status = 'done'
              AND done_ts IS NOT NULL AND done_ts >= ? AND done_ts < ?
            ORDER BY done_ts ASC
            """, [from, to]) {
            items.append(withLink(["type": "deadline", "fact_id": f.int("id"), "kind": f.str("kind"),
                                   "title": f.str("title"), "ts": f.double("done_ts"), "status": "done"],
                                  f.str("detail")))
        }

        return items
    }

    /// One row per fact — the NEXT pending reminder plus how many remain — so a
    /// 5-step revision ladder shows as a single item, not five duplicates.
    func upcomingReminders() -> [[String: Any]] {
        return db.query("""
            SELECT f.id AS fact_id, f.kind, f.title,
                   MIN(r.fire_ts) AS fire_ts,
                   COUNT(*) AS remaining
            FROM reminders r JOIN facts f ON f.id = r.fact_id
            WHERE r.status = 'pending' AND f.status = 'open'
            GROUP BY r.fact_id
            ORDER BY fire_ts ASC LIMIT 50
            """)
    }

    // MARK: - Privacy

    func purge(from: Double, to: Double) -> Int {
        let n = db.query("SELECT COUNT(*) AS n FROM chunks WHERE ts >= ? AND ts <= ?", [from, to]).first?.int("n") ?? 0
        db.run("DELETE FROM chunks WHERE ts >= ? AND ts <= ?", [from, to])
        db.run("DELETE FROM events WHERE ts_start >= ? AND ts_start <= ?", [from, to])
        db.run("DELETE FROM embeddings WHERE chunk_id NOT IN (SELECT id FROM chunks)")
        return n
    }

    func dbSizeBytes() -> Int64 {
        let path = dataDir.appendingPathComponent("mitthuai.db").path
        let attrs = try? FileManager.default.attributesOfItem(atPath: path)
        return (attrs?[.size] as? Int64) ?? 0
    }

    func counts() -> [String: Any] {
        let events = db.query("SELECT COUNT(*) AS n FROM events").first?.int("n") ?? 0
        let chunks = db.query("SELECT COUNT(*) AS n FROM chunks").first?.int("n") ?? 0
        let embedded = db.query("SELECT COUNT(*) AS n FROM embeddings").first?.int("n") ?? 0
        let facts = db.query("SELECT COUNT(*) AS n FROM facts").first?.int("n") ?? 0
        return ["events": events, "chunks": chunks, "embedded": embedded, "facts": facts,
                "db_bytes": dbSizeBytes()]
    }
}
