# The Nov 1 fall-back night: every piece of time math against it (Product item AR)

For: Core, Builder A, Builder B. Owner: Research lab. Date: Oct 16, 2026 (Pacific).

Traced by hand on origin/master 4996500 (Oct 16, 1:46 pm PDT), after #507 (the 12-hour house time). No Swift
toolchain, so nothing here was run; the UTC column was checked with Python `zoneinfo` (America/Los_Angeles). Sources:
the grep in the task (`Calendar|DateComponents|addingTimeInterval|86400|3600|TimeZone|startOfDay|dateComponents|byAdding`,
268 non-test lines), plus greps for notifications, widgets, habits, quiet hours and Shutdown.

Related fixtures, linked rather than repeated:

- [`trip-week.md`](trip-week.md) TW16 (note at the first 1:30 am) and TW17 (task done at the second 1:30 am): both file
  under Sat Oct 31. This sweep does not repeat them.
- [`dst-travel.md`](dst-travel.md) D01 to D20, traced on 582700b. Its seven fails are all fixed on master now: D04 and
  D14 (`WorkoutSummary.swift:97-107` files by start in the start zone), D05 and D11 (`Tasks.swift:36-52` uses
  `TesseraDay`), D08 (the cache is keyed by zone, `WorkoutSummary.swift:92`), D17 (`RollForward.swift:83-85`), D19
  (`ExerciseDigest.swift:192-201`). Its D12, D13, D15 and D16 still hold and are the base for DS15 to DS17 here.

## The night

- PDT is UTC-7 until Sun Nov 1 at 2:00 am PDT (9:00Z). The clock then reads 1:00 am PST, UTC-8. So 1:00 to 1:59 am
  happens twice: the first pass is 8:00Z to 8:59Z, the second 9:00Z to 9:59Z.
- His day runs 4 am to 4 am (`TesseraDay.swift:9-26`). Sat Oct 31 runs from 4:00 am PDT (11:00Z Oct 31) to 4:00 am
  PST (12:00Z Nov 1): 25 hours. Sun Nov 1 runs 12:00Z Nov 1 to 12:00Z Nov 2: 24 hours.
- The Review week Mon Oct 26 to Sun Nov 1 runs 4:00 am PDT Mon (11:00Z Oct 26) to 4:00 am PST Mon Nov 2 (12:00Z):
  169 hours.
- Foundation's `date(bySettingHour:minute:second:of:)` defaults to `repeatedTimePolicy: .first`, so "1:30 am" on Nov 1
  resolves to the first one (8:30Z). Worth one check on the simulator, as `dst-travel.md` rule 5 says.

Key instants (all Nov 1 unless named):

| Wall time | UTC |
|---|---|
| Sat Oct 31, 4:00 am PDT | Oct 31, 11:00Z |
| Sat Oct 31, 9:00 pm / 10:00 pm / 11:00 pm / 11:30 pm PDT | 4:00Z / 5:00Z / 6:00Z / 6:30Z |
| 12:00 am PDT (midnight) / 12:30 am / 12:50 am PDT | 7:00Z / 7:30Z / 7:50Z |
| 1:15 am / 1:30 am / 1:45 am / 1:58:30 am PDT (first pass) | 8:15Z / 8:30Z / 8:45Z / 8:58:30Z |
| 1:01:30 am / 1:10 am / 1:20 am / 1:30 am PST (second pass) | 9:01:30Z / 9:10Z / 9:20Z / 9:30Z |
| 2:10 am PST | 10:10Z |
| 4:00 am PST | 12:00Z |
| 7:00 am / 9:00 am / 11:00 am / 12:00 pm PST | 15:00Z / 17:00Z / 19:00Z / 20:00Z |
| Sun 9:00 pm / 10:00 pm / 11:00 pm PST | Nov 2, 5:00Z / 6:00Z / 7:00Z |

## The cases

Status: **pass** (master gives the expected result), **wrong** (it does not, and it reaches the screen or stored data),
**risk** (right on this night by accident, or wrong only in code nothing calls yet), **not built**.

| ID | Case | Times (Pacific; UTC) | Expected | Master (file:line) | Status |
|---|---|---|---|---|---|
| DS1 | The 25-hour day | Sat Oct 31 4:00 am PDT (11:00Z) to Sun 4:00 am PST (12:00Z Nov 1) | `interval(of:)` any Sat moment is 25 h; Sun's is 24 h | `TesseraDay.swift:34-43`: end is `byAdding .day` to the midnight key, then `bySettingHour: 4`, so wall edges | pass |
| DS2 | The repeated hour and the last second | 1:30 am PDT (8:30Z), 1:30 am PST (9:30Z), 3:59:59 am PST (11:59:59Z), 4:00 am PST (12:00Z) | Sat Oct 31, Sat, Sat, Sun Nov 1 | `TesseraDay.swift:22-26` reads the wall hour (1, 1, 3, 4) | pass |
| DS3 | Roll-forward at the new day | Runs at 4:00 am PST (12:00Z) on "bins" at 1:30 am PDT (8:30Z) | Bins to Mon Nov 2 1:30 am PST (9:30Z Nov 2), rolls 1 (same as D18) | `RollForward.swift:56-73`: `byAdding .day` keeps 1:30; today read by `TesseraDay` (`:83-85`), so it no longer runs at 3:00 am PST | pass |
| DS4 | "Tomorrow" said Sat at 11:30 pm | Said 11:30 pm PDT (6:30Z Nov 1), no time | Sun Nov 1 9:00 am PST (17:00Z) | `TessGrammar.swift:616-618` takes `TesseraDay.day(1, after:)` = Sun midnight key; 9 am via `bySettingHour` (`:677`) | pass |
| DS5 | "Tomorrow" said inside the second 1 am | Said 1:20 am PST (9:20Z), still his Saturday | Sun Nov 1 9:00 am PST (17:00Z), 7 h 40 min away | Same lines; `day(1, after:)` counts from Sat | pass |
| DS6 | Home's words for that task | Read Sat 11:30 pm PDT; task Sun 9:00 am PST | "tomorrow at nine" | `HomeSpatialView.swift:685-697`: `isSameDay(date, adding(days: 1, to: now))`, wall-time add | pass |
| DS7 | Task due at 1:30 am, made before | "bins sun 1:30am" typed Sat 11:00 pm PDT (6:00Z) | `startsAt` 1:30 am PDT (8:30Z, the first); on Saturday's list | `TessGrammar.swift:742-745` then `:677` (`.first`); `Tasks.swift:36-52` keeps it in today (before 12:00Z) | pass |
| DS8 | "1:30 am" said inside the repeated hour | (a) "bins 1:30am" said 1:45 am PDT (8:45Z); (b) the same said 1:10 am PST (9:10Z); (c) "bins sun 1:30am" said 1:10 am PST (9:10Z) | The 1:30 am still ahead: 1:30 am PST (9:30Z Nov 1), 45 and 20 min away | (a), (b): `TessGrammar.swift:671-677` builds the first 1:30 (8:30Z), sees it `<= now`, adds a day: **Mon Nov 2 1:30 am PST (9:30Z Nov 2)**, 24 h late. (c): `:680-688` adds 7 days: **Sun Nov 8 1:30 am PST** | wrong |
| DS9 | The 1:30 am task on Now | Task at 8:30Z. Now read at 1:15 am PDT (8:15Z), then 1:20 am PST (9:20Z) | Takes Now at 1:15 am PDT ("in 15 min"); by 1:20 am PST it is 50 real minutes past and leaves Now; Home reads it "tonight at half past one" | `NowRanker.swift:118-121, 218-220` compare absolute instants; `HomeSpatialView.swift:685-692` says "tonight". The clock reads "1:30 am" in both passes (`HouseTime.swift:7-12`): wall time, fine | pass |
| DS10 | "Not now" on that task | Tapped 1:20 am PDT (8:20Z) | Mon Nov 2 1:30 am PST (9:30Z Nov 2): same wall time, his next day | `Tasks.swift:131-132`: `max(startsAt, start(of: now))` then `adding(days: 1)` | pass |
| DS11 | Quiet hours, 11 pm to 7 am | Sat 11:00 pm PDT (6:00Z) to Sun 7:00 am PST (15:00Z): 9 real hours, not 8 | Nothing alerts in the window; the window ends at 7:00 am on the wall | No quiet-hours rule and no scheduled notification anywhere (`UNUserNotificationCenter`: 0 hits). The only alert is the rest-end Live Activity alert, which he triggers himself | not built |
| DS12 | The Shutdown band and 10 pm, Sat and Sun | Sat 9:00 pm PDT (4:00Z Nov 1), 10:00 pm PDT (5:00Z); Sun 9:00 pm PST (5:00Z Nov 2), 10:00 pm PST (6:00Z Nov 2) | 9 pm is `.shutdown`, 10 pm is `.late` ("tonight") on both days | `NowRanker.swift:29-40` reads the wall hour; `HomeLines.swift:382-388` | pass |
| DS13 | The Shutdown at 9 pm and the 10 pm close | Same instants as DS12 | A Shutdown that opens at 9 pm wall time and a close at 10 pm wall time, both days | Only the `DayPart` band exists. No Shutdown flow, no close (greps for `shutdown`, `close`, hour 21 or 22 find only `NowRanker.swift:37` and `HomeLines.swift:275, 385, 396`) | not built |
| DS14 | Undo windows across the change | LOG AND FINISH at 1:59:55 am PDT (8:59:55Z), UNDO at 1:00:03 am PST (9:00:03Z); a Home "Done" at 1:55 am PDT undone at 1:05 am PST | The 10 s take-back is still open (8 real seconds); the Home UNDO works on its record | `WorkoutSession.swift:431-434` (10 s, absolute); memory scrub `TessMemory.swift:370-378` (10 s, absolute); preview grace `ActionEngine.swift:120-124` (2 s, absolute); Home UNDO has no clock, only the record (`BottomChrome.swift:728-733`). Collisions are in [`undo-collision.md`](undo-collision.md) | pass |
| DS15 | Live workout 12:50 to 2:10 am: which day | Start 12:50 am PDT (7:50Z), finish 2:10 am PST (10:10Z) | Files under Sat Oct 31 (start day); in Saturday's Review column and set counts | `WorkoutSummary.swift:97-107` buckets `startedAt` by `OpZones.dayKey`; `TrainingLedger.swift:231-236` uses `TesseraDay.week` | pass |
| DS16 | Its rest timer across the change | Set logged 1:58:30 am PDT (8:58:30Z), rest 3:00 | Rest ends 1:01:30 am PST (9:01:30Z): 180 real seconds; relaunch at 1:00 am PST restores 1:30 left (D12, D13) | `WorkoutSession.swift:398, 423, 500` add seconds to `AppClock.now`; `WorkoutSession+Rest.swift:13-22` compares absolute | pass |
| DS17 | Its duration and Now line | Same session | "140 min" on the finish (2 h 20 min real, not 1 h 20 min by wall); Now "Running since 12:50 am"; 20 min idle suspends on real time | `WorkoutSession+Types.swift:68`, `WorkoutFinishView.swift:67`; `NowRanker.swift:114` with `HouseTime`; `WorkoutSession.swift:53-57` | pass |
| DS18 | Its finish day line | Same session | "Saturday, 12:50 am to 2:10 am": the day it files under, the day Home drops it into | `WorkoutFinishView.swift:96-97` takes the weekday of `endedAt` with the wall calendar: **"Sunday, 12:50 am to 2:10 am"**. Any session past midnight does this; Nov 1 is just the first night it shows the two-pass hour too | wrong |
| DS19 | Live Activity end times | Same rest as DS16 | Lock Screen counts 3:00 down and flips to Go at 9:01:30Z; `staleDate` 9:01:30Z; "set aside" 10 real minutes after Go | `RestActivityController.swift:103-111` (absolute end, rounded), `:121-126` (`staleDate`), `:130-140` (ready flip sleeps real seconds); `RestActivityAttributes.swift:36-40`; `RestLiveActivity.swift:80, 247, 376` draw `timerInterval` | pass |
| DS20 | Widget timelines | Any timeline crossing 8:00Z to 10:00Z | Entries by absolute dates; a "today" widget flips at 4:00 am PST (12:00Z), not 3:00 am | No widget: `TesseraWidgetsBundle.swift` holds only `RestLiveActivity`; no `TimelineProvider` anywhere | not built |
| DS21 | A cook running across the change | Cook started 1:40 am PDT (8:40Z), "pasta 20" timer ends 1:00 am PST (9:00Z) | Now's bar drains 20 real minutes; line "Pasta, N min" counts real minutes | `Cooking.swift:177-185` stores `start + minutes*60`; `NowPicker.swift:54-66`; bar `NowPage.swift:283-287` | pass |
| DS22 | The cook's "time this month" | Cook finished 12:30 am PDT (7:30Z), his Sat Oct 31; it is his 4th October cook | "Carbonara, fourth time this month." (October, by his day; `TesseraDay.month(containing:)` says 12:30 am on the 1st is last month) | `Cooking.swift:63-64` uses `calendar.isDate(_, equalTo:, toGranularity: .month)` on wall dates: "first time this month" (November). `finishLine` has no caller on master yet | risk |
| DS23 | A recipe step timer | A step "simmer 20 minutes" started 1:50 am PDT (8:50Z) | Ends 1:10 am PST (9:10Z), 20 real minutes | Engine is right (`Cooking.swift:177-185`), but no step-timer UI: no Features view reads `CookLog.timers`, and `TesseraRuntime.swift:65-66` marks the timer actions in-app only, for later | not built |
| DS24 | Backups: daily copy name and one per day | Backgrounds at 12:30 am PDT (7:30Z), 1:30 am PDT (8:30Z), 1:30 am PST (9:30Z), 4:05 am PST (12:05Z) | First three refresh `Tessera-2026-10-31`; 4:05 am PST writes `Tessera-2026-11-01`. The late tail is 5 real hours (7:00Z to 12:00Z) | `TesseraBackup.swift:127-131` names by `TesseraDay`; refresh only while wall hour < 4 (`:148-152`) | pass |
| DS25 | Backups: "clock behind" across the change | Copy at 1:50 am PDT (8:50Z), next background 1:10 am PST (9:10Z): the wall clock reads earlier | Not "behind": refresh and prune as usual | `TesseraBackup.swift:137` compares absolute `createdAt` | pass |
| DS26 | The Review week | Mon Oct 26 4:00 am PDT (11:00Z) to Mon Nov 2 4:00 am PST (12:00Z): 7 days, 169 h | 7 day keys Mon to Sun; Sunday's bands hold Sun 4:00 am PST to Mon 4:00 am PST; DS15's session sits on Saturday | `TesseraDay.swift:64-72, 87-91`; `ReviewView.swift:49-58, 85-88`; `ReviewWeek.swift:29-65`; `WeekView.swift:35-41` | pass |
| DS27 | The Day log for Saturday | Sat 11:00Z Oct 31 to 12:00Z Nov 1 | Saturday's lines include both 1:30 am passes, in instant order (TW16 then TW17) | `DayStory.swift:563-564`: start plus 30 h (9:00 am PST) snapped back to 4:00 am PST, so 25 h (it covers 23 h and 24 h days too); lines sorted by `createdAt` (`:144`) | pass |
| DS28 | Midnight key plus 12 h as "noon" | Nov 1 key 12:00 am PDT (7:00Z) plus 12 h = 11:00 am PST (19:00Z), not noon | The right day (it is), ideally at noon | `BackupView.swift:400` (`fileDay`), `ReviewPage.swift:73, 77`, `TrainingPage.swift:251` (`tomorrowLine` asks at 11 am Sunday), `PlanWording.swift:121` (weekday word). Each only reads the day, so 11 am is harmless. Prefer `bySettingHour: 12` as `WeekFacts.swift:145-147` does | risk |
| DS29 | A dated lift for Sunday | "bench 80x8 sun" said Mon Nov 2 | The ask's day is Sun Nov 1 at 12:00 pm PST (20:00Z) | `TessGrammar+Dated.swift:27-28` adds 12 h to the midnight key: **11:00 am PST (19:00Z)**. Day right, stored hour one off | wrong |
| DS30 | Streaks and habit days | Any habit checked at 1:30 am PDT and again at 1:30 am PST | One habit day, Saturday | No habits or streaks on master (only `Haptics.swift` mentions habits; streaks are banned words, `TessCapturing.swift:99`). Review counts days by `TesseraDay` (`ReviewPage.swift:12-27`) | not built |
| DS31 | The spend month | November opens at 12:00 am PDT Nov 1 (7:00Z); a call at 12:30 am PDT (7:30Z) | Pacific midnight, per the task: the 12:30 am call counts in November; Settings says "Dec 1" | `ClaudeKey.swift:111-115` uses `calendar.dateInterval(of: .month)` in the phone's zone: midnight, not 4 am. `ClaudeSection.swift:28-30` gives "Dec 1". Note: it is the phone's zone, not Pacific; on a trip it resets at local midnight | pass |
| DS32 | Claude "Not today" | Tapped Sat 11:30 pm PDT (6:30Z) | Paused until 4:00 am PST (12:00Z), 5 h 30 min | `ClaudeTessModel.swift:275-277` stores `TesseraDay.end(of:)` | pass |
| DS33 | HomeLines gaps: "first in N days" and "ago" | Last Push A ended Sat Oct 24 7:00 pm PDT; now Sun Nov 1 6:00 pm PST. A cook paused 1:50 am PDT, read 1:10 am PST | "8 days" (calendar days, the 25 h day is one day); "paused 20 min ago" (real time) | `HomeLines.swift:593-603` counts `dateComponents(.day)` between day keys; `ago` is absolute (`:422-431`); `NowRanker.swift:150-154` same day count for `daysAway` | pass |
| DS34 | Exercise history "Yesterday" | Set Sat Oct 31 6:00 pm PDT (1:00Z Nov 1), read Sun Nov 1 11:30 pm PST (7:30Z Nov 2) | "Yesterday" (D19) | `ExerciseDigest.swift:192-201`: `day.adding(days: -1, to: now)` | pass |
| DS35 | Exercise trend span | First point Sun Oct 25 6:00 pm PDT (1:00Z Oct 26), read Sun Nov 1 6:00 pm PST (2:00Z Nov 2) | "7 days" | `ExerciseDigest.swift:106`: 7 d 1 h / 86400 = 7.04, rounded up: **"8 days"** | wrong |
| DS36 | Tess's "about N days a week" | First of 12 starts Sun Oct 18 6:00 pm PDT, now Sun Nov 1 6:00 pm PST | 2 weeks, "about 6 days a week" | `TessMemory+Turnover.swift:162`: 14 d 1 h / (7 * 86400) = 2.006, rounded up: **3 weeks, "about 4 days a week"** | wrong |
| DS37 | Notes' weekday cutoff | Note Mon Oct 26 11:30 pm PDT (6:30Z Oct 27), read Sun Nov 1 11:00 pm PST (7:00Z Nov 2) | "Mon" (6 of his days back; 5 d 23.5 h on the wall) | `NotesView.swift:272`: 6 d 0.5 h real is not `< 6 * 86400`, so **"26 Oct"** | wrong |
| DS38 | The 7-day re-sign | Signed Fri Oct 23; due Fri Oct 30 | Fri Oct 30, same clock (no DST between) | Nothing in code tracks it. The only 7-day constant is `ProcessTable.swift:12` (`putAway`, idle time): a process set aside Sat Oct 31 9:00 pm PDT is put away at Sat Nov 7 8:00 pm PST, 7 real days, by design (D16) | not built |
| DS39 | 86400 added to mean "next day" | Any | Next day is always `byAdding .day` | No such use: next-day math is `TesseraDay.swift:41, 56, 61`, `RollForward.swift:73`, `Tasks.swift:132`, `TessGrammar.swift:675`. Every `86400` is a duration or window (list below) | pass |
| DS40 | Plan my day across the repeated hour | A plan run at 12:45 am PDT with blocks at 1:30 am PDT and 1:30 am PST | Two blocks, an hour apart | `PlanWording.swift:56-61` turns both into wall minute 1530 (25:30), and `:374-377` turns 25:30 back into the first 1:30 only. Plan my day is a daytime surface, so unlikely | risk |
| DS41 | Home's day lanes | Read Sat 11:30 pm PDT; a task Sun 6:00 pm PST | Tomorrow's lane holds it | `HomeSpatialView.swift:613` asks `schedule(around: day)` with the midnight key, and `AppModel.swift:482` keeps only -14 h to +12 h: Sunday's lane stops at 11:00 am PST (noon on other days), and today's lane at 11:30 pm drops items before 9:30 am. Not DST-only. `HomeDayStrip` has no caller outside tests, so not on screen | risk |
| DS42 | Demo seeding | `-demo` seeded Mon Nov 2 with `-demoTime 18:10` | Seeded sessions at 6:10 pm on their days | `DemoData.swift:150` subtracts `daysAgo * 86400`: sessions before Nov 1 land at 7:10 pm PDT; with `-demoTime 03:30` a session 2 days back lands Sat 4:30 am PDT, his Saturday instead of Friday. Simulator only | risk |

## Counts

| Status | Count | IDs |
|---|---|---|
| pass | 25 | DS1-DS7, DS9, DS10, DS12, DS14-DS17, DS19, DS21, DS24-DS27, DS31-DS34, DS39 |
| wrong | 6 | DS8, DS18, DS29, DS35, DS36, DS37 |
| risk | 5 | DS22, DS28, DS40, DS41, DS42 |
| not built | 6 | DS11, DS13, DS20, DS23, DS30, DS38 |
| **total** | **42** | |

Worst: **DS8**. "Bins 1:30am" said at 1:45 am PDT, or at 1:10 am PST, sets the task a full day late (Mon 1:30 am PST),
and "sun 1:30am" at 1:10 am PST a full week late. It is one hour a year, but the fix is small and the same rule
should take the second pass in general: if the first match of a wall time is past and a later instant with the same
wall time exists today, use it. Next: **DS18**, the finish screen naming Sunday for a Saturday session (every
past-midnight session, every night).

## Every `86400` (and `24 * 3600`) on master

No `24 * 3600`, `3600 * 24` or `86_400` exists. Related constants (`43200`, `24 * 60`, `1440`) are listed after.

| # | File:line | Use | Verdict |
|---|---|---|---|
| 1 | `Features/Demo/DemoData.swift:135` | Plan `startsOn` 45 days back | ok: only a start date, off by one hour at most |
| 2 | `Features/Demo/DemoData.swift:150` | Seeded workout `daysAgo` back | risk, DS42 (simulator only) |
| 3 | `Features/Exercise/ExerciseDigest.swift:106` | Trend span in days, rounded up | wrong, DS35: count `dateComponents(.day)` between `TesseraDay` keys |
| 4 | `Features/Notes/NotesView.swift:272` | Weekday label cutoff, 6 days | wrong, DS37: compare day keys (6 of his days) |
| 5 | `TesseraCore/.../DayLog/DayStory.swift:78` | `notesAfter`: fetch window for late notes | ok: a window with slack |
| 6 | `TesseraCore/.../Export/TesseraBackup.swift:137` | "Clock behind" tolerance, 2 days | ok: absolute by intent |
| 7 | `TesseraCore/.../Processes/ProcessTable.swift:10` | `leavesHome`, 3 days idle | ok: idle is real time by rule (D16) |
| 8 | `TesseraCore/.../Processes/ProcessTable.swift:12` | `putAway`, 7 days idle | ok: same; DS38 |
| 9 | `TesseraCore/.../Tess/TessMemory+Turnover.swift:124` | Six-week evidence window | ok: edge moves one hour |
| 10 | `TesseraCore/.../Tess/TessMemory+Turnover.swift:162` | Weeks of evidence, rounded up | wrong, DS36: count days between keys, then divide by 7 |
| 11 | `TesseraCore/.../Training/PlanSchedule.swift:50` | 90-day "typical" window | ok: edge moves one hour |
| 12 | `TesseraCore/.../Training/TrainingLedger.swift:172` | 90-day trend window | ok: edge moves one hour |
| 13 | `tools/storage-spike/Sources/Bench/Fixture.swift:11` | Benchmark fixture on a UTC epoch | ok: not in the app |

Related: `PlanWording.swift:121` (`+ 43200` for a weekday word) risk, DS28; `Cooking.swift:177` (`minutes <= 24 * 60`,
a cap) ok; `PlanWording.swift:60` (`wall + 24 * 60`, wall minutes) risk, DS40; `RecipeImport.swift:119` (`days * 1440`,
parsing a duration) ok. Fixed-hour adds that are fine: `AppModel.swift:482` (schedule window, but see DS41),
`CaptureParts.swift:185` (+4 h real), `HomeQueue.swift:462` (+5 h after the 4:00 am edge, which always falls after the
2:00 am change, so 9:00 am), `DayStory.swift:74, 77, 564`, `ProcessTable.swift:14`, `WeekFacts.swift:146` (fallback
only).

## Swift Testing cases

Fixed zone everywhere, never `.current`. Helper (Core tests; the app tests need the same in `TesseraTests`):

```swift
private var la: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
    calendar.locale = Locale(identifier: "en_US")
    return calendar
}
private func utc(_ text: String) -> Date { try! Date(text, strategy: .iso8601) }
```

`TesseraCore/Tests/TesseraCoreTests/FallBackNightTests.swift` (`struct FallBackNightTests`):

| Test | Fixture (UTC) | Expect |
|---|---|---|
| `saturdayIsTwentyFiveHours()` DS1 | `2026-10-31T19:00:00Z` | `interval.duration == 25 * 3600`, start `2026-10-31T11:00:00Z`, end `2026-11-01T12:00:00Z` |
| `repeatedHourIsSaturday(instant:expected:)` DS2 | `08:30`, `09:30`, `11:59:59` -> Oct 31; `12:00` -> Nov 1 (all `2026-11-01T...Z`) | `day(of:)` y-m-d |
| `rollForwardAtFourKeepsOneThirty()` DS3 | task `2026-11-01T08:30:00Z`, now `2026-11-01T12:00:00Z` | `startsAt == 2026-11-02T09:30:00Z` |
| `notNowOnFirstOneThirtyIsMondayOneThirty()` DS10 | task `08:30Z`, time `2026-11-01T08:20:00Z` | `2026-11-02T09:30:00Z` |
| `shutdownBandBothNights()` DS12 | `2026-11-01T04:00:00Z`, `2026-11-02T05:00:00Z` | `.shutdown`; `05:00Z` / `06:00Z` give `.late` |
| `pausedWorkoutAgoIsRealTime()` DS33 | paused `2026-11-01T08:50:00Z`, now `09:10Z` | `HomeLines.ago == "20 min ago"` |
| `daysSinceLastRunCountsDays()` DS33 | ended `2026-10-25T02:00:00Z`, before `2026-11-02T02:00:00Z` | `8` |
| `backupNamesBothPassesOctober31()` DS24 | now `08:30Z`, then `09:30Z`, then `12:05Z` | files `Tessera-2026-10-31`, same, `Tessera-2026-11-01` |
| `reviewWeekIs169Hours()` DS26 | `2026-11-01T20:00:00Z` | `week(containing:)` = `2026-10-26T11:00:00Z ..< 2026-11-02T12:00:00Z` |
| `dayLogWindowEndsAtFourPST()` DS27 | day `2026-10-31T19:00:00Z` | end `2026-11-01T12:00:00Z` |
| `spendMonthOpensAtMidnightPDT()` DS31 | call at `2026-11-01T07:30:00Z`, now `2026-11-01T20:00:00Z` | counted in `monthTotal` |
| `pauseUntilTomorrowEndsAtFourPST()` DS32 | now `2026-11-01T06:30:00Z` | `2026-11-01T12:00:00Z` |
| `twoWeeksAcrossTheFallBackNightAreTwo()` DS36 (fails on master) | starts from `2026-10-19T01:00:00Z`, now `2026-11-02T02:00:00Z` | weeks `2` |
| `cookCountUsesHisMonth()` DS22 (fails on master) | 3 cooks in October, 4th at `2026-11-01T07:30:00Z` | "fourth time this month" |

`TesseraCore/Tests/TesseraTessTests/TessGrammarFallBackTests.swift` (`struct TessGrammarFallBackTests`):

| Test | Fixture | Expect |
|---|---|---|
| `tomorrowAtElevenThirtyIsSundayNine()` DS4 | "call mom tomorrow", now `2026-11-01T06:30:00Z` | `2026-11-01T17:00:00Z` |
| `tomorrowInSecondOneAMIsSunday()` DS5 | same, now `2026-11-01T09:20:00Z` | `2026-11-01T17:00:00Z` |
| `sunOneThirtyBeforeIsFirstPass()` DS7 | "bins sun 1:30am", now `2026-11-01T06:00:00Z` | `2026-11-01T08:30:00Z` |
| `oneThirtyInTheRepeatedHourIsTheSecondPass(now:)` DS8 (fails on master) | "bins 1:30am" at `08:45Z` and `09:10Z`; "bins sun 1:30am" at `09:10Z` | `2026-11-01T09:30:00Z` |
| `datedLiftSundayIsNoon()` DS29 (fails on master) | "bench 80x8 sun", now `2026-11-02T20:00:00Z` | ask `day == 2026-11-01T20:00:00Z` |

`TesseraTests/FallBackNightAppTests.swift` (`@MainActor struct FallBackNightAppTests`). Three of these need a calendar
or zone parameter first (`WorkoutFinishView.dayLine`, `NotesCopy.when` and `BackupCopy` read `Calendar.current`):

| Test | Fixture | Expect |
|---|---|---|
| `restEndCrossesFallBack()` DS16, DS19 | rest 180 s from `2026-11-01T08:58:30Z` | `restEndsAt == 2026-11-01T09:01:30Z`; `contentState` end the same with `appNow == realNow` |
| `workoutDurationIsRealTime()` DS17 | start `07:50Z`, finish `10:10Z` | `summary.duration == 8400` ("140 min") |
| `finishLineNamesSaturday()` DS18 (fails on master) | same session | "Saturday, 12:50 am to 2:10 am" |
| `trendSameClockOneWeekIsSevenDays()` DS35 (fails on master) | first `2026-10-26T01:00:00Z`, now `2026-11-02T02:00:00Z` | span "7 days" |
| `historyYesterdayAcrossFallBack()` DS34 | set `2026-11-01T01:00:00Z`, now `2026-11-02T07:30:00Z` | "Yesterday" |
| `notesSixDaysIsWeekday()` DS37 (fails on master) | note `2026-10-27T06:30:00Z`, now `2026-11-02T07:00:00Z` | "Mon" |
| `tomorrowLaneHoldsSundayEvening()` DS41 (fails on master) | task `2026-11-02T02:00:00Z`, now `2026-11-01T06:30:00Z` | in lane `offset == 1` |

## Gaps by owner

**Core (engine, day, scheduler, Tess)**

- DS8 wrong: `TessGrammar.swift:671-677` and `:680-688`. When the first match of a wall time is past, try the same wall
  time with `repeatedTimePolicy: .last` before adding a day or a week.
- DS29 wrong: `TessGrammar+Dated.swift:27-28`. Use `bySettingHour: 12` (as `WeekFacts.swift:145-147`).
- DS36 wrong: `TessMemory+Turnover.swift:162`. Weeks from a day count between `TesseraDay` keys.
- DS22 risk: `Cooking.swift:63-64`. Use `TesseraDay.month(containing:)` before anything calls `finishLine`.
- DS40 risk: `PlanWording.swift:56-61, 374-377`, the repeated hour folds to one minute value.
- DS28 risk (Core part): `PlanWording.swift:121`.
- DS11 not built: quiet hours. When it comes, store the window as wall times and test 9 h (fall) and 7 h (spring).
- DS31 note: the spend month follows the phone's zone, not Pacific. Decide before a trip, not for Nov 1.

**Builder A (workout, Live Activity, widgets)**

- DS18 wrong: `WorkoutFinishView.swift:96`. Name the weekday of `TesseraDay.day(of: startedAt)`.
- DS35 wrong: `ExerciseDigest.swift:106`. Count days between keys.
- DS20 not built: widget timelines. When built, reload at `TesseraDay.end(of:)`, never "midnight" or `+ 86400`.
- DS16, DS17, DS19 pass: keep `restEndsAt`, `staleDate` and duration on absolute dates.

**Builder B (Home, Shutdown, Review)**

- DS37 wrong: `NotesView.swift:272` (Notes copy reads like Home's words). Compare day keys.
- DS41 risk: `HomeSpatialView.swift:613` with `AppModel.swift:482`. Filter the day lanes by `TesseraDay.interval`, not a
  window around midnight, before `HomeDayStrip` goes on screen.
- DS28 risk (Home part): `TrainingPage.swift:251`, `ReviewPage.swift:73, 77`, `BackupView.swift:400`.
- DS42 risk: `DemoData.swift:150`. Seed with `TesseraDay.adding(days:)`.
- DS13 not built: Shutdown at 9 pm and the 10 pm close. When built, read the wall hour as `DayPart` does (DS12), so
  both nights open at 9:00 pm on the clock.
- DS23, DS30 not built: step-timer UI (whoever takes Kitchen's cook screen) and habits; when built, a habit day is
  `TesseraDay.day(of:)` so both 1:30 am passes are one Saturday.
