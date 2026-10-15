# Release-candidate read: master 5cb92c4 (ship-2 #91), 2026-10-15 19:25 UTC

*Repo maintainer (QA). A static read of #91, on top of the earlier reviews of #80, #84 and #92. Two subagents traced the workout and plan files, and I checked their key claims in the code. iOS build ran gym-flow A and B1-B5 on a fresh install. Gym-flow D, E, H and regression.md were not run.*

## Verdict: GO
Nothing here loses data or crashes on the paths Kaushik will use tonight: launch on a fresh install, the starter plan, starting a routine, hold to log, rest, finishing, Notes, Groceries and Tess capture. A first install has no old store, so migration doesn't come into play. One short iOS hotfix is recommended before the install if it fits; otherwise it can ship the next day.

## Hotfix if it fits (iOS build, a few lines)
- **W1. Undo after a set typed to Tess removes the wrong set.** `WorkoutSession.swift:365-380` `seatCaptured` doesn't reset `undoable`, `lastEdit` or `editNote`.
  - Scenario: hold-log set 1, then type "bench 80x8". After the bar's 4 s Undo has gone, the live Undo deletes set 1 and keeps the typed set.
  - Fix: set `undoable = nil; lastEdit = nil; editNote = nil` in `seatCaptured`. Better still, build an `Undoable` from the capture's record.
- **W2. Editing can leave no key on screen.** `WorkoutSession+Edit.swift:7-9`: `isEditing` is `editingSetID != nil`.
  - Scenario: tap a stroke to edit it, then long-press it and choose "Undo set N" (or swap the exercise, or a Tess capture moves to another exercise). `editingRow` is then nil, so `EditSetKeys` draws nothing: no Hold, no Cancel, no Undo. The only way out is paging.
  - Fix: `isEditing` returns `editingRow != nil`, and call `endEditing()` in `undoLastSet`, `swap`, `seatCaptured` and `finish`.

## Should-fix next (not blocking)
- W3: after a set is undone by long-press, its edit stays armed. The bar's Undo then writes the old weight onto the deleted set and says "Set 3 is back as it was". Clear `lastEdit` and `editNote` in `undoLastSet`.
- PL1: the week view's today label comes from Core's `nextRoutine`, but the tap resumes today's workout (`PlanDigest.swift:96-98`). If he starts Legs A from a Shortcut while the next routine is Push A, the week says Push A and opens Legs A. Use `PlanData.today?.routine` for the today cell.
- L4: the launch note is now persisted. If an open fails once in a "passing" way and Kaushik doesn't open the Ask bar, the next good launch still says "nothing you do this time will be kept". On an `.opened` outcome, show only the migration-pending note.
- L5: on Home, "log bench 80x8" followed by Undo removes the workout Core started, but `model.session` still points at it (and the rest Live Activity may stay up). Clear the session when its workout is deleted.

## Low
- PL2: with no plan, today's started workout drops out of the week (only if the starter plan is missing).
- PL3: the rep steppers in `RoutineEditor.swift:242,245` build ranges that trap if a slot ever has repMax below 1 or repMin above 50. Seeded slots are fine; clamp them.
- PL4: the routine editor's Undo goes back only one step. The routine page has no Start key.

## Checked and fine
- B3: Undo after a multi-set capture takes back every set.
- G1: Home no longer says "ready for 20" on a first session.
- P2: tidy never suspends the workout under the live cover and resumes it if something did.
- One haptic per set.
- The mic is hidden.
- Routine edits don't leak into a running or past workout.
- The editor writes through the op log and the page refreshes after each write.
- `saveEdit` refreshes the session.
- The `WeightDial` rebuild can't write a weight.
- #92 (Prefill raise) merges cleanly and passes.
