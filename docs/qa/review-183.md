# Review #183 (merged b19fb4a) — Siri "Undo Last Set" hotfix + B1: PASS, GO for install at b19fb4a

Static review only.

## Claims checked
1. **One set, never the workout: holds.** `takeBackLatestSet` (ActionEngine.swift:176) walks history newest first.
   It skips records whose sets are already gone (including its own earlier DeleteObject records), so repeated
   calls take sets 3, then 2, then 1 of a `3x10`.
   - A record that created exactly one object is undone through its own record, so the op log stays exact.
   - A record that created more (LogExercise ×3, or Quick Capture starting the workout) gets a
     `DeleteObject(newest set)` instead, so the workout, the entry and the other sets stay.
   - A finished workout still returns nil.
   - DataSafetyTests pins all of this.
2. **"Set N taken back.": holds.** N is the set's 1-based position among the exercise's live sets before it goes.
3. **The session drops rest, Undo and best for gone sets: holds while the app is alive.**
   `refreshAfterExternalWrite → dropWhatHungOnGoneSets` treats both deleted and missing objects as gone, and calls
   persistRest only when something changed. It runs on `.tesseraSetTakenBack` and on scenePhase `.active`.
   `restEndsAt` and `restNote` are `private(set)` again behind `endRest()`, which closes W8 from review-146.
4. **A fresh resume point after any undo: holds for in-app undo and a live session** (test:
   anUndoneSetLeavesNoRestAfterARelaunch). There's one gap, U1 below.

## Should-fix (not blocking)
- U1 Intents.swift / WorkoutSession init: the intent only posts a notification and never touches the process's
  resume point. If no session is alive when Siri takes the set back (the app was killed, or Siri launched it in
  the background with no scene, so the `.onReceive` isn't attached), the resume point keeps `restEndsAt`. On the
  next open, `WorkoutSession.init` restores a countdown for a set that's gone. `dropWhatHungOnGoneSets` can't catch
  it, because `lastSeated` isn't persisted. The window is the rest length (a few minutes), and Skip clears it.
  Fix (either one):
  - (a) In `WorkoutSession.init`, restore the saved rest only if the newest live set's createdAt is no more than
    a few seconds before the rest start (`endsAt - total`).
  - (b) Have `takeBackLatestSet` clear the rest extras on the workout process's resume point (a store write, not
    an op, like persistRest).

## Lows
- U2: a Siri take-back on a still-pending Tess ghost row deletes one of its sets via a committed op. Discarding the
  ghost later still deletes the rest. Harmless.
- U3: the in-app history Undo after a Siri take-back undoes the DeleteObject and brings the set back. That's
  consistent with "Undo brings it back".

## GO for b19fb4a
It is a superset of d0154a9, with the same install conditions (scripts/test.sh "All green", one TesseraUITests run,
the phone smoke). Add one smoke step: log 3x10 via Tess, say "Undo Last Set" twice, and expect 1 set left, the
workout still open, and no rest countdown.
