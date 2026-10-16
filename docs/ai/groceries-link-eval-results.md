# Groceries link eval: results (AI-12)

Fixture `docs/research/fixtures/groceries-link-eval.md`, claude-haiku-5-5, 3 runs, 15 calls of at most 6 rows. Runner `scripts/ai/groceries_link_eval.py`.

**Gate: PASS.**

| Check | Bar | Result |
|---|---|---|
| Must rows paired in every run | 10 of 10 | 10 of 10 |
| False pairs in all row-runs | 0 of 75 | 0 |
| Replies dropped (over 6 pairs, two pairs on a row, no tool call) | 0 | 0 |
| Cost per run | under $0.001 | $0.0011 |
| Latency p50 / max | 8 s timeout | 1.5 s / 3.8 s |

## Either rows

| # | Row | Allowed | Paired in runs |
|---|---|---|---|
| 17 | cumin seeds | ground cumin | 3 of 3 |
| 18 | red onion | onion | 0 of 3 |
| 19 | brown rice | basmati rice | 0 of 3 |
| 22 | linguine | spaghetti | 0 of 3 |
| 24 | paprika | smoked paprika | 3 of 3 |
