# HelloMac — Personal Activity Memory for macOS

A menu-bar app that continuously logs what you do on your Mac (apps, window titles, on-screen text), stores it locally as a searchable timeline + vector memory, generates reminders and daily reviews, and exposes everything through a local dashboard and an MCP server so any AI assistant can query your memory.

Think of it as: **Rewind-style capture + personal knowledge base + spaced-repetition reminders + MCP access — 100% local, macOS only.**

---

## 1. Core Ideas

1. **Capture** — passively record which app/window/site you're in and the text visible on screen, using the macOS Accessibility APIs (the same machinery VoiceOver uses for blind users — no screenshots needed for most apps).
2. **Timeline** — every event is timestamped, so you can ask "what did I do today?" or "when did I watch that video?" and get a time-ordered answer.
3. **Memory** — text is chunked and embedded into a local vector index, so search works by meaning ("that article about GPU pricing"), not just keywords.
4. **Brain / Tasks** — a pipeline extracts commitments and facts ("bill pending, due in 4 days") from what you see (mail, browser, etc.) into a structured tasks/facts table, so "what's important today?" has a real answer.
5. **Reminders / Revision** — spaced-repetition scheduling: "you watched this lecture — revise in 1 day, 3 days, 7 days."
6. **Access** — a menu-bar (top bar) app for control; a local web dashboard on `localhost:<port>` usable from any browser; an MCP server so Claude (or any MCP client) can search your memory as a tool.
7. **Privacy** — everything stays on the Mac. Encrypted at rest. Per-app exclusion list. Pause button. Nothing leaves the machine unless you connect a client yourself.

---

## 2. Architecture Overview

```
┌──────────────────────────── macOS ────────────────────────────┐
│                                                               │
│  Menu Bar App (SwiftUI, NSStatusItem)                         │
│  ├── start/pause capture, open dashboard, privacy toggles     │
│  │                                                            │
│  Capture Engine (Swift)                                       │
│  ├── NSWorkspace app-switch events                            │
│  ├── AXUIElement: focused window title + visible text (AX)    │
│  ├── Browser URL/title (AX + AppleScript for Safari/Chrome)   │
│  └── Fallback: screenshot + Vision OCR for non-AX apps        │
│         │                                                     │
│         ▼                                                     │
│  Ingest Pipeline                                              │
│  ├── debounce/dedupe (don't store the same screen twice)      │
│  ├── sessionize (group events into activity sessions)         │
│  ├── chunk + embed (local embedding model)                    │
│  └── extractors: tasks/deadlines/bills, watched-video events  │
│         │                                                     │
│         ▼                                                     │
│  Store: SQLite (WAL) + FTS5 keyword index + sqlite-vec        │
│  (single encrypted DB file in ~/Library/Application Support)  │
│         │                                                     │
│         ▼                                                     │
│  Server (one local process, localhost only)                   │
│  ├── REST/JSON + static dashboard  → http://localhost:PORT    │
│  └── MCP server (streamable HTTP + stdio)                     │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

Two processes total:
- **HelloMac.app** — menu bar UI + capture engine + ingest pipeline (Swift/SwiftUI).
- **hellomac-server** — dashboard + API + MCP, launched/managed by the app (can be Swift, or TypeScript/Node for faster iteration on MCP + web UI).

---

## 3. Capture Layer (macOS-specific)

This is the part you correctly identified: macOS ships deep accessibility support, and we use it instead of brute-force screen recording wherever possible.

| Signal | API | Notes |
|---|---|---|
| Frontmost app changes | `NSWorkspace.didActivateApplicationNotification` | Free, no permissions |
| Window title of focused window | `AXUIElementCopyAttributeValue(kAXTitleAttribute)` | Needs **Accessibility** permission |
| Visible text content | Walk the AX tree (`kAXValueAttribute`, `kAXChildrenAttribute`) of the focused window | Works for native apps, Safari, Mail, Notes… |
| Browser URL | `kAXURLAttribute` on Safari; AppleScript/Chrome AX for Chrome-family | Detect & skip private/incognito windows |
| Media playback ("watched a video") | `MPNowPlayingInfoCenter` / MediaRemote now-playing info + YouTube/Netflix title parsing from window title | This powers "when did I watch X" and revision reminders |
| Idle detection | `CGEventSourceSecondsSinceLastEventType` | Don't log when away; close sessions |
| OCR fallback | `CGWindowListCreateImage` + Vision `VNRecognizeTextRequest` | Only for apps whose AX tree is empty (some Electron/games). Needs **Screen Recording** permission. Off by default. |

**Capture cadence:** event-driven (app/window/title change) + a low-frequency poll (every ~5–10s) of the focused window's AX text, with content hashing so unchanged screens are never re-stored.

**Permissions UX:** first-run onboarding walks the user through granting Accessibility (required) and Screen Recording (optional, for OCR fallback), with live status checks.

---

## 4. Data Model (SQLite)

One local database: `~/Library/Application Support/HelloMac/memory.db` (SQLCipher-encrypted, key in macOS Keychain).

```sql
-- Raw timeline: every observation
events(
  id INTEGER PRIMARY KEY,
  ts_start INTEGER, ts_end INTEGER,        -- unix ms; end updated while unchanged
  app_bundle_id TEXT, app_name TEXT,
  window_title TEXT,
  url TEXT,                                 -- browsers only
  kind TEXT,                                -- 'window' | 'media' | 'ocr'
  content_hash TEXT                         -- dedupe key
)

-- Captured text, chunked for retrieval
chunks(
  id INTEGER PRIMARY KEY,
  event_id INTEGER REFERENCES events(id),
  text TEXT,
  ts INTEGER
)
-- FTS5 mirror of chunks(text) for keyword search
-- sqlite-vec table: chunk_embeddings(chunk_id, embedding float[384])

-- Sessions: contiguous activity on one app/topic ("YouTube 21:10–21:48")
sessions(id, ts_start, ts_end, app_name, title, summary TEXT)

-- The "brain": structured things extracted from what you saw
facts(
  id INTEGER PRIMARY KEY,
  kind TEXT,            -- 'task' | 'bill' | 'deadline' | 'note' | 'watched'
  title TEXT, detail TEXT,
  due_ts INTEGER,       -- "bill pending in 4 days" → now+4d
  source_event_id INTEGER,
  status TEXT           -- 'open' | 'done' | 'dismissed'
)

-- Spaced-repetition reminders
reminders(
  id INTEGER PRIMARY KEY,
  fact_id INTEGER REFERENCES facts(id),
  fire_ts INTEGER,
  interval_idx INTEGER, -- position in the 1d/3d/7d/14d… ladder
  status TEXT
)

-- Daily rollups for instant "what did I do today"
daily_digests(date TEXT PRIMARY KEY, summary TEXT, stats_json TEXT)
```

**Why SQLite + sqlite-vec:** one file, zero external services, FTS5 gives keyword search, sqlite-vec gives vector search in the same DB — hybrid retrieval (BM25 + cosine, rank-fused) with time filters is a single query away. Efficient enough for years of personal data.

**Embeddings:** local model, no cloud — e.g. `all-MiniLM-L6-v2` / `bge-small-en` (384-dim) via Core ML or MLX on Apple Silicon. Embedding happens in the background ingest queue, batched.

**Retention:** raw OCR images never stored; text kept per a user-set retention window (default: forever, it's small); DB size shown in the dashboard.

---

## 5. Intelligence Layer

1. **Sessionizer** — merges the event stream into human-level sessions ("Xcode: HelloMac project, 45 min", "YouTube: 'CS231n Lecture 7', 32 min"). Gap > N minutes or app change closes a session.
2. **Daily digest** — at end of day (or on demand), summarize sessions into a readable review: top apps, what you watched/read/wrote, time distribution. Uses a local LLM (MLX, e.g. a small Llama/Qwen) or an optional user-provided API key — user's choice, local by default.
3. **Extractors ("goes into brain")** — rule-based first, LLM-assisted later:
   - Deadline/bill patterns in mail & pages you read ("due", "pending", "expires on", amounts + dates) → `facts(kind='bill'|'deadline', due_ts=…)`.
   - Watched-video detection (media sessions ≥ X minutes) → `facts(kind='watched')` → auto-enroll in the revision ladder if the user opts in per-category (e.g. "study" playlists).
4. **Revision scheduler** — spaced repetition ladder (1d, 3d, 7d, 14d, 30d). Fires macOS notifications (`UNUserNotificationCenter`): "You watched *Lecture 7* 3 days ago — time to revise." Snooze/done/stop feed back into the ladder.
5. **"Important today"** — a single query over `facts` + `reminders` (due today, overdue, firing today), served on the dashboard, in the menu bar dropdown, and as an MCP tool — so when you ask any connected AI "what's important today?", it reflects the same list.

---

## 6. Dashboard (any browser, any port)

Local web app served by `hellomac-server` on a configurable port (default e.g. `localhost:4789`), localhost-bound with a token so other apps/users on the machine can't read your memory.

Views:
- **Timeline** — vertical day view of sessions; click to expand raw events/text. Date picker to "go back in time."
- **Search** — one box, hybrid keyword+semantic, with time filters ("last week"), answers like "when did I watch X" with timestamped hits.
- **Today / Review** — daily digest, time-by-app chart, important items.
- **Brain** — facts/tasks/bills list with due dates; edit/dismiss/complete.
- **Settings** — capture on/off, excluded apps, retention, port, embedding/LLM config, DB size/export.

Stack: static SPA (React or plain Svelte/lit — small) talking to the JSON API. No cloud.

---

## 7. MCP Server

Same server process exposes MCP (streamable HTTP on the same port at `/mcp`, plus stdio mode for local clients like Claude Desktop/Claude Code).

Tools:
- `search_memory(query, from?, to?, app?, k)` — hybrid search over chunks; returns text + timestamps + source app/window.
- `get_timeline(date | range)` — sessions for a day, i.e. "what did I do today."
- `get_important(date?)` — open facts due/overdue + reminders firing.
- `create_reminder(title, due | spaced_from)` / `complete_fact(id)` — let the assistant add/close items.
- `get_daily_digest(date)` — the rendered review.

This is what makes "if I ask important things to do today it should reflect there" work from *any* AI client — the memory is the single source of truth, MCP is the pipe.

---

## 8. Privacy & Security (non-negotiable)

- All data local; server binds `127.0.0.1` only; bearer token for dashboard/MCP.
- SQLCipher encryption at rest; key in Keychain.
- **Exclusion list** (password managers, banking apps by default) + private/incognito browser windows auto-skipped.
- Global pause (menu bar) + "delete last N minutes" and "delete range" actions.
- No analytics, no telemetry.

---

## 9. Tech Stack Summary

| Piece | Choice |
|---|---|
| App + capture | Swift 5.10+, SwiftUI menu bar app, AXUIElement / NSWorkspace / Vision |
| DB | SQLite (WAL) + FTS5 + sqlite-vec, SQLCipher |
| Embeddings | Local MiniLM/BGE-small via Core ML or MLX |
| Summaries/extraction | Rules first; optional local LLM (MLX) or user API key |
| Server + MCP | Node/TypeScript (`@modelcontextprotocol/sdk`, Fastify) *or* Swift (Vapor) — recommend TS for speed of iteration |
| Dashboard | Small SPA (Svelte/React) served by the server |
| Packaging | Xcode, hardened runtime, notarized `.dmg`; server bundled inside the .app and spawned by it |

Prior art worth studying: **Rewind.ai** (capture UX), **screenpipe** (open-source capture pipeline), **ActivityWatch** (event/session model).

---

## 10. Build Plan (phased, each phase ships something usable)

**Phase 0 — Skeleton & permissions spike (repo bootstrap)**
- Xcode project, menu bar app, onboarding that requests/verifies Accessibility permission.
- Proof-of-concept: print focused app + window title + AX text of the frontmost window.

**Phase 1 — Logger (the tracker exists)**
- Event capture (app switches, titles, AX text poll), dedupe, idle detection.
- SQLite schema + writer; sessions built from events.
- Menu bar: pause/resume, today's session list.

**Phase 2 — Timeline dashboard**
- Server + REST API + timeline/search (FTS5 keyword only) UI.
- "What did I do today" answered end-to-end, by time and date.

**Phase 3 — Vector memory**
- Chunking + local embeddings + sqlite-vec; hybrid search with time filters.
- Semantic search in dashboard ("that video about transformers").

**Phase 4 — Brain, reminders, revision**
- Extractors (bills/deadlines/watched), facts table, "Important today".
- Spaced-repetition scheduler + macOS notifications.
- Daily digest generation.

**Phase 5 — MCP**
- MCP tools over the same store; test with Claude Desktop/Claude Code.

**Phase 6 — Hardening & polish**
- Encryption, exclusion lists, delete-range, retention settings, OCR fallback, notarized build.

Suggested repo layout:

```
HelloMac/
├── app/            # Xcode project: menu bar app + capture engine (Swift)
├── server/         # dashboard API + MCP (TypeScript)
├── dashboard/      # web UI (built into server/public)
├── shared/         # DB schema, migrations
└── docs/           # this plan, ADRs
```

---

## 11. Open Decisions (pick before Phase 3/4)

1. **Server language** — TypeScript (fast MCP/web iteration) vs all-Swift (single toolchain). *Recommend TS.*
2. **Summaries/extraction LLM** — pure rules → local MLX model → optional API key. *Recommend shipping rules first.*
3. **Mail integration depth** — passive (you read mail on screen, we capture it) vs active (Mail.app AppleScript/IMAP ingestion even for unread mail). *Passive first; active is a Phase 4+ extension.*
4. **OCR fallback default** — off (privacy-friendly) vs on (better coverage for Electron apps). *Recommend off by default.*
