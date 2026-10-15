# QA: tap a stroke to edit, #108 steers, seed clamp, PR #109 (master 940dca2)

*Repo maintainer (QA), 2026-10-15 22:32 UTC. Static read.* **PASS.**

- **Edit by tap.** Tap a logged stroke to edit it, tap the same stroke to leave, tap another to switch. Each stroke is a 74x44 plain Button. The other strokes dim to 30%, and Reduce Motion drops the lift and wet effects.
- **Save, Remove, Cancel.** Save writes EditSet. Remove writes `DeleteObject`, which goes through the op log, and clears `undoable`, `lastSeated` and `bests` for that set. Cancel is a label word.
- **Undo.**
  - The live Tess bar calls `undoLast()` gated on `canUndoLast && !isEditing` (WorkoutModeView.swift:218). It reverts the last edit or removal first, otherwise the last set.
  - Logging a new set clears `lastEdit` (WorkoutSession.swift:342), so Undo never reaches back past a newer set.
  - The other bar's `undoLastSet()` is in the finished branch only, where `canUndo` is false.
- Removing the context-menu undo is fine (Design's edit-set.md). This also closes old W3, since `isEditing` requires the set to still exist.
- **Seed clamp.**
  - `InkStroke`: `abs((i &+ seed) % 8)`.
  - `DabShape`: `abs(seed % 4)`.
  - `PaintDab` tilt: `&*`.
  - No index can go negative or overflow now, and PaintSeedTests covers it.
- **#108 steers.** Bloom 1.3, the completion haptic is medium 0.8, `ValueWashStyle` now uses `tesseraAnimation`, and TessHorizon is deleted with no references left.
- Low: removing a set while its rest is running leaves the rest timer going. That's harmless, though rest from a deleted set reads oddly.

## test.sh on master
Yes, run `scripts/test.sh --app-only` once on the cut you install. #116, #118 and #109 changed app code in parallel and were each tested only on their own branch. A clean git merge doesn't prove the combined app builds and passes. TesseraCore is untouched since #117 tested it, so `--app-only` is enough.
