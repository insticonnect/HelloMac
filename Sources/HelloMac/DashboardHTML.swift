import Foundation

/// The web dashboard, embedded as a single self-contained page (no CDNs —
/// works fully offline). Served at "/" with the access token in the URL;
/// the page stores the token in localStorage and uses it for API calls.
enum DashboardHTML {
    static let page = #"""
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>HelloMac — Memory</title>
<style>
  :root {
    --bg: #0e0f13; --panel: #16181f; --panel2: #1d2029; --line: #262a36;
    --text: #e8eaf0; --dim: #8a90a3; --accent: #7c6cff; --accent2: #4fd1a5;
    --warn: #ffb454; --danger: #ff6b6b;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: var(--bg); color: var(--text); font: 14px/1.5 -apple-system, "SF Pro Text", Helvetica, Arial, sans-serif; }
  header { display: flex; align-items: center; gap: 16px; padding: 14px 22px; border-bottom: 1px solid var(--line); position: sticky; top: 0; background: var(--bg); z-index: 5;}
  header h1 { font-size: 17px; font-weight: 700; letter-spacing: .3px; }
  header h1 span { color: var(--accent); }
  nav { display: flex; gap: 4px; margin-left: 12px; }
  nav button { background: none; border: none; color: var(--dim); font: inherit; font-weight: 600; padding: 8px 14px; border-radius: 8px; cursor: pointer; }
  nav button.active { color: var(--text); background: var(--panel2); }
  nav button:hover { color: var(--text); }
  #statusdot { margin-left: auto; display: flex; align-items: center; gap: 8px; color: var(--dim); font-size: 12px; }
  .dot { width: 9px; height: 9px; border-radius: 50%; background: var(--accent2); }
  .dot.paused { background: var(--warn); }
  main { max-width: 1060px; margin: 0 auto; padding: 22px; }
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(230px, 1fr)); gap: 14px; margin-bottom: 20px; }
  .card { background: var(--panel); border: 1px solid var(--line); border-radius: 14px; padding: 16px 18px; }
  .card .k { color: var(--dim); font-size: 12px; text-transform: uppercase; letter-spacing: .6px; margin-bottom: 6px; }
  .card .v { font-size: 24px; font-weight: 700; }
  .section { background: var(--panel); border: 1px solid var(--line); border-radius: 14px; padding: 18px 20px; margin-bottom: 18px; }
  .section h2 { font-size: 14px; margin-bottom: 12px; color: var(--dim); text-transform: uppercase; letter-spacing: .6px; }
  .bar-row { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; }
  .bar-row .name { width: 180px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .bar-row .bar { flex: 1; height: 10px; background: var(--panel2); border-radius: 5px; overflow: hidden; }
  .bar-row .bar > div { height: 100%; background: linear-gradient(90deg, var(--accent), #a08bff); border-radius: 5px; }
  .bar-row .time { width: 70px; text-align: right; color: var(--dim); font-variant-numeric: tabular-nums; }
  .sess { display: flex; gap: 12px; padding: 9px 4px; border-bottom: 1px solid var(--line); }
  .sess:last-child { border-bottom: none; }
  .sess .t { color: var(--dim); font-variant-numeric: tabular-nums; white-space: nowrap; }
  .sess .app { font-weight: 600; white-space: nowrap; }
  .sess .title { color: var(--dim); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; flex: 1; }
  .sess .dur { color: var(--accent2); white-space: nowrap; font-variant-numeric: tabular-nums; }
  .sess.idle { opacity: .45; }
  input[type=text], input[type=date], textarea {
    background: var(--panel2); border: 1px solid var(--line); color: var(--text);
    border-radius: 10px; padding: 10px 14px; font: inherit; width: 100%;
  }
  input:focus, textarea:focus { outline: none; border-color: var(--accent); }
  .row { display: flex; gap: 10px; align-items: center; }
  button.btn { background: var(--accent); border: none; color: #fff; font: inherit; font-weight: 600; padding: 10px 18px; border-radius: 10px; cursor: pointer; white-space: nowrap; }
  button.btn.ghost { background: var(--panel2); color: var(--text); }
  button.btn.small { padding: 5px 10px; font-size: 12px; border-radius: 8px; }
  button.btn.danger { background: var(--danger); }
  .result { padding: 12px 4px; border-bottom: 1px solid var(--line); }
  .result:last-child { border-bottom: none; }
  .result .meta { color: var(--dim); font-size: 12px; margin-bottom: 4px; }
  .result .meta b { color: var(--text); }
  .result .snippet { color: #c6cad6; font-size: 13px; }
  .fact { display: flex; gap: 10px; align-items: center; padding: 10px 4px; border-bottom: 1px solid var(--line); }
  .fact:last-child { border-bottom: none; }
  .pill { font-size: 11px; font-weight: 700; text-transform: uppercase; padding: 3px 8px; border-radius: 20px; background: var(--panel2); color: var(--dim); white-space: nowrap; }
  .pill.bill { color: var(--warn); } .pill.deadline { color: var(--danger); }
  .pill.watched { color: var(--accent2); } .pill.note { color: var(--accent); }
  .fact .title { flex: 1; }
  .fact .due { color: var(--dim); font-size: 12px; white-space: nowrap; }
  .fact .due.over { color: var(--danger); font-weight: 700; }
  pre.digest { background: var(--panel2); border-radius: 10px; padding: 16px; white-space: pre-wrap; font: 13px/1.6 ui-monospace, Menlo, monospace; color: #c6cad6; }
  .toggle-row { display: flex; align-items: center; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid var(--line); }
  .toggle-row:last-child { border-bottom: none; }
  .hint { color: var(--dim); font-size: 12px; margin-top: 4px; }
  code.inline { background: var(--panel2); padding: 2px 7px; border-radius: 6px; font: 12px ui-monospace, Menlo, monospace; word-break: break-all; }
  .empty { color: var(--dim); padding: 18px 0; text-align: center; }
  .hidden { display: none; }
  .cols2 { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; margin-bottom: 18px; }
  .cols2 .section { margin-bottom: 0; }
  .donut-wrap { display: flex; align-items: center; gap: 22px; flex-wrap: wrap; justify-content: center; }
  .legend { display: flex; flex-direction: column; gap: 8px; }
  .legend .li { display: flex; align-items: center; gap: 8px; font-size: 13px; }
  .legend .sw { width: 12px; height: 12px; border-radius: 3px; }
  .legend .lt { color: var(--dim); font-variant-numeric: tabular-nums; margin-left: auto; padding-left: 12px; }
  .rule-form { display: grid; grid-template-columns: 1fr 1fr 1fr auto; gap: 12px; align-items: end; }
  .rule-form label { display: block; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .5px; color: var(--dim); margin-bottom: 5px; }
  table.rules { width: 100%; border-collapse: collapse; }
  table.rules th { text-align: left; font-size: 11px; text-transform: uppercase; letter-spacing: .5px; color: var(--dim); padding: 10px 8px; border-bottom: 1px solid var(--line); }
  table.rules td { padding: 12px 8px; border-bottom: 1px solid var(--line); }
  table.rules tr:last-child td { border-bottom: none; }
  table.rules .any { color: var(--dim); }
  .chip { display: inline-block; font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 20px; background: var(--panel2); color: #cdb9ff; }
  .catpick { display: inline-flex; gap: 4px; margin-left: 8px; }
  .catpick button { background: var(--panel2); border: 1px solid var(--line); color: var(--dim); font-size: 11px; padding: 2px 8px; border-radius: 12px; cursor: pointer; }
  .catpick button:hover { color: var(--text); border-color: var(--accent); }
  .catpick button.on { background: var(--accent); color: #fff; border-color: var(--accent); }
  .del { color: var(--danger); background: none; border: none; cursor: pointer; font: inherit; font-weight: 600; }
  @media (max-width: 760px) { .cols2 { grid-template-columns: 1fr; } .rule-form { grid-template-columns: 1fr 1fr; } }
  @media (max-width: 640px) { .sess .title { display: none; } .bar-row .name { width: 110px; } }
</style>
</head>
<body>
<header>
  <h1>Hello<span>Mac</span></h1>
  <nav>
    <button id="tab-today" class="active" onclick="show('today')">Today</button>
    <button id="tab-search" onclick="show('search')">Search</button>
    <button id="tab-brain" onclick="show('brain')">Brain</button>
    <button id="tab-rules" onclick="show('rules')">Rules</button>
    <button id="tab-settings" onclick="show('settings')">Settings</button>
  </nav>
  <div id="statusdot"><div class="dot" id="dot"></div><span id="statustext">tracking</span></div>
</header>
<main>

<div id="view-today">
  <div class="row" style="margin-bottom:16px">
    <input type="date" id="daypick" style="max-width:180px" onchange="loadToday()">
    <button class="btn ghost" onclick="shiftDay(-1)">&larr;</button>
    <button class="btn ghost" onclick="shiftDay(1)">&rarr;</button>
    <button class="btn ghost" onclick="loadDigest()">Daily review</button>
  </div>
  <div class="grid">
    <div class="card"><div class="k">Active screen time</div><div class="v" id="stat-active">–</div><div class="hint">Focused active screen time.</div></div>
    <div class="card"><div class="k">Away (idle)</div><div class="v" id="stat-idle">–</div><div class="hint">Time spent away from keyboard.</div></div>
    <div class="card"><div class="k">Focus vs multitasking</div><div class="v" id="stat-focus" style="color:var(--accent2)">–</div><div class="hint" id="stat-focus-sub">&nbsp;</div></div>
    <div class="card"><div class="k">Tracked events</div><div class="v" id="stat-events" style="color:var(--accent)">–</div><div class="hint">Activity switches logged today.</div></div>
  </div>
  <div class="section hidden" id="digest-box"><h2>Daily review</h2><pre class="digest" id="digest-text"></pre></div>
  <div class="cols2">
    <div class="section"><h2>Category distribution</h2>
      <div class="donut-wrap"><svg id="donut" viewBox="0 0 200 200" width="200" height="200"></svg>
        <div id="donut-legend" class="legend"></div>
      </div>
    </div>
    <div class="section"><h2>Top applications</h2><div id="top-apps"><div class="empty">no data yet</div></div></div>
  </div>
  <div class="section"><h2>Timeline</h2>
    <p class="hint" style="margin-bottom:8px">Tap a category chip on any row to teach HelloMac — it re-tags that title everywhere, including activity within ±10 min.</p>
    <div id="timeline"><div class="empty">no activity logged for this day</div></div>
  </div>
</div>

<div id="view-search" class="hidden">
  <div class="section">
    <div class="row">
      <input type="text" id="q" placeholder="Search your memory — e.g. 'that video about transformers', 'electricity bill'…" onkeydown="if(event.key==='Enter')doSearch()">
      <button class="btn" onclick="doSearch()">Search</button>
    </div>
    <div class="row" style="margin-top:10px">
      <label class="hint">From <input type="date" id="q-from" style="width:auto"></label>
      <label class="hint">To <input type="date" id="q-to" style="width:auto"></label>
      <span class="hint" id="q-mode"></span>
    </div>
  </div>
  <div class="section"><h2>Results</h2><div id="results"><div class="empty">search across everything you've seen on this Mac</div></div></div>
</div>

<div id="view-brain" class="hidden">
  <div class="section">
    <h2>Add item</h2>
    <div class="row">
      <input type="text" id="new-title" placeholder="e.g. Pay electricity bill">
      <input type="date" id="new-due" style="max-width:180px">
      <button class="btn" onclick="createFact()">Add</button>
    </div>
  </div>
  <div class="section"><h2>Open items</h2><div id="facts"><div class="empty">nothing here yet — bills and deadlines you see on screen appear automatically</div></div></div>
  <div class="section"><h2>Upcoming reminders</h2><div id="reminders"><div class="empty">no reminders scheduled</div></div></div>
</div>

<div id="view-rules" class="hidden">
  <div class="section">
    <h2>Create categorization rule</h2>
    <p class="hint" style="margin-bottom:12px">Automatically tag activity. Group related study portals and videos under the same category so they count as focus, not multitasking. Leave a field blank to match anything.</p>
    <div class="rule-form">
      <div><label>Application name</label><input type="text" id="rule-app" placeholder="e.g. Safari"></div>
      <div><label>Window title contains</label><input type="text" id="rule-title" placeholder="e.g. YouTube"></div>
      <div><label>Category / topic</label>
        <input type="text" id="rule-cat" list="cat-list" placeholder="e.g. Study">
        <datalist id="cat-list"></datalist>
      </div>
      <button class="btn" onclick="addRule()">Apply rule</button>
    </div>
  </div>
  <div class="section">
    <h2>Active categorization rules</h2>
    <div id="rules-table"><div class="empty">no rules yet</div></div>
  </div>
</div>

<div id="view-settings" class="hidden">
  <div class="section">
    <h2>Capture</h2>
    <div class="toggle-row"><div><b>Pause tracking</b><div class="hint">Stops all logging until resumed.</div></div><input type="checkbox" id="set-paused" onchange="saveSettings()"></div>
    <div class="toggle-row"><div><b>Capture on-screen text</b><div class="hint">Reads visible text via macOS accessibility — powers memory search.</div></div><input type="checkbox" id="set-text" onchange="saveSettings()"></div>
    <div class="toggle-row"><div><b>Capture browser URLs</b><div class="hint">Uses Apple Events (asks permission once per browser).</div></div><input type="checkbox" id="set-urls" onchange="saveSettings()"></div>
    <div class="toggle-row"><div><b>Auto spaced-repetition for study videos</b><div class="hint">Watched lectures/tutorials get revision reminders after 1/3/7/14/30 days.</div></div><input type="checkbox" id="set-revise" onchange="saveSettings()"></div>
  </div>
  <div class="section">
    <h2>Search quality (embeddings)</h2>
    <p class="hint" style="margin-bottom:10px">Active model: <span id="emb-model" class="chip">–</span></p>
    <div class="toggle-row"><div><b>Turbo accuracy (bring your own OpenAI key)</b><div class="hint">Uses OpenAI text-embedding-3-small for higher-accuracy, multilingual search. Sends captured text to OpenAI — opt-in. Your key is stored in the macOS Keychain, never in the database, and you're billed by OpenAI directly.</div></div><input type="checkbox" id="set-turbo" onchange="saveSettings()"></div>
    <div class="row" style="margin-top:10px">
      <input type="text" id="set-openai" placeholder="sk-… (leave blank to keep existing; clears if emptied on save)">
      <button class="btn" onclick="saveSettings()">Save key</button>
    </div>
    <p class="hint" id="openai-status" style="margin-top:6px">&nbsp;</p>
  </div>
  <div class="section">
    <h2>Excluded apps (never captured)</h2>
    <textarea id="set-excluded" rows="5" placeholder="One app name per line"></textarea>
    <div class="row" style="margin-top:10px"><button class="btn" onclick="saveSettings()">Save</button></div>
  </div>
  <div class="section">
    <h2>Claude.ai web access (mitthuai account)</h2>
    <p class="hint" style="margin-bottom:8px">Sign in with your mitthuai account to use HelloMac from Claude on the web. Login happens on mitthuai.com (Google Sign-In, identity only — we never read your email). Your memory stays on this Mac; the account only lets Claude reach it through a secure tunnel.</p>
    <p class="hint" style="margin-bottom:8px">Status: <b id="acct-status">…</b></p>
    <div class="row"><button class="btn" id="acct-btn" onclick="toggleAccount()">Connect account</button></div>
  </div>
  <div class="section">
    <h2>Connect AI clients (MCP) — local</h2>
    <p class="hint" style="margin-bottom:8px">Claude Code (terminal):</p>
    <code class="inline" id="mcp-code">…</code>
    <p class="hint" style="margin-top:12px;margin-bottom:8px">Claude Desktop — add to <code class="inline">claude_desktop_config.json</code>:</p>
    <code class="inline" id="mcp-desktop">…</code>
  </div>
  <div class="section">
    <h2>Data</h2>
    <p class="hint" id="data-counts">–</p>
    <div class="row" style="margin-top:10px">
      <label class="hint">Delete range: <input type="date" id="purge-from" style="width:auto"></label>
      <label class="hint">to <input type="date" id="purge-to" style="width:auto"></label>
      <button class="btn danger" onclick="purge()">Delete</button>
    </div>
  </div>
</div>

</main>
<script>
(function(){
  const p = new URLSearchParams(location.search);
  if (p.get('token')) { localStorage.setItem('hm_token', p.get('token')); history.replaceState({}, '', '/'); }
})();
const TOKEN = localStorage.getItem('hm_token') || '';
async function api(path, opts) {
  opts = opts || {};
  opts.headers = Object.assign({'Authorization': 'Bearer ' + TOKEN}, opts.headers || {});
  const r = await fetch(path, opts);
  if (!r.ok) throw new Error('api ' + r.status);
  return r.json();
}
function fmtDur(s) { s = Math.round(s); const h = Math.floor(s/3600), m = Math.floor((s%3600)/60); return h > 0 ? h + 'h ' + m + 'm' : m + 'm'; }
function fmtTime(ts) { return new Date(ts*1000).toTimeString().slice(0,5); }
function fmtDate(ts) { const d = new Date(ts*1000); return d.toISOString().slice(0,10) + ' ' + d.toTimeString().slice(0,5); }
function esc(s) { const d = document.createElement('div'); d.textContent = s || ''; return d.innerHTML; }
function todayStr(d) { d = d || new Date(); const off = d.getTimezoneOffset(); return new Date(d.getTime() - off*60000).toISOString().slice(0,10); }

const CAT_COLORS = {'Study':'#4fd1a5','Entertainment':'#7c6cff','Work':'#ffb454','Other':'#5b6274','Idle':'#3a3f4d','Uncategorized':'#5b6274'};
const PALETTE = ['#7c6cff','#4fd1a5','#ffb454','#ff6b6b','#5b8def','#e879f9','#22d3ee','#a3e635'];
function catColor(c, i) { return CAT_COLORS[c] || PALETTE[(i||0) % PALETTE.length]; }
let CATEGORIES = ['Study','Entertainment','Work','Other'];

function show(tab) {
  ['today','search','brain','rules','settings'].forEach(t => {
    document.getElementById('view-' + t).classList.toggle('hidden', t !== tab);
    document.getElementById('tab-' + t).classList.toggle('active', t === tab);
  });
  if (tab === 'today') loadToday();
  if (tab === 'brain') loadBrain();
  if (tab === 'rules') loadRules();
  if (tab === 'settings') loadSettings();
}

function renderDonut(cats) {
  const svg = document.getElementById('donut');
  const legend = document.getElementById('donut-legend');
  // Accept either [{category,total}] (from the API) or {name: seconds}.
  let pairs;
  if (Array.isArray(cats)) {
    pairs = cats.map(r => [r.category || 'Other', +r.total || 0]);
  } else {
    pairs = Object.entries(cats).map(([k, v]) => [k, +v || 0]);
  }
  const entries = pairs.filter(([k]) => k !== 'Idle').sort((a,b) => b[1]-a[1]);
  const total = entries.reduce((s,[,v]) => s+v, 0);
  if (!total) { svg.innerHTML = '<circle cx="100" cy="100" r="70" fill="none" stroke="#1d2029" stroke-width="26"/>'; legend.innerHTML = '<span class="empty">no data</span>'; return; }
  const C = 2 * Math.PI * 70;
  let offset = 0, paths = '';
  entries.forEach(([name, val], i) => {
    const frac = val/total, len = frac * C;
    paths += '<circle cx="100" cy="100" r="70" fill="none" stroke="' + catColor(name,i) + '" stroke-width="26" ' +
      'stroke-dasharray="' + len + ' ' + (C-len) + '" stroke-dashoffset="' + (-offset) + '" transform="rotate(-90 100 100)"></circle>';
    offset += len;
  });
  svg.innerHTML = paths;
  legend.innerHTML = entries.map(([name,val],i) =>
    '<div class="li"><span class="sw" style="background:' + catColor(name,i) + '"></span>' +
    esc(name) + '<span class="lt">' + fmtDur(val) + '</span></div>').join('');
}

function jsAttr(s) {
  return (s || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/"/g, '&quot;');
}
function catChips(app, title, current) {
  if (!title && !app) return '';
  const t = jsAttr(title);
  const a = jsAttr(app);
  return '<span class="catpick">' + CATEGORIES.map(c =>
    '<button class="' + (c === current ? 'on' : '') + '" title="Tag as ' + c + '" ' +
    'onclick="tagTitle(\'' + a + '\',\'' + t + '\',\'' + c + '\')">' + c + '</button>').join('') + '</span>';
}

async function tagTitle(app, title, cat) {
  await api('/api/categorize', {method:'POST', body: JSON.stringify({app:app, title:title, category:cat})});
  loadToday();
}

function shiftDay(n) {
  const el = document.getElementById('daypick');
  const d = new Date(el.value || todayStr());
  d.setDate(d.getDate() + n);
  el.value = todayStr(d);
  loadToday();
}

async function loadToday() {
  const el = document.getElementById('daypick');
  if (!el.value) el.value = todayStr();
  document.getElementById('digest-box').classList.add('hidden');
  try {
    const o = await api('/api/overview?date=' + el.value);
    document.getElementById('stat-active').textContent = fmtDur(o.active_secs);
    document.getElementById('stat-idle').textContent = fmtDur(o.idle_secs);
    document.getElementById('stat-events').textContent = o.event_count;

    const totalFocusable = o.focus_secs + o.multitask_secs;
    const pct = totalFocusable > 0 ? Math.round(100 * o.focus_secs / totalFocusable) : 0;
    document.getElementById('stat-focus').textContent = pct + '%';
    document.getElementById('stat-focus-sub').textContent =
      'Focus: ' + fmtDur(o.focus_secs) + ' | Multitask: ' + fmtDur(o.multitask_secs);

    renderDonut(o.categories || {});

    const apps = document.getElementById('top-apps');
    if (o.top_apps.length) {
      const max = o.top_apps[0].total;
      apps.innerHTML = o.top_apps.map(a =>
        '<div class="bar-row"><div class="name">' + esc(a.app) + '</div>' +
        '<div class="bar"><div style="width:' + Math.max(2, 100*a.total/max) + '%"></div></div>' +
        '<div class="time">' + fmtDur(a.total) + '</div></div>').join('');
    } else apps.innerHTML = '<div class="empty">no data yet</div>';

    const tl = document.getElementById('timeline');
    if (o.sessions.length) {
      tl.innerHTML = o.sessions.slice().reverse().map(s =>
        '<div class="sess' + (s.is_idle ? ' idle' : '') + '">' +
        '<span class="t">' + fmtTime(s.ts_start) + '–' + fmtTime(s.ts_end) + '</span>' +
        '<span class="app">' + esc(s.app) + '</span>' +
        '<span class="title">' + esc(s.title) +
        (s.is_idle ? '' : catChips(s.app, s.title, s.category)) + '</span>' +
        '<span class="dur">' + fmtDur(s.duration) + '</span></div>').join('');
    } else tl.innerHTML = '<div class="empty">no activity logged for this day</div>';
  } catch(e) { console.error(e); }
}

async function loadRules() {
  const r = await api('/api/rules');
  CATEGORIES = r.categories && r.categories.length ? r.categories : CATEGORIES;
  document.getElementById('cat-list').innerHTML = CATEGORIES.map(c => '<option value="' + esc(c) + '">').join('');
  const box = document.getElementById('rules-table');
  if (!r.rules.length) { box.innerHTML = '<div class="empty">no rules yet</div>'; return; }
  box.innerHTML = '<table class="rules"><thead><tr><th>Application</th><th>Title contains</th><th>Category / topic</th><th style="text-align:right">Action</th></tr></thead><tbody>' +
    r.rules.map(x =>
      '<tr><td><b>' + (x.app ? esc(x.app) : '<span class="any">Any</span>') + '</b></td>' +
      '<td>' + (x.title_pattern ? esc(x.title_pattern) : '<span class="any">Any</span>') + '</td>' +
      '<td><span class="chip" style="color:' + catColor(x.category) + '">' + esc(x.category) + '</span></td>' +
      '<td style="text-align:right"><button class="del" onclick="delRule(' + x.id + ')">Delete</button></td></tr>').join('') +
    '</tbody></table>';
}

async function addRule() {
  const app = document.getElementById('rule-app').value.trim();
  const title = document.getElementById('rule-title').value.trim();
  const cat = document.getElementById('rule-cat').value.trim();
  if (!cat || (!app && !title)) { alert('Enter a category and at least an app or title.'); return; }
  await api('/api/rules', {method:'POST', body: JSON.stringify({app:app, title_pattern:title, category:cat})});
  document.getElementById('rule-app').value = '';
  document.getElementById('rule-title').value = '';
  document.getElementById('rule-cat').value = '';
  loadRules();
}

async function delRule(id) {
  if (!confirm('Delete this rule? Affected activity will be re-categorized.')) return;
  await api('/api/rules/delete', {method:'POST', body: JSON.stringify({id:id})});
  loadRules();
}

async function loadDigest() {
  const el = document.getElementById('daypick');
  const d = await api('/api/digest?date=' + (el.value || todayStr()));
  document.getElementById('digest-text').textContent = d.text;
  document.getElementById('digest-box').classList.remove('hidden');
}

async function doSearch() {
  const q = document.getElementById('q').value.trim();
  if (!q) return;
  let url = '/api/search?q=' + encodeURIComponent(q);
  const f = document.getElementById('q-from').value, t = document.getElementById('q-to').value;
  if (f) url += '&from=' + (new Date(f).getTime()/1000);
  if (t) url += '&to=' + (new Date(t).getTime()/1000 + 86400);
  const box = document.getElementById('results');
  box.innerHTML = '<div class="empty">searching…</div>';
  try {
    const r = await api(url);
    if (!r.results.length) { box.innerHTML = '<div class="empty">no matches</div>'; return; }
    box.innerHTML = r.results.map(x =>
      '<div class="result"><div class="meta"><b>' + esc(x.app) + '</b> · ' + esc(x.title) +
      ' · ' + fmtDate(x.ts) + (x.url ? ' · <a style="color:var(--accent)" href="' + esc(x.url) + '" target="_blank">link</a>' : '') + '</div>' +
      '<div class="snippet">' + esc(x.snippet) + '</div></div>').join('');
  } catch(e) { box.innerHTML = '<div class="empty">search failed</div>'; }
}

async function loadBrain() {
  const b = await api('/api/brain');
  const facts = document.getElementById('facts');
  const now = Date.now()/1000;
  if (b.facts.length) {
    facts.innerHTML = b.facts.map(f => {
      const due = f.due_ts ? '<span class="due' + (f.due_ts < now ? ' over' : '') + '">due ' + fmtDate(f.due_ts) + '</span>' : '';
      const revBtn = f.kind === 'watched' ? '<button class="btn small ghost" onclick="factAction(' + f.id + ',\'revise\')">revise</button>' : '';
      return '<div class="fact"><span class="pill ' + esc(f.kind) + '">' + esc(f.kind) + '</span>' +
        '<span class="title">' + esc(f.title) + '</span>' + due + revBtn +
        '<button class="btn small" onclick="factAction(' + f.id + ',\'complete\')">done</button>' +
        '<button class="btn small ghost" onclick="factAction(' + f.id + ',\'dismiss\')">✕</button></div>';
    }).join('');
  } else facts.innerHTML = '<div class="empty">nothing here yet — bills and deadlines you see on screen appear automatically</div>';

  const rem = document.getElementById('reminders');
  if (b.reminders.length) {
    rem.innerHTML = b.reminders.map(r =>
      '<div class="fact"><span class="pill ' + esc(r.kind) + '">' + esc(r.kind) + '</span>' +
      '<span class="title">' + esc(r.title) + (r.interval_idx >= 0 ? ' <span class="hint">(revision ' + (r.interval_idx+1) + ')</span>' : '') + '</span>' +
      '<span class="due">' + fmtDate(r.fire_ts) + '</span></div>').join('');
  } else rem.innerHTML = '<div class="empty">no reminders scheduled</div>';
}

async function factAction(id, action) {
  await api('/api/fact', {method:'POST', body: JSON.stringify({action:action, id:id})});
  loadBrain();
}

async function createFact() {
  const title = document.getElementById('new-title').value.trim();
  if (!title) return;
  const due = document.getElementById('new-due').value;
  const body = {action:'create', title:title};
  if (due) body.due_ts = new Date(due).getTime()/1000 + 9*3600;
  await api('/api/fact', {method:'POST', body: JSON.stringify(body)});
  document.getElementById('new-title').value = '';
  loadBrain();
}

async function loadSettings() {
  const s = await api('/api/status');
  document.getElementById('set-paused').checked = s.paused;
  document.getElementById('set-text').checked = s.capture_text;
  document.getElementById('set-urls').checked = s.capture_urls;
  document.getElementById('set-revise').checked = s.auto_revise;
  document.getElementById('set-turbo').checked = s.turbo_embeddings;
  document.getElementById('emb-model').textContent = s.embeddings_model || '–';
  document.getElementById('openai-status').textContent = s.openai_key_set ? 'A key is saved in Keychain.' : 'No key saved.';
  document.getElementById('set-excluded').value = s.excluded_apps.join('\n');
  document.getElementById('q-mode').textContent = s.embeddings ? 'semantic + keyword search' : 'keyword search only';
  const mcp = 'claude mcp add --transport http hellomac http://localhost:' + s.port + '/mcp --header "Authorization: Bearer ' + s.token + '"';
  document.getElementById('mcp-code').textContent = mcp;
  document.getElementById('mcp-desktop').textContent = JSON.stringify({mcpServers:{hellomac:{command:'npx',args:['mcp-remote','http://localhost:' + s.port + '/mcp','--header','Authorization: Bearer ' + s.token]}}});
  const paired = s.account_paired;
  document.getElementById('acct-status').textContent = paired ? 'connected — Claude.ai web can reach this Mac' : 'not connected';
  document.getElementById('acct-btn').textContent = paired ? 'Disconnect account' : 'Connect account';
  const c = s.counts;
  document.getElementById('data-counts').textContent =
    c.events + ' events · ' + c.chunks + ' text chunks (' + c.embedded + ' embedded) · ' +
    c.facts + ' facts · ' + (c.db_bytes/1048576).toFixed(1) + ' MB on disk';
  updateDot(s.paused);
}

async function saveSettings() {
  const body = {
    paused: document.getElementById('set-paused').checked,
    capture_text: document.getElementById('set-text').checked,
    capture_urls: document.getElementById('set-urls').checked,
    auto_revise: document.getElementById('set-revise').checked,
    turbo_embeddings: document.getElementById('set-turbo').checked,
    excluded_apps: document.getElementById('set-excluded').value.split('\n').map(x => x.trim()).filter(Boolean)
  };
  // Only send the key when the user typed one (never auto-clear on toggles).
  const key = document.getElementById('set-openai').value.trim();
  if (key) body.openai_api_key = key;
  await api('/api/settings', {method:'POST', body: JSON.stringify(body)});
  document.getElementById('set-openai').value = '';
  updateDot(body.paused);
  loadSettings();
}

async function toggleAccount() {
  const s = await api('/api/status');
  if (s.account_paired) {
    if (!confirm('Disconnect this Mac from your mitthuai account? Claude.ai web will no longer reach it.')) return;
    await api('/api/account/disconnect', {method:'POST'});
  } else {
    await api('/api/account/connect', {method:'POST'});
    alert('Opening mitthuai.com to sign in. After you finish, this Mac connects automatically within a minute.');
  }
  setTimeout(loadSettings, 1500);
}

async function purge() {
  const f = document.getElementById('purge-from').value, t = document.getElementById('purge-to').value;
  if (!f || !t) { alert('Pick both dates.'); return; }
  if (!confirm('Permanently delete all captured data from ' + f + ' to ' + t + '?')) return;
  await api('/api/purge', {method:'POST', body: JSON.stringify({from: new Date(f).getTime()/1000, to: new Date(t).getTime()/1000 + 86400})});
  loadSettings();
}

function updateDot(paused) {
  document.getElementById('dot').className = 'dot' + (paused ? ' paused' : '');
  document.getElementById('statustext').textContent = paused ? 'paused' : 'tracking';
}

loadToday();
api('/api/rules').then(r => { if (r.categories && r.categories.length) CATEGORIES = r.categories; }).catch(()=>{});
api('/api/status').then(s => updateDot(s.paused)).catch(()=>{});
setInterval(() => { if (!document.getElementById('view-today').classList.contains('hidden')) loadToday(); }, 60000);
</script>
</body>
</html>
"""#
}
