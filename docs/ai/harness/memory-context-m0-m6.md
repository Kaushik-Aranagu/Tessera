MEMORY AND CONTEXT BUILD TEXT, M0 to M6 (Oct 23, for Core; relay word for word)

Kaushik's ask (Oct 23, 5:51 PM PT): use as much context as possible, with set sizes for each kind of memory, a little kept for working memory and some for each agent's own expertise. Memory is linked, it grows, and agents can fetch more themselves: from saved memory, other pages and objects, documents, and the internet. Measure how much each call and its thinking really use, then tune the sizes. Agents are persistent. Everything ships On. His standing rules hold: lab policy On, the key never leaves ClaudeBrain, the $50 cap and 80% step-aside stay, and a stored Tess turn keeps its walls.

Facts this rests on (Claude API docs, Oct 2026): Haiku 5.5 and Sonnet 5.5 both have a 1M-token context and 128K max output. Haiku 5.5 costs $0.10 in and $0.50 out per million up to 100K input tokens, and $0.50 and $2.50 past that. Sonnet 5.5 costs $2 and $10, with cache reads at $0.20. Writing to the cache costs 1.25x for the 5-minute TTL and 2x for the 1-hour TTL. The minimum cacheable prefix is 512 tokens, with at most 4 breakpoints, and longer-TTL entries must come before shorter ones. Sonnet 5.5 refuses forced tool_choice. Thinking blocks must be sent back unchanged, and a history edit invalidates later thinking. Web search costs $10 per 1,000 searches plus tokens. Web fetch costs only tokens and can fetch only URLs that already appear in the conversation.

THE IDEA IN ONE LINE
Every call is rebuilt from persistent memory, not from a growing transcript. A context compiler fills a fixed budget, section by section, from stores that grow without limit. The model can page in more through fetch tools. Haiku gets the big context because it is about 20 times cheaper; Sonnet gets a compact one plus Haiku's digests.

M0  HARNESS FIXES THE LOOP NEEDS FIRST (Core, Harness/)
1 Verbatim assistant content. Add BrainContent.raw(Data): one content block as the API sent it. SSEParser keeps every block of the assistant message (text, tool_use, thinking with its signature, redacted_thinking, server_tool_use, web_search_tool_result, web_fetch_tool_result) and emits BrainEvent.assistant([Data]) before .done. TessRun appends that message unchanged before the next round. Never rebuild an assistant message from text deltas. This keeps thinking valid, keeps encrypted search results valid, and keeps the cache.
2 pause_turn. When stop is pause_turn, send the paused assistant message back unchanged as the next round. It does not count as one of the 3 rounds.
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
  web_search and web_fetch (server tools): Sonnet gets web_search_20260318 and web_fetch_20260318, max_uses 3 each, response_inclusion "excluded". Haiku gets web_search_20250305 and web_fetch_20250910 with allowed_callers ["direct"], max_uses 2. Read each model's capabilities.server_tools from GET /v1/models/{id} at launch and leave out what it doesn't support. web_fetch max_content_tokens is 12,000. Search results are never stored as beliefs, only cited in her reply.
Every tool result carries the paths it read, so Reports and replies can cite them. A cited path counts as a use for activation.

M3  CONTEXT BUDGET, METER AND TUNER (Core, Harness/Context/)
ContextCompiler.compile(agent, ask) -> BrainRequest. It is pure, and it fills sections in this order, each up to its budget:
  #  section       what                                              TTL     Haiku   Sonnet
  1  rules         voice and rules of the agent, fixed              1 h     2K      2K
  2  tools         definitions, fixed order                         (tools) 4K      4K
  3  expertise     the agent's domain pack (M4), changes on release 1 h     24K     8K
  4  core          profile plus the agent's top beliefs, daily      1 h     4K      3K
  5  recall        ranked beliefs, summaries, linked objects        5 min   36K     12K
  6  episodic      last 4 turns plus today's op digest for the area  -       8K      5K
  7  working       screen, ask, about-objects                        -       6K      4K
  8  growth        headroom for tool results within the run          -       10K     12K
  9  output        max_tokens, thinking included                     -       4K      12K
  Haiku total about 98K (under the 100K price step). Sonnet total about 62K.
Breakpoints: after section 3 (1 h), after section 4 (1 h), after section 5 (5 min), and automatic caching on the tail (5 min). Sections are sorted and stable byte for byte so the prefix caches. A section never borrows from the output reserve. Unused budget flows down to recall.
ContextMeter: after every call, record a TraceSpan extension ContextUse { runID, agent, model, sectionTokens: [section: Int] (chars / 3.6, calibrated), inputTokens, cacheRead, cacheWrite, outputTokens, thinkingTokens (output minus visible text tokens), opens: [path], recalls: Int, cited: [path], hitSections: [section] }. Calibration: once a week, count_tokens on 5 real packs and correct the chars-per-token ratio for each section.
BudgetTuner, page-fault-frequency style (the OS working-set rule): for each agent and section, every Sunday 4 am:
  if the agent opened or recalled something more than 0.3 times per run, and a larger recall section would have held it -> grow recall by 25%;
  if under 5% of a section's items were cited or opened over 20 runs -> shrink it by 20%;
  floors at half the defaults, ceilings at 2x the defaults, and the Haiku total stays under 100K;
  a change that would push the month's projected spend past 80% of the $50 cap is not made.
The table lives in Application Support/Tessera/context-budgets.json (no backup). It ships with the defaults above.
Eval sweep (needs M6): once a week, the nightly eval runs at three recall sizes on Haiku (0.5x, 1x, 2x). The tuner moves the default to the smallest size that scores within 2 points of the best.

M4  PERSISTENT AGENTS (Core, Harness/Agents/)
An agent is data, not a process. AgentSpec is a system class under /system/tess/agents: name, room (AppID or tess), ladder (e.g. [.haiku, .appleOnDevice]; Sonnet only for Tess's open asks and the weekly review), tools (names), memory slice (belief areas, notebooks, which summaries), expertise recipe, budget row, maxRounds (3), children (max 3, depth 2, H4).
Shipped agents: Tess (front desk), Training, Kitchen, Today (tasks, lists, routines), Notes, Money, Body (health, calories, sleep; lab mode only). Money is read only: no agent ever gets a money write tool (his standing rule).
Expertise pack = stable text built from the app's own data and catalog, rebuilt on release and when the catalog changes, never per call. For example, Training gets the exercise library digest (names, muscles, equipment), his current program and phases, his bests table, and the rules the app already uses (e1RM formula, weekly sets). Kitchen gets the pantry classes and shelf-life rules, his recipes' index and the grocery categories. Each pack is a pure function of the store, hashed, and the hash goes in the trace.
Persistence: each agent keeps its notebook (memory tool), its beliefs slice, its budget row and its trace history. A run starts by compiling from them, so an agent "remembers" without a long-lived process. Tess is the only voice: room agents return Reports (H4), never words to him.

M5  GROWTH AND THE NIGHT PASS (Core, at the 4 am turnover)
Rules on the phone: verify noticed beliefs against the record, merge duplicates (same subject and key), close what changed (a change point in the typed series: 3 of the last 4 events off the old pattern), write the day summary (and the week summary on Sundays), prune notebooks over their limits (oldest unused first), refresh expertise packs whose hash changed. With Claude: one Haiku call per agent with activity that day, which reads the day's ops for its area plus its beliefs. Through remember, it may propose up to 5 inferred beliefs, each with evidence paths. Then the tuner (Sundays) and the eval (M6).

M6  NIGHTLY MEMORY EVAL (Core)
Generate about 50 questions a night from the store, with exact answers: find (a set on a date), across days (a count this month), when (a start date), changed (the current open belief after a closed one), don't know (a key with no belief, where the answer must be "I don't know yet"). Run them through the real compiler and Haiku. Score exactly, and keep a score row per night in Application Support/Tessera/memory-eval.json. Show the last 14 nights as plain lines in Developer mode, under Harness. About $0.02 a night.

ACCEPT (swift test)
M0: a round with a thinking block and a web_search result sends both back byte for byte; pause_turn continues without using a round; one search adds $0.01; a 120K-token Haiku pack is costed at the higher rate; a 1 h mark after a 5 min mark is rejected.
M1: a belief with no evidence is refused; a change closes the old belief and links the new one; forget deletes and redacts; the migration keeps every told line's words.
M2: recall ranks a linked object above an unlinked one with the same words; nothing above the floor gives the "nothing kept" line; every fetch tool returns paths; the memory tool can't write outside /memories/<its agent>/; Haiku requests use the basic web tools with allowed_callers direct, and Sonnet requests use the 20260318 versions.
M3: compile is deterministic for the same store and ask (same bytes, same hash); no section passes its budget; the Haiku total stays under 100K; breakpoints are in TTL order; the tuner grows a section that faults and shrinks one that's never used, inside its floor and ceiling; the spend guard blocks growth near the cap.
M4: every shipped AgentSpec compiles; an expertise pack's hash changes only when its source data changes.
M5 and M6: a night pass on the demo history writes summaries, closes a changed belief, and produces an eval row; a second run the same night does nothing.
App: Developer mode, Harness: "Context" (the last run's section sizes and what was used), "Budgets" (the table), "Memory eval" (14 nights). Plain lines only.

ORDER: M0 -> M1 -> M2 -> M3 -> M4 -> M5 -> M6. M0 goes before H3 merges if possible, since H3's loop needs the verbatim content and pause_turn.
