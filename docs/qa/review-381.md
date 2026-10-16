# QA review: #381 live workout on the new frame (Builder A, ios/live-workout, Design 56)

Head `bdb178c`, based on 21f406d. The trial merge onto master `0bff60b` is clean. The PR changes three Swift files
in Features/Workout (+158 / -66) and adds the clip docs/recordings/44-live-workout-frame.mp4 (40 s). This is a static
review plus a contact sheet of the clip at 1 fps. Design reviews the clip in parallel.

## Verdict: FIX FIRST

There are two fixes, both on the new "LOG … AND FINISH" hold, plus a re-cut of the clip.

**F1: the log-and-finish hold plays two haptics, or the wrong one.**
- `WorkoutModeView.swift:607-612`: the hold calls `session.logSet()` and then `finish()`.
- `finish()` (`:679-681`) plays `moment.play(.done)` straight away.
- Then `onChange(of: session.lastSeated)` (`:167-176`) runs on the next update and plays `.setLogged`, or
  `.newBest`, on the same `HapticCue`.
- Depending on whether the two land in one render or two, he feels either two haptics or only the set tap with no
  done. That breaks one haptic per moment.
- A best on the last set is worse. `.newBest` and Tess's thinking-then-done run on top of finish's done.
- Fix: when the workout is finished, the seat's `onChange` stays silent (for example
  `guard session.finishedAt == nil`). The finish path then plays one haptic: `.newBest` when the set is a best,
  otherwise done.

**F2: the last set loses its UNDO.**
- `WorkoutSession.finish()` sets `undoable = nil` (`WorkoutSession.swift:606`).
- Every other set gets the 10 s "Set 1. 82.5 × 7. UNDO" (it's in the clip). The last set is now logged and the
  workout finished in the same hold, with no way back.
- Before this PR the last set had its UNDO and the finish was a separate 0.8 s hold.
- Fix: keep the UNDO on the finish view for 10 s, taking back the set and the finish together (FinishWorkout has
  no undo of its own here). The other way out is a ruling from Design that the combined hold is undoable from the
  workout page. In that case write it into the sheet and I'll re-check against it.

**R1: re-cut the clip so it shows the new paths.**
- The clip shows start, set 1 of 4, the hold, then "Rest, then set 2" with SKIP REST and PAUSE. Frames 6 to 20
  are about 14 s with nothing changing.
- It never shows these new states:
  - "Rest, then Overhead press" (an exercise's last rest),
  - "4 sets, 82.5 × 8 best",
  - "Push A, last set" with "LOG 82.5 × 8 AND FINISH" and the finish,
  - PAUSE landing on Home's RESUME (NowPage.swift:483).
- Please record one walk through a short routine that ends on the finish, without the still stretch.

## What passes

- **Data safety**: no launch flags, no ProcessInfo, no engine or catalog change, no UI tests.
- **Context line** (`WorkoutParts.swift:177-203`): set, rest and the last set read as the sheet says. The "N / M"
  count is gone because the strip carries it.
- **PAUSE**: it is always a 44 pt target while the workout runs, and it leaves to Home's existing RESUME. It
  replaces the chevron, and nothing else hides the system back.
- **Name**: three `ViewThatFits` steps (44 on one line, 34 on one line, 34 on two). Nothing peeks.
  - The longest catalog name, "Seated Dumbbell Shoulder Press" (30 characters), fits in two lines at 34.
- **Key label**: `Format.kilograms` gives the number only, so the label reads "LOG 82.5 × 7" with no "kg", as in
  the clip.
- **Detail line**: "last time 82.5 × 7" takes that set's place from the newest past session (TrainingLedger
  sorts by date, newest first). "first time on this one" shows when there's no history.

## Lows

- **L1.** `WorkoutSession.swift:229`: the new `lastTime` was put under the old "1-based number of the set being
  dialled" comment, so that comment now sits on the wrong function. Move it back above `currentSetNumber`.
- **L2.** The third name step is `lineLimit(2)`. A custom exercise name longer than about 34 characters still
  ends in "…". The catalog fits, so this is only a note for when he names his own.
- **L3.** `sentenceCase` lowercases everything after the first letter, so a custom "DB Row" reads "Rest, then
  Db row". Lowercase only words that aren't all capitals.
- **L4.** Literals in place of tokens: `Theme.voice(size: 21)` and `Paint.cream.opacity(0.6)` on PAUSE. Use or
  add a token.
- **L5 (for Design).** At set 1 the page says the same fact three times: the detail "last time 82.5 × 7", "last 7"
  under reps, and Tess's "Same as last time, 82.5 × 7." That is the home-lines §2 no-repeat idea applied here.
  Design's call.
- **L6.** `context(...)` is computed twice per render, once for the Text and once for `tesseraAnimation(value:)`.
  It's cheap, but it can be one `let`.

## Note

- Builder A reports that between 03:00 and 04:00 PT the full app suite fails 41 cases on master too, because
  DemoData's `tonightWorkout()` returns nil in that hour.
- That isn't #381's doing. The fix (pin AppClock in the DemoData tests) is waiting for Product to give it an owner.
- QA's install-day runs avoid that hour until it lands.

## Addendum: one list with Design (10:45 AM PT)

- Design has #381 at FIX FIRST too.
- Their F1 (re-record the clip) is the same as my R1.
- Their F2: the rest countdown goes in `now`, per sheet 56 §7.
- Their F3: the receipt reads "Set 1 logged. 82.5 × 7.".
- Builder A gets one list: the clip, my F1 and F2, Design's F2 and F3, plus lows L1, L3, L4 and L6.

## Addendum: re-check at `8758235` (11:05 AM PT)

The trial merge onto master `a7797ac` is clean. The diff since bdb178c touches three files in Features/Workout.
The OpZones and TripZones files in the range diff come from the rebase onto #377, which is already on master.
Builder A ran the app tests: 121 green, at 03:59 PT.

**Verdict: PASS.**

- **F1, one haptic: fixed.**
  - The seat's `onChange` now has `guard … session.finishedAt == nil` (WorkoutModeView.swift:194).
  - `finish(withSet:)` (`:708-716`) plays exactly one haptic: `.newBest` when the set it finished with was a best,
    otherwise `.done`.
  - The Tess thinking-then-done no longer stacks on top.
- **F2, UNDO on the last set: fixed.**
  - `finishedWithSet` holds the finish record and the set's Undoable (WorkoutSession.swift:69).
  - `canTakeBackFinish` gives a 10 s window, and the finish view's Tess corner shows UNDO for that window
    (WorkoutModeView.swift:107-120).
  - `takeBackFinish()` undoes the finish first, then the set, and puts the set's numbers back on the dial
    (`undoLastSet`). It plays one undo haptic and says "Push Day A, back on.": the thing, then what happened.
- **R1, the clip: fixed.** Read as a 2/3 fps contact sheet; it runs 45 s. It shows:
  - sets 1 to 4 with the countdown in `now`, "Set 1 logged. 82.5 × 7." with UNDO, and "a new best: e1RM 104.5";
  - "Rest, then Overhead press", "4 sets, 82.5 × 8 best", then PAUSE to Training's "RESUME PUSH DAY A";
  - "Push Day A, last set" with "LOG 25 × 12 AND FINISH", the finish, UNDO giving "Push Day A, back on.", and
    the real finish.
  - It ends inside the app.
- **Design's F2 and F3: fixed.** The countdown uses `Paint.now` (`:448`), and the receipt reads "Set N logged."
  (WorkoutParts.swift:230).
- **Lows: fixed.** L1 (the comment is back above `currentSetNumber`), L3 (all-capital words stay, so "DB Row"
  is kept), L4 (`Theme.voice` and `Paint.secondary`), L6 (one `let line`).
- **`-workoutNearEnd`: OK.** It sits inside `#if DEBUG` and reads through `LaunchFlags.has`, which is simulator
  only (App/LaunchFlags.swift:8-20). No raw ProcessInfo or CommandLine reads were added.

### Lows (new)

- **N1.** The finish view's `onGathered` can still fire after a take-back, setting `summaryLine` and playing
  Tess's done on the live page. The gather starts as the finish view appears, so an UNDO tapped during the gather
  would see this. Guard it with `session.finishedAt != nil`.
- **N2.** In the clip the finish view reads "Friday, 18:10 to 18:10". That is the `-demoTime` relaunch at 3:58
  resetting the shifted clock, not a bug in real use. Noting it so Design doesn't flag it.
- **L2 and L5 stay open.** L2: no two-line 34 pt name was recorded, because no demo routine has a long enough
  name. L5: "last time said once" is Design's follow-up.

### Out of this PR: a wording bug on master (Core)

- The finish line "5 of 5 exercises, 16 sets, **2 records**." comes from `WorkoutSummary.swift:33` on master
  (`"record" : "records"`).
- Decision 8e55cd9 says one word, "best", everywhere and never "record".
- So it should read something like "2 bests". The exact wording is Product's or Design's call; the code owner is
  Core.

## Addendum: light re-check at `1c2d05c` (11:16 AM PT)

The trial merge onto master `abb6cec` is clean. This head adds one commit on top of 8758235. Builder A ran the
tests: 121 app tests and WorkoutSummaryTests, all green.

**Verdict: PASS.**

- **"bests"**: `WorkoutSummary.line` (WorkoutSummary.swift:33) now reads "1 best" or "N bests", and
  WorkoutSummaryTests expects "1 of 5 exercises, 3 sets, 1 best.". No app or Core test still expects
  "record(s)." in that line. This closes the out-of-PR finding.
- **No best said before the set**: the pre-set Tess line "Best N-rep … yet, if it goes." is removed
  (WorkoutParts.swift:245-248). It was also the line that cut off with "…" in the first clip. `recordHint` still
  drives the subline ("set 3: beats 8RM, was 80 × 8"), which Design keeps.
- Design checks the two frames in parallel.

**Note for the board.** `TaskTests.notNowMovesItTomorrowOrToLater` (TaskTests.swift:61) fails on a clean master
archive at 04:13 PT. It's date-dependent, like the DemoData 03:00-04:00 failures, and Core gets it with the
AppClock pin. QA's runs avoid 03:00-04:30 PT until it lands.
