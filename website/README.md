# mitthuai — website 🦜

The marketing site for **mitthuai / HelloMac** — *your Mac's memory, answerable by Claude.*

Built with **React + Vite**. Fully responsive (phone / tablet / desktop), with a greenish
parrot theme and a persistent **dark / light** toggle that also respects the visitor's OS
preference. No CSS framework — the design system is hand-written CSS variables.

## Tech

- **React 18** (function components + hooks)
- **Vite 5** for dev server and production build
- Plain CSS (`src/index.css`) with `[data-theme]` light/dark tokens
- Zero UI dependencies beyond React

## Project structure

```
website/
├── index.html               # Vite entry + no-flash theme bootstrap
├── package.json
├── vite.config.js
├── vercel.json              # caching + security headers
├── public/
│   └── parrot.svg           # Mitthu the parrot — favicon + mascot image
└── src/
    ├── main.jsx             # React entry
    ├── App.jsx              # page composition
    ├── index.css            # theme tokens, layout, responsive rules
    ├── hooks/
    │   ├── useTheme.js       # dark/light state → <html data-theme> + localStorage
    │   └── useReveal.js      # IntersectionObserver scroll-reveal
    └── components/
        ├── Header.jsx  Hero.jsx  Strip.jsx  Features.jsx
        ├── HowItWorks.jsx  ClaudeSection.jsx  Privacy.jsx
        ├── CTA.jsx  Footer.jsx  ParrotMark.jsx
```

## Develop

```bash
cd website
npm install
npm run dev       # http://localhost:5173
```

## Build

```bash
npm run build     # outputs to dist/
npm run preview   # serve the production build locally
```

## Deploy on Vercel

Vercel auto-detects Vite — no manual settings needed.

### Option A — Vercel dashboard (easiest)
1. Import the repo at <https://vercel.com/new>.
2. Set **Root Directory** to `website`.
3. Framework preset is detected as **Vite** automatically
   (Build command `npm run build`, Output directory `dist`).
4. **Deploy.**

### Option B — Vercel CLI
```bash
npm i -g vercel
cd website
vercel        # preview
vercel --prod # production
```

## Customising

- **Colors / theme** — every color is a CSS variable at the top of `src/index.css`
  (`--g-400`, `--brand`, …), split into `[data-theme="dark"]` and `[data-theme="light"]` blocks.
- **Logo** — swap `public/parrot.svg` (favicon + mascot) and `src/components/ParrotMark.jsx` (inline header logo).
- **Copy / sections** — each section is its own component in `src/components/`.
- **Download link** — point the "Download for macOS" buttons at your release URL.
