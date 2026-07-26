# MitthuAI 🧠

Your Mac's memory. MitthuAI lives in the menu bar, passively logs what you do
(apps, window titles, and the **text on your screen** via macOS accessibility),
and turns it into:

- **A timeline** — "what did I do today / last Tuesday?"
- **A searchable memory** — hybrid semantic + keyword search over everything you've seen ("that video about transformers", "the electricity bill")
- **A brain** — bills, deadlines, and watched videos are auto-extracted into tasks with due dates
- **Spaced-repetition reminders** — watched a lecture? Get revision nudges after 1/3/7/14/30 days
- **An MCP server** — plug your memory into Claude Code, Claude Desktop, or any MCP client as a first-class tool

**100% local.** SQLite on your disk, on-device Apple embeddings, server bound to
`127.0.0.1` with a bearer token. No cloud, no telemetry.

> **Naming:** the app is **MitthuAI** 🦜 everywhere — bundle, menu bar, dashboard
> and data folder. Only the *GitHub repository* is still called `HelloMac`, so
> the clone URL below keeps the old name.
>
> **Upgrading from a HelloMac build?** Your data moves itself. On first launch
> MitthuAI copies `~/Library/Application Support/HelloMac/hellomac.db` to
> `~/Library/Application Support/MitthuAI/mitthuai.db` (the old folder is left
> in place as a backup) and carries your Keychain secrets over. Two manual
> steps, because macOS sees a renamed bundle as a brand-new app:
> 1. Re-grant **Accessibility** in System Settings → Privacy & Security, and
>    remove the stale `HelloMac` entry there.
> 2. Delete the old `build/HelloMac.app` if you kept a copy, so you don't launch
>    both at once — two instances would fight over port 4789.

---

## Quick start (new here? start at step 1)

**Requirements:** a Mac running macOS 12 or newer. Nothing else — no Node, no
Homebrew, no package manager. The app is plain Swift against system frameworks.

**1. Install Xcode command line tools** (skip if `swiftc --version` already works):

```bash
xcode-select --install
```

**2. Clone the repo:**

```bash
git clone https://github.com/insticonnect/HelloMac.git
cd HelloMac
```

**3. Build it** (takes about a minute; everything lands in `build/`):

```bash
./build.sh
```

If you get `permission denied`, run `chmod +x build.sh` first.

**4. Launch it:**

```bash
open build/MitthuAI.app
```

A 🦜 parrot icon appears in your menu bar — that's the app. There's no dock icon
and no window; everything happens from the menu bar and the dashboard.

**5. Grant permissions (first run):**

1. **Accessibility** (required) — System Settings → Privacy & Security → Accessibility → enable MitthuAI. This is how window titles and on-screen text are read (the same API VoiceOver uses). **Quit and relaunch the app after granting**, or capture stays empty.
2. **Automation** (optional) — prompted the first time a browser URL is read. Powers per-tab URLs in the timeline.
3. **Notifications** (optional) — for revision/deadline reminders.

**6. Open the dashboard:** click the 🦜 menu bar icon → **Open Dashboard**. It
opens `http://localhost:4789/` with your access token attached. Give it a few
minutes of normal use before expecting the timeline to fill in.

## Updating to a newer version

Pull the latest code and rebuild — same two commands every time:

```bash
git pull
./build.sh
```

Then quit the app from the menu bar (🦜 → Quit) and `open build/MitthuAI.app`
again. Quitting first is the safe order, since the rebuild replaces the binary
the running app is using.

**Your data survives updates.** Everything lives in
`~/Library/Application Support/MitthuAI/mitthuai.db`, which the build never
touches — new columns and tables are migrated automatically on launch. Your
access token, settings, and rules carry over too, so you don't need to
reconnect Claude after an update.

## Dashboard

Click the 🦜 menu bar icon → **Open Dashboard** (it opens `http://localhost:4789/`
with your access token). Tabs:

- **Today** — active/idle time, focus-vs-multitasking score, tracked-event count, category-distribution donut, top-apps chart, and a full session timeline. Each timeline row has inline **Study / Entertainment / Work / Other** chips — tap one to teach MitthuAI how to categorize that title.
- **Search** — semantic + keyword search with date filters
- **Brain** — open items (bills/deadlines/watched/notes), upcoming reminders
- **History** — a revision calendar with Week / Month / 3-Month views (◀ ▶ to move between periods). Shows when you watched each video, which revisions you did, missed, or have coming up, with summary cards vs the previous period and a month-by-month comparison table + chart in the 3-month view. Click any day to see details and mark a revision **did it ✓**. **Export .ics** downloads the upcoming schedule for Google Calendar (Settings → Import & export), Apple Calendar, or Outlook; each upcoming item also has a one-click **+ GCal** link.
- **Rules** — create categorization rules (app + title-contains → category). A new rule re-tags matching history immediately, including same-title activity within ±10 minutes so a video you flicked away from and back to lands in one bucket. Delete any rule to re-categorize affected activity.
- **Settings** — pause, excluded apps, capture toggles, data purge, MCP setup

### Categories & focus score

Activity rolls up into four buckets — **Study, Entertainment, Work, Other** — chosen by your rules first, then a built-in heuristic. Study + Work count as *focus*; the focus-vs-multitasking score is focus time over total categorized time. You can type any custom category on a rule; the donut and chips adapt.

## Connect Claude (MCP)

The Settings tab shows ready-to-copy commands with your token filled in:

**Claude Code:**
```bash
claude mcp add --transport http mitthuai http://localhost:4789/mcp \
  --header "Authorization: Bearer <your-token>"
```

**Claude Desktop** (`~/Library/Application Support/Claude/claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "mitthuai": {
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

## Search quality & embeddings

- **Default:** on-device Apple embeddings — private, free, offline, English.
- **Turbo (opt-in):** paste your own OpenAI API key in Settings to use
  `text-embedding-3-small` (multilingual, higher accuracy). The key is stored in
  the **macOS Keychain** (never in the database), text is sent to OpenAI only
  while enabled, and OpenAI bills you directly.
- **Retrieval** is hybrid (BM25 keyword + vector cosine, reciprocal-rank fusion)
  with **multi-query** support (Claude can pass several angles), a **rerank**
  pass adding lexical-overlap and recency signals, and **time filters**.
- **No duplicate bloat:** identical screens are hashed out, and *near-identical*
  screens (embedding cosine > 0.95 within an app) are suppressed before storage.
- Vectors are tagged with the model that produced them, so switching backends
  never corrupts search over older history.

The MCP server also advertises a retrieval **playbook** (via the `initialize`
`instructions` field) telling connected AI clients to fetch comprehensively.

## Privacy

- Everything stays in `~/Library/Application Support/MitthuAI/mitthuai.db`
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
