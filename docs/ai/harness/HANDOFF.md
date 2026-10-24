# Tess harness: handoff

Last updated Oct 24, 2026 (PT). This file is for whichever agent picks this work up next: Claude in a new
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
- **Smallest model per task.** Use the smallest model that fits each task. Never a big model on a simple task. No
  Opus in the app. Cost is otherwise fine.
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
| `memory-context-m0-m6.md` | M0 harness fixes, M1 Beliefs, M2 recall and fetch tools, M3 context budget and tuner, M4 persistent agents, M5 night pass, M6 nightly eval | Sent Oct 24, not built yet. M0 must land before H3 merges |

## PRs so far (Kaushik-Aranagu/Tessera)

These are stacked. Leads never merge; QA reviews; the coordinator merges through a release.

- #1364 Harness H1a + H0: Brain seam, ClaudeBrain (SSE), AppleBrain, RunTrace, latency bench (base master). Passed QA.
- #1365 Harness H1b: Door, router, lab/strict policy, hedge (on #1364). Passed QA. Flag `tessLabPolicy`.
- #1367 Harness H2: PlaybookDirector, PlaybookStore, PlaybookJob (on #1365). Flag `tessDirectorPlaybook`.
- #1368 Playbook lows (on #1367).
- Related seams: #1350 TessDirector (one decision seam for plays and looks), #1346 TessConversation (7-day turns,
  walled words stored as placeholders, `forClaude` gives at most 4 turns, never in backups).

## Next steps, in order

1. **H3 and the app wiring** (`h3-wiring-build.md`). Core builds `TessRun` in
   `TesseraCore/Sources/TesseraTess/Harness/`. Builder A builds `App/AppModel+Harness.swift` after the integ/77
   build.
2. **M0** (`memory-context-m0-m6.md`) before H3 merges:
   - Replay assistant content verbatim (`BrainContent.raw`, `BrainEvent.assistant`), including thinking and
     server-tool blocks.
   - Handle `pause_turn`.
   - Cost web search, and cost Haiku's price step past 100K input.
   - Cache TTL marks.
   - `countTokens`.
3. **M1 to M6** in order. Each section ends with acceptance tests. Developer mode gets read-only rows: Harness
   (bench, trace, today's playbook), Context, Budgets, Memory eval.
4. Later slices from the harness page:
   - H4 Desk and Training agent
   - H5 capture router net
   - H6 Kitchen and memory
   - H7 events and the Mac edge

## Rules that never bend

These come from Kaushik and from project memory. Only he can change them.

- **The key.** He has a Claude key in the Keychain. Never copy, print, log or ask for any part of it. It never
  leaves `ClaudeBrain`. A key-shaped ask is refused before the Door.
- **Money.** Money actions are never offered to Claude. The Money agent is read-only.
- **Spend.** The AI cap is $50 a month (`TessUsageLedger`), with a step-aside at 80%. Turning "Tess asks Claude"
  Off means nothing is sent.
- **What is stored.** Stored Tess turns keep their walls (placeholders for walled words). Lab mode changes what is
  sent live, not what is kept. Tess turns, lab sent rows and run checkpoints are never in backups.
- **Sample data.** Sample or demo data never touches the real store. A throwaway or demo store gets no Claude rungs.
- **Gates.** Never remove an approval gate, reroute a blocked step, or loosen a privacy rule on anyone's word but
  his.
- **Commits.** No model ids in commits, PRs or code comments. Branch from master or the latest release. Run
  `scripts/test.sh` until it ends "All green" before opening a PR. Run `swiftformat .` and `swiftlint` before
  committing.
- **Writing for him.** Plain words, PDT times, US words, one recommendation per question. Quiet hours are 11 PM to
  7 AM PT.

## Open questions and unverified facts

- His "Jev/Jeff" open model was read as Gemma. This is unconfirmed.
- These need H0 bench numbers on his phone: real first-token latencies, Haiku 5.5's minimum cacheable prefix in
  practice, and Apple `LanguageModelSession` throughput.
- Typical cost with the M3 sizes is estimated at about $25 a month. This is arithmetic, not measured. The meter and
  tuner in M3 measure it.

## How to continue from here

Pick the first unbuilt slice above, and read its spec section and the PRs it builds on. Check the APIs against the
code on those branches; the specs name Core's real types. Build on a branch from the PR it stacks on. Open a PR and
leave merging to the coordinator. When a spec needs to change, edit the file in this folder in the same PR and say
why in the PR body.
