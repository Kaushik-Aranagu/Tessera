# QA review: #552 0ae Review bands by zone (Core)

Head reviewed: 07fef0f (merge-tree on master clean). Static review. **PASS**

- Review's week (ReviewWeek.swift:52-58) and its good days (ReviewView.swift:88-91) now count done tasks and cooks
  through `WeekFactsBuilder.tasksDoneByDay` / `cooksByDay`. Those use `OpZones.dayKey`, which reads each object in
  its own zone and keys it by a midnight in his calendar. A hotel Wednesday stays Wednesday at home (trip R12). The
  keys line up with `week.map(\.day)` because both are TesseraDay keys in the same calendar.
- G2: a cook files on its finish day, read in the finish's zone (DayStory.swift:242-246). Its line keeps the start
  time and the length.
- Tests: Research's 13 ReviewTripWeekTests, ReviewZonesTests and TripZonesTests. `doneDays[..] ?? 0 > 0` parses as
  `(x ?? 0) > 0`.
- No Catalog or migration change. Nothing new for data safety.
- Low **R1**: ReviewView still builds `doneDates` for the week's total (ReviewView.swift:62, :95), which is not
  zone-read. The count is the same either way. Only the per-day split moved.

## Re-review at 4af772e (two commits on 07fef0f; merge-tree on master clean): **PASS**
- The week page's tasks done is now the sum of `doneDays` over the week's days so far (ReviewView.swift:90-92). It
  agrees with the bands (2 at TW18, theWeekPageCountsLikeTheBands). My R1 is closed: the old interval count is gone.
- An overnight cook row shows its finish time and reads its length in h and min from an hour up ("6 h 55 min",
  "2 h", "45 min"; DayStory.swift:249-254, Product 2:48 PM). The row still files on the finish day in the finish's
  zone.
