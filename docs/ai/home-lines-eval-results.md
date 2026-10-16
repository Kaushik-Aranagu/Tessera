# AI-5 Home lines eval: results

Written by `scripts/ai/home_lines_eval.py`, one section per invocation, newest first. Rubric: `docs/ai/eval-rubric.md`. Research's verdict goes above the first section.

## Oct 16, 2026 12:40 PM PT: memory pass, claude-haiku-5-5, claude-sonnet-5-5, 3 run(s)

| Field | Value |
|---|---|
| Pass | memory (memory-days, context line only) |
| Models | claude-haiku-5-5, claude-sonnet-5-5 |
| Tool choice | claude-haiku-5-5: forced proposeLines, claude-sonnet-5-5: auto |
| Effort | low |
| Runs | 3 |
| Prompt hash | 1feb77a66951 |
| Tool schema hash | fe9de502df36 |
| Fixture hash | memory-days.json ecfc5e0d0135 |
| Checker | home_lines_eval.py TessLineCheck 1 |
| Self-test | 61 vectors, 44 probes, all expected verdicts |
| Commit | 860de91 |
| Calls | 162 |
| Spend | $0.1675 |

### claude-haiku-5-5

Calls 81; moments that built no request: none. Memory block hashes: 14 distinct.

| Row | Bar | Result |
|---|---|---|
| Probes and vectors | 100% before any call | 61/61 vectors, 44/44 probes |
| Hard fails shown | 0 | 0 (every failing line is caught and falls back) |
| Caught by checks | 15% or fewer of returned lines | 20 of 99 (20%) |
| Tool called | 99% of items get a line | 99 of 99 (100%); replies with no tool call 0 |
| Returned equal to the rules line | report only | 1 |
| True to the pack | 100% | (person) |
| Tone: scolds or greets | 0 shown | (person) |
| Plain | 90% or more | (person) |
| Not repeating the page | 95% or more | (person) |
| Voice (Research V) | 80% or more | (person) |
| Cost per call, median | under $0.0004 (not gated on this pass) | $0.00010 |
| Latency p95 | under 6 s | 1.6 s; over 6 s: 0 |
| Kaushik reads 10 | 8 or more | (Kaushik) |

#### Catches by code

- C2: 1
- C3: 8
- C6: 2
- C7: 6
- C9: 1
- NOREPEAT: 4

#### Caught lines

| Run | Moment | Item | Slot | Claude | Codes |
|---|---|---|---|---|---|
| 1 | d3m1 | k1 | context | this evening, a Wednesday cook | NOREPEAT |
| 1 | d4m3 | w1 | context | this evening, your usual slot | C7 |
| 1 | d6m1 | w1 | context | this morning, before your usual evening | C3 |
| 1 | d7m1 | k1 | context | This evening, your Sunday cook | NOREPEAT |
| 1 | d10m1 | k1 | context | this evening, as on Wednesdays | C9 |
| 1 | d10m2 | w1 | context | Tonight, after work, your usual slot | C3 |
| 1 | d10m2 | k1 | context | Tonight, your Wednesday cook | NOREPEAT |
| 1 | d11m3 | w1 | context | this evening, your usual slot | C7 |
| 1 | d12m2 | w1 | context | Tonight, after 10:40 pm | C6 |
| 1 | d13m1 | w1 | context | This morning, after your usual slot | C3 |
| 2 | d4m3 | w1 | context | this evening, your usual slot | C7 |
| 2 | d6m1 | w1 | context | this morning, after your usual slot | C3 |
| 2 | d10m1 | w1 | context | Pull A, after work, your usual slot | C2, C3 |
| 2 | d11m3 | w1 | context | this evening, your usual slot | C7 |
| 2 | d13m1 | w1 | context | this morning, after the usual warm-up | C3 |
| 3 | d3m1 | k1 | context | this evening, your Wednesday cook | C3, NOREPEAT |
| 3 | d4m3 | w1 | context | this evening, your usual slot | C7 |
| 3 | d6m1 | w1 | context | this morning, after your usual slot | C3 |
| 3 | d11m3 | w1 | context | this evening, your usual slot | C7 |
| 3 | d12m2 | w1 | context | tonight, after 10 pm | C6 |

#### Shown lines (a person scores each)

| Run | Moment | Item | Slot | Rules | Claude | True | Plain | Not repeating | Tone | Voice | Why (fails) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | d1m1 | w1 | context | Push A today. | this evening, after work |  |  |  |  |  |  |
| 1 | d1m2 | w1 | context | Push A done. | this evening, after work |  |  |  |  |  |  |
| 1 | d2m1 | w1 | context | Pull A today. | after work, your usual slot |  |  |  |  |  |  |
| 1 | d2m2 | w1 | context | Pull A done. | this evening, your usual slot |  |  |  |  |  |  |
| 1 | d3m1 | w1 | context | Legs A today. | this morning, before work |  |  |  |  |  |  |
| 1 | d3m2 | w1 | context | Legs A done. | this evening, your usual slot |  |  |  |  |  |  |
| 1 | d3m2 | k1 | context | Chili cooked. | tonight, Chili |  |  |  |  |  |  |
| 1 | d4m1 | w1 | context | Push A today. | this evening, your usual slot |  |  |  |  |  |  |
| 1 | d4m2 | w1 | context | Push A done. | this evening, after work |  |  |  |  |  |  |
| 1 | d5m1 | w1 | context | Pull A today. | this evening, your usual slot |  |  |  |  |  |  |
| 1 | d6m2 | w1 | context | Pull A done. | this evening, after 3 exercises |  |  |  |  |  |  |
| 1 | d7m1 | w1 | context | Rest day. | Nothing scheduled, no clock time |  |  |  |  |  |  |
| 1 | d8m1 | w1 | context | Legs A today. | this evening, your usual slot |  |  |  |  |  |  |
| 1 | d8m2 | w1 | context | Legs A done. | this evening, your usual slot |  |  |  |  |  |  |
| 1 | d9m1 | w1 | context | Push A today. | this morning, Push A |  |  |  |  |  |  |
| 1 | d9m2 | w1 | context | Push A done. Bench press best. | Bench press best this evening |  |  |  |  |  |  |
| 1 | d10m1 | w1 | context | Pull A today. | this evening, your usual slot |  |  |  |  |  |  |
| 1 | d11m1 | w1 | context | Legs A today. | this morning, after work |  |  |  |  |  |  |
| 1 | d11m2 | w1 | context | Legs A done. | Tonight, after work, done |  |  |  |  |  |  |
| 1 | d12m1 | w1 | context | Push A today. | After work, your usual slot |  |  |  |  |  |  |
| 1 | d13m2 | w1 | context | Pull A done. | Tonight, after a clean Pull A |  |  |  |  |  |  |
| 1 | d14m1 | w1 | context | Rest day. | Nothing scheduled, a slow start |  |  |  |  |  |  |
| 1 | d14m1 | k1 | context | Tacos tonight. | This evening, your cooking slot |  |  |  |  |  |  |
| 2 | d1m1 | w1 | context | Push A today. | This evening, after work |  |  |  |  |  |  |
| 2 | d1m2 | w1 | context | Push A done. | this evening, after work |  |  |  |  |  |  |
| 2 | d2m1 | w1 | context | Pull A today. | this evening, your usual slot |  |  |  |  |  |  |
| 2 | d3m1 | w1 | context | Legs A today. | this morning, before work |  |  |  |  |  |  |
| 2 | d3m1 | k1 | context | Chili tonight. | this evening, your usual slot |  |  |  |  |  |  |
| 2 | d3m2 | w1 | context | Legs A done. | this evening, your usual slot |  |  |  |  |  |  |
| 2 | d3m2 | k1 | context | Chili cooked. | this evening, Chili |  |  |  |  |  |  |
| 2 | d4m1 | w1 | context | Push A today. | after work, your usual slot |  |  |  |  |  |  |
| 2 | d4m2 | w1 | context | Push A done. | this evening, after work |  |  |  |  |  |  |
| 2 | d5m1 | w1 | context | Pull A today. | this morning, after work |  |  |  |  |  |  |
| 2 | d6m2 | w1 | context | Pull A done. | tonight, after a full session |  |  |  |  |  |  |
| 2 | d7m1 | w1 | context | Rest day. | Nothing scheduled today |  |  |  |  |  |  |
| 2 | d7m1 | k1 | context | Dal tonight. | This evening, your cooking slot |  |  |  |  |  |  |
| 2 | d8m1 | w1 | context | Legs A today. | this morning, before work |  |  |  |  |  |  |
| 2 | d8m2 | w1 | context | Legs A done. | tonight, after a full session |  |  |  |  |  |  |
| 2 | d9m1 | w1 | context | Push A today. | this morning, Push A |  |  |  |  |  |  |
| 2 | d9m2 | w1 | context | Push A done. Bench press best. | Tonight, a bench best |  |  |  |  |  |  |
| 2 | d10m1 | k1 | context | Chili tonight. | Tonight, your usual cooking slot |  |  |  |  |  |  |
| 2 | d10m2 | w1 | context | Pull A done. | Tonight, after work |  |  |  |  |  |  |
| 2 | d10m2 | k1 | context | Chili cooked. | Tonight, your usual cook slot |  |  |  |  |  |  |
| 2 | d11m1 | w1 | context | Legs A today. | this morning, after work |  |  |  |  |  |  |
| 2 | d11m2 | w1 | context | Legs A done. | this evening, after work |  |  |  |  |  |  |
| 2 | d12m1 | w1 | context | Push A today. | After work, your usual slot |  |  |  |  |  |  |
| 2 | d12m2 | w1 | context | Push A done. | Tonight, after the session |  |  |  |  |  |  |
| 2 | d13m2 | w1 | context | Pull A done. | this evening, your usual slot |  |  |  |  |  |  |
| 2 | d14m1 | w1 | context | Rest day. | Nothing scheduled, rest up |  |  |  |  |  |  |
| 2 | d14m1 | k1 | context | Tacos tonight. | This evening, your cooking slot |  |  |  |  |  |  |
| 3 | d1m1 | w1 | context | Push A today. | this evening, your usual slot |  |  |  |  |  |  |
| 3 | d1m2 | w1 | context | Push A done. | this evening, after work |  |  |  |  |  |  |
| 3 | d2m1 | w1 | context | Pull A today. | this evening, your usual slot |  |  |  |  |  |  |
| 3 | d2m2 | w1 | context | Pull A done. | Tonight, after work |  |  |  |  |  |  |
| 3 | d3m1 | w1 | context | Legs A today. | this morning, before work |  |  |  |  |  |  |
| 3 | d3m2 | w1 | context | Legs A done. | this evening, your usual slot |  |  |  |  |  |  |
| 3 | d3m2 | k1 | context | Chili cooked. | this evening |  |  |  |  |  |  |
| 3 | d4m1 | w1 | context | Push A today. | this evening, your usual slot |  |  |  |  |  |  |
| 3 | d4m2 | w1 | context | Push A done. | this evening, after work |  |  |  |  |  |  |
| 3 | d5m1 | w1 | context | Pull A today. | this morning, after work |  |  |  |  |  |  |
| 3 | d6m2 | w1 | context | Pull A done. | this evening, your usual slot |  |  |  |  |  |  |
| 3 | d7m1 | w1 | context | Rest day. | Nothing booked, a quiet one |  |  |  |  |  |  |
| 3 | d7m1 | k1 | context | Dal tonight. | This evening, your cooking slot |  |  |  |  |  |  |
| 3 | d8m1 | w1 | context | Legs A today. | this evening, your usual slot |  |  |  |  |  |  |
| 3 | d8m2 | w1 | context | Legs A done. | tonight, after a full session |  |  |  |  |  |  |
| 3 | d9m1 | w1 | context | Push A today. | this morning, Push A |  |  |  |  |  |  |
| 3 | d9m2 | w1 | context | Push A done. Bench press best. | this evening, bench best |  |  |  |  |  |  |
| 3 | d10m1 | w1 | context | Pull A today. | This morning, after work |  |  |  |  |  |  |
| 3 | d10m1 | k1 | context | Chili tonight. | This evening, your usual slot |  |  |  |  |  |  |
| 3 | d10m2 | w1 | context | Pull A done. | Tonight, your usual slot |  |  |  |  |  |  |
| 3 | d10m2 | k1 | context | Chili cooked. | Tonight, your usual cooking |  |  |  |  |  |  |
| 3 | d11m1 | w1 | context | Legs A today. | this morning, after work |  |  |  |  |  |  |
| 3 | d11m2 | w1 | context | Legs A done. | tonight, after work, done |  |  |  |  |  |  |
| 3 | d12m1 | w1 | context | Push A today. | this evening, after work |  |  |  |  |  |  |
| 3 | d13m1 | w1 | context | Pull A today. | this morning, your usual slot |  |  |  |  |  |  |
| 3 | d13m2 | w1 | context | Pull A done. | Tonight, after 3 exercises |  |  |  |  |  |  |
| 3 | d14m1 | w1 | context | Rest day. | Nothing scheduled, no clock |  |  |  |  |  |  |
| 3 | d14m1 | k1 | context | Tacos tonight. | This evening, your cooking slot |  |  |  |  |  |  |

### claude-sonnet-5-5

Calls 81; moments that built no request: none. Memory block hashes: 14 distinct.

| Row | Bar | Result |
|---|---|---|
| Probes and vectors | 100% before any call | 61/61 vectors, 44/44 probes |
| Hard fails shown | 0 | 0 (every failing line is caught and falls back) |
| Caught by checks | 15% or fewer of returned lines | 1 of 99 (1%) |
| Tool called | 90% of items get a line | 99 of 99 (100%); replies with no tool call 0 |
| Returned equal to the rules line | report only | 52 |
| True to the pack | 100% | (person) |
| Tone: scolds or greets | 0 shown | (person) |
| Plain | 90% or more | (person) |
| Not repeating the page | 95% or more | (person) |
| Voice (Research V) | 80% or more | (person) |
| Cost per call, median | under $0.006 (not gated on this pass) | $0.00186 |
| Latency p95 | under 6 s | 2.8 s; over 6 s: 0 |
| Kaushik reads 10 | 8 or more | (Kaushik) |

#### Catches by code

- C6: 1

#### Caught lines

| Run | Moment | Item | Slot | Claude | Codes |
|---|---|---|---|---|---|
| 3 | d11m2 | w1 | context | Finished 95 minutes ago | C6 |

#### Shown lines (a person scores each)

| Run | Moment | Item | Slot | Rules | Claude | True | Plain | Not repeating | Tone | Voice | Why (fails) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | d1m1 | w1 | context | Push A today. | After work, as usual |  |  |  |  |  |  |
| 1 | d2m1 | w1 | context | Pull A today. | After work, your usual slot |  |  |  |  |  |  |
| 1 | d2m2 | w1 | context | Pull A done. | After work, as usual |  |  |  |  |  |  |
| 1 | d3m1 | w1 | context | Legs A today. | After work, your usual slot |  |  |  |  |  |  |
| 1 | d4m1 | w1 | context | Push A today. | After work, your usual slot |  |  |  |  |  |  |
| 1 | d4m2 | w1 | context | Push A done. | After work, as usual |  |  |  |  |  |  |
| 1 | d5m1 | w1 | context | Pull A today. | After work, your usual slot |  |  |  |  |  |  |
| 1 | d8m1 | w1 | context | Legs A today. | After work, your usual slot |  |  |  |  |  |  |
| 1 | d9m1 | w1 | context | Push A today. | After work, your usual slot |  |  |  |  |  |  |
| 1 | d9m2 | w1 | context | Push A done. Bench press best. | Bench press best |  |  |  |  |  |  |
| 1 | d10m1 | w1 | context | Pull A today. | After work, your usual slot |  |  |  |  |  |  |
| 1 | d11m1 | w1 | context | Legs A today. | After work, your usual slot |  |  |  |  |  |  |
| 1 | d12m1 | w1 | context | Push A today. | After work, your usual slot |  |  |  |  |  |  |
| 1 | d13m1 | w1 | context | Pull A today. | After work, your usual slot |  |  |  |  |  |  |
| 2 | d1m1 | w1 | context | Push A today. | After work, as usual |  |  |  |  |  |  |
| 2 | d2m1 | w1 | context | Pull A today. | After work, your usual slot |  |  |  |  |  |  |
| 2 | d2m2 | w1 | context | Pull A done. | After work, as usual |  |  |  |  |  |  |
| 2 | d3m1 | w1 | context | Legs A today. | After work, your usual slot |  |  |  |  |  |  |
| 2 | d4m1 | w1 | context | Push A today. | After work, your usual slot |  |  |  |  |  |  |
| 2 | d4m2 | w1 | context | Push A done. | After work, your usual slot |  |  |  |  |  |  |
| 2 | d5m1 | w1 | context | Pull A today. | After work, your usual slot |  |  |  |  |  |  |
| 2 | d8m1 | w1 | context | Legs A today. | After work, your usual slot |  |  |  |  |  |  |
| 2 | d9m1 | w1 | context | Push A today. | After work, your usual |  |  |  |  |  |  |
| 2 | d9m2 | w1 | context | Push A done. Bench press best. | Bench press best |  |  |  |  |  |  |
| 2 | d10m1 | w1 | context | Pull A today. | After work, your usual slot |  |  |  |  |  |  |
| 2 | d11m1 | w1 | context | Legs A today. | After work, your usual slot |  |  |  |  |  |  |
| 2 | d12m1 | w1 | context | Push A today. | After work, your usual slot |  |  |  |  |  |  |
| 2 | d12m2 | w1 | context | Push A done. | Finished tonight |  |  |  |  |  |  |
| 2 | d13m1 | w1 | context | Pull A today. | After work, your usual slot |  |  |  |  |  |  |
| 2 | d13m2 | w1 | context | Pull A done. | Pull A done |  |  |  |  |  |  |
| 3 | d1m1 | w1 | context | Push A today. | After work, as usual |  |  |  |  |  |  |
| 3 | d2m1 | w1 | context | Pull A today. | After work, your usual slot |  |  |  |  |  |  |
| 3 | d2m2 | w1 | context | Pull A done. | After work, as usual |  |  |  |  |  |  |
| 3 | d3m1 | w1 | context | Legs A today. | After work, your usual slot |  |  |  |  |  |  |
| 3 | d4m1 | w1 | context | Push A today. | After work, your usual |  |  |  |  |  |  |
| 3 | d4m2 | w1 | context | Push A done. | After work, as usual |  |  |  |  |  |  |
| 3 | d5m1 | w1 | context | Pull A today. | After work, your usual slot |  |  |  |  |  |  |
| 3 | d8m1 | w1 | context | Legs A today. | After work, your usual slot |  |  |  |  |  |  |
| 3 | d9m1 | w1 | context | Push A today. | After work, your usual slot |  |  |  |  |  |  |
| 3 | d9m2 | w1 | context | Push A done. Bench press best. | Bench press best |  |  |  |  |  |  |
| 3 | d10m1 | w1 | context | Pull A today. | After work, your usual slot |  |  |  |  |  |  |
| 3 | d11m1 | w1 | context | Legs A today. | After work, your usual slot |  |  |  |  |  |  |
| 3 | d12m1 | w1 | context | Push A today. | After work, your usual slot |  |  |  |  |  |  |
| 3 | d12m2 | w1 | context | Push A done. | Tonight, after work as usual |  |  |  |  |  |  |
| 3 | d13m1 | w1 | context | Pull A today. | After work, your usual slot |  |  |  |  |  |  |
| 3 | d13m2 | w1 | context | Pull A done. | All 3 exercises ticked off |  |  |  |  |  |  |

### The 10 for Kaushik

| # | Rules line | Claude's line | Sounds like Tess? |
|---|---|---|---|
| 1 |  |  |  |
| 2 |  |  |  |
| 3 |  |  |  |
| 4 |  |  |  |
| 5 |  |  |  |
| 6 |  |  |  |
| 7 |  |  |  |
| 8 |  |  |  |
| 9 |  |  |  |
| 10 |  |  |  |

Scorer: (name)

## Oct 16, 2026 12:36 PM PT: gate pass, claude-haiku-5-5, claude-sonnet-5-5, 3 run(s)

| Field | Value |
|---|---|
| Pass | gate (E1-E20, context and detail) |
| Models | claude-haiku-5-5, claude-sonnet-5-5 |
| Tool choice | claude-haiku-5-5: forced proposeLines, claude-sonnet-5-5: auto |
| Effort | low |
| Runs | 3 |
| Prompt hash | 1feb77a66951 |
| Tool schema hash | fe9de502df36 |
| Fixture hash | home-lines-eval.json eb0290252328 |
| Checker | home_lines_eval.py TessLineCheck 1 |
| Self-test | 61 vectors, 44 probes, all expected verdicts |
| Commit | 860de91 |
| Calls | 108 |
| Spend | $0.1002 |

### claude-haiku-5-5

Calls 54; moments that built no request: E4, E10. Memory block hashes: 6 distinct.

| Row | Bar | Result |
|---|---|---|
| Probes and vectors | 100% before any call | 61/61 vectors, 44/44 probes |
| Hard fails shown | 0 | 0 (every failing line is caught and falls back) |
| Caught by checks | 15% or fewer of returned lines | 12 of 118 (10%) |
| Tool called | 99% of items get a line | 60 of 60 (100%); replies with no tool call 0 |
| Returned equal to the rules line | report only | 68 |
| True to the pack | 100% | (person) |
| Tone: scolds or greets | 0 shown | (person) |
| Plain | 90% or more | (person) |
| Not repeating the page | 95% or more | (person) |
| Voice (Research V) | 80% or more | (person) |
| Cost per call, median | under $0.0004 | $0.00009 |
| Latency p95 | under 6 s | 1.9 s; over 6 s: 0 |
| Kaushik reads 10 | 8 or more | (Kaushik) |

#### Catches by code

- C10: 2
- C2: 5
- C3: 3
- C6: 2
- C7: 1
- C8: 1
- NOREPEAT: 4

#### Caught lines

| Run | Moment | Item | Slot | Claude | Codes |
|---|---|---|---|---|---|
| 1 | E6 | w1 | context | tonight, past your usual 6 to 8 pm | C2, C3, C6 |
| 1 | E9 | g1 | context | this morning, your usual Saturday run | C3, NOREPEAT |
| 1 | E14 | w1 | context | at 7:55 pm, new best on Deadlift | C2 |
| 1 | E17 | w1 | context | this morning, Saturday slot | NOREPEAT |
| 2 | E9 | g1 | context | late morning, your Saturday shop | C10, NOREPEAT |
| 2 | E14 | w1 | context | at 7:55 pm, new best on Deadlift | C2 |
| 2 | E18 | k1 | context | this evening, your usual slot | C7 |
| 2 | E19 | w1 | context | at 8:00 pm, new best on bench | C2 |
| 3 | E2 | w1 | detail | 6 exercises, 18 sets, last one 9 days ago. | C8 |
| 3 | E6 | w1 | context | tonight, past your usual 6 pm slot | C2, C3 |
| 3 | E9 | g1 | context | late morning, your Saturday shop | C10, NOREPEAT |
| 3 | E17 | w1 | context | this morning, 9:00 am | C6 |

#### Shown lines (a person scores each)

| Run | Moment | Item | Slot | Rules | Claude | True | Plain | Not repeating | Tone | Voice | Why (fails) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | E2 | w1 | context | done at 7:40 pm | Earlier, at 7:40 pm |  |  |  |  |  |  |
| 1 | E2 | w1 | detail | 6 exercises, 18 sets. | 6 exercises, 18 sets, first in 9 days. |  |  |  |  |  |  |
| 1 | E3 | w1 | context | paused 40 min ago | this evening, paused 40 min ago |  |  |  |  |  |  |
| 1 | E5 | w1 | context | this evening | this evening, your usual slot |  |  |  |  |  |  |
| 1 | E8 | k1 | context | paused 8 min ago | this evening, paused 8 min ago |  |  |  |  |  |  |
| 1 | E11 | w1 | context | done at 8:15 pm | this evening, 8:15 pm |  |  |  |  |  |  |
| 1 | E12 | w1 | context | done at 7:50 pm | at 7:50 pm, your usual slot |  |  |  |  |  |  |
| 1 | E13 | k1 | context | 2 to buy | this evening, 2 to buy |  |  |  |  |  |  |
| 1 | E15 | w1 | context | done at 7:30 pm | this evening, your usual slot |  |  |  |  |  |  |
| 1 | E16 | w1 | context | done at 6:50 pm | this evening, your usual slot |  |  |  |  |  |  |
| 1 | E16 | w1 | detail | 5 exercises, 15 sets. | 5 exercises, 15 sets, last Pull A 3 days ago. |  |  |  |  |  |  |
| 1 | E18 | w1 | context | done at 4:10 pm | done, this afternoon at 4:10 pm |  |  |  |  |  |  |
| 1 | E18 | k1 | context | paused 5 min ago | this evening, paused 5 min ago |  |  |  |  |  |  |
| 1 | E20 | w1 | context | done at 9:05 pm | this evening, 9:05 pm |  |  |  |  |  |  |
| 2 | E2 | w1 | context | done at 7:40 pm | this evening, 7:40 pm |  |  |  |  |  |  |
| 2 | E2 | w1 | detail | 6 exercises, 18 sets. | 6 exercises, 18 sets, first Push A in 9 days. |  |  |  |  |  |  |
| 2 | E3 | w1 | context | paused 40 min ago | this evening, paused 40 min ago |  |  |  |  |  |  |
| 2 | E5 | w1 | context | this evening | this evening, your usual slot |  |  |  |  |  |  |
| 2 | E6 | w1 | context | today | this evening, your usual slot |  |  |  |  |  |  |
| 2 | E8 | k1 | context | paused 8 min ago | this evening, paused 8 min ago |  |  |  |  |  |  |
| 2 | E11 | w1 | context | done at 8:15 pm | this evening at 8:15 pm |  |  |  |  |  |  |
| 2 | E12 | w1 | context | done at 7:50 pm | at 7:50 pm, your usual slot |  |  |  |  |  |  |
| 2 | E13 | k1 | context | 2 to buy | this evening, 2 to buy |  |  |  |  |  |  |
| 2 | E15 | w1 | context | done at 7:30 pm | at 7:30 pm, your usual slot |  |  |  |  |  |  |
| 2 | E17 | w1 | context | today | this morning, not after work |  |  |  |  |  |  |
| 2 | E18 | w1 | context | done at 4:10 pm | done, this afternoon |  |  |  |  |  |  |
| 2 | E20 | w1 | context | done at 9:05 pm | this evening, 9:05 pm |  |  |  |  |  |  |
| 3 | E2 | w1 | context | done at 7:40 pm | this evening at 7:40 pm |  |  |  |  |  |  |
| 3 | E3 | w1 | context | paused 40 min ago | this evening, paused 40 min ago |  |  |  |  |  |  |
| 3 | E5 | w1 | context | this evening | this evening, your usual slot |  |  |  |  |  |  |
| 3 | E8 | k1 | context | paused 8 min ago | this evening, paused 8 min ago |  |  |  |  |  |  |
| 3 | E11 | w1 | context | done at 8:15 pm | this evening, 8:15 pm |  |  |  |  |  |  |
| 3 | E12 | w1 | context | done at 7:50 pm | at 7:50 pm, your usual slot |  |  |  |  |  |  |
| 3 | E13 | k1 | context | 2 to buy | this evening, 2 to buy |  |  |  |  |  |  |
| 3 | E15 | w1 | context | done at 7:30 pm | this evening, your usual slot |  |  |  |  |  |  |
| 3 | E16 | w1 | context | done at 6:50 pm | this evening, your usual slot |  |  |  |  |  |  |
| 3 | E18 | w1 | context | done at 4:10 pm | done, 4:10 pm |  |  |  |  |  |  |
| 3 | E20 | w1 | context | done at 9:05 pm | at 9:05 pm, your usual slot |  |  |  |  |  |  |

### claude-sonnet-5-5

Calls 54; moments that built no request: E4, E10. Memory block hashes: 6 distinct.

| Row | Bar | Result |
|---|---|---|
| Probes and vectors | 100% before any call | 61/61 vectors, 44/44 probes |
| Hard fails shown | 0 | 0 (every failing line is caught and falls back) |
| Caught by checks | 15% or fewer of returned lines | 3 of 120 (2%) |
| Tool called | 90% of items get a line | 60 of 60 (100%); replies with no tool call 0 |
| Returned equal to the rules line | report only | 110 |
| True to the pack | 100% | (person) |
| Tone: scolds or greets | 0 shown | (person) |
| Plain | 90% or more | (person) |
| Not repeating the page | 95% or more | (person) |
| Voice (Research V) | 80% or more | (person) |
| Cost per call, median | under $0.006 | $0.00166 |
| Latency p95 | under 6 s | 3.0 s; over 6 s: 0 |
| Kaushik reads 10 | 8 or more | (Kaushik) |

#### Catches by code

- C3: 3
- C6: 3

#### Caught lines

| Run | Moment | Item | Slot | Claude | Codes |
|---|---|---|---|---|---|
| 1 | E5 | w1 | context | 6:10 this evening, your usual slot | C3, C6 |
| 2 | E5 | w1 | context | 6:10 this evening, your usual slot | C3, C6 |
| 3 | E5 | w1 | context | 6:10 this evening, your usual slot | C3, C6 |

#### Shown lines (a person scores each)

| Run | Moment | Item | Slot | Rules | Claude | True | Plain | Not repeating | Tone | Voice | Why (fails) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | E1 | w1 | context | done at 8:05 pm | 8:05 pm, bench press best |  |  |  |  |  |  |
| 1 | E2 | w1 | context | done at 7:40 pm | 7:40 pm, first in 9 days |  |  |  |  |  |  |
| 1 | E14 | w1 | context | done at 7:55 pm | 7:55 pm, Deadlift best |  |  |  |  |  |  |
| 2 | E1 | w1 | context | done at 8:05 pm | 8:05 pm, a bench best |  |  |  |  |  |  |
| 2 | E2 | w1 | context | done at 7:40 pm | 7:40 pm, first in 9 days |  |  |  |  |  |  |
| 3 | E1 | w1 | context | done at 8:05 pm | 8:05 pm, bench press best |  |  |  |  |  |  |
| 3 | E14 | w1 | context | done at 7:55 pm | 7:55 pm, a best on Deadlift |  |  |  |  |  |  |

### The 10 for Kaushik

| # | Rules line | Claude's line | Sounds like Tess? |
|---|---|---|---|
| 1 |  |  |  |
| 2 |  |  |  |
| 3 |  |  |  |
| 4 |  |  |  |
| 5 |  |  |  |
| 6 |  |  |  |
| 7 |  |  |  |
| 8 |  |  |  |
| 9 |  |  |  |
| 10 |  |  |  |

Scorer: (name)
