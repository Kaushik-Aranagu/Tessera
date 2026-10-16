# The trip week: Review's bands by the zone each thing happened in (Product item AP, Core board item 0ae)

For: Core. Owner: Research lab. Date: Oct 16, 2026 (Pacific).

Traced by hand on origin/master f4bc55b, nothing run (no Swift toolchain). Builds on `../trip-check.md` row R12 and
gap N1, and on `trip-rehearsal.md` (127). The rule used everywhere below is the ruled one: **a thing belongs to the
day where he was when it happened, by the 4 am boundary in that zone** (`docs/product/decisions.md:433`; T1 to T4).
Times print in the phone's current zone (same decision); only the day a thing files under reads its stored zone.

## The problem in one paragraph

On master, Today, the Day log, WeekFacts and Review's training band already read the stored zone: workouts through
`OpZones.dayKey` (`WorkoutSummary.swift:96-104`), done tasks on Today (`Tasks.swift:42-49`), the Day log by each
record's zone (`DayStory.swift:118-122`), and WeekFacts' `tasksDoneByDay` and `cooksByDay` (`WeekFacts.swift:201-223`).
Review's bands page (`ReviewPage.swift:233`, built by `ReviewWeekData.compute`) does not, for two of its bands: the
task band buckets `doneAt` with a plain `TesseraDay` in the phone's zone (`ReviewWeek.swift:53-59`, the bucket at
`:58`), and the cooking band does the same with `cookedAt` (`ReviewWeek.swift:60-65`, the bucket at `:64`). The
calendar it gets is `WeekReview.mondayFirst`, which is `Calendar.current` (`ReviewPage.swift:110-114`). So anything
done between 4:00 and 6:59 am Eastern reads as the day before once he is home, and anything done in flight between
1:00 and 3:59 am Pacific reads as the next day in New York.

## Zones and the trip

- Pacific: PDT is UTC-7 through Sun Nov 1 at 2:00 am, then PST, UTC-8. Eastern: EDT is UTC-4 through Sun Nov 1 at
  2:00 am (6:00 am UTC), then EST, UTC-5.
- Trip (from `trip-rehearsal.md`): Mon Oct 26 red-eye from LAX, boards 10:30 pm PDT, lands JFK Tue 6:45 am EDT. Back
  Wed Oct 28: leaves JFK 6:00 pm EDT (3:00 pm PDT), lands LAX 9:20 pm PDT (Thu 12:20 am EDT, Thu 4:20 am UTC).
- In flight the phone keeps the zone it took off in until it lands (trip-rehearsal Q1), so the stored `op.zone` on an
  in-flight write is the departure zone.
- The week Review shows is Mon Oct 26 to Sun Nov 1 (Monday first). He is a long-time user: first use is well before
  the week, so every day up to today is "past" in `ReviewWeekData` (`ReviewWeek.swift:49-51`).
- Plan: PPL x2 rolling, 6 a week, rest Sunday. Pull A was planned for Tue and done Wed.

Divergence windows, the only times the two zones disagree about the day: 4:00 to 6:59 am EDT (= 1:00 to 3:59 am PDT),
and in flight 1:00 to 3:59 am PDT (= 4:00 to 6:59 am EDT). Everything else is a control that must not move.

## The events

Zone is the stored `op.zone` of the record that files the thing: the start for a workout, the done for a task, the
finish for a cook (`OpZones.swift:11-12, 77-86`: a start beats a finish beats a create), the create for a note.

| id | Event | Pacific | Eastern | UTC | Stored zone | Belongs to |
|---|---|---|---|---|---|---|
| TW1 | Task "print boarding pass" done (made Sun 8:00 pm PDT) | Mon 26, 2:00 am | Mon 26, 5:00 am | Mon 26, 9:00 am | LA | **Sun 25** (2 am is before 4 am; last week) |
| TW2 | Task "water the plants" done | Mon 26, 7:30 am | Mon 26, 10:30 am | Mon 26, 2:30 pm | LA | Mon 26 |
| TW3 | Workout Push A, 18 sets | Mon 26, 5:30 to 6:32 pm | Mon 26, 8:30 to 9:32 pm | Tue 27, 12:30 to 1:32 am | LA | Mon 26 |
| TW4 | Cook "overnight oats": started at home, finished after landing | start Mon 26, 9:00 pm; finish Tue 27, 3:55 am | start Tue 27, 12:00 am; finish Tue 27, 6:55 am | start Tue 27, 4:00 am; finish Tue 27, 10:55 am | start LA, finish NY (finish wins) | **Tue 27** (finished in New York at 6:55 am) |
| TW5 | Task "expense report" done in flight | Tue 27, 1:20 am | Tue 27, 4:20 am | Tue 27, 8:20 am | LA | **Mon 26** |
| TW6 | Note "slept two hours" in flight | Tue 27, 1:30 am | Tue 27, 4:30 am | Tue 27, 8:30 am | LA | Mon 26 |
| TW7 | Task "call mom" done | Tue 27, 9:05 am | Tue 27, 12:05 pm | Tue 27, 4:05 pm | NY | Tue 27 |
| TW8 | Note "dinner was great" | Tue 27, 5:10 pm | Tue 27, 8:10 pm | Wed 28, 12:10 am | NY | Tue 27 |
| TW9 | Task "send invoice" done at 11:30 pm New York | Tue 27, 8:30 pm | Tue 27, 11:30 pm | Wed 28, 3:30 am | NY | Tue 27 (both zones agree) |
| TW10 | Workout Pull A, hotel gym | Wed 28, 2:40 to 3:30 am | Wed 28, 5:40 to 6:30 am | Wed 28, 9:40 to 10:30 am | NY | Wed 28 |
| TW11 | Task "pack" done | Wed 28, 3:45 am | Wed 28, 6:45 am | Wed 28, 10:45 am | NY | **Wed 28** |
| TW12 | Task "check out" done | Wed 28, 7:50 am | Wed 28, 10:50 am | Wed 28, 2:50 pm | NY | Wed 28 |
| TW13 | Task "unpack" done at 2 am at home | Thu 29, 2:00 am | Thu 29, 5:00 am | Thu 29, 9:00 am | LA | **Wed 28** (2 am is before 4 am) |
| TW14 | Workout Legs A | Thu 29, 5:30 to 6:25 pm | Thu 29, 8:30 to 9:25 pm | Fri 30, 12:30 to 1:25 am | LA | Thu 29 |
| TW15 | Cook "tacos" | Thu 29, 7:00 to 7:40 pm | Thu 29, 10:00 to 10:40 pm | Fri 30, 2:00 to 2:40 am | LA | Thu 29 |
| TW16 | Note "can't sleep", the first 1:30 am | Sun Nov 1, 1:30 am PDT | Sun Nov 1, 3:30 am EST | Sun Nov 1, 8:30 am | LA | Sat 31 |
| TW17 | Task "set the clocks" done, the second 1:30 am | Sun Nov 1, 1:30 am PST | Sun Nov 1, 4:30 am EST | Sun Nov 1, 9:30 am | LA | Sat 31 |
| TW18 | Review opened while away | Tue 27, 4:00 am | Tue 27, 7:00 am | Tue 27, 11:00 am | phone NY | today is Tue 27 |
| TW19 | Review opened while away, after the gym | Wed 28, 4:00 am | Wed 28, 7:00 am | Wed 28, 11:00 am | phone NY | today is Wed 28 |
| TW20 | Review opened in Pacific after returning | Thu 29, 8:00 am | Thu 29, 11:00 am | Thu 29, 3:00 pm | phone LA | today is Thu 29 |
| TW21 | Review opened at home after fall back | Sun Nov 1, 9:00 am PST | Sun Nov 1, 12:00 pm EST | Sun Nov 1, 5:00 pm | phone LA | today is Sun Nov 1 |

TW9 is the requested 11:30 pm New York done: 8:30 pm Pacific is the same Tuesday, so it is a control that must stay
on Tue in both zones (a fix that keys by UTC date would move it to Wed). TW1 and TW13 are the 2 am cases: TW1 also
crosses the week edge, and in New York master pulls it into this week.

## What each surface shows on master, event by event

"OK" means master shows the expected day. Review columns are for the opens where the event is in range; where master
differs, the open is named.

| id | Today | Day log | Review training band | Review task band | Review cooking band | Expected |
|---|---|---|---|---|---|---|
| TW1 | OK: done row on Sun 25's list until 4:00 am PDT (`Tasks.swift:42-49`) | OK: Sun 25 in any zone (`DayStory.swift:118-122, 276-278`) | n/a | **Wrong in New York:** TW18, TW19 count it on Mon 26 (5:00 am EDT, `ReviewWeek.swift:58`). OK at home (TW20, TW21: Sun 25, out of the week) | n/a | Sun 25, never in this week |
| TW2 | OK, Mon | OK, Mon | n/a | OK, Mon, all opens | n/a | Mon 26 |
| TW3 | OK: Home "Push A done", 6:32 pm (`WorkoutSummary.swift:96-104`) | OK, Mon (`DayStory.swift:218-221`) | OK: Mon trained, all opens (`ReviewWeek.swift:33-35` via `WeekView.swift:50`) | n/a | n/a | Mon 26 |
| TW4 | OK: Home shows the cook done on Tue in New York (`HomeLines.swift:549-555`, phone zone is NY then) | Mon 26: "Cooked overnight oats, 415 min" at the start (`DayStory.swift:241-249`); see gap G2 | n/a | n/a | OK in New York (TW18, TW19: Tue). **Wrong at home:** TW20, TW21 put it on Mon (3:55 am PDT, `ReviewWeek.swift:64`) | Tue 27 (band); Day log day is G2 |
| TW5 | OK: not in Tue's done list at 7:00 am EDT (`Tasks.swift:42-49`, R11 fixed) | OK, Mon in any zone | n/a | **Wrong in New York:** TW18, TW19 count it on Tue (4:20 am EDT). OK at home (1:20 am PDT, Mon). This is R12 | n/a | Mon 26 |
| TW6 | n/a (notes are not on Today) | OK, Mon (`DayStory.swift:294-302`) | n/a | n/a | n/a | Mon 26 (Review's Mon lines, `ReviewWeek.swift:67-71`) |
| TW7 | OK, Tue | OK, Tue | n/a | OK, Tue | n/a | Tue 27 |
| TW8 | n/a | OK, Tue | n/a | n/a | n/a | Tue 27 |
| TW9 | OK: on Tue's list until 4:00 am EDT | OK, Tue; prints 8:30 pm when read at home | n/a | OK, Tue in both zones | n/a | Tue 27 |
| TW10 | OK: Home "Pull A done" Wed in NY and Wed 9:30 pm PDT at home (R22 fixed) | OK, Wed | OK: Wed trained in both zones (`WorkoutSummary.swift:99-104`) | n/a | n/a | Wed 28 |
| TW11 | OK: Wed's done list in NY, and at home Wed night | OK, Wed | n/a | OK in New York (TW19: Wed). **Wrong at home:** TW20, TW21 count it on Tue (3:45 am PDT) | n/a | Wed 28 |
| TW12 | OK, Wed | OK, Wed | n/a | OK, Wed | n/a | Wed 28 |
| TW13 | OK: on Wed's list at 2:00 am PDT Thu | OK, Wed | n/a | OK, Wed (TW20, TW21) | n/a | Wed 28 |
| TW14 | OK, Thu | OK, Thu | OK: Thu trained (TW21) | n/a | n/a | Thu 29 |
| TW15 | OK, Thu | OK, Thu | n/a | n/a | OK, Thu (TW21) | Thu 29 |
| TW16 | n/a | OK, Sat 31 (hour 1 before 4 am on the 25 h day, `TesseraDay.swift:22-26`) | n/a | n/a | n/a | Sat 31 |
| TW17 | OK: on Sat's list at the second 1:30 am | OK, Sat 31 | n/a | OK, Sat 31 (TW21) | n/a | Sat 31 |

## Counts table: what Review's bands show at each open

Per day, Mon to Sun; "." is a day still ahead (nil in `ReviewWeekData`). Rows marked **differs** are what 0ae fixes.

| Open | Band | Master on f4bc55b | Expected | |
|---|---|---|---|---|
| TW18 Tue 7:00 am EDT (NY) | Training | Mon trained; Tue today; "1 of 6" | same | OK |
| TW18 | Tasks done | Mon 2 (TW1, TW2), Tue 1 (TW5); total 3 | Mon 2 (TW2, TW5), Tue 0; total 2 | **differs** |
| TW18 | Cooked | Tue 1 (TW4); total 1 | Tue 1; total 1 | OK |
| TW19 Wed 7:00 am EDT (NY) | Training | Mon, Wed trained; Tue open (was due); "2 of 6" | same | OK |
| TW19 | Tasks done | Mon 2, Tue 3 (TW5, TW7, TW9), Wed 1 (TW11); total 6 | Mon 2, Tue 2 (TW7, TW9), Wed 1; total 5 | **differs** |
| TW19 | Cooked | Tue 1; total 1 | Tue 1; total 1 | OK |
| TW20 Thu 8:00 am PDT (home) | Training | Mon, Wed trained; Tue open; Thu today; "2 of 6" | same | OK |
| TW20 | Tasks done | Mon 2 (TW2, TW5), Tue 3 (TW7, TW9, TW11), Wed 2 (TW12, TW13), Thu 0; total 7 | Mon 2, Tue 2, Wed 3 (TW11, TW12, TW13), Thu 0; total 7 | **differs** (same total) |
| TW20 | Cooked | Mon 1 (TW4); total 1 | Tue 1; total 1 | **differs** (same total) |
| TW21 Sun Nov 1 9:00 am PST (home) | Training | Mon, Wed, Thu trained; "3 of 6" | same | OK |
| TW21 | Tasks done | Mon 2, Tue 3, Wed 2, Thu 0, Fri 0, Sat 1 (TW17), Sun 0; total 8 | Mon 2, Tue 2, Wed 3, Thu 0, Fri 0, Sat 1, Sun 0; total 8 | **differs** (same total) |
| TW21 | Cooked | Mon 1, Thu 1; total 2 | Tue 1, Thu 1; total 2 | **differs** (same total) |

What he would see from the wrong counts:

- TW18 in New York: the Tasks done figure reads 3 for 2, Tue's numeral reads 1 on a day he has done nothing yet, and
  VoiceOver reads "Tasks done, 3. Monday 2, Tuesday 1." (expected "Tasks done, 2. Monday 2."; `ReviewWeek.swift:213-220`).
  Mon's numeral is 2 either way but counts the wrong pair (TW1 instead of TW5), so a test must check items, not just
  Mon's number.
- TW19: tapping Tue reads the hero "3 done" (`ReviewWeek.swift:171-173`) over a list with two dones (call mom, send
  invoice), because the day's lines come from the Day log, which is right.
- TW20 and TW21 at home: totals are right, days are wrong. Wed's hero reads "Pull A, 2 done" for "Pull A, 3 done";
  the cooking dab sits on Mon, and VoiceOver says "Cooked, 1. Monday."

Score on master: 21 rows (17 events, 4 opens); Today 14 of 14 relevant OK; Day log 16 of 17 OK on the current rules
(TW4's day is G2); training band OK at all 4 opens; task band wrong at all 4 opens (5 event placements: TW1 and TW5 in New York,
TW11 at home); cooking band wrong at 2 of 4 opens (TW4 at home).

## Fix shape (for Core, about 8 lines)

`OpZones.dayKey(of:for:calendar:)` is public (`OpZones.swift:65-67`); the WeekFacts helpers are internal
(`WeekFacts.swift:201, 213`), so from the app either read `builder.facts(...).days` (`tasksDone`, `cooked.count`) or
key each date by its object:

```swift
let zones = OpZones(store: model.store)
// tasks: keep (id, doneAt) pairs, then
past(day) ? done.count { zones.dayKey(of: $0.at, for: $0.id, calendar: calendar) == day } : nil
// cooks: the same with (cook.id, cookedAt)
```

A nil zone (rows from before v3) falls back to the calendar's zone, so old history reads as today.

## Swift Testing cases for ReviewWeek (paste into `TesseraTests/ReviewTripWeekTests.swift`)

Setup, as `TripZonesTests` does it: `AppModel` on `TesseraSchema.makeContainer(inMemory: true)`; each write through
`model.engine` with `engine.zone = { zone }` and the record's and object's `createdAt` set to the fixture instant; pass
`time:` to `SetTaskDone`, `StartCooking`, `FinishCooking`, `StartRoutine`, `FinishWorkout`. Pin the plan's `createdAt`
to Thu Oct 1, 2026, 9:00 am PDT so first use is before the week (otherwise `past` is false and every count is nil).
Calendars are Gregorian, `firstWeekday = 2`, zone `America/Los_Angeles` or `America/New_York`, never `.current`.
Call `ReviewWeekData.compute(model, now: <open>, calendar: <zone calendar>)`.

```swift
@Suite @MainActor struct ReviewTripWeekTests {
    @Test func inFlightDoneCountsOnMondayInNewYork()               // TW5 at TW18: tasksDone[0] == 2, [1] == 0 (R12)
    @Test func twoAmBoardingPassStaysOnSundayInNewYork()           // TW1 at TW18: not in this week's sum (2, not 3)
    @Test func newYorkWednesdayCountsTwoTwoOne()                   // TW19: [2, 2, 1, nil, nil, nil, nil]
    @Test func lateNightNewYorkDoneStaysTuesdayInBothZones()       // TW9: Tue at TW19 and at TW20
    @Test func hotelPackCountsOnWednesdayAtHome()                  // TW11 at TW20: [2, 2, 3, 0, nil, nil, nil]
    @Test func twoAmUnpackAtHomeBelongsToWednesday()               // TW13 at TW20: Wed, not Thu
    @Test func oatsCookFinishedAfterLandingIsTuesdayInNewYork()    // TW4 at TW18: cooked[1] == 1
    @Test func oatsCookFinishedAfterLandingIsTuesdayAtHome()       // TW4 at TW20: cooked[0] == 0, cooked[1] == 1
    @Test func fallBackNightDoneBelongsToSaturday()                // TW17 at TW21: tasksDone[5] == 1, [6] == 0
    @Test func sundayAfterTheTripCountsTheWholeWeek()              // TW21: tasks [2, 2, 3, 0, 0, 1, 0], cooked Tue and Thu
    @Test func trainingBandUnchangedByTheFix()                     // TW18 to TW21: marks and "1/2/2/3 of 6" as above
    @Test func taskAndCookBandsMatchWeekFactsInEveryZone()         // each open: per-day counts == WeekFacts days
    @Test func rowsWithoutAZoneReadInThePhonesZone()               // TW11 with op.zone nil read at home: Tue (fallback)
}
```

Seven fail on master: `inFlightDoneCountsOnMondayInNewYork`, `twoAmBoardingPassStaysOnSundayInNewYork`,
`newYorkWednesdayCountsTwoTwoOne`, `hotelPackCountsOnWednesdayAtHome`, `oatsCookFinishedAfterLandingIsTuesdayAtHome`,
`sundayAfterTheTripCountsTheWholeWeek` and `taskAndCookBandsMatchWeekFactsInEveryZone`. The other six pass on master
and guard against a fix that over-corrects (a UTC key, or reading the 4 am edge in the wrong zone).

## Gaps outside 0ae

| # | Where | What he sees | Owner, when |
|---|---|---|---|
| G1 | "The week" page (`ReviewView.swift:62-66, 85-90`, opened from the Review link, `HomeSpatialView.swift:351`): counts dones by instant in the phone-zone week interval and marks good days by `tesseraDay.day(of:)` in the phone zone | At TW18 in New York: "3 tasks done" for 2 (TW1 is inside the Mon 4:00 am EDT interval), and "Something done on two days" for one (TW5 makes Tue good). At home the totals are right | Core; it is on trip-check's N1 line, so ride with 0ae if cheap, else next |
| G2 | A cook's day: the Day log files it at its start (`DayStory.swift:241-249`, the `startCooking` record's zone), while WeekFacts and the fixed band file it at its finish (`WeekFacts.swift:201-211`, `OpZones.swift:12`) | TW4: Review's Tue has the cooking dab, but tapping Tue shows no cook line; the line is on Mon, "Cooked overnight oats, 415 min" | Product rules (default: a cook counts on the day it was finished, like a done task, and the Day log line moves there with its start time); then Core |
| G3 | Home's done cook (`HomeLines.swift:549-555`): `isSameDay` in the phone zone | A cook finished in flight between 1:00 and 3:59 am PDT would show on Home as done today after landing in New York (not in this fixture; TW4 finishes after landing) | Core, can wait |
| G4 | Already listed in `trip-check.md`: N2 Plans month heatmap (`PlanSchedule.swift:59-60`, `PlanDigest.swift:204`), N3 "did X yesterday" (`TrainingActions.swift:362-367`), N4 turnover check across zones | Unchanged by this fixture | Core, can wait (as boarded) |

## Unsure

- Whether Tue at TW19 reads as "open" or as the plan's moved day depends on the rolling plan's `wasDue`; the count of
  training marks is what the cases check, not the mark's kind.
- TW4's 415 minutes assumes the Day log line keeps start to finish as its length; if G2 moves the line, the length
  stays the same.
