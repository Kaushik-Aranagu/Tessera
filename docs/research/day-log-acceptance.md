# Day log acceptance pack (board item 104)

For: Core (the `DayStory` PR) and QA (its review). Date: 2026-10-16.
Folds `day-log-copy.md` (item 68), `day-log-late-night.md` (item 72, 19 Swift Testing names) and Product's
7:34 PM and 7:40 PM PT calls of Oct 15 (`../product/decisions.md`) into one numbered list. Read only, nothing run.

## Source map

| Short name | File and section | What it gives |
|---|---|---|
| COPY | `research/day-log-copy.md` | Rules, fixed words, line forms, states 1 to 12, 5b Tess line, mismatches M1 to M9 |
| LATE | `research/day-log-late-night.md` | Days 1 to 6 (21 to 31 Oct), wrong-day table, the 19 test names |
| 7:34 | `product/decisions.md`, "Day log and M3 lines" (7:34 PM PT, Research #204) | Took COPY's defaults M1 to M5: "07:10" column, "6:12 pm" in sentences, no "not finished", "Rest day" row, "×", titles as stored, first-day line |
| 7:40 | `product/decisions.md`, "Day log on late nights" (7:40 PM PT, Research #208) | Took LATE's defaults: fold by TesseraDay on the root item's own start time, never `OpRecord.createdAt`; a workout past 4 AM stays on its start day; times in the current zone "until a zone is stored per item"; in-flight note a known issue until then. The zone is now stored (#225, #236), so the known issue is gone: see K4 |
| 7:52 | `product/decisions.md`, "Store each record's time zone now" (7:52 PM PT, Research 80) | Zone column on the op table; already merged as #225 and #236. See K4 |
| 8:07 | `product/decisions.md`, "No dabs" (8:07 PM PT Oct 15; `design/no-dots.md`) | No dabs on the Day log: time, then text. Colour arrives through motion only |
| 9:12 | `product/decisions.md`, "the faint row" (9:12 PM PT Oct 15) | A past unfinished workout reads as the faint row: text in `inkSecondary`, no words, no mark. Replaces 7:34's faint dab |
| FIRST | `research/day-log-first.md`, "Smallest Core slice" | The planned API: `DayLine`, `DayLookup`, `DayStory.lines(for:on:calendar:lookup:)` in `TesseraCore/Sources/TesseraCore/DayLog/DayStory.swift` |

### What master has (origin/master 68ad34c, 15 Oct 20:55 PT; rechecked on de70d67, 15 Oct 11:25 PM PT: still no `DayStory` or `DayLine`)

- **No `DayStory`, `DayLine`, `DayLookup` or `Features/DayLog/`.** `git grep DayStory origin/master` finds only docs.
  Every test below is new; the file is `TesseraCore/Tests/TesseraCoreTests/DayStoryLateNightTests.swift` (LATE) plus
  a `DayStoryCopyTests.swift` for the rest (suggested).
- The 4 AM rule exists: `TesseraDay.startHour = 4` (`TesseraCore/Sources/TesseraCore/Engine/TesseraDay.swift:10`),
  `day(of:)` (`:21-26`, hour < 4 is the day before), `start(of:)` and `end(of:)` at 04:00 (`:34-43`).
- Workouts already bucket by start day: `TesseraDay.day(of: started)` keyed per revision and zone
  (`TesseraCore/Sources/TesseraCore/Training/WorkoutSummary.swift:89-101`). DayStory must agree with it.
- Done tasks count in the 04:00 to 04:00 window (`TesseraCore/Sources/TesseraCore/Tasks/Tasks.swift:38-45`).
- A past-dated note sets the object's `createdAt` to `on` (`TesseraCore/Sources/TesseraCore/Notes/Notes.swift:106-107`);
  its title is `title ?? firstLine(text)` (`:102`, `firstLine` at `:112`). `OpRecord.createdAt` defaults to `.now`
  (`TesseraCore/Sources/TesseraCore/Model/Models.swift:521`).
- **Each action record carries the zone it was logged in.** #225 added `op.zone` (v3 migration,
  `TesseraCore/Sources/TesseraCore/Model/TesseraDatabaseSchema.swift:52-55`, read back at `:251`), exposed as
  `OpRecord.zone: String?` (`Model/Models.swift:549-552`, a zone identifier such as "America/Los_Angeles"; nil for
  rows from before v3, meaning the device's zone). `ActionEngine.perform` stamps it once per record
  (`Actions/ActionEngine.swift:66-67`: `record.zone = zone().identifier`), and #236 made the default
  `TimeZone.autoupdatingCurrent` (`:36-38`), overridable in tests (`engine.zone = { ... }`, as
  `Tests/TesseraCoreTests/OpZoneTests.swift:40`). The zone is per `OpRecord` (one action), not per `Op` inside it, and
  objects carry no zone; so the zone of an item is the zone of the record that created its root object.
- Column clock: `Format.clock`, `Calendar.current`, `"%02d:%02d"` (`App/AppClock.swift:47-50`).
- LATE cites `Tasks/RollForward.swift:71-73` for `logicalDay`; on 68ad34c it is at `RollForward.swift:83`. Other LATE
  citations still hold.

### Rules every expected line assumes

TesseraDay turns at 04:00. Lines sort by instant (`Date`), never by the "HH:mm" text. Column times are 24 h,
zero padded ("07:10"); times in sentences and VoiceOver read "6:12 pm" (7:34). Sets use "×" (VoiceOver says "by").
Titles print exactly as stored. Under 12 words, past tense, digits, units once, no "!", no em-dashes, none of: only,
missed, not finished, behind, streak, should, again, late, great. No colour means good or bad: no dabs on the Day log (8:07 PM PT), no red, no coloured bullet dots. Inter Tight, no italics. The page never writes, so no UNDO key on it in
v1. Core's text uses plain spaces around ×; the page swaps in no-break spaces when it draws, so tests compare the
plain strings. Tests pass a `Calendar(identifier: .gregorian)` with an explicit `timeZone` (LA unless said), never `.current`.
Zone is America/Los_Angeles unless said. "Layer" says who owns the check: Core (the fold's `DayLine` text and day)
or Page (Builder B's screen; QA checks it on the simulator).

## Conflicts and recommendations

| # | Sources | Conflict | Recommendation |
|---|---|---|---|
| K1 (decided) | COPY state 10 vs LATE Day 5, 7:40 | COPY's red-eye block prints "07:30  Done: water the plants" (LA time) next to "00:40  Mobility, 35 min" (New York time). LATE prints both in the current zone: "10:30" and "00:40". | Decided by Product, 8:56 PM PT Oct 15 (`decisions.md`, "Day log times print in the current zone"): every Day log time prints in the phone's current zone. DL11, DL57 expect "10:30". COPY state 10 is fixed to match. |
| K2 | COPY state 3 vs COPY state 3 prose, LATE Day 2, 7:40 | The state 3 block shows "01:30  Note: watered the plants" under TODAY (Friday), while the prose under it says that note, said with "yesterday", goes to Thursday at Tess's time. | Treat the block's 01:30 note as a plain note with no date word: it stays on Friday at 01:30 (DL45). The "yesterday" form is tested in DL5. Ask Research to rename the block's note so the two don't read as one. |
| K3 | LATE Day 2 vs master `Notes.swift:102`, COPY "titles as stored" | LATE expects "Note: watered the plants" for a note said as "watered the plants yesterday". On master the title is `title ?? firstLine(text)`, so unless Tess passes a title without the date word, the stored title is "watered the plants yesterday", and DayStory may not trim it. | DL5's fixture stores the title "watered the plants" explicitly, so the fold test stays about the day. Whether Tess strips the date word is a separate check for the note action owner; if it doesn't, the real line is "Note: watered the plants yesterday" and that is correct per "titles as stored". |
| K4 | 7:40, LATE Day 5 and DL13 vs master (#225, #236) | 7:40 and LATE keep the in-flight note as a known issue "until a zone is stored per item". That condition is already met on master: every `OpRecord` has `zone` (`Models.swift:549-552`), stamped by `ActionEngine.perform` (`ActionEngine.swift:66-67`) from `TimeZone.autoupdatingCurrent`. The in-flight `createNote` was performed with the phone still on PDT, so its record says "America/Los_Angeles". | DayStory reads the day in the zone of the record that created the root object (workout: its `startWorkout` record; note, task, cook, shop: its create record), falling back to the calendar's zone when `zone` is nil (pre-v3 rows). DL13 is a plain pass, no `withKnownIssue`. Times print in the current zone (decided 8:56 PM PT, K1), so DL11 and DL57 stand. Decided (Product, after 8:56 PM PT Oct 15): the day reads `op.zone` now; "read later" covered printed times only, which stay in the current zone. All 8 wrong-day cases pass. Needs `DayLookup` to expose the root's create-record zone (see K6). |
| K5 | 7:40 vs LATE wrong-day table | LATE says #7 (in-flight note) stays wrong even in a correct fold until a zone is stored; 7:40 says 8 cases. With `op.zone` on master, a fold that reads the create record's zone gets #7 right too. | All 8 pass in DL69, no known issue. |
| K6 | 7:40 vs FIRST API | 7:40 folds on the root item's own start time (workout `startedAt`, note `createdAt`). FIRST's `DayLookup` has `title`, `groupRoot` and `topSet` but nothing returns that time, and its signature takes `[OpRecord]` only. | Add `func dayTime(of id: UUID) -> Date?` and `func dayZone(of id: UUID) -> TimeZone?` (or similar) to `DayLookup`; the fake returns the object's `startedAt` or `createdAt`, and the `zone` of the record that created the root (nil means the calendar's zone). Without them DL5, DL9, DL10 and DL13 can't pass. |
| K8 | 9:12 faint row, 8:07 no dabs, Rest day and tail tiers | The page must pick a tier (finished, running, unfinished, rest, tail) for each line, but `DayLine` carries only `time` and `text`; reading "min." out of the text is fragile. | `DayLine` gains a kind or state (`.finished`, `.running`, `.unfinished`, `.rest`, `.tail`). Core test `pastUnfinishedWorkoutIsMarkedUnfinished` (DL22, DL60); Page check DL70: a running line on a past block stays `ink`. With Core. |
| K7 | COPY 5b A5 | "Full one. 31 things across 4 apps." counts records; COPY itself says Core should count folded items. | 5b only, not gating this PR. Count folded items when slot A lands (DL61). |

No other conflicts: 7:34 matches COPY's M1 to M5 defaults word for word, and 7:40 matches LATE's defaults.

## The test list

Expected lines are written as the screen shows them: column time, two spaces, text. "No line" means the fold returns
nothing for that item on that day. Block labels (TODAY, WED 21) are Page; the day an item lands on is Core.

### A. Late night: the 19 Swift Testing names (LATE, "Swift Testing names, Core's Day log v1")

| ID | Test name | Setup (time, data) | Action | Expected exactly | Source |
|---|---|---|---|---|---|
| DL1 | `setAfterMidnightStaysInWorkoutStartedBefore` | LA (all records `zone = "America/Los_Angeles"` unless said). Wed 21 Oct 19:05 two `createTask`. Push Day B `startWorkout` 23:20, sets 23:28 to 23:58, set Thu 22 00:40 Incline 30 × 10 (a PR), `finishWorkout` Thu 00:52. | `lines` for Wed 21 and Thu 22 | Wed 21: `19:05  Added 2 tasks`, `23:20  Push Day B, 92 min. Incline 30 × 10, PR.` Thu 22: no Push Day B line. | LATE Day 1; wrong-day #1; 7:40 |
| DL2 | `workoutAcrossMidnightShowsAbsoluteMinutes` | As DL1 | Read the workout line | `23:20  Push Day B, 92 min. Incline 30 × 10, PR.` (92 = `endedAt` minus `startedAt`) | LATE Day 1 |
| DL3 | `runningWorkoutAt0045IsUnderToday` | As DL1 but no finish; now Thu 22 00:45; 5 sets logged | `lines` for logical today (Wed 21) | `19:05  Added 2 tasks`, `23:20  Push Day B, 5 sets` (no minutes, no top set). No Thu 22 lines. Page: label TODAY until 04:00, then WED 21 without moving. | LATE Day 1; COPY state 11 Design's sheet also draws `00:31  Note: hotel ideas` under Wed 21; that line is illustrative and not part of this fixture (P6, Research default). |
| DL4 | `noteAt0210BelongsToEveningBefore` | LA. Thu 22 08:30 `setTaskDone` "call the bank"; Fri 23 02:10 `createNote` "hotel ideas" | `lines` for Thu 22 and Fri 23 | Thu 22: `08:30  Done: call the bank`, `02:10  Note: hotel ideas`. Fri 23: no line for it. | LATE Day 2; wrong-day #2 |
| DL5 | `pastDatedNoteUsesItsOnDateNotRecordTime` | Fri 23 02:12 `createNote`, title "watered the plants", `on` = Wed 21 12:00 (object `createdAt` Wed 12:00, record `createdAt` Fri 02:12) | `lines` for Wed 21, Thu 22, Fri 23 | Wed 21 gains a first line `12:00  Note: watered the plants`. Thu 22 and Fri 23: no line for it. | LATE Day 2; wrong-day #3; 7:40; K3, K6 |
| DL6 | `taskDoneAt0355IsOnDayBefore` | LA. Fri 23 cook ramen 18:40 to 19:20; Sat 24 03:55 `setTaskDone` "pay rent" | `lines` for Fri 23 and Sat 24 | Fri 23: `18:40  Cooked ramen, 40 min`, `03:55  Done: pay rent`. Sat 24: no line for it. Agrees with `Tasks.swift:44-45`. | LATE Day 3; wrong-day #4 |
| DL7 | `captureAt0405OpensTheNewDay` | Sat 24 04:05 one `createTask` | `lines` for Fri 23 and Sat 24 | Sat 24: `04:05  Added 1 task`. Fri 23: no line for it. | LATE Day 4 |
| DL8 | `recordsAt035959And040000FallOnEitherSide` | Own fixture: one `createTask` at Sat 24 03:59:59, one at Sat 24 04:00:00 | `lines` for Fri 23 and Sat 24 | Fri 23: `03:59  Added 1 task`. Sat 24: `04:00  Added 1 task`. | LATE Day 4; `TesseraDay.swift:21-26` |
| DL9 | `workoutStarted0350FinishedAfter0400StaysOnStartDay` | LA. Sat 24 04:05 `createTask`; 11:30 shop finished, 14 items; Sun 25 03:50 Pull Day A `startWorkout`, set 03:58, four sets 04:02 to 04:25 (top Row 60 × 10), `finishWorkout` 04:30 | `lines` for Sat 24 and Sun 25 | Sat 24: `04:05  Added 1 task`, `11:30  Shopped, 14 items`, `03:50  Pull Day A, 40 min. Row 60 × 10.` Sun 25: `[]` (Page: empty at 45%). | LATE Day 4; wrong-day #5; 7:40 |
| DL10 | `groupDayComesFromRootNotEachRecord` | As DL9 | Count Pull Day A lines across both days | Exactly one: `03:50  Pull Day A, 40 min. Row 60 × 10.` on Sat 24. Never `03:50  Pull Day A, 1 set. Row 55 × 10.` or a `04:02` line on Sun 25. Agrees with `WorkoutSummary.swift:100`. | LATE Day 4; 7:40; K6 |
| DL11 | `redEyeTimesPrintInCurrentZone` | Mon 26: 07:30 PDT `setTaskDone` "water the plants"; Mobility 21:40 to 22:15 PDT | `lines` for Mon 26 with an LA calendar, then a New York calendar | LA: `07:30  Done: water the plants`, `21:40  Mobility, 35 min`. New York: `10:30  Done: water the plants`, `00:40  Mobility, 35 min`. | LATE Day 5; 7:40; Product 8:56 PM (K1) |
| DL12 | `redEyeWorkoutStaysOnMondayInNewYork` | As DL11, New York calendar | `lines` for Mon 26 and Tue 27 | Mobility on Mon 26 (`00:40  Mobility, 35 min`, before 04:00 EDT). Tue 27: no Mobility line. | LATE Day 5; wrong-day #6 |
| DL13 | `inFlightNoteKeepsLoggedZoneDay` | As DL11 plus note "seat 14C, no sleep" at Tue 01:30 PDT (08:30Z), its `createNote` record with `zone = "America/Los_Angeles"` (set via `engine.zone` or on the record); every DL11 record also LA. Read with a New York calendar. Day from the create record's `zone`: 08:30Z is 01:30 in LA, before 04:00, so Mon 26. | `lines` for Mon 26 and Tue 27 | Mon 26: `10:30  Done: water the plants`, `00:40  Mobility, 35 min`, `04:30  Note: seat 14C, no sleep` (times in the current zone). Tue 27: no line for it. Plain pass, no `withKnownIssue`. Control: same note with `zone = nil` read in New York lands on Tue 27 (fallback to the calendar's zone). | LATE Day 5; wrong-day #7; 7:40; K4, K5 |
| DL14 | `fallBackNightPrintsTwo0130LinesInInstantOrder` | LA. Sat 31 note "hall light out" at 08:30Z (01:30 PDT, 1 Nov); `setTaskDone` "bins" at 09:30Z (01:30 PST) | `lines` for Sat 31 | Two separate lines in this order: `01:30  Note: hall light out`, `01:30  Done: bins`. No zone tag, not merged. | LATE Day 6 |
| DL15 | `fallBackWorkoutMinutesAreAbsolute` | Push Day B 07:50Z (00:50 PDT) to 09:20Z (01:20 PST), top Bench 82.5 × 8 | Read the workout line | `00:50  Push Day B, 90 min. Bench 82.5 × 8.` (never "30 min") | LATE Day 6; wrong-day #8 |
| DL16 | `fallBackNightIsOneDayOf25Hours` | All of LATE Day 6: cook dal tadka 20:00 to 20:50 PDT plus DL14, DL15 | `lines` for Sat 31 and Sun 1 Nov | Sat 31: `20:00  Cooked dal tadka, 50 min`, `00:50  Push Day B, 90 min. Bench 82.5 × 8.`, `01:30  Note: hall light out`, `01:30  Done: bins`. Sun 1: nothing before 12:00Z. | LATE Day 6; wrong-day #8 |
| DL17 | `columnClockIsTwentyFourHourZeroPadded` | Instant Thu 22 00:40 PDT | Format the column time | `00:40` | LATE Format; 7:34; `AppClock.swift:47-50` |
| DL18 | `voiceOverTimeIsSentenceForm` | DL1's workout line | VoiceOver text | `11:20 pm, Push Day B, 92 minutes. Incline 30 by 10, PR.` | LATE Day 1, Format; 7:34 |
| DL19 | `zoneSwapWithoutWriteRebucketsDays` | DL11's records, no write between reads | `lines` with LA calendar, then New York, then LA again, same store revision | Each read equals DL11 for that zone (`21:40` then `00:40` then `21:40`); no stale per-zone cache key. | LATE Cache; `WorkoutSummary.swift:89-101` |

### B. Copy: every line form, fixed word and state (COPY)

| ID | Layer | Setup (time, data) | Action | Expected exactly | Source |
|---|---|---|---|---|---|
| DL20 | Core | Push Day A, 52 min, finished, top Bench 82.5 × 8 | Fold | `Push Day A, 52 min. Bench 82.5 × 8.` | COPY line forms |
| DL21 | Core | As DL20, top set is a PR | Fold | `Push Day A, 52 min. Bench 82.5 × 8, PR.` | COPY line forms |
| DL22 | Core | Past day, Pull Day A, 3 sets, top Row 60 × 10, never finished | Fold | `Pull Day A, 3 sets. Row 60 × 10.` Page: the faint row, text in `inkSecondary`, no mark. No "not finished". | COPY line forms, M2; 7:34 |
| DL23 | Core | Cook carbonara, 35 min | Fold | `Cooked carbonara, 35 min` | COPY line forms |
| DL24 | Core | Shop finished, 1 item; then another day, 14 items | Fold | `Shopped, 1 item`; `Shopped, 14 items` | COPY line forms |
| DL25 | Core | 1 task captured; another day 3 tasks and 2 groceries | Fold | `Added 1 task`; `Added 3 tasks, 2 groceries` (tasks first) | COPY line forms, state 1 |
| DL26 | Core | 1 done; 2 dones; 5 dones | Fold | `Done: call the bank`; `Done: water the plants, call mom`; `5 tasks done` | COPY line forms |
| DL27 | Core | 1 tick on Home; 6 ticks on Lisbon packing | Fold | `Ticked 1 on Home`; `Ticked 6 on Lisbon packing` | COPY line forms |
| DL28 | Core | 1 note "hotel ideas"; 2 notes | Fold | `Note: hotel ideas`; `2 notes` | COPY line forms |
| DL29 | Core | New recipe "dal tadka"; new list; new routine | Fold | `Saved dal tadka`; `New list: Lisbon packing`; `New routine: Push Day B` (case as stored) | COPY line forms; 7:34 |
| DL30 | Core | More than 6 kinds on a day | Fold, last line | `Also: 3 notes, 5 groceries, ticked 4 on Lisbon packing.` with `time == nil`. Page: no time, no dab, 70%. Largest counts keep a line; the tail orders by first time. | COPY line forms, M9 |
| DL31 | Core | Planned rest day | Fold, first line | `Rest day` with `time == nil`. Page: no time, 21/400 `inkSecondary`, no dab. | COPY line forms, M3; 7:34 |
| DL32 | Page | Review page | Read the link row | `The week · Day log · Notes` | COPY fixed words |
| DL33 | Page | Home on Thursday afternoon | Read Home's day label (second way in) | `Thursday afternoon` | COPY fixed words |
| DL34 | Page | Day log open; then an object opened from a line | Read the back word | `‹ HOME`; `‹ DAYS` | COPY fixed words |
| DL35 | Page | October | Month title (Title 44/500) | `October` | COPY fixed words |
| DL36 | Page | Today and a past Wed 14 | Date labels | `TODAY` (ink); `WED 14` (`inkSecondary`) | COPY fixed words |
| DL37 | Page | Scrub on Sun 11; scrub over an empty run Oct 1 to 4 | Scrub numeral | `SUN` over `11`; `OCT` over `1–4` (en dash allowed) | COPY fixed words, M7 |
| DL38 | Page | DL21's line at 07:10 | VoiceOver | `7:10 am, Push Day A, 52 minutes. Bench 82.5 by 8, PR.` | COPY fixed words; 7:34 |
| DL39 | Page | Empty run Oct 1 to 4 | VoiceOver | `October 1 to 4, nothing logged` | COPY fixed words |
| DL40 | Core | Every fixture in this pack | Scan all `DayLine.text` | Under 12 words; no "!", no em-dash; none of only, missed, not finished, behind, streak, should, again, late, great. Page: no red, no coloured bullet dots, Inter Tight, no italics. | COPY rules |
| DL41 | Core | State 1: Thu Oct 8, 31 records | `lines` | `06:50  Pull Day A, 61 min. Row 70 × 10.`, `08:30  4 tasks done`, `09:00  Added 7 tasks, 5 groceries`, `13:15  New list: Lisbon packing`, `17:40  Cooked omelette, 10 min`, then tail `Also: 3 notes, ticked 4 on Lisbon packing.` (6 lines, cap). No Tess line in v1. | COPY state 1 |
| DL42 | Core | State 2: Sun Oct 11, planned rest, 3 tasks at 09:15, 2 ticks on Home at 18:05 | `lines` | `Rest day`, `09:15  Added 3 tasks`, `18:05  Ticked 2 on Home` | COPY state 2; 7:34 |
| DL43 | Core | Planned rest day, nothing else | `lines` | `Rest day` alone | COPY state 2 |
| DL44 | Core | A day with no plan at all, some records | `lines` | No `Rest day` line | COPY state 2 |
| DL45 | Core, Page | State 3: now Sat 17 01:30; Fri 16 cooked ramen 19:00 40 min; Push Day B 23:20 to 00:35, Incline 30 × 10 PR; plain note "watered the plants" (no date word) at Sat 01:30 | `lines` for Fri 16 | `19:00  Cooked ramen, 40 min`, `23:20  Push Day B, 75 min. Incline 30 × 10, PR.`, `01:30  Note: watered the plants`. Page: label TODAY, no SAT 17 block yet. | COPY state 3; K2 |
| DL46 | Page | As DL45, clock passes 04:00 | Watch the block | Relabels `FRI 16` in place; the window may then ease up 64pt for the new empty TODAY (Design's turnover). Reduce Motion: a crossfade, no ease or rise. No copy comments on the hour. | COPY state 3 |
| DL47 | Core | State 4: Tue Oct 13, 4 tasks and 3 groceries from 08:05, 3 notes from 14:55 | `lines` | `08:05  Added 4 tasks, 3 groceries`, `14:55  3 notes` | COPY state 4 |
| DL48 | Core | As DL47 with 1 note "gate B32, seat 14C" | `lines` | `14:55  Note: gate B32, seat 14C` | COPY state 4 |
| DL49 | Page | Empty past day; empty run; run across months; empty today | Labels | `THU 8` at 45%, no lines; `OCT 1 TO 4` at 45%; `SEP 29 TO OCT 2`; `TODAY` alone, no line under it. Never a count of days. | COPY state 5, M8 |
| DL50 | Core, Page | State 6: no records ever | Open the log | Under `TODAY`: `Your days write themselves here.` (21/400 `inkSecondary`, no dab, no time). No days drawn above it. First record inks in below the date and the line leaves. | COPY state 6, M5; 7:34 |
| DL51 | Core | State 7: Wed 14, Push Day A planned, 0 sets; 12:40 done "call the bank"; 19:30 cooked carbonara 35 min; plus a workout started and finished with 0 sets | `lines` | `12:40  Done: call the bank`, `19:30  Cooked carbonara, 35 min`. No plan line, no `Rest day`, no faint workout row, no line for the 0-set workout. | COPY state 7, rules ("Trained") |
| DL52 | Core | State 8: Thu 15 Push Day A rolled to Fri 16, done Fri 07:10, 52 min, Bench 82.5 × 8 | `lines` for Thu 15 and Fri 16 | Thu 15: `[]`. Fri 16: `07:10  Push Day A, 52 min. Bench 82.5 × 8.` No "moved" or "rolled". | COPY state 8 |
| DL53 | Core | State 9: Mon Oct 5, Leg Day A 18:20, 48 min, 11 sets with 3 undone, a task made and deleted, 2 edits | `lines` | `18:20  Leg Day A, 48 min. Squat 102.5 × 5.` only | COPY state 9 |
| DL54 | Page | Today, log open, workout running; "Set 3 taken back." in the workout | Watch the line | Numbers swap like a value word (blur crossfade, 220 ms). | COPY state 9, M6 |
| DL55 | Page | Today, "Added 1 task" showing; "Dentist taken back." on Home; then redo | Watch the line | Line fades out (220 ms); comes back on redo. | COPY state 9, M6 |
| DL56 | Page | Delete a note (destructive) from its own screen | Watch the log | Where it was made: the undo line names the thing, then what happened, with UNDO for 10 s. The log draws the committed state at once and redraws if UNDO lands. No UNDO key on the log. | COPY rules, state 9 |
| DL57 | Core | State 10: Mon Oct 26 red-eye, as DL11 | `lines`, LA then New York | LA: `07:30  Done: water the plants`, `21:40  Mobility, 35 min`. New York: `10:30  Done: water the plants`, `00:40  Mobility, 35 min`. No "Travel day". Never a mix such as `07:30` beside `00:40`. | COPY state 10; LATE Day 5; Product 8:56 PM (K1) |
| DL58 | Core, Page | State 11: Thu 18:10, 07:10 two tasks, Push Day A started 18:02, 4 sets | `lines` | `07:10  Added 2 tasks`, `18:02  Push Day A, 4 sets`. Page: `ink`, no mark, no glow; a Tess write gets the 2.8 s cobalt wash behind its text. | COPY state 11 |
| DL59 | Core | As DL58, then finish (61 min, Bench 82.5 × 8) | `lines` | `18:02  Push Day A, 61 min. Bench 82.5 × 8.` | COPY state 11 |
| DL60 | Core | State 12: same unfinished Pull Day A on a past day and today | `lines` | Past: `Pull Day A, 3 sets. Row 60 × 10.` (faint row). Today running: `Pull Day A, 3 sets` (`ink`). After the 6 h auto-finish: minutes form, as DL20. | COPY state 12 |
| DL61 | 5b, not v1 | State 1 day with Tess slot A | Tess line | `Full one. 31 things across 4 apps.` with the count from folded items. Does not gate this PR. | COPY state 1, slot A; K7 |
| DL62 | 5b, not v1 | Undo set 3 (bench 80 × 5) from Oct 12 | Preview, commit, refused | `Set 3, bench 80 × 5, from Oct 12. PR goes back to 77.5.`; `Set 3 from Oct 12 taken back.` with UNDO 10 s; refused: `Set 3 changed since. OPEN`. Does not gate this PR. | COPY Tess line (5b) |

### C. The two calls (decisions.md, Oct 15 PT)

Each clause of the call, with the test that proves it. The M3 half of 7:34 (trend, habits, weigh-in, "Read is back.",
D12, habit grammar) is not Day log and is left to `m3-lines.md`.

| ID | Call clause | Setup | Action | Expected exactly | Proven also by |
|---|---|---|---|---|---|
| DL63 | 7:34: column reads "07:10", sentences say "6:12 pm" | One done at 18:12 | Column, VoiceOver | Column `18:12`; VoiceOver starts `6:12 pm, ` | DL17, DL18, DL38 |
| DL64 | 7:34: unfinished workout gets no "not finished" words; the faint row carries it (9:12 PM PT, replacing 7:34's faint dab) | DL22 | Fold | `Pull Day A, 3 sets. Row 60 × 10.` | DL22, DL60 |
| DL65 | 7:34: a planned rest day opens with a "Rest day" row | DL42 | Fold | First line `Rest day`, no time | DL31, DL42, DL43 |
| DL66 | 7:34: sets use "×", titles show exactly as stored | Recipe stored "dal tadka", top set 82.5 × 8 | Fold | `Saved dal tadka`; `... Bench 82.5 × 8.` (never "x", never "Dal Tadka") | DL29, DL20 |
| DL67 | 7:34: the first day reads "Your days write themselves here." | No records | Open the log | `Your days write themselves here.` | DL50 |
| DL68 | 7:40: fold by TesseraDay on the root item's own start time, never `OpRecord.createdAt` | DL5 and DL9 records | Fold | As DL5 and DL9 | DL5, DL9, DL10; K6 |
| DL69 | 7:40: a calendar-day fold gets 8 cases wrong | LATE wrong-day table #1 to #8 as one parameterised test | Fold each | All 8 land on the "Right" column: #1 WED 21 one line; #2 THU 22; #3 WED 21 12:00; #4 FRI 23; #5 SAT 24; #6 MON 26; #7 MON 26 (read the `zone` of the note's `createNote` record, "America/Los_Angeles"); #8 SAT 31. No `withKnownIssue`. | DL1 to DL16; K5 |
| DL70 | 7:40: a workout running past 4 AM stays on the day it started | DL9's workout, not yet finished; now Sun 25 04:10 | `lines` for Sat 24 and today (Sun 25) | Sat 24: `03:50  Pull Day A, 2 sets`. Sun 25 (TODAY): `[]`. | LATE Day 4 live, Open default |
| DL71 | 7:40: times print in the current zone until a zone is stored; in-flight note is a known issue until then. **Met** (K4): the zone is stored since #225, #236, so this is no longer a known issue | DL11, DL13 | Fold | Days from each create record's `zone`, times in the current zone: as DL11, and DL13 passes plainly (zone stored since #225, #236) | DL11, DL13, DL57; K4 |

**Count:** 71 numbered checks. DL1 to DL19 are LATE's 19 tests; DL20 to DL62 cover every COPY line, fixed word and
state (DL61, DL62 are 5b and don't gate); DL63 to DL71 trace each day-log clause of the 7:34 and 7:40 calls.
Eight conflicts (K1 to K8); K1 and K4 are decided (Product, 8:56 PM PT and after). K3, K6 and K8 are with Core (K3 and K6 sent by the coordinator Oct 15; K8 added with the pack fixes, Oct 15 11:25 PM PT).
