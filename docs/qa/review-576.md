# QA review: #576 0ag DST night (Core)

Head reviewed: da006da (one commit on b41695d, before #553). Static review. **FIX FIRST** (one item, from the merge).

Passing
- DS8: `laterPass` (TessDates+FallBack.swift:35-41) finds the repeated wall time. The first pass has gone and the
  second is still ahead, so "1:30am" said at 1:45 am PDT gives the 1:30 am PST. On any other night `last == first`, so
  it returns nil. Both the plain path (TessGrammar.swift:687-691) and the weekday path use it, and the weekday path
  tries it before the +7 days.
- DS29: a dated lift's day is noon on the wall (TessGrammar+Dated.swift:28), not 12 hours on from midnight.
- DS36: memory's weeks count his days from `TesseraDay`, so two weeks across the fall-back night are 2, not 3
  (TessMemory+Turnover.swift:162-166).
- FallBackNightTests and a TessMemoryTests row cover each case. No copy, Catalog or migration change.

FIX FIRST
- **F1** merge-tree on master conflicts in TessGrammar.swift, in the block the new `TessDates.ahead` replaces. It is not
  only textual. #553 (merged) changed that block: a "today" with no time after 23:00 now gets 23:30 when no whole hour is
  left in the day, and then the quiet-hours snap moves it to 7 am. `ahead` copies the old block. For
  `saidDay, !saidTime, next >= 24` it returns `resolved`, which has already passed, because 9 am is not in quiet hours.
  Resolving in favour of #576 undoes #553. "call mom today" at 11:10 pm would no longer say "tomorrow 7 am"
  (TimeWordsTests.tessSaysTheQuietHourMoveWithItsDay).
  Fix: merge master into the branch and keep the 23:30 fallback inside `ahead`:
  `next < 24 ? setHour(next) : setHour(23, 30)` for the `saidDay, !saidTime` case, then keep the
  `outOfQuietHours` step after the call. Run the TimeWordsTests suite on the merged result.

## Re-review at e068e14 (master merged in; merge-tree on current master clean): **PASS**
- F1 fixed. `TessDates.ahead` (TessDates+FallBack.swift:21-26) keeps #553's fallback for a "today" with no time: the next
  whole hour, or 23:30 when none is left. `outOfQuietHours` runs after the call (TessGrammar.swift, same order as
  master), so "call mom today" at 11:10 pm still ends at tomorrow 7 am.
- I traced `ahead` against master's block case by case, and it matches in every case except the DS8 second pass:
  - weekday, no time: next whole hour, or +7 days;
  - weekday with a time: +7 days;
  - "today", no time: next whole hour, or 23:30;
  - everything else: left as resolved.
- The master merge carries only master's own changes (the PR's own diff is the same six files).
- Low **R1**: the doc comment on `ahead` runs past the line width (TessDates+FallBack.swift:6). SwiftLint may flag it.
