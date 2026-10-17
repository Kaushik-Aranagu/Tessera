# QA review: #546 0h + 0g, VoiceOver hint and time words (Builder A)

Head reviewed: 8e11619 (branched before #507; merge-tree on master clean). Static review. **PASS**

- 0h: `PaintKeyHint.hint` (Paint.swift:230-234) gives hold keys "Double tap to finish" and tap keys no hint, with the
  default action `complete()` (Paint.swift:318). It never says "hold" (VO19).
- 0g: the Live Activity's Always-On line reads "Ready at 6:12 pm" (RestLiveActivity.swift:243). The finish line's
  weekday comes from the 4 am day at the start (WorkoutFinishView.swift:101-108), so "Friday, 11:40 pm to 12:50 am"
  is right. "done this night" is gone: `doneWhen` (TrainingPage.swift:663-671) says "done early this morning" from
  4 to 7 am and "done tonight" from 9 pm to the 4 am edge. TimeWordsTests covers all three.
- No launch flags, raw argument reads, Catalog or migration changes.

Lows
- **R1** `Shared/HouseClock.time` repeats master's `HouseTime.clock` (TesseraCore Format/HouseTime.swift:7, #507)
  line for line. The widget target doesn't link TesseraCore (project.yml), so the extension's copy is justified.
  WorkoutFinishView.dayLine is in the app and could call `HouseTime.clock`. The output is the same, so nothing breaks
  today. Tidy it when the widget links Core, or add a test that the two agree.
- **R2** "Double tap to finish" is also read on RESET. VO19 asked for one fix, but "finish" on a reset key is odd.
  Design's call.

## Re-review at 84ad7dc (adds 84ad7dc on 8e11619; merge-tree on master clean): **PASS**
- PaintKey now takes a `hint` per call site, the result in words. R2 is closed: no key says "finish" unless it
  finishes. The hints:
  - "Finishes the workout"
  - "Logs the set" (and "and finishes the workout" on the last set)
  - "Finishes the task"
  - "Keeps the plan"
  - "Finishes the shop"
  - "Clears the basket"
  - "Restores this backup"
- NowPage's two "Touch and hold" hints are gone. Every hold PaintKey call site has a hint; tap keys keep "".
- R1 is closed by a test: TimeWordsTests pins HouseClock.time to HouseTime.clock at seven times.
- 0r: `NowPage.plannedSets` reads "targetSets", or 3 when an entry has none, at least 1 each. The test expects
  4+3+5 = 12, which matches how WorkoutSession counts.
