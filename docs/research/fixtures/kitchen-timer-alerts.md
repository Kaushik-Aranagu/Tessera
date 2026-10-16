# Kitchen timers that ring (board item 140, CL6)

For: Core, Builder A (Live Activity) and QA. Owner: Research lab. Date: Oct 16, 2026 (Pacific).
Master `bb7f082` (the checked-out branch has the same code), traced by hand, nothing was run.

**Sources.** Product's answers in `asks-after-close.md` (CL6, CL9, CL11, C14) and decisions 3:46 AM PT Oct 16;
decisions 6:20 PM and 6:30 PM PT (notifications, first set; ask lines final) and 4:50 PM PT (cook timer calls);
`notifications.md` N3, sections 3, 4 and 6; `cook-timer-phrases.md`; `cook-mode-scenarios.md`; `cook-mode-acceptance.md`.
**Fixed:** Core schedules a local notification when a timer starts and cancels it on stop or UNDO. His timers ring at
any hour, haptic included. Quiet hours (11 pm to 7 am) and the day close hold app asks only.

**Master today.** No `UNUserNotificationCenter` anywhere (`git grep`: only HealthKit and Speech ask for anything).
`StartKitchenTimer` stores `startedAt`, `endsAt`, `minutes` (`Cooking.swift:176-194`). The only way to start one is the
Tess bar ("timer rice 12", `TessCaptureEngine.swift:347-352`); the parse needs the word "timer"
(`TessGrammar+Kitchen.swift:100`). Nothing in the app calls `StopKitchenTimer`. There is no cook Live Activity: the
widget bundle has only `RestLiveActivity` (`Widgets/TesseraWidgetsBundle.swift:7`).

## Rules

| # | Rule | Status |
|---|---|---|
| KT1 | **Line.** Title "Rice, done." (thing first, the house shape of "dal, done."). Body in a cook: "Weeknight dal, step 2." Bare: "12 min." Under 2 min the body reads in seconds ("90 sec."). No "!", no emoji | Default proposed |
| KT2 | **Sound and haptic.** Sound `.default`; the system vibrates with it. At any hour, on a closed day and in quiet hours (CL9, CL11). In the app, Tessera plays its own haptic with the flare | Decided (CL9) |
| KT3 | **Interruption level** `.active`, thread `tessera.kitchen`, no badge. Time Sensitive needs an entitlement the free team may not sign (`notifications.md` Q6) | Default proposed |
| KT4 | **One notification per timer**, id `kitchen-timer.<timerID>`. No repeat, no snooze, no "still going" | Default proposed |
| KT5 | **Trigger** `UNTimeIntervalNotificationTrigger(endsAt - real now)`, never a calendar trigger, so a zone or DST change never moves it. Real clock, not `-demoTime` | Default proposed |
| KT6 | **Cancel** on stop, UNDO of the start, `FinishCooking` and delete: pending and delivered both removed | Decided (CL6) |
| KT7 | **Edit.** A running label restarts that timer (decision 4:50 PM): same object, same id, request replaced. UNDO of the edit puts the old end back | Decided (restart); id rule proposed |
| KT8 | **Several at once.** Each timer its own request. Two ending the same minute: two banners, each with its own line | Default proposed |
| KT9 | **In a cook or bare.** Same rule; only the body differs (KT1). Finishing a cook cancels its own timers; bare timers live on | Default proposed |
| KT10 | **App in front.** `willPresent` returns `[.sound, .list]`, no banner. The Now line (or cook mode) flares "Rice, done." with the haptic | Default proposed |
| KT11 | **Locked or app away.** Banner with sound and haptic on the Lock Screen | Default proposed |
| KT12 | **Focus or Do Not Disturb.** We never read Focus. A Focus that doesn't allow Tessera holds it in Notification Center; his setting | Default proposed |
| KT13 | **Permission not asked yet.** The ask fires at his first timer (decision 6:30 PM): after the receipt, "Want timers to alert you when locked?" Allow · Not now. Allow shows the iOS sheet; schedule on grant. Request `[.alert, .sound]`, never provisional | Decided (trigger); line from A7 |
| KT14 | **Not now or denied.** Receipt "Rice, 12 min. It rings in the app only." on the first timer of each day; the in-app flare still plays | Default proposed |
| KT15 | **Killed, rebooted.** Pending requests live in iOS, not the app: a timer rings with the app killed or after a restart. One reconcile on launch and foreground rebuilds the set from the store | Default proposed |
| KT16 | **Time zone (trip Oct 26) and DST (Nov 1).** A timer is a length: 40 min is 40 real minutes across a zone change or the fall-back hour | Default proposed |
| KT17 | **Past the end, not stopped.** Never rescheduled and never rung twice; the reconcile skips `endsAt <= now`. It stays flared in the app until stopped | Default proposed |
| KT18 | **Live Activity (Builder A).** The notification is the only sound. Activity updates carry no `AlertConfiguration`; the face flips to Done through `staleDate` | Default proposed (acceptance 3) |
| KT19 | **Budget.** At most 8 kitchen timers pending; a ninth is refused with "Eight timers is the most." | Default proposed |

## Scenarios (Thursday, Oct 22, Pacific, unless a row says so)

| # | What he does / says, at what time | Expected (what rings, when, the line) | Master today (file:line) |
|---|---|---|---|
| T1 | 7:45 pm, cooking Weeknight dal on step 2, phone locked after: "timer rice 12" | 7:57 pm banner "Rice, done." / "Weeknight dal, step 2.", sound and haptic | Timer stored, linked to the cook; nothing rings (`Cooking.swift:176-194`, `TessCaptureEngine.swift:350`) |
| T2 | 3:10 pm, no cook: "timer eggs 9" | 3:19 pm "Eggs, done." / "9 min." | Stored; not on Now, which reads only a running cook's timers (`NowPicker.swift:56-57`); silent |
| T3 | Rice ends at 7:57 pm with Now on screen | No banner; sound, haptic, the Now line flares "Rice, done." | The ended timer drops off Now (`endsAt > now`, `NowPicker.swift:57`); the line falls back to the step |
| T4 | Rice ends while he is in Safari | Banner, sound, haptic | Nothing |
| T5 | Rice ends 7:57 pm, Simmer ends 8:05 pm | Two rings, each at its own time, each its own line | Nothing |
| T6 | 6:20 pm, "timer pasta 10" then "timer sauce 10" ten seconds apart | Two banners at 6:30 pm: "Pasta, done.", "Sauce, done." | Nothing |
| T7 | 7:45 pm "timer rice 12", then UNDO within 4 s | Nothing ever rings | Inside the 2 s grace the start is discarded before any observer sees it; after commit, `undo` notifies no observer (`ActionEngine.swift:27, 68-70, 142-148`), so a scheduler hung on `observe` would still ring |
| T8 | 7:52 pm, stops Rice (cook mode drag, or "stop the rice" once RC15 S1 lands) | Pending request removed; nothing at 7:57 pm. Line "Rice stopped." with UNDO | No app caller of `StopKitchenTimer` (`Cooking.swift:202-214`); no stop grammar |
| T9 | 7:58 pm, stops Rice after it rang | The delivered notification leaves Notification Center | Nothing |
| T10 | 7:53 pm, UNDO of that stop | Same id rescheduled for 7:57 pm | Nothing |
| T11 | 7:50 pm, Rice running: "timer rice 15" | Rice restarts, ends 8:05 pm; one ring at 8:05 pm, none at 7:57 pm | A second Rice timer (`Cooking.swift:182` always creates) |
| T12 | 7:51 pm, UNDO of that edit | Back to one ring at 7:57 pm | Undo removes the second Rice; nothing rings either way |
| T13 | 7:55 pm, finishes the dal early; bare Eggs timer also runs | Rice and Simmer cancelled; Eggs still rings | `FinishCooking` stops linked timers (`Cooking.swift:248-252`); nothing to cancel |
| T14 | 7:56 pm, UNDO of the finish | Rice (7:57 pm) and Simmer (8:05 pm) rescheduled; a timer already past its end flares, no late ring | Undo clears `isStopped`; nothing rings |
| T15 | 7:50 pm, swipes Tessera away | Rice rings at 7:57 pm | Nothing |
| T16 | 7:50 pm, phone restarts, unlocked 7:55 pm | Rice rings at 7:57 pm (persistence across restart unverified on iOS 27) | Nothing |
| T17 | 11:10 pm, Sleep Focus on, Tessera not allowed: tea timer ends | Held in Notification Center, no sound (his Focus) | Nothing |
| T18 | 11:10 pm, day closed at 9:10 pm, no Focus: tea timer ends | "Tea, done." with sound and haptic (CL9, C14) | Nothing; `shutdown.md` "Never" rule would also block the haptic (CL9) |
| T19 | 6:00 pm, first timer ever, permission not asked | "Rice, 12 min." then "Want timers to alert you when locked?" Allow · Not now; Allow, then the iOS sheet, then scheduled | No ask exists (no ask ledger in code) |
| T20 | 11:30 pm, first timer ever, quiet hours | Ask held (Q1 ★); this timer flares in the app only; the ask fires at the next timer between 7 am and the close | Nothing |
| T21 | Permission denied: "timer rice 12" at 6 pm | "Rice, 12 min. It rings in the app only." In-app flare at 6:12 pm; nothing on the Lock Screen | "Rice, 12 min." only |
| T22 | Mon Oct 26, 2:30 pm PT on the plane: "timer nap 40"; phone switches to Eastern at 2:50 pm PT | Rings at 3:10 pm PT (6:10 pm ET), 40 real minutes | Nothing |
| T23 | Sun Nov 1, 1:50 am PDT: "timer oven 20" | Rings at 1:10 am PST, 20 real minutes | Nothing |
| T24 | Cook Live Activity showing (Builder A) when Rice ends, locked | One sound, from the notification; the face flips to Done silently | No cook activity (`TesseraWidgetsBundle.swift:7`) |
| T25 | Rice ended 7:57 pm, never stopped; he opens the app Friday 8 am | No second ring; Rice still flared until stopped | Kept forever as a running timer (`Cooking.swift:49-60`) |
| T26 | QA: `-demoTime 18:10 -resetDemo`, "timer tea 2" | Rings 2 real minutes later; the line never shows the shifted clock | Start uses the real clock (`Cooking.swift:180`); nothing rings |

## Gaps for Core

| # | Gap | Where | Default proposed | Owner |
|---|---|---|---|---|
| KG1 | No notifications at all: no scheduler, no delegate, no categories | `App/TesseraApp.swift:80` (scenePhase only), new `NotificationScheduler` | Pure `NotificationPlan` in TesseraCore plus an app scheduler that diffs pending requests (`notifications.md` section 6) | Core |
| KG2 | UNDO and redo never reach observers, so a hook on commit leaves a ring after UNDO | `ActionEngine.swift:68-70, 92-101, 142-156`; UNDO paths `BottomChrome.swift:724-731`, `AppModel.swift:297-308` | Call `notify` from `undo` and `redo`, or reconcile after every UNDO | Core |
| KG3 | A running label makes a second timer, against the 4:50 PM call | `Cooking.swift:176-194` | Restart the open timer with that label: new `startedAt`, `endsAt`, same id | Core |
| KG4 | Nothing in the app stops a timer | `Cooking.swift:202-214` (no caller) | RC15 S1 and S2 in grammar; cook mode drag and flare tap | Core, Builder A |
| KG5 | A bare timer is never on Now, and an ended one drops off, so the in-app ring has no home | `NowPicker.swift:54-67` | Now shows any running or flared timer; flare "Rice, done." until stopped | Core, Builder B |
| KG6 | Ended timers that were never stopped count as running forever | `Cooking.swift:49-60` | Plan skips `endsAt <= now`; the 4 am roll stops timers flared over 6 h | Core |
| KG7 | No permission ask or fallback line | `TessCaptureEngine.swift:352` | KT13 and KT14; ask is A7 in the one-ask-a-day queue | Core, Builder B |
| KG8 | Copy differs: `notifications.md` N3 and `cook-mode-scenarios.md` say "Pasta is done" | `notifications.md` N3 | "Rice, done." (KT1); Design to confirm | Design |

## Question for Product

**Q1.** His first timer ever comes in quiet hours or after the close. The permission ask is an app ask, so CL11 holds
it. ★ Hold the ask to his next timer between 7 am and the close; tonight's timer flares in the app only. Or ask now,
since he just started the timer.
