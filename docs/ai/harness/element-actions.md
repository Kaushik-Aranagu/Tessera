# The six missing actions behind Tess's element calls (for Core)

Core wired `checkListItem`, `startWorkout`, `startCooking` and `logSpend` (device only) on `core/elements-run`. These
six calls from `elements.md` had no engine action yet. Each spec below says what the action writes, what Undo does,
the receipt, what reads it, and the tool's inputs. They come from the approved sheets and standing rulings; none
needs a new product decision.

Shared rules for all six:
- Each is an `EngineAction`, run as Tess (`by: .tess`, pending: a ghost row with Undo 10 s) or by his own touch.
- Each receipt is "thing, what happened." with Undo.
- Each is reversible by the op log's own Undo. No action deletes data.

Two new classes carry four of them:

| Class | Fields | Used by |
|---|---|---|
| `routineRun` (parent thing) | `routine` (ref to routine), `day` (date, the Tessera day), `doneAt` (date), `stepsDone` (number), `by` (choice: `tended`, `workout`) | `tendRoutine` |
| `rest` (parent thing) | `scope` (choice: `training`, `routine`), `routine` (ref, for scope routine), `from` (date, a day), `until` (date, a day; empty means open), `endedAt` (date) | `restDay`, `pauseRoutine` |

`routine` gains `grove` (choice: `body`, `mind`, `home`; empty reads as body, as every routine is today) for
`plantRoutine`. `note` and `list` gain `pinned` (bool) and `pinnedAt` (date) for `pinNote`. `settings` gains
`rainAlert` (bool) and `rainAlertLead` (number, minutes, default 30) for `rainAlert`.

## 1. pinNote (Log)

- **Writes:** `SetPinned(object:pinned:)` on a note or a list. Pinning sets `pinned` true and `pinnedAt` now.
  Unpinning sets `pinned` false and clears `pinnedAt`.
- **Reads it:**
  - The Log's switcher "Pinned" window and the Pinned door list pinned notes and lists, newest pin first.
  - On the wall, a pinned title keeps its place across re-packs.
- **Receipt:** "Trip packing, pinned." or "Trip packing, unpinned." with Undo.
- **Walls:** a private note can be pinned. It stays "Private note" everywhere.
- **Tool:** `pinNote(note, pinned?)`. The note is the referent. `pinned` defaults to the opposite of now ("pin
  this" on a pinned note unpins it). Kinds: note, list.

## 2. rainAlert (Lookout)

- **Source:** sheet 243: the action word "Rain alert" toggles; the receipt is "You'll hear 30 minutes before
  rain." with Undo 10 s.
- **Writes:** `WriteSettings` with `rainAlert` true or false. `rainAlertLead` stays 30 unless he says another
  ("an hour before" sets 60).
- **Reads it:** the app's weather refresh (Open-Meteo, 30 min cache) schedules one local notification at the first
  rain hour minus the lead, at most one per rain spell. It is replaced when the forecast moves, and cleared when the
  setting is off. No location or place name goes in the notification text: "Rain in about 30 minutes."
- **Receipt:** "You'll hear 30 minutes before rain." or "Rain alert off." with Undo.
- **Tool:** `rainAlert(on?, leadMinutes?)`. A one-off alert for one window ("tell me if it rains tonight") is not in
  this slice; Tess answers with the setting.

## 3. restDay (Deck)

- **Source:** the Deck action word "Rest" (sheet 283 v3), the Deck empty state "Rest today. Next is Saturday."
  (landing contract 12), and the ruling that a skip gets a receipt with Undo.
- **Writes:** `TakeRest(scope: .training, from: today, until: today)`, a `rest` row for today only.
- **Reads it:**
  - Rolling plan: nothing advances. Today's routine stays next, and the next session date moves to the next
    training day.
  - Fixed-days plan: today's pinned routine is skipped, not moved (the same as the rest weekday).
  - The day log reads today as a rest day (`DayStory` `isRestDay` from the `rest` row as well as `restWeekday`).
  - The Deck board chalks "Rest today, Push A tomorrow", today's week letter gets "rest" under it, and the barbell
    glyph sets its plates down (sheet 285, board v13). The widget keeps the app's own type.
  - The Watch: a workout routine's tree does not dry on a rest day.
- **Refuses:** a day with a workout already started or finished: "Push A is already going." No row is written.
- **Receipt:** "Rest today. Next is Push A." with Undo.
- **Tool:** `restDay()`. No inputs. Today only. The weekly rest weekday stays `setRestWeekday`.

## 4. tendRoutine (Watch)

- **Source:** sheet 268 v4. Holding a tree for 1.5 s does the routine. Steps are buds, opened one tap each. Missed
  days dry the tree. Planned rest hangs a lamp.
- **Writes:** `TendRoutine(routine:at:)`, a `routineRun` for today with `by` = tended, `doneAt` now, and
  `stepsDone` = all its steps. A second tend the same day changes nothing ("Journal is done for today."). Tending a
  paused routine also ends the pause (sets the `rest` row's `endedAt`).
- **Reads it:** the woodland's run days are the union of finished workouts from the routine and its
  `routineRun` rows. That covers growth, health and fruit (`WoodlandLog`), the widget's strike, and the brief's
  "done today".
- **Training is untouched:** a tended workout routine counts for the tree only. The training ledger, bests and
  weekly sets read workouts, never runs. To log the sets, he starts it on the Deck.
- **Receipt:** "Journal, done for today." with Undo.
- **Tool:** `tendRoutine(routine)`, the referent. Kinds: routine.

## 5. plantRoutine (Watch)

- **Source:** sheet 268 v4. Tapping open ground makes the caretaker walk out and set a seed. The groves are Body,
  Mind and Home, plus borrowed ones (landing contract 11.15).
- **Writes:** `CreateRoutine(title:)`, then `cadence` (from his words: every day reads `day`; "on Mondays and
  Thursdays" sets `fixedWeekdays`; otherwise `day`) and `grove`.
- **Grove:** picked on the phone from the name with no model: walk, stretch, swim and run go to body; journal, read
  and meditate to mind; tidy, water plants and laundry to home; body when unsure. He moves it by its door. The
  tree's kind comes from its id, as `WoodlandLog.species` already does.
- **Walls:** a private routine (its name hits the private words) is planted as "Private routine".
- **Receipt:** "Journal, planted." with Undo.
- **Tool:** `plantRoutine(name, cadence?, weekdays?)`. Kinds: none (it acts on open ground).

## 6. pauseRoutine (Watch)

- **Source:** sheet 268 v4: "planned rest hangs a lamp in the tree".
- **Writes:** `TakeRest(scope: .routine, routine:, from: today, until:)`. `until` is empty when he names no end:
  the pause holds until he tends the tree or says resume. "Pause journal for a week" sets `until` to today plus 6.
  A pause past `until` ends by itself, with no receipt.
- **Reads it:** the tree hangs its lamp and does not dry while the pause holds. The brief's "needs a little care"
  skips it. Resuming sets `endedAt`.
- **Receipt:** "Journal, resting until Sunday." or "Journal, resting." with Undo. Resume: "Journal, back."
- **Tool:** `pauseRoutine(routine, days?, resume?)`, the referent. Kinds: routine.

## For the Design studio

Every look is on the sheets: the strike and petals for tend, the seed for plant, the lamp for pause, the rest board
for rest (sheet 285, board v13), and the action word toggle for the rain alert. When Tess runs one of these, sheet
285 (`docs/design/tess-hand-285.md`) applies: her pending blue for the 10 s Undo window, then the room's ink.
