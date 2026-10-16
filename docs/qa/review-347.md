# QA review 347: Training matched rise, plus Design's #337 fixes (Builder A)

*QA, Oct 16, about 1:25 AM Pacific. PR #347, head `37d0155`, from `7b321d2`. Static review (no Swift toolchain in the
cloud). Trial merges are clean both onto master and together with #342 at `9281b0d`. 4 Swift files, plus a clip
(`40-training-rise.mp4`, 8.5 s, 590×1282) and a still. Design judges the motion.*

## Verdict: FIX FIRST (one line: Routines lost the edge swipe back)

### F1. The Routines page can't be swiped back

`RoutinesPage` now hides the system back button for its "‹ TRAINING" word (`Features/Plans/RoutinesPage.swift:56`).
Hiding it also turns off UIKit's edge-swipe pop. The app already has the fix for exactly this, QA K1:
`.background { EdgeSwipeBack() }`, which Backup uses at `Features/Backup/BackupView.swift:155`. Add the same line to
RoutinesPage.

## Checked and fine

- **START fires once.**
  - `tapMark` guards on `!isLifting` and `startTask == nil` (`TrainingPage.swift:349`).
  - The sequence is one stored task that re-checks `isCancelled` after each sleep, and `onDisappear` cancels it.
    This closes review-337 L3.
  - Under Reduce Motion, `start()` runs at once with no wait, which closes L2. `workoutRisesFromLane` is false
    then, so the cover takes the plain presentation.
- **Rest day tomorrow** closes L1. On a done day the label reads the same rest-day rule Now uses
  (`NowPicker.restDay` at tomorrow noon, sessions per week from `NowPage`), and otherwise falls back to
  "*Next* tomorrow". The other 16 pt detail line now uses `Theme.voice(size: 16)`, which closes L4.
- **Tess's slot is fixed.** It keeps two lines' height whether or not Tess has a line, so the plan line and the
  ROUTINES word never move (`TrainingPage.swift:128-143`).
- **The matched rise.**
  - The first lane is the zoom source. The cover uses the same `zoom` namespace RootView hands down
    (`RootView.swift:32, 59-63`).
  - The other lanes, the plan line and Tess's slot sink to 0.96 and fade.
  - Dismissing the cover restores `sinking` and clears the flag (`TrainingPage.swift:161-166`).
- **One view for every state.** `source` keeps START's flight alive across the switch to running.
- **Data safety.** No LaunchFlags or ProcessInfo reads, no new store writes (START still calls
  `startRoutine` / `startWorkout`), no project.yml change. No secrets.

## Lows

- **L1. A cancel inside the last 160 ms can leave the plan invisible.** `onDisappear` sets `startTask = nil` before
  the task wakes. The task's `reset()` then sees `startTask?.isCancelled` as nil and leaves `sinking` true
  (`TrainingPage.swift:157-160, 396-399`). If he swipes off Training in the 160 ms between the sink and the cover,
  he comes back to just the first lane. Fix: make the cancel path set `sinking = false` itself (for example
  `reset(cancelled: true)`). The window is tiny.
- **L2. Tess's line is capped at two lines** (`:138`). At large Dynamic Type a long line ends in "…", which breaks
  the no-"…" rule. Another approach: keep the reserved height, but let the line grow, or fall back to a shorter line.
- **L3. `workoutRisesFromLane` is cleared only by Training's view.** Say the cover closes while Training isn't
  mounted. The next cover opened from elsewhere tries to zoom from a source that isn't on screen, and SwiftUI falls
  back to the plain cover. That's harmless, but clearing the flag in `isWorkoutPresented`'s `didSet` would be
  tidier.

## Install-day

#347 is not in the pinned candidate (`7b321d2`), so T3 in the script stays a "known gap". When #347 is in a later
build:
- T3 expects "Rest day tomorrow" on a rest eve.
- Add "edge-swipe back from Routines" to T2.
