# Carton

Package tracker, iOS first. Paste a UPS number or link, get a countdown to the delivery day. No account, no server.

## How tracking works
UPS's API needs a UPS shipping account for keys, and ups.com blocks plain HTTP (Akamai). So the app loads UPS's own tracking page in a hidden `WKWebView` and reads the visible text (`app/Carton/UPSPage.swift`). `UPSPage.parse` is the fragile part: it keys off labels like "Estimated delivery", "Last Location", "Ship To" and the progress step marked "active". When UPS rewords its page, fix `parse` and add the new page text to `tests/ParseCheck.swift`. Run `tests/run.sh` after any change. The official API (`cli/ups.py`) is the upgrade path once keys exist.

## Layout
- `app/Carton/`: SwiftUI. `Brand` registers Carton Sans and `Font.carton(_:)` sets it at Dynamic Type sizes. `Store` (list, archive, iCloud key-value sync), `PackageList` (Packages and Archive tabs), `SettingsView` (profile, sync), `UPSPage` (the reader).
- `Carton.icon`: Icon Composer bundle, the source of the app icon. Drawing in `brand/src/box.svg`.
- `brand/`: `BRAND.md` is the rulebook, `tokens.css` the web tokens, `cover/` the App Store cover.
- `fonts/`: Carton Sans (Inter, OFL, renamed). Rebuild with `uv run --with fonttools --with brotli scripts/gen_font.py`, then `--check`.
- `docs/`: App Store listing, whitepaper, security.
- `cli/ups.py`: official-API tracker, needs `UPS_CLIENT_ID` and `UPS_CLIENT_SECRET`.

## QA
Use the dedicated `Carton-QA` simulator, not the shared booted one; other sessions drive that. Launch flags: `-add <number or link>` adds a package, `-tab 0|1|2` opens a tab, `-open` opens the first package.

## Web
`wrangler.toml` deploys one Worker named `carton` to carton.jaybulb.com: `web/` is the landing page with the working web app under the hero (`web/app.js`, list in localStorage), and `/api/track/<number>` reads UPS's page with Cloudflare Browser Rendering (`worker/index.js`). ups.com aborts a cold headless visit; loading the UPS home page first with a desktop Safari user agent picks up the cookies that let the tracking page through. `worker/parse.js` is the JS twin of `UPSPage.parse`: change both together and run `node worker/parse.test.mjs`. Results cache for 15 minutes. The free plan limits how often a new browser can start (429 "Rate limit exceeded"); the cache is what keeps that rare. Deploy is `npx wrangler deploy`; a push deploys nothing. Never put a real tracking number on the public page; `#1Z...` in the URL adds one locally and the hash never reaches the server.

## Not done
See `roadmap.md`: Mac target, icon layers, App Store record (probe the name Carton first).
