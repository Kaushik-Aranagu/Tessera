# Review 337: Training page at rest, START lift, RESUME, Routines (Design 44 part one)
PR #337 (ios/training-mode) at 88c22e3, on bec22bc. Trial merge onto master c34aac1 clean. 6 Swift files (TrainingPage.swift +701/−246 net rewrite, new RoutinesPage.swift, a `Route.routines` case wired through AppModel, ExerciseRouting, ObjectPage and RecipePage) plus clips 37 (60 fps, 10.8 s) and 38. Static review, Oct 16 PT.

**Verdict: PASS.** The look is Design's (they review 37/38 and the three declared deviations).

## Data safety: PASS
- No `ProcessInfo` or `CommandLine` reads, no LaunchFlags, no UI tests added, `project.yml` untouched.
- No migrations, catalog or schema changes. `Route` isn't persisted anywhere (no SceneStorage or Codable), so the new `.routines(UUID)` case is in-memory navigation only. Every `switch` over `Route` handles it (AppModel title, ExerciseRouting, ObjectPage, RecipePage).
- Writes: the only write is START, which calls the existing `model.startRoutine` / `model.startWorkout`. RESUME only presents the running session. The Routines page is read-only (taps open the routine). The DONE state shows a label only.

## Behaviour checks
- **START** (`tapMark`, TrainingPage.swift:300-320): `guard !isLifting` plus `landed` turn the mark into `.running`, so taps during the 520 ms lift or the 420 ms pause can't start twice. One `.made` haptic per tap (`liftTaps`), through `.tesseraFeedback`. The animation goes through `withTesseraAnimation(..., reduceMotion:)`.
- **RESUME:** `.paused("Resume …", done/total)` fills the line to sets done over target sets (0 when there's no target), and the tap just presents live mode.
- **Done:** "<next> tomorrow" from `ledger.nextRoutine(in:)`, else "Done for today".
- **Minutes:** `about(sets:)` gives 2.5 min per set rounded to 5, min 5, and "about 1 h" on whole hours. Declared; Design's call.

## Lows
- L1: "<next> tomorrow" doesn't know his rest day. On the evening before his rest weekday, it names tomorrow's routine though tomorrow is Rest day, and with a missed day rolling on, the next routine isn't always tomorrow. If Product wants it exact: say "Rest day tomorrow" when tomorrow is his `restWeekday`, else "<next> tomorrow". Product and Design's call.
- L2: with Reduce Motion on, START still waits 940 ms (520 + 420) with nothing moving. Under Reduce Motion, start after a short beat (or at once).
- L3: the START task isn't cancelled if he leaves the page in those 940 ms, so the workout still starts. That matches one tap, one start, so it's fine, but `isWorkoutPresented` then rises over whatever page he went to.
- L4: RoutineRow's detail uses `.font(.system(size: 16))` rather than a Theme text role. Design's call.

## Not mine (declared, for Design)
Strip under the tabs; live mode as a full-screen cover with no zoom match yet; minutes at 2.5 per set.
