# AI ship list

For: Product (take as is). Owner: AI architecture team. Date: Oct 16, 2026 (Pacific).
Design: `docs/ai/architecture.md`. Features: `docs/ai/first-features.md`.

**Reordered Oct 16, 12:20 AM PT.** Kaushik: explore memory, profile and context first; the graph is small, so pick models and architecture to suit; he has $200 a month of credits. So memory (AI-7 to AI-9) now comes right after the plain Home lines (AI-1), ahead of Claude wording; Home lines and the week story move to Sonnet 5.5; and a memory experiment (AI-0) decides the shape before AI-7 is built. Cap: **$10 today, $50 proposed** by Product (772c450); Kaushik hasn't said yes yet. One constant (`TessUsageLedger.capNano`), raised in AI-2 only after his yes. Product's order: AI-1, AI-7, AI-8, AI-9, AI-2, AI-3, AI-5, AI-4, AI-10, AI-6, AI-11, AI-12. Models per job on quality; AI-5's eval decides Haiku against Sonnet.

Order is the build order. Each slice is one small PR. "Rules" slices need no key and no network.

| # | Slice | Owner | Done when |
|---|---|---|---|
| AI-1 | **Short rules lines on Home** (feature 1a) | Core: `HomeLines` lens in TesseraCore. Builder B: Home reads it | Every Home item shows one `HomeLines` line; no `lineLimit(1)` + `truncationMode` on any Tess line (`NowPage.swift:538`, `HomeQueue.swift:346`); `WorkoutSummary.line` counts move to the Training page; unit tests for the nine rules rows; 60fps recording on the demo day. Follows Design 41's sheet |
| AI-0 | **Memory experiment** (runs on fixtures, no app code) | AI team | Three shapes tried on `docs/research/fixtures/` days with real calls: (a) one plain profile block in every prompt, (b) per-area memory picked by job, (c) Claude writes its own noticed notes, checked on the phone. Scored on Home lines H1-H12 and the week story for truth, voice and cost; a short report with the winning shape and its token size. Decides AI-7's fields |
| AI-7 | **Memory store** | Core | `TessMemory` class (Catalog v6, additive): told, noticed, recent; screen for health, money and unlicensed digits; recent line written at 04:00 turnover from `DayStory`; noticed lines recomputed Sunday 04:00 on the phone (training time of day, routine order, cook days); `private` facts never packed; trim rules from architecture section 4; in backups |
| AI-8 | **"Remember that…"** | Core: grammar phrase + `remember` tool | "remember that …" lands as a pending told fact with the 2 s dry and UNDO; Claude can call `remember` on misses; Siri and Shortcuts never write memory |
| AI-9 | **What Tess knows page** | Builder B, on Design's m4-steers section 11 | Facts with their source line; swipe left to FORGET with 10 s UNDO; forgotten text redacted from earlier ops (Core helper); "Forget everything"; reached from Settings and "what do you know" |
| AI-2 | **`ClaudeClient` and `TessJob`** | Core | One client does reserve, send, failure lines, ledger row (with a new `job` field on `TessCall`), switch and demo gates, `sk-ant-` refusal, late-reply drop; stub `URLSession` tests for every status code. Existing four callers untouched; `capNano` raised to $50 only after Kaushik's yes |
| AI-3 | **Shared line checks** | Core | `TessLineCheck` (ids, word and character budget, licensed numbers, names from the pack, `TessVoice` and plan banned and health words) lifted out of `PlanProposalValidator`; plan tests still pass unchanged |
| AI-5 | **Home lines eval** (gate for turning AI-4 on) | Research or QA, from `first-features.md` fixtures, grown to 40 | Research's rubric `docs/research/ai5-home-lines-eval.md` (#332): checks C1-C14, truth 100%, voice 80%; E1-E20 gate the release, the 27 memory-days moments run as a second pass for truth and voice; cost gate per model, Haiku under $0.0004 and Sonnet under $0.006 a call. Kaushik reads 10 and says 8 sound like Tess. If Haiku fails and Sonnet passes, ship Sonnet |
| AI-4 | **Home lines through Claude** (feature 1b) | Core: `homeLines` job (model per AI-5), pack, cache file, debounce. Builder B: swap-in | Lines swap in only when they pass AI-3; pack snapshot test shows no weights, reps, health or notes; offline, cap, switch off and demo show rules lines; at 80% of the month the job steps aside; max 40 calls a day. Recording of a line drying in (Design 41's motion) |
| AI-10 | **Home lines read memory** | Core | `homeLines` pack adds the last 7 recent lines and up to 10 noticed training lines; fixtures H5 and H2 pass |
| AI-6 | **Settings copy for the switch** | Design copy, Builder B | The yes line names Home: "Tess asks Claude when she's unsure, for Plan my day, and to word Home and your week." (Design may change words.) |
| AI-11 | **The week, told** (feature 2) | Core: `WeekFacts` lens and `weekStory` job (Sonnet 5.5). Builder B: Review top | Three lines on Review, worded Sunday after 04:00 and when week facts change; handles link; same checks; rules version (three plain count lines) when Claude is off |
| AI-12 | **Groceries that know your recipes** (feature 3, corrected with the Kitchen lead) | Recipes and groceries lead specs with Design 47; Core: `linkItems` job; Builder B | Claude only matches names (`linkItems`, strict, no `addGroceries`); matches land as ghost rows he keeps as `GroceryShare` rows or drops; missing ingredients, staples and "usually have" stay phone rules; no notification ever (Product): the planned cook's Home line carries the count; ingredient titles sent, never typed lines; 0 wrong matches in 3 runs on the kitchen fixtures |
| AI-13 | **Old callers onto `ClaudeClient`** | Core, only when already in the file | Capture, plan, recipe link and key check use `ClaudeClient`; no change in behaviour or ledger rows |
| AI-14 | **Living soul colour** (architecture section 9; Design 48 `docs/design/living-colours.md` 8cac57a; Product ea55257) | Core: rule table, cadence gate (at most 3 a day, 2 h apart, idle only, never in a workout or quiet hours except the 04:00 turnover), `LivingPalette` store, `soulPalette` job once a day under the switch. Builder A: repaint. AI team: `proposeSoul` contract | `proposeSoul` returns only a palette name from Design's per-look table (Today, Kiln, Lagoon, Orchard, Aurora, Ember) and two nudges, warmth ±0.2 and weight ±0.2; the phone clamps and decides when; offline or capped keeps today's colours; FORGET pins her back; under $0.01 a month. After AI-4 and Design 48 |

**First visible win:** AI-1 alone answers his "three dots" and "too much detail" notes, with no key involved.
**First Claude win:** AI-4 after AI-5 passes, now with memory (AI-7) already in its pack.
**Month cost when all of this is on:** about $4 with Sonnet on Home lines and the week story (architecture section 5.6), against the $10 cap ($50 proposed).

## Decisions taken as defaults (no question to Kaushik needed)

- Home lines use the one "Tess asks Claude" switch.
- Live workout lines stay rules-only, no network while he lifts.
- Memory is counted on the phone; Claude never sees history, only finished lines.
- Body facts he tells Tess stay on the phone.
- Memory rides in backups; the key and the miss log still never do.
