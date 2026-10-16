# QA review: #402 Builder A's soul router

Head `cf111f8` on master 732d72f. Trial merge onto master 5ef908d is clean. Nine files: SoulRouter.swift (new), SoulRouterTests.swift (new), AppModel, RootView, BottomChrome, HomeSpatialView, ClaudeSection, WorkoutModeView, and the clip 47-soul-router-capture.mp4 (15.6 s). This is a static review; there is no Swift toolchain here.

## Verdict: FIX FIRST (one line: the workout's corner now falls asleep after 23:00)

### F1. `page = .live` rests 23:00 to 06:00; master's workout corner never did
On master, the workout's `play(_:)` always returned to `.idle` after Done. The router's `rest` (SoulRouter.swift:65-68) ignores `page`: after 23:00 or before 06:00 it returns `.resting`, and every Done ends there (`playDone`, :159). So a late session now goes Done, then resting (the 12-15 s breath meant for Shutdown and quiet hours, tess-motion.md §10 and line 210) after every set. Before the first set the corner is still `.idle`, because the live router never gets `.appeared`. The PR says behavior is unchanged, and this is the one place it isn't.

Fix: `guard page == .home else { return .idle }` at the top of `rest`, plus a test: `SoulRouter(page: .live, clock: 23:30)`, then `.setLogged`, then after 2 s the mode is `.idle`.

## The two acceptance gates (tess-motion-build.md "Acceptance for the PR")
- `tessMode\s*=` outside SoulRouter.swift: the only hit is the doc comment in SoulRouterTests.swift:90. `AppModel.tessMode` is now a get-only view of `soul.mode` (AppModel.swift:91-94), and `mode` is `private(set)`. `noViewSetsHerMode` greps App, Features and DesignSystem. **Pass.**
- `Task.sleep` in Features/Tess, BottomChrome and WorkoutModeView: soul timers are only in the router (4 s line :85, 1.2 s best :110, 900 ms brighten :129, Done or flood :157). None of the others writes the soul or emits an event from its timer:
  - BottomChrome: `-speakScript` and `-tessScript` (:117-119, :680-690, both inside `#if DEBUG` and `LaunchFlags.has`); the 400 ms hold-to-listen gesture timer (:245, which calls `speak`, and `speak` emits `.speak`); the dry (:477, which commits); the 260 ms double-tap window (:540); the voice ghost dry (:638); and the line fade (:704, text only now).
  - WorkoutModeView: UNDO line (:119), rest glint (:142), ask reply (:281), subline drying (:410), "One more than last time." (:493), snap note (:548), GO (:607). All are text or ink.
  - SoulGallery.swift:73 cycles the DEBUG gallery's preview modes (TesseraApp.swift:44-46); that isn't her state.
  - **Pass.**

## Behavior against master (each traced)
- Open, close, draft, send, dry-cancel, speak, heard, heard-nothing and commit map one for one onto the old writes. `opened()` runs on every expand, including ObjectPage, ExercisePage and the voice path, so `isSurfaceOpen` tracks `isCommandExpanded` as the old `say()` guard did.
- Brighten moves into the router (900 ms). The `.success` haptic now triggers on `soul.isBright` (BottomChrome.swift:126), still one per capture. The animation goes through `.tesseraAnimation`.
- In the workout, set, best (thinking 1.2 s, then Done), swap, top-set, gathered and live ask keep the same modes and durations. The router also cancels overlapping timers, where master's `play()` raced them. That is a fix.
- Lens (§15): the hold is refused while she listens or the surface is open (HomeSpatialView.swift:258). A refused hold never sets `lens`, so `releaseLens` returns early and no unpaired `.lensReleased` is sent. `isPinned` has no reader yet, as stated.
- Data safety: no store, migration or launch-flag change. Both debug scripts stay behind `LaunchFlags.has` inside `#if DEBUG`. There are no raw ProcessInfo reads.

## Lows
- L1: `goHome` under Reduce Motion. On master, Done lasted 150 + 60 + 900 ms and then went to `.idle`. Now it is a fixed 1.44 s, then rest (resting at night). Fine as is; the spec row says idle after 900 ms.
- L2: in ClaudeSection, the key check's Done now returns to rest after 1.8 s. On master she stayed in `.done` until something else moved her. That is a fix; it's noted only because it is a change.
- L3 (this was on master too): the 4 s line timer (`.lineShown`) isn't cancelled when she starts listening. A hold-to-speak doesn't open the surface, so a line said just before a hold returns her to rest mid-listen. Master's `say()` had the same gap. `guard mode != .listening && mode != .thinking` in the timer would close it.
- L4: three router tests wait on real time (2.0 s and 1.4 s, SoulRouterTests.swift:56-80). There's room on a loaded simulator, but an injected sleeper would make them exact.
- The clip shows the capture path at 9:00 PM: open, Write, the dry, the receipt "Stretch, today 9:30 pm." with UNDO, and the soul back at rest. It doesn't show the workout corner or night rest, which is F1's case.

## Addendum: re-check at `559e093`

Verdict: **PASS**. One commit on cf111f8. Trial merge onto master is clean.

- F1 fixed: `rest` returns `.idle` for `page = .live` (SoulRouter.swift, `rest`). The test is `theWorkoutCornerRestsAtIdleAtNight`.
- L1 withdrawn: I had the old sum wrong. Master's Reduce Motion path was 150 + 60 + 900 ms = 1.11 s, not 0.69 s. The router now uses that exact sum (`.goHome(reduceMotion:)`).
- L2: a failed key check emits `.claudeFailed`, which goes to rest, and Done plays only for works or capReached.
- L3 fixed: the 4 s line timer skips listening and thinking. The test is `herLineNeverCutsHisVoice`.
- The lab's fixes, checked for regressions:
  - closed, heardNothing, appeared and claudeFailed now leave a Done in flight alone. Done returns through `queued ?? rest` itself, which also ends master's goHome case, where the surface's `.closed` cut the Done.
  - sent, heard and liveAsk queue thinking behind a Done. Every queued thinking is later settled by `.committed`, `.liveAnswered` or the commit path, so none is left hanging.
  - `.goHome` clears `isSurfaceOpen`.
  - askWaiting and askAnswered come from one `onChange` on `setAsk != nil || liftAsk != nil` (BottomChrome.swift:103). `refusesLens` is checked in both HomeSpatialView and the router.
- The gates still pass: no new `tessMode =` and no new soul `Task.sleep`. The `swiftlint:disable:next cyclomatic_complexity` covers only `handle(_:)`, the §14 table.
- New low (L5): if BottomChrome leaves while an ask waits, `isAskWaiting` stays true until the next ask change, so the lens is refused until then. The workout's end clears `setAsk` (:108), so the common path is covered.
- L4 (real-time waits, about 12 s in total) stays a low.

## Addendum: re-check at `45cbcd2` (the lab's F4)

Verdict: **PASS**. The change since 559e093 is limited to SoulRouter.swift and its test. Trial merge is clean.

- `playDone` clears `queued`, and a `.claudeFailed` during a Done clears it too. Every way a thinking gets queued now ends: `.committed` settles rest, while a Done or a failure clears the queue. My line at 559e093 that "every queued thinking is settled" missed the case where the answer arrives during the Done. The lab was right.
- New low L6, latent: `.backgrounded` cancels the Done timer, and `.foregrounded` is then ignored by the Done-in-flight guard, so she would stay in `.done`. Neither event is emitted yet (no caller in App or Features). When they're wired, `.backgrounded` should settle rest, or `.foregrounded` should skip the guard.
