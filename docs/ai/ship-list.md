# AI ship list

For: Product (take as is). Owner: AI architecture team. Date: Oct 16, 2026 (Pacific).
Design: `docs/ai/architecture.md`. Features: `docs/ai/first-features.md`.

**Reordered Oct 16, 12:20 AM PT.** Kaushik: explore memory, profile and context first; the graph is small, so pick models and architecture to suit; he has $200 a month of credits. So memory (AI-7 to AI-9) now comes right after the plain Home lines (AI-1), ahead of Claude wording; Home lines and the week story move to Sonnet 5.5; and a memory experiment (AI-0) decides the shape before AI-7 is built. Cap: still $10 until he says; the team's recommendation is $50 (`TessUsageLedger.capNano`, one number).

Order is the build order. Each slice is one small PR. "Rules" slices need no key and no network.

| # | Slice | Owner | Done when |
|---|---|---|---|
| AI-1 | **Short rules lines on Home** (feature 1a) | Core: `HomeLines` lens in TesseraCore. Builder B: Home reads it | Every Home item shows one `HomeLines` line; no `lineLimit(1)` + `truncationMode` on any Tess line (`NowPage.swift:538`, `HomeQueue.swift:346`); `WorkoutSummary.line` counts move to the Training page; unit tests for the nine rules rows; 60fps recording on the demo day. Follows Design 41's sheet |
| AI-0 | **Memory experiment** (runs on fixtures, no app code) | AI team | Three shapes tried on `docs/research/fixtures/` days with real calls: (a) one plain profile block in every prompt, (b) per-area memory picked by job, (c) Claude writes its own noticed notes, checked on the phone. Scored on Home lines H1-H12 and the week story for truth, voice and cost; a short report with the winning shape and its token size. Decides AI-7's fields |
| AI-7 | **Memory store** | Core | `TessMemory` class (Catalog v6, additive): told, noticed, recent; screen for health, money and unlicensed digits; recent line written at 04:00 turnover from `DayStory`; noticed lines recomputed Sunday 04:00 on the phone (training time of day, routine order, cook days); `private` facts never packed; trim rules from architecture section 4; in backups |
| AI-8 | **"Remember that…"** | Core: grammar phrase + `remember` tool | "remember that …" lands as a pending told fact with the 2 s dry and UNDO; Claude can call `remember` on misses; Siri and Shortcuts never write memory |
| AI-9 | **What Tess knows page** | Builder B, on Design's m4-steers section 11 | Facts with their source line; swipe left to FORGET with 10 s UNDO; forgotten text redacted from earlier ops (Core helper); "Forget everything"; reached from Settings and "what do you know" |
| AI-2 | **`ClaudeClient` and `TessJob`** | Core | One client does reserve, send, failure lines, ledger row (with a new `job` field on `TessCall`), switch and demo gates, `sk-ant-` refusal, late-reply drop; stub `URLSession` tests for every status code. Existing four callers untouched |
| AI-3 | **Shared line checks** | Core | `TessLineCheck` (ids, word and character budget, licensed numbers, names from the pack, `TessVoice` and plan banned and health words) lifted out of `PlanProposalValidator`; plan tests still pass unchanged |
| AI-4 | **Home lines through Claude** (feature 1b) | Core: `homeLines` job on Sonnet 5.5 (Haiku if AI-5 shows no difference), pack, cache file, debounce. Builder B: swap-in | Lines swap in only when they pass AI-3; pack snapshot test shows no weights, reps, health or notes; offline, cap, switch off and demo show rules lines; at 80% of the month the job steps aside; max 40 calls a day. Recording of a line drying in (Design 41's motion) |
| AI-5 | **Home lines eval** (gate for turning AI-4 on) | Research or QA, from `first-features.md` fixtures, grown to 40 | Haiku 5.5 and Sonnet 5.5 side by side, 3 runs each: 0 lines shown that fail a check, every ✗ fixture caught, median cost under $0.0004 a call. Kaushik reads 10 and says 8 sound like Tess. If Haiku fails and Sonnet passes, ship Sonnet |
| AI-6 | **Settings copy for the switch** | Design copy, Builder B | The yes line names Home: "Tess asks Claude when she's unsure, for Plan my day, and to word Home and your week." (Design may change words.) |
| AI-10 | **Home lines read memory** | Core | `homeLines` pack adds the last 7 recent lines and up to 10 noticed training lines; fixtures H5 and H2 pass |
| AI-11 | **The week, told** (feature 2) | Core: `WeekFacts` lens and `weekStory` job (Sonnet 5.5). Builder B: Review top | Three lines on Review, worded Sunday after 04:00 and when week facts change; handles link; same checks; rules version (three plain count lines) when Claude is off |
| AI-12 | **Groceries that know your recipes** (feature 3) | Recipes and groceries lead to spec with Design 47; Core job; Builder B | Proposal only from this team; done-when lives in the Groceries AI spec (board item 3, next from this team) |
| AI-13 | **Old callers onto `ClaudeClient`** | Core, only when already in the file | Capture, plan, recipe link and key check use `ClaudeClient`; no change in behaviour or ledger rows |
| AI-14 | **Living soul colour** (architecture section 9; his Oct 16 12:08 AM PT ask) | Design: palette space and nudge ranges. Core: on-phone rules picker, `LivingPalette`, contrast clamp, `soulPalette` job once a day. Builder A: `SoulPalette.look(_:living:)` and the idle-only crossfade | Claude returns only a Design palette name plus clamped nudges; on-phone rules pick by default; Claude at most once a day under the switch, cached; never mid-moment or in a workout; resting opacity, the voice token and Done untouched; offline or capped keeps today's colours; FORGET pins her back; under $0.01 a month. After AI-4 and Design 48 |

**First visible win:** AI-1 alone answers his "three dots" and "too much detail" notes, with no key involved.
**First Claude win:** AI-4 after AI-5 passes, now with memory (AI-7) already in its pack.
**Month cost when all of this is on:** about $4 with Sonnet on Home lines and the week story (architecture section 5.6), against a $10 cap today, $50 recommended.

## Decisions taken as defaults (no question to Kaushik needed)

- Home lines use the one "Tess asks Claude" switch.
- Live workout lines stay rules-only, no network while he lifts.
- Memory is counted on the phone; Claude never sees history, only finished lines.
- Body facts he tells Tess stay on the phone.
- Memory rides in backups; the key and the miss log still never do.
