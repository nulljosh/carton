# App Review prep

## Privacy nutrition label
Data Not Collected. Cartons has no account, no analytics and no server for the app. Tracking numbers stay on the device and in the user's own iCloud key-value store.

## Review notes (paste into App Store Connect)
Cartons tracks UPS packages. Tap +, paste a UPS tracking number (they start with 1Z) or a full UPS tracking link, and Cartons shows the status and a countdown to the delivery date. No sign-in is needed.

To try it, use any live UPS tracking number. Cartons loads UPS's public tracking page for that number, the same page a person would open in Safari, and shows the result in a simpler layout. Each package has an "Open on ups.com" link to the source page.

## Screenshots
`brand/screenshots/iphone/` (6.9 inch, Cartons-QA-Max simulator, status bar 9:41) and `brand/screenshots/mac/`. They use the `-demo` launch flag (debug builds only): sample packages on UPS's published example number pattern, no real shipment.

## Risks to weigh before submitting
- **Reading UPS's site.** UPS's website terms restrict automated access, and Apple's guideline 5.2.2 asks apps that use a third-party service to be permitted under its terms. Cartons opens the page on the user's own device for the user's own package, the way a browser would, which is the strongest version of this, but a reviewer or UPS could still object. Deliveries dropped UPS live status at some point, likely for this reason. The fallback is the official UPS API (`cli/ups.py`), which needs a UPS shipping account for keys.
- **Trademark.** The listing says "UPS" as a factual description of the carrier supported. No UPS logo or brown-and-gold styling anywhere.
- **Name.** "Cartons" had no exact match in a store search on 2026-10-20, but App Store Connect is the real test. Probe it before building the listing around it.
