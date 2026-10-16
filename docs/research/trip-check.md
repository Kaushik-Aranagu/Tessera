# The Oct 26 trip on master: a re-check of 127 (board item 141)

For: Core, QA, coordinator. Owner: Research lab. Date: Oct 16, 2026 (Pacific).

Master 5601a24 (its Swift code is the same as bb7f082). Traced by hand, nothing was run (no Swift toolchain).
Re-reads all 35 rows of `fixtures/trip-rehearsal.md` (127) after #377 (0bff60b, T1 to T3) and 70112f9 (R34).

## Go / no-go for the trip

1. **Go.** All three "before Oct 26" breaks are fixed: the hotel Pull A stays on Wed at home, Home won't offer a second session Wed at 9:30 pm PDT, and the turnover writes one "Tue:" line.
2. If nothing else lands, three things are still off. In New York (EDT), the Review page counts the in-flight "expense report" on Tue, not Mon. At home, the Plans month grid paints Pull A on Tue. Nothing rings, since notifications are not built.
3. The fix that matters most is the install: a build at or after 0bff60b and 70112f9 must be on his phone by Oct 25 (`trip-checklist.md` merge-base check). In code, the top fix is N1 (Review page counts by each item's zone, about 10 lines).

## The 35 rows

Trip from 127: LA to New York on the Mon 26 red-eye (boards 10:30 pm PDT), back Wed 28 (lands LAX 9:20 pm PDT). ✓ means master gives the expected line; "✓ fixed" marks a former F.

| # | Expected (short) | Master now (file:line) | Verdict |
|---|---|---|---|
| R01 | Mon 6:35 pm PDT, Home: "Push A done", 6:32 pm | `TrainingPage.swift:31, 197`; `WorkoutSummary.swift:99-104`; context is now the clock alone, "6:32 pm" (#369, by design) | ✓ |
| R02 | Day log Mon, PDT times | `DayStory.swift:118-122, 221` | ✓ |
| R03 | WeekFacts: Mon trained, Tue Pull A | `WeekFacts.swift:80-126`; `WeekView.swift:50` | ✓ |
| R04 | In flight, zone stored as LA | `ActionEngine.swift:38, 67` (unchanged) | ✓ |
| R05 | Backup refreshed at 1:35 am PDT | `TesseraBackup.swift:125, 148-150` (unchanged) | ✓ |
| R06 | Roll-forward once at 6:55 am EDT, nothing carried | `RollForward.swift:52-56` (unchanged) | ✓ |
| R07 | Turnover writes the "Mon:" line | Now on master: `TessMemory+Turnover.swift:23-37`; in-flight items stay Mon via `DayStory.swift:118-122` | ✓ |
| R08 | Day log Mon read in EDT holds S4 | `DayStory.swift:167, 242` | ✓ |
| R09 | Day log Tue empty at 6:55 am EDT | same | ✓ |
| R10 | Home 7:00 am EDT: Pull A today, "call mom" 12 pm | `AppModel.swift:595-604`; `HomeLines.swift:320-321` | ✓ |
| R11 | Tasks today leaves out "expense report" | `Tasks.swift:43-48` (LA day of the done is Mon) | ✓ fixed |
| R12 | Tue 7:00 am EDT: tasks done Mon 1, Tue 0 | `WeekFacts.swift:213-222` right; the Review page counts its own in EDT, `ReviewWeek.swift:58`, `ReviewView.swift:62-66, 89`: Tue 1, Mon 0 | still wrong |
| R13 | Plan my day window 7:00 am to 9:00 pm EDT | `DayPlan.swift:208-217`; `DayPlan+Store.swift:60-80` | ✓ |
| R14 | "call mom" rings 12:00 pm EDT; invoice silent | No notification code anywhere | untested |
| R15 | Day log Tue: call mom, dinner note | `DayStory.swift:242, 301` | ✓ |
| R16 | Invoice carried at 5:35 am EDT, `rolls` 1 | `RollForward.swift:61-75` | ✓ |
| R17 | Turnover writes "Tue:" | `TessMemory+Turnover.swift:29-37` | ✓ |
| R18 | Home running: "Row, set 2", "now" | `TrainingPage.swift:21-23`; `HomeLines.swift:337-338` | ✓ |
| R19 | Home 6:35 am EDT: "Pull A done", 6:30 am | `WorkoutSummary.swift:104` | ✓ |
| R20 | Mon, Wed trained; Tue past, due | `WeekView.swift:50, 87-93` | ✓ |
| R21 | Plan my day: no workout block | `DayPlan+Store.swift:64` | ✓ |
| R22 | Wed 9:30 pm PDT, Home: "Pull A done", 3:30 am | `WorkoutSummary.swift:99-104` + `OpZones.swift:65-67, 91-99`: NY day is Wed | ✓ fixed |
| R23 | Day log Wed: "02:40 Pull A" | `DayStory.swift:221` | ✓ |
| R24 | WeekFacts: Mon, Wed trained; Wed today, done | `WeekView.swift:50` over the zoned buckets | ✓ fixed |
| R25 | 27 h Wed: no second "Tue:" line | In-process guard by y-m-d, `TessMemory+Turnover.swift:25-27`. After a relaunch the check at `:32` still misses, but rule "recent.2026-10-27" (`:34`) finds the line and `TessMemory.swift:656` rewrites it in place, same words | ✓ fixed |
| R26 | Invoice is today at 9:30 pm PDT, nothing moves | `RollForward.swift:94-104` | ✓ |
| R27 | Plan my day closed after 9:00 pm PDT | `DayPlan.swift:217-221` | ✓ |
| R28 | Backup Oct 28 not replaced | `TesseraBackup.swift:131-150` | ✓ |
| R29 | Thu 6:30 am PDT: invoice to Thu 10:00 pm, `rolls` 2 | `RollForward.swift:61-75` | ✓ |
| R30 | Turnover writes "Wed: Pull A done, done check out." | `TessMemory+Turnover.swift:29-37`; Pull A on Wed via zone | ✓ |
| R31 | Plan my day: Legs A from 5:00 pm PDT | `DayPlan.swift:208-217` | ✓ |
| R32 | Thu 8:00 am PDT, Review: Mon, Wed trained; tasks 1, 1, 1 | `WeekFacts.swift:213-222`; the Review page's PDT count lands right too (every done there is in its own day in PDT) | ✓ fixed |
| R33 | Day log Mon read at home | `DayStory.swift:118-122` | ✓ |
| R34 | Row's Pull A set reads "Yesterday" | `ExerciseDigest.swift:192-199`, `ExerciseViews.swift:131, 148` (70112f9) | ✓ fixed |
| R35 | Export and restore carry the zone | `TesseraExport.swift:140, 253` (unchanged) | ✓ |

**Counts: 33 ✓ (6 of them fixed: R11, R22, R24, R25, R32, R34), 1 still wrong (R12), 1 untested (R14), 0 regressed.**

## Gaps T4 to T7

| Gap | Status on master |
|---|---|
| T4 history "Yesterday" | Fixed by 70112f9; tested in `TesseraTests/ExerciseAndPlansTests.swift:49-50` |
| T5 notifications, quiet hours | Open, not built (no `UNUserNotificationCenter` in the repo). Not on the phone for the trip |
| T6 times print in the phone's zone | Open by decision (8:56 pm PT); Wed's page shows "02:40 Pull A" at home |
| T7 no zone-change observer | Open (no `NSSystemTimeZoneDidChange` anywhere). Safe: the workout day cache is keyed by zone (`WorkoutSummary.swift:96`), so the next read after landing rebuilds |

## Regressions since #377, and readers 127 missed

No regression found. Merges since 0bff60b that touch Swift (secret words #422, router, live workout, Kitchen, DemoData,
OpZones incremental #399) add no calendar-day read; #422 only changes the private note's wording in
`DayStory.swift:345-348` and the turnover filter at `TessMemory+Turnover.swift:65`. The reading rule is not merged;
fixed-day plans go through `finishedWorkouts` (`WeekView.swift:113`) and his plan is rolling anyway. Pre-existing
readers that still bucket by the phone's zone:

| # | Where | What he sees | Owner, when |
|---|---|---|---|
| N1 | `ReviewWeek.swift:58, 64`; `ReviewView.swift:62-66, 89` | R12 on the Review page in NY; cooks the same shape | Builder, before Oct 26 if cheap: use `WeekFacts.tasksDoneByDay` / `cooksByDay` or `OpZones.dayKey` |
| N2 | `PlanSchedule.swift:59-60` (month heatmap), `PlanDigest.swift:204` | Thu at home, Plans month paints Pull A on Tue 27 | Core, can wait |
| N3 | `TrainingActions.swift:362-367` (`pastWorkout`) | Thu, "did curls yesterday" makes a new Wed workout beside Pull A | Core, can wait |
| N4 | `TessMemory+Turnover.swift:32`; `HomeLines.swift:613`; `NowRanker.swift:153` | Turnover check compares a stored midnight in today's zone (the rule saves it); "days since" can be one off | Core, can wait |

## Unsure

- R25 after a relaunch rests on the rule match, not on the check; no test covers a relaunch (`TripZonesTests.swift:137-149` keeps one process).
- Whether the Review page shows per-day task counts as a number or only as the day's mark; either way Tue reads "good" in NY.
- 127's own R32 trace said tasks "Mon 0, Tue 2"; read in PDT the old code would already give Mon 1, so that row was right for the wrong reason.
