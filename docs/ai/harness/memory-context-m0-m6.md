MEMORY AND CONTEXT BUILD TEXT, M0 to M6 (Oct 23, for Core; relay word for word)

Kaushik's ask (Oct 23, 5:51 PM PT): use as much context as possible, with set sizes for each kind of memory, a little kept for working memory and some for each agent's own expertise. Memory is linked, it grows, and agents can fetch more themselves: from saved memory, other pages and objects, documents, and the internet. Measure how much each call and its thinking really use, then tune the sizes. Agents are persistent. Everything ships On. His standing rules hold: lab policy On, the key never leaves ClaudeBrain, and a stored Tess turn keeps its walls.

ACCURACY FIRST (Kaushik, Oct 23, 6:14 PM PT, overrides any cost rule below): "I want us to be more functionally accurate than being cost effective. We'll take care of costs later... I want us to be functionally accurate and like factually right and doing the tasks right." And: "I'm not asking you to forcefully increase the context size, but we should allow it to always work at its best to whatever extent it needs. Forget about cost." So sizes are starting points, never cost ceilings; a call takes as much context as helps; models are picked by what gets the task right; the cap is $100 a month and exists only to stop a runaway bug (his credits are at least $100).

Facts this rests on (Claude API docs, Oct 2026): Haiku 5.5 and Sonnet 5.5 both have a 1M-token context and 128K max output. Haiku 5.5 costs $0.10 in and $0.50 out per million up to 100K input tokens, and $0.50 and $2.50 past that. Sonnet 5.5 costs $2 and $10, with cache reads at $0.20. Writing to the cache costs 1.25x for the 5-minute TTL and 2x for the 1-hour TTL. The minimum cacheable prefix is 512 tokens, with at most 4 breakpoints, and longer-TTL entries must come before shorter ones. Sonnet 5.5 refuses forced tool_choice. Thinking blocks must be sent back unchanged, and a history edit invalidates later thinking. Web search costs $10 per 1,000 searches plus tokens. Web fetch costs only tokens and can fetch only URLs that already appear in the conversation.

THE IDEA IN ONE LINE
Every call is rebuilt from persistent memory, not from a growing transcript. A context compiler fills a fixed budget, section by section, from stores that grow without limit. The model can page in more through fetch tools. Each call takes as much as helps it be right, and the nightly eval decides what helps.

M0  HARNESS FIXES THE LOOP NEEDS FIRST (Core, Harness/)
1 Verbatim assistant content. Add BrainContent.raw(Data): one content block as the API sent it. SSEParser keeps every block of the assistant message (text, tool_use, thinking with its signature, redacted_thinking, server_tool_use, web_search_tool_result, web_fetch_tool_result) and emits BrainEvent.assistant([Data]) before .done. TessRun appends that message unchanged before the next round. Never rebuild an assistant message from text deltas. This keeps thinking valid, keeps encrypted search results valid, and keeps the cache.
2 pause_turn. When stop is pause_turn, send the paused assistant message back unchanged as the next round. It does not count as a round.
3 Server tool cost. Read usage.server_tool_use.web_search_requests and add $0.01 per search to costNano. Web fetch adds nothing beyond tokens.
4 Haiku price step. TessUsageLedger.cost charges Haiku 5.5 at $0.50 / $2.50 per million when input is over 100K tokens. The estimate uses the same rule.
5 Cache TTL. BrainRequest.cacheAfter becomes [CacheMark] with index and ttl (.fiveMinutes or .oneHour). ClaudeBrain writes {"type":"ephemeral","ttl":"1h"} for oneHour. The 1-hour marks must come before the 5-minute marks; the request builder asserts it.
6 Token counting. ClaudeBrain.countTokens(_ request:) calls POST /v1/messages/count_tokens (free) with the same body minus stream and max_tokens. It is used only by the meter's weekly calibration (M3).

M1  BELIEFS (Core, TesseraCore/Tess/)
New system class Belief under /system/tess, read through a value type TessBelief.
  subject: handle (you, a class, or one object)   key: BeliefKey (usualTime, cadence, prefers, avoids, goal, limit, pattern, alias, fact)
  value: typed JSON   confidence: 0...1   source: told | noticed | inferred | learned
  evidence: [link] (required, at least one op or object; a belief with none is refused)
  validFrom: Date   validUntil: Date? (closed, never deleted)   supersedes: link?   uses: [Date] (last 50)
  words: String (80 chars, second person; told keeps his own words)
Today's told and noticed TessMemory lines become beliefs in a one-time migration (TessMemory stays readable for What Tess knows until Builder B moves the page). His forget gesture still deletes and redacts, as in memory-store.md section 5. Closing is for change, deleting is for his forget. An inferred belief is a maybe: it is shown and spoken as "I think", and it becomes a fact when the record confirms it twice or he keeps it. Beliefs have no cap; told lines keep the 40 cap.

M2  RECALL, PATHS AND FETCH TOOLS (Core, Harness/Recall/)
Addresses. Every memory has a path, using ObjectPath slugs: /training/exercises/bench-press (object), /classes/exercise (class), /beliefs/<handle>, /summaries/day/2026-10-23, /summaries/week/2026-W43, /notebooks/training/<file>, /pages/<room>/<page> (what a room page shows, as text), /docs/<handle> (notes, recipes, pasted pages). Packs show paths and short handles, never UUIDs.
Recall score for each candidate, equal weights to start (Generative Agents):
  nearness  spread from the objects in the ask and on screen along links, 3 hops, 0.5 decay per hop (personalized PageRank, 10 iterations)
  activation  ACT-R base level: ln(sum of t^-0.5 over uses, t in days), from uses
  importance  correction 1.0, told 0.8, surprise 0.6, noticed 0.5, inferred 0.3
  confidence  the belief's own; 1 for objects and summaries
  fit  free text only: keyword match over SQLite FTS5 on titles, notes and summaries
Each part is min-max scaled to 0...1 and summed. Below a floor of 0.5, recall returns nothing, and the pack says "nothing kept on this".
Fetch tools (strict schemas, reads run in parallel):
  recall(query, kinds?, limit 1-20) -> path, one-line digest, score for each hit
  open(path, depth 1-2) -> the item's text plus its links' digests (replaces H3's open(handle)); a page path returns what the page shows
  links(path, relation?) -> neighbors as path + digest
  history(path, since?) -> op-log lines for that object, newest first, at most 30
  remember(subject, key, value, words, evidence) -> writes an inferred belief (pending ghost row, KEEP / NOT NOW)
  memory (memory_20250818) -> the agent's notebook. Its /memories/<agent>/ paths are Notebook objects, never files. Commands: view, create, str_replace, insert, delete, rename. Each file holds at most 4,000 characters and each agent at most 40 files.
  web_search and web_fetch (server tools): Sonnet gets web_search_20260318 and web_fetch_20260318, max_uses 8 each, response_inclusion "excluded". Haiku gets web_search_20250305 and web_fetch_20250910 with allowed_callers ["direct"], max_uses 5. Read each model's capabilities.server_tools from GET /v1/models/{id} at launch and leave out what it doesn't support. web_fetch max_content_tokens is 50,000. Search results are never stored as beliefs, only cited in her reply.
Every tool result carries the paths it read, so Reports and replies can cite them. A cited path counts as a use for activation.

M3  CONTEXT BUDGET, METER AND TUNER (Core, Harness/Context/)
ContextCompiler.compile(agent, ask) -> BrainRequest. It is pure. It fills sections in this order. Each size below is a starting point (a floor the section always gets if it has content), not a cap:
  #  section       what                                                    TTL     start (Haiku and Sonnet alike)
  1  rules         voice and rules of the agent, fixed                     1 h     2K
  2  tools         definitions, fixed order                                (tools) 4K
  3  expertise     the agent's whole domain pack (M4), never trimmed       1 h     as built (expect 20-60K)
  4  core          profile plus every open belief in the agent's areas      1 h     6K
  5  recall        everything that scores above the floor, best first      5 min   36K
  6  episodic      stored turns of the last 24 hours (up to 20) plus today's op digest for the area   -   12K
  7  working       screen, ask, about-objects in full                      -       8K
  8  growth        headroom for tool results within the run                -       whatever is left
  9  output        max_tokens, thinking included                           -       Haiku 16K, Sonnet 32K
How much it takes: recall keeps adding candidates while their score is above the floor (0.5), so a narrow ask gets a small pack and a broad one gets a big pack. Nothing is cut for cost. The only hard limit is the model's window: input stays under 700K so growth and output always fit inside 1M. If even that overflows, the lowest-scoring recall items go first and the pack says "more is kept; open to see it".
No cost step decides a size: Haiku may go past 100K whenever the pack needs it (the ledger prices it at the higher rate, M0 item 4).
Breakpoints: after section 3 (1 h), after section 4 (1 h), after section 5 (5 min), and automatic caching on the tail (5 min). Sections are sorted and stable byte for byte so the prefix caches; this is for speed now, not for cost. A section never borrows from the output reserve.
ContextMeter: after every call, record a TraceSpan extension ContextUse { runID, agent, model, sectionTokens: [section: Int] (chars / 3.6, calibrated), inputTokens, cacheRead, cacheWrite, outputTokens, thinkingTokens (output minus visible text tokens), opens: [path], recalls: Int, cited: [path], hitSections: [section], ttftMs }. Calibration: once a week, count_tokens on 5 real packs and correct the chars-per-token ratio for each section.
BudgetTuner, accuracy first (page-fault style, but the goal is right answers, not savings). For each agent and section, every Sunday 4 am:
  if the agent opened or recalled something more than 0.3 times per run, or an eval miss traces to something that wasn't in the pack -> grow that section's start by 50%, and lower the recall floor by 0.05 (never under 0.3);
  a section shrinks only when the eval sweep shows the smaller size scores the same (no lower by even 1 point), so we never trade accuracy for size;
  no spend guard: a projected spend never blocks a change. The $100 cap still stops calls if a bug runs away.
The table lives in Application Support/Tessera/context-budgets.json (no backup). It ships with the starts above.
Eval sweep (needs M6): once a week, the nightly eval runs on Haiku and Sonnet at four recall settings (floor 0.5 at 1x start, 2x start, 4x start, and "everything above floor 0.3"). The tuner takes the best-scoring setting; on a tie it takes the smaller one, because smaller is faster.

M4  PERSISTENT AGENTS (Core, Harness/Agents/)
An agent is data, not a process. AgentSpec is a system class under /system/tess/agents: name, room (AppID or tess), ladder, tools (names), memory slice (belief areas, notebooks, which summaries), expertise recipe, budget row, maxRounds (10 for Tess, 8 for room agents), children (max 3, depth 2, H4).
Models by accuracy, not price. Thinking is adaptive and on for every Claude call. Haiku 5.5 runs at effort medium, its default. Sonnet 5.5 runs at effort medium for asks and high for plans, the weekly review and the night pass.
  Lookups, counts, small actions and classification go to Haiku. Those are tasks it gets right; a bigger model only overthinks them (his rule).
  Anything open, anything that reasons across days, and every write that changes more than one object go to Sonnet.
  Escalation: when the Door's check fails on an answer, the next rung up retries once with the failed answer and the check's reason appended. The rungs are Haiku, then Sonnet, then Opus 5.5 (claude-opus-5-5, effort high). Opus is used only as that escalation step and for asks where the eval shows Sonnet below 90% on that kind of question. It is never the first rung.
  A call that forces a tool (toolChoice .tool, like PlaybookJob) sends thinking disabled, because a forced tool and thinking don't mix. Haiku accepts disabled at effort high or below. Sonnet never gets a forced tool (auto, as today).
  The eval (M6) keeps a score per model per question kind, and pickRung moves a kind up one rung when its score is under 90%.
Shipped agents: Tess (front desk), Training, Kitchen, Today (tasks, lists, routines), Notes, Money, Body (health, calories, sleep; lab mode only). Money is read only: no agent has a money write tool (`AgentSpec.problems` still flags one). Tess herself may make money changes since his Oct 27 pick (`ClaudeSees.moneyWrites`).
Expertise pack = stable text built from the app's own data and catalog, rebuilt on release and when the catalog changes, never per call. For example, Training gets the exercise library digest (names, muscles, equipment), his current program and phases, his bests table, and the rules the app already uses (e1RM formula, weekly sets). Kitchen gets the pantry classes and shelf-life rules, his recipes' index and the grocery categories. Each pack is a pure function of the store, hashed, and the hash goes in the trace.
Persistence: each agent keeps its notebook (memory tool), its beliefs slice, its budget row and its trace history. A run starts by compiling from them, so an agent "remembers" without a long-lived process. Tess is the only voice: room agents return Reports (H4), never words to him.

M5  GROWTH AND THE NIGHT PASS (Core, at the 4 am turnover)
Rules on the phone: verify noticed beliefs against the record, merge duplicates (same subject and key), close what changed (a change point in the typed series: 3 of the last 4 events off the old pattern), write the day summary (and the week summary on Sundays), prune notebooks over their limits (oldest unused first), refresh expertise packs whose hash changed. With Claude: one Sonnet call (effort high) per agent with activity that day, which reads the day's ops for its area plus its beliefs. Through remember, it may propose up to 5 inferred beliefs, each with evidence paths. Then the tuner (Sundays) and the eval (M6).

M6  NIGHTLY MEMORY EVAL (Core)
Generate about 50 questions a night from the store, with exact answers: find (a set on a date), across days (a count this month), when (a start date), changed (the current open belief after a closed one), don't know (a key with no belief, where the answer must be "I don't know yet"). Run them through the real compiler on Haiku and on Sonnet, and score each model per question kind (that score drives pickRung, M4). Score exactly, and keep a score row per night in Application Support/Tessera/memory-eval.json. Show the last 14 nights as plain lines in Developer mode, under Harness. Cost doesn't limit it; expect well under a dollar a night.

ACCEPT (swift test)
M0: a round with a thinking block and a web_search result sends both back byte for byte; pause_turn continues without using a round; one search adds $0.01; a 120K-token Haiku pack is costed at the higher rate; a 1 h mark after a 5 min mark is rejected.
M1: a belief with no evidence is refused; a change closes the old belief and links the new one; forget deletes and redacts; the migration keeps every told line's words.
M2: recall ranks a linked object above an unlinked one with the same words; nothing above the floor gives the "nothing kept" line; every fetch tool returns paths; the memory tool can't write outside /memories/<its agent>/; Haiku requests use the basic web tools with allowed_callers direct, and Sonnet requests use the 20260318 versions.
M3: compile is deterministic for the same store and ask (same bytes, same hash); every section gets at least its start when it has content; recall includes every item above the floor; input never passes 700K and an overflow drops the lowest-scoring recall first with the "more is kept" line; a Haiku pack over 100K is sent, not cut; breakpoints are in TTL order; the tuner grows a section that faults and never shrinks one unless the sweep shows an equal score; projected spend never blocks a change; a failed check escalates one rung and Opus is never a first rung.
M4: every shipped AgentSpec compiles; an expertise pack's hash changes only when its source data changes.
M5 and M6: a night pass on the demo history writes summaries, closes a changed belief, and produces an eval row; a second run the same night does nothing.
App: Developer mode, Harness: "Context" (the last run's section sizes and what was used), "Budgets" (the table), "Memory eval" (14 nights). Plain lines only.

ORDER: M0 -> M1 -> M2 -> M3 -> M4 -> M5 -> M6. M0 goes before H3 merges if possible, since H3's loop needs the verbatim content and pause_turn.
