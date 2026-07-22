# mitthuai — ship & operate runbook

What it takes to let people download HelloMac from **mitthuai.com**, sign in with
Google (login only), and use it from Claude. No Stripe. No Gmail reading.

## Accounts & one-time setup

| # | What | Why | Cost |
|---|------|-----|------|
| 1 | **Apple Developer Program** | Sign + notarize the app so macOS lets people install it without warnings | $99/yr |
| 2 | **Google Cloud project + OAuth client (Web)** | "Sign in with Google" for identity. Scopes `openid email profile` only → no security assessment | free |
| 3 | **Domain mitthuai.com** (have it) + host for the landing page (`site/`) | Download page + privacy/terms | ~free |
| 4 | **A small server** (Cloud Run / Fly / a VPS) for the relay (`relay/`) | Tunnel so Claude.ai web can reach a user's Mac | ~$5–20/mo |
| 5 | **Privacy policy + Terms pages** | Required by Google consent screen & Apple | time only |

## Build & distribute the app (D1)

1. In `build.sh`, replace the ad-hoc sign step with your Developer ID:
   ```bash
   codesign --force --deep --options runtime \
     -s "Developer ID Application: <Your Name> (<TEAMID>)" \
     --entitlements entitlements.plist "${APP_DIR}"
   ```
2. Notarize and staple:
   ```bash
   xcrun notarytool submit build/HelloMac.dmg --apple-id <id> --team-id <TEAMID> --password <app-specific-pw> --wait
   xcrun stapler staple build/HelloMac.app
   ```
3. Host the `.dmg`; point `mitthuai.com/download` at it.
4. (Optional) Add **Sparkle** for auto-updates.

## Stand up the relay (D3)

1. Create the Google OAuth client (Web application); redirect URI
   `https://relay.mitthuai.com/auth/google/callback`.
2. Deploy `relay/` with env `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`,
   `BASE_URL=https://relay.mitthuai.com`. See `relay/README.md`.
3. Point the app at it if your host differs from the defaults — the app reads
   `relay_url` (`wss://relay.mitthuai.com/agent`) and `pairing_url`
   (`https://mitthuai.com`) from settings (`Config.swift`).

## The user's flow (already built in the app)

1. Download, install, grant Accessibility.
2. Dashboard → Settings → **Claude.ai web access** → *Connect account* →
   browser opens `mitthuai.com/pair` → Sign in with Google.
3. App polls `/api/device-token`, stores the account token in the Keychain, and
   `RelayClient` opens the tunnel automatically.
4. In Claude, add the connector:
   - Claude Code/Desktop (works now):
     `claude mcp add --transport http mitthuai https://relay.mitthuai.com/mcp --header "Authorization: Bearer <account token>"`
   - Claude.ai web: add the custom connector once the relay's OAuth endpoints
     are in place (see `relay/README.md` → "Claude.ai web OAuth").

## What's done vs. what needs your accounts

- **Done in this repo:** app-side tunnel (`RelayClient.swift`), device pairing
  (`AccountPairing.swift`), account UI in the dashboard, shared MCP dispatch,
  a runnable relay (`relay/`), and the landing page (`site/`).
- **Needs your accounts/keys (can't be done from code):** Apple Developer ID +
  notarization, the Google OAuth client, deploying the relay, and the Claude.ai
  web OAuth endpoints (routing/tunnel underneath them is already built).
