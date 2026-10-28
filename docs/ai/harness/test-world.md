# Test world: the Core pieces

Kaushik, Oct 23 9:22 PM PT: until he calls the app production ready, use sample data everywhere, and build a lot of
simulation data to test Tess and the harness. Plan (for him): "Tess test world and question tests". The world and
its answer key are code: `Harness/Eval/EvalWorld.swift` (the generator), `EvalWorldKey.swift` and
`EvalWorldKey+Bank.swift` (about 160 questions in 15 kinds, answers computed from the world, scoring), and
`EvalWorldTests.swift` (pins every planted fact).

## 1. The seeder (written: `Harness/Eval/EvalWorldSeeder.swift`)

`EvalWorldSeeder.seed(_ world: EvalWorld, into engine: ActionEngine)` writes the world through the app's own
actions, with `by: .system`, so the rows look like real use. Each action gets the world's own time (`time:`,
`spentAt:`, `on:`), so the clock never moves. Two walls, checked before the first write:

- **Only a test store.** In memory, or a file under the temporary folder. When the stamp below lands, a stamped
  store passes too (the phone's Sample data needs it). The app's own store file never passes.
- **Only an empty store.** Every live row must be one a fresh catalog installs (the starter plan and its routines,
  the equipment, the Groceries list), matched by class and title. Any other live row of any class, one task
  included, refuses the seed, so it can never mix into his data.

The forgotten line is forgotten through `ForgetMemory`, then scrubbed with `TessBeliefStore.redact` (its forget
log kept in the store), so its words leave the op log as they do after the app's UNDO window. Its report counts
rows and refusals by room. Not seeded yet: leftovers (no class), the Pulldown rename (`RenameObject` renames objects, not exercise
classes), and told lines carry the seed's time (`RememberFact` takes none). Room by room:

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
- Claude rungs are allowed when `settingsAreReal` is true, or when the store is stamped test. Demo mode
  (`-demo`, `-resetDemo`, the screenshots) keeps no Claude.
- The phone's Sample data IS the stamped test world (his rule, Oct 23 9:22 PM PT): Builder A swaps
  `DemoData.prepareSample` for the seeder, with the stamp. So Sample data may call Claude, through `asksClaude`,
  the lab or strict policy and the shared cap below, like real data. The key and the ask gate stay as they are.
- Backups refuse a test store. The test store has its own sent log and trace files, next to its sqlite file.
- **One monthly figure.** Every Claude call, from the phone (real or Sample data) or the Mac runner, counts against
  the one $100 cap. The phone's cap counts the runner's ledger too (the runner writes its spend where the phone's
  `UsageLedger` reads it; until the Mac and phone share a file, the runner's month total is entered as one row).
  The runner stops at the smaller of $50 and ($100 minus what the phone spent this month).

## 3. The live runner (Core, on the Mac)

`scripts/tess-eval.sh --world small|big --policy lab|strict [--kinds ...]`

- It always starts from a fresh test store in the temporary folder, made for that run and never reused. It refuses
  any path inside the app's own data folder, and the seeder refuses anything else anyway.
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
- It stops at the smaller of $50 and ($100 minus the phone's spend this month), before each call, not after.
- It records AnswerCheck's result on every reply, shadow only. A **false fail** is a fail on a reply the key
  scores right. AnswerCheck retries only after a run on the big world shows false fails under 2% of replies, and
  none on money; until then the trace records the result and nothing retries.

The replay brain for `swift test` comes in my PR once the harness is on master.

## How to run the runner

```
scripts/tess-eval.sh --world small --policy lab --dry          # scripted brain, nothing leaves the Mac, no cost
scripts/tess-eval.sh --world small --policy strict --phone-spent 12.40   # LIVE: spends on the Claude API
```

A live run refuses to start without `--phone-spent`. `--kinds lookUp,count` limits the kinds; `--out DIR` moves the report folder (never inside the app's data folder).
The live run needs the key in the Mac keychain (item `com.kaushikaranagu.tessera.anthropic`, account `api-key`) and
never prints or writes it. The allowance is the smaller of $50 and ($100 minus `--phone-spent` minus the simulator's $20), minus what earlier runs
spent this month (`~/Library/Application Support/TessEval/ledger.json`, one place whatever `--out` says); the test store's ledger starts with one row for everything above that, so the
Door refuses a call before it is sent. The runner is `TessLiveEvalTests` and does nothing unless `TESSERA_LIVE_EVAL=1`.
Each report holds the reply, the tools called, the rung, time to first word and to the end, the cost and the key's
score per question, and under strict the sent-log scan (walled words, key shape).
