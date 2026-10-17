# B5: model, effort and cost per Claude job

Sources: docs/ai/spend-projection.md (Oct 17 refresh), architecture.md, old-callers.md, home-lines-job.md,
week-story-job.md, ask-subject-pack.md, side-jobs.md and the eval result files, all on origin/master.
Prices (n$ per token): Sonnet 5.5 2,000 in / 10,000 out. Haiku 5.5 100 in / 500 out. 1 USD = 1e9 n$.
M = measured on real calls, A = assumed. Month = 30 days. Calls/day cap: "doc" means written in a doc but not in code.

| Job | Model | Effort | Max tokens | Typical in / out | Cost per call typ / worst | Calls/day typ / cap | Month typ / worst |
|---|---|---|---|---|---|---|---|
| capture (misses) | Haiku 5.5 | none | 512 | 5,150 / 130 A (2 rounds) | $0.0006 / $0.0015 (3 rounds held) | 5 / 20 (worst case, no cap) | $0.09 / $0.35 |
| Home done lines | Sonnet 5.5 | low | 512 | 600 / 80 A | $0.0020 / $0.0075 | 1 / 3 (doc cap 40, not in code) | $0.06 / $0.68 |
| Plan my day wording | Sonnet 5.5 | low | 1,024 | 1,000 / 300 A | $0.0050 / $0.0128 | 2 / 5 (no cap) | $0.30 / $1.92 |
| week story | Sonnet 5.5 | low | 400 | 2,000 / 300 A | $0.0070 / $0.0100 (gate) | 8 a month / 2 a day (no cap) | $0.06 / $0.60 |
| recipe reader | Haiku 5.5 | low | 4,096 | 7,000 / 1,200 A | $0.0013 / $0.0027 | 10 a month / 30 a month | $0.01 / $0.08 |
| askSubject (opt-in) | Sonnet 5.5 | low | 300 | 500 / 100 A | $0.0020 / $0.0046 (810 in, 300 out) | 3 / 20 (doc cap, ledger counts) | $0.18 / $2.77 |
| fillFacts (once per new thing) | Sonnet 5.5 | low | not stated | 700 / 45 A | $0.0019 / $0.0026 (900 / 80) | 10 a month / 100 a month | $0.02 / $0.26 |
| linkItems (groceries link) | Haiku 5.5 | low | not stated | 1,200 / 150 A | $0.00022 M / assumed | 2 / 4 | $0.01 / $0.03 |
| living colour | Haiku 5.5 | low | not stated | 1,200 / 60 A | $0.00015 / same | 1 / 1 | $0.005 / $0.005 |
| keyCheck | Haiku 5.5 | none | n/a | count_tokens, free; fallback "Hi" | about $0 | rare | $0.00 / $0.00 |
| **Ten jobs above** | | | | | | | **about $0.74 / about $6.85** |

The ask-a-log-question job (Haiku, 5 a day, $0.05 typical, $0.20 worst) is in spend-projection.md but not in
your list. Adding it gives the doc's $0.79 typical and $6.90 worst. Worst-case column sums are my arithmetic on
the doc's rows; they round differently by a cent or two.

## Would a cheaper model or effort do?

| Job | Cheaper option | Evidence |
|---|---|---|
| capture | Already Haiku, no effort | none needed; cost is under $0.35 even at worst |
| Home done lines | Haiku (about $0.0002 a call, $0.27 worst) or no Claude at all | Rerun (home-lines-eval-results.md) was Sonnet only: 0 hard fails, but voice 3/13 FAIL, memory p95 8.1 s FAIL, and the only added fact is the day gap, which rules can say free. Recommendation: Claude Home off. Haiku: memory-experiment-results.md says Haiku returned no line for 118 items under tool_choice auto, so Haiku with forced tool is untested. Evidence: no Haiku rerun yet |
| Plan my day | Haiku or effort none | no evidence (Sonnet chosen by decision, not eval) |
| week story | Haiku | no evidence (AI-11 gate allows up to $0.01; not run) |
| recipe reader | Already Haiku | no Sonnet comparison; the $0.026 Sonnet retry in recipe-link-fetch.md is not in code |
| askSubject | Haiku | no evidence (no eval run, only a no-call packer check) |
| fillFacts | Haiku | no evidence (eval gate defined, not run; full run capped under $0.25) |
| linkItems | Already Haiku | eval gate PASS, 3 runs, $0.0011 a run |
| living colour | Already Haiku | no evidence yet; architecture says the AI-5 eval decides if Haiku low holds the 6-word budget |
| keyCheck | Already free | n/a |

## Contradictions and risks

- $50 cap: the in-app Claude cap is $50 a month, a hard stop; it resets on the 1st (Product's 8:16 ruling). Worst
  month of every planned job is about $6.90 (14%), so the cap holds with more than 7x room. Stale text still saying
  $10: `ClaudeKey.swift` comment (Swift, not changed here), claude-first-uses.md, recipe-link-fetch.md.
- $40 step-aside: at 80% ($40), Home lines, the week story and living colour step aside before the reserve; capture,
  plan, recipe and questions keep running to $50 (settled). linkItems is in none. Only the Settings warm line at 80%
  exists in code; the step-aside itself is docs only. At worst spend ($6.90) it never fires, so it guards only loops.
- The 40-a-day Home cap and 10-minute debounce are docs only. Without them a ticking pack value could hit about
  1,440 calls a day, $6.48 a day, so $40 in 6.2 days and $50 in 7.7 days. No caps exist in code for plan, week story
  or askSubject beyond the 20 a day written in the doc.
- Unknown model string prices as 0 in the ledger, so a typo or an Opus id is spend the cap cannot see.
- Home lines model: ship list and decision say Sonnet; architecture section 6 table still lists it as Sonnet until
  AI-5 and the 5.6 table says Haiku; the eval's own recommendation is no Claude on Home. The cost row assumes the
  decided Sonnet done job. If Home wording stays off, drop $0.06 to $0.68.
- Week story max_tokens is 400 but the cost uses 300 out; worst per call at 400 out is $0.008 for 2,000 in, inside
  the $0.01 gate.
- $200 a month dev credits: this pays for cloud development and eval runs (memory experiment about $0.60 so far),
  logged separately in the board. Dev credits are not counted in the $50 cap (settled); the cap is the phone's own
  key spend.
