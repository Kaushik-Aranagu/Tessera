# QA: v1 engine gaps, PR #122 (master 1aa9565, head 237ac14)

*Repo maintainer (QA), 2026-10-15 22:45 UTC. Static read, engine-only.* **PASS.**

- **RemoveSlot** (RoutineEditing.swift):
  - It soft-deletes the slot and re-indexes the siblings 0..n-1. Both ops are in the transaction, so Undo restores the slot and its order.
  - Past and running workout entries keep their `slot` link to the soft-deleted record. Prefill (Prefill.swift:62) and the swap carrier (ExerciseOverview.swift:77) still read it, which is harmless because a soft delete keeps the values.
  - It's registered in ActionRegistry and marked in-app only in the Intents catalog, with `isDestructive: true`.
- **EditSet clearRPE:**
  - `rpe` together with `clearRPE` throws.
  - Otherwise `clearRPE` sets rpe to nil.
  - Validation is unchanged.
  - The app's `saveEdit` still passes `rpe: rpe`. Clearing RPE from the dial needs the app to send `clearRPE: true` when the dialled rpe is nil and the row had one. That's a follow-up for iOS build: today, turning effort off on an edit leaves the old RPE.
- **Rest days in `week(containing:)`:**
  - The sessions still due (`perWeek − days done`) are spread over the days ahead, today first. The formula `round(i·(left−1)/(due−1))` gives distinct, ascending indexes whenever due < left, and the case due ≥ left means every day trains.
  - `isRest` is only set when a cycle exists.
  - Behavior changes for existing callers with no new argument: `sessionsPerWeek` falls back to the plan's own field. On PPL×2 (6 a week) the strip now shows rest days mid-week.
- **exerciseGroups:**
  - Patterns come in library order and exercises by name. A "Yours" group catches the rest, and empty groups are dropped.
  - `descendants(of:).dropFirst()` assumes the pattern itself comes first (it does in ClassResolver).
- **"Up X kg from last time":** the copy change is fine.

## Lows
- E1: `saveEdit` doesn't pass `clearRPE` (see above).
- E2: a rest day can disagree with Home. If `week()` marks today as rest, NowPage/`nextRoutine` still offers the next routine as today's. Home should check `isRest` for today, or that's a Product call.
- E3: `exerciseGroups` keeps only leaf classes (`subclasses.isEmpty`). If he ever makes a variant under an existing exercise, the parent exercise drops out of the picker. Library exercises are all leaves today.
- E4: a plan whose `sessionsPerWeek` is 0 makes every day ahead a rest day. That's probably right, but there's no test for it.
