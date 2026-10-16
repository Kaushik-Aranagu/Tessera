# QA: Groceries and Backups design pass, PR #124 (master 5258866, head dda6990)

*Repo maintainer (QA), 2026-10-15 22:52 UTC. Static read.* **PASS. Restore stays confirm-gated.**

## Restore path (R1 and R2)
- **Still confirm-gated.** `stageRestore` is called only from `confirmRestore`, which is the hold PaintKey's action inside `restoreSection`. Picking a file still only runs `inspect` and the temp copy. "Keep what's here" still drops the copy.
- **R2 closed.**
  - `pending` is `@State`.
  - It is read once in `.task`, set from `stageRestore`'s returned Info on confirm, and cleared on Cancel, which runs `cancelRestore()`, then `pending = nil`.
  - `body` no longer calls `inspect`.
- The folder is now a tappable value word inside an AttributedString sentence. The local `openURL` action only opens the folder picker, and an accessibility action is provided. It is not a restore path.

## Lows
- **K1:** `EdgeSwipeBack` takes over `interactivePopGestureRecognizer.delegate` and never gives it back. After BackupView pops, ReviewView's stack is left with a dead (weak, nil) delegate. With the system delegate gone, an edge swipe on the root page can start a pop with nothing to pop, which is the known UIKit freeze. Fix: save the original delegate in `viewDidAppear` and restore it in `viewWillDisappear`.
- **K2:** the "‹ Review" back word uses a typed chevron glyph. That's a Design call, so it's only noted here.
- Groceries:
  - Clearing the basket now records `Cleared` and offers Undo for 6 s. The timeout checks the record id, so a newer clear isn't wiped.
  - Undo goes through `engine.undo`, which is fine.
  - If `ClearDoneItems` throws, an older `cleared` can still be showing for its remaining seconds. This is harmless.

## Follow-up: #126 K1 (c86adbb) and #128 E3/E4 (8379c63), 2026-10-15 22:58 UTC. **Both PASS.**
- **K1 closed.**
  - `EdgeSwipeBack` now saves the nav controller's original pop delegate (weak), borrows it in `viewDidAppear`, and hands it back in `viewWillDisappear`, with `deinit` as a backstop. The hand-back only runs if the delegate is still borrowed.
  - `shouldBegin` checks the borrowed controller's stack is deeper than 1.
  - A cancelled interactive pop calls `viewDidAppear` again, so the borrow is re-taken.
  - `deinit` uses `MainActor.assumeIsolated`. That's fine, because UIKit releases view controllers on main.
- **E3 closed.** The leaf-only filter is gone. Groupings (library.pattern.*, library.group.* and the system groupings) are still excluded by `isConcreteExercise`, so an exercise with a variant now shows next to it.
- **E4 closed.** A `sessionsPerWeek` of zero or less now means no rhythm: every day ahead gets the next routine. A test covers it.
- **Tip ab30efa:**
  - The app code since 5258866 is only Features/Backup/EdgeSwipeBack.swift (#126) and two TesseraCore files plus their tests (#128). #127 and #129 are docs. The sets are disjoint, so no textual or semantic overlap.
  - I can't build here (no Swift toolchain in the QA container). A Mac `scripts/test.sh` at the tip still has to confirm it. The full run, not `--app-only`, because TesseraCore changed in #122 and #128.

## Follow-up: #131 (master 012c53a, head a2a424b), 2026-10-15 23:05 UTC. **PASS.**
- **Basket clear.** It now goes through `TessVoice.shared.say("Cleared N from the basket.", undo: record)`, Tess's one reply line. Groceries covers the soul, so `TessNoteLine` mirrors that line in the bottom inset, with Undo through `engine.undo`. The local `Cleared` timer is gone.
- **Aisle handoff.** `AisleHandoff`: removal 260 ms, insertion 340 ms delayed 120 ms. Under Reduce Motion it is a 0.18 s fade. Shop and list share one ZStack slot.
- **Folder link.** It gets a `.selection` haptic on a counter.
- **Low K3:** `TessNoteLine` shows whatever note TessVoice holds whenever the basket is empty, including a note from elsewhere (for example "Done. Dentist." from Home if it's still showing when Groceries opens). Its Undo then undoes that record, under the hint "Puts them back in the basket". Fix: tag the note with its source, or make the hint generic.

## #86 R1-R3 re-check on master: **all fixed.**
- **R1:** `AddRecipeToGroceries` replaces the recipe's share instead of doubling it. GroceryTests:46-50 cover adding twice (800 g, then "1 kg" stays "1 kg"), and R1b's drop-once is in `apply`.
- **R2:** RecipePage's default `cook` performs `StartCooking` when no `onCook` is given (RecipePage.swift:140-149), so Cook from paste starts a cook.
- **R3:** `PasteCopy.nextReading(after: corrections[index], …)` cycles on the marked reading (ingredient → step → ignore). Title, heading and meta return nil, so they are out of the cycle (PasteRecipe.swift:359-367, PasteCycleTests).
