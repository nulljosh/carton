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
- The 1.1 store text is done in nine languages (Spanish for Spain and Mexico, Chinese, Japanese, German, Portuguese, French, Korean, Italian), as `metadata/<locale>.json` on main. The app UI is in eight languages. None of it has been submitted.
- Built for 1.1 but not in a build yet: Tuck in the empty Packages list with its Add button, a "Checked" time on each package, a friendly error when UPS does not answer, Mac keys on onboarding (Return and Esc), the "It's here" celebration with Archive, haptics, notifications when a status changes (iOS background refresh, Mac on open), Tuck as an alternate app icon picked in Settings, the landing parallax pass, and the Apache 2.0 license.
- Not yet seen on a real device: the status-change notification banner.
- Siri and Shortcuts landed in 793efb7 and the roadmap marks it shipped (987d927), so the open question about v9 from the earlier handoff is closed. The landing sky change (21d4947) is on main too.
- The repo was clean at this checkpoint. The web deploy was not re-checked, so confirm it matches `main` before calling a web item done.
- Repo `nulljosh/cartons`, folder `~/Documents/Code/cartons`. App Store record 6825115360, bundle `com.nulljosh.carton`, SKU `carton`. Web at cartons.jaybulb.com.

## Next, in order
1. Each tick, check App Review for 1.0.0 on both platforms. When 1.0 clears, upload a 1.1 build with the items above, validate it, and ask Joshua for the yes before submitting. The nine-language store text goes up with that build.
2. v3 widgets: next delivery on the home and lock screen. Blocked on the App Group check, which needs a live Apple web session. Joshua re-runs `asc web auth login` himself (Apple returned a 503 on the last try, and auto sign-in is paused until 2026-10-21 02:23 UTC). Then `export ASC_BYPASS_KEYCHAIN=1; asc web app-groups list`.
3. v4 share sheet: send a tracking link from Mail or Safari straight in.
4. Then the roadmap in order, v5 onward.

## Restart prompt
```
/loop work Cartons (~/Documents/Code/cartons) down roadmap.md from v1.1 toward v100, forever: build each item, QA it, commit, push, deploy, send screenshots as each piece lands, check App Review status each tick, keep the roadmap current. Never submit or reply to Apple without Joshua's yes.
```
