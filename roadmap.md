# Cartons roadmap

One number first: days until it shows up. Everything below serves that.

## v1.1 (next build, while 1.0 is in review)
- [ ] If review rejects for "couldn't test" (2.1): reply with how to get a live UPS number, never Joshua's own

## v1 to v10: the tracker people keep
- v3 Widgets: next delivery on the home and lock screen (blocked: the App Group needs Joshua to run `asc web auth login` himself)
- v4 Share sheet: send a tracking link from Mail or Safari straight in
- v5 Live Activity for out-for-delivery day
- v6 Canada Post and USPS (Canada Post 403s plain requests, so it needs the WebKit reader; waiting on one real Canada Post number to build against)
- v7 FedEx and DHL
- v8 Amazon order links
- v10 Apple Watch: the countdown on your wrist

## v10 to v30: every carrier, every device
- v12 Mail scanning: find tracking numbers in your inbox, on device, opt in
- v15 Map of the route with every scan as a stop
- v18 iPad layout with a sidebar
- v22 Delivery photos and signatures where the carrier shows them
- v25 Thirty carriers through one reader per carrier, each with captured page text in the test
- v28 Translations: the app is in 8 languages (es, zh-Hans, ja, de, pt-BR, fr, ko, it) through `Localizable.xcstrings`; the App Store listing is ready in `metadata/<locale>.json` and goes up with the 1.1 version; next Siri phrases, then 11 more languages
- v30 Accessibility: a real-device VoiceOver walkthrough is left (rows read as one sentence, Tuck hidden where text says it, reduced motion stops Tuck and the glyphs, largest Dynamic Type wraps)

## v30 to v60: households and history
- v35 Shared lists for a household through iCloud sharing
- v40 History: what you ordered, from whom, how late it was
- v45 Carrier report card: on-time rate per carrier from your own deliveries
- v50 Returns: track the package going back and the refund
- v55 Porch alerts: out for delivery plus a nudge when it lands
- v60 Vision Pro and Apple TV views

## v60 to v100: the best tracker on the store
- v70 Official carrier APIs where keys allow, page readers as the fallback
- v80 Web app at parity with iOS, synced through iCloud web
- v90 Open data export, JSON and CSV
- v100 Ten years of packages in one calm list

## Ingested 2026-10-22
- [ ] Apple emailed "There's an issue with your Cartons (iOS) submission" (submitted Oct 20, 2026 05:31 PM PDT by API key, 1 item, submission ID 47d903af-ce77-450c-b448-ac44199d8411, App Version 1.0.0 for iOS). The reason is cut off in the screenshot (/Users/joshua/Documents/Code/notes/attachments/2026-10-22/asc-1.png). Read it with `asc web review show`, fix, resubmit. Mac 1.0.0 was submitted separately and is not named in this email.
