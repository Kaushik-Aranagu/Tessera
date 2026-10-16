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
