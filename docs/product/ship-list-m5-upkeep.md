*Approved by Product, 2026-10-15 19:11, from Research's draft (`../research/ship-list-m5-upkeep-draft.md`) with all seven defaults. Comes after Money. Chore needs M3 slice 2 (Habit) first.*

# Home upkeep ship list: third slice for M5 (engine-first)

**DRAFT for Product to review.** Research lab, 2026-10-15. Not approved; nothing here is a decision until Product signs it. Comes after Money (`ship-list-m5-money-draft.md`) and before People, as Kaushik ordered. Same rules as `../product/ship-list-lists.md` and `../product/ship-list-kitchen.md`: small end-to-end slices, velocity over perfection, engine first so Core can start now. **Engine** = logic and tests only; **Feature screen** = a self-contained screen in its own `Features/Upkeep/` folder that meets the UI bar (no cards, pills, capsules or stock lists). Source: the Home upkeep part of `people-and-upkeep.md` (smallest version only) and `habits.md`. Owners: **Core** builds engine slices, **Builder B** builds screens. Checked against `origin/master` at `23a0e10`: there is no `Habit` class, no `habit` key in `SystemCatalog.Key`, and no Money, Reading or upkeep code on master yet. `NowPicker` has three rules (running process, timed items, untimed today).

**The idea in one line.** A chore is a habit with an interval: "watered plants" logs a check-in and resets its age, and the chore reads "watered 6 days ago, usually every 7", never "overdue". The only new class is `Chore`, a child of M3's `Habit`. It reuses `Habit` check-ins, `ObjectStore`, the op log and undo, the ghost row and `TessCaptureEngine`, and `NowPicker` as they are. No red, no streaks, no points, no rooms.

**Age, not due dates.** A chore has no due date and is never late. It has an age (days since the last check-in) and, when known, an interval. Staleness is age divided by interval; it only orders things and is never shown as a number.

**Progressive disclosure rule.** A chore opens as its name and its age ("Plants, 6 days"). Interval, history of gaps and pause are one gesture away. The upkeep page shows chores; counts appear only as "3 chores this week" one level deeper.

**Parse order for M5 (decisions.md, 4:10 PM PT):** notes, pasted recipes, relative sets, then reading, money, people, then comma sets, lifts and kitchen, then upkeep, then tasks.

*"paid" plus an amount is Money's (decisions.md, 4:34 PM PT): a spend that also ticks the matching chore, so eval rows 34 and 40 expect that. "paid rent" with no amount stays here.*

## Slices

| # | Slice | Done when | Type | Owner |
|---|---|---|---|---|
| 1 | **Chore class and actions** | `SystemCatalog.Key.chore`, parent `habit` (M3 slice 2, which lands first): name, verb (the past form used to log it, "watered"), interval (`.number`, days, optional), place (`.text`, optional), snoozedUntil (`.date`), pausedFrom / pausedUntil (`.date`), about (`.refList` to `thing`). Last done is derived from the newest Habit check-in, never stored. A check-in gains kind: done or fine. `DoChore(chore, at?)` adds a done check-in, `ChoreFine(chore)` adds a fine check-in ("looked, fine": resets age, not counted as done), `SnoozeChore(chore)` sets snoozedUntil to tomorrow 00:00, `SetChoreInterval(chore, days?)`, `PauseChores(until)` and `ResumeChores`, `AddChore(name, verb, interval?)` and `DeleteObject`, all undoable through the op log. `chore(named:)` matches exact name, then every word contained as a whole word with a trailing "s" dropped (the `recipe(named:)` rule). `AddChore` with an existing name returns that chore. Op summaries read "Watered plants", "Plants: looked, fine". `DoChore` is registered in `ActionRegistry` with name-only parameters, so the model and Claude can call it | Engine | Core |
| 2 | **Upkeep ledger** | `UpkeepLedger` (in `TesseraCore/Upkeep/`, shaped like `ListContents`) returns per chore: age in whole local days, interval (set, or learned), staleness, and `ageLine` ("watered 6 days ago, usually every 7", "watered today", "never logged"). With no interval set, the interval is the median gap after three done check-ins, else none. Paused days are left out of age: a chore at 4 days before a 10-day pause is at 4 days after it. `weekLine` reads "3 chores this week" (done check-ins only, Monday start, fine excluded). Tests: day boundary in local time, learned median with 2 and 3 logs, pause, fine resets age but not the week count, undo | Engine | Core |
| 3 | **The stalest drifts toward Now** | `NowPicker` gains one chore item, at most one, ever: the chore with the highest staleness that is at least 1, not snoozed, not paused. Below 2 it goes last in the queue (after untimed today tasks); from 2 it moves ahead of untimed today tasks; it never goes ahead of a running process or a timed item (or the Reading and Money rules once they land). Chores with no interval never drift. Next step reads "6 days, usually 7". A test with the chore at staleness 0.9, 1.2 and 2.1, against an empty day, two untimed tasks, a timed task and a workout running, shows it in the expected place in all 12 cases. After 5+ days with no upkeep logs, still exactly one chore | Engine | Core |
| 4 | **Upkeep phrases** | `TessGrammar+Upkeep.swift`, a `.chore` parse case (done, fine, interval, pause), checked after notes, pasted recipes, relative sets, comma sets, lifts and kitchen (and after reading, money and people once they land), before tasks. Narrow the planned question guard (collision rule 2) so `did` is a question lead only before `i`, `you`, `we` or `tess`. All phrases below map as written, with their feedback line. All 15 eval rows pass, and every phrase in `../product/kitchen-phrases.md`, the existing grammar tests and the `grammar-collisions.md` guard rows still parse the same | Engine | Core |
| 5 | **Chore page** | Object page for one chore, see design steer | Feature screen `Features/Upkeep/` | Builder B |
| 6 | **Upkeep page** | The Upkeep front page: every chore by staleness, see design steer | Feature screen `Features/Upkeep/` | Builder B |
| 7 | **A chore on Now** | The Now slot and ledger row for the drifting chore, and done from there, see design steer | Feature screen `Features/Upkeep/` | Builder B |

Build order: M3 slice 2 (Habit) → 1 → 2 → 4 → 3; screen 5 after 2, 6 after 2, 7 after 3.

## Capture phrases (slice 4)

| Phrase | Maps to | Feedback line |
|---|---|---|
| `watered plants`, `watered the plants` | `DoChore` on Water plants | "Watered plants. Was 6 days, usually 7." |
| `watered plants` (no such chore) | `AddChore` "Water plants", verb watered, then `DoChore` | "Watered plants. How often? 7d" (one tap, or ignore and learn) |
| `watered plants yesterday`, `watered plants sat` | `DoChore` dated yesterday, or the most recent past Saturday | "Watered plants, Sat 10 Oct." |
| `did laundry`, `took out the bins`, `changed the sheets` | `DoChore` (or `AddChore` then `DoChore`) | "Did laundry." |
| `plants fine`, `plants ok`, `checked plants, fine` | `ChoreFine` | "Plants: looked, fine. Counting from today." |
| `plants every 7d`, `plants every 7 days`, `plants weekly`, `sheets every 2 weeks` | `SetChoreInterval` (existing chore only) | "Plants, every 7 days." |
| `snooze plants` | `SnoozeChore` | "Plants tomorrow." |
| `pause chores till sun`, `away till sun` | `PauseChores` until Sun 00:00 | "Chores paused till Sun. Ages hold." |
| `chores back`, `home` (while paused) | `ResumeChores` | "Chores back on." |

Rules:
- Phrases are ghost rows like everything else: pending, commit after 2 s or on tap, undo.
- The verb is an explicit prefix (collision rule 1). The upkeep verb list is fixed in v1: watered, cleaned, did, paid, changed, washed, emptied, took out, hoovered, vacuumed, mowed, descaled, dusted, mopped, swept, ironed, defrosted, topped up, fed. A new chore is created only from this list; any other past tense ("finished the report") goes on unchanged.
- The past tense means done; the plain verb with a day cue is a task. "water plants sun" is a task for Sunday, "watered plants sat" is done last Saturday. A day cue after a done verb means the most recent past day (the Money rule); a done check-in is never in the future.
- An open task beats a new chore (collision rule 5): "cleaned the oven" with an open task "Clean the oven" completes the task. If a chore and an open task both match, both happen in one ghost batch.
- `note` wins, as now: "note watered plants" is a note and resets nothing.
- `<chore> every N` binds only to an existing chore and a day count or week word. A weekday ("bins every thursday") is not an interval; it goes on to the task grammar (see open question 3).
- A number after a bill ("paid rent 650") is kept as the check-in's note, not a spend. Money's `spent` stays the only way to log a spend.
- During a live workout, relative sets run first, so "same", "8" and "80 x5" never touch upkeep.

## Eval phrases (15)

Clock: Thu 15 Oct 2026, 18:00 in the phone's zone (America/Los_Angeles for him), the `grammar-collisions.md` fixtures, plus chores Water plants (every 7, last done Fri 9 Oct, 6 days), Clean bathroom (every 14, last done Thu 24 Sep, 21 days), Laundry (no interval), Pay rent (every 30), and an open task "Clean the oven". A context is idle unless stated. "Model" means the grammar returns nil.

| # | Phrase | Context | Expected |
|---|---|---|---|
| 1 | `watered plants` | idle | chore.done Water plants, 15 Oct; age 0 |
| 2 | `note watered plants` | idle | trap: note "watered plants", no check-in |
| 3 | `watered plants yesterday` | idle | chore.done Water plants, 14 Oct |
| 4 | `watered plants sat` | idle | trap: chore.done Water plants, Sat 10 Oct, not a task |
| 5 | `water plants sun` | idle | trap: task "Water plants", Sun 18 Oct, no check-in |
| 6 | `plants fine` | idle | chore.fine Water plants (age 0, week count unchanged) |
| 7 | `plants every 10d` | idle | chore.interval Water plants 10 |
| 8 | `descaled the kettle` | idle | chore.new "Descale the kettle" + done, "How often?" |
| 9 | `cleaned the oven` | idle | trap: task.complete Clean the oven, no new chore |
| 10 | `cleaned bathroom` | idle | chore.done Clean bathroom ("Was 21 days, usually 14."), no red, no "overdue" |
| 11 | `bins thursday` | idle | trap: task "Bins", Thu 15 Oct (today, per `decisions.md`), not a chore |
| 12 | `did laundry` | idle | trap: chore.done Laundry, not a question |
| 13 | `did i water the plants` | idle | trap: question, no write ("Watered 6 days ago.") |
| 14 | `paid rent 650` | idle | chore.done Pay rent, note "650", no spend, no set |
| 15 | `pause chores till sun` | idle | chore.pause until Sun 18 Oct 00:00, not a task |

As Swift Testing rows, beside `collisionRows`: `.init("watered plants", .idle, "chore.done Water plants 15 Oct")`, `.init("note watered plants", .idle, "note")`, `.init("bins thursday", .idle, "task Bins Thu 15 Oct")`, and so on. The upkeep fixtures are added to the shared eval store.

## Design steers (one per screen)

Shared: light ground, the house paper and washes; Design picks the Upkeep lean in its build sheet. Vermilion only for something running (chores never run), cobalt only for Tess. Never red, never a progress bar filling up. Age is words in tabular figures; staleness shows only as position and ink weight.

**5. Chore page.** The hero is the name. One context line in Body: "watered 6 days ago · usually every 7". The interval is a **day drum**, the reps drum's sibling: turn it to set "every 7 days", release writes `SetChoreInterval`. **Done** is a hold key; **fine** is a single word beside it, calm copy. One level deeper: the gaps between the last check-ins as a row of short rules whose lengths are the gaps (a rhythm, not a streak; fine check-ins drawn hollow), and pause.

**6. Upkeep page.** Not a checklist. One typographic column where vertical position is staleness: fresh chores sit low and faint, and as a chore ages it rises toward a hairline at the top marked "Now", its ink darkening from pale grey to full text weight. Logging done sinks it back to the bottom with a spring and one haptic. Chores with no interval sit in a quiet footnote row. After a holiday the column simply rises together; nothing turns red. The week line "3 chores this week" sits under the hairline on tap. New chore is the ghost row ("watered plants"). Empty state is one cobalt line from Tess: "Tell me what you just did. Try: watered plants."

**7. A chore on Now.** The drifting chore arrives in grey, never vermilion: name in the big tier, "6 days, usually 7" in the second. It slides in from below the Next list as it crosses its interval, and steps above the untimed tasks once it is twice its interval. Hold to log done; the slot settles back without a celebration. A flick down snoozes it to tomorrow.

## Depends on

- M3 slice 2 (`Habit` and check-ins), not on master at `23a0e10`. `Chore` is its child; if Habit slips, slice 1 waits rather than building a second check-in model.
- From master: `ObjectStore`, `SystemCatalog`, the op log and undo, `DeleteObject`, the ghost row and `TessCaptureEngine`, `ActionRegistry`, `NowPicker`, `TaskList`.
- `grammar-collisions.md` rules 1, 2, 5 and 7, and the task-completion parse case (row 12) for eval row 9. If task completion has not landed, eval row 9 falls back to the model, never to a new chore.
- Nothing from Reading or Money is required. The upkeep check sits after them in `TessGrammar.parse`; they share no verbs (`spent` vs `paid`).
- M4 slice 5 (Day log) is not on master. Op summaries ("Watered plants, did laundry") are written now for it.

## Later

Beyond the smallest version, not in this list:
- Weekday-anchored chores ("bins every thursday"), which are recurring tasks, not ages.
- Bills linked to a Money spend ("paid rent 650" offering a spend), once Money lands.
- Places and rooms as objects (`place` stays text in v1), plants as objects with species, Planta-style watering from light and season.
- Shared household rotas, assignees, points, scores.
- Reminders or notifications of any kind, widgets, a Live Activity, Shortcuts and Siri "log a chore".
- The Day log line, once M4 slice 5 lands.

## Decisions (Product took every default, 19:11)

1. **Chore as a Habit child, or its own class?** Default: child of `Habit` (Kaushik's yes in `people-and-upkeep.md` question 3), reusing check-ins; the weekly target is unused for chores.
2. **No interval set: when does a chore drift?** Default: never until three logs give a learned median; until then it shows its age only on the Upkeep page.
3. **"bins thursday" and "bins every thursday"?** Default: both stay tasks (one dated, one recurring later). Upkeep is age since last done, not the calendar.
4. **Does "fine" count in "3 chores this week"?** Default: no. It resets age only.
5. **Where does the chore sit on Now?** Default: one at most, last in the queue from staleness 1, ahead of untimed tasks from 2, never ahead of running or timed items.
6. **New chores from any past-tense verb?** Default: no, only from the fixed verb list; anything else goes to the model, which can call `DoChore` by name.
7. **Upkeep app or Home only?** Default: its own small app, `Features/Upkeep/`, beside Reading and Money on the sibling rail.
