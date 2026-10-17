# B2: Claude jobs, offline and retry table (draft)

Sources: origin/master docs/ai/ (claude-client, architecture 5.5 and 6, old-callers, home-lines-job,
week-story-job, ask-subject-pack, side-jobs, spend-projection). Month cap $50, a hard stop; it resets on the 1st. At 80% ($40) Home lines, the week story and living colour step aside before the reserve; capture, plan, recipe and questions run to $50.
Shared rules: switch off, demo, no key, and money or secret packs send nothing and write no row.
At the cap every job gets "Claude paused until <date>." and no row. No job retries today.

| Job | Timeout | Retries | User sees offline or on failure | Cache or ledger effect | Cap and step-aside |
|---|---|---|---|---|---|
| Tess capture ("capture", Haiku, up to 3 rounds) | 8 s | None | Offline: "No connection. Saved it for Claude." Other failures: the five Failure lines | Offline text waits in TessInbox and is read later. One row per run, use .capture, tokens summed | Priority .capture, never steps aside. Cap: paused line, no row |
| Home lines, incl. done lines (Sonnet) | 6 s | None | Rules lines at once. Cached words for unchanged items. Failure lines never shown on Home, Settings only | Pack-hash cache, day-keyed JSON file. No queue. Max 1 call per 10 min, 40 a day (docs only). Row says why on a reject | .lines steps aside at $40 before reserve. Cap: .refused(.cap), rules lines |
| Workout done line (part of Home lines) | 6 s | None | Rules line stays. A timeout is final: that finish is never asked again | Cached by workout id only, one call per finish, ever | Same as Home lines. Done lines go quiet first, intended |
| Week story (Sonnet) | 20 s | None | All three rules lines stay (no mixing), nothing visible | Pack-hash cache in the Home lines file. Row records the reason. Once a week, Monday after 04:00 | Steps aside at $40 before the reserve (word job). Rules lines |
| Plan my day wording ("plan", Sonnet) | 20 s hard deadline | None. Same-pack reuse and a failure remembered for the day spend nothing | The usual plan, with a failure line. Cap line: "Claude paused until <date>. Here's your usual plan." | Row per call in a defer. Outcomes include "late", "rejected <codes>", "cancelled". Late reply dropped, cost kept | Priority .plan, keeps running at $40. Cap: paused line, no row |
| Recipe reader ("recipeLink", Haiku) | 20 s in code and old-callers (architecture table says 15 s) | None in code | The no-recipe line; offline or busy mapped by outcome | Row use .paste, requestID nil. Page fetch has its own redirect guard | Priority .recipe, keeps running at $40. Cap: RecipeLinkLine.paused, no row |
| askSubject (Sonnet) | 8 s | None | The phone answers alone. Refused asks make no Claude event | 20 asks a day, 21st sends nothing and writes no row. Row job "askSubject" | Priority .asks, keeps running at $40 (questions run to $50). Cap line only at the cap |
| fillFacts (Sonnet, side-jobs) | Not stated | Not stated | A decline stores nothing; the side is complete without the row | factsAsked date set on any answer, so asked once, ever. Fact stored with "From Claude" source | Not stated. Off until eval passes and Kaushik says yes |
| Grocery connect ("linkItems", Haiku) | 8 s | Not stated | Not stated (names stay unmatched) | Row per call. About 60 calls a month | Priority not stated |
| Key check ("keyCheck") | Not stated | None | Own Outcome lines in Settings | count_tokens first, cost 0. Fallback path reserves, else "capReached" at cost 0 | Fallback stops at the cap. No switch, called from Settings |
| Living colour (Haiku, architecture section 9) | Not stated | Not stated | Stays on current palette, nothing visible | Result cached on pack hash, 31 calls a month at most | Steps aside at $40 before the reserve (word job) |

## Gaps and contradictions to resolve
1. Recipe timeout: architecture section 6 says 15 s; old-callers and the spec say 20 s.
2. Recipe 504: shared table maps 504 to timeout; the recipe reader maps it to busy (kept byte-identical).
3. Hard deadline: claude-client lists a late-reply drop as shared, but only ClaudePlanWording has it. Capture and
   recipe rely on the idle URLRequest timeout today.
4. Step-aside scope: settled (Product 8:16): lines, week story and living colour step aside at $40; capture, plan,
   recipe and questions run to $50. Groceries link is in none of them; claude-client text to follow.
5. Home lines: the 40-a-day count, 10-minute debounce and 80% step-aside are docs only; no code yet.
6. fillFacts has no timeout, priority, ledger job name or retry. Needs a TessJob entry.
7. Recipe retry: spend-projection cites recipe-link-fetch.md pricing a Sonnet retry ($0.026); code has Haiku only,
   and claude-client says no retries today.
8. Cap wording: settled at $50. ClaudeKey.swift still says "The $10 month" (Swift, not changed here).
9. A cancelled URLError is "offline" for capture but "cancelled" (no line) for plan.
10. Done line timeout is final (never re-asked); Home line timeouts retry on the next pack change. State this in B2.
