# Ranker tuning: log the picks, then retune the weights

For: Core engine, Product · Date: 2026-10-15 · Research lab · Follows `context-packing.md` (the Home ranker)
Inputs: `context-packing.md` §4 to §9, `fixtures/year-of-data.md`, and master at 0c0bfdb (origin/master).

## 1. What exists on master today

- `NowPicker.pick(at:next:calendar:)` (`TesseraCore/Sources/TesseraCore/Tasks/NowPicker.swift`) is ordering only: the running process, then timed items by start, then untimed today with carried-over first. It returns `(now: NowItem?, next: [NowItem])`. There are no scores, weights or reasons.
- `ProcessTable.ledger(now:)` (`Processes/ProcessTable.swift`) lists suspended processes under 3 days old and waiting ones past their check time, at most `Limits.ledgerRows = 3`.
- Home does not call the picker. `NowPage` uses `AppModel.schedule(around:)` and `currentTask(around:)` (`App/AppModel.swift` lines 377 and 406), with a 60 s cache.
- No ranker, `rank`, `Pick`, `why` or weights exist anywhere on master (`git grep` for `rank(`, `score`, `ranker` finds nothing in Swift). So this doc assumes context-packing slice 1 (`NowPicker.rank` with `Pick.why`) lands first.
- Undo lives in `ActionEngine` (`Actions/ActionEngine.swift`): every row in the `op` table can be undone. That is why the log below must stay out of it.

## 2. What to log (one row per render, one per outcome)

Log when the ranked list changes or Home comes to the foreground, not on every SwiftUI body pass. Store ids and class keys, never titles or note text.

**Where:** its own file, `Application Support/Tessera/ranklog.sqlite`, opened with a separate GRDB `DatabaseQueue`. Not a table in `tessera.sqlite`, so it never reaches the op log, undo, the JSON export, the year-of-data content digest or a future CKSyncEngine sync. A JSONL file would also work, but outcomes are filled in later, and SQLite makes that an `UPDATE` instead of a rewrite.

```sql
CREATE TABLE render (
  id INTEGER PRIMARY KEY, at REAL NOT NULL,      -- AppClock.now
  weightsVersion INTEGER NOT NULL,               -- which RankWeights produced it
  dayPart TEXT, weekend INTEGER, runningKind TEXT, -- context: nil when nothing runs
  override TEXT,                                 -- running / eventSoon / reentry / nil
  candidates TEXT NOT NULL,                      -- JSON array, see below
  pickId TEXT NOT NULL, why TEXT NOT NULL);
CREATE TABLE outcome (
  renderId INTEGER PRIMARY KEY REFERENCES render(id) ON DELETE CASCADE,
  kind TEXT NOT NULL,       -- followed / overridden / dismissed / capture / ignored
  chosenId TEXT,            -- for overridden: the candidate he did instead
  via TEXT,                 -- tap / op / timer
  minutes REAL);            -- render to outcome; plus an index on render(at)
```

Each candidate in `candidates` is compact: `{"id":…,"k":"task","s":63,"f":{"soon":40,"due":1,"carry":0,"part":1,"last":0,"place":0,"habit":0,"full":0,"inc":1}}`. `f` holds the signal values as scored (minutes-to-start is stored as its points, so the feature equals its weight times one). Cap it at 8 candidates.

**Outcomes** are resolved on device by a read-only pass over the op log, at the next render or foreground, within **N = 20 minutes** of the render:
- **followed:** he tapped Now or a Today line for the pick, or a `.user` op touched the pick's subject (`StartTask`, `LogSet`, `GoToCookStep` and so on).
- **overridden:** a `.user` op touched another candidate first. Store `chosenId`; this gives an (shown, chosen) pair.
- **dismissed:** only if a dismiss gesture already exists (this doc adds no new control). **capture:** he opened capture or Tess and made something new, touching no candidate.
- **ignored:** nothing within N. Not counted as a "no", because he may just have locked the phone.

## 3. Retention and size

Keep **30 days**. Prune rows older than that at launch (`DELETE FROM render WHERE at < ?`, outcomes cascade), then `VACUUM` once a week. Estimate: about 25 logged renders a day (foregrounds plus real re-ranks; §6 of context-packing forbids minute ticks). A render with 6 candidates is about 600 B of JSON plus about 150 B of row and index, so 25 × 30 × 750 B ≈ **0.6 MB**. Hard cap: if the file passes 5 MB, drop the oldest week. Writes are one insert per render on a background queue and must not count toward the 2 ms `home.rank` budget in year-of-data §5.

## 4. Privacy

- It stays on the phone. No sync, no backup into the JSON export, `isExcludedFromBackup` set on the file.
- It is never read by `TessContextPack` or any Claude or Foundation Models prompt. A test asserts that no context pack builder links `RankLog`.
- It adds nothing to the screen: no badge, no "was this useful?" prompt, no new setting. The only way out is a Debug-only launch argument, `-exportRankLog`, that writes `ranklog-YYYY-MM-DD.jsonl` to the app's Documents folder. The export replaces object ids with a per-export salted hash and keeps only class keys, signal values and outcomes. Kaushik decides whether to hand it to a session.

## 5. Retuning after one week

**Metrics first** (a 20-line script over the export):
1. Follow rate overall, by day part, and with versus without a running process.
2. Follow rate per signal: of picks where signal X fired, the share followed. Compare with the overall rate.
3. Override pairs: for each (shown, chosen), which signals the chosen item had that the pick lacked. A signal that keeps showing up on the chosen side is underweighted.
4. Hold rate of hard overrides (running, meeting in 15 min, re-entry). These are not tuned by weights; a low rate there is a product question.

**Offline method** (a Core session runs it on the export, no app code):
- Treat each render with a followed or overridden outcome as one choice among its candidates, and fit a conditional logit (softmax over candidates, linear in `f`). This is plain logistic regression on the pairs when there are only two options. Use scikit-learn's `LogisticRegression` with L2 regularisation, or a hand-written gradient step with numpy. [1][2]
- Simpler fallback, the per-weight nudge: for each signal, `delta = clamp(k × (followRate_X − followRate_all) × 100, −5, +5)` points, with k = 0.5.
- Correct for position bias: he mostly sees pick[0], so a lower item that was "not chosen" may never have been seen. Learn from overrides (he went past the pick to something else) more than from plain follows. [3]
- The output is a proposed `RankWeights` diff plus a short table of evidence, sent as a normal PR. Weights never change on the phone by themselves.

**Guardrails:**
- At least 7 days and 60 renders with a followed or overridden outcome before any change; a signal needs at least 15 firings to move.
- Each weight moves at most 5 points or 30% (whichever is smaller) per week. No sign flips in one step.
- Fixed and not tunable: the three hard overrides, the hysteresis margin of 15, the one-ask rule, and the anti-patterns in context-packing §8.
- Every change bumps `weightsVersion`, and the 20 moments in context-packing §7 must still pass as fixtures. If a change breaks a moment, the moment wins and the change is cut.

## 6. How it feeds the year-of-data fixture

`fixtures/year-of-data.md` exists and already budgets the ranker (`home.rank`, ≤ 2 ms p95). Add a `rankLog` `FixtureDomain` with its own SplitMix64 stream, so it never shifts the other domains:
- For the last 30 simulated days, run `rank` at each simulated foreground (about 6 a day plus the 20 pinned times) and write render rows.
- Draw outcomes from a hidden **oracle** weight set (for example `part` worth 25, not 15), recorded in the fixture's oracle like the PRs.
- Test: the retune script, run on the fixture export, moves `part` up and leaves the others within ±5. That proves the method can find a known bias before it is trusted on real data.
- The log is outside `tessera.sqlite`, so it stays out of the content digest and the 12 to 16 MB size check.

## 7. Smallest Core slice and done-when tests

**Slice: `RankLog` in TesseraCore** (after context-packing slice 1). Adds `RankWeights` (the current weights as a versioned struct that `rank` reads), `RankLog` (its own `DatabaseQueue`, migration, `record(_:context:)`, `resolve(ops:now:)`, `prune(before:)`, `exportJSONL(salt:)`). No UI and no retune code on the phone.

Done when:
1. `RankLogTests.recordsCandidates`: one `rank` call writes one render row with every candidate's `f` values, `pickId`, `why` and `weightsVersion`.
2. `RankLogTests.notInOpLog`: recording 100 renders leaves the `op` row count and `undoLatest()` unchanged.
3. `RankLogTests.resolvesOutcomes`: with a pinned clock, a `StartTask` on the pick at +5 min gives `followed`; one on another candidate gives `overridden` with `chosenId`; nothing by +20 min gives `ignored`.
4. `RankLogTests.prunes30Days`: rows older than 30 days are gone after `prune`, with their outcomes.
5. `RankLogTests.exportHasNoTitles`: the JSONL holds no object titles or raw ids, only salted hashes.
6. `RankLogTests.sizeBudget`: 750 synthetic renders produce a file under 1 MB.
7. Year-of-data `home.rank` budget still passes with logging on.

## Sources

[1] scikit-learn, `sklearn.linear_model.LogisticRegression` documentation, scikit-learn.org (not re-checked today).
[2] D. McFadden, "Conditional logit analysis of qualitative choice behavior", in Frontiers in Econometrics, 1974.
[3] T. Joachims et al., "Accurately interpreting clickthrough data as implicit feedback", SIGIR 2005.
