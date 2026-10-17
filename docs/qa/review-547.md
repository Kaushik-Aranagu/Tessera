# QA review: #547 0f, receipts name the thing first (Builder A)

Head reviewed: 34359e1 (merge-tree on master clean). Static review. **PASS**

- The six receipts lead with the thing:
  - "Bench press 82.5 × 8, logged. e1RM 105." (CaptureParts.swift:223-228)
  - "Set 3 logged." (WorkoutParts.swift:244-246)
  - "Sets 2 to 4, 85 kg." (SwapPanel.swift:121-123)
  - "Bench press, added / swapped in / moved to 3 / removed / 4 × 8–12." (Receipts.swift:30-41)
  - "Push A, taken back." on both UNDO lines (RoutineEditor.swift:222, RoutinesPage.swift:274)
  - The routines page's lines.
- The exercise is read before the action runs, so a removed slot still has its name (RoutineEditor.swift:190).
- ReceiptsTests covers each form plus the nil fallback. The haptic count is unchanged: one per moment.
- No "record", no "…". No launch flags, Catalog or migration changes.

Lows
- **R1** RoutineEditor's UNDO names the routine ("Push A, taken back.") even when the change undone was one slot.
  That matches the decision's example, but "Bench press, taken back." would name what came back. Design's call.
- **R2** The accepted top-set line uses `Format.mass` ("85 kg") while the offer above it uses `Format.kilograms`
  ("Drop to 77.5"). Both are right on their own. The pair differs only in the unit word.
