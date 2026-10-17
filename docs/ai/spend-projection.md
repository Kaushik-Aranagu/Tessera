# Claude spend projection per job (after AI-2)

For: AI architecture, Core, Product. Date: Oct 16, 2026 (Pacific). No calls were made to write this.

The in-app Claude cap is $50 a month, a hard stop; it resets on the 1st (`TessUsageLedger.capNano = 50_000_000_000` n$,
Product's 8:16 ruling). Dev credits ($200 a month) are not counted in the cap. The 80% line is **$40**. Prices are `TessUsageLedger.prices` in code: Haiku 5.5 100 n$ in and 500 n$ out per token
($0.10 and $0.50 per million), Sonnet 5.5 2,000 and 10,000 n$ ($2 and $10 per million), no cache hits. A month is
30 days. **M** = measured on real calls; **A** = assumed (character-count estimates from the docs named).

## Per job

| Job | Model | Calls/day typ / worst | Tokens in / out | Per call | Month typ | Month worst |
|---|---|---|---|---|---|---|
| Home lines, done job only (AI-4, Oct 17: one call per finish) | Sonnet 5.5 | 1 / 3 | 600 / 80 A (1,200 / 512 max) | $0.0020 A ($0.0075 max) | $0.06 | $0.68 |
| Week story (AI-11) | Sonnet 5.5 | 8 a month / 2 | 2,000 / 300 A | $0.007 A ($0.01 gate) | $0.06 | $0.60 (at the $0.01 gate price) |
| Plan my day | Sonnet 5.5 | 2 / 5 | 1,000 / 300 A (1,270 / 1,024 max) | $0.005 A ($0.0128 max) | $0.30 | $1.92 |
| Recipe reader (L3) | Haiku 5.5 | 10 a month / 1 | 7,000 / 1,200 A (4,096 max out) | $0.0013 A ($0.0027 max) | $0.01 | $0.08 |
| Groceries link (AI-12) | Haiku 5.5 | 2 / 4 | 1,200 / 150 A | $0.00022 M | $0.01 | $0.03 |
| Misses (capture) | Haiku 5.5 | 5 / 20 | 5,150 / 130 A over 2 rounds | $0.0006 A | $0.09 | $0.35 |
| Ask (log question) | Haiku 5.5 | 5 / 10 | 3,000 / 100 A | $0.00035 A ($0.00066 two turns) | $0.05 | $0.20 (at the two-turn $0.00066) |
| Living colour (AI-14) | Haiku 5.5 | 1 / 1 | 1,200 / 60 A | $0.00015 A | $0.005 | $0.005 |
| Ask about this (`askSubject`, opt-in) | Sonnet 5.5 | 3 / 20 | 500 / 100 A (810 / 300 max) | $0.0020 A ($0.0046 max) | $0.18 | $2.77 |
| Facts Claude may fill (once per new thing) | Sonnet 5.5 | 10 a month / 100 | 700 / 45 A (900 / 80 max) | $0.0019 A ($0.0026 max) | $0.02 | $0.26 |
| Key check | Haiku 5.5 | rare | count_tokens, free; fallback "Hi" | about $0 | $0.00 | $0.00 |

Where each number comes from:
- **Home lines.** Tokens and $0.0045 from `ai5-home-lines-eval.md` Q2 and architecture 5.6. Measured: Sonnet shape A
  at $0.0018 a call over 81 calls (`memory-experiment-results.md`), on a smaller pack with no detail line. Worst is the
  40-a-day cap in architecture 5.5 and ship list AI-4. On Haiku it would be $0.0002 a call, $0.27 at worst.
- **Week story.** Architecture 5.6 (8 a month); the AI-11 eval gate allows up to $0.01. Worst assumes it rewords twice
  a day as week facts change; no doc or code caps it.
- **Plan my day.** `claude-first-uses.md` use 2; worst is 5 a day, all at `max_tokens` 1,024 (`PlanWording.swift`). Max in is 1,270: a full
  400-token pack plus the ~870-token fixed part (Research's pack fixture; Product, Oct 16 12:06 PM PT).
- **Recipe reader.** `recipe-link-fetch.md` 2d; worst is 30 a month at `max_tokens` 4,096 (`RecipeLinkReader.swift`).
- **Groceries link.** Measured $0.0011 for one run of 5 calls (`groceries-link-eval-results.md`); tokens from
  architecture 5.6. Worst is assumed.
- **Misses and ask.** `claude-first-uses.md` uses 1 and 3. The ledger holds more per miss before it is sent:
  3 rounds x 507,000 n$ = $0.0015 (`ClaudeTessModel.maxRounds = 3`), so 600 misses at that ceiling is $0.91.
- **Living colour.** Architecture section 9: at most once a day, under $0.01 a month.

## Totals against the cap

| | Typical | Worst |
|---|---|---|
| All jobs | **$0.79** (2% of $50) | **$6.90** (14%); $7.46 with misses at their held ceiling |
| Headroom to $40 (80%) | $39.21 | $33.10 |
| Headroom to $50 (100%) | $49.21 | $43.10 |

The cap is more than 7 times the worst month of the planned jobs.

**Which job dominates.** Ask about this: 40% of the worst month, if it is used 20 times every day; typically no single job tops $0.20. Home lines is now small, since only a finished workout with a best or a long gap calls. Every Haiku job together is under $0.70 even at worst.

## At 80% and at 100%

- **At $40 (80%).** Settings' month line turns warm (`ClaudeSection`, `share >= 0.8`, in code). After AI-2, these
  step aside before reserve (`claude-client.md` step 4): Home lines (`.lines`), the week story and living colour (the
  word jobs). They show rules lines and today's colours. Capture, plan, recipe and questions keep running to $50.
  Groceries link has no stated priority (see below).
- **At $50 (100%).** `reserve` returns nil when month total + pending + this call's estimate would pass the cap, so a
  call is refused a little before $50 exactly. Every job gets `.refused(.cap)` with "Claude paused until <date>.";
  nothing is sent and no row is written. The key check's fallback also stops. Grammar, rules lines and on-device
  answers carry on until the 1st.

## What would push a month past the cap

- **A Home lines loop.** $40 from Home lines alone takes about 8,900 Sonnet calls, about 300 a day. The 40-a-day cap
  stops that, but it is not in code yet. With only the 10-minute debounce, 144 a day is $19.44 a month. If a pack
  carries a ticking value ("paused 21 min ago"), its hash changes every minute and moments skip the debounce: about
  1,440 calls a day is about $6.48 a day: $40 in about 6.2 days and $50 in about 7.7.
- **A model missing from `prices`.** `estimate` and `cost` return 0 for an unknown model string, so a typo or an
  Opus id would spend real money that the ledger records as free and the cap never sees.
- **Bigger packs.** Home lines on Sonnet with 5,000 tokens in costs $0.0115 a call, $13.80 at 40 a day.
- **Plan reworded on every change.** Plan at its $0.0128 ceiling needs about 104 a day to reach $40.
- **Untracked spend.** A call billed but killed before its `TessCall` row is written is never counted.

## Where code and docs differ

- **The cap.** Settled: $50 (Product's 8:16 ruling). The "$10 month" text is retired. `ClaudeKey.swift`'s ledger
  comment still says "The $10 month" (a Swift fix, not made here);
  `claude-first-uses.md`, `recipe-link-fetch.md` and AI-5 Q2 still measure against $10.
- **Home lines model.** Ship list (Oct 16 reorder) says Sonnet 5.5; architecture section 6 and the 5.6 table say
  Haiku. DECIDED (Product, decisions.md 11:45 AM PT Oct 16): Sonnet until AI-5 decides. This page assumes Sonnet, the costlier case.
- **Month total.** This page's totals are the source: $0.79 typical, $6.90 worst, after the Home narrowing. Older
  figures ($3.23 and $8.59) are retired.
- **The 40-a-day cap, 10-minute debounce and 80% step-aside.** Docs only. No `homeLines` job and no day cap exist in
  `TesseraCore/` today; only the Settings warm line at 80% is in code.
- **Who steps aside at 80%.** Settled: Home lines, the week story and living colour (Product's 8:16 ruling).
  Capture, plan, recipe and questions keep running. Groceries link is in none of them.
- **What is live.** Only misses (`ClaudeTessModel`) and the key check are wired in the app. Plan wording and the
  recipe reader exist in Core but run only in tests, so today's real spend is a few cents.
- **Recipe retry.** `recipe-link-fetch.md` prices a Sonnet retry at $0.026; the code has Haiku only.
- **Month boundary.** `claude-first-uses.md` says Los Angeles time; the ledger uses the phone's calendar.

*Oct 17 refresh (AI architecture): Home lines narrowed to the done job after Kaushik chose Sonnet on Home (`home-lines-job.md` 2b and 2c); `askSubject` and the facts job added from `ask-subject-pack.md` and `side-jobs.md`. Per-call figures use the rerun's median ($0.00183) and the worst cases in those docs; the earlier all-Home job row is retired. The other rows are unchanged.*
