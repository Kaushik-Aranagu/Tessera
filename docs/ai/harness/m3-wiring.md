# M3 wiring: the context packer into TessRun (for Core)

The packer (`ContextPacker`, #1378) lays out one call from memory. Today `TessRun.pack(about:screen:withTools:)`
builds its own small pack: voice and profile as system blocks, and everything else as fragments on the ask. This
note says how the packer replaces that, without loosening a wall. I read the code on `core/beliefs` (afd58d8) and
the #1378 head (01439d4). Nothing here is built yet.

## 1. Where each section goes

| Section | Comes from | Goes to |
| --- | --- | --- |
| rules | `TessRun.voice`, the tool rules, the AnswerCheck rule ("every number from the query or `open`") | system |
| expertise | the room's playbook (Training, Kitchen, Money...) | system |
| core | `profile()` and the M1 beliefs with `confidence` above the core cut | system |
| recall | `Recall.items(...)` over the store graph, scored and floored | system |
| episodic | `conversation.forClaude(asksClaude:)` | the messages, as now |
| working | the ask, "On screen", the `about` objects, today's digest | fragments on the ask |

- The packer's blocks for the four system sections become `request.system`, in section order.
- The packer's `cacheMarks` replace TessRun's two marks. Voice moves into rules and profile into core, so the
  1-hour marks still cover them. **The API allows four marks**, and `ClaudeBrain.body` throws above four. So TessRun
  must not add its own marks on top of the packer's three.
- **The fourth mark** goes on the newest message each round (5 minutes), so rounds 2 to 10 read the history and the
  earlier tool results from cache. The packer's comment says the tail "is cached automatically by the request
  builder", but `ClaudeBrain.body` has no such step today. Two ways to fix it:
  - Add the mark in TessRun per round.
  - Or let `cacheControl()` also mark a `tool_result` block (the API allows `cache_control` there). As it stands,
    a message that holds only tool results has no text block to carry the mark.
- `ContextUse` is recorded once per run from the pack, plus the paths `open` read. The meter needs nothing else.

## 2. Taints: strict must drop a block, not refuse the call

**Today:** the Door filters fragments by taint, but it sends system blocks as they are. Under strict,
`strictHit` scans the system text, and a walled word there refuses the whole Claude rung. If recall or core
moved into the system as plain text, one health belief would make every strict call fail.

**Proposal:**

1. **Tag each item.** `ContextItem` gets `taint: Taint = .claudeSafe`. The caller tags an item `deviceOnly` when
   its object is unnameable (`TessAskRouter.isUnnameable`) or its text is walled (`PrivateFacts.isWalled`,
   `isCalorieShaped`, `SecretWords.mentions`). A belief takes the taint of the thing it is about.
2. **Split mixed sections.** The packer emits a section with mixed taints as two blocks: the safe block first,
   then the deviceOnly block. `ContextPack.Block` gets the taint.
3. **Choose blocks per rung.** The Door builds the system per rung. `DoorJob` gets
   `systemFragments: [(section, text, taint)]` in place of a fixed `request.system`. `Door.pack` keeps what
   `policy.allows` and recomputes the marks with `ContextPacker.marks(for:)` over what was kept.
   - Under lab (his pick), nothing is dropped.
   - Under strict on a Claude rung, deviceOnly blocks are dropped. Then `strictHit` runs on what is left, as now.
4. **Never let strict read as "nothing kept".** If strict drops a recall block, put the line "Some of what's kept is
   on this phone only." in its place, so Claude doesn't say nothing is kept when the phone has it. `nothingKept`
   stays the packer's own flag. It is true only when nothing passed the floor.

**Tests:**
- A strict Claude rung with a deviceOnly core belief gets the call minus that block, and is not refused.
- Lab gets every block.
- The marks stay in order and number at most four after a drop.

## 3. The phone's own rung needs its own pack

Both ladders end in `.appleOnDevice`, and `RungPlan.deviceOnly` is that rung alone. `AppleBrain` joins every
system block into the session's instructions. A pack sized for a 1M window will not fit the on-device model's
small window (check the current limit in the iOS 27 docs). So the fallback after a Claude failure would fail too.

**Proposal:** TessRun builds a second, small pack for the device rung, from a `BudgetRow` for `.appleOnDevice`:
- voice;
- the ask;
- the about lines;
- the top recall items that fit.

`DoorJob` carries it as `deviceRequest`. The device rung always gets every taint, since it never leaves the phone.

## 4. Shown-label paths

The packer shows each item's `path` so the model can open more. The rule: **no walled word ever reaches a path or
an item's text.**

1. **Paths.** A path is built from the class word and the shown name, never a slug of a walled title. A private
   object's path uses its shown label and a number in pack order: `/training/workouts/private-workout-2`. The
   number keeps two private workouts apart without naming either one.
2. **Text.** Item text is built the way `pack(about:)` builds lines now:
   `ObjectPrivacy.shownLabel`, then `TessAskRouter.shownSentence`, then the title, then "an object". Beliefs about
   a private thing say its shown label (M1 already redacts values and set ops).
3. **`open` takes paths.** `open` takes a handle (`o1`) today. TessRun's `handles` map should hold both the handle
   and the path for every packed object, and the tool's description becomes "a handle or path from the pack". The
   strict "on this phone only" reply stays as it is.
4. **Episodic is already walled.** `TessConversation.append` stores a private thing's shown label in place of his
   words, and holds unnameable turns back. `forClaude` is the only source for the episodic section.
5. **Test the paths themselves.** Run `strictHit` over the path of every claudeSafe item in the sample store. A
   class word in a path (for example a money pool's folder) must not trip the strict scan by itself. If it does,
   that item is deviceOnly by construction.

## 5. Other things found while reading

- **Fragments move every round.** `Door.pack` puts the fragments on the last user message. In round 2 and later
  that message is the tool results, not the ask. So the model sees the working context after the tool output, and
  the messages prefix differs every round, which misses the cache. Fix: `DoorJob.fragmentsAt` (the ask's message
  index), so they stay on the ask.
- **The 30-second round deadline.** An uncached pack of several hundred thousand tokens can take a long time
  before the first token. Scale the deadline with the input size, and measure it with `LatencyBench` on a real
  large pack before choosing the number. A timeout falls to the next rung, so a short deadline costs accuracy.
- **Thinking blocks across rungs.** Round blocks are replayed as `.raw`, thinking included. If a later round falls
  from Sonnet to Opus, Sonnet's thinking is replayed to Opus, and thinking blocks are tied to the model that wrote
  them. Either pin a run's later rounds to the rung that answered round 1, or strip thinking blocks when the rung
  changes. Check what the API does with a mismatched block before choosing.
- **A stale comment.** `TessRun.rounds` says "Up to three rounds". `maxRounds` is 10.
- **Docs low owed from #1378.** A section whose shipped start is 0 never grows, because its ceiling is twice 0. This goes in
  the BudgetTuner and ContextBudget docs in my next PR.
- **AnswerCheck starts in shadow.** Wire C6 into the Door as a trace field first: record the result and don't
  retry. Wired: each finished reply gets a `check` span named `answer-check` on its run, with "passed" or "failed"
  and `unsupported`, a count. The numbers themselves are never traced, since one can be a body or money value. It retries one rung up only after the live runner shows false fails (a fail
  on a reply the key scores right) under 2% of replies on the big world, and none on money (test-world.md, part 3).
- **The forget path purges the eval.** Before `ForgetBelief` applies, take `ForgetBelief.chain(of:in:classes:)`: the
  whole chain it deletes, every revision and every belief the night pass merged into it or it into. After it
  applies, call `MemoryEvalRecord.forget(beliefs:)` with all of those ids, so no kept miss, streak or night miss
  outlives any belief in the chain. The file holds
  question ids only; a kept miss is written again from the store each night, so a deleted fact can't be re-asked.
