# Carton

Package tracker, iOS first. Paste a UPS number or link, get a countdown to the delivery day. No account, no server.

## How tracking works
UPS's API needs a UPS shipping account for keys, and ups.com blocks plain HTTP (Akamai). So the app loads UPS's own tracking page in a hidden `WKWebView` and reads the visible text (`app/Carton/UPSPage.swift`). `UPSPage.parse` is the fragile part: it keys off labels like "Estimated delivery", "Last Location", "Ship To" and the progress step marked "active". When UPS rewords its page, fix `parse` and add the new page text to `tests/ParseCheck.swift`. Run `tests/run.sh` after any change. The official API (`cli/ups.py`) is the upgrade path once keys exist.

## Layout
- `app/Carton/`: SwiftUI. `Store` (list, archive, iCloud key-value sync), `PackageList` (Packages and Archive tabs), `SettingsView` (profile, sync), `UPSPage` (the reader).
- `Carton.icon`: Icon Composer bundle, the source of the app icon. Drawing in `brand/src/box.svg`.
- `brand/`: `BRAND.md` is the rulebook, `tokens.css` the web tokens, `cover/` the App Store cover.
- `fonts/`: Carton Sans (Inter, OFL, renamed). Rebuild with `uv run --with fonttools --with brotli scripts/gen_font.py`, then `--check`.
- `docs/`: App Store listing, whitepaper, security.
- `cli/ups.py`: official-API tracker, needs `UPS_CLIENT_ID` and `UPS_CLIENT_SECRET`.

## QA
Use the dedicated `Carton-QA` simulator, not the shared booted one; other sessions drive that. Launch flags: `-add <number or link>` adds a package, `-tab 0|1|2` opens a tab.

## Not done
Landing at carton.jaybulb.com and the web app (a browser can't load ups.com cross-origin, so the web app needs a Worker that reads the page), macOS target, more carriers, App Store record (probe the name Carton first).
