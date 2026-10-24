# Test world: the Core pieces

Kaushik, Oct 23 9:22 PM PT: until he calls the app production ready, use sample data everywhere, and build a lot of
simulation data to test Tess and the harness. Plan (for him): "Tess test world and question tests". The world and
its answer key are code: `Harness/Eval/EvalWorld.swift` (the generator), `EvalWorldKey.swift` (about 40 questions
in 15 kinds, answers computed from the world, scoring), and `EvalWorldTests.swift` (pins every planted fact).

## 1. The seeder (Core)

`EvalWorldSeeder.seed(_ world: EvalWorld, into engine: ActionEngine)` writes the world through the app's own
actions, with `by: .system`, so the rows look like real use. Go room by room in the world's order:

- **Workouts:** routines from `Maker.routines`, a plan per phase, and workouts with entries and sets. Do it the way
  `DemoData.addWorkout` does. `isPrivate` makes a walled routine titled "Shoulder rehab", so its shown label is
  "Private workout". `isDeleted` is created, then deleted through the delete action.
- **Renames:** make the exercise under `old`, then rename it to `new` on `on`. The op log keeps the old name.
- **Kitchen:** recipes with `CreateRecipe`, cooks as cook sessions, and leftovers with their throw-out dates.
- **Money:** `LogSpend` for spends (USD, plus EUR on the trip), inflows as paychecks, and `isReversed` as a spend
  and then its Undo ("Reversed").
- **Notes:** `CreateNote`, with `@Name` links. `isPrivate` makes a walled note, so its shown label is "Private note".
- **Chores, habits, sleep, weight, events:** each through its own class.
- **Tess's memory:** told lines to TessMemory and beliefs to M1 with their windows. Forget the forgotten line
  through the real forget, so the scrub and the stick are tested too.

Use the world's own dates. Set `AppClock` to `EvalWorld.now` during the seed and the run.

## 2. The test store stamp (Core)

- A store made by the seeder carries a test stamp: one settings field, `storeKind = test`.
- Claude rungs are allowed when `settingsAreReal` is true, or when the store is stamped test. Demo and Sample data
  keep no Claude.
- Backups refuse a test store. The test store has its own sent log, usage ledger and trace files, next to its
  sqlite file.
- The phone's Sample data now seeds this world (his rule): Builder A swaps `DemoData.prepareSample` for the seeder,
  with the stamp.

## 3. The live runner (Core, on the Mac)

`scripts/tess-eval.sh --world small|big --policy lab|strict [--kinds ...]`

- It makes a fresh test store in a temporary folder. It refuses any path inside the app's own data folder.
- It reads the key from the Mac keychain and never prints it.
- It runs each `WorldQuestion` through TessRun, every turn in order, and records:
  - the reply and the tools called (from the trace);
  - the rung that answered;
  - the time to the first word and to the end;
  - the cost;
  - the AnswerCheck result on the reply.
- It scores with `EvalWorldKey.score`. Under strict, it also scans the run's sent log for walled words and the
  key shape.
- It writes `eval-runs/<date>-<world>-<policy>.json`, and I build the report page from it.
- It has a $50 a month guard of its own inside the $100 cap, and it stops the run when the guard is reached.

The replay brain for `swift test` comes in my PR once the harness is on master.
