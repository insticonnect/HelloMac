# MitthuAI — website copy

Finished copy, section by section. Paste into any builder. Everything here is
true of the current build; the notes in *Claims and receipts* at the end say
where each number comes from.

---

# HOME

## Hero

> ### Where did your time go?
> ## Your Mac already knows.
>
> MitthuAI sits in your menu bar and quietly remembers what you actually did —
> every app, every tab, every lecture, every deadline that flashed past in an
> email. Then it hands the day back to you: searchable, sorted, and honest.
>
> Free and open source. Runs entirely on your Mac.
>
> **[Download for macOS]**  **[View the source]**
>
> *macOS 12 or newer · Apple Silicon and Intel · no account, no sign-up*

**Strip under the hero:** 100% on your Mac · No account needed · Open source ·
7 tools for Claude · 5 revision nudges per lecture

---

## The problem

> ## You can't fix a week you can't see.

**Hours disappear and nobody can tell you where.**
You sat down at nine. It's six. You know you were *busy*. You could not
truthfully say what took the most time, and no timer you have to remember to
start will ever tell you — you only start it on the days you were already
focused.

**Deadlines hide in plain sight.**
The application closes on the 12th. It was in an email you read once, on a
Tuesday, between two other things. It never made it to a list, because getting
it onto a list was a separate job you didn't do.

**You watch a lecture once and it evaporates.**
Two weeks later you remember there *was* a video about it. Not what it said,
not where it was, not whether you finished it.

> None of that is a discipline problem. It's a memory problem — and your Mac
> already has the memory. It just wasn't keeping notes.

---

## What it does

### 1. See where your time actually goes

No timers. No "what are you working on?" prompts. MitthuAI notices for you.

Every app and window becomes a session on a timeline, sorted into **Study,
Entertainment, Work** or your own categories, with a **focus score** that
separates real stretches of work from half an hour of flicking between tabs.
Switch tabs inside one app and it stays one row — labelled with whatever you
actually spent the time on, not whichever tab you closed on.

Then zoom out. **Week, month, and three-month views**, each compared against the
period before, with a month-by-month table and chart. Watch a habit form, or
watch one quietly fall apart.

*"3h 12m of focus across Xcode and Notion, 48m on YouTube. Your longest stretch
was 10:05 AM–11:40 AM."*

### 2. Search everything you've ever seen

Not just filenames. The actual text that was on your screen.

Semantic and keyword search work together, so *"that article about attention
heads"* finds the page even when it never used those words. Filter by date,
jump straight back to the source.

*"When did I watch that GPU video?" — Tuesday at 9:24 PM, 22 minutes, and
here's the link.*

### 3. It catches what you'd forget

**Deadlines and bills** get lifted off the screen as you read them, with the
right date — parsed by the same on-device engine macOS uses for "Add to
Calendar", anchored to the actual deadline word. From an email, it also notes
**who sent it** and any Meet, Zoom or Teams link, so the reminder tells you who
and where.

**Meetings** count too. *"Let's meet tomorrow over Meet"* becomes an item due
tomorrow, once — not once for the tab title, once for the subject line and once
for the sentence in the body.

**Lectures enrol themselves in a revision ladder**: nudges after 1, 3, 7, 14
and 30 days, the spacing that actually moves things into long-term memory. It
recognises a video by how it behaves — a player timecode, transport controls,
audio, a video-shaped link — so a lecture embedded in a college portal is
caught exactly like a YouTube one.

Export the whole schedule to Google Calendar, Apple Calendar or Outlook.

### 4. And then — ask Claude about your own life

Connect once and Claude answers from your memory through a native MCP server:
seven tools covering search, your timeline, what's due, the daily digest,
reminders and revisions.

*"What did I do today?" · "What's important this week?" · "Remind me to pay
rent in 4 days."*

Works with Claude Code and Claude Desktop out of the box. Entirely optional —
MitthuAI is a complete app without it.

---

## How it works

1. **Download and open it.** One drag. No installer, no account, no sign-up.
2. **Grant Accessibility.** One permission, the same macOS API screen readers
   use. It's how window titles and on-screen text are read.
3. **Forget about it.** It lives in the menu bar with no dock icon and no
   window, and starts with your Mac.
4. **Open the dashboard when you're curious.** `localhost:4789`, whenever you
   want to know where the week went.

---

## Privacy strip

> ## It watches your screen. So it had better be trustworthy.
>
> Everything lives in **one SQLite file on your disk**. The server binds to
> `127.0.0.1` and every request needs a bearer token. Search runs on
> **Apple's on-device embeddings**. There is no telemetry, no analytics, no
> account, and no server to send anything to.
>
> **Nothing leaves your Mac unless you switch it on** — and three things can be
> switched on, all off by default: turbo search with your own OpenAI key, web
> access for Claude.ai, and Apple's on-device model. Each is a toggle you own.
>
> Secure text fields, password managers and private windows are never read.
> Pause any time, exclude any app, delete any date range.
>
> And because it's open source, you don't have to take our word for any of it.
>
> **[Read the privacy page]**  **[Read the source]**

---

## FAQ

**Does my data leave my Mac?**
No — not unless you turn on one of three optional features, each off by
default: turbo search (sends captured text to OpenAI with your own key), web
access for Claude.ai (routes Claude's questions through a relay to your Mac),
and Apple's on-device model (which stays on the device anyway). Leave them off
and MitthuAI never makes a network request.

**Why does it need Accessibility permission?**
It's how macOS lets an app read window titles and on-screen text — the same API
VoiceOver uses. Without it there is no timeline and nothing to search. Secure
text fields, password managers and private browsing windows are excluded.

**Does it slow my Mac down?**
It samples the front window once a second and reads text every ten seconds,
which is a rounding error on any Mac that runs macOS 12. No background
indexing, no daemons.

**Is it really free?**
Yes, and open source. No accounts, no subscription, no paid tier.

**Why only macOS?**
It's built directly on macOS — the accessibility APIs, IOKit power assertions,
CoreAudio, Apple's on-device embeddings. That's what makes it fast and private,
and it's also what makes it Mac-only. A cross-platform version would be a
different, worse app.

**Can I delete everything?**
It's your file on your disk. Purge any date range from Settings, or delete
`~/Library/Application Support/MitthuAI/` and it's gone.

---

## Closing CTA

> ## Your week is already recorded. Go and read it.
>
> Free, open source, and it never leaves your Mac.
>
> **[Download for macOS]**  **[Star on GitHub]**
>
> *macOS 12+ · Apple Silicon and Intel*

---

# ABOUT

> # Built because I kept forgetting things.
> ## An open-source Mac app, made in the open, that runs entirely on your machine.

## Why this exists

This started as a student's problem. Online-degree lectures pile up faster than
anyone watches them. Application deadlines arrive inside newsletters you skim
at 1 AM. You finish a week genuinely unable to say where it went — and the
tools meant to fix that all ask you to *do* something first: start a timer, tag
a task, fill in a sheet. On the days you most need them, you don't.

So MitthuAI takes the opposite bet: **the Mac should keep the notes.** It's
already the thing that saw the lecture, the email and the four hours in a code
editor. It should be able to tell you about them.

## Why it's open source

An app that reads your screen is asking for real trust. The only honest answer
to that is to let you check.

- **5,713 lines of Swift in 24 files.** Small enough that a curious person can
  read all of it in an afternoon.
- **Zero dependencies.** No package manager, no vendored frameworks, nothing
  pulled from a registry at build time. Just Swift against Apple's own
  frameworks.
- **Builds in about a minute.** `git clone`, `./build.sh`, done. What you run
  is what you compiled.
- **Nothing hidden.** The capture, the database schema, the extraction rules,
  the network code — all of it is in the repo.

If a privacy claim isn't verifiable, it's marketing. This one is `grep`-able.

## Why it's offline

Not as a feature. As the point.

A tool that watches your screen and ships that somewhere is a surveillance
product no matter how nice the dashboard is. Keeping everything on the device
isn't a limitation we're apologising for — it's the reason the app is allowed
to see this much in the first place.

The optional extras follow the same rule: each is off until you turn it on, and
each says plainly what it sends where.

## Why Mac only

MitthuAI is built out of macOS, not merely for it:

- **Accessibility APIs** read window text — the same interface VoiceOver uses.
- **IOKit power assertions** reveal when something is genuinely playing.
- **CoreAudio** hears when sound is actually coming out.
- **Apple's Natural Language embeddings** make search semantic without a cloud.
- **Apple Events** read the front tab's URL from Safari, Chrome and friends.
- **SQLite with FTS5**, already in the system, does the indexing.

Every one of those is Apple-specific. A cross-platform port wouldn't be a port
— it'd be a rewrite into something slower and less private. We'd rather do one
platform properly.

## What it doesn't do

Open source means being straight about the edges too:

- It doesn't sync between devices. One Mac, one database.
- It doesn't read email, files or anything you haven't looked at.
- It isn't a blocker or a nanny — no shaming, no site blocking.
- It reads what's on screen, so a lecture you left playing in a background tab
  is a lecture it can't see.
- Trends cover months and a full year at a time, not multiple years.

## Contributing

Issues, ideas and pull requests are all welcome — the extraction rules
especially, since every inbox and portal is written a little differently. If
MitthuAI misses something it should have caught, that's a bug worth reporting,
and Settings has a detections log that shows exactly why it made the call it
made.

**[GitHub](https://github.com/insticonnect/HelloMac)**

---

# PRIVACY

> # What it reads, what it never reads, and where it all goes.

## What it reads

Window titles, the visible text of the front window, the front tab's URL in
supported browsers, and how long each window stayed in front. That's what
builds the timeline, the search index and the reminders.

## What it never reads

- **Secure text fields.** Password boxes are skipped at the accessibility
  level — the app never receives them.
- **Password managers.** 1Password, Keychain Access, Bitwarden, KeePassXC and
  Apple Passwords are excluded by default, and you can add any app to that
  list.
- **Private windows.** Incognito and private browsing windows are detected and
  skipped.
- **Anything you haven't opened.** It reads screens, not disks. Your files,
  mailbox and photo library are never touched.

## Where it lives

One SQLite file: `~/Library/Application Support/MitthuAI/mitthuai.db`. The
dashboard is served from `127.0.0.1:4789` and every request needs a bearer
token, so nothing else on your network can reach it. Secrets like an API key go
to the macOS Keychain, never the database.

## The three optional extras

All off by default. Each one is the only way data can leave your Mac:

| Feature | What it sends | Where |
|---|---|---|
| Turbo search | Captured text, for embedding | OpenAI, with your own API key and billing |
| Claude.ai web access | Claude's questions and the answers | A relay that routes to your Mac; your memory stays on the device |
| Apple on-device model | Nothing | Stays on the Mac; needs macOS 26 with Apple Intelligence |

Claude Code and Claude Desktop connect over `localhost` and need none of these.

## Your controls

- **Pause** capture from the menu bar at any time.
- **Exclude** any app from ever being read.
- **Turn off** on-screen text capture or URL capture separately.
- **Delete** any date range from Settings.
- **Remove everything** by deleting the folder above.

There is no telemetry, no crash reporting, no analytics and no account.

---

# FEATURES (the fuller list)

**Timeline & time analysis**
Passive per-app and per-window logging · idle detection · Study / Entertainment
/ Work / custom categories · focus-vs-multitasking score · category donut and
top-app charts · session timeline with inline re-tagging · rules that re-tag
your history retroactively · week, month and three-month views · comparisons
against the previous period · month-by-month table and chart.

**Memory & search**
On-screen text captured and chunked · hybrid semantic + keyword search
(Apple's on-device embeddings + SQLite FTS5) · date filters · duplicate screens
hashed out · jump back to the source.

**The Brain**
Deadlines and bills read off the screen with real dates · sender and meeting
link captured from email · your own editable note on any item · a "check date"
flag when a date is ambiguous, with one-click correction · one item per thing,
however many times it appears on screen · marketing urgency filtered out.

**Revision**
Automatic 1 / 3 / 7 / 14 / 30-day ladder for study videos · works on embedded
players and college portals, not just YouTube · total watch time accumulated
across sittings · revision calendar with done / missed / upcoming · export to
Google Calendar, Apple Calendar or Outlook.

**For Claude**
Native MCP server with 7 tools — `search_memory`, `get_timeline`,
`get_important`, `get_daily_digest`, `create_reminder`, `complete_item`,
`add_revision`.

**The app itself**
Menu bar only, no dock icon · starts at login · pause any time · one SQLite
file · macOS 12+ · Apple Silicon and Intel · open source · no dependencies.

---

# Claims and receipts

For whoever builds the site — every number above, and where it comes from, so
nothing here is guesswork:

| Claim | Source |
|---|---|
| 5,713 lines, 24 Swift files | `Sources/MitthuAI/*.swift` |
| Zero dependencies | no package manager; `build.sh` calls `swiftc` directly |
| 7 MCP tools | `McpServer.swift` tool definitions |
| 1 / 3 / 7 / 14 / 30-day ladder | `Store.addRevisionLadder` |
| macOS 12+, Apple Silicon and Intel | `build.sh` target, `Info.plist` |
| localhost + bearer token | `HttpServer.swift` |
| Three opt-ins, all off by default | `Config.swift` — `turboEmbeddings`, `relayEnabled`, `modelAssist` |
| Samples once a second, text every 10s | `Tracker.swift`, `ContentCapture.swift` timers |
| Months and a year, not multiple years | report caps at 366 days, history at 400 (`Api.swift`) |

**Deliberately not claimed:** multi-year analysis, syncing between Macs, and
any absolute "nothing ever leaves your Mac" line — the three opt-ins make the
qualified version the honest one.
