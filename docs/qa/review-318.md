# Review 318: Day log engine (DayStory)
PR #318 at fd9dc1d, base 7cae550 (master). Trial merge clean. 2 files: `DayLog/DayStory.swift` (+490), `DayStoryTests.swift` (+294). Static review (no Swift toolchain here), Oct 15 PT.

**Verdict: FIX FIRST** on S1 (cost) and S2 (running line after 04:00). The day and zone logic is otherwise right.

## Day boundary and zone: PASS except S2
- `onDay` keys each item's day in its own zone (`record.zone`, or the root's `dayZone`, nil = calendar zone) through `TesseraDay`'s 04:00 start, and compares (y, m, d) with the target's key in the current calendar. That matches day-log-v1.md line 68 (K4/K6) and the travel phone: times print in the current zone, days come from the logged zone.
- Workouts fold to one line on the day their root started (`startedAt`), so a set after midnight or after 04:00 stays with its workout (tests at :81, :137). Past-dated notes use their own `on` time (:121). 03:59:59 / 04:00:00 split (:129). Fall-back night orders by instant (:167).
- The fold is pure and recomputed on read, so nothing a record says changes at 04:00.
- Undone records (`state == .committed`) and system records are left out; same-day make-and-delete cancels.

### S2 (must fix): a running workout turns faint at 04:00
`DayStory.swift`, the workout branch: `.running` needs `onDay(now) && target == today`. day-log-v1.md (row "The 04:00 turnover", DL70, and line 23) says a workout still running at 04:00 **stays on WED 21, in `ink`, still counting**. Here, once `now` passes 04:00, WED 21 is no longer `today`, so the same workout (no `endedAt`) falls to `.unfinished`: the faint row, with a top set added, under a workout he is still lifting. A workout started at 23:00 can run to 05:00 before the 6 h auto-finish.
Fix: `.running` when `endedAt == nil` and `now.timeIntervalSince(started) < 6 h` (the auto-finish window), whatever the day; `.unfinished` only past that. Test: start 23:20 Wed, sets to 03:50, read WED at `now` 04:30 Thu, expect `.running` and "Push Day B, N sets".

## Cost of `engine.history(limit: .max)`: S1 (must fix)
- `history` (ActionEngine.swift:221) sorts **every** OpRecord on the main actor, and the comparator builds two `uuidString`s per comparison. At five years (~37,500 sets, ~50k records) that's ~800k comparisons with string allocations, every time the page reads.
- The fold then walks all of them, and is **quadratic for workout records**: for each `logSet` etc. on any other day, `seenRoots` is only filled for roots on the target day, so every off-day record re-runs `groupRoot` (parent walk with `kind()` per step), `workout()` (counts every set) and `StoreDayLookup.dayZone(of:)`, which is a **linear scan of all records**. That's roughly 37,500 × ~25,000 `contains` checks per day read: seconds, on the main actor, per day block, as he scrolls.
- `createTask` / grocery branches also call `created(...)`/`parent` lookups before the `onDay` guard, so every task and grocery record in history pays kind lookups.

Fix (any of these is enough; the first two together are best):
1. Window first: keep only records with `createdAt` in [day start − 14 h, day end + 20 h] (zones ±14 h plus the 6 h auto-finish) before the loop. Better, an engine `history(from:to:)` that filters before it sorts, so the app never asks for `.max`.
2. Remember every root you've checked (`checkedRoots`), not only the ones on the day, and build `dayZone` as a `[UUID: TimeZone]` once in `StoreDayLookup.init`.
3. Move the `onDay` guard to the top of each branch.
Add a `ScaleTests` budget for one `DayStory.lines` read at `TESSERA_SCALE=1500`.

## Migrations: none
No catalog, schema or `project.yml` change. Read-only: `DayStory` and `StoreDayLookup` never write.

## Lows
- L1: the 6-line cap only applies when `room >= 1`. Six own lines or groups (say 4 recipes saved, a workout, a cook) plus Rest day and loose counts give 9+ lines; `room <= 0` appends all loose lines. Cap own lines too, or fold the overflow into the tail.
- L2: a task done, reopened, then done again the same day is in `reopenedToday` and drops out of "Done:" though it ended done. Compare the last `isDone` write of the day.
- L3: two `startShop`s with one `finishShop` (an abandoned shop) both match the same finish and print two "Shopped" lines. Take the first start after the previous finish.
- L4: `.running`'s `onDay(now, zone: calendar.timeZone)` is redundant with `target == today` (goes away with the S2 fix).

## Checked and fine
Kind tiers (K8) are set by the engine, never read from text; the "Also:" tail only past the cap and ranks by size then time; VoiceOver form ("7:10 am, … by …, … minutes"); every action has a fold rule, with a test that fails on a new action; no Never-list words in any line text.

## Addendum: re-check at 83dd60d (Oct 16 PT, 12:1x am): PASS
Trial merge onto master 4011570 clean. Only TesseraCore changed (ActionEngine, DayStory, two test files).
- **S2 closed.** An unfinished workout is `.running` while `now` is 0 to 6 h after its start (`DayStory.liveFor`), whatever the day, and `.unfinished` after that. `aLiveWorkoutFromLastNightStaysOnItsDayPast0400` reads WED at 04:30 Thu. That matches DL70.
- **S1 closed.**
  - `ActionEngine.history(from:to:)` filters `context.operations` before sorting.
  - The new `DayStory.lines(engine:on:…)` windows the history: day start − 14 h to day end + 20 h, plus `createNote` up to 8 days later for past-dated notes.
  - Every root is checked once (`seenRoots.insert` runs before the day test), and roots are memoised.
  - `StoreDayLookup` builds its zone map once in `init`.
  - `onDay` comes first in every branch.
  - The cook and shop finishes are paired in one pass.
  - `topSet`'s PR is one `recordsBeaten` read.
  - `dayLogStaysFast`: 17 ms at 200 workouts, 68 ms at 1500 (Core's numbers; there's no toolchain here).
- **L1 closed.** The cap always leaves a slot for "Also:". Workouts are kept first, then own lines by time, then the largest counts. Own lines that spill over join the tail.
- **L2 closed.** A done counts by its last state that day (`doneToday`), once, at its first time.
- **L3 closed.** A shop is its start plus the finish that closes it, and a later start replaces an open one.
- Old signature unchanged; no migrations; read-only.

### Notes (not blocking)
- The app doesn't call the Day log yet. When Builder B wires the page, it should use `lines(engine:…)`, never `history(limit: .max)`.
- `isPR` uses `recordsBeaten(excludingWorkout:)`, which compares against every other workout, later ones included. A past day's ", PR" can drop once a later session beats it. `WorkoutSummary` behaves the same way, so this isn't a regression. If Product wants "PR at the time", both need an as-of date.
- Overflowed workout lines in the tail carry their full text, with its own full stops ("Also: Push A, 52 min. Bench 85 × 8., …"). That only happens with five or more workouts in a day, so it's cosmetic.

## The app test that failed at 00:07 PDT: a test bug, not #318
`TesseraTests/ExerciseAndPlansTests.swift:146` finds "today" with `Calendar.current.isDate($0.date, inSameDayAs: now)`, a midnight day. The plan's week uses his 04:00 day, so between 00:00 and 04:00 the test picks tomorrow's row (`.planned`) and fails. It isn't random: it fails every time in that window. #318 touches no app code and nothing PlanData reads (`history(from:to:)` is additive).
Fix (Builder A, one line): match on `TesseraDay(calendar: .current).day(of: now)` the way PlanData does, or pin `AppClock` to midday.
**Verdict: PASS.**
