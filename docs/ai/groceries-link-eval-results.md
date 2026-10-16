# Groceries link eval: results (AI-12)

Fixture `docs/research/fixtures/groceries-link-eval.md`, claude-haiku-5-5, 3 runs, 15 calls of at most 6 rows. Runner `scripts/ai/groceries_link_eval.py`.

## Run notes

Run Oct 16, 2026, about 9:50 AM PT, from a cloud session, script unchanged from master. Spend about $0.003 for the
15 calls, plus one extra diagnostic call (about $0.0002) to see why nothing paired.

Why it fails: the model's pairs were right, but it named the ingredient by title, not handle. For rows 1-6 it
returned g1 spring onions, g2 red pepper, g4 beef mince, g5 chopped tomatoes, g6 tomato puree, all correct
must pairs. The runner keeps a pair only when `ingredient` is a handle like `i5`, so every pair was dropped and
the gate scored 0 of 10. The `linkItems` schema and instructions never say to use handles. The fix is the AI and
Kitchen teams' call: say so in the tool description, or map titles back to handles on the phone, then rerun.

**Gate: FAIL.**

| Check | Bar | Result |
|---|---|---|
| Must rows paired in every run | 10 of 10 | 0 of 10 |
| False pairs in all row-runs | 0 of 75 | 0 |
| Replies dropped (over 6 pairs, two pairs on a row, no tool call) | 0 | 0 |
| Cost per run | under $0.001 | $0.0010 |
| Latency p50 / max | 8 s timeout | 1.5 s / 2.6 s |

## Must rows missed

| Run | # | Row | Want | Got |
|---|---|---|---|---|
| 1 | 1 | scallions | spring onions | nothing |
| 1 | 2 | capsicum | red pepper | nothing |
| 1 | 3 | bell pepper | red pepper | nothing |
| 1 | 4 | ground beef | beef mince | nothing |
| 1 | 5 | tinned tomatoes | chopped tomatoes | nothing |
| 1 | 6 | tomato paste | tomato puree | nothing |
| 1 | 7 | parmigiano | parmesan | nothing |
| 1 | 9 | beef stock cube | beef stock | nothing |
| 1 | 10 | cherry toms | cherry tomatoes | nothing |
| 1 | 25 | feta cheese | feta | nothing |
| 2 | 1 | scallions | spring onions | nothing |
| 2 | 2 | capsicum | red pepper | nothing |
| 2 | 3 | bell pepper | red pepper | nothing |
| 2 | 4 | ground beef | beef mince | nothing |
| 2 | 5 | tinned tomatoes | chopped tomatoes | nothing |
| 2 | 6 | tomato paste | tomato puree | nothing |
| 2 | 7 | parmigiano | parmesan | nothing |
| 2 | 9 | beef stock cube | beef stock | nothing |
| 2 | 10 | cherry toms | cherry tomatoes | nothing |
| 2 | 25 | feta cheese | feta | nothing |
| 3 | 1 | scallions | spring onions | nothing |
| 3 | 2 | capsicum | red pepper | nothing |
| 3 | 3 | bell pepper | red pepper | nothing |
| 3 | 4 | ground beef | beef mince | nothing |
| 3 | 5 | tinned tomatoes | chopped tomatoes | nothing |
| 3 | 6 | tomato paste | tomato puree | nothing |
| 3 | 7 | parmigiano | parmesan | nothing |
| 3 | 9 | beef stock cube | beef stock | nothing |
| 3 | 10 | cherry toms | cherry tomatoes | nothing |
| 3 | 25 | feta cheese | feta | nothing |

## Either rows

| # | Row | Allowed | Paired in runs |
|---|---|---|---|
| 17 | cumin seeds | ground cumin | 0 of 3 |
| 18 | red onion | onion | 0 of 3 |
| 19 | brown rice | basmati rice | 0 of 3 |
| 22 | linguine | spaghetti | 0 of 3 |
| 24 | paprika | smoked paprika | 0 of 3 |
