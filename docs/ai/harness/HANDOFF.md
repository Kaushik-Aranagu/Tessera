# Tess harness: handoff

Last updated Oct 24, 2026, 1:05 AM PT (Codex handoff checkpoint, weekly limit at 97%). This file is for whichever agent picks this work up next: Claude in a new
thread, or Codex. Read `CLAUDE.md` at the repo root first. Its rules apply to every agent. Then read this file and
the three build specs in this folder.

## What Kaushik asked for

He wants a harness around the Claude API, because the app only has raw API calls. It covers:

- Tess as her own agent.
- An agent per room or app, which can spawn sub-agents.
- How agents talk to each other.
- The memory each agent keeps.
- How context is built and maintained.
- What goes in each prompt.
- What happens to results.
- Which tool calls are allowed.

His later asks, in order:

- **Latency first.** Optimize for pipelining and many calls in flight. A backend server or the Mac as an edge
  server is fine later.
- **Small models.** Open models later (Gemma), and small "application specific" models trained on our typed classes
  (workouts, ingredients, pantry items).
- **Lab mode (his pick, Oct 23).** Claude calls from his phone may carry health, body, calendar, calories and money.
  The key never leaves `ClaudeBrain`. Strict mode stays one switch away.
- **Don't overthink simple tasks.** Never a big model on a simple task, because bigger models overthink.
- **Accuracy first (Oct 23, 6:14 PM PT, wins over any cost rule).** "I want us to be more functionally accurate than
  being cost effective... Forget about cost." And: "I'm not asking you to forcefully increase the context size, but
  we should allow it to always work at its best to whatever extent it needs." Sizes are starting points, not
  ceilings. Models are picked by what gets the task right: Haiku for simple tasks, Sonnet for open ones, and Opus
  only as an escalation rung. The cap is $100 a month, as a runaway guard only.
- **Our own memory system.** Explain it in plain words, and improve it over time.
- **Everything on.** Every feature, experiments included, ships On to his phone. Tell him when slices land.
- **Big, persistent context (Oct 24, 12:51 AM UTC).** Use as much context as possible, with set sizes for each kind
  of memory: some for working memory and some for each agent's expertise. Memory is linked and it grows. Agents can
  fetch more themselves from saved memory, other pages, documents and the internet. Measure what each call and its
  thinking use, tune the sizes, and keep agents persistent.

## The design in one paragraph

The phone is the harness, and Claude is a stateless worker. Every call goes through one `Door`, which applies the
policy, packs the request, scans for the key, reserves budget on the ledger, routes, streams, checks the result,
settles cost, and writes the trace and the sent log. A `BrainRouter` picks the smallest rung that fits:

1. Rules
2. Typed nets (later)
3. Apple on-device
4. Mac (later)
5. Haiku
6. Sonnet

Tess is the only voice. Room agents report back to her. Every call is rebuilt from persistent memory, not from a
growing transcript. A context compiler fills a fixed budget section by section, and agents page in more through
fetch tools. The record (objects plus the op log) is never summarized away. Beliefs are typed objects with evidence
and validity windows. A 4 am night pass verifies, merges, summarizes and evaluates.

Design pages (claude.ai, owner only):

- Harness: https://claude.ai/artifact/L3drGrNV8Xu9eJjCu7Jbok
- Memory: https://claude.ai/artifact/6ubnKsjT7KueZQocUTHmiE

The specs in this folder hold everything a builder needs. The pages explain it to him.

## Build specs (this folder)

| File | What | State |
|---|---|---|
| `h0-h2-build.md` | H0 latency bench, H1a Brain seam, H1b Door and router, H2 Director playbook | Built by Core (PRs below) |
| `h3-wiring-build.md` | App wiring for H1/H2 (Builder A), H3 `TessRun` streaming loop (Core) | Sent Oct 23, not built yet |
| `memory-context-m0-m6.md` | M0 harness fixes, M1 Beliefs, M2 recall and fetch tools, M3 context budget and tuner, M4 persistent agents, M5 night pass, M6 nightly eval | M0, H3 and M1 built by Core on the `core/beliefs` chain. M3 core, M4, M5 and M6 built on the AI lane below. M2 is Core's, not built |

These live on the AI lane branches, not on master yet: `m3-wiring.md` (what Core wires for M3, AnswerCheck and the
forget path), `checks.md` (running list of checks), `test-world.md` (the test world, the stamp and the live runner)
and `night-pass.md` (the M5 night pass and how Core calls it).

## PRs so far (Kaushik-Aranagu/Tessera)

These are stacked. Leads never merge; QA reviews; the coordinator merges through a release.

- #1364 Harness H1a + H0: Brain seam, ClaudeBrain (SSE), AppleBrain, RunTrace, latency bench (base master). Passed QA.
- #1365 Harness H1b: Door, router, lab/strict policy, hedge (on #1364). Passed QA. Flag `tessLabPolicy`.
- #1367 Harness H2: PlaybookDirector, PlaybookStore, PlaybookJob (on #1365). Flag `tessDirectorPlaybook`.
- #1368 Playbook lows (on #1367).
- Related seams: #1350 TessDirector (one decision seam for plays and looks), #1346 TessConversation (7-day turns,
  walled words stored as placeholders, `forClaude` gives at most 4 turns, never in backups).

## The AI lane stack (Oct 24, 1:05 AM PT)

Built in a cloud container with no Swift toolchain. Each head was checked with a tree-sitter parse and the
120-column rule only. **Core must run `swift test` in `TesseraCore/` on each head before QA re-checks it.**
Branches are `claude/project-thread-1kliwl-ai*`. Leads never merge; the coordinator merges.

| PR | Branch | Base | Head | What | Verdict |
|---|---|---|---|---|---|
| #1378 | `claude/project-thread-1kliwl` | `core/harness-m0` | 01439d49 | M3 core (packer, budgets, meter, tuner) and M2 recall score | Carried inside #1394 (merged into `-ai`) |
| #1394 | `-ai` | `core/beliefs` | d22bfac0 | AnswerCheck (C6, starts in shadow), M6 MemoryEval and its record, the test world and its answer key (~160 questions), M3 wiring note, checks | QA notes folded. Core found 2 type-check errors; fixed in d22bfac0. Needs Core's compile, then QA |
| #1395 | `-ai-m4` | `-ai` | 7aed147f | M4: AgentSpec as data, ExpertisePack (pure render, SHA-256 hash), lab-only Body and Money | QA notes folded. Needs compile, then QA |
| #1398 | `-ai-m5` | `-ai-m4` | e601cc3f | M5: NightPass planner (merge, revise, confirm, summaries, prune, refresh, reflect) | QA FIX FIRST fixed (never closes a told or kept belief; strict drops money, body and calendar from summaries). Needs compile, then QA |
| #1399 | `-ai-m6` | `-ai-m5` | 7cea3319 | M5 to M6: NightRun (runs steps through actions, then the eval), NightRecord, MergeBelief, the eval's store adapter | QA PASS WITH NOTES; notes folded (MergeBelief refuses his own beliefs, private routines stay out, `ForgetBelief.chain`). Needs compile |
| #1400 | `-ai-seed` | `-ai` | d688c8e4 | EvalWorldSeeder: writes the test world through engine actions only | QA FIX FIRST fixed (only an in-memory or temp store, only catalog rows; the forgotten line is scrubbed). Needs compile, then QA |

**Merge order:** Core's `core/beliefs` chain, then #1394, #1395, #1398, #1399. #1400 can go any time after #1394.
When a lower head changes, merge it up the stack (`-ai` into `-ai-m4` into `-ai-m5` into `-ai-m6`; `-ai` into
`-ai-seed`). Never rebase these branches.

## What Core still owes

- **Compile and test** every head above (`swift test`), and send back any error with its file and line.
- **The test store stamp** (`test-world.md` part 2): a settings field `storeKind = test`. Claude rungs are allowed
  on a stamped store. Backups refuse a stamped store. Once the stamp exists, `EvalWorldSeeder.isTestStore` must
  accept a stamped store too; the phone's Sample data needs that before Builder A can swap `DemoData.prepareSample`
  for the seeder.
- **The live runner** (`test-world.md` part 3): `scripts/tess-eval.sh --world small|big --policy lab|strict`.
  It always starts from a fresh temp store, reads the key from the Mac keychain without printing it, and stops at
  the smaller of $50 and ($100 minus the phone's month).
- **M2:** the recall and fetch tools (`recall`, `remember`, `open`, web search and fetch), using `RecallScore`.
- **Wiring:**
  - Put the packer and the budgets into `TessRun`.
  - Wire the meter and the Sunday tuner.
  - Wire AnswerCheck into the Door as a trace field only (shadow). It may start retrying one rung up only after the
    runner shows false fails under 2% and none on money.
  - Feed `AgentSpec` and `ExpertisePack` into the run.
  - Call `NightRun` at the 4 am turnover, with the reflect and ask closures (`night-pass.md`, "Calling it").
  - The forget path takes `ForgetBelief.chain` before the forget, then calls `MemoryEvalRecord.forget(beliefs:)`.
  - Add the Developer mode rows: Context, Budgets, Memory eval.

## Next slices (AI lane)

1. The reflect call itself: the prompt, and parsing up to 5 inferred beliefs with evidence through `remember`.
2. Cadence ("three times a week") gets the same change-point rule as usual times, over weekly counts.
3. Seeder gaps: leftovers (needs a class) and the exercise rename (needs a class rename action).
4. The first runner pass on the small world, then the big world. Then tune the budgets and decide on AnswerCheck
   leaving shadow, from the numbers.
5. Then the harness page's later slices (below).

## The original plan, in order (H3, M0 and M1 are now built on Core's branches)

1. **H3 and the app wiring** (`h3-wiring-build.md`). Core builds `TessRun` in
   `TesseraCore/Sources/TesseraTess/Harness/`. Builder A builds `App/AppModel+Harness.swift` after the integ/77
   build.
2. **Accuracy-first changes to what's built.** Raise `TessUsageLedger`'s cap to $100. Add `.opus` to `BrainID`
   (claude-opus-5-5, an escalation rung only). Turn adaptive thinking on for Claude calls, except calls that force a
   tool. `h0-h2-build.md` still says "No Opus" and "effort low"; the ACCURACY FIRST section of
   `memory-context-m0-m6.md` wins.
3. **M0** (`memory-context-m0-m6.md`) before H3 merges:
   - Replay assistant content verbatim (`BrainContent.raw`, `BrainEvent.assistant`), including thinking and
     server-tool blocks.
   - Handle `pause_turn`.
   - Cost web search, and cost Haiku's price step past 100K input.
   - Cache TTL marks.
   - `countTokens`.
4. **M1 to M6** in order. Each section ends with acceptance tests. Developer mode gets read-only rows: Harness
   (bench, trace, today's playbook), Context, Budgets, Memory eval.
5. Later slices from the harness page:
   - H4 Desk and Training agent
   - H5 capture router net
   - H6 Kitchen and memory
   - H7 events and the Mac edge

## Rules that never bend

These come from Kaushik and from project memory. Only he can change them.

- **The key.** He has a Claude key in the Keychain. Never copy, print, log or ask for any part of it. It never
  leaves `ClaudeBrain`. A key-shaped ask is refused before the Door.
- **Money.** Money actions are never offered to Claude. The Money agent is read-only.
- **Spend.** The AI cap is $100 a month (`TessUsageLedger`; it was $50 until Oct 23), with a step-aside at 80%. It's
  there to stop a runaway bug, not to shape any design choice. Turning "Tess asks Claude"
  Off means nothing is sent.
- **What is stored.** Stored Tess turns keep their walls (placeholders for walled words). Lab mode changes what is
  sent live, not what is kept. Tess turns, lab sent rows and run checkpoints are never in backups.
- **Sample data.** Sample or demo data never touches the real store. A throwaway or demo store gets no Claude rungs.
- **Gates.** Never remove an approval gate, reroute a blocked step, or loosen a privacy rule on anyone's word but
  his.
- **Commits.** No model ids in commits, PRs or code comments. Branch from master or the latest release. Run
  `scripts/test.sh` until it ends "All green" before opening a PR. Run `swiftformat .` and `swiftlint` before
  committing.
- **Writing for him.** Plain words, PDT times, US words, one recommendation per question. No quiet hours (his
  call, Oct 23, 11:43 PM PT).
- **Sample data, always (Oct 23, 9:22 PM PT).** Until he says production ready, the phone and the tests run on
  sample data. The seeder writes only through engine actions, and only into a test store.

## Open questions and unverified facts

- His "Jev/Jeff" open model was read as Gemma. This is unconfirmed.
- These need H0 bench numbers on his phone: real first-token latencies, Haiku 5.5's minimum cacheable prefix in
  practice, and Apple `LanguageModelSession` throughput.
- Cost under accuracy-first is not estimated. The M3 meter measures it from the first day.

## How to continue from here

Pick the first unbuilt slice above, and read its spec section and the PRs it builds on. Check the APIs against the
code on those branches; the specs name Core's real types. Build on a branch from the PR it stacks on. Open a PR and
leave merging to the coordinator. When a spec needs to change, edit the file in this folder in the same PR and say
why in the PR body.
