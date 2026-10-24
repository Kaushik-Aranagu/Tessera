# Harness: things to check and improve

A running list (started Oct 23, 6:35 PM PT). Kaushik's rule since 6:14 PM: accuracy first, cost later. Each item
names what it protects and how we'd know. When one is done, mark it with the PR that did it. Add new ones at the
bottom of their group.

## Checks: things that must stay true

| # | Check | How we'd know |
|---|---|---|
| C1 | The key never leaves `ClaudeBrain`. | Test: run a session of asks, some with key-shaped text. No span, sent-log row, checkpoint, `ContextUse` or pack has a key-shaped string, and no key-shaped ask reaches the Door. |
| C2 | Stored turns keep their walls. Lab rows and checkpoints stay out of backups. | Test: back up after a lab-mode money ask. The backup has no lab row, no Tess turn and no `tess-runs.json`. |
| C3 | Thinking and web results are replayed byte for byte (M0). | Fixture: a recorded multi-round SSE stream with thinking, `server_tool_use` and `web_search_tool_result`. Round 2's request carries round 1's blocks unchanged. On a real call, the response's `input_transformations` is empty. |
| C4 | No clock, counter or random text in cached sections. | Test: compile the same ask twice a minute apart. Rules, expertise and core are byte-identical. On his phone, the cache-read share per agent (from `ContextUse`) stays high. |
| C5 | Packs are deterministic. | Test (in the packer PR): same items, same bytes. Later the same for the whole compiler: same store and ask, same hash. |
| C6 | Every number Tess says matches the store. | A Door check on replies: each number tied to a cited path must equal that object's value (sets, weights, counts, money). A mismatch fails the check and escalates one rung. |
| C7 | "I don't know" when nothing is kept. | Eval "don't know" kind: 100% abstain. Any made-up answer there is a red test. |
| C8 | Escalation can't loop. | Test: a check that always fails. Haiku, then Sonnet, then Opus, at most once each per ask, then the phone line. |
| C9 | The $100 cap stops a runaway. | Test: a fake brain that always asks for a tool. Calls stop at the cap and at the round limit, whichever comes first. |
| C10 | Day and week edges are right. | Eval questions at 3:59 and 4:01 am, on Sunday night and Monday morning, around a time change (Nov 1). "Yesterday" and "this week" use the 4 am edge and Monday weeks. |
| C11 | Units are right in answers. | Eval: the same set asked in lb and in kg. The reply uses his unit and the stored value. |
| C12 | Web search follows the policy. | His pick (Oct 23, 7:59 PM PT): under lab, a search query may carry health and money specifics; under strict it carries none. Walled titles never go, under either. Search results never become beliefs. Test: a health-flavored ask that searches the web, once per policy. Under strict, the query has no walled words, numbers from walled classes or names. Under lab, it may name the number, but never a walled title. |
| C13 | Fetched pages and notes can't steer writes. | Test: a fetched page says "add a task". No write happens without a pending row he keeps. Search results never become beliefs (M2 rule). |
| C14 | Expertise packs follow the catalog. | Test: change an exercise's muscles, and the Training pack's hash changes. Change nothing, and it stays the same. |
| C15 | Token estimates stay calibrated. | Weekly calibration row in Developer mode: the estimate is within 10% of `count_tokens` for each section. |
| C16 | Server tools exist for each model. | Launch read of `GET /v1/models/{id}` capabilities. A model without web tools gets none, and the trace says so. |
| C17 | Offline still answers what the phone can. | Test: no network. Lookups answer from the Apple model or rules, and open asks get the phone line. Nothing hangs past the deadline. |
| C18 | Big packs stay usable. | Measure on his phone: first-token time at 50K, 200K and 500K input for Haiku and Sonnet. Accuracy wins, but past about 10 s we show it in Developer mode and look again. |

## Improvements: ways to be more right

| # | Idea | Why |
|---|---|---|
| I1 | A typed query tool: `query(class, filter, group, measure)` over the store, returning exact rows and totals. | Counts, sums and bests come from the store, not from model arithmetic. This is the biggest accuracy win for "how many", "how much" and "best". |
| I2 | Citations required: every factual sentence in a reply names the paths it rests on. Uncited facts fail the check. | Makes C6 checkable, and the citations feed activation and the tuner. |
| I3 | A grounding pass: Haiku reads the reply and its cited items and flags any claim the items don't support. | Catches confident wrong answers before he sees them. Accuracy first makes the extra call worth it. |
| I4 | Ask back instead of guessing: when the ask fits two objects about equally (two "Push A"s, two chilis), Tess asks one short question. | Wrong-object answers are the most common failure in agents over personal data. |
| I5 | Eval failures become regression tests: every missed nightly question is kept and rerun each night until it passes for a week. | The eval grows from real misses, not only generated ones. |
| I6 | Per-kind model scores pick the rung (M4), shown as a small table in Developer mode. | We see which model handles which kind of question, instead of guessing. |
| I7 | A night contradiction pass: two open beliefs that disagree (trains at 6 and trains at 7) are closed or merged with the record's evidence. | Keeps core beliefs consistent before they reach every pack. |
| I8 | Precompiled packs for the morning's likely asks (M5 "prepare"). | The first ask of the day is fast without trimming anything. |
| I9 | Month and year summaries above the week ones. | "Since I started" questions get a path to open instead of thousands of rows. |
| I10 | Free-text embeddings on the Mac edge for notes and recipe steps. | Better `fit` for "spicy" style asks. Typed things keep using links. |
| I11 | A "why" view: tap a Tess answer to see the paths she used and the model that answered. | He can see where an answer came from, and tell us when it was wrong. That gives us labels. |
| I12 | Room agents report with handles and a digest (H4), and Tess re-reads the handles she cites. | Keeps the voice single without losing the room agents' precision. |

## Open questions for Kaushik

- **C12 (answered Oct 23, 7:59 PM PT):** under lab, web searches may carry health and money specifics; strict keeps
  them out.
- **Spending cap:** the $100 monthly cap stays as a runaway guard only. World test runs may use up to $50 of it.
