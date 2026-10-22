# Cartons loop handoff (2026-10-22, past midnight)

## What the loop is
This session's loop works the App Store rejections for Cartons and Oohaah. It is a cross-app loop run from the Claude session, not the roadmap loop from 2026-10-20. Each tick: check whether Apple's web sign-in has cleared, read the rejection reasons in Resolution Center with `asc web review show`, fix what Apple named in this repo, commit and push, and report back. It never resubmits or replies to Apple without Joshua's yes.

Rules for every tick:
- Never submit to App Review or reply to Apple without Joshua's yes.
- Never put a real tracking number or Joshua's address in code, tests, screenshots, the web page or the store text. Test numbers come from UPS's sample pages.
- Run `git status` first. Another session may be mid-edit, so stage only the files this tick changed.
- A push deploys nothing on the web. Deploy the Worker with `npx wrangler deploy` when web files change.

## Where things stand
- 1.0.0 is REJECTED on iPhone and on Mac, per asc. The iOS issue email arrived from Apple on Oct 20 at 5:31 PM PDT (submission 47d903af-ce77-450c-b448-ac44199d8411).
- The reasons are not read yet. Apple's web sign-in was throttled (HTTP 503) until 07:38 UTC, so the reasons sit behind it in Resolution Center.
- Review risk stays the same: guideline 5.2.2, because the app reads UPS's public tracking page. Fallback is 17TRACK's API. If Apple says it could not test (2.1), reply with how to get a live UPS number, never one of ours.
- The 1.1 store text is done in nine languages and sits on main as `metadata/<locale>.json`. None of it has been submitted, and it waits until the 1.0.0 rejection is handled.
- Repo `nulljosh/cartons`, folder `~/Documents/Code/cartons`. App Store record 6825115360, bundle `com.nulljosh.carton`, SKU `carton`. Web at cartons.jaybulb.com.

## Next, in order
1. When the sign-in clears, run `asc web review show` for Cartons on both platforms and copy the reasons into roadmap.md, not into the store text.
2. Fix what Apple named. Commit and push. Ask Joshua for the yes before any resubmit.
3. Once 1.0.0 is resolved, the 1.1 build goes up with the items below, validated first.
4. Built for 1.1 but not in a build yet: Tuck in the empty Packages list with its Add button, a "Checked" time on each package, a friendly error when UPS does not answer, Mac keys on onboarding, the "It's here" celebration with Archive, haptics, status-change notifications, Tuck as an alternate icon, the landing parallax pass, and the Apache 2.0 license.
5. v3 widgets, then the v4 share sheet, then the roadmap in order.

## Restart prompt
```
Read docs/LOOP-HANDOFF.md in ~/Documents/Code/cartons, then check whether asc web sign-in works. If it does, run asc web review show for Cartons 1.0.0 on iOS and macOS, record Apple's reasons in roadmap.md, and fix what they name. Commit and push each fix, stage by exact path. Never submit to App Review or reply to Apple without Joshua's yes.
```
