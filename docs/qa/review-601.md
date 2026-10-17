# QA review: #601 Builder A R2 (release 1 walk row R2)

Head 2ee37fe. Static, medium depth. Merge-tree clean. No body-weight wording touched (receipts for sets and routines only).

- Receipts: typed log is "Bench press 82.5 × 8, logged." or ", logged, best." (CaptureParts.swift:234, `lastSeated?.records.isEmpty == false`); live rest line "New best: 82.5 × 8." with no e1RM (WorkoutParts.swift:226-233); "Set, logged." when no set number. Matches Product 2:29 PM PT (no e1RM in receipts). "best", never "record": OK. The e1RM in WorkoutParts.swift:131 is the live display, not a receipt, unchanged.
- Routines and RoutineEditor now say changes in Tess's band through TessVoice with takeBack; local line + Undo button removed. UNDO reverses every op newest first, then Tess says "<thing>, taken back." / "Legs B, back on the plan." One haptic per moment: the undo cue now comes from BottomChrome's `.decrease` on undo, the page's own `.undo` cue is removed, so one cue.
- Make a routine: UNDO takes both ops and pops the new routine's page if it is on top (`model.path.last == route`).
- RoutineRow: a sideways drag sets `swiped`, so a drop no longer opens the row; reset after 150 ms.
- RoutineEditor scroll content margin 84 keeps rows out of Tess's band.
- Tests updated (ReceiptsTests, AppModelTests); no Catalog, migration or flag change.

Lows: (1) the undo receipt is posted in a follow-up Task after the band clears its line, a small ordering dependence on BottomChrome (BottomChrome.swift:738-742); fine as walked. (2) `swiped` reset uses a timer; a very slow tap right after a swipe inside 150 ms is ignored, harmless.

Verdict: PASS at 2ee37fe.
