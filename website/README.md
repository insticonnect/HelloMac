# mitthuai — website 🦜

The marketing site for **mitthuai / HelloMac** — *your Mac's memory, answerable by Claude.*

Built with **React 18 + Vite**. Componentized, genuinely interactive (theme toggle, animated
count-up stats, an "Ask Mitthu" chat demo, tabbed MCP tools, an FAQ accordion, scroll-spy nav,
back-to-top), with a greenish parrot theme, **light + dark** mode, and full phone/tablet/desktop
responsiveness.

## Tech

- **React 18** — function components + hooks, no other UI libraries
- **Vite 5** — dev server + production build (`base: './'` so assets resolve anywhere)
- Plain CSS design system in `src/index.css` with `[data-theme]` light/dark tokens

## Structure

```
website/
├── index.html                Vite entry + no-flash theme bootstrap
├── package.json  vite.config.js  vercel.json
├── public/parrot.svg          favicon
└── src/
    ├── main.jsx  App.jsx  index.css
    ├── data/site.js           all copy: nav, stats, features, steps, demo, tools, FAQ
    ├── hooks/
    │   ├── useTheme.js         dark/light → <html data-theme> + localStorage, OS-aware
    │   ├── useInView.js        IntersectionObserver → reveal + count-up trigger
    │   ├── useCountUp.js       eased number animation
    │   └── useScrollSpy.js     active nav link
    └── components/
        ├── Header · Hero · Stats · Features · HowItWorks
        ├── AskDemo (interactive chat) · Tools (tabs) · ClaudeSetup (copy)
        ├── Privacy · FAQ (accordion) · CTA · Footer · BackToTop
        ├── Reveal (scroll-reveal wrapper) · ParrotMark (logo)
```

## Develop

```bash
cd website
npm install
npm run dev        # http://localhost:5173
```

## Build

```bash
npm run build      # → dist/
npm run preview    # serve the production build
```

## Deploy on Vercel — two easy paths

### Path A · zero config (recommended)
There's a **`vercel.json` at the repo root** that already tells Vercel how to build this
subfolder. So you can just:

1. Import the repo at <https://vercel.com/new>.
2. Leave every setting at its default.
3. **Deploy.** Vercel runs `cd website && npm install && npm run build` and serves `website/dist`.

### Path B · point Vercel at this folder
1. Import the repo, then set **Root Directory** to `website`.
2. Vercel auto-detects **Vite** (build `npm run build`, output `dist`).
3. **Deploy.**

Either way it builds and serves correctly — no other tweaks needed.

### Vercel CLI
```bash
npm i -g vercel
cd website
vercel --prod
```

## Customising

- **Content** — edit `src/data/site.js` (nav, stats, features, demo Q&A, tools, FAQ).
- **Colors / theme** — CSS variables at the top of `src/index.css`, split into
  `[data-theme="dark"]` and `[data-theme="light"]`.
- **Logo / mascot** — `src/components/ParrotMark.jsx` and `public/parrot.svg`.
- **Download link** — point the "Download for macOS" buttons at your release URL.
