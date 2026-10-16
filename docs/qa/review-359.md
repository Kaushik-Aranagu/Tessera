# QA review: PR #359, Design 44 part two (routines on fixed days)

Head `2e92f8848cef0136425eac5c85554318d87b1e52` (branch ios/routines-days). Static review; no Swift toolchain here.
Trial merge onto master: clean. 6 files, +392/-16: App/AppModel.swift, Features/Home/TrainingPage.swift,
Features/Plans/PlanData.swift, Features/Plans/RoutineEditor.swift, Features/Plans/RoutinesPage.swift,
docs/recordings/42-routines-fixed-days.mp4.

## Verdict: FIX FIRST (one line), everything else PASS

## Must fix
- **F1 Two haptics per day tap.** DaysLine plays `.tesseraFeedback(.selection, trigger: ticks)`
  (RoutineEditor.swift:451, `ticks += 1` at :490), and its `onChange` closure in the editor also does
  `haptic += 1` (RoutineEditor.swift:111), which fires `.sensoryFeedback(.selection, trigger: haptic)` (:89).
  One moment, two selection ticks. Fix: drop `haptic += 1` at :111 (or drop DaysLine's own feedback).

## What checks out
- Data safety: every write goes through engine actions (SetRoutineWeekdays, SetScheduleMode, CreateRoutine +
  AddRoutineToPlan, MoveRoutineInPlan, DropRoutineFromPlan); no launch flags, no ProcessInfo reads, no project.yml,
  no catalog or migration change.
- `nextRoutine(in:now:calendar:)` gets `now:` everywhere (AppModel.swift:589, PlanData, RoutinesPage `next`,
  tomorrow line with `now: tomorrow`), so fixed days resolve by weekday.
- `onDisappear` guarded by `!model.isWorkoutPresented`.
- DaysLine: "rolls on" / "Pick a day" / "Mon, Thu"; tap opens the week; a pick wets in tess 900 ms then dries;
  the handoff line comes from `WeekdayHandoff.line(to:)`, else a receipt ("Push A on Mondays and Thursdays.").
- RoutinesPage: "Make a routine" = create + add, undoes the create if the add fails, UNDO reverses both; hold 0.35 s
  then drag reorders; swipe left past 90 pt drops, with a VoiceOver action "Drop from the plan" (:336);
  ROLLS ON / FIXED DAYS words; fixed rows read "Mon, Thu · …" / "no days · …"; back word plus
  `.background { EdgeSwipeBack() }` kept (:89-92); one haptic per moment on this page (HapticCue).

## Product's defaults (not in this PR; Core)
- "Drop clears the routine's days": master's DropRoutineFromPlan leaves fixedWeekdays on the routine.
- "Add reconciles a clash newer-pick-wins with the handoff": AddRoutineToPlan does not reconcile.
  Both belong in the engine actions (Core, ties to #341 L1). Impact today is low: the UI has no "add an existing
  routine" path, and a dropped routine is out of the plan so its stale days don't schedule. They bite once a dropped
  routine is re-added. Research 118 T5-T10 should keep a line for each so the gap stays visible.

## Lows
- L1 Device check: hold a row and let go without dragging; it must not also open the routine (the sequenced
  long press sits on a Button, RoutinesPage.swift:289 / :192).
- L2 RoutinesPage tess line `.lineLimit(2)` (:242) can truncate with "…". Its lines are short today
  ("Push A moved."), so low; `fixedSize(horizontal: false, vertical: true)` would remove it.
- L3 Reorder has no VoiceOver path (no move-up/move-down actions).
- L4 UNDO stays until the next change rather than 10 s; matches the editor's existing pattern, flag for Product.
- L5 Switching to FIXED DAYS with no days picked leaves no next routine; the plan's Tess line could say "Pick a day."
- L6 Builder A's known gap: the routine editor still shows the system back chevron.

## Install script
Research 118 T5-T10 apply as written once this is in a pinned candidate; add T11 "hold-release opens nothing"
(L1) and T12 "one tick per day tap" (F1).
