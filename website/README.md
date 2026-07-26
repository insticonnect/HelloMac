# mitthuai — website 🦜

The marketing site for **mitthuai** — *your Mac's memory, answerable by Claude.*

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

## Deploy on Vercel

Because the app lives in the `website/` subfolder (the repo root is the macOS app),
you point Vercel at this folder **once** with the Root Directory setting. Then Vercel
auto-detects Vite and everything else is default — no custom build commands.

### New project
1. Import the repo at <https://vercel.com/new>.
2. When it asks, set **Root Directory** to `website`
   (the "Edit" next to Root Directory → pick the `website` folder).
3. Framework is auto-detected as **Vite** — leave Build/Output at their defaults.
4. **Deploy.**

### Existing project that failed to build
If you already created the project, just fix the one setting:
1. Vercel dashboard → your project → **Settings → General**.
2. **Root Directory** → set to `website` → **Save**.
3. Make sure **Build & Development Settings** have no manual overrides
   (Framework = Vite, everything else "Override" toggles **off**).
4. **Deployments** tab → **Redeploy**.

> There is intentionally **no `vercel.json` at the repository root** — a root-level build
> command conflicts with the Root Directory setting and causes
> `cd: website: No such file or directory`. Setting Root Directory to `website` is all
> that's needed.

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
