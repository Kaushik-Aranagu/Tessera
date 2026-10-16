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
