// Central place for repeated content so it's easy to tweak.

export const GITHUB_URL = 'https://github.com/insticonnect/mitthuai'

export const NAV_LINKS = [
  { href: '#features', label: 'Features' },
  { href: '#how', label: 'How it works' },
  { href: '#demo', label: 'Demo' },
  { href: '#claude', label: 'For Claude' },
  { href: '#faq', label: 'FAQ' },
]

export const STATS = [
  { value: 100, suffix: '%', label: 'runs on your Mac', sub: 'nothing leaves the device' },
  { value: 0, suffix: '', label: 'cloud servers store your data', sub: 'no telemetry, ever' },
  { value: 7, suffix: '', label: 'native tools for Claude', sub: 'via the MCP server' },
  { value: 5, suffix: '×', label: 'spaced-repetition nudges', sub: '1 · 3 · 7 · 14 · 30 days' },
]

export const FEATURES = [
  {
    ic: '🧠',
    title: 'Remembers everything',
    body: 'Apps, window titles, and on-screen text become a private, searchable timeline. "When did I watch that lecture?" — answered instantly.',
  },
  {
    ic: '🔁',
    title: 'Never forget to revise',
    body: 'Watched a study video? Get spaced-repetition nudges after 1, 3, 7, 14 and 30 days — so what you learn actually sticks.',
  },
  {
    ic: '✅',
    title: "Knows what's due",
    body: 'Bills and deadlines you see on screen turn into tasks with dates. Ask "what\'s important today?" and get a real answer.',
  },
  {
    ic: '🔌',
    title: 'Plugs into Claude',
    body: 'Connect once and Claude answers from your memory — in the terminal, on desktop, and on the web via a native MCP server.',
  },
  {
    ic: '🔎',
    title: 'Hybrid search',
    body: 'BM25 keyword + vector similarity with reciprocal-rank fusion, rerank, and time filters. Duplicate screens are hashed out.',
  },
  {
    ic: '🔒',
    title: 'Private by design',
    body: 'Everything lives in one SQLite file on your Mac. The server binds to localhost and every request needs a bearer token.',
  },
]

export const STEPS = [
  {
    title: 'Download & install',
    body: 'Grab the app from this site and drag it in. Apple Silicon and Intel, macOS 12+.',
  },
  {
    title: 'Grant Accessibility',
    body: 'One permission lets Mitthu read window text — the same API screen readers use. Nothing is sent anywhere.',
  },
  {
    title: 'Sign in with Google',
    body: 'Used for login only — we never read your email. It just pairs your Mac to the secure tunnel.',
  },
  {
    title: 'Ask Claude',
    body: 'Your memory stays on your Mac; Claude reaches it to answer questions and set reminders.',
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
    a: 'No. Your activity, text, and search index live only in a SQLite file on your Mac. The local server binds to 127.0.0.1 and every request needs a bearer token. mitthuai\'s servers are only a tunnel that routes Claude\'s questions to your Mac and the answers back — they never store your memory.',
  },
  {
    q: 'Why does it need Accessibility permission?',
    a: 'That permission lets Mitthu read window titles and on-screen text — the same macOS API screen readers use. It\'s how your timeline and search get built. Secure text fields, password managers, and incognito windows are never read.',
  },
  {
    q: 'What is MCP and why should I care?',
    a: 'MCP (Model Context Protocol) is how Claude connects to external tools. mitthuai ships a native MCP server, so Claude Code, Claude Desktop, and the web app can search your memory, check what\'s due, and set reminders — as first-class tools.',
  },
  {
    q: 'Is it free? What are the requirements?',
    a: 'Free to use. It runs on macOS 12+ on both Apple Silicon and Intel, and lives quietly in your menu bar. On-device Apple embeddings are the default; you can optionally bring your own OpenAI key for multilingual turbo search.',
  },
  {
    q: 'Can I pause or delete my data?',
    a: 'Anytime. Pause capture from the menu bar, exclude specific apps, or purge any date range from Settings. It\'s your file on your disk — you\'re always in control.',
  },
]
