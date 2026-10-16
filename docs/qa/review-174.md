# Review #174 (merged dc1285a) — Now rest-day hookup: E5 CLOSED, GO for install at dc1285a

Static review only. Checked against E5 in review-132.md (the week page showed a rest day while Now offered the routine).

## E5: closed
- NowPage now calls `NowPicker.rank(RankContext(now, plan, sessionsPerWeek, incumbent, lastAction, daysAway))` with
  the full context. Precedence comes from the ranker: running → timed task within 15 min → rest day → re-entry →
  score.
- The Rest day hero shows when `top.item.kind == .rest`. A running workout is still checked first, so it always wins.
- The rhythm matches the Plan page: both use `PlanRhythm.perWeek(cycleCount:)` on the plan's linked routines, so
  the week page and Now agree on which day is rest. HomeRestDayTests pins that the seeded PPL x2 plan (6 a week)
  has a rest day.
- The incumbent is fed back through `onChange(of: top?.id)`. Pick.id is item.id, so the +15 hold applies to the
  current Now on the next render. This closes my #147 note.
- "Start Push" on the rest hero uses InkLabelWordStyle, so no button shape. It starts the routine, which then shows
  as RunningHero.

## S1 (from review-151): closed
`.onDisappear { if holding { grab(false) } }` on QueueRow.

## Lows
- N6 NowPage.swift:24: rank() runs inside body on every render, including TaskList.load, the lastAction op-log
  read and daysAway. That's fine at today's data sizes. If Home ever stutters, cache it per revision and minute.
- N7 NowPage.swift:369: the old RoutineHero doc comment ("Nothing else on…") now sits stacked above RestHero's
  own comment. Cosmetic.
- When the ranker's top pick isn't a task (a process or an offer), Now falls back to model.currentTask. That was
  the behaviour before this PR, so it's not a regression.

## Combined master dc1285a: GO
#146, #147, #151, #153 and #174 all pass. No blockers are open. Before install:
1. Run the full scripts/test.sh on the Mac (TesseraCore changed). The only accepted failure is
   TaskTests.todayCarriesOverUndoneWorkWithoutCallingItOverdue. It is clock-dependent and fails after about 4 PM;
   Core is pinning it, and it predates these PRs. Any other failure means NO-GO.
2. Run the TesseraUITests scheme once (HomeQueueUITests, the real-touch Q1 check).
3. Phone smoke: flick across a Today row (it pages and no task finishes); press, then drag a row (it finishes, with
   Undo); Now on a rest day shows "Rest day" with Start <routine>; type "watered plants yesterday" (it makes a
   note, "Noted for …").
