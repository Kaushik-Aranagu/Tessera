# Groceries link eval: results (AI-12)

Fixture `docs/research/fixtures/groceries-link-eval.md`, claude-haiku-5-5, 3 runs, 15 calls of at most 6 rows. Runner `scripts/ai/groceries_link_eval.py`.

## Run notes

Rerun Oct 16, 2026, about 9:56 AM PT, after #413 (handle enums), script unchanged from master. Spend about $0.0033.
The one miss is row 3, bell pepper, in all 3 runs. It shares a call with row 2, capsicum, which paired with red
pepper every time; Haiku seems to give each ingredient to one row only (inferred from the batch, not checked).
Cost per run is $0.0011, just over the $0.001 line, which isn't part of the pass bar.

**Gate: FAIL.**

| Check | Bar | Result |
|---|---|---|
| Must rows paired in every run | 10 of 10 | 9 of 10 |
| False pairs in all row-runs | 0 of 75 | 0 |
| Replies dropped (over 6 pairs, two pairs on a row, no tool call) | 0 | 0 |
| Cost per run | under $0.001 | $0.0011 |
| Latency p50 / max | 8 s timeout | 1.3 s / 2.1 s |

## Must rows missed

| Run | # | Row | Want | Got |
|---|---|---|---|---|
| 1 | 3 | bell pepper | red pepper | nothing |
| 2 | 3 | bell pepper | red pepper | nothing |
| 3 | 3 | bell pepper | red pepper | nothing |

## Either rows

| # | Row | Allowed | Paired in runs |
|---|---|---|---|
| 17 | cumin seeds | ground cumin | 3 of 3 |
| 18 | red onion | onion | 3 of 3 |
| 19 | brown rice | basmati rice | 0 of 3 |
| 22 | linguine | spaghetti | 0 of 3 |
| 24 | paprika | smoked paprika | 3 of 3 |
