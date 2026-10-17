# The Review first-week side line "Wednesday was the fullest day." (rule and fixture)

For: Core (the helper), Builder B (the Review side). Owner: Research lab. Date: Oct 17, 2026 (Pacific).

Docs only. Nothing here was run: there is no Swift toolchain in this container. Read against origin/master 3b4bc1c (fetched Oct 17), with `git show` and `git grep` only. Every value is made up; placeholders are hunter2, tacocat, 4417 and 2100.

Product's ruling (decisions, 8:18 pm Oct 16, sheet 83, call 3): "Wednesday was the fullest day." is accepted as a rules line. Finished things only, ties say nothing, the 4 am house day. Research writes the rule and the fixture. The task adds: no body or money facts. Where the ruling is silent, this page proposes a default and lists it in section 5 for Product.

## 1. The rule in plain words

**What it says.** Of the days of the first week so far, the one day that has more finished things than every other day. One sentence: "{Weekday} was the fullest day." It names a weekday and nothing else. It never names a thing, a routine, an exercise, a weight, a body number, an amount or a note, and it never says how many.

**What counts as a finished thing (proposal P1).** One thing is one of these, and each counts once:

1. A task that is done: `isDone` is true and `doneAt` is set, not deleted, not reopened. It lands on the day it was done, read in the zone it was done in (`WeekFactsBuilder.tasksDoneByDay`, `WeekFacts.swift`, uses `OpZones.dayKey`).
2. A workout that is finished: `endedAt` set, committed, not deleted, with at least one logged working set (the 6:44 pm Oct 16 ruling that "trained" means at least one set). It lands on the day it started, read in the zone it started in, so a workout running past 4 am stays on the day it started (decisions 7:40 pm Oct 16; `ledger.finishedWorkouts(onDay:)`, `WorkoutSummary.swift:87`). Two sessions in one day count as two things.
3. A cook that is finished: `cookedAt` is set (`cooksByDay`, `WeekFacts.swift`). It lands on the day it was cooked, in its own zone.

These do not count, ever: a note (a Private note most of all, and Design's day rule already leaves notes out, `depth-76.md` Q2), a planned or due thing not done, a task that was done and then reopened, a deleted or undone thing, a workout that is still running or never finished, a workout closed with no sets, a cook that was started and not finished, a body weight or any body measure, a money amount or expense. A habit check would count as a finished thing if the habit class existed, but there is no habit class in `SystemCatalog.swift` on master, so nothing is written for it (Q2).

The count is on things, not on days and not on titles. A task titled "hunter2 renewal" or "Pay rent 2100 fri" counts as one task like any other. The line never reads a title.

**The winner.** For each house day of the first week from the first day through the last full day before today, add up the finished things. The fullest day is the day with the highest total, but only when exactly one day has it. If two or more days share the top total, the line is nil: "ties say nothing" (ruling). Ties lower down do not matter, only a tie for first.

**The floor (proposal P2).** The line also needs the winner to have at least 2 things, and at least 2 days with something finished. A week with one thing, or one busy day and all the others empty, says nothing. The ruling does not set a floor. The reason: with a single day that has anything, "fullest" is only a comparison with nothing, and on the evening of the first day it would read "Monday was the fullest day." about one task. This is the same shape as the sibling Day log line, which says nothing under 4 sessions.

**When all days have 0 things.** Nil. A zero is never a fact on a side (`sides-77-lines.md` section 1, `side-line-helpers.md` shared rules E5 and E6). The zero-day copy "Your first week starts today" / "Nothing to count yet." stands (sheet 83 call 4) and is not this line.

**Which week (proposal P3).** The first week means the Review week (Monday to Sunday, house days) that holds first use. On master that is `firstWeek` in `ReviewWeekData.compute` (`Features/Home/ReviewWeek.swift:39`): first use is on or after the shown week's Monday. First use on the page is the earlier of the starter plan's creation and the first workout's start (`ReviewPage.firstUse`, `ReviewPage.swift:226`). The line is for that week only. In week two and after, this line is not shown (the Review sides use their own glance, `depth-76.md` DP1 to DP4). Days before first use have no things (`beforeFirstUse`) and count as empty; they are not compared as ties.

**Which days are compared (proposal P4).** Only days before today's house day. Today is not over, so a line in the past tense about it would be wrong an hour later: "Friday was the fullest day." on Friday morning is untrue by Friday night. So today is left out of the comparison until the 4 am turn. A day ahead is never in it. Because the page can be read on Sunday night, the last day of the first week is only named after the week has turned (and then the week is no longer "so far" and the page reads the next week; see Q4).

**The 4 am house day.** Every thing is filed by `TesseraDay` (`Engine/TesseraDay.swift`): 4:00 am to 4:00 am, read from the wall clock in the thing's own zone. A task done 3:59 am Thursday belongs to Wednesday. A task done 4:00 am Thursday belongs to Thursday. A workout started 11:30 pm Wednesday and finished 12:40 am Thursday belongs to Wednesday (by its start). A workout started 3:50 am Thursday and finished 4:30 am belongs to Wednesday (start 3:50 am is still Wednesday's day).

**The wording.** "{Weekday} was the fullest day." The weekday is the full name, capitalized, in US English ("Wednesday", not "Wed" and not "wednesday"), one stop at the end, no "this week", no "your". It is 5 words and 29 to 33 characters, one sentence ending in a stop, no "?" or "!": it passes the detail slot (at most 14 words and 80 characters, `HomeLines.fitsDetail`). The helper returns a day key (a `Date`) or nil; the caller formats the weekday, like `ReviewWeekData.dayName` does with `.weekday(.wide)` (`ReviewWeek.swift`). Proposal P5: the name is formatted in US English whatever the phone's region, since the app's copy is US English (Q5).

**Edge cases.**

| Case | Rule |
|---|---|
| Tie for first (two days, or three) | Nil. Say nothing, no "Wednesday and Thursday" (ruling). |
| Tie below the top | Ignored. The top day is still named if it is alone. |
| One day with things, the other days 0 | Nil (P2). |
| Every day 0 | Nil. |
| Only 1 thing all week | Nil (P2). |
| Winner has exactly 2 things and every other day has 1 | The line shows (P2 floor met). |
| Day 1 is the first day, first use today | Nil. Only today exists and today is left out (P4). |
| First use midweek (Wed) | Mon and Tue are before first use, empty, and not a tie. Wed and Thu compare normally. |
| Not the first week | Not shown by this rule (P3). |
| Task done 3:59 am vs 4:00 am | 3:59 am files under the day before; 4:00 am under the new day. |
| Done 12:30 am (after midnight, before 4 am) | Belongs to the day before. |
| Workout spans midnight | Filed by its start. |
| Workout spans 4 am | Filed by its start; the finish never moves it. |
| Unfinished, running, undone, deleted | Not counted. |
| Workout with 0 sets | Not counted (P1). |
| Task done in another zone | Filed by the zone it was done in (`OpZones`), as the Review week already does (trip R12). |
| Week of Nov 1 (fall-back) | Wall clock, not elapsed time. Sat Oct 31 is a 25-hour house day (4:00 am PDT to 4:00 am PST). Both 1:30 am passes on Nov 1 (1:30 am PDT, then 1:30 am PST) file under Saturday. The longer day gets no extra weight: only the count of things matters, never hours. |
| Private title, secret word | Not read. Same line. |
| Body weight, money amount, Private note | Not a thing. Same line. |
| Habit | No habit class on master (Q2). |

## 2. The helper this needs (proposal, for Core)

No helper exists on master (section 4). Proposed shape, small and in the neighbors' style:

```swift
@MainActor public struct FullestDay {
    public init(engine: ActionEngine, calendar: Calendar = .current)
    /// The day key of the one fullest day of the first week so far, else nil (tie for first, under 2 things, under
    /// 2 days with something, not the first week, today alone).
    public func day(weekContaining date: Date, firstUse: Date?, now: Date) -> Date?
}
```

Reads: per day the finished sessions (with at least one set), the tasks done and the cooks, each filed by the same functions the Review week uses (`ledger.finishedWorkouts(onDay:)`, `WeekFactsBuilder.tasksDoneByDay()` and `cooksByDay()`). Day math through `TesseraDay`. It returns counts through the comparison only; it never reads a title, a note, a set weight, a body figure or an amount. Builder B formats the weekday. A natural home is an extra on `WeekFacts` (the doc comment on `bestLines` already promises "then the fullest day", but the code does not build it).

## 3. Fixture

"Now" is Saturday Oct 17, 2026, 9:00 am PDT (UTC-7) unless a row says otherwise. The first week is Mon Oct 12 to Sun Oct 18, first use Mon Oct 12, 8:00 am. Past days are Mon to Fri (today, Sat, is left out). Times are Pacific, in the zone each thing happened in.

Shared sets used by the rows (T is a task done, W a finished workout with 4 logged sets, C a finished cook):

- **B** (tasks only): Mon Oct 12 1 T. Tue Oct 13 2 T. Wed Oct 14 3 T. Thu Oct 15 2 T. Fri Oct 16 1 T. Wednesday leads 3 to 2.
- **M** (mixed): Mon 1 T. Tue 1 W and 1 T (2). Wed 1 W, 3 T and 1 C (5). Thu 2 T. Fri 1 T. Wednesday leads 5 to 2.

| ID | Case | Input | Expected | Test name | Owner |
|---|---|---|---|---|---|
| FD1 | The ruling's example, tasks only | B | "Wednesday was the fullest day." | `fullestDayWednesday` | Core |
| FD2 | The example with mixed things | M | "Wednesday was the fullest day." | `fullestDayCountsWorkoutsTasksAndCooks` | Core |
| FD3 | A tie below the top does not matter | B (Tue 2 and Thu 2 tie for second) | "Wednesday was the fullest day." | `fullestDayTieBelowTopIsFine` | Core |
| FD4 | A tie for first says nothing | B plus 1 T Thu Oct 15 11:00 am (Wed 3, Thu 3) | nil | `fullestDayTieForFirstIsNil` | Core |
| FD5 | A three-way tie says nothing | Tue 2 T, Wed 2 T, Thu 2 T, Mon and Fri 0 | nil | `fullestDayThreeWayTieIsNil` | Core |
| FD6 | Every day has exactly one | 1 T each, Mon to Fri | nil | `fullestDayAllEqualIsNil` | Core |
| FD7 | One busy day, every other day 0 | Wed 4 T only | nil (P2, Q3) | `fullestDaySingleDayWithThingsIsNil` | Core |
| FD8 | A single thing all week | 1 T Wed | nil | `fullestDayOneThingIsNil` | Core |
| FD9 | Every day 0 | Nothing finished; a planned routine and 2 open tasks | nil (the "Nothing to count yet." copy stands) | `fullestDayZeroWeekIsNil` | Core |
| FD10 | Winner has 2, every other day 1 | Mon 1 T, Tue 1 T, Wed 2 T, Thu 1 T, Fri 1 T | "Wednesday was the fullest day." | `fullestDayTwoBeatsOnes` | Core |
| FD11 | First use today | Now Mon Oct 12, 6:00 pm; 3 T done today | nil (today is left out, P4) | `fullestDayFirstDayIsNil` | Core |
| FD12 | First use midweek: days before it are empty, not a tie | First use Wed Oct 14, 8:00 am; Wed 3 T, Thu 2 T, Fri 1 T; Mon and Tue before first use | "Wednesday was the fullest day." | `fullestDayBeforeFirstUseIsNotATie` | Core |
| FD13 | Not the first week | First use Mon Oct 5; now Sat Oct 17; B in the Oct 12 week | nil (P3, Q4) | `fullestDayOnlyFirstWeek` | Core |
| FD14 | Today is never named | Now Fri Oct 16, 9:00 pm; B but Fri has 5 T | "Wednesday was the fullest day." (Fri is left out) | `fullestDayTodayIsLeftOut` | Core |
| FD15 | Before 4 am today is still yesterday | Now Sat Oct 17, 2:00 am (house day Fri); B | "Wednesday was the fullest day." (Fri is today, left out) | `fullestDayNowBeforeFourAmUsesYesterday` | Core |
| FD16 | An unfinished workout does not count | B plus Thu 1 W started 6:00 pm never finished (would tie Wed 3, Thu 3) | "Wednesday was the fullest day." | `fullestDayUnfinishedWorkoutDoesNotCount` | Core |
| FD17 | A running workout does not count | B plus Thu 1 W started 6:00 pm, still running, now Fri 9:00 pm | "Wednesday was the fullest day." | `fullestDayRunningWorkoutDoesNotCount` | Core |
| FD18 | A reopened task does not count | B plus Thu 1 T done 11:00 am, then marked not done | "Wednesday was the fullest day." | `fullestDayReopenedTaskDoesNotCount` | Core |
| FD19 | A deleted task or workout does not count | B plus Thu 1 T deleted and Thu 1 W deleted | "Wednesday was the fullest day." | `fullestDayDeletedDoesNotCount` | Core |
| FD20 | A workout with 0 sets does not count | B plus Thu 1 W 6:30 pm to 6:32 pm, 0 sets | "Wednesday was the fullest day." (P1; on master it would tie) | `fullestDayNoSetsDoesNotCount` | Core |
| FD21 | A planned or due thing not done does not count | B plus Thu has a routine planned and 2 tasks due, none done | "Wednesday was the fullest day." | `fullestDayPlannedIsNotFinished` | Core |
| FD22 | A started cook does not count | B plus Thu 1 C started, not finished | "Wednesday was the fullest day." | `fullestDayUnfinishedCookDoesNotCount` | Core |
| FD23 | A finished cook counts | B plus Thu 1 C finished 6:30 pm | nil (Wed 3, Thu 3 tie) | `fullestDayFinishedCookCounts` | Core |
| FD24 | Two sessions in one day are two things | Thu 2 W (7:00 am, 6:30 pm) and 1 T, Wed 1 W and 1 T | "Thursday was the fullest day." | `fullestDayCountsSessionsNotDays` | Core |
| FD25 | A Private note is not a thing | B plus Thu 2 Private note, one reading "rent 2100 fri" | "Wednesday was the fullest day." | `fullestDayNotesDoNotCount` | Core |
| FD26 | Body and money facts change nothing | B plus a body weight of 82.4 kg logged Thu and an expense of 2100 logged Thu | "Wednesday was the fullest day." | `fullestDayNeverReadsBodyOrMoney` | Core |
| FD27 | A private title counts as one thing, unnamed | B with one Wed task titled "hunter2 renewal" and one titled "Pay rent 2100 fri" | "Wednesday was the fullest day." (identical to FD1) | `fullestDayNeverReadsTitles` | Core |
| FD28 | Done 3:59 am files under the day before | B plus 1 T done Fri Oct 16, 3:59 am (that is Thu: Thu 3, Wed 3) | nil | `fullestDayThreeFiftyNineBelongsToPriorDay` | Core |
| FD29 | Done 4:00 am files under the new day | B plus 1 T done Thu Oct 15, 4:00 am (Thu 3, Wed 3) | nil, because 4:00 am is Thu; contrast with 3:59 am Thu, which is Wed (Wed 4) and gives "Wednesday was the fullest day." | `fullestDayFourAmBelongsToNewDay` | Core |
| FD30 | After midnight, before 4 am, belongs to the day before | B plus 1 T done Thu Oct 15, 12:30 am | "Wednesday was the fullest day." (the task is Wed's, Wed 4) | `fullestDayAfterMidnightBelongsToPriorDay` | Core |
| FD31 | A workout across midnight files by its start | B plus 1 W Wed 11:30 pm to Thu 12:40 am | "Wednesday was the fullest day." (Wed 4, Thu 2) | `fullestDayWorkoutAcrossMidnightByStart` | Core |
| FD32 | A workout that starts before 4 am files to the day before | B plus 1 W Thu 3:50 am to 4:30 am, 4 sets | "Wednesday was the fullest day." (Wed 4) | `fullestDayWorkoutStartedBeforeFourAm` | Core |
| FD33 | A workout started 4:00 am files to the new day | B plus 1 W Thu 4:00 am to 4:45 am | nil (Wed 3, Thu 3) | `fullestDayWorkoutStartedAtFourAm` | Core |
| FD34 | Another zone: the stored zone wins | B plus 1 T done Thu Oct 15, 5:30 am EDT (2:30 am PDT), zone America/New_York stored | nil (Thu 3 in New York, tie). Reading the device zone would put it on Wed (Wed 4) and name Wednesday | `fullestDayReadsStoredZone` | Core |
| FD35 | Fall-back week, both 1:30 am passes file to Saturday | First use Mon Oct 26; now Sun Nov 1, 9:00 am PST (UTC-8). Mon 1 T, Tue 2 T, Wed 1 T, Thu 2 T, Fri 2 T; Sat Oct 31: T done 9:00 am, T done 11:00 pm, T done Nov 1 1:30 am PDT (8:30Z), T done Nov 1 1:30 am PST (9:30Z) | "Saturday was the fullest day." (Sat 4; if the repeated hour were misfiled to Sun, Sat 2 would tie) | `fullestDayFallBackBothPassesFileToSaturday` | Core |
| FD36 | Fall-back week, the 4:00 am edge | Same as FD35 but the last task is done Nov 1 4:00 am PST (12:00Z) instead of 1:30 am PST | "Saturday was the fullest day." (that task is Sunday's and Sunday is today, left out; Sat 3, Fri 2, Thu 2) | `fullestDayFallBackFourAmEdge` | Core |
| FD37 | The 25-hour Saturday gets no extra weight | Same week, Fri 3 T and Sat 3 T (one Sat task at 1:30 am PST) | nil (tie) | `fullestDayLongSaturdayIsNotHeavier` | Core |
| FD38 | Week turns on Nov 2 | Now Mon Nov 2, 3:30 am PST (house day Sun Nov 1); week is Oct 26 to Nov 1, first week | The week still reads, Sun left out as today (P4) | `fullestDayNovTwoThreeThirtyIsStillSunday` | Core |
| FD39 | The wording for all seven weekdays | Each of Mon to Sun as the single leader of a first week (Sunday leader read on Mon 9:00 am after the turn is Q4) | "Monday was the fullest day." through "Sunday was the fullest day." | `fullestDayWeekdayWording` | Core |
| FD40 | The copy rules hold | The output of FD1 and FD24 | Passes `HomeLines.fitsDetail`; capitalized full weekday; one stop; no "at"; no em-dash, no ellipsis, no "?" or "!"; no "record" or "PR"; names no title | `fullestDayCopyRules` | Core |
| FD41 | US English whatever the region | FD1 data with the device region set to a non-US locale | "Wednesday was the fullest day." (P5, Q5) | `fullestDayWeekdayIsUSEnglish` | Core |
| FD42 | The Review side shows the line only when non-nil | FD1 data, FD4 data | FD1: the line shows on the first-week Review side; FD4: no line, no blank row | `fullestDayShowsOnlyWhenNonNil` | Builder B |
| FD43 | Not in week two | FD13 data | The Review side shows no such line | `fullestDayAbsentAfterFirstWeek` | Builder B |
| FD44 | VoiceOver reads the sentence as is | FD1 data | The label is "Wednesday was the fullest day." | `fullestDayVoiceOverLabel` | Builder B |
| FD45 | The line and the DAYS glance can disagree | M, with the glance's tasks-only pick | Line "Wednesday was the fullest day." (5 things); glance small fact is "Wednesday, 3 tasks". Only a case where they name different days needs a Product pick (Q1) | `fullestDayLineAndGlanceStayApart` | Builder B |

Notes on the rows:

- FD35 and FD36 are a pair: the same Saturday has 4 things with the 1:30 am PST task and 3 with the 4:00 am PST task, and both name Saturday; only a misfiled repeated hour (FD35) would tie.
- FD28 and FD29 are the 3:59 am and 4:00 am pair; a test can run them together. FD30 to FD33 cover after midnight and before 4 am.
- FD35 to FD38: nothing in them depends on elapsed hours. Only the wall clock decides the day (`TesseraDay.swift` comment: "1 Nov is 25 h long"). `dst-nov-1.md` traces the same night for the other clock math, and `trip-week.md` TW16 and TW17 already file a note and a task done at the two 1:30 am passes under Sat Oct 31.
- FD4 against `depth-76.md` Q4: the older Design pick for the DAYS glance is "a tie goes to the earlier day". The 8:18 pm Oct 16 ruling says ties say nothing for this line. They are two different surfaces; see Q1.

## 4. What passes on master

Read on origin/master 3b4bc1c. Short answer: no row passes, because nothing builds this line.

- `git grep` for "fullest" in `*.swift` finds only comments: `WeekFacts.swift:52` ("then the fullest day") and `ReviewWeek.swift:22`. `bestLines` ranks finished Day log lines by a record flag, a first time and a finished workout, one per day, three in all; it has no per-day total and no fullest-day pick. No string "was the fullest day" exists in code.
- The week data has the inputs per day. `ReviewWeekData` carries `sessions` (finished workouts per day), `tasksDone` and `cooked` (counts per day, nil for a day ahead or before first use) and `days`, Monday first (`ReviewWeek.swift:9-27`). `WeekFacts.Day` carries `trained`, `tasksDone`, `cooked` and `beforeFirstUse`.
- First week exists: `firstWeek` is computed at `ReviewWeek.swift:39` and drives "Your first week" copy (`ReviewPage.swift:31-46`). Note the two first-use sources differ: `ReviewPage.firstUse` (earlier of plan creation and first workout start, `ReviewPage.swift:226`) feeds the page, while `WeekFactsBuilder.firstUse()` (oldest op not by the system) feeds `WeekFacts`. A helper should take first use as an argument rather than pick one.
- Filing is right for the 4 am rules: `TesseraDay` (`Engine/TesseraDay.swift`) reads the wall hour, tasks and cooks file through `OpZones.dayKey` in their own zones (`OpZones.swift:65`), workouts file by start in the start zone (`WorkoutSummary.swift:97-107`). None of it is tested for this line.
- Gap against P1: `finishedWorkouts(onDay:)` counts a workout whenever `endedAt` is set. It does not require a logged set, so a 0-set workout would count on master (FD20). `store.objects(of:)` already drops deleted objects.
- Weekday name: `ReviewWeekData.dayName` uses `.dateTime.weekday(.wide)` in the device locale, not fixed to US English (FD41).
- No habit class in `SystemCatalog.swift`.

| Rows | On master |
|---|---|
| FD1 to FD41 (helper and sentence) | Not built. No helper, no sentence, no test. |
| FD20 | Would fail even with a helper that reuses `finishedWorkouts(onDay:)`: 0-set workouts count. |
| FD41 | Would fail with `dayName` as written (device locale). |
| FD42 to FD45 (page) | Not built. No side declaration or SideHost on master either (`drawn-sides-acceptance.md` section 7), so these wait on Core 0ak. |

Result: 0 of 45 pass. A good first test to write is FD1, FD4 and FD7, because they fix the shape, the tie and the floor.

## 5. Open questions for Product

1. **What counts, and the glance (Q1).** Proposal P1: tasks done, finished workouts with at least one set, and finished cooks, one each. The older DAYS glance picks the fullest day by tasks only, earlier day on a tie (`depth-76.md` Q4). With the new line counting all three and saying nothing on a tie, the line and the glance can name different days, or one can speak while the other is silent. One rule for both, or two? Proposal: the line follows this page, the glance keeps its own, and Design confirms the pair never appears on one screen.
2. **Habits (Q2).** There is no habit class on master. If one lands, should a completed habit check count as a finished thing? Proposal: yes, one each, added then; nothing is written now.
3. **The floor (Q3).** Proposal P2: at least 2 things on the winner and at least 2 days with something. Without it, one task on one day reads "Monday was the fullest day." Keep the floor, or does a single busy day deserve the line?
4. **First week only, today left out (Q4).** Proposals P3 and P4: shown in the first Review week only, and only days before today are compared. On Sunday night the last day waits until 4 am Monday. Confirm, or should the line also exist in later weeks (then it needs its own tie and floor rules)?
5. **US English weekday (Q5).** Proposal P5: the name is formatted in US English whatever the phone's region. Confirm, or follow the phone's language like the day letters do.
6. **Weight of a thing (Q6).** A one-set workout and a task count the same, one each. Is a workout worth more (for example two), or is one each right for a line that says nothing on a tie?
7. **Past tense late in the week.** Because the line is past tense and today is left out, it can feel late on a Friday when Friday looks fullest. Proposal: accept; the glance shows today.

## Rulings

Product ruled at 8:30 pm (decisions 8:30): all seven proposals are yes as written. The line and the DAYS glance each keep their own tie rule, and Design confirms the two never share a screen. Core gaps are boarded: workouts with 0 sets are counted by `finishedWorkouts(onDay:)`, and `dayName` uses the device locale. No row is open.
