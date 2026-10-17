# QA review: #605 Core 0am (keepPlannedTask, TaskStory, BuyCadence)

Head eb8fb0e. Static, middle depth. Merge-tree clean. Engine-only plus two call sites in HomePlan.

- KeepPlannedTask: same apply/summary/receipt as MoveTask (wraps it), registered in descriptors and decoders, added to DayStory `dropped` (so the Day log does not narrate it), intents catalog note "in-app only". HomePlan.swift:146/175 now perform it for Plan my day's keep; undo still works (record-based).
- Other readers of the action name: ReviewView.swift:70 counts "moveTask" and "rollForwardTasks" for "put away" tasks that are still in Later. A keep sets a time, so a kept task is never in Later: no regression. No other string match on "moveTask" in app or Core.
- TaskStory: moves = moveTask by user/tess/intent only; system moves never count; rolls = rollForwardTasks by system; keeps = planned; undone and pending records are excluded (`state == .committed`); events sorted stable. Tests cover SA-STORY-1/3/4/5/6/11/12, undone moves and Later.
- BuyCadence: buys = committed checkListItem with a true setValue by a hand actor, one per 4 am day (TesseraDay), needs 3 buys, mean gap rounded, min 1: "You buy it about every N days." Tests cover deleted rows, system checks, same-day dupes, rounding. Items are found through the ingredient's incoming links, and the test clears rows after each shop, so the deleted-row path is exercised.

Lows (not blocking):
1. KeepPlannedTask's doc says "Not offered to Tess or Siri", but it sits in `ActionRegistry.descriptors`, which the header says feeds Tess's tool list, the Claude tool schema and App Intents. Nothing in production consumes `catalog`/`toolDefinitionsJSON` yet (tests only), so it is latent; once a consumer lands, the model could pick keepPlannedTask for "move it to 3", which TaskStory would then call "planned" and not count as a move. Add an `offeredToModel: false` flag (or filter) before the first consumer, with a test.
2. BuyCadence `span` uses calendar day components between 4 am day keys; across a DST change this is still whole days because the keys are day starts, but a test with Nov 1 would pin it (fixtures/dst-nov-1.md).

Verdict: PASS at eb8fb0e.
