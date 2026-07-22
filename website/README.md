# mitthuai — website 🦜

The marketing site for **mitthuai / HelloMac** — *your Mac's memory, answerable by Claude.*

A single, self-contained static site. No build step, no dependencies, no framework —
just HTML, CSS and a little vanilla JS. Fully responsive (phone / tablet / desktop),
with a greenish parrot theme and a persistent **dark / light** toggle that also respects
the visitor's OS preference.

## Files

```
website/
├── index.html      # the page
├── styles.css      # theme tokens, layout, responsive rules, light + dark
├── script.js       # theme toggle, mobile menu, scroll reveal, copy-to-clipboard
├── vercel.json     # clean URLs + caching/security headers
├── assets/
│   └── parrot.svg   # Mitthu the parrot — logo & favicon
└── README.md
```

## Preview locally

It's plain static files, so anything that serves a folder works:

```bash
cd website
python3 -m http.server 5173
# open http://localhost:5173
```

(You can also just double-click `index.html`.)

## Deploy on Vercel

This folder is ready to ship as-is — no framework detection needed.

### Option A — Vercel dashboard (easiest)
1. Import the repo at <https://vercel.com/new>.
2. Set **Root Directory** to `website`.
3. Framework preset: **Other** · Build command: *(leave empty)* · Output dir: *(leave empty)*.
4. **Deploy.**

### Option B — Vercel CLI
```bash
npm i -g vercel
cd website
vercel        # preview
vercel --prod # production
```

## Customising

- **Colors / theme** — every color is a CSS variable at the top of `styles.css`
  (`--g-400`, `--brand`, etc.), split into `[data-theme="dark"]` and `[data-theme="light"]` blocks.
- **Logo** — swap `assets/parrot.svg` (it's used for both the favicon and the mascot).
- **Copy / sections** — all content lives in `index.html`.
- **Download link** — point the `#download` "Download for macOS" buttons at your release URL.
