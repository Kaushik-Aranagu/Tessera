# QA review: #553 0ab quiet-hours default (Core)

Head reviewed: 22d3fd9 (merge-tree on master clean). Static review. **FIX FIRST** (one item).

Passing
- Grammar: a time Tess picks (none said) leaves 23:00 to 07:00 for the next 7 am (`TessDates.outOfQuietHours`,
  TessGrammar.swift:745-751). A said time is kept. "tonight" sets its own time, so it stays tonight. A late "today"
  goes to 23:30 and then to 7 am. My R1, "call mom thu" at 1 am, gives 7 am. TimeWordsTests covers each case.
- MoveTask takes an optional calendar (Tasks.swift:110-118), and "Not now" at 11:20 pm goes to 7 am (decision 2:00).

FIX FIRST
- **F1** MoveTask's quiet-hours move anchors on `now`, not on the target (Tasks.swift:140-144). When the task's own
  time is ahead, "Not now" can pull it earlier or barely move it. At 8 pm Tuesday, a task at 6:30 am Wednesday gets
  target Thursday 6:30. That is in quiet hours, so the code takes the next 7 am after now, which is Wednesday 7 am:
  "Not now" moved it 30 minutes. A task at 11:30 pm Thursday, seen Tuesday, lands on Wednesday 7 am, a day earlier.
  Fix: move the target itself, the way the grammar does (`TessDates.outOfQuietHours(target, calendar:)`, or the same
  logic in Core). Add a test for a future task at 6:30 am.

Low
- **R1** DayBoundaryTests now expects 7 am where it expected the same wall time. That matches the decision; just
  noting the expectation changed.

## Re-review at 2ece632 (two commits on 22d3fd9): **FIX FIRST**
- F1 is half fixed. Times before 7 am now move to 7 am on the target's own day: a 6:30 am Wednesday task "Not now"'d
  Tuesday 8 pm lands Thursday 7 am. That is the case I meant.
- **F2 (new; from the F1 fix)**: for 23:00 and later, the fix adds a day and then sets 7 am (Tasks.swift:142-143),
  which skips a whole day. Research EQ26 (fixtures/evening-quiet.md:108, :171; board 0ab): "Not now" on an untimed
  task at Thu 11:20 pm must land Fri 7:00 am. With this head, base = now (Thu 23:20) gives target Fri 23:20, which
  gives Sat 7 am. The PR's own tests encode the skip:
  - TimeWordsTests: a Tue 11 pm task gives Thursday 7 am, where it should be Wednesday.
  - DayBoundaryTests: Pay rent gives Sunday 7 am, where it should be Saturday.
  Fix: in both bands use 7 am on the target's own calendar day, `calendar.date(bySettingHour: 7, …, of: target)`, and
  drop the +1. Then:
  - EQ26 gives Fri 7 am.
  - The Wed 6:30 task gives Thu 7 am.
  - The Tue 11 pm task gives Wed 7 am.
  - Pay rent (Sat 01:00) gives Sat 7 am, still after now.
  Add EQ26 as Research's test `notNowOnUntimedTaskLateSnapsToSeven`.
- **Merge**: merge-tree on current master now conflicts in TessCaptureEngine.swift. It's comment-only: this PR edits
  `when()`'s doc comment, which #534 split with `privateTaskLine`. Merge master in.
- Design copy, passing: Home says "Stretch, tomorrow 7 am." / "Stretch, next week." (HomeQueue.swift:474-478; one
  line in Builder B's file). The history reads "Stretch, moved to Later" (Tasks.swift:155). `when` is made public
  for HomeQueue; nothing else changed.

## Re-review at da1e6ca (merge of master 9c439c3 plus the F2 fix; merge-tree on current master clean): **PASS**
- F2 fixed: a quiet-hours target snaps to 7 am on its own calendar day, and the +1 day is gone (Tasks.swift:141-145).
  That 7 am is always ahead of now: target = base + 1 day with base ≥ now, so a 23:xx target's 7 am is at least 8 h
  out.
- The tests cover it:
  - EQ26 (`notNowOnUntimedTaskLateSnapsToSeven`, TimeWordsTests.swift:93) lands Fri 7 am.
  - The Tue 11 pm task lands Wed 7 am.
  - Wed 6:30 lands Thu 7 am.
  - A 9 am task stays at 9 am.
  - Pay rent (DayBoundaryTests) lands Sat 7 am.
- The master merge carries only master's own changes (the three-dot diff is the PR's 7 files). The
  TessCaptureEngine comment conflict is resolved, with no markers.
- Design passed the copy at 2ece632. The words are unchanged since.
