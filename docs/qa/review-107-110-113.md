# QA: master 21566b8 (#107, #110) and 43c7ddb (#106 with T2-1)

*Repo maintainer (QA), 2026-10-15 21:45 UTC. Static read.* **PASS on both. Install 43c7ddb (or 21566b8; #106 adds no UI).**

## NAV1: confirmed fixed
- `Features/Home/HomeSpatialView.swift:106-115`: Home links now open with `.fullScreenCover(item: $presented)` and a zoom `navigationTransition`. They are no longer pushed onto RootView's NavigationStack, so each screen's own NavigationStack is the root of a modal, not nested.
- Every cover has a way out: a "Close" ink word overlaid top-trailing that sets `presented = nil`, plus the zoom transition's interactive swipe-down.
- RecipePage's "Recipes" `dismiss()` pops inside RecipesEntry's own stack. At the root, it dismisses the cover. Both are correct.

## #107 / #110 lows (not blockers)
- N1: RootView's BottomChrome moved from `.safeAreaInset(edge: .bottom)` to an overlay aligned bottom-trailing (`App/RootView.swift:33`). Home reserves `dockClearance`, but screens pushed on RootView's stack (workout, exercise, object pages) no longer get a bottom inset. The soul can now sit over the bottom-right of their last row. Check on the phone.
- N2: the "Close" overlay sits at the top trailing edge of each cover with no reserved space. It may overlap a long title or trailing content on Groceries or Review on narrow phones.
- The whole-word PR match (`contains(/\bprs?\b/)`, BottomChrome) is correct: it matches "pr", "prs" and "PR's", and no longer matches "press" or "approach".
- NowPage #110: `LedgerRow.ago` gives "just now", "N min ago" or "N h ago", which is fine. The finish key's meta line uses a 30 s TimelineView, which is fine.

## #106 with T2-1: fixed
- `TessTools.run` (TessTools.swift:55-72) marks the newest op before the tool runs. On a throw, it walks history newest-first back to that mark, discarding pending records and undoing committed ones, then rethrows. The order is right: a CheckListItem is undone before its AddListItem.
- The rollback depends on OpRecord `createdAt` being the real clock time (history sorts by createdAt, then by UUIDv7). That holds for every live path.
- `createList` with `items: []` now returns just the CreateList record (line 176). This was the orphan case.
- `startShop` is back in `all`. logBodyWeight, createRoutine and createPlan stay off, which is accepted (T2-2 note).
- Low: when a createList call's items all have empty text, the list itself is rolled back with "no items to add". This is harmless, since the model can retry.

## Follow-up: #113 (master df110c0), 2026-10-15 21:58 UTC. **PASS.**
- **N1 fixed.** RootView keeps a 56 pt clear `safeAreaInset` at the bottom of its NavigationStack, so every pushed page scrolls clear of the soul. Home's `dockClearance` drops to 48, which with the 56 matches the old 104. The inset doesn't hit-test.
- **N2 fixed.** In the cover, "Close" sits in its own top `safeAreaInset` row, so it no longer overlaps a title.
- **Steers 1-5 read correctly:**
  - One line, Tess's reply or the launch note. Undo stays while there's a capture.
  - The halo box is replaced by a paper shadow.
  - The veil's removal waits 0.12 s and the surface fades in 0.16 s, so the words go before the page returns.
  - The resting soul brightens with a success haptic instead of `.done`.
  - The countdown is a 2 pt track with a DryStroke over the elapsed part. Its width uses `max(..., 0)` and the path guards `width > 1`.
- Low: `brighten()` uses plain `withAnimation`, not `withTesseraAnimation`, so the glow ignores MotionPolicy and Reduce Motion (BottomChrome.swift, `brighten`).
- Note: a drying capture now shows no line beside the soul. Swipe-to-drop lives on its ghost row. This is intended (steer 1).
