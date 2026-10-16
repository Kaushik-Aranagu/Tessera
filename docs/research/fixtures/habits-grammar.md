# Habit phrases (board item 70)

For Core (`TessGrammar`) and Builder B (habits). Research lab. Date: 2026-10-16.

Thirty phrases that create, tick, pause, resume or delete a habit, typed to Tess, with the parse each should give
under the 7:34 PM PT M3 call (`m3-lines.md` defaults taken, "new habit {name} {n} a week" added to Core's grammar
batch) and the defaults proposed below, and what master does today. They are folded into `grammar-regression.md`
as group L (L819 to L848), one row each.

**Master read:** `origin/master` at `bf28a92` (Merge PR #208). The grammar is `aec9ccd`'s (PR #205 added the
live-workout guard, `TessGrammar+Live.swift`; nothing in `TesseraTess` changed after it). Only L836 has an entry in
focus, so the guard touches no other row here. Master has no habit code at all: no `Habit` or `HabitCheckIn` class,
no `CheckInHabit` action, no habit rule in the grammar and no model tool for it (`m3-1-2-brief.md` section 1 still
holds). So every habit target is gated on the Habits slice, and the status judges what master must do until then
(the "now" parse). No Swift toolchain here: every result is a hand trace. Nothing was run. "TG:n" is
`TesseraCore/Sources/TesseraTess/TessGrammar.swift` line n on `bf28a92`, "K:n" is `TessGrammar+Kitchen.swift`, "LV:n" is `TessGrammar+Live.swift`.

## Contexts

All rows run on Thu 15 Oct 2026 18:10 America/Los_Angeles, as the suite does. The habit week is Mon 12 to Sun 18.
- **none**: the suite's misfires store (open tasks Dentist Sat 17 10:00, Call mom, Clean the oven; five recipes;
  no people), no habits.
- **habits**: the misfires store plus seven habits. Read (target 5; Mon 12 and Wed 14 in, so 2 of 5), Meditate
  (3; none in), Yoga (2; Tue 13 in, 1 of 2), Run (3; none in), Call mom (1; none in; the open task "Call mom" stays),
  Milk (7, a glass before bed; none in) and Train (3, rule `workout`; the Tue 13 workout fills it, 1 of 3).
- **read paused**: as habits, with Read's week of Mon 12 paused.
- **live workout**, **shop run**: the suite's own (Bench Press in focus, last set 80 x 8; Groceries running).

## The rows

| id | phrase | context | expected parse | decision: reason | master (hand trace) | status | root cause | gate |
|---|---|---|---|---|---|---|---|---|
| L819 | `new habit read 5 a week` | none | CreateHabit(Read, 5), "Read added, 5 times a week." | H734: m3-lines A1; the 7:34 PM call adds the rule | nil: `parseLift` has a weight (5) and no reps (TG:309-311); `new` is no past verb (TG:204); not `new list` (K:24); no day, so no cook (K:112) and no task (TG:442) | pass | - | Habits |
| L820 | `new habit meditate` | none | CreateHabit(Meditate, 3), "Meditate added, 3 times a week." | H734: A1, no count is 3 | nil: no number (TG:311), no day (TG:442) | pass | - | Habits |
| L821 | `new habit yoga twice a week` | none | CreateHabit(Yoga, 2) | HP1: `twice` is 2 | nil: no digits, no day (TG:311, TG:442) | pass | - | Habits |
| L822 | `new habit read 5 a week from monday` | none | CreateHabit(Read, 5), counted from this week (`from monday` read and dropped); never a task | HP1 | task "New habit read 5 a week from" Mon 19 09:00: no reps (TG:311); `monday` is a day (TG:525), so the cook rule finds a date but no recipe (K:110-117) and the task rule keeps `from`, which is no lead word (TG:490) | wrong write | HABW | Habits |
| L823 | `new habit read 8 a week` | none | nil (a target past 7: the model asks; never set to 7) | HP1 | nil: weight 8, no reps (TG:311) | pass | - | - |
| L824 | `new habit read 4 a week` | none, habits | SetHabitTarget(Read, 4), "Read now 4 times a week." (never a second Read) | HP2: m3-lines A12 | nil: as L819 | pass | - | Habits |
| L825 | `new habit bench 2 a week` | none | CreateHabit(Bench, 2), manual (the prefix makes it a habit; no exercise link, the rule is set on the page) | H734, HP1 | nil: weight 2, no reps (TG:311); the exercise is never resolved without reps | pass | - | Habits |
| L826 | `read` | none, habits | CheckInHabit(Read), "Read, 3 of 5 this week." | H734: A2, an exact name | nil: no number (TG:311), no day (K:112, TG:442) | pass | - | Habits |
| L827 | `habit read` | none, habits | CheckInHabit(Read), "Read, 3 of 5 this week." | H734: A2, explicit prefix | nil: `habit` is no task lead (TG:422), no day | pass | - | Habits |
| L828 | `✓ read` | none, habits | CheckInHabit(Read), "Read, 3 of 5 this week." | H734: A2 | nil: `✓` is a symbol, so `normalize` keeps it (TG:461); no day | pass | - | Habits |
| L829 | `read 20 pages` | none, habits | CheckInHabit(Read), the amount not stored in v1 | H734: A2; m3-1-2-brief section 4 | nil: weight 20, no reps (TG:311); a bare `20` is no clock time (TG:533) | pass | - | Habits |
| L830 | `read today` | none, habits | CheckInHabit(Read) Thu 15, "Read, 3 of 5 this week." · now: task "Read" Thu 15 19:00 | HP3 | task "Read" Thu 15 19:00: no recipe (K:117); `today` with no time takes the next whole hour (TG:593-598), which T647 turns into "no time" once N1 lands | pass | - | Habits |
| L831 | `meditated` | none, habits | CheckInHabit(Meditate), "Meditate, 1 of 3 this week." | H734: A3, the past form | nil: a past verb with no day is no log (TG:210-212); no day for a task | pass | - | Habits |
| L832 | `meditated` | none | nil (no such habit: it falls through, the model) | H734: A15 | nil: as L831 | pass | - | - |
| L833 | `meditated yesterday` | none, habits | CheckInHabit(Meditate) Wed 14 · now: note "Meditated" Wed 14 12:00 | HP3, C2 | note "Meditated" Wed 14 12:00 (TG:208-216, TG:615-617) | pass | - | Habits |
| L834 | `did yoga` | none, habits | CheckInHabit(Yoga), "Yoga done for the week." (2 of 2) | H734: A4; O410 (`did` narrowed) | nil: `did` leads a question (TG:110, TG:64) | pass | - | Habits, did narrowed |
| L835 | `run` | none, habits | CheckInHabit(Run), "Run, 1 of 3 this week." | H734: A2 | nil: no number, no day | pass | - | Habits |
| L836 | `run` | live workout, habits | nil (in a running process only `habit X` or `✓ X` checks in; a bare name goes to the model) | HP5 | nil: the workout claims only `rest`/`timer N` (TG:133); the live guard finds no set shape and lets it fall through (LV:71-72); no number (TG:311) | pass | - | - |
| L837 | `ran 5k yesterday` | none, habits | CheckInHabit(Run) Wed 14 · now: note "Ran 5k" Wed 14 12:00 | HP3, HP4, C2 | note "Ran 5k" Wed 14 12:00: `ran` is a past verb (TG:196); `5k` is no number or unit (TG:343-345) | pass | - | Habits |
| L838 | `run 5k sat` | none, habits | task "Run 5k" Sat 17, no time, alerts F (a future day is a plan, never a check-in) · now: task "Run 5k" Sat 17 09:00 | HP3, N620, R630 | task "Run 5k" Sat 17 09:00 (K:117 no recipe; TG:433-447) | pass | - | N1 |
| L839 | `call mom` | none, habits | nil (a habit and an open task share the name: check-in or to-do is unclear; the model) | HP6 | nil: no day (TG:442) | pass | - | - |
| L840 | `called mom` | none, habits | CheckInHabit(Call mom) + SetTaskDone("Call mom") in one ghost row, "Call mom done for the week." · now: nil | HP6, P434 (one ghost row), A005 | nil: a past verb with no day (TG:211); no day for a task | pass | - | Habits, People |
| L841 | `milk` | none, habits | CheckInHabit(Milk), "Milk, 1 of 7 this week." · now: nil | H734: A2, an exact name | nil: one bare word is no grocery outside a shop run (K:40-66) and no task (TG:442) | pass | - | Habits |
| L842 | `milk` | shop run, habits | groceries [milk] (the shop owns bare input; never a check-in) | HP5, MB | groceries [milk] (TG:136-153) | pass | - | - |
| L843 | `pause read` | none, habits | PauseHabitWeek(Read, Mon 12), "Read paused this week." | HP7: m3-lines A10 | nil: no number, no day | pass | - | Habits |
| L844 | `pause read till monday` | none, habits | PauseHabitWeek(Read, Mon 12) (the pause ends with the week); never a task | HP7 | task "Pause read till" Mon 19 09:00: `pause` is no reschedule verb (TG:158), `monday` is a day (TG:525) | wrong write | HABW | Habits |
| L845 | `resume read` | none, habits, read paused | ResumeHabitWeek(Read, Mon 12), "Read back on this week, 2 of 5." | HP7: m3-lines A11 | nil: no number, no day | pass | - | Habits |
| L846 | `skip read today` | none, habits | nil (habits have no skip: an empty day is already blank, `habits.md`; never a task) | HP7 | task "Skip read" Thu 15 19:00 (TG:433-447, TG:593-598); `skip` only stops a grocery line (K:151) | wrong write | HABW | - |
| L847 | `delete habit read` | none, habits | DeleteObject(Read) with its check-ins, "Read deleted.", 10 s undo | HP7: m3-lines A13 | nil: no number, no day | pass | - | Habits |
| L848 | `habit sing` | none, habits | nil (no habit Sing: it falls through, never creates one) | H734: A15 | nil: no day (TG:442) | pass | - | - |

**Totals:** 30 rows: 27 pass, 3 wrong write, 0 miss. 22 are gated on Habits (one also on People, one also on `did`
narrowed), 1 on N1 only (L838), 7 not gated.

| root cause | what goes wrong | rows | wrong write | miss |
|---|---|---|---|---|
| HABW | a habit phrase with a day word (`skip read today`, `pause read till monday`, `new habit ... from monday`) falls through to the task rule | 3 | 3 | 0 |

## Worst wrong writes

1. **`skip read today` (L846)**: a task "Skip read" for 19:00 tonight. It is the one row that stays wrong after
   Habits lands unless the skip guard ships with it, because the target is nil, not a habit action.
2. **`pause read till monday` (L844)** and **`new habit read 5 a week from monday` (L822)**: a task dated Mon 19 with
   the habit words as its title. Both turn into the right write once the habit rules run before `parseTask`.

Everything else falls to the model today, which has no habit tool, so at worst nothing is written.

## Proposed defaults (HP1 to HP7, for Product; none writes where master does not)

- **HP1 Counts.** `new habit X n a week`, `n times a week`, `once`, `twice`, number words one to seven and `every
  day` (7) set the target; no count is 3 (A1). A target of 0 or past 7 goes to the model, never clamped. A start
  day (`from monday`) is read and dropped: the habit counts from this week. The name is whatever is left, even an
  exercise (`bench`); the grammar never sets a rule.
- **HP2 Existing name.** `new habit X n a week` for a habit that exists changes its target ("Read now 4 times a
  week.", A12); with no count, or the same count, nothing is written and Tess says "Read is already a habit, 5
  times a week.".
- **HP3 Days.** `today` checks in today. A past day in this week (`yesterday`, a weekday back to Monday) checks in
  that day; a day before Monday goes to the model (no backfill, `habits.md`). A future day (`run 5k sat`) is a plan:
  the task rule, never a check-in.
- **HP4 Past forms.** Regular past and -ing forms are derived (`meditated`, `meditating`); irregular ones come from
  a short table (`ran` Run, `swam` Swim, `rode` Ride, `read` Read, `did X`).
- **HP5 Running process.** While a workout, cook or shop run is in front, only `habit X` and `✓ X` check in; a bare
  name belongs to the process (rule 3) or the model.
- **HP6 Shared names.** A habit name that is also an open task's title: the bare name goes to the model; a past form
  (`called mom`) checks in and ticks the task in one ghost row, as P434 does for a chore and a spend.
- **HP7 Pause, resume, skip, delete.** `pause X` and `skip X this week` pause this week; `pause X till <day>` pauses
  this week (the pause ends with the week); `pause X next week` pauses Mon 19. `resume X` and `unpause X` undo it.
  `skip X today` writes nothing and is never a task. `delete habit X` and `remove habit X` delete with a 10 s undo
  (A13), only with the word `habit` (`delete read` goes to the model).

Placement for Core (from `m3-1-2-brief.md` section 4, extended): after `parseForProcess` and before
`parseRelativeSet`: `new habit`, `habit X` and `✓ X`, `pause`/`resume`/`skip`/`delete habit`, then the name rule
(exact, past, -ing, name plus a quantity, name plus a day). The name rule only runs with no process in front (HP5),
and the question guard needs `did` narrowed (as for Upkeep) before `did yoga` can reach it.
