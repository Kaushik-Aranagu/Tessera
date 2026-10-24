# Night pass (memory spec M5): the Core wiring

`Harness/Memory/NightPass.swift` is the rules half, as a pure planner: it takes plain values and returns steps.
The store side builds those values, runs each step through its action, and records the night. This file is that
side, for Core.

## Inputs, built at the 4 am turnover

- **beliefs:** `TessBeliefStore.all()`; the planner reads only the open ones.
- **series:** one `Event` per dated row behind a usual-time belief: workouts by `startedAt` (class Workout, verb
  "train"), cooks by their time (verb "cook"). Private rows count here, since only the time is read, never a name.
- **day** and **week:** the closing day's items (and on Sundays the week's, Monday 4 am to Monday 4 am), each by its
  shown name (`ObjectPrivacy.shownLabel`), its class word and its agent room.
- **notebooks:** every file under `/memories/`, with its size and when a run last read it.
- **packs:** `ExpertisePack.build(for:)` hash now, and the hash the cached pack was built with.
- **agents:** `AgentSpec.available(under:)` with the Door's policy, so strict never reflects as Body or Money.
- **lastNight:** the night stamp the last finished pass wrote. The planner returns nothing when it matches, so a
  second run the same night does nothing.

## Steps

| Step | Action | Notes |
| --- | --- | --- |
| `merge(keep:close:)` | `ReviseBelief` closing `close`, superseded by `keep` | Kept and told win; for usual times the newest wins otherwise. |
| `revise(belief:words:value:evidence:)` | `ReviseBelief` with the evidence ids | `by: .system`; the receipt is the belief's own line. |
| `confirm(belief:)` | `ConfirmBelief` | At most once a night, and only with a new event that day. |
| `summary(path:text:)` | write the summary object at the path | `/summaries/day/2026-10-23`, `/summaries/week/2026-W43`. |
| `prune(path:)` | delete the notebook file | Oldest unused first, until the folder is under 32,000 bytes. |
| `refresh(_:)` | rebuild the pack and store its hash | The 1 hour cache then misses once. |
| `reflect(agent:)` | one Sonnet call (effort high) through the Door | Up to 5 inferred beliefs with evidence, through `remember`. |

Run the steps in order, through the actions, so every change lands in the op log and Undo works. Then write
`lastNight`. Then, on Sundays, the tuner; then the eval (M6).

## Not yet

- Usual times only change on time of day. Cadence ("three times a week") gets the same change-point rule over weekly
  counts in a later step.
- The reflect call reads the day's items for its room. Under strict the Door drops deviceOnly fragments as usual.
