# QA review 341: Design 44 plan actions (Core)

*QA, Oct 16, about 1:10 AM Pacific. PR #341, `core/plan-days`, head `111501a`, from `73a734d`. Static review (no
Swift toolchain in the cloud). Trial merge onto master: clean, 7 files, +472 / -5, engine package only (no app files).*

## Verdict: PASS

The catalog bump to v6 is additive and safe on his existing store. Product's rules hold, and every action is one
op-log row with one UNDO.

## What I checked

1. **Catalog v6 is additive.**
   - Two fields are added:
     - `routine.fixedWeekdays` (text, no default) at `SystemCatalog.swift:173-174`.
     - `plan.scheduleMode` (choice, default `rolling`) at `:193-195`.
   - The version goes 5 → 6 at `:324`.
   - Seeding already adds fields missing from classes seeded by older versions (`SystemCatalog.swift:363-381`). The
     refresh only touches shipped names, options and defaults; it never touches values or objects. Nothing is
     removed or renamed, and there is no migration.
   - The readers default safely, so his existing plans read as rolling and his routines have no days:
     - `PlanSchedule.mode` falls back to `.rolling` on nil or an unknown string (`PlanEditing.swift:236-238`).
     - `weekdays` decodes nil to empty and drops junk (`:42-44`).
2. **Rolling still rolls.** The rolling branch of `nextRoutine` is unchanged (`PlanSchedule.swift:20` on). `WeekView`
   only branches when the mode is `.fixed` (`WeekView.swift:42-44`). Test: switching back to rolling gives "Pull A"
   from the last finished routine (`PlanDaysTests.swift:143-146`).
3. **A missed fixed day does not roll on** (Product 1fdd1c6).
   - In fixed mode, `nextRoutine` returns today's pinned routine, or tomorrow's onward if today is trained. It never
     returns the missed one (`PlanSchedule.swift:11-19`).
   - A past pinned day with nothing done is `.past`, `wasDue` (`WeekView.swift:117-120`).
   - Test: Tuesday's Pull A was missed and Wednesday is rest, so next is Thursday's Push A, and the rest day names
     Thursday (`PlanDaysTests.swift:121-142`).
   - The day comes from `TesseraDay.today`, so 01:00 Friday still reads Thursday's routine, which matches the 04:00
     rule.
4. **One routine per weekday, and the loser is named.**
   - `SetRoutineWeekdays` takes the day off every routine that shares a plan with this one. It returns
     `[WeekdayHandoff]`, whose `.line(to:)` reads "Thursday was Pull A's. Push A has it now." (`PlanEditing.swift:197-217`;
     test `:97-119`).
   - A routine in no shared plan keeps its days (test `:113-118`).
   - Out-of-range days throw.
5. **UNDO.** All five actions write only through `Transaction.set` / `setLinks`, so each is one op. A handoff, which
   writes to two routines, undoes in one step: "One UNDO gives Thursday back" (test `:107-109`). Add, move and drop each
   undo (test `:57-85`). All five are registered in `ActionRegistry.swift:102-112`, so the op log decodes them.
6. **Safety.**
   - No app code, LaunchFlags, ProcessInfo or project.yml changes.
   - The `nextRoutine(in:now:calendar:)` defaults keep the app's three callers compiling unchanged
     (`AppModel.swift:553`, `TrainingPage.swift:270`, `PlanData.swift:21`).
   - No secrets.

## Lows (none block; most land with Builder A's 44 PR 2)

- **L1. A dropped routine keeps its fixed days.** Say Push A is dropped on Thursday, Legs A takes Thursday, and then
  Push A is added back. Two routines now claim Thursday, and `PlanSchedule.routine(on:)` silently picks the first in
  the cycle (`PlanEditing.swift:247-252`). Two fixes would work: `AddRoutineToPlan` could reconcile the days (as a
  handoff), or `DropRoutineFromPlan` could clear them in the same op.
- **L2. The app callers don't pass `now:`.** The three calls above use the real clock and `.current` calendar, not
  `AppClock`. That's harmless today, because the app can't set fixed mode yet. When 44 PR 2 lands, pass
  `AppClock.now` so `-demoTime` and Home agree with the week row.
- **L3. Fixed mode with no days set returns nil.** No routine is next, so Training has no START word. The editor
  should not let FIXED DAYS stand with no days, or should say so in one line. This is Builder A's.
- **L4. The v5 test doesn't open a v5 store.** `aStoreFromCatalogV5ReadsRollingAtV6` checks a fresh v6 store. The
  safety rests on the seeding code (item 1), which I read, not on this test. A fixture that seeds at v5 and then
  reseeds would prove it.
- **L5. Wording.**
  - Clearing every day writes the summary "Push A on no days." (`PlanEditing.swift:24`, `:221`); "Push A has no days
    now." would read better.
  - `AddRoutineToPlan` on a routine already in the cycle moves it but still says "added".
  - Duplicate weekdays (`[5, 5]`) throw rather than collapse (`:200-203`).

## Install-day

Nothing to check on the phone. The engine reads his plan as rolling, and nothing in the app sets fixed days until
Builder A's 44 PR 2.
