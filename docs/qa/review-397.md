# QA review: #397 live-workout follow-ups (Builder A, ios/live-followups)

Head `96d0617`. The trial merge onto master `9f91f26` is clean. The PR changes six files (+15 / -16) and adds the
clip docs/recordings/45-live-followups.mp4 (5 s). This is a static review plus a 1 fps contact sheet. Builder A
reports the app tests green.

## Verdict: PASS

These are the five lines of sheet 56's addendum (6a79f06), plus QA's N1:
- **Reps ghost:** the "last N" text under the reps is gone (RepsRow.swift:79). Last time is said once, in the
  detail line.
  - The ghost still drives the beat and the VoiceOver value ("7, same as last time", `:96-100`).
  - The same row draws Rope Pushdown, so its ghost goes too.
- **"ready for 82.5" is silent** on Training at rest (TrainingPage.swift:334-338). It's also silent for a
  scheduled workout unless the prefill source is `.target`.
- **"Rest skipped."**: the session note (WorkoutSession.swift:490-492), the Tess check `hasPrefix("Rest skipped")`
  (WorkoutParts.swift:249) and the test (WorkoutSessionTests:267) all agree. No other "Skipped" prefix check is
  left in Features.
- **Detail line colour:** a new best, RPE and the record-hint line all move to `Paint.secondary` with no
  emphasis. That's Design's ruling.
- **N1:** `onGathered` now guards `session.finishedAt != nil` (WorkoutModeView.swift:97), so a take-back during
  the gather no longer sums up or plays done.

**Clip.** It shows Training at rest with no "ready for" line, set 1 with the detail "last time 82.5 × 7" and no
ghost under the reps, "Set 1 logged. 82.5 × 7." with UNDO, the countdown in `now`, and "Rest skipped. Set 2 is
up.".

**Data safety.** Strings and views only: no flags, no ProcessInfo, no engine or catalog change.

## Lows

- **L1.** In TrainingPage.swift:345 the comment says "only when the plan moved the target (progression)".
  `SetPrefill.Source.target` actually means the slot's planned target (Prefill.swift:10-11), and a progression bump
  may not use that source. Today this means the line is nearly always silent, which matches the sheet. Fix the
  comment, or key the line off a real progression signal when one exists.
- **L2, for Design.** At set 1, Tess still says "Same as last time, 82.5 × 7." under the detail line "last time
  82.5 × 7". That is the last place the fact is said twice, and it's Design's call.

## Addendum: re-check at `7937f15`

Verdict: **PASS**. There is one commit on top of 96d0617, and only these four files change: WorkoutParts.swift, WorkoutSession+Prefill.swift, WorkoutSessionTests.swift, and the still docs/recordings/46-set1-quiet-band.png.

- `.lastTime` reasons now return nil (WorkoutSession+Prefill.swift:12-13). `setLine` drops "Last best was …" and "Set N. W × R" and returns "" (WorkoutParts.swift:258-259). Before a set, the band speaks only for a swap, "Rest skipped", "Logged.", a first time, or "From the plan". This closes L2 (Design's repeat).
- Readers: nothing else reads those strings. `WorkoutLines.tess` feeds only the two `LiveTessCorner`s (WorkoutModeView.swift:105, :259), and `LiveTessCorner` shows nothing and no UNDO for an empty line (LiveTessCorner.swift:51, :66). There are no Live Activity, Watch, Day log, UI test or doc readers. The core `Progression` reason "Same as last time" (Progression.swift:61) is a different string and isn't shown here. The test at WorkoutSessionTests.swift:48 now expects nil; the tests at :39, :76, :114 and :118 are unchanged.
- The still shows set 1 with "last time 82.5 × 7" once and the corner silent. A still is fine for an absence.
- L1 (the `.target` comment, now at Features/Home/TrainingPage.swift:345-347) is not in. It stays a low.
- New low: `previousBest` (WorkoutSession+Prefill.swift:42) has no callers now and can go in a later push.

## Addendum: re-check at `ba66718`

Verdict: **PASS**. One commit on top of 7937f15. It only rewrites the comment at Features/Home/TrainingPage.swift:346-347, so L1 is closed. No code changed.
