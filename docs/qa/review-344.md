# QA review 344: "PR at the time" flag on the set (Core)

*QA, Oct 16, about 1:20 AM Pacific. PR #344, `core/set-record`, head `fb348f4`, from `d55d29c`. Static review (no
Swift toolchain in the cloud). Trial merges are clean both onto master `19c1dfd` and together with #341. The engine
changes are three files: `TrainingActions.swift`, `SystemCatalog.swift` and `DayStory.swift`, plus a test. The rest
of the diffstat is docs already on master.*

## Verdict: FIX FIRST (one small fix: editing a set must re-decide the flag)

The flag does what Product asked. LogSet decides it once, when the set is logged, against every workout except
this one (`TrainingActions.swift:63-70`). It only writes `wasRecord = true` (`:82-84`). Nothing ever recomputes a
stored flag. The Day log reads the flag first (`DayStory.swift:528, 534-537`), so "Bench 70 × 8, PR." stays after a
later session's 80 × 8 (test `DayStoryTests.swift:147-160`).

Other checks:
- **UNDO.** The flag is set in the same transaction as the set, so undoing the set takes its flag with it.
- **Every set goes through LogSet.** LogNextSet calls LogSet (`Prefill.swift:95`), and no other engine path creates
  a set.
- **Catalog v6 is additive.** One bool field on `set` (`SystemCatalog.swift:159-161`). The seed loop adds missing
  fields at any version, so the second of #341 and #344 to merge can keep `version: 6`; the two edits are the same
  line and merge cleanly.
- **Warm-ups never flag.** Only working sets are compared.
- **Safety.** There are no app changes and no secrets.

### F1. Editing a set leaves the flag as it was

`EditSet` changes the weight, reps and RPE (`TrainingActions.swift:123-141`) but never touches `wasRecord`.
- He says or types a typo, "800 for 8". LogSet flags it as a record. He edits it to 80, and the Day log says
  "Bench 80 × 8, PR." for good.
- It also goes the other way: a set corrected up to a real record never gets the flag.

Typos are the common case with spoken numbers. **Fix:** when `EditSet` changes weight, reps or RPE on a working
set, re-decide `wasRecord` with the same `recordsBeaten(... excludingWorkout:)` read LogSet uses, in the same op.
That keeps UNDO whole. It is still "at the time it was logged", now with the corrected numbers. Add one test: log
800 × 8, edit it to 60 × 8 below an earlier 70 × 8, and the line drops the PR.

## Lows

- **L1. Sets that weren't a record carry no flag, not `false`.** `topSet` falls back to the live records read for
  any top set without a flag (`DayStory.swift:538-541`). So new non-record workouts still pay that read and are
  still recomputed. In practice that only matters if an earlier record set is later deleted. Writing `.bool(false)`
  on working sets would make the "never recomputed" rule hold for every new set, and the fallback would then cover
  only sets from before the field existed.
- **L2. "Before this workout" really means "every other workout"** (`excludingWorkout`). A set logged later for an
  earlier day (#251's "bench 80x8 mon") is also compared against the workouts after it. That's right for "a record
  when he logged it", but the comment at `:65` reads as if only earlier history counts.
- **L3.** Two working sets in one workout that both beat prior history are both flagged. `topSet` shows the best one,
  so the Day log is right. Anything that later counts flagged sets ("2 records this week") would count both.

## Install-day

Nothing to check on the phone until it is in a build. Then: log a set that beats his best, log a bigger one
another day, and look at the first day in the Day log: it still says PR.

## Addendum: re-check at `0cbf423` (Oct 16, about 1:35 AM Pacific): PASS

The delta is `TrainingActions.swift` (+29 / -9) and one test.

- **F1 closed.** `EditSet` re-decides `wasRecord` in the same op whenever weight, reps, RPE or clearRPE changes.
  It reads the set's corrected values back from the store and asks the same `SetRecord.beats` read that LogSet
  uses, against every other workout (`TrainingActions.swift:135-144`, `:562-571`). The set's own workout is
  excluded, so it never compares against its old self. One op means one UNDO restores both the numbers and the
  flag. Test: 800 × 8 → 50 loses the flag; → 80 gains it, and the Day log says PR again.
- **L1 taken.** Every new set writes `.bool(true)` or `.bool(false)` (`:79`), so new sets never fall back to the
  live read. Warm-ups get `false`.
- **L2 comment fixed.** L3 is left, which is fine.
- Safety and the additive catalog are unchanged.
