# Home lines on his real day (board item 116)

For: Core (`HomeLines`, #334), Design (41), Builder B (AI-1 Home). Owner: Research lab.
Date: Oct 16, 2026 (Pacific). Traced by hand on master 13a8819 against `TesseraCore/Sources/TesseraCore/Home/HomeLines.swift`. There is no Swift toolchain here, so every output below is read from the code, not run. Home doesn't read `HomeLines` yet; that is Builder B's AI-1 work.

**The day.** Tuesday Oct 20, 2026, in Pacific time, with his 4 AM day.

| Time | What happens |
|---|---|
| Morning | Push A planned, tacos planned for tonight with 2 to buy, "Call mom" at 11:15 am |
| 12:30 | Trader Joe's: 6 items to get |
| 17:50 | Push A starts |
| 18:35 | Pauses at incline |
| 19:20 | Resumes |
| 20:05 | Finishes: 6 exercises, 18 sets, a bench best |
| 20:30 | Cooks tacos (7 steps), pausing at step 5 |
| 21:40 | Tacos done |
| After that | Up past midnight |

Columns: **row** is `text`, **hero** is `hero`, **ctx** is `context` (with `contextShort` where it differs), and **SO FAR** is `detail`. "fixed" means Claude never gets the line.

## 1. Hour by hour

| # | Time | Home item (facts) | Row | Hero | Ctx | SO FAR |
|---|---|---|---|---|---|---|
| D1 | 04:10 | Push A planned | Push A today. | Push A | today | (none) |
| D2 | 07:30 | Push A planned | Push A today. | Push A | today | (none) |
| D3 | 07:30 | tacos planned, toBuy 2 | Tacos today, 2 to buy. | Tacos today | 2 to buy | (none) |
| D4 | 07:30 | "Call mom", starts 11:15 | Call mom | Call mom | 11:15 am | (none) |
| D5 | 12:30 | shop running, 6 left | Groceries: 6 left. | Groceries, 6 left | at the store | 6 items left. |
| D6 | 12:52 | shop running, 0 left | Groceries: all in the basket. | Groceries, all in the basket | at the store | All in the basket. |
| D7 | 12:55 | tacos planned, toBuy 0 | Tacos today, nothing to buy. | Tacos today | nothing to buy | (none) |
| D8 | 17:10 | Push A planned | Push A this evening. | Push A | this evening | (none) |
| D9 | 17:52 | Push A running, Bench set 1, 0 sets (fixed) | Bench, set 1. | Push A, bench set 1 | now | 1 exercise, 0 sets. |
| D10 | 18:36 | paused at Incline set 2, 9 sets, lastTouched 18:35 | Incline paused at set 2. | Push A, paused at incline | paused 1 min ago (short: paused 1 min) | 3 exercises, 9 sets. |
| D11 | 19:15 | same, 40 min on | Incline paused at set 2. | Push A, paused at incline | paused 40 min ago (paused 40 min) | 3 exercises, 9 sets. |
| D12 | 19:58 | running, every set logged (`isComplete`, step nil) | Push A, under way. | Push A | now | 6 exercises, 18 sets. |
| D13 | 20:06 | done 20:05, 18 sets, records [Bench] | Push A done. Bench record. | Push A done | done at 8:05 pm | 6 exercises, 18 sets, 1 new best. |
| D14 | 20:31 | cook running, step 1 of 7 | Tacos, on step 1. | Tacos, step 1 | now | Step 1 of 7. |
| D15 | 21:05 | cook paused at step 5, lastTouched 20:50 | Tacos, on step 5. | Tacos, step 5 | paused 15 min ago (paused 15 min) | Step 5 of 7. |
| D16 | 21:40 | cook finished | (nothing: `HomeFacts.fact(process:)` only builds running or paused, so the cook leaves Home) | | | |
| D16b | 21:40 | if a done cook fact were built (state done, step 7) | Tacos, on step 7. | Tacos, step 7 | now | Step 7 of 7. |
| D17 | 22:30 | the done workout, still today | Push A done. Bench record. | Push A done | done at 8:05 pm | 6 exercises, 18 sets, 1 new best. |
| D18 | 00:40 Wed | the same (his day is still Tuesday) | Push A done. Bench record. | Push A done | done at 8:05 pm | 6 exercises, 18 sets, 1 new best. |
| D20 | 04:05 Wed | Pull A planned | Pull A today. | Pull A | today | (none) |

Variants on the same day:

| # | Time | Home item | Row | Hero | Ctx | SO FAR |
|---|---|---|---|---|---|---|
| V1 | 19:15 | paused 1 h 59 min (lastTouched 17:16) | Incline paused at set 2. | Push A, paused at incline | paused 1 h ago (paused 1 h) | 3 exercises, 9 sets. |
| V2 | 20:06 | done, records [Bench, Press] | Push A done. 2 records. | Push A done | done at 8:05 pm | 6 exercises, 18 sets, 2 new bests. |
| V3 | 15:00 | finished with no sets (fixed) | Push A, no sets. | Push A, no sets | this afternoon | 0 exercises, 0 sets. |
| V4 | 14:10 | shop paused at home, 2 left, lastTouched 12:45 | Groceries: 2 left. | Groceries, 2 left | at the store | 2 items left. |
| V5 | 18:00 | running, exercise "Dumbbell Lateral Raise" set 3 | Dumbbell Lateral Raise, set 3. | Push A, dumbbell lateral raise set 3 | now | 4 exercises, 11 sets. |
| V6 | Sunday 10:00 | rest day | Rest day. | Rest day | Sunday | (none) |
| V7 | 00:20 Wed | workout ended 00:15 | Push A done. | Push A done | done at 12:15 am | 6 exercises, 18 sets. |

## 2. Gaps and awkward lines

Ranked by what he'd notice first.

| # | Rows | What's wrong | Proposed fix | Owner |
|---|---|---|---|---|
| G1 | D16, D16b | A finished cook just vanishes from Home, while a finished workout stays until 04:00 as "Push A done". And if a done cook fact is ever built, the lens reads it as still going ("Tacos, on step 7.", ctx "now"): `text`, `hero` and `context` have no done case for `.cook` | Build a done-cook fact like the done workout, worded: row "Tacos done.", hero "Tacos done", ctx "done at 9:40 pm", no SO FAR | Core |
| G2 | V4 | A paused shop still says "at the store" after he's gone home, because `context` puts every `.shop` state on "at the store" | Paused shop gets the paused clause: "paused 1 h ago" | Core |
| G3 | D13, V2 | The row says "record" while SO FAR (and home-lines.md, "a bench best") says "best". One thing, two words | Use "best" everywhere: "Push A done. Bench best." and "2 bests." | Core, Design copy |
| G4 | D9, V3 | SO FAR shows "1 exercise, 0 sets." and "0 exercises, 0 sets." A zero count reads as grading | No SO FAR while sets are 0 (it's nil, like a planned item); V3's hero already says "no sets" | Core |
| G5 | D12 | "Push A, under way." when every set is logged but he hasn't tapped finish. The words aren't wrong, but they're vague at the one moment he's done | "Push A, all sets in." with hero "Push A, all sets in" | Core, Design copy |
| G6 | V1 | 1 h 59 min reads "paused 1 h ago" because `ago` truncates. Close to two hours shows as one | Round to the nearest hour from 60 min on ("paused 2 h ago"), or keep minutes below 2 h ("paused 119 min" is worse); default: round | Core |
| G7 | V5 | Long exercise names: the hero runs "Push A, dumbbell lateral raise set 3" (36 characters). `ExerciseWords.short` covers 5 names only | Add the plan's other long names ("Lateral raise", "Face pull", "Leg curl", "Calf raise", "Pull-down") or fall back to the last two words | Core |
| G8 | D3, D7 | The planned cook's hero reads "Tacos today" from 04:00 to 17:00. home-lines.md's table says "Tacos tonight", since a cook is an evening thing | Planned cook uses its task's due time when it has one; otherwise "tonight" (Kitchen lead to confirm) | Core, Kitchen lead |
| G9 | D7 | "nothing to buy" is a fine line, but with toBuy 0 the context's job (the count) is done, and it reads like a to-do | Ctx becomes the cook's time when one is set ("6:30 pm"), else "nothing to buy" stays | Design copy |
| G10 | D5, D6 | Shop rows have no clock or "since" at all: an hour in the store looks the same as a minute | None for v1 (the count is the news); listed so Design can say no on purpose | Design |
| G11 | D10 | "paused 1 min ago" in the first minutes is noisy; "just now" covers only the first 60 s | "paused just now" up to 2 min | Core |
| G12 | D20 | Nothing on Home tells him at 22:30 what's next tomorrow; Design 44 part two adds "Rest day tomorrow". `HomeLines` has no tomorrow fact yet | A `.planned` fact with tomorrow's day word ("tomorrow"), or Design 44's own line; item 118 checks it on the phone | Core, Design 44 |

What reads well: D1 to D4, D8, D11, D13, D14, D15, D17, D18 (the 4 AM day holds: at 00:40 the done workout and "tonight" both stay Tuesday's), V6 and V7. No line is cut and none carries "…" or " · ". Every context fits 6 words and 32 characters; the longest is "Groceries, all in the basket" (a hero, not a context, so it can step down).

## 3. For the AI-5 eval

D13, D15 and D11 match the eval fixture's E1, E8 and E3 shapes. Once Core builds a done cook (G1), the eval should gain it as E21: hero "Tacos done", ctx "done at 9:40 pm".
