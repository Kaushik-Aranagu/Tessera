# The 4 AM day boundary sweep (board item 36)

Tessera's day runs 04:00 to 04:00 (`RollForwardTasks.dayStartHour = 4`). Only the roll-forward knows that. Everything
else cuts the day at midnight, so between 00:00 and 03:59 the app behaves as if it is already tomorrow. #165
(`light-day.md`, gap L2) named four places: `TaskList.today`, `TrainingLedger.week(containing:)`, `finishedWorkouts` and
`DayLoad.load`. This sweep lists every other place on `origin/master` (f933dd1, 15 Oct 17:47 PT) that cuts at midnight.

Method: `git grep` for `startOfDay`, `isDateIn*`, `inSameDayAs`, `.day` arithmetic, `Calendar.current`, `dayStart`
and `today` over `*.swift`, plus `dateInterval(of:)`, `weekOfYear`, `86400` and `.weekday`. 347 hits; tests, doc
comments and copy strings dropped; every remaining hit read by hand. No Swift toolchain, so traced, not run.

Running example used below: Friday 16 Oct 2026. Push A starts 22:50 and ends **Sat 00:40**. Task "Pay rent" is set for
Fri 23:00 (30 min) and is not done. Task "Dentist" is Sat 15:00. A note is written Fri 23:30.

## 1. The helper first: `TesseraDay`

`RollForwardTasks.logicalDay` (`RollForward.swift:71`) has three problems, so the fix is a new helper, not just
`public`:

1. It is internal (the 4:50 PM PT decision made it public; master has not caught up).
2. It returns the **midnight** of the logical date, not 04:00, although its doc comment says "the start (04:00)".
   Fine as a key, wrong as a range edge.
3. It subtracts 4 hours of absolute time, which breaks on DST days. On Sun 1 Nov 2026 (clocks go back at 02:00),
   03:30 PST minus 4 h is 00:30 PDT on 1 Nov, so 03:00 to 03:59 already counts as Sunday and tasks roll an hour
   early. In March 04:00 to 04:59 still counts as the day before.

Proposal, in `TesseraCore/Engine/TesseraDay.swift` (public, `Sendable`), reading the wall clock hour so DST is free:

```swift
public struct TesseraDay: Sendable {
    public static let startHour = 4
    public var calendar: Calendar
    public init(calendar: Calendar = .current)
    /// Key: midnight of the date the moment belongs to (00:00 to 03:59 belongs to the day before).
    public func day(of date: Date) -> Date        // hour < 4 ? startOfDay - 1 day : startOfDay
    public func start(of date: Date) -> Date      // 04:00 on day(of:)
    public func end(of date: Date) -> Date        // 04:00 on day(of:) + 1 (25 h on 1 Nov, 23 h in March)
    public func interval(of date: Date) -> DateInterval
    public func isSameDay(_ a: Date, _ b: Date) -> Bool
    public func today(_ now: Date) -> Date        // day(of: now)
    public func adding(days: Int, to date: Date) -> Date   // same wall time, n logical days later
    public func week(containing date: Date) -> DateInterval // weekOfYear of day(of:), edges at 04:00
}
```

Rules: keys (dictionary buckets, cell dates, "is this cell today") use `day(of:)`; range filters (`doneAt >= start`) use
`start`/`end`. `RollForwardTasks.logicalDay` becomes `TesseraDay(calendar:).day(of:)` so there is one rule. Caches keyed
by day (`derived.daySummaries`, `workoutDays`) keep `Date` keys; only the bucketing function changes. Owner: Core.
With it, every fix below is a one-line swap: `calendar.startOfDay(for: x)` to `day.day(of: x)`,
`calendar.isDate(a, inSameDayAs: b)` to `day.isSameDay(a, b)`, `dateInterval(of: .weekOfYear, for: x)` to
`day.week(containing: x)`.

## 2. Sites that cut at midnight (beyond #165)

Severity: **write** = stores a wrong date; **display** = shows or ranks the wrong day; harmless ones are in section 3.

### Core (TesseraCore, Tess, Notes, Review, Recipes)

| # | File:line | What it computes | What goes wrong at 1 AM | Sev. | Fix |
|---|---|---|---|---|---|
| C1 | `TesseraCore/.../Tasks/RollForward.swift:71-73` | `logicalDay`, the only 04:00 rule | DST: on 1 Nov 03:00-03:59 PST counts as Sunday, so "Pay rent" rolls an hour early; returns midnight, not 04:00 | write | Replace body with `TesseraDay.day(of:)`; make public |
| C2 | `TesseraCore/.../Tasks/Tasks.swift:118-119` | `MoveTask` default "same time tomorrow": `max(current, startOfDay(now)) + 1 day` | "Not now" on Pay rent at 01:00: base becomes Sat 00:00, so the task lands **Sun 00:00**, time lost and a day late. Wanted Sat 23:00 | write | `base = max(current ?? now, day.start(of: now))`, `target = day.adding(days: 1, to: base)` |
| C3 | `TesseraCore/.../TesseraTess/TessGrammar.swift:509-510` | "tomorrow"/"tmrw" = calendar today + 1 | "Dentist tomorrow 3pm" at 01:00 Sat writes **Sun** 15:00. He means Sat (tomorrow after sleeping) | write | `day = day.adding(days: 1, to: day.today(now))` |
| C4 | `TesseraTess/TessGrammar.swift:584-599` | `pastDay`: "today", "yesterday", "last night", weekday, for past logs | "Watered plants today" at 00:40 Sat writes a note dated **Sat 12:00**, 11 hours in the future; "yesterday" gives Fri, which is still today | write | `let today = day.today(now)`; weekday back-count from the logical day's weekday |
| C5 | `TesseraTess/TessModelCapture.swift:55-61` | Model context "today is Saturday 17 October 2026, 01:00" | The on-device model resolves "tomorrow" to Sunday and writes it | write | Add "his day runs to 04:00, so it is still Friday 16 October" when hour < 4 |
| C6 | `TesseraCore/.../Tasks/Tasks.swift:64` | `TaskList.upcoming`: tasks after the end of today | At 01:00 Dentist (Sat 15:00) is "today", not upcoming; Home's upcoming list skips it | display | `end = day.end(of: now)` |
| C7 | `TesseraCore/.../Tasks/NowRanker.swift:151-152` | `daysAway`: whole days since the last hand action | Act at 23:50, open at 00:10: `daysAway = 1`, Now ranks as if he was away a day | display | `dateComponents([.day], from: day.day(of: last.at), to: day.today(now))` |
| C8 | `Tasks/NowRanker.swift:218` | Timed task still going stays on Now | A task 23:30-00:30 vanishes from Now at 00:00 while still running | display | `day.isSameDay(startsAt, now)` |
| C9 | `Tasks/NowRanker.swift:227` | `dueToday` boost | Something due Fri 23:59 loses "due today" at 00:00 | display | `day.isSameDay(due, now)` |
| C10 | `Tasks/NowRanker.swift:236-237` | Scheduled, unstarted workout offered on Now | A workout scheduled Fri 22:00 and not started disappears from Now at midnight | display | `day.isSameDay(scheduled, now)` |
| C11 | `TesseraCore/.../Training/RestDay.swift:46` | `hasWorkoutUnderway`: started today, not finished | Push A started 23:50 and set aside: at 00:30 it no longer counts, so Now can say "rest day" with a workout open (also feeds `week`'s `busyToday`) | display | `day.isSameDay(startedAt, now)` |
| C12 | `TesseraCore/.../Training/PlanSchedule.swift:48` | `month(containing:)` heatmap buckets by `startOfDay` | Push A (ended 00:40) paints the **Sat** cell, Fri stays blank; on the 1st at 00:30 the session lands in the new month | display | Bucket by `day.day(of:)`; month of `day.today(now)` |
| C13 | `TesseraCore/.../Training/TrainingLedger.swift:225-226` | `forEachEntry(inWeekOf:)`, weekly sets per muscle | A Saturday-night session ending Sun 00:20 counts toward the **new** week's sets (week starts Sunday in en_US) | display | `day.week(containing: date)` and test `session.date` against it |
| C14 | `TesseraTess/TessCaptureEngine.swift:112, 194-197` | Reply wording "today"/"tomorrow"; "Noted for Fri" | After C3/C4 are fixed the reply still says "Sun"/"tomorrow" wrongly unless this matches | display | `day.isSameDay`, tomorrow via `day.adding(days: 1, to:)` |
| C15 | `TesseraTess/TessTools.swift:243-252` | "how many X today/this week" via `isDate(equalTo:toGranularity:)` | "Coffees today" at 01:00 counts only since midnight: 0 | display | `.day` case: `day.interval(of: now).contains`; week: `day.week(containing:)` |
| C16 | `Features/Home/ReviewPage.swift:13-14, 19` (Review) | `WeekReview.lastDays` / `trainedDays`: the seven dabs | At 01:00 Fri's session (ended 00:40) fills **Sat's** dab; Fri reads empty; hero says "four good days" with the wrong four | display | `today = day.today(now)`; `day.isSameDay` |
| C17 | `Features/Review/ReviewView.swift:50-51, 81-87` | `ReviewWeek.compute`: window start, workout days, good days | Window starts Sun 00:00 not 04:00; a task done at 00:30 Fri night lights Sat; the window gains a sliver of last week | display | `start = day.start(of: day.adding(days: -6, to: now))`; good days by `day.isSameDay` |
| C18 | `Features/Review/ReviewView.swift:131, 241` | `ReviewCopy.day` ("today") and the dab's "today" label | At 01:00 the Sat dab is labelled today; VoiceOver reads "Saturday, today" | display | `day.isSameDay(date, now)` |
| C19 | `Features/Notes/NotesView.swift:242-245` | Note age: "3 h", "yesterday", weekday | Note from Fri 23:30 reads "yesterday" at 01:00 (should be "1 h") | display | `day.isSameDay`; yesterday via `day.adding(days: -1, to: now)` |
| C20 | `Features/Recipes/RecipePage.swift:375-376` | "cooked today / yesterday / n days ago" | Cooked Fri 21:00, read at 01:00: "yesterday" | display | `dateComponents([.day], from: day.day(of: date), to: day.today(now))` |

### Builder A (Workout, Exercise, Plans, Routine, Widgets, DesignSystem)

| # | File:line | What it computes | What goes wrong at 1 AM | Sev. | Fix |
|---|---|---|---|---|---|
| A1 | `Features/Plans/PlanData.swift:32-35` | Today's open workout for the Plans week | Push A started 23:50 and still running at 00:30 is not "today's"; the week row loses its link to it | display | `day.isSameDay($0, now)` |
| A2 | `Features/Plans/PlanData.swift:75` | `dominantPaint`: routine colour per muscle this week | Sun 00:20 end puts Saturday's session in the new week's paint | display | `day.week(containing: now)` |
| A3 | `Features/Plans/PlanDigest.swift:202-212` | Month cells: `isToday`, `isFuture`, sessions by day | At 01:00 the Sat cell is "today", Fri's session is drawn on Sat | display | `today = day.today(now)`; `byDay` keyed by `day.day(of:)` |
| A4 | `Features/Exercise/ExerciseDigest.swift:192-195` | History dates "Today", "Yesterday" (uses `now - 86400`) | Fri's sets read "Yesterday" at 01:00; the `86400` is also an hour off on DST days | display | `day.isSameDay`; `day.adding(days: -1, to: now)` |

### Builder B (Home, Command, RootView, BottomChrome)

| # | File:line | What it computes | What goes wrong at 1 AM | Sev. | Fix |
|---|---|---|---|---|---|
| B1 | `Features/Home/HomeQueue.swift:383` | Swipe an undated row: next week, 09:00 | At 01:00 Sat it goes to **Sat** +7 09:00, one day later than the same swipe at 23:59 Fri | write | `day.adding(days: 7, to: day.start(of: now))` at 09:00 |
| B2 | `Features/Home/HomeSpatialView.swift:363-365` | `HomeData.lanes`: yesterday, today, tomorrow on the day strip | At 01:00 the today lane is an empty Saturday; Fri's session sits in "yesterday" | display | Lane days from `day.today(now)`; filter with `day.isSameDay` |
| B3 | `Features/Home/HomeSpatialView.swift:438-442` | `SpokenTime.when`: "this evening at six", "tomorrow at…" | At 01:00 Dentist reads "this afternoon at three"; he hears today, but it is tomorrow's afternoon | display | `day.isSameDay`; tomorrow via `day.adding(days: 1, to: now)` |
| B4 | `Features/Home/DayStrip.swift:30` | `DayTimeline.span` cuts an item at midnight | A 23:30-00:30 item is cut at 24:00 on Friday's lane and missing on the next lane | display | End test with `day.isSameDay(end, start)`; hours past 24 allowed up to 28 |

### Callers that inherit #165 (no own edit needed once #165's four use `TesseraDay`)

`App/AppModel.swift:507-519` (`todaysRoutine`, `finishedToday`) and so `NowPage.swift:102-104` and
`TrainingPage.swift:16-20`: at 01:00 after Push A, `finishedToday` is empty, so Home offers **Pull A as today's
training**, one hold from live mode. `MonthPage.swift:16`, `WeekPage.swift:66-146`, `RestDay.swift:25`, `TaskList.rollForward`
(`RollForward.swift:86-89`) and `todayCounts` all read `week` or `TaskList.today`. They are fixed by the #165 change.

## 3. Places that should stay midnight (or are harmless)

| File:line | What | Why it stays |
|---|---|---|
| `TesseraCore/.../Export/TesseraBackup.swift:94` | Backup file name `Tessera-YYYY-MM-DD` | A file name is a calendar label; a 01:00 copy named for Saturday is true and still one per day |
| `Features/Backup/BackupView.swift:277-278` | "the last one today/yesterday" | Must match the file names above |
| `TesseraTess/TessGrammar.swift:512-513, 621-624` | A typed weekday for a future task ("gym mon") | A date he names is a calendar date; at 00:30 Mon "mon" gives Mon either way |
| `TesseraTess/TessGrammar.swift:502-503, 529-576` | "today"/"tonight" with a time | Already lands on the coming morning or evening, which is what he means at 01:00; only "tomorrow" (C3) is wrong |
| `TesseraCore/.../Kitchen/Cooking.swift:64` | "cooked n times this month" | Month edge only; off once a month for 4 hours |
| `App/AppModel.swift:422-426` | `findTonightWorkout`: ±12 h window | A rolling window, not a day cut; works across midnight |
| `Tasks/NowRanker.swift:30-35`, `BottomChrome.swift:93`, `ThemeLayers.swift:24`, `DayStrip.swift:12`, `SpokenTime.partOfDay` | Hour of day (day part, Tess resting, sky, 07-23 strip) | Clock time, not which day |
| `TrainingLedger.swift:166`, `ExerciseDigest.swift:106`, `NotesView.swift:251`, `ProcessTable.swift:10-12` | Rolling 90 days, "n days", 6 days, process timeouts | Durations, not day edges |
| `App/AppClock.swift:25, 48`, `Features/Demo/DemoData.swift` | Demo clock and seed | Debug only |
| `TesseraCore/.../Actions/TrainingActions.swift:282` (`LogExercise`, Shortcuts) | Logs into the workout in progress | No day test at all |

Not on master, so nothing to sweep yet: widgets (`Widgets/` holds only the rest Live Activity, which has no day logic),
the Day log (`day-log.md` is research only), streaks (Review counts days, never streaks), groceries (no day logic; the
Now "Shop" offer's `declined` set is never filled by the app yet). Each must take `TesseraDay` from its first commit.

Copy wart found on the way: `DoneHero` and `DoneTraining` say "trained this night" / "done this night" after 22:00
(`partOfDay` returns "night"). Should read "tonight" or "last night". Builder B and A.

## 4. Fixtures between midnight and 04:00

Running example from the top (Push A 22:50 to Sat 00:40, Pay rent Fri 23:00, Dentist Sat 15:00, note Fri 23:30).
Calendar `en_US`, `America/Los_Angeles`, week starts Sunday. "Day" is the logical day every surface should use.

| # | Moment | Day | What each surface should show or write | Master today |
|---|---|---|---|---|
| X1 | Sat 17 Oct 00:00:00 | Fri 16 | `TaskList.today` still holds Pay rent as on-day (not carried); Now keeps the running 23:30-00:30 item (C8) | Saturday, Pay rent carried, item gone |
| X2 | Sat 00:40 (Push A ends) | Fri 16 | `finishedWorkouts(Fri)` has Push A; Home shows DoneHero, not Pull A; Review Fri dab filled (C16); month cell Fri (C12, A3) | Sat dab, Sat cell, Pull A offered |
| X3 | Sat 01:00 | Fri 16 | "Dentist tomorrow 3pm" writes Sat 15:00 (C3, C5); "not now" on Pay rent writes Sat 23:00 (C2); Dentist is in upcoming (C6) | Sun 15:00; Sun 00:00; Dentist under today |
| X4 | Sat 01:30 | Fri 16 | "watered plants today" writes Fri 12:00; "yesterday" writes Thu 15 12:00 (C4); reply "Noted." (C14) | Sat 12:00 (future); Fri 12:00 |
| X5 | Sat 02:15 | Fri 16 | Note from 23:30 reads "2 h" (C19); recipe cooked 21:00 "today" (C20); Exercise history "Today" (A4); "coffees today" counts from Fri 04:00 (C15) | "yesterday", "yesterday", "Yesterday", 0 |
| X6 | Sat 03:59:59 | Fri 16 | Roll-forward does nothing; Pay rent not carried; day strip today lane is Friday (B2) | Saturday everywhere except roll-forward |
| X7 | Sat 04:00:00 | Sat 17 | Roll-forward moves Pay rent to Sat 23:00, `rolls = 1`; backup on leaving writes `Tessera-2026-10-17` (stays calendar) | Same (the one place that is right) |
| X8 | Sun 18 Oct 00:30, after a session Sat 23:30 to Sun 00:20 | Sat 17 | Weekly sets and paint count it in the week of 11-17 Oct (C13, A2); Plans week is still 11-17 with Sat done | Counted in the new week, Sat empty |
| X9 | Sun 1 Nov 01:30 PDT (first 01:30) | Sat 31 Oct | Every surface Saturday | Sunday (midnight cut); `logicalDay` Sat |
| X10 | Sun 1 Nov 01:30 PST (second 01:30, one hour later) | Sat 31 Oct | Every surface Saturday; a task "not now" at this moment writes Sun 1 Nov at the task's own wall time | Sunday; `logicalDay` Sat |
| X11 | Sun 1 Nov 03:30 PST | Sat 31 Oct | Roll-forward does nothing yet | `logicalDay` says **Sun 1 Nov** (C1), rolls an hour early |
| X12 | Sun 1 Nov 04:00 PST | Sun 1 Nov | Roll-forward runs; `TesseraDay.interval(of: Sat 31 Oct)` is 04:00 PDT to 04:00 PST, 25 h | Rolled already at 03:00 |

Test shape: one Swift Testing table in `TesseraCoreTests/TesseraDayTests.swift` for `day(of:)`, `start`, `end`,
`isSameDay` over X1-X12 with a fixed `America/Los_Angeles` calendar; then one assertion per site above using the same
moments, so each fix lands with its row.

## 5. Counts and order

28 sites beyond #165's four, plus the inheriting callers and 10 rows kept as is.

| Owner | Write | Display | Total |
|---|---|---|---|
| Core | 5 (C1-C5) | 15 (C6-C20) | 20 |
| Builder A | 0 | 4 (A1-A4) | 4 |
| Builder B | 1 (B1) | 3 (B2-B4) | 4 |
| **All** | **6** | **22** | **28** |

C1 is the rule itself, so 27 call sites plus the rule. Harmless or deliberate: 10 rows in section 3.

Worst: **C3, "tomorrow" in `TessGrammar` at 01:00**. He says "dentist tomorrow 3pm" before bed and the task is
silently written a day late, with Tess's reply (C14) saying "Sunday" so it looks intended. Close second: **C2**, "not
now" after midnight moves a task to 00:00 two days on and drops its time.

Order: Core lands `TesseraDay` with X1-X12 tests and switches `logicalDay` and #165's four to it; then the five Core
writes (C1-C5) and B1; then display sites, each a one-line swap.
