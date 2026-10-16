# Review #190 (merged 71c9dac) — Builder A: U1, A1-A4, late-night #12, canStart: PASS (not in tonight's install)

Static review only.

## U1 (review-183): closed
`persistRest` stores `restAfterSet` (lastSeated, else undoable). `savedRest(for:)` returns nil when that set is
deleted or missing. Resume points from before this PR have no key, so they restore as before. The test covers
"taken back while closed".
- Small residual: after a relaunch, `lastSeated` is nil. If he then drags the rest (extendRest → persistRest), the
  re-saved point has no `restAfterSet`, so a Siri take-back after that point is caught only by the live-session
  path. That's a narrow window. Fix if wanted: carry the loaded `afterSet` in the session and write it back.

## A1-A4: TesseraDay on PlanData (today + week), PlanDigest month buckets, ExerciseDigest today/yesterday. OK.
They're consistent with #187's ledger (day = the day it started).

## Late-night #12: closed
- The ready state gets `staleDate = now + 10 min` (wall clock, which is right for ActivityKit; AppClock is only
  for app time).
- Stale and ready show "Push A, set aside" on the Lock Screen, and "Aside" in the island. Resting still goes stale
  at its rest end, which flips the face to Go as before.
- L1 (low): a genuinely long gap (chatting between exercises, a long cardio "set") shows "set aside" after 10 minutes
  while he's still training. The next log refreshes it, so this is acceptable for v1.

## canStart
- `startRoutine` and WeekPage both guard an empty routine. OK.
- C1 (low, should-fix for the no-buttons rule): Now's RestHero (NowPage.swift:389), RoutineHero (NowPage.swift:424)
  and TrainingPage.swift:184 still draw "Start <routine>" for an empty routine, and tapping it now silently does
  nothing. Hide the word with `model.canStart(routine)`, as WeekPage does.
- C2 (low): StartRoutineIntent (Intents.swift:94, Siri/Shortcuts) bypasses canStart and can still start an empty
  routine. A guard in the StartRoutine action itself would cover every caller.
