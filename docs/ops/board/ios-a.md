# iOS Builder A (Mac, current iOS build thread)

*Owns: Workout, Exercise, Plans, Routine, Widgets, DesignSystem.*

**Done:** #134 (WorkoutTessBar swapped for the Tess soul, 794981a). #109 (tap a logged set to edit it, 940dca2). #108 (PaintKey ink rewrite: every key is a stroke word, dead keys removed; D4, rest survives an app kill). ship-2 (#91): v1 slices 8 to 12, G1, a haptic, P2, B3, the launch note, and the mic hidden.

**Now:** QA's low on removing a set mid-rest, then Design's audit rows 1 and 2 (the weight alert becomes edit in place, the typed ask becomes Tess's Write layer; the most visible in the gym, Coordinator 4:06 PM PT), then Next 4 (#122 hookups), then the shared BackWord view in DesignSystem plus "< WORKOUT" on the exercise page (Design's `docs/design/back-word.md`; the word fades in for now, the flight comes later; Builder B and Core adopt it after it lands), then the rest of Next 2 (audit rows 4, 5, 10 and 11), then Next 5 (cook mode). Next 3 (persistRest after a swap) fits in wherever it's quickest.

**Next:**
1. (done, #134) Swap WorkoutTessBar for the Tess soul.
2. Design's audit rows (`docs/design/audit-build-1.md`): 1 weight alert to edit in place and 2 typed ask to the Write layer (first, see Now), then 4 swap panel as a veil, 5 "Add to routine" as a label word, 10 vermilion UNDO in RoutineEditor, 11 drop the double "Skip". Row 3 is done (#134). Done when each row is fixed and recorded.
3. QA's fix: rest persists after a swap. Done when swapping an exercise mid-rest keeps the rest counting after a kill, with a test.
4. Hook up Core's #122 on screen. Done when the routine editor uses `RemoveSlot` in place of DeleteObject, the edit-set view can clear RPE, the week view shows rest days, the exercise library is grouped by movement pattern and then equipment, and the workout shows "Up X kg from last time" when the target rose. This comes right after the mid-rest set removal low (Coordinator, 4:04 PM PT).
5. Cook mode screen (kitchen slices 12 and 12b, moved from Core because its engine is merged). Done when it passes the Kitchen lead's cook-mode acceptance (#127) and `cook-mode-scenarios.md`: live steps, two timers, timers on the Lock Screen, the idle rule, and a Cook entry on finish. Cook is un-hidden on the recipe page. Timer UI follows the UI rows in Research's `../research/fixtures/cook-timer-phrases.md` (#154): the step-verb label, the flared timer, seconds under 2 minutes, "dal, done." on finish. Extend and Pause wait for 12b. Includes a HomeLink word in `HomeSpatialView`, so the screen isn't DEBUG-only.
6. Button sweep (Kaushik, 19:00: no rounded-rectangle, oval or pill buttons anywhere, Apple defaults included). Start once Design's `docs/design/no-buttons.md` lands. Done when every button on Builder A's screens (Workout, Exercise, Plans, Routine, Widgets) uses Design's replacement language and the audit's rows for those files are ticked, with a recording. Put the shared button style in DesignSystem first so Builder B and Core can reuse it. Builder A's rows from `../research/screen-fast-paths.md` are part of it: drop "Keep holding"; show the workout instruction lines only the first few times (the keys are now at `WorkoutModeView.swift:544-575`, so no-buttons.md's line numbers are stale); remove the rounded fills on the week range bar and on lifted or picked rows; and make one path back into a running workout, the lit top seam plus the Live Activity, in place of six. The Exercise page's main action is history and progress, not logging (Product, 19:47).
7. Fixes from Kaushik's phone review on Workout, Exercise and Plans (haptics, dial feel, finish animation). These go ahead of 3 and 4 when they come in.
8. M4 slice 10, widgets and snippets, pulled forward. Snippets first, then the App Group test build, per Design's `widgets-and-snippets.md`.

**Later:**
- M3 body weight page, after Core's M3 slice 1, with a BODY WEIGHT word on the Training page. Design's sheet: `docs/design/body-weight-and-habits.md` with `m3-surfaces.mp4` (1f17bd1 on Design's branch), drawn on Research's `../research/m3-1-2-brief.md` fixtures with exact copy.
- M5 Reading screens (`../product/ship-list-m5-reading.md`) and M5 Money screens 6, 7, 5 (`../product/ship-list-m5-money.md`), each after Core's engine slices land. Includes a HomeLink word in `HomeSpatialView`, so the screen isn't DEBUG-only. (Moved from Builder B, 3:50 PM PT, to spread the screen work.)
- Fixes from Kaushik's phone review on haptics, dial feel and the finish animation (unverifiable in the simulator).

*All v1 slices except 17 (voice) are on master after #91. Voice moved to Builder B's Ask Tess capture surface (Kaushik, 19:18). 14 still needs Core's Prefill fix.*
