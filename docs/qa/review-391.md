# QA review: #391 history dates in the workout's zone (Builder A, ios/history-zone, R34 / T4)

Head `70112f9`. The trial merge onto master `9029637` is clean. The PR changes three files (+26 / -9): two in
Features/Exercise and one test. Builder A ran the app tests: 122 green.

## Verdict: PASS

- **`ExerciseWords.historyDate(_:now:calendar:zone:)`** (ExerciseDigest.swift:190-207)
  - It keys the set with `TesseraDay.day(of:in:)` (#377), so the day is taken where the set was logged.
  - It compares that key with today and yesterday as calendar midnights, and formats the **key**, not the
    instant, in the calendar's zone.
  - `zone: nil` falls back to the old behaviour, so rows written before zones were stamped read as they did.
- **HistoryList** (ExerciseViews.swift:130, 147) passes `OpZones.zone(of: row.workoutID)`.
  - That is the workout's start zone, which #377's test pins as the workout id.
  - The VoiceOver label and the visible text use the same day.
- **Test**: Wed Oct 28 05:00 PDT is 02:00 HST, before 4 AM, so the set belongs to Tue 27.
  - Read on Thu 08:00 PDT it gives "Tue 27" with the zone and "Yesterday" without it. That is R34 exactly.
  - Oct 26 2026 is a Monday, so the weekdays are right.
- **Data safety**: no writes, flags, migrations or ProcessInfo reads.

This closes R34. With #377, all seven F rows in trip-rehearsal.md are covered in code before Oct 26.

## Lows

- **L1.** `OpZones(store:)` is built twice per row, once for the label and once for the spoken text. It's cached
  per revision, so this is cheap, but one instance per list (a `let` in `body`) is tidier.
- **L2.** The test calls `historyDate` with an explicit zone. Nothing pins the `row.workoutID → OpZones` wiring
  in the view. #377's TripZonesTests covers the OpZones half, so this is only a note.
