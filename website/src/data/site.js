// Central place for repeated content so it's easy to tweak.

export const GITHUB_URL = 'https://github.com/insticonnect/HelloMac'

export const NAV_LINKS = [
  { href: '#features', label: 'Features' },
  { href: '#how', label: 'How it works' },
  { href: '#demo', label: 'Demo' },
  { href: '#claude', label: 'For Claude' },
  { href: '#faq', label: 'FAQ' },
]

export const STATS = [
  { value: 100, suffix: '%', label: 'runs on your Mac', sub: 'one SQLite file on your disk' },
  { value: 0, suffix: '', label: 'accounts to create', sub: 'no sign-up, no telemetry' },
  { value: 7, suffix: '', label: 'native tools for Claude', sub: 'via the MCP server' },
  { value: 5, suffix: '×', label: 'spaced-repetition nudges', sub: '1 · 3 · 7 · 14 · 30 days' },
]

export const FEATURES = [
  {
    ic: '⏱️',
    title: 'See where your time actually goes',
    body: 'No timers to start. Every app and window becomes a session, sorted into Study, Entertainment or Work, with a focus score that separates real work from tab-flicking.',
  },
  {
    ic: '📈',
    title: 'Zoom out to months and a year',
    body: 'Week, month and three-month views, each compared against the period before, with a month-by-month table and chart. Watch a habit form — or quietly fall apart.',
  },
  {
    ic: '🔎',
    title: "Search everything you've seen",
    body: 'Not filenames — the actual text that was on your screen. Semantic and keyword search together, so "that article about attention heads" finds it anyway.',
  },
  {
    ic: '✅',
    title: "Catches what you'd forget",
    body: 'Deadlines, bills and meetings lifted off the screen with the right date, the sender, and the meeting link. Lectures enrol themselves in a 1/3/7/14/30-day revision ladder.',
  },
  {
    ic: '🔒',
    title: 'Private by design',
    body: 'One SQLite file on your disk, a server bound to localhost behind a bearer token, on-device Apple embeddings. Nothing leaves your Mac unless you switch it on.',
  },
  {
    ic: '🔌',
    title: 'Then: ask Claude about it',
    body: 'Connect once and Claude answers from your memory through a native MCP server — 7 tools. Entirely optional; MitthuAI is a complete app without it.',
  },
]

export const STEPS = [
  {
    title: 'Download & open it',
    body: 'One drag. No installer, no account, no sign-up. Apple Silicon and Intel, macOS 12+.',
  },
  {
    title: 'Grant Accessibility',
    body: 'One permission lets Mitthu read window text — the same macOS API screen readers use. It never leaves your Mac.',
  },
  {
    title: 'Forget about it',
    body: 'It lives in the menu bar with no dock icon and no window, and starts with your Mac.',
  },
  {
    title: 'Open the dashboard when curious',
    body: 'localhost:4789 — whenever you want to know where the week went. Connecting Claude is optional, and comes later.',
  },
]

// Interactive "Ask Mitthu" demo — clicking a question reveals its answer.
export const DEMO = [
  {
    q: 'What did I do today?',
    a: '3h 12m of focus across Xcode and Notion, 48m on YouTube, and 2 bills spotted on screen. Your longest stretch was 10:05 AM–11:40 AM in Xcode.',
  },
  {
    q: 'When did I watch that GPU video?',
    a: 'Tuesday at 9:24 PM — "How GPUs Work" on YouTube, watched for 22 minutes. It\'s enrolled in your revision ladder; next nudge is in 3 days.',
  },
  {
    q: "What's important today?",
    a: 'Electricity bill due tomorrow (₹1,840, seen in Gmail), and a revision nudge for your transformers lecture from last week.',
  },
  {
    q: 'Remind me to pay rent in 4 days',
    a: 'Done — reminder "Pay rent" set for Sunday. I\'ll fire a macOS notification and it\'ll show up in your Brain tab.',
  },
]

// MCP tools shown as tabs.
export const TOOLS = [
  {
    name: 'search_memory',
    tag: 'search',
    desc: 'Hybrid semantic + keyword search over everything you\'ve seen, with date filters and multi-query support.',
    example: 'search_memory("electricity bill", after: "2026-07-01")',
  },
  {
    name: 'get_timeline',
    tag: 'timeline',
    desc: 'Sessions and stats for a given day — active vs idle time, focus score, top apps, and category breakdown.',
    example: 'get_timeline(date: "today")',
  },
  {
    name: 'get_important',
    tag: 'brain',
    desc: 'Bills and deadlines due soon, plus any spaced-repetition revisions firing today.',
    example: 'get_important()',
  },
  {
    name: 'create_reminder',
    tag: 'brain',
    desc: 'Add a task or reminder with a due date. Fires a native macOS notification when it\'s time.',
    example: 'create_reminder("Pay rent", due: "in 4 days")',
  },
  {
    name: 'add_revision',
    tag: 'study',
    desc: 'Enroll anything you\'ve seen in the 1 / 3 / 7 / 14 / 30-day revision ladder.',
    example: 'add_revision("Transformers lecture")',
  },
  {
    name: 'get_daily_digest',
    tag: 'review',
    desc: 'A readable end-of-day review of what you worked on, watched, and what\'s coming up.',
    example: 'get_daily_digest(date: "yesterday")',
  },
]

export const FAQS = [
  {
    q: 'Does any of my data leave my Mac?',
    a: 'Not unless you switch on one of three optional features, each off by default: turbo search (sends captured text to OpenAI using your own key), web access for Claude.ai (routes Claude\'s questions through a relay to your Mac — your memory stays on the device), and Apple\'s on-device model (which never leaves the Mac anyway). Leave them off and MitthuAI makes no network requests at all: your activity, text and search index live only in a SQLite file on your disk, behind a server bound to 127.0.0.1 with a bearer token.',
  },
  {
    q: 'Why does it need Accessibility permission?',
    a: 'That permission lets Mitthu read window titles and on-screen text — the same macOS API screen readers use. It\'s how your timeline and search get built. Secure text fields, password managers, and private browsing windows are never read.',
  },
  {
    q: 'Do I need an account?',
    a: 'No. There is no sign-up, no login and no paid tier — download it and it works. An account only exists for the optional Claude.ai-web connection; Claude Code and Claude Desktop connect over localhost and need nothing.',
  },
  {
    q: 'Why is it Mac only?',
    a: 'It\'s built directly on macOS — the accessibility APIs, IOKit power assertions, CoreAudio, Apple\'s on-device embeddings, Apple Events for browser URLs. That\'s what makes it fast and private, and it\'s also what makes it Mac-only. A cross-platform version would be a different, worse app.',
  },
  {
    q: 'What is MCP and why should I care?',
    a: 'MCP (Model Context Protocol) is how Claude connects to external tools. MitthuAI ships a native MCP server with 7 tools, so Claude Code and Claude Desktop can search your memory, check what\'s due, and set reminders — as first-class tools. It\'s optional: the app is complete without it.',
  },
  {
    q: 'Is it free? What are the requirements?',
    a: 'Free and open source — 5,713 lines of Swift with zero dependencies, which you can read and build yourself in about a minute. It runs on macOS 12+ on both Apple Silicon and Intel, and lives quietly in your menu bar.',
  },
  {
    q: 'Can I pause or delete my data?',
    a: 'Anytime. Pause capture from the menu bar, exclude specific apps, turn off text or URL capture separately, or purge any date range from Settings. It\'s your file on your disk — you\'re always in control.',
  },
]
