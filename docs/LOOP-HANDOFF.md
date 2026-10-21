# Cartons loop handoff (2026-10-20, evening)

## What the loop is
The loop works Cartons (`~/Documents/Code/cartons`) down `roadmap.md` from v1.1 toward v100, one item at a time. Each tick: build the item, QA it, commit, push, deploy the web side when it changed, send Joshua screenshots as each piece lands, check App Review status, and keep the roadmap current.

Rules for every tick:
- Never submit to App Review or reply to Apple without Joshua's yes.
- Never put a real tracking number or Joshua's address in code, tests, screenshots, the web page or the store text. Test numbers come from UPS's sample pages.
- Run `git status` first. Another session may be mid-edit, so stage only the files this tick changed.
- A push deploys nothing on the web. Deploy the Worker with `npx wrangler deploy` when web files change.

## Where things stand
- 1.0.0 is in App Review on iPhone (build 2) and Mac (build 1), both WAITING_FOR_REVIEW since 2026-10-20. Price is $0.99 upfront, set the same day (MONEY.md).
- Review risk: guideline 5.2.2, because the app reads UPS's public tracking page. Fallback is 17TRACK's API. If Apple says it could not test (2.1), reply with how to get a live UPS number, never one of ours.
- Built for 1.1 but not in a build yet: Tuck in the empty Packages list with its Add button, a "Checked" time on each package, a friendly error when UPS does not answer, Mac keys on onboarding (Return and Esc), the "It's here" celebration with Archive, haptics, notifications when a status changes (iOS background refresh, Mac on open), Tuck as an alternate app icon picked in Settings, the landing parallax pass, and the Apache 2.0 license.
- Not yet seen on a real device: the status-change notification banner.
- Mid-edit at checkpoint, not finished and not part of this handoff: `app/Cartons/Store.swift` (modified) and `app/Cartons/Shortcuts.swift` (new). The next tick reads both first, finishes them with a QA pass or leaves them alone, and never commits them half-done.
- Repo `nulljosh/cartons`, folder `~/Documents/Code/cartons`. App Store record 6825115360, bundle `com.nulljosh.carton`, SKU `carton`. Web at cartons.jaybulb.com. The web deploy was not re-checked at this checkpoint, so confirm it matches `main` before calling a web item done.

## Next, in order
1. Each tick, check App Review for 1.0.0 on both platforms. When 1.0 clears, upload a 1.1 build with the items above, validate it, and ask Joshua for the yes before submitting.
2. v3 widgets: next delivery on the home and lock screen.
3. v4 share sheet: send a tracking link from Mail or Safari straight in.
4. Then the roadmap in order, v5 onward.

## Restart prompt
```
/loop work Cartons (~/Documents/Code/cartons) down roadmap.md from v1.1 toward v100, forever: build each item, QA it, commit, push, deploy, send screenshots as each piece lands, check App Review status each tick, keep the roadmap current. Never submit or reply to Apple without Joshua's yes.
```
