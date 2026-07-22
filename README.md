# HelloMac 🧠

Your Mac's memory. HelloMac lives in the menu bar, passively logs what you do
(apps, window titles, and the **text on your screen** via macOS accessibility),
and turns it into:

- **A timeline** — "what did I do today / last Tuesday?"
- **A searchable memory** — hybrid semantic + keyword search over everything you've seen ("that video about transformers", "the electricity bill")
- **A brain** — bills, deadlines, and watched videos are auto-extracted into tasks with due dates
- **Spaced-repetition reminders** — watched a lecture? Get revision nudges after 1/3/7/14/30 days
- **An MCP server** — plug your memory into Claude Code, Claude Desktop, or any MCP client as a first-class tool

**100% local.** SQLite on your disk, on-device Apple embeddings, server bound to
`127.0.0.1` with a bearer token. No cloud, no telemetry.

---

## Build & run

Requires macOS 12+ and Xcode command line tools (`xcode-select --install`).

```bash
./build.sh
open build/HelloMac.app
```

### Permissions (first run)

1. **Accessibility** (required) — System Settings → Privacy & Security → Accessibility → enable HelloMac. This is how window titles and on-screen text are read (the same API VoiceOver uses). Relaunch the app after granting.
2. **Automation** (optional) — prompted the first time a browser URL is read. Powers per-tab URLs in the timeline.
3. **Notifications** (optional) — for revision/deadline reminders.

## Dashboard

Click the 🧠 menu bar icon → **Open Dashboard** (it opens `http://localhost:4789/`
with your access token). Tabs:

- **Today** — active/idle time, focus-vs-multitasking score, tracked-event count, category-distribution donut, top-apps chart, and a full session timeline. Each timeline row has inline **Study / Entertainment / Work / Other** chips — tap one to teach HelloMac how to categorize that title.
- **Search** — semantic + keyword search with date filters
- **Brain** — open items (bills/deadlines/watched/notes), upcoming reminders
- **Rules** — create categorization rules (app + title-contains → category). A new rule re-tags matching history immediately, including same-title activity within ±10 minutes so a video you flicked away from and back to lands in one bucket. Delete any rule to re-categorize affected activity.
- **Settings** — pause, excluded apps, capture toggles, data purge, MCP setup

### Categories & focus score

Activity rolls up into four buckets — **Study, Entertainment, Work, Other** — chosen by your rules first, then a built-in heuristic. Study + Work count as *focus*; the focus-vs-multitasking score is focus time over total categorized time. You can type any custom category on a rule; the donut and chips adapt.

## Connect Claude (MCP)

The Settings tab shows ready-to-copy commands with your token filled in:

**Claude Code:**
```bash
claude mcp add --transport http hellomac http://localhost:4789/mcp \
  --header "Authorization: Bearer <your-token>"
```

**Claude Desktop** (`~/Library/Application Support/Claude/claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "hellomac": {
      "command": "npx",
      "args": ["mcp-remote", "http://localhost:4789/mcp",
               "--header", "Authorization: Bearer <your-token>"]
    }
  }
}
```

Then ask Claude things like *"what did I do today?"*, *"when did I watch that
GPU video?"*, *"what's important today?"*, *"remind me to pay the bill in 4 days"*.

### MCP tools exposed

| Tool | What it does |
|---|---|
| `search_memory` | Hybrid search over captured screen text, with time filters |
| `get_timeline` | Sessions + stats for a day |
| `get_important` | Bills/deadlines due soon + revisions firing today |
| `get_daily_digest` | Readable end-of-day review |
| `create_reminder` | Add a task/reminder with a due date |
| `complete_item` | Mark an item done |
| `add_revision` | Enroll an item in the 1/3/7/14/30-day revision ladder |

## Privacy

- Everything stays in `~/Library/Application Support/HelloMac/hellomac.db`
- Server binds `127.0.0.1` only; every request needs the bearer token
- Password managers are excluded by default (editable list); secure text fields and private/incognito windows are never read
- Pause anytime from the menu bar; delete any date range from Settings

## Architecture

```
menu bar app (SwiftUI)
  ├─ Tracker         1s sampling: frontmost app/window/idle → events table
  ├─ ContentCapture  10s: AX text of focused window → chunks (dedup, ~800 chars)
  │    ├─ Embeddings on-device NLEmbedding vectors → embeddings table
  │    └─ Extractors bills/deadlines/watched → facts (+ auto reminders)
  ├─ ReminderScheduler due reminders → macOS notifications
  └─ HttpServer (127.0.0.1:4789, bearer token)
       ├─ /            dashboard (embedded SPA)
       ├─ /api/*       REST for the dashboard
       └─ /mcp         MCP streamable-HTTP endpoint
storage: SQLite (WAL) + FTS5 + vector blobs — one file
```

See `PLAN.md` for the full roadmap (OCR fallback, encryption at rest, local LLM digests…).
