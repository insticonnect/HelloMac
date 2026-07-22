# mitthuai — website 🦜

The marketing site for **mitthuai / HelloMac** — *your Mac's memory, answerable by Claude.*

**One self-contained HTML file. No build step, no framework, no dependencies.**
It works the instant you double-click it, and deploys to Vercel with zero configuration.
Greenish parrot theme, **light + dark** mode (toggle in the header, also follows your OS),
fully responsive on phone / tablet / desktop.

## Files

```
website/
├── index.html      # the whole site — HTML + CSS + JS + parrot art, all inline
├── parrot.svg      # favicon
├── vercel.json     # clean URLs + security headers
└── README.md
```

## Preview

Just **double-click `index.html`** — it opens in your browser and works immediately.

Or serve the folder:

```bash
cd website
python3 -m http.server 5173     # then open http://localhost:5173
```

## Deploy on Vercel

Because it's plain static files, there's nothing to build.

### Option A — Vercel dashboard
1. Import the repo at <https://vercel.com/new>.
2. Set **Root Directory** to `website`.
3. Framework preset: **Other**. Leave the build command and output directory **empty**.
4. **Deploy.** Done.

### Option B — Vercel CLI
```bash
npm i -g vercel
cd website
vercel --prod
```

### Option C — drag & drop
Zip the `website` folder (or just its contents) and drop it onto
<https://vercel.com/new> — it deploys as a static site.

## Customising

Everything lives in `index.html`:

- **Colors / theme** — the CSS variables at the top of the `<style>` block
  (`--g-400`, `--brand`, …), split into `[data-theme="dark"]` and `[data-theme="light"]`.
- **Logo / mascot** — the `<symbol id="parrot">` near the top of `<body>` (and `parrot.svg` for the favicon).
- **Copy / sections** — the HTML in `<main>`.
- **Download link** — point the "Download for macOS" buttons at your release URL.
