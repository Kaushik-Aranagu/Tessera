# Night pass (memory spec M5): the Core wiring

`Harness/Memory/NightPass.swift` is the rules half, as a pure planner: it takes plain values and returns steps.
`Harness/Memory/NightRun.swift` is the store side: it builds those values, runs each step through its action,
records the night in `night-pass.json`, then runs the M6 eval and keeps its row. What is left for Core is calling
it at the 4 am turnover with the two Claude closures (below).

## Inputs, built at the 4 am turnover

- **beliefs:** `TessBeliefStore.all()`; the planner reads only the open ones.
- **series:** one `Event` per dated row behind a usual-time belief: workouts by `startedAt` (class Workout, verb
  "train"), cooks by their time (verb "cook"). Private rows count here, since only the time is read, never a name.
- **day** and **week:** the closing day's items (and on Sundays the week's, Monday 4 am to Monday 4 am), each by its
  shown name, its class word and its agent room. **Shown names are the caller's job:** a private thing arrives as its
  label (`ObjectPrivacy.shownLabel`, "Private workout"), and a kind whose title may be his own words (a note)
  arrives with an empty name, so it is counted and never named. The planner writes names into the summary as they
  come and does not check them again.
- **notebooks:** every file under `/memories/`, with its size and when a run last read it.
- **packs:** `ExpertisePack.build(for:)` hash now, and the hash the cached pack was built with.
- **agents:** `AgentSpec.available(under:)` with the Door's policy, so strict never reflects as Body or Money.
- **policy:** the Door's policy (default strict). Strict leaves money, body and calendar kinds
  (`NightPass.labOnlyKinds`, and the Money and Body rooms) out of the summaries and the reflect rooms.
- **lastNight:** the night stamp the last finished pass wrote. The planner returns nothing when it matches, so a
  second run the same night does nothing.

## Steps

| Step | Action | Notes |
| --- | --- | --- |
| `merge(keep:close:)` | `MergeBelief` | Kept and told win; for usual times the newest wins otherwise. A told or kept belief never closes (`MergeBelief` refuses it too), and when two of his disagree nothing in that group closes. `close` ends and joins `keep`'s evidence, so a forget of either takes both. |
| `revise(belief:words:value:evidence:)` | `ReviseBelief` with the evidence ids | `by: .system`; the receipt is the belief's own line. |
| `confirm(belief:)` | `ConfirmBelief` | At most once a night, and only with a new event that day. |
| `summary(path:text:)` | `NightRecord.summaries[path]` | `/summaries/day/2026-10-23`, `/summaries/week/2026-W43`; 60 days, 26 weeks. |
| `prune(path:)` | delete the notebook file | Oldest unused first, until the folder is under 32,000 bytes. |
| `refresh(_:)` | `NightRecord.packHashes` takes the new hash | The 1 hour cache then misses once. |
| `reflect(agent:)` | one Sonnet call (effort high) through the Door | Up to 5 inferred beliefs with evidence, through `remember`. |

Run the steps in order, through the actions, so every change lands in the op log and Undo works. Then write
`lastNight`. Then the eval (M6). Then, on Sundays, the tuner reads `MemoryEvalRecord.tunerMisses`.

## Calling it (Core)

```swift
var record = NightRecord.load()
var eval = MemoryEvalRecord.load()
let run = NightRun(engine: engine, policy: door.policy)
let report = await run.run(record: &record, eval: &eval, packs: hashes, notebooks: files,
                           prune: { notebooks.delete($0) },
                           reflect: { spec in
                               let kept = await tessRun.reflect(spec, items: run.dayItems(for: spec), cap: left)
                               left -= kept.kept.count  // starts at TessRun.reflectCap: five maybes a night in all
                           },
                           ask: { question, model in await compiledAsk(question.text, on: model) })
record.save()
eval.save()
```

- `reflect` is `TessRun.reflect(_:items:cap:)`: the room agent runs as itself (its personality, notebook, beliefs and
  last episodes, from `AgentContext`), on its open ladder at high effort, reads the closing day's things in its room
  through its own scope, and keeps at most `cap` maybes through `remember`, each with the paths that show it. Its
  line is kept as its episode. A day with nothing it may see under the policy makes no call.
- `ask` returns nil when the call failed. A question counts toward the kept misses only when every model answered.
- The eval facts come from `MemoryEvalFacts.from(store:classes:calendar:now:)`: private workouts, recipes, cooks and
  beliefs, and private exercise names, are left out.
- **His forget takes the merge chain.** A merged belief sits in the evidence of the one that kept on, so
  `ForgetBelief` deletes both. Take `ForgetBelief.chain(of:in:classes:)` before it applies and hand every id to
  `MemoryEvalRecord.forget(beliefs:)` after, so a closed, merged belief's misses go too.
- `report.failed` lists steps whose action refused (a belief closed in between). Show it in Developer mode.

## Not yet

- Usual times only change on time of day. Cadence ("three times a week") gets the same change-point rule over weekly
  counts in a later step.
- The reflect call reads the day's items for its room. Under strict the Door drops deviceOnly fragments as usual.
