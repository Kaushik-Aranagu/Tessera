# Routine mode data (sheets 323 and 329): the steps

Core, `TesseraCore/Training/RoutineSteps.swift`. A routine's steps are its children of class `routineStep`; a step's
moves are its children of the same class. Read with `RoutineSteps(store:classes:)`:

- `steps(of: routine) -> [RoutineStep]` in order: `title`, `minutes`, `cue`, `breath`, `moves: [RoutineMove]`, and
  `seconds` (the moves added up, else the minutes). A `RoutineMove` has `move` (the big word, the title when empty),
  `seconds`, `cue` (one line in Tess's voice) and `breath` ("in", "out" or "in/out", words only, no pace).
- `totalMinutes(of:)` for "about 32 min to bed".
- `RoutineSteps.dusk(tended:of:) -> 0...1`: how dark the dusk is (0 at the start, 1 once the last step is tended). A step
  left for tomorrow ("Not tonight") does not darken it.
- A private routine returns no steps (it shows as "Private workout"); its steps read as private through the parent rule.

Write with the actions `AddRoutineStep(parent:title:minutes:seconds:cue:breath:)` (parent is the routine, or a step for
a move) and `EditRoutineStep(step:title:minutes:seconds:cue:breath:)` (a field left out stays; an empty cue or breath
takes it off). Minutes 1 to 120 for a step, seconds 5 to 3600 for a move, words up to 40 and a cue up to 100 characters;
a secret word, a body fact or a key is refused. Both undo with the usual 10 s Undo.

`RoutineSample.evening(in:)` makes the sample Evening of sheet 323: Tidy 5, Stretch 6 (Hips, Shoulders, Neck, two
minutes each, with cues and breath), Read 15, Journal 5, Lights 1: 32 minutes.

Not Core's: the session itself (`RoutineSession`: which step and move you are on, their end dates, pause), what counts
as tended today (a tended run is `TendRoutine` in the element actions) and "Not tonight". Skipping a step never breaks a
streak: that is the session's rule, nothing here counts steps as owed.
