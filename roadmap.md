# Cartons roadmap

One number first: days until it shows up. Everything below serves that.

## To v1.0 (the loop works this list)
- [x] v0.8 Splash, first-run onboarding (three animated glyph pages) and Tuck the mascot (`Mascot.swift`)
- [x] Tuck on the landing page; parallax hero and shader footer
- [x] Tuck in the empty Packages list (with an Add button) and on the brand kit page
- [x] v0.9 iOS build 2 and Mac build 1 (1.0.0) uploaded and attached, listing, screenshots (iPhone, iPad, Mac), privacy label, pricing free, all territories; `asc validate` clean
- [x] v1.0 Submitted for review on iOS and Mac, 2026-10-20 (both WAITING_FOR_REVIEW)

## v1.1 (next build, while 1.0 is in review)
- [ ] Empty-list Tuck and Add button in the build (ships with 1.1, 1.0 is frozen)
- [x] Mac keys on onboarding: Return for Next, Esc for Skip
- [x] "Checked" time on each package (pull to refresh was already there)
- [x] Friendly error when UPS doesn't answer: Tuck, the reason, "Open on ups.com" below
- [x] Fix: a delivered page with no date showed "Latest Update" (app) or the number (web) as the date; both parsers now need a real date, with a test
- [x] Delivered state: "It's here", Tuck waves and a haptic fires the first time only, then "Archive it"
- [x] Haptics on add and on the first "It's here" (iOS)
- [ ] Tuck as an alternate app icon, picked in Settings (iOS and iPad; the kraft box stays the default)
- [ ] Landing parallax A+ pass: depth blur, lighting, smoother scroll, mobile
- [x] Price $0.99 upfront (MONEY.md), Apache 2.0, README badges and rounded icon, footer tracking, 7 done issues closed
- [ ] If review rejects for "couldn't test" (2.1): reply with how to get a live UPS number, never Joshua's own

## v1 to v10: the tracker people keep
- [x] v2 Notifications when the status changes (iOS background refresh every 30 min or so; Mac on open). Banner still to be seen on a real device
- v3 Widgets: next delivery on the home and lock screen
- v4 Share sheet: send a tracking link from Mail or Safari straight in
- v5 Live Activity for out-for-delivery day
- v6 Canada Post and USPS
- v7 FedEx and DHL
- v8 Amazon order links
- v9 Siri and Shortcuts: "when is my package coming"
- v10 Apple Watch: the countdown on your wrist

## v10 to v30: every carrier, every device
- v12 Mail scanning: find tracking numbers in your inbox, on device, opt in
- v15 Map of the route with every scan as a stop
- v18 iPad layout with a sidebar
- v20 Calendar: delivery day as an all-day event
- v22 Delivery photos and signatures where the carrier shows them
- v25 Thirty carriers through one reader per carrier, each with captured page text in the test
- v28 Translations, every interface string in 19 languages
- v30 Accessibility audit: VoiceOver walkthrough, Dynamic Type to the largest size

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
