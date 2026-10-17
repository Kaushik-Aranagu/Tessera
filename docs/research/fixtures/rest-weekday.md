# Sunday rest on a rolling plan (board item 146)

For: Core, Builder A, QA. Owner: Research lab. Date: Oct 16, 2026 (Pacific). Master `81a9323`, traced by hand,
nothing was run. Builds on `decisions.md` (11:47 am Oct 16: Sunday rest, rolling PPL x2, fixed days ignore it; 3:05 am
planned session beats rest; 2:53 am day marks; 12:56 am "Rest day tomorrow"), `new-feature-phrases.md` (V-T12 to V-T15),
`week-two-monday.md` (Q4 block) and `dst-travel.md` (rule 7). All dates and sessions below are made up.

**Master today, in one line:** `restWeekday` is stored (`TesseraSettings.swift:25`, read at `:81`) and read by nothing
else. On a rolling plan the rest day floats: `week()` spreads 6 sessions over the days left (`WeekView.swift:56-61`,
`spread` at `:130-138`), so a fresh Monday puts rest on **Thursday**, not Sunday (6 over 7 days lands on index 3).

## Rules

- **RW1, reader (decided, shape proposed).** On a rolling plan, `restWeekday` (1 to 7, Sunday = 1) is rest in `week()`:
  that day is `isRest`, `planned` nil, and is taken out of the pool before `spread`, ahead and past. Default proposed:
  it applies even when no rhythm is passed, so callers without `sessionsPerWeek` still see Sunday as rest. Nil keeps
  today's floating rest.
- **RW2, the roll skips Sunday (decided: rolls on).** `nextRoutine` is unchanged (the routine after the last finished
  one), so Sunday only moves the next session to Monday. Sunday is never `wasDue`, so Review never rings it.
- **RW3, trained anyway on Sunday (Default proposed).** It logs normally, Sunday's mark is "trained", and the roll
  advances (Monday gets the routine after it). The week reads its real count ("7 sessions"), never "7 of 6".
- **RW4, a planned session beats rest (decided 3:05 am).** A workout scheduled for Sunday with a time makes Sunday a
  training day: hero "Push A at 5 pm" with START, never "Rest day" beside it.
- **RW5, 4 am boundary (decided).** Sunday runs 4:00 am Sunday to 4:00 am Monday. Sunday 1:00 am is Saturday;
  Monday 2:00 am is still Sunday's rest.
- **RW6, a day mark elsewhere (decided 2:53 am).** "rest day today" on a weekday marks that day only and never writes
  `restWeekday`. The marked day's routine rolls to the next training day, Sunday stays rest, so the week ends at 5.
- **RW7, travel (Default proposed, per `dst-travel.md` rule 7).** "Is today Sunday" reads the phone's zone now.
  A finished workout keeps the day where he was (`OpZones`), so a hotel-gym Sunday stays Sunday once home (RW3).
- **RW8, wording (Default proposed).** No new words on the day: Now keeps the decided rest hero ("today" / "Rest day"
  / "Push A is a tap away."), Home's row "Rest day.", Saturday's done label "Rest day tomorrow". "Sunday, rest day."
  is only the receipt for setting it (thing first, 3:15 am). Widgets: none on master but the rest-timer Live
  Activity; any later widget reads `restDay`.
- **RW9, week view and Review (decided).** Sunday is the rest dab on Review, the Plans week and WeekFacts; never the
  miss ring, never "missed" in words.
- **RW10, a change mid-week (Default proposed).** It applies from today on: days ahead re-spread at once; past days
  keep the marks they had (see ★).
- **RW11, clearing (Default proposed).** "Any" in Settings, or UNDO, sets nil: the floating rest returns from today.
- **RW12, fixed days ignore it (decided).** A FIXED DAYS plan's unpinned day is rest; a pinned day trains even when
  it is the rest weekday (`WeekView.swift:109-124` already never reads it).
- **RW13, setting it (Default proposed).** Tess "rest day Sunday" or "make Sunday my rest day" writes `restWeekday`
  = 1 after Core's grammar change: "Sunday, rest day." with a 10 s UNDO. Settings gets a Rest day row (Sun to Sat,
  Any). On the first launch carrying the reader, one op writes 1 with the same receipt (Q4 block).

## Scenarios (PDT unless marked; PPL x2: Push A, Pull A, Legs A, Push B, Pull B, Legs B; `restWeekday` = 1)

| # | When | Before | Expected Now / Home | Expected next session | Master today |
|---|---|---|---|---|---|
| S01 | Fri Oct 16, 8:00 pm | Says "rest day Sunday" | "Sunday, rest day." with UNDO; no task | Unchanged | Task "Rest day", Sunday (`TessGrammar.swift:490`; phrases V-T12) |
| S02 | Fri Oct 16, 8:00 pm | Says "make Sunday my rest day" | As S01 | Unchanged | Task "Make my rest day" (phrases V-T13) |
| S03 | Fri Oct 16, 8:00 pm, 6 s after S01 | Taps UNDO | `restWeekday` nil; floating rest back | Unchanged | No write to undo |
| S04 | First launch on the reader build | `restWeekday` empty | One op: "Sunday, rest day." with UNDO | Unchanged | No such op |
| S05 | Mon Oct 19, 7:00 am | Legs B Sat, rested Sun | Push A hero | Push A today; Mon to Sat train, Sun rest | Thu rest, Sun trains (`WeekView.swift:60`, `:136`) |
| S06 | Thu Oct 22, 7:00 am | Mon to Wed done | Push B hero | Push B | "Rest day", "Push B is a tap away." (`spread` drops Thu after Wed, `:132`) |
| S07 | Sat Oct 24, 6:30 pm | Legs B finished | "Legs B done."; label "Rest day tomorrow" | Push A, Mon Oct 26 | Same, by accident (Sun due 0; `TrainingPage.swift:253`) |
| S08 | Sun Oct 25, 1:00 am | S07 | Still Saturday: "Legs B done." | Push A, Monday | Same (`TesseraDay.swift:24`) |
| S09 | Sun Oct 25, 10:00 am | Mon to Sat done | "today" / "Rest day" / "Push A is a tap away." | Push A, Monday | Same, by accident (`RestDay.swift:25`, `:29`) |
| S10 | Mon Oct 26, 2:00 am | S09 | Still Sunday: "Rest day" | Push A | Same, by accident |
| S11 | Thu Oct 22, 7:00 am | Mon, Tue done; Wed nothing | Legs A hero | Legs A Thu, Push B Fri, Pull B Sat; Legs B Mon Oct 26 | Sun trains Legs B (4 due over 4 days, `:131`) |
| S12 | Sun Oct 25, 9:00 pm | S11 week, 5 done | Review: Wed ring, Sun rest dab; "5 sessions" | Legs B, Monday | Sun is due Legs B, so drawn planned, not rest (`ReviewPage.swift:134-135`) |
| S13 | Wed Oct 21, 7:30 am | Says "rest day today" | "Rest today"; "Legs A waits for tomorrow"; no START | Legs A Thu; Legs B Mon | Task "Rest day", today (phrases V-T15) |
| S14 | Sun Oct 25, 10:00 am | Mon to Sat done; starts Push A | Running wins; then "Push A done." | Pull A, Mon Oct 26 (RW3) | Same roll (`PlanSchedule.swift:29-30`) |
| S15 | Sun Oct 25, 9:00 pm | S14 | Review: Sun "trained"; "7 sessions" | Pull A | Same |
| S16 | Sun Oct 25, 10:00 am | Push A scheduled 5:00 pm | Hero "Push A at 5 pm", START | Push A today | Now "Rest day" (`RestDay.swift:23`, scheduled ignored `:35-36`); Home drops rest (`HomeLines.swift:578`) |
| S17 | Sun Oct 25, 9:00 am | Says "rest day Sunday" (already 1) | "Sunday, rest day." no new op | Push A, Monday | Task "Rest day", Sunday |
| S18 | Mon Oct 19, 9:00 am | Plans page week | Sun drawn as rest | Mon to Sat routines | Sun shows Push A: no rhythm passed (`PlanData.swift:46`; `WeekView.swift:53-55`) |
| S19 | Sun Oct 25, 7:00 am | Plan my day | Pack `rest: true`; "Rest day." row first | Push A, Monday | Workout block on Sunday: no rhythm passed (`DayPlan+Store.swift:60`) |
| S20 | Wed Oct 21, 8:00 pm | Mon to Wed done; Settings to Saturday (7) | Wed unchanged | Thu, Fri, Sun train; Sat rest | No Settings row; no reader |
| S21 | Wed Oct 21, 8:00 pm | Mon to Wed done; Settings "Any" | Wed unchanged | Same as a store that never had a rest day (the spread decides which day floats; Thu rest is the expected spread, 3 left over Thu to Sun) | Already floating |
| S22 | Mon Oct 19, 7:00 am | FIXED DAYS Mon Push A to Sat Legs B; `restWeekday` 5 | Push A (Thu still Push B) | Sun rest (unpinned) | Same (`WeekView.swift:42-45`) |
| S23 | Sun Oct 25, 11:00 pm EDT (8:00 pm PDT) | In New York, Mon to Sat done | "Rest day" | Push A, Monday | Same, by accident |
| S24 | Mon Oct 26, 4:30 am EDT (1:30 am PDT) | In New York | Monday where he is: Push A | Push A | Push A (zone now, `Calendar.current`) |
| S25 | Sun Oct 25, 7:00 am EDT | Hotel gym Push A; home Mon 8:00 am PDT | Review: Sun "trained" | Pull A | Sunday kept (`WorkoutSummary.swift:97-104`) |
| S26 | Sun Nov 1, 1:30 am PST (second 1:30) | Legs B Sat Oct 31 | Still Saturday | Push A, Mon Nov 2 | Same (wall clock, `TesseraDay.swift:3-5`) |
| S27 | Sun Nov 1, 10:00 am PST | Mon to Sat done | "Rest day" (25-hour day, one rest) | Push A, Monday | Same, by accident |

## Gaps

| # | Gap | Where | Default proposed | Owner |
|---|---|---|---|---|
| RG1 | No reader: Sunday floats (S05, S06, S11, S12) | `WeekView.swift:34-104`, `RestDay.swift:20-30` | RW1: take `restWeekday` out of the pool before `spread`, ahead and past; `isRest` true | Core |
| RG2 | Callers without a rhythm see no rest at all (S18, S19) | `PlanData.swift:46`, `DayPlan+Store.swift:60` | RW1 applies with no `sessionsPerWeek`; or pass `NowPage.sessionsPerWeek` | Core, Builder A |
| RG3 | "rest day Sunday" makes a task (S01, S02, S17) | `TessGrammar.swift:490` | SetRestWeekday before `parseTask`; "Sunday, rest day." with 10 s UNDO | Core |
| RG4 | No Settings row (S20, S21) | `Features/Settings/` (no hit) | Rest day row, Sun to Sat and Any, one op each | Builder A |
| RG5 | Scheduled Sunday session: Now says rest, Home drops rest (S16) | `RestDay.swift:23`, `HomeLines.swift:577-579` | `restDay` returns nil when `plannedSession(on:)` has one | Core |
| RG6 | Day mark not built (S13) | grammar, WeekFacts | As decided 2:53 am; never writes `restWeekday` | Core |
| RG7 | Mid-week change rewrites past marks (S20) | `WeekView.swift:69-92` | Read the value in force that day from the settings op | Core ★ |

★ **Product:** when he changes his rest day, do past weeks keep their marks (read the value in force from the
settings op log, RW10), or redraw with the new day? Recommend keep: a past rest Sunday never turns into a ring.

QA guard rows: S05, S06, S11, S16 and S18 must differ from "Master today" once RG1 to RG5 land; S07 to S10 must not move.

**Decided (Product, decisions.md 11:52 AM PT Oct 16):** Core builds RG1, RG2, RG3, RG5 and RG7 to this fixture (past weeks keep their marks; RG2's Plans view cc Builder A). Builder B adds the Settings row "Rest day: Sunday." (RG4). Both defaults are yes: the first launch writes Sunday as one op with UNDO, and a session trained on Sunday advances the roll.
