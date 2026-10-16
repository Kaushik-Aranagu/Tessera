# QA: live workout, soul in the corner, PR #134 (master 794981a, head 5abd1cb)

*Repo maintainer (QA), 2026-10-15 23:15 UTC. Static read.* **PASS.**

- WorkoutTessBar is gone, with no references left, and the glass card is removed. LiveTessCorner shows the soul (64 pt hit area), her line for 4 s (`task(id: line)`, cancelled on change), and Undo as a label word while `canUndo` is true.
- **Undo wiring is unchanged:**
  - The live corner uses `canUndoLast && !isEditing` and calls `undoLast()`, which reverts the edit or removal before the last set.
  - The finished corner uses `canUndo && finishedAt == nil` and calls `undoLastSet()`, but it's never active there.
- Tap opens LiveAskField, and double tap sets `isWorkoutPresented = false`. That only hides the workout: the process keeps running and Now shows Resume. The swell answers the touch at once, through a simultaneous zero-distance drag.
- LiveAskField is now a writing line (a 0.5 pt rule, the Inter display face, Close as a label word). `InkWordType` is made internal for this.
- Lows:
  - **W4:** the line fades after 4 s. That includes "Last one. Hold to finish." and the record hint, which were persistent before. If he looks away during rest, the only cue is the subline. This is a Design call; noting it.
  - **W5:** `.id(shownLine)` restarts the slide-in each time the text changes. The record hint changes as the dial crosses a best, so the line can re-slide while he dials. Swap `.id` for `.contentTransition(.opacity)` within the same view.
  - **W6:** the finished corner keeps the hint "Type to Tess." and the "Go to Today" action, but `onOpen` and `onHome` are nil there. Drop them when the callbacks are nil.
