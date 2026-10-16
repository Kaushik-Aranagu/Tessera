# QA review: #403 Tess's eyes

Head `9c95408` on master dbc2557. Trial merge is clean. Eight files changed: SoulEyes.swift (new), SoulEyesTests.swift (new), SoulRouter, TessSoul, AppModel, BottomChrome, LiveTessCorner, WorkoutModeView; plus the clip 48-tess-eyes-obsidian.mp4 (21.4 s). This is a static review.

## Verdict: PASS

- **The phone can't turn eyes on.** `AppModel.tessHasEyes` is only `LaunchFlags.has("-tessEyes")` (AppModel.swift:98-100). `LaunchFlags.allowed` is false outside `targetEnvironment(simulator)`, whatever the configuration (LaunchFlags.swift:8-14). Nothing else sets `eyes:`: every `TessSoul` and `LiveTessCorner` defaults to `false`, and the only three call sites pass `tessHasEyes` (BottomChrome.swift:224, WorkoutModeView.swift:111, :260). There's no stored setting yet, so nothing is written either.
- Gates:
  - No `tessMode =` outside the router.
  - The one new `Task.sleep` is the router's 1 s glance (`glanceTimer`, SoulRouter `.lineShown`), and it lives in the router.
  - The blink is a pure function of time inside a `TimelineView`, not a timer.
- L6 is in: `.backgrounded` settles to rest. Nothing emits it yet.
- The workout corner gets `eyes` but no `gaze`, so it stays `.ahead`. The live page is glance-free, as §14 says.
- Done fade: eyes fade out over 120 ms as Done starts and back in over 200 ms after (TessSoul `onChange(of: mode)`).
- Reduce Motion: the soul's timeline pauses, while the eyes keep their own 30 fps timeline. The blink plays, the dots sit still, and there's no glance (`still`). The eyes tick at the same rate as the soul (30 fps when slow, else 60). They're `accessibilityHidden` and don't take hits.
- Blink: a 3-8 s gap, a double one time in five, 160 ms. Seeded by time, so a frame always looks the same. `blinkCadenceStaysInRange` covers the cadence.
- The clip (bottom-right corner, Obsidian) shows the dots on the soul through open, Write, the receipt "… today 9:30 pm." with UNDO, and back.

## Lows
- L1: the blink schedule restarts every 600 s (`origin = floor(time / 600) * 600`). A blink in flight across that edge is cut short, at most once every 10 minutes. Gaps stay at least 3 s. Not visible in practice.
- L2: the walk from `origin` takes up to about 200 steps per frame. That's cheap, but caching the last interval would make it O(1).
- L5 (from #402) is deferred to the working PR, as stated.

## Addendum: re-check at `3099412`

Verdict: **PASS**. The diff since 9c95408 is limited to SoulEyes.swift, TessSoul.swift and SoulEyesTests.swift. Trial merge is clean.

- E1 (the lab): `SoulEyes.centre(of:)` scales once. The pair is scaled, then offset in screen points, with the glance scaled to match. There's no second scale.
- The eyes' opacity is multiplied by `look.opacity`. The workout corner uses `workoutLook` when `onWorkoutGround`, so the eyes sit on the workout's base.
- L1 and L2 closed: the schedule is built once over 3600 s and found by binary search, so each frame is O(log n). The last blink ends before `period − 3`, so no blink is cut at the wrap.
- New low: across the hourly wrap, the gap can run past 8 s, up to about 19 s, because the trimmed tail plus the first gap of 3 to 8 s add up. That happens once an hour. Fine as is.
- The phone gate is unchanged: `tessHasEyes` is still LaunchFlags-only.

## Addendum: `c053fc7`

PASS stands. The only change since 3099412 is one commit, which adds docs/recordings/48-tess-eyes-done.mp4 (the lab's E2 clip). No code changed.
